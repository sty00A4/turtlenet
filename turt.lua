-- if term then
--     term.clear()
--     term.setCursorPos(1, 1)
-- end
local turtlenet = require "turtlenet"

local args = {...}
if args[1] == "server" then
    return turtlenet.server.start()
elseif args[1] == "client" then
    if not turtle then print "computer needs to be a turtle to be a client" return end
    local idString = args[2]
    if not idString then print "expected the server's ID after \"client\"" return end
    local id = tonumber(idString)
    if not id then print("expected the server's ID as a number, got \""..idString.."\"") return end
    return turtlenet.client.start(id)
elseif args[1] == "picolua" then
    if args[2] == "debug" then
        local path = args[3] if not path then
            print "expected path after \"picolua debug\""
            return
        end
        return turtlenet.picolua.debug(path)
    end
    local path = args[2] if not path then
        print "expected path after \"picolua\""
        return
    end
    local targetPath = args[3]
    if targetPath then
        local compiler, err, epos = turtlenet.picolua.compile(path) if err then
            print(err) return
        end
        if not compiler then return end
        local file = io.open(targetPath, "wb")
        if not file then
            print(("cannot open target path %q"):format(targetPath)) return
        end
        file:write(string.char(table.unpack(compiler.code)))
        file:close()
        print(("successfully compiled %q to %q!"):format(path, targetPath))
    else
        local value, err, epos = turtlenet.picolua.run(path) if err then
            print(err) return
        end
        if type(value) ~= "nil" then print(value) end
    end
elseif args[1] == nil then
    print "USAGE:"
    print "  turt server - starts as a server"
    print "  turt client [serverID] - starts as a client (if the device is a turtle) and connects to the given server ID"
else
    print(("unknown command %q"):format(args[1]))
end