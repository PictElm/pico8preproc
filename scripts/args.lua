---@class options
---@field   infile {file: file*, name: string}
---@field   outfile {file: file*, name: string}
---@field   sourcemapfile {file: file*, name: string}
---@field   version string
--- field   strictheader boolean
--- field   makefile boolean

---@param args string[]
---@return options
return function(args)
  local prog = args[0]
  prog = prog:sub(prog:find("[^/]+$"))

  local usage = function(oops)
    if oops then io.stderr:write("Error: "..oops.."\n") end
    local spce = prog:gsub('.', ' ')
    print("Usage: "..prog.." <infile> -o <outfile>")
    print("       "..spce.." [-s <sourcemapfile>]")
    print("       "..spce.." [-v <version>]")
    print("       "..spce.." [-S] [-M]")
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
      if '-' == f:sub(1, 1)
        then  if "-h" == f then usage()
          elseif "--" == f then r.infile = open(v or usage("missing file name after "..f), 'i')
          elseif "-o" == f then r.outfile = open(v or usage("missing file name after "..f), 'o')
          elseif "-s" == f then r.sourcemapfile = open(v or usage("missing file name after "..f), 'e')
          elseif "-v" == f then r.version = v or usage("missing version after "..f) -- TODO: check version
          else usage("unknown option "..f) end
        else
          if nxv then c = c-1 end
          r.infile = open(args[c], 'i')
      end
      c = c+1
  end

  if not r.infile.file then usage("cannot read file '"..r.infile.name.."'") end
  if not r.outfile.file then usage("cannot write file '"..r.outfile.name.."'") end
  if not r.sourcemapfile.file then usage("cannot write file '"..r.sourcemapfile.name.."'") end

  return r
end
