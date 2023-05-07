local Position3D
local Position3D = {
    mt = {
        __name = "position3d",
        ---@param self Position3D
        __tostring = function(self)
            return ("(%s, %s, %s)"):format(self.x, self.y, self.z)
        end,
        ---@param self Position3D
        ---@param other Position3D
        __eq = function(self, other)
            return self.x == other.x and self.y == other.y and self.z == other.z
        end,
        ---@param self Position3D
        ---@param other Position3D
        ---@return Position3D
        __add = function(self, other)
            return Position3D.new(self.x + other.x, self.y + other.y, self.z + other.z)
        end,
        ---@param self Position3D
        ---@param other Position3D
        ---@return Position3D
        __sub = function(self, other)
            return Position3D.new(self.x - other.x, self.y - other.y, self.z - other.z)
        end,
        ---@param self Position3D
        ---@param other Position3D
        ---@return Position3D
        __mul = function(self, other)
            return Position3D.new(self.x * other.x, self.y * other.y, self.z * other.z)
        end,
        ---@param self Position3D
        ---@param other Position3D
        ---@return Position3D
        __div = function(self, other)
            return Position3D.new(self.x / other.x, self.y / other.y, self.z / other.z)
        end,
        ---@param self Position3D
        ---@param other Position3D
        ---@return Position3D
        __mod = function(self, other)
            return Position3D.new(self.x % other.x, self.y % other.y, self.z % other.z)
        end,
    }
}
---@param x integer
---@param y integer
---@param z integer
---@return Position3D
function Position3D.new(x, y, z)
    return setmetatable(
        ---@class Position3D
        {
            x = x, y = y, z = z,

            tostring = Position3D.mt.__tostring,
            eq = Position3D.mt.__eq,
            add = Position3D.mt.__add, sub = Position3D.mt.__sub,
            mul = Position3D.mt.__mul, div = Position3D.mt.__div, mod = Position3D.mt.__mod,
        },
        Position3D.mt
    )
end
function Position3D.default()
    return Position3D.new(0, 0, 0)
end
---@alias Direction "north"|"south"|"east"|"west"

local Transform = {
    mt = {
        __name = "transform",
        ---@param self Transform
        __tostring = function(self)
            return ("(%s, %s)"):format(self.position, self.direction)
        end,
        ---@param self Transform
        ---@param other Transform
        __eq = function(self, other)
            return self.position:eq(other.position) and self.direction == other.direction
        end
    }
}
---@param position Position3D
---@param direction Direction
---@return Transform
function Transform.new(position, direction)
    return setmetatable(
        ---@class Transform
        {
            position = position, direction = direction,

            directionX = Transform.directionX, directionZ = Transform.directionZ,
            forward = Transform.forward, back = Transform.back,
            up = Transform.up, down = Transform.down,
            left = Transform.left, right = Transform.right,
            
            tostring = Transform.mt.__tostring,
            eq = Transform.mt.__eq
        },
        Transform.mt
    )
end
function Transform.default()
    return Transform.new(Position3D.default(), "north")
end
---@param self Transform
---@return integer
function Transform:directionX()
    if self.direction == "east" then
        return 1
    elseif self.direction == "west" then
        return -1
    else
        return 0
    end
end
---@param self Transform
---@return integer
function Transform:directionZ()
    if self.direction == "south" then
        return 1
    elseif self.direction == "north" then
        return -1
    else
        return 0
    end
end
---@param self Transform
function Transform:forward()
    self.position.x = self.position.x + self:directionX()
    self.position.z = self.position.z + self:directionZ()
end
---@param self Transform
function Transform:back()
    self.position.x = self.position.x - self:directionX()
    self.position.z = self.position.z - self:directionZ()
end
---@param self Transform
function Transform:up()
    self.position.y = self.position.y + 1
end
---@param self Transform
function Transform:down()
    self.position.y = self.position.y - 1
end
---@param self Transform
function Transform:right()
    if self.direction == "north" then
        self.direction = "east"
    elseif self.direction == "south" then
        self.direction = "west"
    elseif self.direction == "east" then
        self.direction = "south"
    elseif self.direction == "west" then
        self.direction = "north"
    end
end
---@param self Transform
function Transform:left()
    if self.direction == "north" then
        self.direction = "west"
    elseif self.direction == "south" then
        self.direction = "east"
    elseif self.direction == "east" then
        self.direction = "north"
    elseif self.direction == "west" then
        self.direction = "south"
    end
end

return {
    Transform = Transform,
    Position3D = Position3D
}