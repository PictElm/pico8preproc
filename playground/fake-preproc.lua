---does `\s*?something\n` -> `\s*print(something)\n` and comments out anything else
require 'scripts/impls/common' .new(function(r)
  repeat
    local eol = r:toeol()

    local at, len = (r.read/eol):find('%s*%?')
    if at
      then
        local arg = r.read:copy()+at-1+len
        r:append(r.read%(arg:copy()-1), "print(", arg%eol, ")\n")
      else
        r:append("--", r.read%eol, "\n")
    end

    r.read = eol+1
  until r:iseof()
end)(require 'scripts/args' (arg))
