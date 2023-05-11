NET_PROTOCOL = "turtlenet"
SERVER_TIMEOUT = 0.5
CLIENT_TIMEOUT = 5

---checks if `item` is contained in `t`
---@param t table
---@param item any
---@return boolean
function table.contains(t, item)
    for k, v in pairs(t) do
        if v == item then
            return true
        end
    end
    return false
end
---seperates the string `s` by the seperator `sep`
---@param s string
---@param sep string
---@return table<integer, string>
function string.sep(s, sep)
    local t = {}
    local temp = ""
    local idx = 1
    while idx <= #s do
        local c = s:sub(idx, idx + #sep - 1)
        if c == sep then
            if #temp > 0 then
                table.insert(t, temp)
            end
            temp = ""
            idx = idx + #sep
        else
            temp = temp .. c
            idx = idx + 1
        end
    end
    if #temp > 0 then
        table.insert(t, temp)
    end
    return t
end

local server = require "turtlenet.apps.server"
local client = require "turtlenet.apps.client"
local picolua = require "turtlenet.picolua"
local gui = require "turtlenet.gui"
return {
    server = server,
    client = client,
    picolua = picolua,
    gui = gui,
}