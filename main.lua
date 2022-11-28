#!/usr/bin/env lua

local p8pp = require 'scripts/p8pp05'

-- TODO: just noticed that one-to-last line is not processed correctly;
--       its corresponding output should be `a = a / b = = = / b + 2`
--       but for now we end up with `a  = a / b = b + 2`
local inn = [[a = 2
print('a: '..a)
a+= 1
if (a != 3) a-= 3
print('last line')
a /=b+=2
b*=a]]

print("input source:\n---\n"..inn.."\n---")
local out = p8pp.pp(inn)
print("output source:\n---\n"..out.."\n---")
