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
    self.fuelLimit = turtle.getFuelLimit()
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
        self.log:push("error", msg or "couldn't move forward", "Turtle.forward")
    end
end
---@param self Turtle
function Turtle:back()
    local success, msg = turtle.back()
    if success then
        self.transform:back()
    else
        self.log:push("error", msg or "couldn't move back", "Turtle.back")
    end
end
---@param self Turtle
function Turtle:up()
    local success, msg = turtle.up()
    if success then
        self.transform:up()
    else
        self.log:push("error", msg or "couldn't move up", "Turtle.up")
    end
end
---@param self Turtle
function Turtle:down()
    local success, msg = turtle.down()
    if success then
        self.transform:down()
    else
        self.log:push("error", msg or "couldn't move down", "Turtle.down")
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
    ---@diagnostic disable-next-line: undefined-field
    if self.serverId == os.getComputerID() then gui.prompt.info "server ID is this computer's ID" return false end
    rednet.send(self.serverId, { head = "register" }, NET_PROTOCOL)
    local recvId, success = nil, false
    local tries = 1
    while recvId ~= self.serverId do
        recvId, success = rednet.receive(NET_PROTOCOL, CLIENT_TIMEOUT)
        if type(success) ~= "boolean" then success = false end
        tries = tries + 1
        if tries > 5 then break end
    end
    self.registered = success
    return success
end
---@param self Turtle
function Turtle:listen()
    ---@diagnostic disable-next-line: undefined-field
    os.queueEvent("update")
    while self.registered do
        local recvId, message
        while recvId ~= self.serverId do
            recvId, message = rednet.receive(NET_PROTOCOL, CLIENT_TIMEOUT)
        end
        ---@diagnostic disable-next-line: undefined-field
        os.queueEvent("update")
        if type(message) == "table" then
            if message.head == "picolua" then
                if type(message.code) == "string" then
                    local file = picolua.location.File.new("<input>")
                    ---@type ChunkNode
                    ---@diagnostic disable-next-line: assign-type-mismatch
                    local ast, err, epos = picolua.parseCode(message.code) if err then
                        rednet.send(recvId, { head = message.head, err = err, epos = epos }, NET_PROTOCOL)
                    else
                        local compiler = picolua.compiler.Compiler.new(file)
                        picolua.compiler.writeCode(compiler.code, 0, 0, picolua.bytecode.ByteCode.Get, compiler:newConst(self))
                        picolua.compiler.writeCode(compiler.code, 0, 0, picolua.bytecode.ByteCode.Set, compiler:newConst("Turtle"))
                        local _, err, epos = compiler:chunk(ast) if err then
                            rednet.send(recvId, { head = message.head, err = err, epos = epos }, NET_PROTOCOL)
                        else
                            compiler.optimisations.count(compiler)
                            local program = picolua.program.Program.new(file, compiler)
                            local value, err, epos = program:run()
                            rednet.send(recvId, { head = message.head, value = value, err = err, epos = epos }, NET_PROTOCOL)
                        end
                    end
                end
            elseif message.head == "command" then
                if type(message.command) == "string" then
                    local success = shell.run(message.command)
                    rednet.send(recvId, { head = message.head, success = success }, NET_PROTOCOL)
                end
            elseif message.head == "call" then
                if type(message.func) == "string" then
                    if type(self[message.func]) == "function" then
                        if type(message.args) == "table" then
                            local returns = { self[message.func](table.unpack(message.args)) }
                            rednet.send(recvId, { head = message.head, returns = returns }, NET_PROTOCOL)
                        end
                    end
                end
            end
        end
        if self.serverId then rednet.send(self.serverId, self:toInfo()) end
    end
end
---@param self Turtle
function Turtle:gui()
    local W, H = term.getSize()
    local connectPage = gui.Page.new {
        gui.Input.new {
            id = "connect.input",
            x = math.floor(W / 2 - 6), y = math.floor(H / 2 - 1),
            empty = "server ID..."
        },
        gui.Button.new {
            id = "connect.button", label = "connect",
            color = colors.lime,
            x = math.floor(W / 2 - 3), y = math.floor(H / 2 + 1),
            key = keys.enter,
            onClick = function (_, _gui, page, window)
                local id = tonumber(page:getElementById("connect.input").input)
                if not id then return gui.prompt.info("server ID is not a number") end
                ---@diagnostic disable-next-line: undefined-field
                if id == os.getComputerID() then return gui.prompt.info("server ID is this computer's ID") end
                self.serverId = id
                _gui:changePage("connecting")
                _gui:draw(window)
            end
        },
        gui.Button.new {
            id = "connect.exit", label = "exit",
            color = colors.red,
            x = 1, y = 1,
            onClick = function (_, _gui)
                _gui:exit()
            end
        }
    }
    local connectingPage = gui.Page.new {
        gui.Text.new {
            id = "connecting.text", text = "connecting...",
            x = math.floor(W / 2 - 7), y = math.floor(H / 2),
            ---@param _gui GUI
            ---@param page Page
            update = function (_self, _gui, page, window)
                self:register()
                if self.registered then
                    _gui:exit()
                else
                    gui.prompt.info("couldn't connect to #"..tostring(self.serverId))
                    _gui:changePage("main")
                end
            end
        }
    }
    local main = gui.Page.new {
        gui.Text.new {
            id = "main.text", text = "main app",
            fg = colors.lime,
            x = math.floor(W / 2 - 4), y = math.floor(H / 2),
        }
    }
    local interface = gui.GUI.new {
        main = connectPage,
        connecting = connectingPage,
    }
    interface:run()
    local interface = gui.GUI.new {
        main = main
    }
    parallel.waitForAny(function ()
        self:listen()
    end, function ()
        interface:run()
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
    if not turtle then
        turtle = {
            ---@return number
            getFuelLevel = function() return 0 end,
            ---@return number
            getFuelLimit = function() return 20000 end,
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