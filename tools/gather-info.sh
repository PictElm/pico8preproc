#!/bin/sh -e
# Example: tools/gather-info.sh 0.0.5
log() { echo "$@" >&2; }
die() { log "$@"; exit 1; }

ver=$1
p8bin=`${0%/*}/have-version.sh $ver`/pico8 || die 'Cannot continue'

hver=`grep ^$ver,version\  '${0%/*}/../.cache/pico8_versions.csv' | cut -f2 -d,`

( rz-bin -s "$p8bin" |
  grep "\spico8_preprocess$"
) |

( read _ addr _ _ _ size _
  #sum=`tail -c +$((addr)) | head -c $size | md5sum | cut -f1 -d\ `
  echo $ver,$hver,$addr,$size #,$sum
)
