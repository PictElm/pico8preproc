local smap = require 'scripts/text/smap'
local loc = require 'scripts/text/loc'

local text = require 'scripts/text'
local args = require 'scripts/args'

---does `\s*?something\n` -> `\s*print(something)\n`
---@param t string
---@param inname string
---@param outname string
---@return string, sourcemap
local function pp(t, inname, outname)
  local r, s = loc.new(0, 0, "", inname), smap.new(outname)
  local ln = 0

  local o = setmetatable({}, {
    __concat= function(self, lit_or_range)
      ---@type string
      local added
      if 'table' == type(lit_or_range)
        then
          ---@cast lit_or_range range
          s:append(r, lit_or_range.from, ln)
          added = tostring(lit_or_range)
        else
          added = lit_or_range
      end
      local _, count = added:gsub('\n', ' ')
      ln = ln+count
      r = r..added
      return self
    end,
  }) --[[@as string]]

  local cursor = loc.new(0, 0, t, r.tag)
  repeat
    local eol = loc.new(cursor.line+1, 0, t, cursor.tag)-1
    local line = cursor/eol

    local at, len = line:find('%s*%?')
    if at
      then
        local arg = cursor:copy()+at-1+len
        o = o..cursor%(arg:copy()-1)
        o = o.."print("
        o = o..arg%eol
        o = o..")\n"
      else
        o = o.."--"
        o = o..cursor%eol
        o = o.."\n"
    end

    cursor = eol:copy()+1
  until "" == ~cursor

  return tostring(r), s
end

local function main()
  local o = args(arg)
  local r, s = pp(o.infile.file:read('a'), o.infile.name, o.outfile.name)
  o.outfile.file:write(r)
  o.sourcemapfile.file:write(s:encode())
end main()
