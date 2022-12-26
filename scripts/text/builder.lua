---@class builder_m
---@field private len integer
---@field private str string
---@field private n integer
local builder = {}

-- piece inteface:
-- * __len() -> integer
-- * __tostring(self) -> str
-- * [__concat(self, <self>) -> <self>]
-- * sub(self, i, j?) -> <self>
-- * find(self, pattern, init?, plain?) -> int, int
---@alias piece string|range|builder

local mt = {
  __index= builder,

  ---@param self builder
  ---@diagnostic disable-next-line: invisible
  __tostring= function(self) return self.str end,

  ---@param self builder
  ---@return integer
  ---@diagnostic disable-next-line: invisible
  __len= function(self) return self.len end,

  ---@param self builder
  ---@param other piece
  ---@return builder
  __concat= function(self, other) return builder.new(self, other) end,
}
---@class builder : builder_m
---@operator len(): integer
---@operator concat(piece): builder

---@param ... piece
---@return builder
function builder.new(...)
  local r = table.pack(...)
  r.len, r.str = 0, ""
  for k=1,#r.n
    do r.len, r.str = r.len+#r[k], r.str..r[k]
  end
  return setmetatable(r, mt) --[[@as builder]]
end

---@generic T, U
---@param self builder
---@param does fun(it: piece, k: integer, acc: T): T, U?
---@param init T
---@return T, U?
---@private
function builder.loop(self, does, init)
  local acc, done = init, false
  for k=1,self.n
    do
      acc, done = does(self[k], k, acc)
      if done then return acc, done end
  end
  return acc, done
end

---@param self builder
---@return (string|range)[]
function builder.flatten(self)
  return self:loop(function(it, _, a)
    if getmetatable(it).__index == mt
      then
        local f = it:flatten()
        for k=1,#f do a[#a+1] = f[k] end
      else
        a[#a+1] = it
    end
    return a
  end, {})
end

---@param self builder
---@param i integer
---@param j integer?
---@return builder
function builder.sub(self, i, j)
  local need = (j or self.len)-i+1
  return builder.new(table.unpack(
    self:loop(function(it, _, a)
      local l = #it
      if #it < i
        then
          i = i-l
          return a
      end
      local b = it:sub(i, i+need)
      i, l = 1, #b
      need = need-l
      a[#a+1] = b
      return a, 0 == need
    end, {})
  ))
end

---@param self builder
---@param pattern string
---@param init integer?
---@param plain boolean?
---@return integer start
---@return integer end
function builder.find(self, pattern, init, plain) return self.str:find(pattern, init, plain) end

return builder
