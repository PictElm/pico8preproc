---@class m
local loc = {}

---@class location : m
---@field   line   integer  #warning: it is 0-based
---@field   column integer  #warning: it is 0-based

---@param line integer?
---@param column integer?
---@param text string?
---@return location
function loc.new(line, column, text, offset)
  local self = {line= line or 0, column= column or 0}

  local bound, offset = text, offset or 1

  local mt
  mt = {
    __index= loc,
    bind= function(text) bound = text end,
    __tostring= function() return bound end,
    __concat= function() assert(nil, "niy") end,
    --...
    __bnot= function() return offset end,
    __unm= function() return offset end,
  }

  return setmetatable(self, mt)
end

---@param off integer
---@param text string
---@return location
function loc.fromoffset(off, text)
  local line, column
  assert(nil, "niy: location from offset in text")
  return loc.new(line, column, text, off)
end

---@param self location
---@return location
function loc.copy(self)
  return loc.new(self.line, self.column, tostring(self), -self)
end

---@param self location
---@param text string
function loc.bind(self, text)
  getmetatable(self).bind(text)
  return self
end

return loc
