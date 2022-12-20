#!/bin/sh -e
cd "${0%/*}/.."
smap=`mktemp`
trap "rm $smap" EXIT
lua playground/fake-preproc.lua .ignore/fake-input.p8 -s $smap
echo ===
cat $smap; echo
echo ===
lua playground/dump-smap.lua $smap
