---@class options
---@field   infile        string
---@field   outfile       string
---@field   sourcemap     string   #command-line optional
---@field   root          string   #command-line optional
---@field   version       string   #command-line optional
--- field   strictheader  boolean  #command-line optional
--- field   makefile      boolean  #command-line optional

---@param args string[]
---@return options
return function(args)
  local prog = args[0]
  prog = prog:sub(prog:find("[^/]+$"))

  local usage = function(oops)
    if oops then io.stderr:write("Error: "..oops.."\n") end
    local spce = prog:gsub('.', ' ')
    print("Usage: "..prog.." <infile> -o <outfile>")
    print("       "..spce.." [-s <sourcemap>]")
    print("       "..spce.." [-v <version>]")
    print("       "..spce.." [-R <root>]")
    -- print("       "..spce.." [-S] [-M]")
    os.exit(1)
  end

  ---@type options
  local r = {
    infile= "-",
    outfile= "-",
    sourcemap= "-",
    root= "", -- ie. "./"
    version= '0.0.5',
  }

  local c, n = 1, #args
  while c < n+1
    do
      local f, v = args[c]:sub(1, 2), args[c]:sub(3)
      local nxv = false
      if "" == v then v, c, nxv = args[c+1], c+1, true end
      if '-' == f:sub(1, 1)
        then  if "-h" == f then usage()
          elseif "--" == f then r.infile = v or usage("missing file name after "..f)
          elseif "-o" == f then r.outfile = v or usage("missing file name after "..f)
          elseif "-s" == f then r.sourcemap = v or usage("missing file name after "..f)
          elseif "-R" == f then r.root = v or usage("missing version after "..f)
          elseif "-v" == f then r.version = v or usage("missing version after "..f) -- TODO: check version
          else usage("unknown option "..f) end
        else
          if nxv then c = c-1 end
          r.infile = args[c]
      end
      c = c+1
  end

  return r
end
