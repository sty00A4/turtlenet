local element = require "turtlenet.gui.element"

local Input = {
    ---@class Input
    std = {
        empty = "input text...",
        input = "",
        focused = false,
        w = 13,
        h = 1,
        fg = colors.white,
        bg = colors.gray,
        ---@param self AnyElement
        ---@param page GUI
        ---@param window table|nil
        update = function (self, page, window)
            if self.focused then
                local x, y = element.absolutePosition(self.position, self.x, self.y)
                local w, h = element.absoluteTransform(self.transform, self.w, self.h)
                term.setCursorPos(x + (#self.input < w and #self.input or w - 1), y)
                term.setCursorBlink(true)
            end
        end,
        ---@param self AnyElement
        ---@param page GUI
        ---@param window table|nil
        draw = function (self, page, window)
            local cx, cy = term.getCursorPos()
            local fg, bg = term.getTextColor(), term.getBackgroundColor()
            local x, y = element.absolutePosition(self.position, self.x, self.y)
            local w, h = element.absoluteTransform(self.transform, self.w, self.h)
            term.setBackgroundColor(self.bg)
            for y = y, y + h - 1 do
                term.setCursorPos(x, y)
                term.write((" "):rep(w))
            end
            term.setCursorPos(x, y)
            term.setTextColor(self.fg)
            if #self.input == 0 and not self.focused then
                -- term.write(self.empty:sub(#self.empty <= w and #self.empty - w or 1, #self.empty))
            else
                if #self.input <= w - 1 then
                    term.write(self.input:sub(1, #self.input))
                else
                    term.write(self.input:sub(#self.input - w + 2, #self.input))
                end
            end

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
                    self.focused = self:mouseOver(mx, my, window)
                end
            end
            if event == "char" then
                local c = p1
                if self.focused then
                    self.input = self.input .. c
                end
            end
            if event == "key" then
                local key = p1
                if self.focused then
                    if key == keys.backspace then
                        self.input = self.input:sub(1, #self.input - 1)
                    end
                    if key == keys.tab then
                        self.input = self.input .. "\t"
                    end
                    if key == keys.enter then
                        self.focused = false
                    end
                end
            end
        end,
    },
    types = {
        empty = { value = "string", type = "type" },
        input = { value = "string", type = "type" },
        focused = { value = "boolean", type = "type" },
        fg = { value = "number", type = "type" },
        bg = { value = "number", type = "type" },
        draw = { value = "function", type = "type" },
        event = { value = "function", type = "type" },
        mouseOver = { value = "function", type = "type" },
    },
    mt = {
        __name = "Input"
    }
}
---@param opts Input
function Input.new(opts)
    element.checkOptsElement(2, opts, Input.std, Input.types)
    local button = element.Element.new(opts)
    return button
end

return {
    Input = Input
}