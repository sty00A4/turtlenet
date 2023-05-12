local log = require "turtlenet.apps.server.log"
local client = require "turtlenet.apps.server.client"
local transform = require "turtlenet.apps.server.transform"
local gui = require "turtlenet.gui"

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
            listen = Server.listen, gui = Server.gui, eventListener = Server.eventListener,
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
    local hostName = "Server#"..tostring(os.getComputerID())
    rednet.host(NET_PROTOCOL, hostName)
    self.running = true
    while self.running do
        local id, msg = rednet.receive(NET_PROTOCOL, SERVER_TIMEOUT)
        if id then
            if not self:blocked(id) then
                if type(msg) == "table" then
                    if msg.head == "info" then
                        local client = self:client(id) or client.Client.new(id, transform.Transform.default())
                        if client then
                            msg = turtleInfo(msg, client)
                            client.transform.position.x = msg.x
                            client.transform.position.y = msg.y
                            client.transform.position.z = msg.z
                            client.transform.direction = msg.direction
                            client.inventory = msg.inventory
                            client.fuel = msg.fuel
                            client.status = msg.status
                        end
                    elseif msg.head == "task" then
                        if msg.status == "request" then
                            local client = self:client(id)
                            if client then
                                rednet.send(id, table.remove(client.tasks), NET_PROTOCOL)
                            else
                                self.log:push("info", ("unregistered computer #%s is trying to request a task"):format(id), "server.Server.listen")
                            end
                        end
                    end
                end
            end
        end
    end
    rednet.unhost(NET_PROTOCOL, hostName)
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
function Server:gui()
    local W, H = term.getSize()
    local function newClient(id, name)
        return gui.button.Button.new {
            label = ("%s: %s"):format(id, name),
            onClick = function (_, page, window)
                local client = self.clients[id]
                if client then
                    client:gui(self, window)
                end
            end
        }
    end
    local listPage = gui.GUI.new {
        gui.text.Text.new {
            w = W / 2, h = H,
            text = "CLIENTS:",
            update = function (_, page, window)
                ---@type Element|List
                local listE = page:getElementById("list") if listE then
                    listE.list = {}
                    for id, client in pairs(self.clients) do
                        table.insert(listE.list, newClient(id, client:tostring()))
                    end
                end
            end
        },
        gui.list.List.new {
            y = 2,
            w = W / 2, h = H - 1,
            list = {},
            ---@param list Element|List
            update = function (list, page, window)
                list.list = {}
                for id, client in pairs(self.clients) do
                    table.insert(list.list, newClient(id, client:tostring()))
                end
            end
        }
    }
    listPage:run()
end

local function start()
    local server = Server.new()
    parallel.waitForAll(function()
        server:listen()
    end, function()
        server:gui()
    end)
end

return {
    Server = Server,
    start = start
}