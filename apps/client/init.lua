local transform = require "turtlenet.apps.server.transform"
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
---@param t table
---@return Item
function Item.from(t)
    t.name = t.name or "?"
    t.count = t.count or 0
    return Item.new(t.name, t.count)
end
---@alias Inventory table<integer, Item>

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
    for i = 1, 16 do
        self.inventory[i] = Item.from(turtle.getItemDetail(i))
    end
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
    turtle.forward()
    self.transform:forward()
end
---@param self Turtle
function Turtle:back()
    turtle.back()
    self.transform:back()
end
---@param self Turtle
function Turtle:up()
    turtle.up()
    self.transform:up()
end
---@param self Turtle
function Turtle:down()
    turtle.down()
    self.transform:down()
end
---@param self Turtle
function Turtle:left()
    turtle.turnLeft()
    self.transform:left()
end
---@param self Turtle
function Turtle:right()
    turtle.turnRight()
    self.transform:right()
end

---@param self Turtle
---@return boolean
function Turtle:register()
    if not self.serverId then gui.prompt.info "no server ID provided" return false end
    rednet.send(self.serverId, { head = "register" })
    local recvId, success
    while recvId ~= self.serverId do
        recvId, success = rednet.receive(NET_PROTOCOL)
    end
    self.registered = success
    return success
end
---@param self Turtle
function Turtle:listen()
    while true do
        while not self.registered do end
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
end
---@param self Turtle
function Turtle:gui()
    local W, H = term.getSize()
    local connectPage = gui.GUI.new {
        gui.input.Input.new {
            id = "connect.input",
            x = math.floor(W / 2 - 6), y = math.floor(H / 2 - 1),
            w = 12, empty = "server id..."
        },
        gui.input.Button.new {
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
    connectPage:run()
    while true do
        connectingPage:run()
        if self.registered then
            mainPage:run()
        end
    end
end

local function start()
    if not turtle then error("computer needs to be a turtle", 2) end
    local turtle = Turtle.init()
    parallel.waitForAll(function() turtle:listen() end, function() turtle:gui() end)
end

return {
    Turtle = Turtle,
    start = start,
}