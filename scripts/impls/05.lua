return require 'scripts/impls/common' .new(function(r)
  local maxIter = 16000

  repeat
    local eol = r:toeol()
    local ln = r.read/eol

    local at
    local sb = {ln}
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
        then
          ln = ln:sub(1, at-1).."~"..ln:sub(at+1)
          -- sb = {sb:sub(1, at-1), "~", sb:sub(at+1)}
        else
          local backw = ln:sub(1, at-1):reverse()
          local a, b = backw:find("%S+")
          -- TODO: translate to indices in 'forward' ln
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
end)
