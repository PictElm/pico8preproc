---@type {decode: fun(s: string): table; encode: fun(t: table): string}
local json = require '3rd/json_lua/json'
local vlq = require 'scripts/text/vlq'
local loc = require 'scripts/text/loc'

---@class smap_m
local smap = {}

---@class sourcemap : smap_m
---@field   version        integer       #spec version
---@field   file           string?       #name of the generated code that this source map is associated with
---@field   sourceRoot     string?       #source root, prepended to the indivitual entries in the `source` field
---@field   sources        string[]      #list of original sources used by the `mappings` field
---@field   sourcesContent (string?)[]?  #list of source content when the `source` can't be hosted
---@field   names          string[]      #list of symbol names used by the `mappings` field
---@field   mappings       string        #string with the encoded mapping data

---@param self sourcemap #sourcemap-like
local function intosourcemap(self)
  ---@class segment
  ---@field   cloc  location   #location in result file
  ---@field   idx   integer?   #index in `sources`
  ---@field   oloc  location?  #location in original source
  ---@field   name  integer?   #index in `names`

  ---@type segment[][]
  local internal
  local intup, mapup = false, false

  local mt
  mt = {
    __index= smap,

    --- ZZZ
    _playground_getinternal= function()
      mt.updateinternal()
      return internal
    end,
    _playground_dumpinternal= function()
      mt.updateinternal()
      for k,v in ipairs(internal)
        do
          print("line "..k)
          for _,it in ipairs(v)
            do
              print(""
                , self.file..':'..it.cloc:repr()
                , it.idx and self:getsourcepath(it.idx)..':'..it.oloc:repr()
                , it.name or ""
                )
          end
      end
    end,

    updatemappings= function()
      if mapup then return end
      local text = ""

      local sep = ''
      for i=1,#internal
        do
          local line = internal[i]
          text = text..sep
          sep = ';'

          local abs_ccol = 0
          local abs_idx = 0
          local abs_oline = 0
          local abs_ocol = 0
          local abs_name = 0

          local sepp = ''
          for j=1,#line
            do
              local segment = line[j]
              text = text..sepp
              sepp = ','

              local rel_ccol = 0
              local rel_idx = 0
              local rel_oline = 0
              local rel_ocol = 0
              local rel_name = 0

              rel_ccol = segment.cloc.column-abs_ccol
              abs_ccol = segment.cloc.column
              if segment.idx
                then
                  rel_idx = segment.idx-abs_idx
                  abs_idx = segment.idx
                  rel_oline = segment.oloc.line-abs_oline
                  rel_ocol = segment.oloc.column-abs_ocol
                  abs_oline = segment.oloc.line
                  abs_ocol = segment.oloc.column
                  if segment.name
                    then
                      rel_name = segment.name-abs_name
                      abs_name = segment.name
                  end
              end

              text = text..vlq.encode(rel_ccol, rel_idx, rel_oline, rel_ocol, rel_name)
          end -- for each segment
      end -- for each line

      self.mappings = text
      mapup = true
    end,

    updateinternal= function()
      if intup then return end

      ---@type segment[][]
      local lines, linecount = {}, 0
      local at, len = 1, #self.mappings
      while at <= len
        do
          local semi = self.mappings:find(';', at) or len+1
          local line = self.mappings:sub(at, semi-1)

          local abs_ccol = 0
          local abs_idx = 0
          local abs_oline = 0
          local abs_ocol = 0
          local abs_name = 0

          ---@type segment[]
          local segments, segmentcount = {}, 0
          local att, lenn = 1, #line
          while att <= lenn
            do
              local comm = line:find(',', att) or lenn+1
              local segment = line:sub(att, comm-1)

              local rel_ccol  -- 0-based starting column of the current line
                  , rel_idx   -- (optional) 0-based index in `sources`
                  , rel_oline -- (optional) 0-based starting line in original source
                  , rel_ocol  -- (optional) 0-based starting column in original source
                  , rel_name  -- (optional) 0-based index in `names`
                = vlq.decode(segment)

              -- TODO: proper throw on invalid? or let the `+` fail?

              ---@type segment
              local it = {cloc= loc.new(linecount, abs_ccol+rel_ccol)}
              abs_ccol = it.cloc.column
              if rel_idx
                then
                  it.idx = abs_idx+rel_idx
                  abs_idx = it.idx
                  it.oloc = loc.new(abs_oline+rel_oline, abs_ocol+rel_ocol)
                  abs_oline = it.oloc.line
                  abs_ocol = it.oloc.column
                  if rel_name
                    then
                      it.name = abs_name+rel_name
                      abs_name = it.name
                  end
              end

              segmentcount = segmentcount+1
              segments[segmentcount] = it
              att = comm+1
          end -- while (loop reading a line off of `mappings`)


          linecount = linecount+1
          lines[linecount] = segments
          at = semi+1
      end -- while (loop reading `mappings`)

      internal = lines
      intup = true
    end,
  }

  return setmetatable(self, mt) --[[@as sourcemap]]
