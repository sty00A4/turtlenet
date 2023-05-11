local transform = require "turtlenet.apps.server.transform"

local Client = {
    mt = {
        __name = "client",
        ---@param self Client
        __tostring = function(self)
            return ("Client#%s"):format(self.id)
        end,
        ---@param self Client
        ---@param other Client
        __eq = function(self, other)
            return self.id == other.id and self.transform:eq(other.transform)
        end
    }
}
---@param id integer
---@param transform Transform
---@return Client
function Client.new(id, transform)
    return setmetatable(
        ---@class Client
        {
            id = id, transform = transform,
            
            tasks = {},
            ---@type table<integer, table>
            inventory = {}, fuel = 0,

            tostring = Client.mt.__tostring,
            eq = Client.mt.__eq
        },
        Client.mt
    )
end

return {
    Client = Client,
    transform = transform
}