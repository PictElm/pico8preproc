local smap = require 'scripts/text/smap'
local loc = require 'scripts/text/loc'

---@class text_m
local text = {}

local mt = {
  __index= text,

  ---@param self text
  ---@param lit_or_range string|number|range
  ---@return text
  __concat= function(self, lit_or_range)
    if 'table' == type(lit_or_range)
      then self.sourcemap:append(self.write, lit_or_range.from, self.linecount)
    end
    local added = tostring(lit_or_range)
    local _, count = added:gsub('\n', ' ')
    self.linecount = self.linecount+count
    self.write = self.write..added
    return self
  end,
}
---@class text : text_m
---@field   sourcemap sourcemap   #(read-only)
---@field   write     location    #(read-only)
---@field   read      location
---@field   incstack  location[]  #(read-only)
---@field   linecount integer     #(read-only) counts line in output
---@operator concat(string|number|range): text

---@param name string
---@param from string|location|nil
---@return {file: file*, name: string}
local function tryopen(name, from, mode, ifdash)
  if ifdash and '-' == name then return {file= ifdash, name= name} end
  local file = io.open(name, mode)
  if file then return {file= file, name= name} end
  error("could not open file '"..name.."'"..(from and " (included from '"..('string' == type(from) and from or from:repr()).."')" or ""))
end

---@param out string
---@param in1 string?  #the first file to start reading from; if not available yet, make sure to call `pushinclude` before doing anything else
---@return text
function text.new(root, out, in1)
  local r = setmetatable({
    sourcemap= smap.new(out, root),
    write= loc.new(0, 0, "", out, 1),
    read= nil,
    incstack= {},
    linecount= 0,
  }, mt) --[[@as text]]
  if in1 then r:pushinclude(in1) end
  return r
end

---flush the output buffer, and optionally the JSON source map
---@param self text
---@param outfile string
---@param sourcemap string?
function text.flush(self, outfile, sourcemap)
  local out = tryopen(outfile, nil, 'wb', io.stdout)
  out.file:write(tostring(self.write))
  out.file:close()
  if sourcemap
    then
      local map = tryopen(sourcemap, nil, 'wb', io.stderr)
      map.file:write(self.sourcemap:encode())
      map.file:close()
  end
end

---@param self text
---@param ... string|number|range
---@return text
function text.append(self, ...)
  local t = table.pack(...)
  for k=1,t.n do self = self..t[k] end
  return self
end

---@param self text
---@param inname string
---@return location #the push'ed location (ie. `self.read`)
function text.pushinclude(self, inname)
  if self.read
    then self.incstack[#self.incstack+1] = self.read
  end
  -- TODO: include relative to current self.read (default behavior)
  local path = self.sourcemap:getrootpath()..inname
  local info = tryopen(path, self.read, 'rb', not self.read and io.stdin)
  local buffer = info.file:read('a')
  info.file:close()
  self.read = loc.new(0, 0, buffer, inname, 1)
  return self.read
end

---@param self text
---@return location #the pop'ed location
function text.popinclude(self)
  local len = #self.incstack
  local it = self.incstack[len]
  self.incstack[len], self.read = nil, self.incstack[len-1]
  return it
end

---@param self text
---@return boolean
function text.iseof(self)
  return "" == ~self.read
end

---@param self text
---@param pat string
---@return location?
function text.tofind(self, pat)
  local off = (~self.read):find(pat)
  return off and self.read:copy()+off-1
end

---@param self text
---@return location
function text.toeol(self) -- XXX: when no nl
  -- return self:tofind('\n') or self.read:copy()+-self.read

  -- YYY: this might be the most costly
  return loc.new(self.read.line+1, 0, tostring(self.read), self.read.tag)-1

  -- .. and this the cheapest
  -- local txt = ~self.read
  -- local off = txt:find('\n') or #txt
  -- return self.read:copy()+off-1
end

return text
