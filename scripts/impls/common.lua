local text = require 'scripts/text'

local common_m = {}
---@class preproc
---@operator call(options): nil

---@param does fun(text: text, opts: options)
---@return preproc
function common_m.new(does)
  return setmetatable({}, {
    ---@param _ preproc #(self)
    ---@param opts options
    __call= function(_, opts)
      local rexr = text.new(opts.root, opts.outfile, opts.infile)
      does(rexr, opts)
      rexr:flush(opts.outfile, opts.sourcemap)
    end
  })
end

return common_m
