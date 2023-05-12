local element = require "turtlenet.gui.element"

local List = {
    ---@class List
    std = {
        ---@type table<integer, AnyElement>
        list = {},
        scroll = 0,
        w = 12,
        h = 1,
        fg = colors.white,
        bg = colors.black,
        ---@param self Element|List
        ---@param gui GUI
        ---@param page Page
        ---@param window table|nil
        draw = function (self, gui, page, window)
            local cx, cy = term.getCursorPos()
            local fg, bg = term.getTextColor(), term.getBackgroundColor()
            local x, y = element.absolutePosition(self.position, self.x, self.y)
            local _, h = element.absoluteTransform(self.transform, self.w, self.h)

            for i = 1, h do
                term.setCursorPos(x, y + i - 1)
                local element = self.list[i + self.scroll]
                if element then
                    element.x, element.y = term.getCursorPos()
                    element:draw(gui, page, window)
                end
            end

            term.setCursorPos(cx, cy)
            term.setTextColor(fg)
            term.setBackgroundColor(bg)
        end,
        ---@param self Element|List
        ---@param gui GUI
        ---@param page Page
        ---@param events table<integer, any>
        ---@param window table|nil
        event = function (self, gui, page, events, window)
            local event, p1, p2, p3 = events[1], events[2], events[3], events[4]
            if event == "mouse_click" then
                local mb, mx, my = p1, p2, p3
                if mb == 1 then
                    local over, element = self:mouseOver(mx, my, window)
                    if over and element then
                        if type(element.onClick) == "function" then
                            return element:onClick(gui, page, window)
                        end
                    end
                end
            end
            if event == "mouse_scroll" then
                local dir, mx, my = p1, p2, p3
                local over = self:mouseOver(mx, my, window)
                if over then
                    self.scroll = self.scroll + dir
                    if self.scroll < 0 then self.scroll = 0 end
                    if #self.list > self.h then
                        if self.scroll > #self.list - self.h then self.scroll = #self.list - self.h end
                    else
                        self.scroll = 0
                    end
                end
            end
        end,
        ---@param self Element|List
        ---@param mx integer
        ---@param my integer
        ---@param window table|nil
        ---@return boolean, AnyElement|nil, integer|nil
        mouseOver = function (self, mx, my, window)
            local x, y = element.absolutePosition(self.position, self.x, self.y)
            local w, h = element.absoluteTransform(self.transform, self.w, self.h)
            local offsetX, offsetY = 0, 0
            if window then
                offsetX, offsetY = window.getPosition()
                offsetX, offsetY = offsetX - 1, offsetY - 1
            end
            x, y = x + offsetX, y + offsetY
            if (mx >= x and mx <= x + w - 1) and (my >= y and my <= y + h - 1) then
                local idx = my - y + 1 + self.scroll
                return true, self.list[idx], idx
            end
            return false
        end,
    },
    types = {
        list = { values = {"Element"}, keys = {"number", "string"}, valueFunc = element.checkMetaName },
        scroll = { value = "number", type = "type" },
        draw = { value = "function", type = "type" },
        event = { value = "function", type = "type" },
        mouseOver = { value = "function", type = "type" },
    },
    mt = {
        __name = "List"
    }
}
---@param opts List
function List.new(opts)
    element.checkOptsElement(2, opts, List.std, List.types)
    local button = element.Element.new(opts)
    return button
end

return List