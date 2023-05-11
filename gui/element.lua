local ElementPositionMeta = { __name = "ElementPosition" }
local ElementPosition = {
    ---@class ElementPosition
    absolute = setmetatable({}, ElementPositionMeta),
    ---@class ElementPosition
    relative = setmetatable({}, ElementPositionMeta),
}
local ElementTransfromMeta = { __name = "ElementTransfrom" }
local ElementTransfrom = {
    ---@class ElementTransfrom
    absolute = setmetatable({}, ElementTransfromMeta),
    ---@class ElementTransfrom
    relative = setmetatable({}, ElementTransfromMeta),
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
---@param transform ElementTransfrom
---@param w integer
---@param h integer
local function absoluteTransform(transform, w, h)
    local W, H = term.getSize()
    if transform == ElementTransfrom.relative then
        w, h = W * w, H * h
    end
    return w, h
end

---@param level integer
---@param opts table<string, any>
---@param std table<string, any>
---@param types table<string, table>
local function checkOpts(level, opts, std, types)
    for k, v in pairs(std) do
        opts[k] = type(opts[k]) ~= "nil" and opts[k] or v
        local typ = types[k] or { type = "" }
        if typ.type == "type" then
            checkType(level + 1, opts[k], k, typ.value)
        elseif typ.type == "meta" then
            checkMetaName(level + 1, opts[k], k, typ.value)
        elseif typ.type == "table" then
            checkTable(level + 1, opts[k], k, typ.keys, typ.valueFunc, table.unpack(typ.values))
        elseif typ.type == "value" then
            checkValue(level + 1, opts[k], k, table.unpack(typ.values))
        end
    end
end


local Element = {
    ---@class Element
    std = {
        x = 1.,
        y = 1.,
        w = 1,
        h = 1,
        position = ElementPosition.absolute,
        transform = ElementTransfrom.absolute,
        ---@param self AnyElement
        ---@param page GUI
        draw = function (self, page) end,
        ---@param self AnyElement
        ---@param page GUI
        update = function (self, page) end,
        ---@param self AnyElement
        ---@param page GUI
        ---@param events table<integer, any>
        event = function (self, page, events) end,
        ---@param self AnyElement
        ---@param mx integer
        ---@param my integer
        ---@return boolean
        mouseOver = function (self, mx, my)
            local x, y = absolutePosition(self.position, self.x, self.y)
            local w, h = absoluteTransform(self.transform, self.w, self.h)
            return (mx >= x and mx <= x + w - 1) and (my >= y and my <= y + h - 1)
        end,
    },
    types = {
        x = { value = "number", type = "type" },
        y = { value = "number", type = "type" },
        position = { value = "ElementPosition", type = "meta" },
        draw = { value = "function", type = "type" },
        update = { value = "function", type = "type" },
        event = { value = "function", type = "type" },
    },
    mt = {
        __name = "Element"
    }
}
---@param opts AnyElement
---@return AnyElement
function Element.new(opts)
    checkOpts(3, opts, Element.std, Element.types)

    return setmetatable(
        opts,
        Element.mt
    )
end

---@param level integer
---@param opts table<string, any>
---@param std table<string, any>
---@param types table<string, table>
local function checkOptsElement(level, opts, std, types)
    checkOpts(level + 1, opts, std, types)
    checkOpts(level + 1, opts, Element.std, Element.types)
end

return {
    ElementPosition = ElementPosition,
    Element = Element,
    checkType = checkType,
    checkMetaName = checkMetaName,
    checkValue = checkValue,
    checkTable = checkTable,
    absolutePosition = absolutePosition,
    absoluteTransform = absoluteTransform,
    checkOpts = checkOpts,
    checkOptsElement = checkOptsElement,
}