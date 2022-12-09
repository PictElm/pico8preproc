#!/bin/sh
# Example: tools/make-truepp.sh hidden/versions/0.0.5/bin/pico-8/pico8 truepp05
# TODO: find and solve this 'WARNING: Cannot find plugin constructor'

p8bin=$1
truepp=${2:-./truepp}
egg=${3:-`dirname $0`/make-truepp-egg.asm}

log() { echo "$@" >/dev/tty; }
die() { log "$@"; exit 1; }

test -z "$p8bin"  && die "Usage: `basename $0` <p8bin> [<truepp> [<egg>]]"
test -x "$p8bin"  || die "'$p8bin' is not an executable"
test -e "$truepp" && die "Would override '$truepp'"
test -f "$egg"    || die "Cannot read shellcode '$egg'"

fns=`printf '%s\n' codo_main codo_exit codo_malloc codo_free pico8_preprocess | sort`
plat='-a x86.nz -b 64'

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
  set +a
  log "`env | grep _vaddr`"

  log "available space: $codo_main_size bytes"

  echo $codo_main_paddr $codo_main_size

  sed /^\$/d "$egg" | tr -s \  | envsubst
) |

# assemble and insert
( read at size

  egg=`mktemp`
  trap rm\ $egg EXIT
  rz-asm $plat -o $at -B - >$egg
  len=`wc -c <$egg`

  log "override from $at ($len bytes)"

  head -c $at "$p8bin"
  cat $egg
  #tail -c +$((at+len+1)) "$p8bin"

  log "padding with 'nop's ($((size-len)) bytes)"
  printf %$((size-len))s | tr \  `rz-asm $plat -B nop` | head -c $((size-len))
  tail -c +$((at+size+1)) "$p8bin"
) |

# output into executable
( cat >"$truepp"
	chmod +x "$truepp"
)
