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
---@param max integer|nil
---@return Log
function Log.new(max)
    return setmetatable(
        ---@class Log
        {
            ---@type table<integer, Message>
            log = {}, max = max or 500,
            push = Log.push,
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
    if #self.log > self.max then
        table.remove(self.log, 1)
    end
end

return {
    Log = Log,
    Message = Message
}