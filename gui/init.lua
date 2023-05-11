local element = require "turtlenet.gui.element"
local text = require "turtlenet.gui.text"
local button = require "turtlenet.gui.button"
local input = require "turtlenet.gui.input"
local container = require "turtlenet.gui.container"

---@alias AnyElement Element|Button|Input|Text|Container

local GUI = {
    mt = {
        __name = "gui"
    }
}
---@param elements table<integer|string, AnyElement>
---@return GUI
function GUI.new(elements)
    element.checkTable(2, elements, "elements", {"number", "string"}, element.checkMetaName, "Element")
    return setmetatable(
        ---@class GUI
        {
            elements = elements,
            draw = GUI.draw,
            update = GUI.update,
            event = GUI.event,
            run = GUI.run,

            running = false
        },
        GUI.mt
    )
end
---@param self GUI
---@param window table|nil
function GUI:draw(window)
    for _, element in pairs(self.elements) do
        element:draw(self, window)
    end
end
---@param self GUI
---@param window table|nil
function GUI:update(window)
    for _, element in pairs(self.elements) do
        element:update(self, window)
    end
end
---@param self GUI
---@param window table|nil
function GUI:event(window)
    local event = { os.pullEvent() }
    term.setCursorBlink(false)
    for _, element in pairs(self.elements) do
        element:event(self, event, window)
    end
end
---@param self GUI
---@param window table|nil
function GUI:run(window)
    self.running = true
    while self.running do
        self:update(window)
        term.clear()
        self:draw(window)
        self:event(window)
    end
end

local prompt = {}
---@param msg string
---@param width integer|nil
---@param height integer|nil
---@return boolean
function prompt.confirm(msg, width, height)
    local mainWindow = term.current()
    local W, H = mainWindow.getSize()
    width = width or #msg + 2
    width = width >= 10 and width or 10
    width = width <= W and width or W
    height = height or 3
    height = height >= 3 and height or 3
    height = height <= H and height or H
    local x, y = math.floor(W / 2 - width / 2), math.floor(H / 2 - height / 2)
    local promptWindow = window.create(mainWindow, x, y, width, height)
    term.redirect(promptWindow)
    term.setBackgroundColor(colors.gray)
    local confirm = false
    local page = GUI.new {
        text.Text.new {
            x = 2, y = 1, w = width - 2, h = height - 2,
            text = msg
        },
        button.Button.new {
            x = 1, y = height,
            label = "OK", color = colors.green,
            braceColor = colors.lightGray,
            onClick = function (self, page)
                confirm = true
                page.running = false
            end
        },
        button.Button.new {
            x = 5, y = height,
            label = "CANCEL", color = colors.red,
            braceColor = colors.lightGray,
            onClick = function (self, page)
                confirm = false
                page.running = false
            end
        },
    }
    page:run(promptWindow)
    term.redirect(mainWindow)
    promptWindow.setVisible(false)
    return confirm
end

return {
    element = element,
    text = text,
    button = button,
    input = input,
    container = container,
    prompt = prompt,
    test = function()
        term.clear()
        term.setCursorPos(1, 1)
        local page = GUI.new {
            button.Button.new {
                x = 1, y = 1,
                label = "exit",
                color = colors.red,
                onClick = function (self, page)
                    if prompt.confirm("are you sure you wanna exit?") then
                        error "exited"
                    end
                end
            },
            input.Input.new {
                x = 1, y = 2,
            },
            text.Text.new {
                x = 1, y = 3,
                text = "this is a test",
                w = 20
            }
        }
        page.running = true
        while page.running do
            page:update()
            term.clear()
            page:draw()
            page:event()
        end
    end,
    GUI = GUI,
}