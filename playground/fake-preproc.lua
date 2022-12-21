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
  local x = o --[[@as text]]

  repeat
    local eol = x:toeol()
    local line = x.read/eol

    local at, len = line:find('%s*%?')
    if at
      then
        local arg = x.read:copy()+at-1+len
        o = o..x.read%(arg:copy()-1)
        o = o.."print("
        o = o..arg%eol
        o = o..")\n"
      else
        o = o.."--"
        o = o..x.read%eol
        o = o.."\n"
    end

    x.read = eol:copy()+1
  until x:iseof()

  return tostring(x.write), x.sourcemap
end

local function main()
  local o = args(arg)
  local r, s = pp(o.infile.file:read('a'), o.infile.name, o.outfile.name)
  o.outfile.file:write(r)
  o.sourcemapfile.file:write(s:encode())
end main()
