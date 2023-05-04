local turtlenet = require "turtlenet"

local args = {...}
if args[1] == "server" then
    return turtlenet.server.start()
elseif args[1] == "client" then
    if not turtle then print("computer needs to be a turtle to be a client") return end
    local idString = args[2]
    if not idString then print("expected the server's ID after \"client\"") return end
    local id = tonumber(idString)
    if not id then print("expected the server's ID as a number, got \""..idString.."\"") return end
    return turtlenet.client.start(id)
else
    print "USAGE:"
    print "  turt server - starts as a server"
    print "  turt client [serverID] - starts as a client (if the device is a turtle) and connects to the given server ID"
end