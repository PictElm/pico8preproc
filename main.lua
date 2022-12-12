#!/usr/bin/env lua

--[[
  Not sure how to properly deal with the overall mess of
  versions that is going to be; The header version does
  not reflect the version of the preprocessing algorithm:
  sometimes hver changes but pp is the same, other pp
  clearly changes but hver stays...

  What I will probably end up doing is to version pps by
  the first p8 version it appears. In any case, this table
  should always map from a p8 version ('ver') to a unique
  way to identify a version of the pp.
]]
local v_map = {
  ['0.0.5']= '05',
  ['0.1.0']= '05',
  ['0.1.1']= '11',
}
---gets the p8pp implementation for the provided p8 version
---@param p8ver string
---@return {pp: function}?
local function for_ver(p8ver)
  local id = v_map[p8ver]
  return id and require('scripts/p8pp'..id)
end

-- TODO: (among other things) proper typing

local p = assert(for_ver '0.0.5', "preprocess not implemented for ..")
io.write(p.pp(io.read('a')))