end

-- XXX: if ever, may support
--local indexmap_mt = {__index= m}  (niy)
-- @alias section {offset: location; url: string?; map: sourcemap?}
-- @class indexmap : m
-- @field   version        integer       #spec version
-- @field   file           string?       #name of the generated code that this source map is associated with
-- @field   sections       section[]     #sections with their own sourcemaps (sorted and non-overlapping)

---create a new empty sourcemap object
---@param file string
---@param sourceRoot string
---@return sourcemap
function smap.new(file, sourceRoot)
  return intosourcemap({
    version= 3,
    file= file,
    sourceRoot= sourceRoot,
    sources= {},
    --sourcesContent= {},
    names= {},
    mappings= ""
  })
end

---decode a JSON-encoded source map
---@param jsonstr string
---@return sourcemap? #nil if it was not a valid JSON or not a valid source map
function smap.decode(jsonstr)
  local yes, r = pcall(json.decode, jsonstr)
  if not yes
  or                     'number' ~= type(r.version)
  or r.file and          'string' ~= type(r.file)
  or r.sourceRoot and    'string' ~= type(r.sourceRoot)
  or                      'table' ~= type(r.sources)
  or r.sourcesContent and 'table' ~= type(r.sourcesContent)
  or                      'table' ~= type(r.names)
  or                     'string' ~= type(r.mappings)
    then return nil end
  return intosourcemap(r)
end

---encode the source map into JSON
---@param self sourcemap
---@return string
function smap.encode(self)
  local mt = getmetatable(self)
  assert(smap == mt.__index, "not a sourcemap, don't wanna deal with that")
  mt.updatemappings()
  -- YYY: safe as long as mt has no `__pairs` and no `__len`
  return json.encode(self)
end

---returns the path for the source by its index; the index is assumed to be correct
---@param self sourcemap
---@param idx integer #an index in `sources`
---@return string
function smap.getsourcepath(self, idx)
  local root = self.sourceRoot
  if not root
    then root = ""
  elseif 0 < #root and '/' ~= root:sub(-1)
    then root = root..'/'
  end
  return root..self.sources[idx+1]
end

---returns the content for the source by its index; the index is assumed to be correct
---@param self sourcemap
---@param idx integer #an index in `sources`
---@return string? #nil if the source could not be reached/read
function smap.getsourcecontent(self, idx)
  if self.sourcesContent and self.sourcesContent[idx+1]
    then return self.sourcesContent[idx+1]
  end
  local path = self:getsourcepath(idx)
  -- YYY/ZZZ
  if "http" ~= path:sub(1, 4)
    then
      local file = io.open(path, 'r')
      if not file then return nil end
      local buf = file:read('a')
      file:close()
      return buf
  end
  return nil
end

---transform a location in `file` to its original location in one of `sources` (which is return as its index)
---@param self sourcemap
---@param infile location #location in `file`
---@return location #location in the source
---@return integer #index of the source in `sources`
function smap.forward(self, infile)
  local mt = getmetatable(self)
  mt.updateinternal()
  return mt.forward(infile)
end

---transform a location in a `sources` to its resulting location in `file`
---@param self sourcemap
---@param insource location #location in `file`
---@param idx integer #index in `sources`
---@return location #location in the source
function smap.backward(self, insource, idx)
  local mt = getmetatable(self)
  mt.updateinternal()
  return mt.backward(insource, idx)
end

local function _playground()
  local root = "tests/smap/"
  local name = "helloworld"
  local function readfile(ext, n)
    local f = assert(io.open(root..(n or name).."."..ext))
    ---@type string
    local b = f:read('a')
    f:close()
    return b
  end

  local osource = readfile('coffee')
  local csource = readfile('js')
  local self = assert(smap.decode(readfile('js.map')))

  -- print("self.mappings: _"..self.mappings.."_")
  -- getmetatable(self)._playground_dumpinternal()
  -- print "====="

  ---@type segment[][]
  local internal = getmetatable(self)._playground_getinternal()

  for i=1,#internal
    do
      local segments = internal[i]
      print("line "..i.." ("..#segments.." segment-s):")

      for j=1,#segments-1
        do
          local from = segments[j].cloc:copy():bind(csource)
          local till = segments[j+1].cloc:copy():bind(csource)
          print
            ( "   "..from:repr().."/"..till:repr().."="
            , "_"..from/till.."_"
            )
      end

      local last = segments[#segments].cloc:copy():bind(csource)
      local eol = loc.new(last.line+1, 0, csource)-1
      print
          ( "   "..last:repr().."/"..eol:repr().."="
          , "_"..last/eol.."_"
          )
  end

  -- local infile = {}
  -- local insource, sourceidx = self:forward(infile)
end
_playground()

return smap
