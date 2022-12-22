local vers = require 'scripts/vers'

---@param version version
---@return preproc
return function(version)
  return (require('scripts/impls/'..vers.short[version]))
end
