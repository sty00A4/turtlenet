local element = require "turtlenet.gui.element"

local Container = {
    ---@class Container
    std = {
        ---@type table<integer|string, AnyElement>
        elements = {},
        window = {},
        ---@param self Container
        ---@param page GUI
        update = function (self, page)
            local back = term.current()
            term.redirect(self.window)
            for _, element in pairs(self.elements) do
                element:update(page)
            end
            term.redirect(back)
        end,
        ---@param self Container
        ---@param page GUI
        draw = function (self, page)
            local back = term.current()
            term.redirect(self.window)
            for _, element in pairs(self.elements) do
                element:draw(page)
            end
            term.redirect(back)
        end,
        ---@param self Container
        ---@param page GUI
        ---@param events table<integer, any>
        event = function (self, page, events)
            local back = term.current()
            term.redirect(self.window)
            for _, element in pairs(self.elements) do
                element:event(page, events)
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

return {
    Container = Container
}