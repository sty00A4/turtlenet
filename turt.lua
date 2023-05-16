-- if term then
--     term.clear()
--     term.setCursorPos(1, 1)
-- end
local turtlenet = require "turtlenet"

local args = {...}
if args[1] == "server" then
    return turtlenet.server.start(args[2])
elseif args[1] == "client" then
    return turtlenet.client.start()
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
            print(epos, err) return
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
            print(epos, err) return
        end
        if type(value) ~= "nil" then print(value) end
    end
elseif args[1] == "gui" then
    return turtlenet.gui.test()
elseif args[1] == "update" then
    fs.delete("turtlenet")
    fs.delete("turt.lua")
    print "Deleted old directory"
    shell.run "pastebin run fizMeZiw" print "Downloaded Turtlenet"
elseif args[1] == nil then
    print "USAGE:"
    print "  turt server - starts as a server"
    print "  turt client [serverID] - starts as a client (if the device is a turtle) and connects to the given server ID"
else
    print(("unknown command %q"):format(args[1]))
end