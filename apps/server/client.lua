local log = require "turtlenet.apps.server.log"
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
            
            ---@type table<integer, any>
            unhandledMessages = {},
            log = log.Log.new(),

            tasks = {},
            ---@type ClientStatus
            status = "idle",
            ---@type table<integer, Item|nil>
            inventory = {}, fuel = 0, fuelLimit = 20000,

            tostring = Client.mt.__tostring,
            eq = Client.mt.__eq,
            gui = Client.gui,
            unhandledMessage = Client.unhandledMessage,
            peekUnhandledMessage = Client.peekUnhandledMessage,
            popUnhandledMessage = Client.popUnhandledMessage,
        },
        Client.mt
    )
end
---@param self Client
---@param server Server
---@param window table
function Client:gui(server, window)
    local mainWindow = term.current()
    if window then
        term.redirect(window)
    end
    
    local W, H = term.getSize()
    local interface = gui.GUI.new {
        main = gui.Page.new {
            gui.Button.new {
                label = "exit", color = colors.red,
                onClick = function (_, gui)
                    gui:exit()
                end
            },
            gui.Text.new {
                text = self:tostring(),
                x = 7, y = 1,
                fg = colors.lime,
            },
            gui.Text.new {
                text = "fuel: ",
                y = 2,
            },
            --- fuel display
            gui.element.Element.new {
                x = 7, y = 2, w = 20, h = 1,
                text = ("%s/%s"):format(self.fuel, self.fuelLimit),
                fg = colors.red, bg = colors.gray,
                ---@param element Element|Text
                update = function (element)
                    local fuelPercent = self.fuel / self.fuelLimit
                    local percentColors = { colors.red, colors.orange, colors.yellow, colors.green, colors.lime }
                    element.text = ("%s/%s"):format(self.fuel, self.fuelLimit)
                    element.fg = percentColors[math.ceil((fuelPercent * 4) + 1)]
                end,
                ---@param element Element|Text
                ---@param window table
                draw = function (element, _, _, window)
                    local cx, cy = term.getCursorPos()
                    local fg, bg = term.getTextColor(), term.getBackgroundColor()
                    local w, h = gui.element.absoluteTransform(element.transform, element.w, element.h)
                    local x, y = gui.element.absolutePosition(element.position, element.x, element.y)

                    local barWidth = w * (self.fuel / self.fuelLimit)
                    for ly = 0, h - 1 do
                        term.setCursorPos(x, y + ly)
                        term.setBackgroundColor(element.bg)
                        term.write((" "):rep(w))
                        term.setCursorPos(x, y + ly)
                        term.setBackgroundColor(element.fg)
                        term.write((" "):rep(barWidth))
                    end
                    if element.text then
                        term.setCursorPos(x, y)
                        local left, right = element.text:sub(1, barWidth), element.text:sub(barWidth + 1, #element.text)
                        term.write(left)
                        term.setBackgroundColor(element.bg)
                        term.write(right)
                    end

                    term.setCursorPos(cx, cy)
                    term.setTextColor(fg)
                    term.setBackgroundColor(bg)
                end
            },
            gui.Button.new {
                y = H,
                label = "command",
                onClick = function ()
                    local command = gui.prompt.input("send shell command")
                    if #command > 0 then
                        server:transmit(self.id, { head = "command", command = command })
                    else
                        gui.prompt.info("no command provided")
                    end
                end
            },
            gui.Button.new {
                x = 10, y = H,
                label = "call",
                onClick = function ()
                    local func = gui.prompt.input("call function on client")
                    if #func > 0 then
                        local args = {}
                        server:transmit(self.id, { head = "call", func = func, args = args })
                    else
                        gui.prompt.info("no function provided")
                    end
                end
            },
            gui.Button.new {
                x = 16, y = H,
                label = "picolua",
                onClick = function ()
                    local code = gui.prompt.input("send picolua code")
                    if #code > 0 then
                        server:transmit(self.id, { head = "picolua", code = code })
                    else
                        gui.prompt.info("no code provided")
                    end
                end
            },
        }
    }

    interface:run()
    term.redirect(mainWindow)
end
---@param self Client
---@param message table
function Client:unhandledMessage(message)
    table.insert(self.unhandledMessages, message)
end
---@param self Client
---@return table|nil
function Client:peekUnhandledMessage()
    return self.unhandledMessages[1]
end
---@param self Client
---@return table|nil
function Client:popUnhandledMessage()
    return table.remove(self.unhandledMessages, 1)
end

return {
    Client = Client,
    transform = transform
}