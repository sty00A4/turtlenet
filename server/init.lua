local log = require "turtlenet.log"

local Server = {
    mt = {
        __name = "server"
    }
}
---@param handleRequests table<string, function>
---@return Server
function Server.new(handleRequests)
    return setmetatable(
        ---@class Server
        {
            handleRequests = handleRequests,

            ---@type table<integer, Client>
            clients = {},
            log = log.Log.new(),
            running = false,
            ---@type table<integer, boolean>
            blockedIds = {},

            client = Server.client, addClient = Server.addClient,
            blocked = Server.blocked
        }
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
        self.log:push("error", ("%s already exists"):format(client), os.clock(), "server.Server.addClient")
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
        self.log:push("error", ("Client#%s doesn't exist"):format(id), os.clock(), "server.Server.removeClient")
    end
end

---@param self Server
---@param id integer
function Server:block(id)
    self.blockedIds[id] = true
end
---@param self Server
---@param id integer
function Server:blocked(id)
    return self.blockedIds[id]
end

---@param self Server
function Server:run()
    local name = "Server#"..tostring(os.getComputerID())
    rednet.host(NET_PROTOCOL, name)
    self.running = true
    while self.running do
        local id, msg = rednet.receive(NET_PROTOCOL, SERVER_TIMEOUT)
        if id then
            if not self:blocked(id) then
                local handle = self.handleRequests[msg]
                if handle then
                    handle(self, id)
                end
            end
        end
    end
    rednet.unhost(NET_PROTOCOL, name)
end

return {
    Server = Server
}