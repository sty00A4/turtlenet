local transform = require "turtlenet.server.transform"

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
    ---@type Turtle
    local turt = setmetatable(
        ---@class Turtle
        {
            transform = transform.Transform.default(),
            ---@type Inventory
            inventory = {},
            fuel = turtle.getFuelLevel(),

            update = Turtle.update,
            updateInventory = Turtle.updateInventory, updateFuel = Turtle.updateFuel,

            forward = Turtle.forward, back = Turtle.back,
            up = Turtle.up, down = Turtle.down,
            left = Turtle.left, right = Turtle.right,

            register = Turtle.register, listen = Turtle.listen,
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
        x = self.transform.position.x,
        y = self.transform.position.y,
        z = self.transform.position.z,
        direction = self.transform.direction,
        inventory = self.inventory,
        fuel = self.fuel,
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
---@param id integer
---@return boolean
function Turtle:register(id)
    rednet.send(id, { head = "register" })
    local recvId, success
    while recvId ~= id do
        recvId, success = rednet.receive(NET_PROTOCOL)
    end
    return success
end
---@param self Turtle
---@param id integer
function Turtle:listen(id)
    while true do
        rednet.send(id, { head = "task", status = "request" })
        local recvId, program
        while recvId ~= id do
            recvId, program = rednet.receive(NET_PROTOCOL)
        end
        if type(program) == "table" then
            -- turtlang.runProgram(program)
            rednet.send(id, { head = "task", status = "done" })
        end
    end
end

---@param id integer
local function start(id)
    local turtle = Turtle.init()
    turtle:register(id)
    turtle:listen(id)
end

return {
    Turtle = Turtle,
    start = start,
}