#!/bin/sh -e
# Example: tools/foreach-ver.sh tools/gather-info.sh {}
list=${0%/*}/../.cache/pico8_versions.csv
test -f "$list" || (cd "${0%/*}/../.cache"; wget https://gist.githubusercontent.com/PictElm/9e1930781b8c541f7199059ccc08cf89/raw/8780d7459ee7efa18ab5c769d1da52598233d362/pico8_versions.csv)
tail -n+4 "$list" | cut -f1 -d, | xargs -d\\n -I{} sh -c "$*"
