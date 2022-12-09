#!/bin/sh -e

set -a
codo_main_paddr=$((0x0003e610))
codo_free_paddr=$((0x0006eac0))
codo_malloc_paddr=$((0x0006eaa0))
codo_exit_paddr=$((0x0003e400))
pico8_preprocess_paddr=$((0x0003dcc0))
buffer_size=$((0x4000))

#cat egg-wip.asm |
#sed /^\$/d |
sed 's/\s*;.*//;/^$/d' tools/make-truepp-egg.asm |
tr -s \  |
envsubst |
head -n ${1:-12345} |
rz-asm -a x86.nz -b 64 -o $((codo_main_paddr)) -B - |
rz-asm -a x86 -b 64 -d -B - |
less;exit
tee /dev/tty |
wc -c |
dc -e?1-2/p
