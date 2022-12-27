local vers = require 'scripts/vers'

---@class options
---@field   infile        string   #default "-" (ie stdin)
---@field   outfile       string   #default "-" (ie stdout)
---@field   verbfile      string?  #default nil (ie do quiet)
---@field   sourcemap     string?  #default nil (ie do not emit)
---@field   root          string   #default "" (ie cwd)
---@field   version       version  #default `vers.default`
--- field   strictheader  boolean
--- field   makefile      boolean

---@param args string[]
---@return options
return function(args)
  local prog = args[0]
  prog = prog:sub(prog:find("[^/]+$"))

  local usage = function(oops)
    if oops then io.stderr:write("Error: "..oops.."\n") end
    local spce = prog:gsub('.', ' ')
    print("Usage: "..prog.." <infile> -o <outfile>")
    print("       "..spce.." [-V <verbfile>]")
    print("       "..spce.." [-s <sourcemap>]")
    print("       "..spce.." [-v <version>]")
    print("       "..spce.." [-R <root>]")
    -- print("       "..spce.." [-S] [-M]")
    print [[

   Use '-v' with no argument to print a list of supported
   versions.

   For files, a mere '-' implies:
      for infile: stdin
      for outfile: stdout
      for verbfile: stderr
      for sourcemap: stderr
   (Specifying both '-V-' and '-s-' may be undesirable.)
]]
    os.exit(1)
  end

  ---@type options
  local r = {
    infile= "-",
    outfile= "-",
    verbfile= nil,
    sourcemap= nil,
    root= "",
    version= vers.default,
  }

  local c, n = 1, #args
  while c < n+1
    do
      local arg = args[c]
      local f, v = arg:sub(1, 2), arg:sub(3)
      local nxv = false
      if "" == v then v, c, nxv = args[c+1], c+1, true end
      if '-' == f:sub(1, 1)
        then  if "--" == f
            then
              r.infile = v or usage("missing file name after "..f)
          elseif "-h" == f then usage()
          elseif "-o" == f then r.outfile = v or usage("missing file name after "..f)
          elseif "-V" == f then r.verbfile = v or usage("missing file name after "..f)
          elseif "-s" == f then r.sourcemap = v or usage("missing file name after "..f)
          elseif "-R" == f then r.root = v or usage("missing version after "..f)
          elseif "-v" == f
            then
              if not v
                then
                  print(prog.." (pico8preproc) version:\n"..vers.app)
                  print("recognized PICO8 version:")
                  for k=1,#vers.sorted
                    do print(vers.sorted[k][1]..(vers.sorted[k][1] == vers.default and "*" or ""))
                  end
                  os.exit(0)
              elseif not vers.short[v]
                then
                  usage("unknown version or version not implemented "..v)
              end
              r.version = v
            else usage("unknown option "..f)
          end
        else
          if nxv then c = c-1 end
          r.infile = args[c]
      end
      c = c+1
  end

  return r
end
