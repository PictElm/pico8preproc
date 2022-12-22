local app = 'n.i.y'

---@alias version
---| '0.0.5'
---| '0.1.0'
---| '0.1.1'

---@type {[1]:version, [2]:string}[]
local sorted = {
  {'0.0.5', '05'},
  {'0.1.0', '05'},
  {'0.1.1', '11'},
}
---@type table<version, string>
local short = {}
for k=1,#sorted do short[sorted[k][1]] = sorted[k][2] end
---@type version
local default = sorted[#sorted][1]

return {
  app= app,
  sorted= sorted,
  short= short,
  default= default,
}
