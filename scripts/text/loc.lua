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
  assert(not line or column, "line given but not column")
  local self = {line= line or 0, column= column or 0}

  if not offset and line and text
    then
      offset = 1
      for k=1,line
        do
          local nl = text:find('\n', offset) or #text
          offset = nl+1
      end
      offset = offset+column
  end

  local bound = text or ""

  local mt
  mt = {
    __index= function(self, k)
      if 'number' == type(k)
        then return bound:sub(offset+k, offset+k)
        else return loc[k]
      end
    end,

    bind= function(text) bound = text end,
    __tostring= function() return bound end,

    __add= function(self, by) -- YYY: returns self!
      local at, to = offset, offset+by
      local s = bound:sub(at, to-1)
      local nl = s:find('\n')
      while nl
        do
          by, s = by-nl, s:sub(nl+1)
          self.line = self.line+1
          self.column = 0
          nl = s:find('\n')
      end
      self.column = self.column+by
      offset = to
      return self
    end,

    __sub= function(self, by) -- YYY: returns self!
      local to, at = offset-by, offset
      local s = bound:sub(to, at)
      local nl = s:find('\n')
      if nl
        then
          self.column = nl
          self.line = s:gsub('\n', ' ')
        else
          self.column = self.column-by
      end
      offset = to
      return self
    end,

    __concat= function(self_or_txt, txt_or_self) -- YYY: returns self!
      if 'table' == type(self_or_txt)
        then
          local self, txt = self_or_txt, txt_or_self
          bound = bound:sub(1, offset-1)..txt..bound:sub(offset)
          return self+#txt
        else
          local self, txt = txt_or_self, self_or_txt
          bound = bound:sub(1, offset-1)..txt..bound:sub(offset)
          return self
      end
    end,

    __bnot= function() return bound:sub(offset) end, -- YYY
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

---@param self location
---@return string
function loc.repr(self)
  return self.line..':'..self.column
end

function _playground()
  text = [[this is the first line
now there is the second line
then that's the thrid and last line
]]
  local self = loc.new(2, 9, text)
  print(self:repr().." _"..~self.."_")
  self = self.."coucou"
  print('___'..tostring(self)..'___')
  self = self-4
  print(self:repr().." _"..~self.."_")
end _playground()

return loc
