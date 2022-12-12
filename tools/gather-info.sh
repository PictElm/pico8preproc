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
    for vver in `cut -f1 -d, pico8_versions.csv`
      do
        p8bin=`${0%/*}/have-version.sh $vver`/pico8 || die 'Cannot continue'
        hver=`grep ^$vver,version\  pico8_versions.csv | cut -f2 -d,`

        ( rz-bin -s "$p8bin" |
          grep "\spico8_preprocess$"
        ) |

        ( read _ addr _ _ _ size _
          #sum=`tail -c +$((addr)) | head -c $size | md5sum | cut -f1 -d\ `
          echo $vver,$hver,$addr,$size #,$sum
        )
    done
fi

grep ^$ver,version\  pico8_preprocesses_info.csv
