local element = require "turtlenet.gui.element"

local Button = {
    ---@class Button
    std = {
        label = "button",
        color = colors.white,
        braces = "[]",
        ---@param self Button|Element
        ---@param page GUI
        onClick = function (self, page) end,
        ---@param self Button|Element
        ---@param page GUI
        draw = function (self, page)
            local x, y = element.absolutePosition(self.position, self.x, self.y)
            term.setCursorPos(x, y)
        end,
        ---@param self Button|Element
        ---@param page GUI
        ---@param events table<integer, any>
        event = function (self, page, events)
            local event, mb, mx, my = events[1], events[2], events[3], events[4]
            if event == "mouse_click" then
                if mb == 1 then
                    if self:mouseOver(mx, my) then
                        if type(self.onClick) == "function" then
                            return self:onClick(page)
                        end
                    end
                end
            end
        end,
        ---@param self Button|Element
        ---@param mx integer
        ---@param my integer
        ---@return boolean
        mouseOver = function (self, mx, my)
            local x, y = element.absolutePosition(self.position, self.x, self.y)
            return (mx >= x and mx <= x + #self.label + 1) and my == y
        end,
    },
    types = {
        label = { value = "string", type = "type" },
        colors = { value = "integer", type = "type" },
        braces = { value = "string", type = "type" },
        onClick = { value = "function", type = "type" },
        draw = { value = "function", type = "type" },
        event = { value = "function", type = "type" },
        mouseOver = { value = "function", type = "type" },
    },
}
---@param opts any
---@return Button
function Button.new(opts)
    element.checkOptsElement(2, opts, Button.std, Button.types)
    ---@type Button
    ---@diagnostic disable-next-line: assign-type-mismatch
    local button = element.Element.new(opts)
    return button
end

return {
    Button = Button
}