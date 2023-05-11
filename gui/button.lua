local element = require "turtlenet.gui.element"

local Button = {
    ---@class Button
    std = {
        label = "button",
        color = colors.white,
        braceColor = colors.gray,
        braces = "[]",
        ---@type integer|nil
        key = nil,
        ---@param self AnyElement
        ---@param page GUI
        ---@param window table|nil
        onClick = function (self, page, window) end,
        ---@param self AnyElement
        ---@param page GUI
        ---@param window table|nil
        update = function (self, page, window)
            self.w = #self.label + 2
            self.h = 1
        end,
        ---@param self AnyElement
        ---@param page GUI
        ---@param window table|nil
        draw = function (self, page, window)
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
        ---@param self AnyElement
        ---@param page GUI
        ---@param events table<integer, any>
        ---@param window table|nil
        event = function (self, page, events, window)
            local event, p1, p2, p3 = events[1], events[2], events[3], events[4]
            if event == "mouse_click" then
                local mb, mx, my = p1, p2, p3
                if mb == 1 then
                    if self:mouseOver(mx, my, window) then
                        if type(self.onClick) == "function" then
                            return self:onClick(page, window)
                        end
                    end
                end
            end
            if event == "key" then
                local key = p1
                if key == self.key then
                    if type(self.onClick) == "function" then
                        return self:onClick(page, window)
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
        key = { values = {"number", "nil"}, type = "types" },
        onClick = { value = "function", type = "type" },
        draw = { value = "function", type = "type" },
        event = { value = "function", type = "type" },
        mouseOver = { value = "function", type = "type" },
    },
    mt = {
        __name = "Button"
    }
}
---@param opts Button
function Button.new(opts)
    element.checkOptsElement(2, opts, Button.std, Button.types)
    local button = element.Element.new(opts)
    return button
end

return {
    Button = Button
}