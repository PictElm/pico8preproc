local common = require 'scripts/impls/common'

return common.new("11", function(log, txt)
  log(type(txt))
  assert(nil, 'niy')
end)
