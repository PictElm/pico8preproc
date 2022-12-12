#!/bin/sh -e
# Example: tools/have-version.sh 0.0.5
log() { echo "$@" >&2; }
die() { log "$@"; exit 1; }

cd "${0%/*}/../.cache"
ver=$1

test -f pico8_versions.csv || wget https://gist.githubusercontent.com/PictElm/9e1930781b8c541f7199059ccc08cf89/raw/8780d7459ee7efa18ab5c769d1da52598233d362/pico8_versions.csv
test -z "$ver" && die 'No version code specified'
grep -q ^$ver,version\  pico8_versions.csv || die "Not a known version: '$ver'"
test -d versions || mkdir versions

at=$PWD/versions/$ver
if mkdir "$at" 2>/dev/null
  then
    ( cd "$at"
      export ver
      eval "`grep ^release_url_for_ver= "$OLDPWD/../.env" | envsubst`"
      wget -O dl.zip $release_url_for_ver || die "Could not download release version: '$ver'"
      unzip dl.zip -d bin || die "Could not unzip release version: '$ver'"
    )
fi

test -x "$at/bin/pico-8/pico8" || die "Found item does not contain the binary executable at: '$at/bin/pico-8/pico8'"
echo "$at/bin/pico-8"
