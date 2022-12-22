local common = require 'scripts/impls/common'

return common.new(function(txt)
  print(type(txt))
  assert(nil, 'niy')
end)
