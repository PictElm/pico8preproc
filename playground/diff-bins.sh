#!/bin/sh

asm='rasm2 -ax86 -b64'
disasm='rasm2 -ax86 -b64'

plain_dump_preprocess() {
  tools/gather-info.sh $1 | cut -f3-4 -d, | tr , \  |
    ( read addr size
      tail -c+$((addr+1)) `tools/have-version.sh $1`/pico8 | head -c$size
    )
}
plain_dump_lex() {
  tools/gather-info.sh $1 | cut -f5- -d, | tr , \  |
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
  diff -y -W75 <(plain_dump_$1 $2 | $disasm -dB -) <(plain_dump_$1 $3 | $disasm -dB -)
}

filter() {
  grep ^[+-] | grep -v '\(call 0x\|jmp 0x\|mov ecx, 0x\|mov esi, 0x\)'
}

# compare_disasm preprocess 0.0.5 0.1.0 | less
# compare_disasm preprocess 0.1.0 0.1.1 | less # diff
# compare_disasm preprocess 0.1.1 0.1.2 | less
# compare_disasm preprocess 0.1.2 0.1.3 | less
compare_disasm preprocess 0.1.3 0.1.4 | less # diff
compare_disasm lex 0.1.3 0.1.4 | less # diff
