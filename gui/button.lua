local element = require "turtlenet.gui.element"

local Button = {}
function Button.new(opts)
    local button = element.Element.new(opts)
    button.label = button.label or "button"
    element.checkType(2, button.label, "label", "string")
    button.color = button.color or colors.white
    element.checkType(2, button.color, "color", "number")
    button.braces = button.braces or "[]"
    element.checkType(2, button.braces, "braces", "string")
    ---@param self Element
    ---@param mx integer
    ---@param my integer
    button.mouseOver = button.mouseOver or function (self, mx, my)
        local x, y = element.absolutePosition(self.position, self.x, self.y)
        return (mx >= x and mx <= x + #self.label + 1) and my == y
    end
    element.checkType(2, button.mouseOver, "mouseOver", "function")
    ---@param self Element
    ---@param page GUI
    ---@param events table
    button.event = button.event or function (self, page, events)
        local event, mb, mx, my = events[1], events[2], events[3], events[4]
        if event == "mouse_click" then
            if mb == 1 then
                if type(self.onClick) == "function" then
                    return self:onClick(page)
                end
            end
        end
    end
    ---@param self Element
    ---@param page GUI
    button.draw = button.draw or function (self, page)
        local x, y = element.absolutePosition(self.position, self.x, self.y)
        term.setCursorPos(x, y)
    end
    element.checkType(2, button.event, "event", "function")
    return button
end

return {
    Button = Button
}