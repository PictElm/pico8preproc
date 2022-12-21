local text = require 'scripts/text'
local args = require 'scripts/args'

---does `\s*?something\n` -> `\s*print(something)\n`
---@param opts options
local function pp(opts)
  local x = text.new("", opts.outfile, opts.infile)
  local o = x --[[@as string]]

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

  x:flush(opts.outfile, opts.sourcemap)
end

pp(args(arg))
