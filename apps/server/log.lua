---@alias MessageType "debug"|"info"|"error"
local Message = {
    mt = {
        __name = "message",
        ---@param self Message
        __tostring = function (self)
            return ("[%s] %s%s: %q"):format(self.type, self.src and self.src..":" or "",  os.date("%x-%X", self.date), self.text)
        end
    }
}
---@param type MessageType
---@param text string
---@param date integer
---@param src string|nil
---@return Message
function Message.new(type, text, date, src)
    return setmetatable(
        ---@class Message
        {
            type = type,
            text = text, date = date, src = src
        },
        Message.mt
    )
end
local Log = {
    mt = {
        __name = "log"
    }
}
---@return Log
function Log.new()
    return setmetatable(
        ---@class Log
        {
            ---@type table<integer, Message>
            log = {},
            push = Log.push
        },
        Log.mt
    )
end
---@param self Log
---@param type MessageType
---@param text string
---@param src string|nil
function Log:push(type, text, src)
    table.insert(self.log, Message.new(type, text, os.clock(), src))
end

return {
    Log = Log,
    Message = Message
}