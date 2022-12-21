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
  local o = text.new("", outname, inname) --[[@as string #meh]]

  local cursor = loc.new(0, 0, t, inname)
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

  local x = o --[[@as text]]
  return tostring(x.write), x.sourcemap
end

local function main()
  local o = args(arg)
  local r, s = pp(o.infile.file:read('a'), o.infile.name, o.outfile.name)
  o.outfile.file:write(r)
  o.sourcemapfile.file:write(s:encode())
end main()
