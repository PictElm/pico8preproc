local vlq = {}

local b64a = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64d, b64e = {}, {}
for k=0,63
  do
    local c = b64a:sub(k+1, k+1)
    b64d[c], b64e[k] = k, c
end

---@param ... integer
---@return string
function vlq.encode(...)
  local r = ""
  local l = table.pack(...)
  for k=1,l.n
    do
      local n = l[k]
      local sign = n < 0
      if sign then n = -n end
      local s = b64e[(15 < n and 32 or 0) | (n & 15) << 1 | (sign and 1 or 0)]
      n = n >> 4
      while 0 ~= n -- TODO: move this below to next iteration (if that makes sense..)
        do s, n = s..b64e[(31 < n and 32 or 0) | n & 31], n >> 5
      end
      r = r..s
  end
  return r
end

---@param s string
---@return integer ...
function vlq.decode(s)
  local r = {}
  local at, last = 1, b64d[s:sub(1, 1)]
  while last
    do
      local sign, n, shft = 1 - ((last&1)<<1), last >> 1, 4
      at = at+1
      while 31 < last and at <= #s
        do
          last = b64d[s:sub(at, at)]
          n, at, shft = (last&31) << shft | n, at+1, shft+5
      end
      r[#r+1] = sign*n
      last = b64d[s:sub(at, at)]
  end
  return table.unpack(r) --, at
end

return vlq
