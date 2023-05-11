local log = require "turtlenet.apps.server.log"
local client = require "turtlenet.apps.server.client"
local transform = require "turtlenet.apps.server.transform"

---@param turtInfo table
---@param turt Client
---@return TurtleInfo
local function turtleInfo(turtInfo, turt)
    if type(turtInfo) ~= "table" then turtInfo = {} end
    turtInfo.x = turtInfo.x or turt.transform.position.x
    turtInfo.y = turtInfo.y or turt.transform.position.y
    turtInfo.z = turtInfo.z or turt.transform.position.z
    turtInfo.direction = turtInfo.z or turt.transform.direction
    turtInfo.inventory = turtInfo.inventory or turt.inventory
    turtInfo.fuel = turtInfo.fuel or turt.fuel
    return turtInfo
end

local Server = {
    mt = {
        __name = "server"
    }
}
---@return Server
function Server.new()
    return setmetatable(
        ---@class Server
        {
            ---@type table<integer, Client>
            clients = {},
            log = log.Log.new(),
            running = false,
            ---@type table<integer, boolean>
            blockedIds = {},
            ---@type table<string, table<integer, string>>
            events = {},

            client = Server.client, addClient = Server.addClient,
            blocked = Server.blocked,
            listen = Server.listen, interface = Server.interface, eventListener = Server.eventListener,
            run = Server.run
        },
        Server.mt
    )
end

---@param self Server
---@param id integer
---@return Client|nil
function Server:client(id)
    return self.clients[id]
end
---@param self Server
---@param id integer
---@param client Client
function Server:addClient(id, client)
    if self:client(id) then
        self.log:push("error", ("%s already exists"):format(client), "server.Server.addClient")
    else
        self.clients[id] = client
    end
end
---@param self Server
---@param id integer
---@return Client|nil
function Server:removeClient(id)
    local client = table.remove(self.clients, id)
    if client then
        return client
    else
        self.log:push("error", ("Client#%s doesn't exist"):format(id), "server.Server.removeClient")
    end
end

---@param self Server
---@param id integer
function Server:block(id)
    self.blockedIds[id] = true
    self.log:push("info", ("Client#%s blocked"):format(id))
end
---@param self Server
---@param id integer
function Server:blocked(id)
    return self.blockedIds[id]
end

---@param self Server
function Server:listen()
    ---@diagnostic disable-next-line: undefined-field
    local name = "Server#"..tostring(os.getComputerID())
    rednet.host(NET_PROTOCOL, name)
    self.running = true
    while self.running do
        local id, msg = rednet.receive(NET_PROTOCOL, SERVER_TIMEOUT)
        if id then
            if not self:blocked(id) then
                if type(msg) == "table" then
                    if msg.head == "register" then
                        local client = client.Client.new(id, transform.Transform.zero())
                        self.log:push("info", ("%s is registered"):format(client), "server.Server.listen")
                        self:addClient(id, client)
                        rednet.send(id, true)
                    elseif msg.head == "info" then
                        local client = self:client(id)
                        if client then
                            msg = turtleInfo(msg, client)
                            client.transform.position.x = msg.x
                            client.transform.position.y = msg.y
                            client.transform.position.z = msg.z
                            client.transform.direction = msg.direction
                            client.inventory = msg.inventory
                            client.fuel = msg.fuel
                        end
                    elseif msg.head == "task" then
                        if msg.status == "request" then
                            local client = self:client(id)
                            if client then
                                rednet.send(id, table.remove(client.tasks), NET_PROTOCOL)
                            else
                                self.log:push("info", ("unregistered computer #%s is trying to request a task"), "server.Server.listen")
                            end
                        end
                    end
                end
            end
        end
        self = coroutine.yield(true)
    end
    rednet.unhost(NET_PROTOCOL, name)
end
---@param self Server
function Server:eventListener()
    term.clear()
    term.setCursorPos(1, 1)
    while true do
        ---@diagnostic disable-next-line: undefined-field
        table.insert(self.events, { os.pullEvent() })
    end
end
---@param self Server
function Server:interface()
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        for id, client in ipairs(self.clients) do
            print(id, client:tostring())
        end
        local clientsSize = #self.clients
        while #self.events == 0 and #self.clients == clientsSize do
            coroutine.yield()
            print "waiting" --- dont yeidl
        end
        -- handle changes
    end
end

local function start()
    local server = Server.new()
    parallel.waitForAll(function()
        server:listen()
    end, function()
        server:eventListener()
    end, function()
        server:interface()
    end)
end

return {
    Server = Server,
    start = start
}