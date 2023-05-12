local transform = require "turtlenet.apps.server.transform"
local log = require "turtlenet.apps.server.log"
local gui = require "turtlenet.gui"
local picolua = require "turtlenet.picolua"

local Item = {
    mt = {
        __name = "item",
        ---@param self Item
        __tostring = function (self)
            return ("%s x %s"):format(self.name, self.count)
        end
    }
}
---@param name string
---@param count integer
function Item.new(name, count)
    return setmetatable(
        ---@class Item
        {
            name = name, count = count,
            tostring = Item.mt.__tostring
        },
        Item.mt
    )
end
---@param t table|nil
---@return Item|nil
function Item.from(t)
    if not t then return nil end
    t.name = t.name or "?"
    t.count = t.count or 0
    return Item.new(t.name, t.count)
end
---@alias Inventory table<integer, Item|nil>

local Turtle = {
    mt = {
        __name = "turtle"
    }
}
function Turtle.init()
    if not turtle then error("computer needs to be a turtle", 2) end
    ---@type Turtle
    local turt = setmetatable(
        ---@class Turtle
        {
            transform = transform.Transform.default(),
            log = log.Log.new(),
            ---@type Tasks
            tasks = {},
            ---@type ClientStatus
            status = "idle",
            registered = false,
            ---@type integer|nil
            serverId = nil,
            ---@type Inventory
            inventory = {},
            fuel = turtle.getFuelLevel(),

            update = Turtle.update,
            updateInventory = Turtle.updateInventory, updateFuel = Turtle.updateFuel,

            forward = Turtle.forward, back = Turtle.back,
            up = Turtle.up, down = Turtle.down,
            left = Turtle.left, right = Turtle.right,

            register = Turtle.register, listen = Turtle.listen, toInfo = Turtle.toInfo,

            gui = Turtle.gui
        },
        Turtle.mt
    )
    turt:updateInventory()
    return turt
end

---@param self Turtle
function Turtle:update()
    self:updateFuel()
    self:updateInventory()
end
---@param self Turtle
function Turtle:updateInventory()
    local currentSlot = turtle.getSelectedSlot()
    for i = 1, 16 do
        turtle.select(i)
        self.inventory[i] = Item.from(turtle.getItemDetail())
    end
    turtle.select(currentSlot)
end
---@param self Turtle
function Turtle:updateFuel()
    self.fuel = turtle.getFuelLevel()
end
---@param self Turtle
---@return TurtleInfo
function Turtle:toInfo()
    ---@class TurtleInfo
    return {
        head = "info",
        x = self.transform.position.x,
        y = self.transform.position.y,
        z = self.transform.position.z,
        direction = self.transform.direction,
        inventory = self.inventory,
        fuel = self.fuel,
        status = self.status
    }
end

---@param self Turtle
function Turtle:forward()
    local success, msg = turtle.forward()
    if success then
        self.transform:forward()
    else
        self.log:push("error", msg, "Turtle.forward")
    end
end
---@param self Turtle
function Turtle:back()
    local success, msg = turtle.back()
    if success then
        self.transform:back()
    else
        self.log:push("error", msg, "Turtle.back")
    end
end
---@param self Turtle
function Turtle:up()
    local success, msg = turtle.up()
    if success then
        self.transform:up()
    else
        self.log:push("error", msg, "Turtle.up")
    end
end
---@param self Turtle
function Turtle:down()
    local success, msg = turtle.down()
    if success then
        self.transform:down()
    else
        self.log:push("error", msg, "Turtle.down")
    end
end
---@param self Turtle
function Turtle:left()
    local success = turtle.turnLeft()
    if success then
        self.transform:left()
    else
        self.log:push("error", "couldn't turn", "Turtle.left")
    end
end
---@param self Turtle
function Turtle:right()
    local success = turtle.turnRight()
    if success then
        self.transform:right()
    else
        self.log:push("error", "couldn't turn", "Turtle.right")
    end
end

