---@class loc_m
local loc = {}

---@class location : loc_m
---@field   line   integer  #warning: it is 0-based
---@field   column integer  #warning: it is 0-based
---@operator add(integer): location
---@operator sub(integer): location
---@operator concat(string): location
---@operator div(location): string
---@operator bnot(location): string
---@operator unm: location

---@param line integer?
---@param column integer?
---@param text string?
---@return location
function loc.new(line, column, text, offset)
  assert(not line or column, "line given but not column")
  local _self = {line= line or 0, column= column or 0}

  local function bind(newtext)
    text = newtext
    ---@cast text string
    offset = 1
    for _=1,_self.line
      do
        local nl = text:find('\n', offset) or #text
        offset = nl+1
    end
    offset = offset+_self.column
    text = newtext
  end

  if not offset
    then if line and text then bind(text) end
    else offset = 1
  end
  if not text then text = "" end

  local mt
  mt = {
    __index= function(_, k)
      if 'number' == type(k)
        then return text:sub(offset+k, offset+k)
        else return loc[k]
      end
    end,

    bind= bind,
    __tostring= function() return text end,

    __add= function(self, by) -- YYY: returns self!
      local at, to = offset, offset+by
      local s = text:sub(at, to-1)
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
      local s = text:sub(to, at-1)
      local nl = s:find('\n')
      if nl
        then
          local _, nlcount = s:gsub('\n', ' ')
          self.line = nlcount
          self.column = (text:sub(1, at-1-nl):reverse():find('\n') or at-1-nl)-1
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
          text = text:sub(1, offset-1)..txt..text:sub(offset)
          return self+#txt
        else
          local self, txt = txt_or_self, self_or_txt
          text = text:sub(1, offset-1)..txt..text:sub(offset)
          return self
      end
    end,

    __div= function(_, mate)
      local till = -mate-1
      if till < 0 or till <= offset then return "" end
      return text:sub(offset, till)
    end,

    __bnot= function() return text:sub(offset) end,
    __unm= function() return offset end,
  }

  return setmetatable(_self, mt)
end

---@param off integer
---@param text string
---@return location
function loc.fromoffset(off, text)
  return loc.new(nil, nil, text)+off
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

return loc
