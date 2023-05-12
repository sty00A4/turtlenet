local transform = require "turtlenet.apps.server.transform"
local gui = require "turtlenet.gui"

---@alias ClientStatus "idle"|"task"
---@alias Tasks table<integer, any>

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
            ---@type ClientStatus
            status = "idle",
            ---@type table<integer, Item|nil>
            inventory = {}, fuel = 0,

            tostring = Client.mt.__tostring,
            eq = Client.mt.__eq,
            gui = Client.gui,
        },
        Client.mt
    )
end
---@param self Client
---@param server Server
---@param window table
function Client:gui(server, window)
    local interface = gui.GUI.new {
        main = gui.Page.new {
            
        }
    }

    interface:run()
end

return {
    Client = Client,
    transform = transform
}