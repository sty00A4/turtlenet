local element = require "turtlenet.gui.element"

local Text = {
    ---@class Text
    std = {
        text = "",
        w = 12,
        h = 1,
        fg = colors.white,
        bg = colors.black,
        ---@param self AnyElement
        ---@param page GUI
        ---@param window table|nil
        draw = function (self, page, window)
            local cx, cy = term.getCursorPos()
            local fg, bg = term.getTextColor(), term.getBackgroundColor()
            local x, y = element.absolutePosition(self.position, self.x, self.y)
            local w, h = element.absoluteTransform(self.transform, self.w, self.h)

            local lines = self.text:sep("\n")
            local idx = 1
            for y = y, y + h - 1 do
                term.setCursorPos(x, y)
                term.setTextColor(self.bg)
                term.write((" "):rep(w))

                local line = lines[idx]
                if line then
                    term.setCursorPos(x, y)
                    term.setTextColor(self.fg)
                    if #line <= w then
                        term.write(line)
                    else
                        term.write(line:sub(1, w))
                    end
                    idx = idx + 1
                end
            end

            term.setCursorPos(cx, cy)
            term.setTextColor(fg)
            term.setBackgroundColor(bg)
        end,
    },
    types = {
        text = { value = "string", type = "type" },
        draw = { value = "function", type = "type" },
        event = { value = "function", type = "type" },
        mouseOver = { value = "function", type = "type" },
    },
    mt = {
        __name = "Text"
    }
}
---@param opts Text
function Text.new(opts)
    element.checkOptsElement(2, opts, Text.std, Text.types)
    local button = element.Element.new(opts)
    return button
end

return {
    Text = Text
}