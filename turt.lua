if term then
    term.clear()
    term.setCursorPos(1, 1)
end
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
    local path = args[2] if not path then
        print "expected path after \"picolua\""
        return
    end
    local value, err, epos = turtlenet.picolua.run(path) if err then
        print(err) return
    end
    if type(value) ~= "nil" then print(value) end
elseif args[1] == nil then
    print "USAGE:"
    print "  turt server - starts as a server"
    print "  turt client [serverID] - starts as a client (if the device is a turtle) and connects to the given server ID"
else
    print(("unknown command %q"):format(args[1]))
end