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
        ---@param gui GUI
        ---@param page Page
        ---@param window table|nil
        draw = function (self, gui, page, window)
            local cx, cy = term.getCursorPos()
            local fg, bg = term.getTextColor(), term.getBackgroundColor()
            local w, h = element.absoluteTransform(self.transform, self.w, self.h)
            local x, y = element.absolutePosition(self.position, self.x, self.y)
            
            local lines = self.text:sep("\n")
            local idx = 1
            while idx <= #lines do
                local line = lines[idx]
                if #line > w then
                    lines[idx] = line:sub(1, w)
                    table.insert(lines, idx + 1, line:sub(w + 1, #line))
                end
                idx = idx + 1
            end
            local idx = 1
            for ly = y, y + h - 1 do
                term.setCursorPos(x, ly)
                term.setTextColor(self.bg)
                term.write((" "):rep(w))
                
                local line = lines[idx]
                if line then
                    term.setCursorPos(x, ly)
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

return Text