local element = require "turtlenet.gui.element"
local text = require "turtlenet.gui.text"
local button = require "turtlenet.gui.button"
local input = require "turtlenet.gui.input"
local prompt = require "turtlenet.gui.prompt"

local GUI = {
    mt = {
        __name = "gui"
    }
}
---@param elements table<integer|string, Element>
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
function GUI:draw()
    for _, element in pairs(self.elements) do
        element:draw(self)
    end
end
---@param self GUI
function GUI:update()
    for _, element in pairs(self.elements) do
        element:update(self)
    end
end
---@param self GUI
function GUI:event()
    local event = { os.pullEvent() }
    for _, element in pairs(self.elements) do
        element:event(self, event)
    end
end
---@param self GUI
function GUI:run()
    self.running = true
    while self.running do
        self:update()
        self:draw()
        self:event()
    end
end

return {
    element = element,
    text = text,
    button = button,
    input = input,
    prompt = prompt,
    test = function()
        term.clear()
        term.setCursorPos(1, 1)
        local page = GUI.new {
            button.Button.new {
                x = 1, y = 1,
                label = "click",
                fg = colors.green
            }
        }
        page:run()
    end,
    GUI = GUI,
}