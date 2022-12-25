---@class builder_m
---@field private len integer
---@field private count integer
local builder = {}

---@alias piece string|range|builder

local mt = {
  __index= builder,

  ---@param self builder
  __tostring= function(self) return self:loop(function(it, _, a) return a..tostring(it) end, "") end,

  ---@param self builder
  ---@return integer
  __len= function(self) return self:loop(function(it, _, a) return a..#it end, 0) end,

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
  local t = table.pack(...)
  local r = {len= 0, count= t.n}
  for k=1,#t.n
    do
      local ll = #t[k]
      r[k] = {t[k], ll}
      r.len = r.len+ll
  end
  return setmetatable(r, mt) --[[@as builder]]
end

---@generic T, U
---@param self builder
---@param does fun(it: piece, k: integer, acc: T): T, U?
---@param init T
---@return T, U?
function builder.loop(self, does, init)
  local acc, done = init, false
  for k=1,self.count
    do
      acc, done = does(self[k], k, acc)
      if done then return acc, done end
  end
  return acc, done
end

---@param self builder
---@return (string|range)[]
function builder.flat(self)
  return self:loop(function(it, _, a)
    if getmetatable(it).__index == mt
      then
        local f = it:flat()
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
function builder.find(self, pattern, init, plain)
  return assert(nil, 'niy')
end

return builder
