local element = require "turtlenet.gui.element"

local Container = {
    ---@class Container
    std = {
        ---@type table<integer|string, AnyElement>
        elements = {},
        window = {},
        ---@param self AnyElement
        ---@param id number|string|nil
        ---@return AnyElement|nil
        getElementById = function (self, id)
            for _, element in pairs(self.elements) do
                if element.id == id then
                    return element
                end
                if type(element.getElementById) == "function" then
                    local res = element:getElementById(id)
                    if res then return res end
                end
            end
        end,
        ---@param self Container
        ---@param gui GUI
        ---@param page Page
        ---@param window table|nil
        update = function (self, gui, page, window)
            local back = term.current()
            term.redirect(self.window)
            for _, element in pairs(self.elements) do
                if element.active then
                    element:update(gui, page, window)
                end
            end
            term.redirect(back)
        end,
        ---@param self Container
        ---@param gui GUI
        ---@param page Page
        ---@param window table|nil
        draw = function (self, gui, page, window)
            local back = term.current()
            term.redirect(self.window)
            for _, element in pairs(self.elements) do
                if element.visible then
                    element:draw(gui, page, window)
                end
            end
            term.redirect(back)
        end,
        ---@param self Container
        ---@param gui GUI
        ---@param page Page
        ---@param events table<integer, any>
        ---@param window table|nil
        event = function (self, gui, page, events, window)
            local back = term.current()
            term.redirect(self.window)
            for _, element in pairs(self.elements) do
                if element.active then
                    element:event(gui, page, events, window)
                end
            end
            term.redirect(back)
        end,
    },
    types = {
        elements = { values = {"Element"}, keys = {"number", "string"}, valueFunc = element.checkMetaName },
        draw = { value = "function", type = "type" },
        event = { value = "function", type = "type" },
        mouseOver = { value = "function", type = "type" },
    },
    mt = {
        __name = "Container"
    }
}
---@param opts Container
function Container.new(opts)
    element.checkOptsElement(2, opts, Container.std, Container.types)
    ---@type AnyElement
    local opts = opts
    local x, y = element.absolutePosition(opts.position, opts.x, opts.y)
    local w, h = element.absoluteTransform(opts.transform, opts.w, opts.h)
    opts.window = opts.window or window.create(term.current, x, y, w, h)
    local button = element.Element.new(opts)
    return button
end

return Container