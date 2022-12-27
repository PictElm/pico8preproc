local text = require 'scripts/text'

local common_m = {}
---@class preproc
---@operator call(options): nil

---@param o any
---@return string
local function da(o, i)
  if 'string' == type(o) then return "'"..o:gsub("'", "\\'"):gsub("\n", "\\n"):gsub("\t", "\\t").."'" end
  if 'table' == type(o)
    then
      local r = "{\n" i = i or ""
      for k,v in pairs(o)
        do
          r = r..i.."\t"
          if 'string' == type(k)
            then r = r..k
            else r = r.."["..da(k).."]"
          end
          r = r.."= "..da(v, i.."\t")..",\n"
      end
      return r..i.."}"
  end
  return tostring(o)
end

---@param does fun(log: fun(...), text: text, opts: options)
---@return preproc
function common_m.new(tag, does)
  ---@type file*?
  local logfile = nil
  ---@param ... any
  local function log(...)
    if not logfile then return end
    logfile:write("["..tag.."] ")
    local l, sep = table.pack(...), " "
    if 1 == l.n and 'string' == type(l[1])
      then logfile:write(l[1])
      else
        for k=1,l.n
          do
            if nil == l[k] and l.n == k then return end
            logfile:write(da(l[k])..sep)
        end
    end
    logfile:write("\n")
  end
  return setmetatable({}, {
    ---@param _ preproc #(self)
    ---@param opts options
    __call= function(_, opts)
      if opts.verbfile
        then logfile = '-' == opts.verbfile and io.stderr or io.open(opts.verbfile)
      end
      local rexr = text.new(opts.root, opts.outfile, opts.infile)
      does(log, rexr, opts)
      if logfile then logfile:close() end
      rexr:flush(opts.outfile, opts.sourcemap)
    end
  })
end

return common_m
