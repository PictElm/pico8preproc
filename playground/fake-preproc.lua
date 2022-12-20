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

---@class options
---@field   infile {file: file*, name: string}
---@field   outfile {file: file*, name: string}
---@field   sourcemapfile {file: file*, name: string}
---@field   version string
--- field   makefile boolean
--- field   strictheader boolean

---@param args string[]
---@return options
local function parseargs(args)
  local prog = args[0]

  local usage = function(oops)
    if oops then print("Error: "..oops) end
    print("Usage: "..prog.." <infile> -o <outfile> [-s <sourcemapfile>]")
    os.exit(1)
  end

  ---@return {file: file*, name: string}
  local open = function(name, ioe)
    return {
      file= "-" == name
        and ({i= io.stdin, o= io.stdout, e= io.stderr})[ioe]
        or io.open(name, ({i= 'rb', o= 'wb', e= 'wb'})[ioe]),
      name= name,
    }
  end

  ---@type options
  local r = {
    infile= {file= io.stdin, name= "-"},
    outfile= {file= io.stdout, name= "-"},
    sourcemapfile= {file= io.stderr, name= "-"},
    version= '0.0.5'
  }

  local c, n = 1, #args
  while c < n+1
    do
      local f, v = args[c]:sub(1, 2), args[c]:sub(3)
      local nxv = false
      if "" == v then v, c, nxv = args[c+1], c+1, true end
          if "-h" == f then usage()
      elseif "--" == f then r.infile = open(v or usage("missing file name after "..f), 'i')
      elseif "-o" == f then r.outfile = open(v or usage("missing file name after "..f), 'o')
      elseif "-s" == f then r.sourcemapfile = open(v or usage("missing file name after "..f), 'e')
      elseif "-v" == f then r.version = v or usage("missing version after "..f) -- TODO: check version
        else
          if nxv then c = c-1 end
          r.infile = open(args[c], 'i')
      end
      c = c+1
  end

  if not r.infile.file then usage("cannot read file "..r.infile.name) end
  if not r.outfile.file then usage("cannot write file "..r.outfile.name) end
  if not r.sourcemapfile.file then usage("cannot write file "..r.sourcemapfile.name) end

  return r
end

local function main()
  local o = parseargs(arg)
  local r, s = pp(o.infile.file:read('a'))
  o.outfile.file:write(r)
  o.sourcemapfile.file:write(s:encode())
end main()
