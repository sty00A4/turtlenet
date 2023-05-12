---@alias MessageType "debug"|"info"|"error"
local Message = {
    mt = {
        __name = "message",
        ---@param self Message
        __tostring = function (self)
            return ("[%s] %s: %s (%s)"):format(self.type, self.src and self.src..":" or "", self.text, os.date("%x-%X", self.date))
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
            text = text, date = date, src = src,

            tostring = Message.mt.__tostring
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
    table.insert(self.log, Message.new(type, text, os.time(), src))
end

return {
    Log = Log,
    Message = Message
}