#!/bin/sh -e
# Usage: play-test.sh <ver> <test-name>
log() { echo "$@" >&2; }
die() { log "$@"; exit 1; }

cd "${0%/*}/.."
ver=$1
tname=$2

truepp=`tools/have-truepp.sh $ver` || die 'Cannot continue'
p8pp="./main.lua $ver"

sver=`echo ${ver#0} | tr -d .`

test -z "$tname" && die 'No test name provided'
in=tests/in/$tname.p8.lua
out=tests/out-$sver/$tname.lua
test -f "$in" || die "Test not found: $in"

test -f "$out" || {
  mkdir -p "${out%/*}"
  $truepp <"$in" >"$out"
}

tmp=`mktemp --suffix=.lua`
trap "rm $tmp" EXIT
$p8pp <"$in" >$tmp

${diff:-`command -v colordiff || echo diff; echo -u`} "$out" $tmp && log 'No diff (yey)'
