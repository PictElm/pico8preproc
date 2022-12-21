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
---@field   read      location    #(read-only)
---@field   incstack  location[]  #(read-only)
---@field   linecount integer     #(read-only) counts line in output
---@operator concat(string|number|range): text

---@param name string
---@param from string|location|nil
---@return {file: file*, name: string}
local function tryopen(name, from)
  local file = io.open(name)
  if file then return {file= file, name= name} end
  error("could not open file '"..name.."' "..(from and "(included from '"..('string' == type(from) and from or from:repr()).."')" or ""))
end

---@param name string
---@param from string|location|nil
---@return string
local function tryread(name, from)
  local info = tryopen(name, from)
  local buffer = info.file:read('a')
  info.file:close()
  return buffer
end

---@param outname string
---@param inname string?
---@return text
function text.new(root, outname, inname)
  local r = setmetatable({
    sourcemap= smap.new(outname, root),
    write= loc.new(0, 0, "", outname, 0),
    read= nil,
    incstack= {},
    linecount= 0,
  }, mt) --[[@as text]]
  if inname then r:pushinclude(inname) end
  return r
end

---@param self text
---@param inname string
---@return location #the push'ed location (ie. `self.read`)
function text.pushinclude(self, inname)
  if self.read
    then self.incstack[#self.incstack+1] = self.read
  end
  self.read = loc.new(0, 0, tryread(inname), inname, 0)
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
  return "" == ~self
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
function text.toeol(self)
  -- return self:tofind('\n') or self.read:copy()+-self.read

  -- YYY: this might be the most costly
  return loc.new(self.read.line+1, 0, tostring(self.read), self.read.tag)-1

  -- .. and this the cheapest
  -- local txt = ~self.read
  -- local off = txt:find('\n') or #txt
  -- return self.read:copy()+off-1
end

return text
