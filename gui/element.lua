local ElementPositionMeta = { __name = "ElementPosition" }
local ElementPosition = {
    ---@class ElementPosition
    absolute = setmetatable({}, ElementPositionMeta),
    ---@class ElementPosition
    relative = setmetatable({}, ElementPositionMeta),
}

---@param level integer
---@param value any
---@param name string
---@param ... type
local function checkType(level, value, name, ...)
    local types = {...}
    if not table.contains(types, type(value)) then
        error(("expected %s to be of type %s, not %s"):format(name, table.concat(types, "|"), type(value)), level + 1)
    end
end
---@param level integer
---@param value table
---@param name string
---@param ... string
local function checkMetaName(level, value, name, ...)
    local names = {...}
    local meta = getmetatable(value)
    if not meta then
        error(("expected %s to be of type %s, not %s"):format(name, table.concat(names, "|"), type(value)), level + 1)
    end
    local name = meta.__name
    if not name then
        error(("expected %s to be of type %s, not %s"):format(name, table.concat(names, "|"), type(value)), level + 1)
    end
    if not table.contains(names, name) then
        error(("expected %s to be of type %s, not %s"):format(name, table.concat(names, "|"), name), level + 1)
    end
end
---@param level integer
---@param value any
---@param name string
---@param ... any
local function checkValue(level, value, name, ...)
    local values = {...}
    if not table.contains(values, type(value)) then
        for k, value in pairs(values) do
            if type(value) == "string" then
                values[k] = ("%q"):format(value)
            end
        end
        error(("expected %s to be %s, not %s"):format(name, table.concat(values, "|"), tostring(value)), level + 1)
    end
end
---@param level integer
---@param value table
---@param name string
---@param keys table<integer, type>
---@param valueFunc function
local function checkTable(level, value, name, keys, valueFunc, ...)
    local keysT = {}
    for k, _ in pairs(value) do
        table.insert(keysT, type(k))
    end
    for _, typ in pairs(keysT) do
        if not table.contains(keys, typ) then
            error(("expected %s key's to be %s, not %s"):format(name, table.concat(keys, "|"), table.concat(keysT, "|")), level + 1)
        end
    end
    for k, v in pairs(value) do
        valueFunc(level + 2, v, name.."["..(type(k) == "string" and ("%q"):format(k) or tostring(k)).."]", ...)
    end
end

---@param position ElementPosition
---@param x integer
---@param y integer
local function absolutePosition(position, x, y)
    local W, H = term.getSize()
    if position == ElementPosition.relative then
        x, y = W * x, H * y
    end
    return x, y
end

local Element = {
    mt = {
        __name = "element"
    }
}
---@param opts Element
---@return Element
function Element.new(opts)
    opts.x = opts.x or 1.
    checkType(2, opts.x, "x", "number")
    opts.y = opts.y or 1.
    checkType(2, opts.y, "y", "number")
    opts.position = opts.position or ElementPosition.absolute
    checkMetaName(2, opts.position, "position", "ElementPosition")

    ---@param self Element
    ---@param page GUI
    opts.update = opts.update or function (self, page) end
    checkType(2, opts.update, "update", "function")
    ---@param self Element
    ---@param page GUI
    opts.draw = opts.draw or function (self, page) end
    checkType(2, opts.draw, "draw", "function")
    ---@param self Element
    ---@param page GUI
    ---@param events table
    opts.event = opts.event or function (self, page, events) end
    checkType(2, opts.event, "event", "function")

    return setmetatable(
        ---@class Element
        opts,
        Element.mt
    )
end

return {
    ElementPosition = ElementPosition,
    Element = Element,
    checkType = checkType,
    checkMetaName = checkMetaName,
    checkValue = checkValue,
    checkTable = checkTable,
    absolutePosition = absolutePosition,
}