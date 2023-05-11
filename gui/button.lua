local element = require "turtlenet.gui.element"

local Button = {
    ---@class Button
    std = {
        label = "button",
        color = colors.white,
        braceColor = colors.gray,
        braces = "[]",
        ---@param self Element|Button|Input|Text
        ---@param page GUI
        onClick = function (self, page) end,
        ---@param self Element|Button|Input|Text
        ---@param page GUI
        update = function (self, page)
            self.w = #self.label
            self.h = 1
        end,
        ---@param self Element|Button|Input|Text
        ---@param page GUI
        draw = function (self, page)
            local cx, cy = term.getCursorPos()
            local fg, bg = term.getTextColor(), term.getBackgroundColor()
            local x, y = element.absolutePosition(self.position, self.x, self.y)
            term.setCursorPos(x, y)
            term.setTextColor(self.braceColor)
            term.write(self.braces:sub(1, 1))
            term.setTextColor(self.color)
            term.write(self.label)
            term.setTextColor(self.braceColor)
            term.write(self.braces:sub(2, 2))

            term.setCursorPos(cx, cy)
            term.setTextColor(fg)
            term.setBackgroundColor(bg)
        end,
        ---@param self Element|Button|Input|Text
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
    },
    types = {
        label = { value = "string", type = "type" },
        colors = { value = "number", type = "type" },
        braceColor = { value = "number", type = "type" },
        braces = { value = "string", type = "type" },
        onClick = { value = "function", type = "type" },
        draw = { value = "function", type = "type" },
        event = { value = "function", type = "type" },
        mouseOver = { value = "function", type = "type" },
    },
    mt = {
        __name = "Button"
    }
}
---@param opts table
function Button.new(opts)
    element.checkOptsElement(2, opts, Button.std, Button.types)
    local button = element.Element.new(opts)
    return button
end

return {
    Button = Button
}