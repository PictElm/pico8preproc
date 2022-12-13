#!/bin/sh

asm='rasm2 -ax86 -b64'
disasm='rasm2 -ax86 -b64'

plain_dump() {
  tools/gather-info.sh $1 | cut -f3- -d, | tr , \  |
    ( read addr size
      tail -c+$((addr+1)) `tools/have-version.sh $1`/pico8 | head -c$size
    )
}

asm_each_lines() {
  while IFS= read -r line
    do echo $line | $asm -
  done
}

compare_disasm() {
  diff -y -W75 <(plain_dump $1 | $disasm -dB -) <(plain_dump $2 | $disasm -dB -)
}

filter() {
  grep ^[+-] | grep -v '\(call 0x\|jmp 0x\|mov ecx, 0x\|mov esi, 0x\)'
}

compare_disasm 0.0.5 0.1.0 | less
# compare_disasm 0.1.0 0.1.1 | less
