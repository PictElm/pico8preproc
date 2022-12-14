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
local function next(src)
  local ident = ""

  local s = src:find("[^ %t]")
  if not s then return "", -1000, "" end

  local function su(o) return src:sub(s, o and s+o-1) end
  local function ret(skip, tok) return src:sub(s+skip), tok, ident end

  if "--" == su(2)
    then return ret((su():find('%n', s) or #su()+1)-1, -995)
  end

  if src:match("^[^A-Za-z]", s) -- to test in truepp: how does it deal with idents starting with '_' again?
    then
      if print 'niy: /[0-9]/' -- need to play around with it (seems it also accepts 0x and decimal, how hard can it be to implement?)
        then
          ident = "the literal itself"
          return ret(42, -997)
      end

      if print 'niy: string' -- same as above, but doesnt look like it handes escaping quotes...
        then
          ident = "the string itself (with quotes)"
          return ret(42, -996)
      end

      if ':' == su(1) or '\n' == su(1)
        then return ret(1, -999)
      end

      print 'niy: <=>~!+-*/% (both <op>= and <op>)'
  end

  print 'niy: scan word (ident/kw)'
  ident = "coucou"

  local map = {
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
  }
  local tok = map[ident]

  if not first_char and '.' ~= prev and api_functions[ident]
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
      source, tok, ident = next(source)
      print(tok, ident)
    until -1000 == tok
    return "niy"
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
    if at and not ln:find("then")
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
          then ln = ln:sub(1, at+2)..ln:sub(op, cl).." then "..ln:sub(cl+1).." end"
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
