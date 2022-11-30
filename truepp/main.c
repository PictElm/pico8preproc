#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include "xed-interface.h"
#include "xed-decode.h"
#include "xed-decoded-inst-api.h"

#define die(...) do { printf(__VA_ARGS__); exit(errno); } while(0)

int version_code(char const* version_string) {
  // version_string ::~ 0.y.z[z][c]
  // -> y zz c
  char y = 0, z1 = 0, z2 = 0, c = 0;

  version_string++; // skip '0'
  version_string++; // skip '.'

  y = *version_string++;
  version_string++; // skip '.'

  z1 = *version_string++;
  if ('0' <= *version_string && *version_string <= '9')
    z2 = *version_string++;

  if (*version_string)
    c = *version_string;

  return (y << (8*3)) | (z1 << (8*2)) | (z2 << (8*1)) | (c << (8*0)) ;
}

// size_t address(int version) {
//   (void) version;
//   return 0x0043dcc0;
// }

struct callfix {
  size_t oaddr; // if the address of the call is
  size_t raddr; // replace so it rather calls
};

struct proghack {
  size_t offset; // call into the address
  size_t length; // puts a ret length after
  struct callfix* call_fixups;
};

struct callfix cfv05[3] = {
  {.oaddr= 0x0046eaa0 & 0x0fffff, .raddr= (size_t)malloc}, // codo_malloc -> malloc
  {.oaddr= 0x0046eac0 & 0x0fffff, .raddr= (size_t)free},   // codo_free -> free
  {0},
};
struct proghack v05 = {
  .offset= 0x043dcc0 & 0x0fffff,
  .length= 1112,
  .call_fixups= cfv05,
};

void get_proghack_for(int version, struct proghack* out) {
  (void) version;
  // if (version_for("0.0.5") == version)
  memcpy(out, &v05, sizeof(struct proghack));
}

struct loaded {
  void* addr;
  size_t size;
};

// TODO: change signature to take `at` - if 0 then means first call
void fixup(struct loaded const* ldd, struct proghack const* fx) {
  xed_state_t dstate;
  xed_decoded_inst_t xedd;
  dstate.mmode = XED_MACHINE_MODE_LONG_64;

  size_t cursor = 0;
  while (cursor < fx->length) {
    size_t at = (size_t)ldd->addr + fx->offset + cursor;
    size_t left = fx->length - cursor;

    xed_decoded_inst_zero_set_mode(&xedd, &dstate);
    xed_error_enum_t err = xed_decode(&xedd, (unsigned char*)at, left);
    if (XED_ERROR_NONE != err) {
      printf("got xed error: '%s'\n", xed_error_enum_t2str(err));
      exit(1);
    }

    xed_uint_t len = xed_decoded_inst_get_length(&xedd);
    xed_category_enum_t cat = xed_decoded_inst_get_category(&xedd);
    printf("%p %s\n", (unsigned char*)at, xed_category_enum_t2str(cat));

    if (XED_CATEGORY_CALL == cat) {
      xed_int32_t displ = xed_decoded_inst_get_branch_displacement(&xedd);
      size_t target = at+len + displ;
      size_t infile = target & 0x0fffff;
      printf(" found a call to 0x%zx - ", infile);

      size_t new_target = 0;
      struct callfix const* search = fx->call_fixups;
      while (search->oaddr) {
        if (search->oaddr == infile) {
          // new_target = search->raddr;
          new_target = (size_t)ldd->addr;

          // at+len + displ = target  =>  new_displ = new_target - (at+len)
          // so that  new_target = at+len + found - (at+len)
          size_t ideal_new_displ = new_target - (at+len);
          xed_int32_t new_displ = new_target - (at+len);
          if (new_displ != ideal_new_displ) {
            printf("\ncould not make in within 32 bits: %d != %zd\n", new_displ, ideal_new_displ);
            exit(1);
          }
          printf("changing it for a call to 0x%zx (new displ: %d)\n", new_target, new_displ);

          //printf("-- %hhx, %hhx, %hhx, %hhx\n", ((char*)at)[-1], ((char*)at)[0], ((char*)at)[1], ((char*)at)[2]);
          xed_uint_t displw = xed_decoded_inst_get_branch_displacement_width(&xedd);
          xed_decoded_inst_set_branch_displacement(&xedd, new_displ, displw);
          //printf("-- %hhx, %hhx, %hhx, %hhx\n", ((char*)at)[-1], ((char*)at)[0], ((char*)at)[1], ((char*)at)[2]);

          // TODO: apply the change by encoding it back and placing the result `at`
          break;
        }
        search++;
      }

      if (!new_target) {
        puts("could not find in the callfix table\n"); // YYY: would need to recurse
        puts("NIY: recursively fixup called procedure");
        exit(1);
        fixup(ldd, fx/*, at*/);
      }
    }

    if (!len) {
      puts("somehow got a zero length instruction");
      exit(1);
    }
    cursor+= len;
    if (40 < cursor) break; // ZZZ
  }
  exit(0);
}

void load(char const* filename, struct loaded* out) {
  if (out->addr) return;

  int fd = open(filename, O_RDONLY);
  if (fd < 0) die("open");

  size_t size;
  off_t off = 0;

  struct stat st = {0};
  if (fstat(fd, &st) < 0) die("stat");
  size = st.st_size;

  int prot = PROT_EXEC | PROT_READ;
  int flags = MAP_PRIVATE | MAP_EXECUTABLE;
  void* addr = mmap(NULL, size, prot, flags, fd, off);

  close(fd);

  if (MAP_FAILED == addr) die("mmap");

  out->addr = addr;
  out->size = size;
}

void unload(struct loaded* in) {
  if (in->addr && munmap(in->addr, in->size) < 0) die("munmap");

  in->addr = NULL;
  in->size = 0;
}

int main(int argc, char* argv[]) {
  char const* prog = *argv++;
  if (--argc <3) {
    printf("Usage: %s <version> <exe-path> <input-file>\n", prog);
    return EXIT_FAILURE;
  }

  char const* version = *argv++;
  char const* exe_path = *argv++;
  char const* input_file = *argv++;

  struct proghack fx;
  get_proghack_for(version_code(version), &fx);

  struct loaded ldd = {0};
  load(exe_path, &ldd);

  xed_tables_init(); // this only once
  fixup(&ldd, &fx);

  void (*pico8_preprocess)(char const* in, char* out);
  pico8_preprocess = (void*)(ldd.addr + fx.offset);

  char const* in = "print 'hello'\n";
  char out[256] = {0};

  printf("in:\n---\n%s---\n", in);
  pico8_preprocess(in, out);
  printf("out:\n---\n%s---\n", out);

  unload(&ldd);

  puts("done");
  return EXIT_SUCCESS;
}
