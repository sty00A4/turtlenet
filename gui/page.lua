local element = require "turtlenet.gui.element"

local Page = {
    mt = {
        __name = "Page"
    }
}
---@param elements table<integer|string, AnyElement>
---@return Page
function Page.new(elements)
    element.checkTable(2, elements, "elements", {"number", "string"}, element.checkMetaName, "Element")
    return setmetatable(
        ---@class Page
        {
            elements = elements,
            getElementById = Page.getElementById,
            draw = Page.draw,
            update = Page.update,
            event = Page.event,
            run = Page.run,

            running = false
        },
        Page.mt
    )
end
---@param self Page
---@param id number|string|nil
---@return AnyElement|nil
function Page:getElementById(id)
    for _, element in pairs(self.elements) do
        if element.id == id then
            return element
        end
        if type(element.getElementById) == "function" then
            local res = element:getElementById(id)
            if res then return res end
        end
    end
end
---@param self Page
---@param gui GUI
---@param window table|nil
function Page:draw(gui, window)
    term.clear()
    for _, element in pairs(self.elements) do
        if element.visible then
            element:draw(gui, self, window)
        end
    end
end
---@param self Page
---@param gui GUI
---@param window table|nil
function Page:update(gui, window)
    for _, element in pairs(self.elements) do
        if element.active then
            element:update(gui, self, window)
        end
    end
end
---@param self Page
---@param gui GUI
---@param window table|nil
function Page:event(gui, window)
    ---@diagnostic disable-next-line: undefined-field
    local event = { os.pullEvent() }
    term.setCursorBlink(false)
    for _, element in pairs(self.elements) do
        if element.active then
            element:event(gui, self, event, window)
        end
    end
end
---@param self Page
---@param gui GUI
---@param window table|nil
function Page:run(gui, window)
    self.running = true
    self:draw(gui, window)
    while self.running do
        self:update(gui, window)
        self:draw(gui, window)
        self:event(gui, window)
    end
end

return Page