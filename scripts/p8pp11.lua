local m = {
  version= '0.1.1',
  v= 11,
}

-- TODO: not done

local api_functions = { "load", "save", "folder", "files", "run", "resume", "reboot", "stat", "flip", "clip", "pget", "pset", "sget", "sset", "fget", "fset", "print", "cursor", "color", "cls", "camera", "circ", "circfill", "line", "rect", "rectfill", "pal", "palt", "spr", "sspr", "add", "del", "all", "foreach", "count", "btn", "btnp", "sfx", "music", "mget", "mset", "map", "peek", "poke", "memcpy", "reload", "cstore", "memset", "max", "min", "mid", "flr", "cos", "sgn", "atan2", "sqrt", "abs", "rnd", "seed", "band", "bor", "bxor", "bnot", "bshl", "bshr" };
for k=1,#api_functions
  do api_functions[api_functions[k]] = true
end

---@param src string
---@return string
---@return number|string
---@return string
local function lex(src)
  local ident = ""

  local s = src:find("[^ \t]")

  local function su(o) return src:sub(s, o and s+o-1) end
  local function ma(t) return src:match("^"..t, s) end
  local function ret(skip, tok) return skip and src:sub(s+skip) or "", tok, ident end

  if not s then return ret(nil, -1000) end

  if "--" == su(2)
    then
      local t = ma("--[^\n]*\n")
      return ret(t and #t-1, -995)
  end

  if ma("[^A-Za-z]")
    then
      if ma("[0-9]")
        then
          ident = ma("[0-9x.]+")
          return ret(#ident, -997)
      end

      do
        local q = ma("[\"']")
        if q
          then
            ident = ma(q..".*"..q)
            return ret(#ident, -996)
        end
      end

      local c = su(1)
      if ':' == c or '\n' == c
        then return ret(1, -999)
      end

      local cc = su(2)
      if "//" == cc
        then
          local t = ma("//[^\n]*\n")
          return ret(t and #t-1, -999)
      end
      local is2 = ({
        ["<="]= -969,
        [">="]= -968,

        ["<>"]= -966, ["~="]= -966, ["!="]= -966,
        ["=="]= -965,
        ["+="]= -964,
      })[cc]
      if is2
        then return ret(2, is2)
      end

      return ret(1, c)
  end

  ident = ma("[A-Za-z0-9_]+")

  local tok = ({
    ["function"]= -993,
    ["end"]=      -992, ["endif"]= -992, ["next"]= -992,
    ["for"]=      -991,
    ["if"]=       -990,
    ["then"]=     -989,
    ["else"]=     -988,
    ["elseif"]=   -987,
    ["while"]=    -986,
    ["do"]=       -985,
    ["local"]=    -984,
    ["return"]=   -983,
    ["repeat"]=   -982,
    ["until"]=    -981,
    ["goto"]=     -980,
    ["break"]=    -979,

    ["not"]=      -975,
    ["and"]=      -974,
    ["or"]=       -973,
  })[ident]

  -- the '.' check is just used for syntax highlight, so ok to ignore here
  if --[['.' ~= prev and]] api_functions[ident]
    then tok = -978
  end

  return ret(#ident, tok or -998)
end

---pico8_preprocess()
---@param source string
---@return string
function m.pp(source)
  if true then
    local tok, ident
    repeat
      source, tok, ident = lex(source)
      print(tok, ident)
    until -1000 == tok
    return "(niy)"
  end

  local result = ""

  local maxIter = 16000
  local cursor = 1

  repeat
    local lnend = source:find('\n', cursor)
    local ln = source:sub(cursor, lnend)

    local at
    repeat
      at = ln:find('%!=')
        or ln:find('%+=')
        or ln:find('%-=')
        or ln:find('%*=')
        or ln:find('%/=')
        or ln:find('%%=')
      if not at then break end
      local c = ln:sub(at, at)
      if '!' == c
        then ln = ln:sub(1, at-1).."~"..ln:sub(at+1)
        else
          local backw = ln:sub(1, at-1):reverse()
          local a, b = backw:find("%S+")
          ln = backw:sub(a):reverse().." = "..backw:sub(a, b):reverse().." "..c.." "..ln:sub(at+2)
      end
    until nil

    at = ln:find("if[( ]")
    if at and (1 == at or '\n' == ln:sub(at-1, at-1) or ' ' == ln:sub(at-1, at-1)) and not ln:find("then")
      then
        local depth, op, cl = 1, ln:find("%(", at)
        while cl and 0 < depth
          do
            cl = ln:find("[()]", cl+1)
            if cl and '(' == ln:sub(cl, cl)
              then depth = depth+1
              else depth = depth-1
            end
        end
        if cl
          then ln = ln:sub(1, op-1)..ln:sub(op, cl).." then "..ln:sub(cl+1).." end"
        end
    end

    result = result..ln

    if not lnend then break end
    cursor = lnend+1
    maxIter = maxIter-1
  until 0 == maxIter

  return result
end

return m