---@param self Turtle
---@return boolean
function Turtle:register()
    if not self.serverId then gui.prompt.info "no server ID provided" return false end
    rednet.send(self.serverId, { head = "register" }, NET_PROTOCOL)
    local recvId, success = nil, false
    local tries = 1
    while recvId ~= self.serverId do
        recvId, success = rednet.receive(NET_PROTOCOL, CLIENT_TIMEOUT)
        tries = tries + 1
        if tries > 5 then break end
    end
    self.registered = success
    return success
end
---@param self Turtle
function Turtle:listen()
    while self.registered do
        local recvId, program
        while recvId ~= self.serverId do
            recvId, program = rednet.receive(NET_PROTOCOL, CLIENT_TIMEOUT)
        end
        os.queueEvent("update")
        if type(program) == "table" then
            ---@type Program
            program = program
            local file = picolua.location.File.new(program.file.path)
            local compiler = picolua.compiler.Compiler.new(file)
            compiler.code = program.code
            compiler.consts = program.consts
            local program = picolua.program.Program.new(file, picolua.compiler.Compiler.new(file))
            local infoTimer = os.time()
            while true do
                program:step()
                if os.time() - infoTimer >= 1 then
                    os.queueEvent("update")
                    if self.serverId then rednet.send(self.serverId, self:toInfo()) end
                    infoTimer = os.time()
                end
            end
        end
        if self.serverId then rednet.send(self.serverId, self:toInfo()) end
    end
end
---@param self Turtle
function Turtle:gui()
    local W, H = term.getSize()
    local connectPage = gui.GUI.new {
        gui.input.Input.new {
            id = "connect.input",
            x = math.floor(W / 2 - 6), y = math.floor(H / 2 - 1),
            empty = "server id..."
        },
        gui.button.Button.new {
            id = "connect.button", label = "connect",
            x = math.floor(W / 2 - 3), y = math.floor(H / 2 + 1),
            key = keys.enter,
            ---@param page GUI
            onClick = function (_, page, window)
                local id = tonumber(page:getElementById("connect.input").input)
                if not id then return gui.prompt.info("server id is not a number") end
                self.serverId = id
                page.running = false
            end
        }
    }
    local connectingPage = gui.GUI.new {
        gui.text.Text.new {
            id = "connecting.text", text = "connecting...",
            x = math.floor(W / 2 - 7), y = math.floor(H / 2),
            update = function (_, page, window)
                self:register()
                if not self.registered then gui.prompt.info("couldn't connect to #"..tostring(self.serverId)) end
                page.running = false
            end
        }
    }
    local mainPage = gui.GUI.new {
        gui.text.Text.new {
            id = "main.text", text = "main app",
            fg = colors.lime,
            x = math.floor(W / 2 - 4), y = math.floor(H / 2),
        }
    }
    while not self.registered do
        connectPage:run()
        connectingPage:draw()
        connectingPage:run()
    end
    parallel.waitForAny(function ()
        while self.serverId do
            if self.registered then
                mainPage:run()
            end
            connectingPage:run()
        end
    end, function ()
        self:listen()
    end)
    term.clear()
    term.setCursorPos(1, 1)
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
    rednet.open("back")
    if not turtle then
        turtle = {
            ---@return number
            getFuelLevel = function() return 0 end,
            ---@return integer
            getSelectedSlot = function() return 1 end,
            ---@param i integer
            select = function(i) end,
            ---@return table|nil
            getItemDetail = function() end,
            ---@return boolean, string|nil
            forward = function() return false, "not a turtle" end,
            ---@return boolean, string|nil
            back = function() return false, "not a turtle" end,
            ---@return boolean, string|nil
            up = function() return false, "not a turtle" end,
            ---@return boolean, string|nil
            down = function() return false, "not a turtle" end,
            ---@return boolean
            turnLeft = function() return false end,
            ---@return boolean
            turnRight = function() return false end,
        }
    end
    local turtle = Turtle.init()
    turtle:gui()
end

return {
    Turtle = Turtle,
    start = start,
}