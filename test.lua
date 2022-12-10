#!/usr/bin/env lua

---@param test string
---@return string
---@return string
local function readtest(test)
  local test_in = "tests/"..test..".in"
  local test_out = "tests/"..test..".out"

  local file_in, err_in = io.open(test_in, 'rb')
  assert(file_in, test_in..": "..(err_in or ""))
  local file_out, err_out = io.open(test_out, 'rb')
  assert(file_out, test_out..": "..(err_out or ""))

  local i, o = file_in:read('a'), file_out:read('a')

  file_in:close()
  file_out:close()

  return i, o
end

---@param test string
---@param p8pp {pp: function}
local function dotest(test, p8pp)
  local input, expect = readtest(test)

  print("input source:\n---\n"..input.."\n---")
  local result = p8pp.pp(input)
  print("output source:\n---\n"..result.."\n---")

  assert(expect == result, "test failed [TODO: a diff would be cool]")
end

local p8pp = require 'scripts/p8pp05'
dotest("t05.p8-lua", p8pp)
