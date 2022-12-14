#!/bin/sh -e
# Example: tools/gather-info.sh 0.0.5
log() { echo "$@" >&2; }
die() { log "$@"; exit 1; }

cd "${0%/*}/../.cache"
ver=$1

test -z "$ver" && die 'No version code specified'
grep -q ^$ver,version\  pico8_versions.csv || die "Not a known version: '$ver'"

if ! test -f pico8_preprocesses_info.csv
  then
    ( get_info_for() {
        ( rz-bin -s "$1" |
          grep "\s$2$" || echo _ 0x0 _ _ _ 0 _
        ) |
        ( read _ addr _ _ _ size _
          echo $addr $size
        )
      }

      symbols='pico8_preprocess get_next_token'

      printf %s 'pico-8 version,header version'
      for n in $symbols
        do printf ',%s address,%s size' $n $n
      done
      echo

      for vver in `tail -n+4 pico8_versions.csv | cut -f1 -d,`
        do
          p8bin=`../tools/have-version.sh $vver`/pico8 || die 'Cannot continue'
          hver=`grep ^$vver,version\  pico8_versions.csv | cut -f2 -d,`

          printf %s,%s "$vver" "$hver"
          for n in $symbols
            do printf ,%s,%s `get_info_for "$p8bin" $n`
          done
          echo
      done
    ) >pico8_preprocesses_info.csv
fi

grep ^$ver,version\  pico8_preprocesses_info.csv
