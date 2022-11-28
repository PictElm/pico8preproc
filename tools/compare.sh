#!/bin/sh -e
cd `dirname $0`/..

# (for each function bellow) Usage: <version> <test-file>

truepp() {
  tmp=`mktemp -d`
  ( cd $tmp
    cat $2 >in.p8
    printf 'pico-8 cartridge\n\n__lua__\nprinth([=[\n#include in.p8\n]=])\n' >ph.p8
    "`hidden/have-version $1`/pico8" -root_path $tmp -run ph.p8 & p=$!
    sleep 10 ; kill $p # :(
    rm in.p8 ph.p8
  )
  rmdir $tmp
}

p8pp() {
  #make or equivalent
  #call with arguments
  :
}

compp() {
  truepp=`mktemp truepp-XXX.lua`
  p8pp=`mktemp p8pp-XXX.lua`
  truepp "$1" "$2" >$truepp
  p8pp "$1" "$2" >$p8pp
  diff -u $truepp $p8pp
  rm $truepp $p8pp
}

for dver in tests/*
  do
    for name in $dver/*
      do
        echo compp "${dver##*/}" "$PWD/$name"
    done
done
