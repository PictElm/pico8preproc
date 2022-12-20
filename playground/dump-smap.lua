local file = assert(io.open(assert(arg[1], "no file given"), 'rb'), "could not open file")
getmetatable(require('scripts/text/smap').decode(file:read('a')))._playground_dumpinternal()
file:close()
