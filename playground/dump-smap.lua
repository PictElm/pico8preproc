#!/usr/bin/env lua
getmetatable(require('scripts/text/smap').decode(assert('-' == arg[1] and io.stdin or io.open(assert(arg[1], "no file given"), 'rb'), "could not open file"):read('a')))._playground_dumpinternal()
