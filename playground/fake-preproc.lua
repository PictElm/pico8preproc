local smap = require 'scripts/text/smap'
local loc = require 'scripts/text/loc'

local function log(t)
  io.stderr:write('\x1b[31m'..tostring(t)..'\x1b[m\n')
end

---does `\s*?something\n` -> `\s*print(something)\n`
---@param t string
---@return string, sourcemap
local function pp(t)
  local r, s = loc.new(0, 0, "", "stdout.lua"), smap.new("stdin.p8")

  local o = setmetatable({}, {
    __concat= function(self, lit_or_range)
      -- TODO: update `s` about insertion
      if 'table' == type(lit_or_range)
        then
          ---@cast lit_or_range range
          local from, to = lit_or_range.from, lit_or_range.to
          log("concatenating range: "..from:repr().."/"..to:repr())
          r = r..tostring(lit_or_range)
        else
          r = r..lit_or_range
      end
      return self
    end,
  }) --[[@as string]]

  local cursor = loc.new(0, 0, t, "source")
  repeat
    local eol = loc.new(cursor.line+1, 0, t, "source")-1
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

local r, s = pp(io.read('a'))
io.stdout:write(r)
io.stderr:write(s:encode())
