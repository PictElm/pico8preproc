#!/bin/sh
# Example: tools/make-truepp.sh 0.0.5 truepp05
# TODO: find and solve this 'WARNING: Cannot find plugin constructor'
log() { echo "$@" >&2; }
die() { log "$@"; exit 1; }

p8bin=`${0%/*}/have-version.sh $1`/pico8 || die 'Cannot continue'
truepp=${2:-./truepp}
egg=${3:-`dirname $0`/make-truepp-egg.asm}

test -z "$p8bin"  && die "Usage: `basename $0` <p8bin> [<truepp> [<egg>]]"
test -x "$p8bin"  || die "Not an executable: '$p8bin'"
test -e "$truepp" && die "Would override: '$truepp'"
test -f "$egg"    || die "Cannot read shellcode: '$egg'"

# (note to self: _exit, _malloc and _free no longer used and _main only for injection address)
fns=`printf '%s\n' codo_main codo_exit codo_malloc codo_free pico8_preprocess | sort`
asmbl='rz-asm -a x86.nz -b 64 -B -'

# get info of needed symbols
( rz-bin -s "$p8bin" |
  grep "\s\(`printf '\|%s' $fns | tail -c +3`\)$" |
  sort -k 7
) |

# select usefull and translates from hex notation
( while read fn_nth fn_paddr fn_vaddr fn_bind fn_type fn_size fn_name
    do echo $((fn_paddr)) $((fn_vaddr)) $fn_size
  done
) |

# subst in asm file
( set -a
  for fn in $fns
    do read ${fn}_paddr ${fn}_vaddr ${fn}_size
  done
  buffer_size=$((0x4000))
  set +a
  log "`env | grep _vaddr`"

  log "Available space: $codo_main_size bytes"

  echo $codo_main_paddr $codo_main_size

  sed 's/\s*;.*//;/^$/d' "$egg" | tr -s \  | envsubst
) |

# assemble and insert
( read at size

  egg=`mktemp`
  trap rm\ $egg EXIT
  $asmbl -o $at >$egg
  len=`wc -c <$egg`

  log "Override from $at ($len bytes)"

  head -c $at "$p8bin"
  cat $egg
  #tail -c +$((at+len+1)) "$p8bin"

  log "Padding with 'nop's ($((size-len)) bytes)"
  printf %$((size-len))s | tr \  `echo nop $asmbl` | head -c $((size-len))
  tail -c +$((at+size+1)) "$p8bin"
) |

# output into executable
( cat >"$truepp"
  chmod +x "$truepp"
)
