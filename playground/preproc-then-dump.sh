#!/bin/sh -e
cd "${0%/*}/.."
lua playground/fake-preproc.lua .ignore/fake-input.p8 -o .ignore/fake-output.lua -s .ignore/fake-map.json
cat .ignore/fake-output.lua
echo ===
cat .ignore/fake-map.json; echo
echo ===
lua playground/dump-smap.lua .ignore/fake-map.json | tee .ignore/fake-dump.txt
