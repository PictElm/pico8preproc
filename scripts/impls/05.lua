return require 'scripts/impls/common' .new("05", function(log, r)
  log "entering"

  local builder = require 'scripts/text/builder'
  local maxIter = 16000

  repeat
    local eol = r:toeol()+1
    local ln = builder.new(r.read%eol)

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
      if '!' == tostring(c)
        then
          ln = builder.new(ln:sub(1, at-1), "~", ln:sub(at+1))
        else
          local forw = tostring(ln:sub(1, at-1))
          local sa = at-1
          while 1 < sa and ' ' == forw:sub(sa, sa) do sa = sa-1 end
          local so = sa
          while 1 < so and ' ' ~= forw:sub(so, so) and '\t' ~= forw:sub(so, so) do so = so-1 end
          ln = builder.new(ln:sub(1, so), " = ", ln:sub(sa, so), " ", c, " ", ln:sub(at+2))
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
          then ln = builder.new(ln:sub(1, op-1), ln:sub(op, cl), " then ", ln:sub(cl+1), " end")
        end
    end

    local f = ln:flatten()
    log(nil, table.unpack(f))
    r:append(table.unpack(f))

    if r:iseof() then break end -- YYY: could move above
    r.read = eol
    maxIter = maxIter-1
  until 0 == maxIter

  log "leaving"
end)
