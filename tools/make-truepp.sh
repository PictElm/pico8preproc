#!/bin/sh

# TODO: find and solve this 'WARNING: Cannot find plugin constructor'

p8bin=${1:-../bin/pico-8/pico8}
truepp=${2:-./truepp}

test -x "$p8bin"

log() { echo "$@" >/dev/tty; }
fns=`printf '%s\n' codo_main codo_exit pico8_preprocess | sort`

( rz-bin -s "$p8bin" 2>/dev/null |
  grep "\s\(`printf '\|%s' $fns | tail -c +3`\)$" |
  sort -k 7
) |

( readfn() { read $1_nth $1_paddr $1_vaddr $1_bind $1_type $1_size $1_name; }
  for fn in $fns; do readfn $fn; done
  log "`set | grep _vaddr`"

  log "available space: $((codo_main_size)) bytes"
  echo $codo_main_paddr

  cat <<-EGG
  ; // (using x86_64 call convention)
  ; 
  ; // max uint or something
  ; #define BUF_SZ 0x4000
  ; // should use malloc/free directly?
  ; 
  ; char* in = codo_malloc(BUF_SZ);
  ; char* out = codo_malloc(BUF_SZ);
  ; 
  ; char* head;
  ; ssize_t sz;
  ; 
  ; head = in;
  ; while ((sz = read(STDIN_FILENO, in, BUF_SZ-(in-head)))) in+= sz;
  ; 
  ; pico8_preprocess(in, out);
  ; 
  ; head = in;
  ; while ((sz = write(STDOUT_FILENO, out, BUF_SZ-(out-head)))) out+= sz;
  ; 
  ; codo_free(in);
  ; codo_free(out);
  ; return 0; // _exit(0);

  ; TODO: all
  ;mov rdi [in]
  ;mov rsi [out]
  ;call $pico8_preprocess_paddr

  xor eax, eax
  ret
EGG
) |

( read at

  egg=`mktemp`
  trap 'rm $egg' EXIT
  rz-asm -o $((at)) -B - >$egg 2>/dev/null||:
  len=`wc -c <$egg`

  log "override from $((at)) ($((len)) bytes)"

  head -c $((at)) "$p8bin"
  cat $egg
  tail -c +$((at+len+1)) "$p8bin"
) |

( cat >"$truepp"
	chmod +x "$truepp"
	#tee "$truepp" | xxd -g1 | less
)

