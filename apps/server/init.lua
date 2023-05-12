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
    if self.clients[id] then
        self.log:push("error", ("%s already exists"):format(client), "server.Server.addClient")
        return false
    else
        self.clients[id] = client
        return true
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
---@param content any
---@return Client|nil
function Server:transmit(id, content)
    local client = self:client(id)
    if client then
        ---@diagnostic disable-next-line: undefined-field
        rednet.send(os.getComputerID(), {head = "transmit", id = id, content = content}, NET_PROTOCOL)
    else
        self.log:push("error", ("trying to transmit message to unregistered client #%s"):format(id), "server.Server.sendClient")
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
    local computerID = os.getComputerID()
    local hostName = "Server#"..tostring(computerID)
    rednet.host(NET_PROTOCOL, hostName)
    self.running = true
    self.log:push("debug", "started as "..hostName)
    while self.running do
        local id, msg = rednet.receive(NET_PROTOCOL, SERVER_TIMEOUT)
        if id then
            if id == computerID then
                if msg.head == "transmit" then
                    rednet.send(msg.target, msg.content, NET_PROTOCOL)
                end
            elseif not self:blocked(id) then
                if type(msg) == "table" then
                    if msg.head == "register" then
                        local success = self:addClient(id, client.Client.new(id, transform.Transform.default()))
                        rednet.send(id, success, NET_PROTOCOL)
                        if success then self.log:push("info", ("registered client #%s"):format(id), "server.Server.listen") end
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
                            client.status = msg.status
                        else
                            self.log:push("info", ("unregistered computer #%s is trying to send info"):format(id), "server.Server.listen")
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
                    else
                        self.log:push("info", ("#%s sent unknown request: %q (type %s)"):format(id, msg.head, type(msg.head)), "server.Server.listen")
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
        return gui.Button.new {
            label = ("%s: %s"):format(id, name),
            onClick = function (_, gui, page, window)
                local client = self.clients[id]
                if client then
                    client:gui(self, window)
                end
            end
        }
    end
    ---@param msg Message
    local function newMsg(msg, id)
        return gui.Text.new {
            id = id, h = 2,
            text = msg:tostring(),
            w = W / 2,
            fg = msg.type == "error" and (colors.red or colors.white) or colors.white
        }
    end
    
    local main = gui.Page.new {
        gui.Text.new {
            w = W / 2, h = 1,
            text = "CLIENTS:"
        },
        gui.List.new {
            id = "clients",
            y = 2,
            w = math.floor(W / 2), h = H - 1,
            list = {},
            ---@param list Element|List
            update = function (list, gui, page, window)
                list.list = {}
                for id, client in pairs(self.clients) do
                    table.insert(list.list, newClient(id, client:tostring()))
                end
                if #list.list > list.h then list.scroll = #list.list - list.h end
            end
        },
        gui.List.new {
            id = "logs",
            x = math.ceil(W / 2), y = 2,
            w = math.floor(W / 2), h = H - 1,
            list = {},
            ---@param list Element|List
            update = function (list, gui, page, window)
                list.list = {}
                for id, msg in pairs(self.log.log) do
                    table.insert(list.list, newMsg(msg, "message_"..id))
                end
            end,
        }
    }
    local interface = gui.GUI.new {
        main = main
    }
    interface:run()
end

local function start()
    if ccemux then
        ccemux.detach("back")
        ccemux.attach("back", "wireless_modem", {
            range = 1000,
            world = "main",
            interdimensional = false,
            posX = 0, posY = 10, posZ = 0
        })
    end
    local modem = peripheral.find("modem")
    if not modem then error("no modem connected") end
    modem.open(64)
    peripheral.find("modem", rednet.open)
    local server = Server.new()
    parallel.waitForAny(function()
        server:listen()
    end, function()
        server:gui()
    end)
    term.clear()
    term.setCursorPos(1, 1)
end

return {
    Server = Server,
    start = start
}