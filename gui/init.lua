local element = require "turtlenet.gui.element"
local text = require "turtlenet.gui.text"
local button = require "turtlenet.gui.button"
local input = require "turtlenet.gui.input"
local container = require "turtlenet.gui.container"
local list = require "turtlenet.gui.list"

---@alias AnyElement Element|Button|Input|Text|Container|List

local GUI = {
    mt = {
        __name = "gui"
    }
}
---@param elements table<integer|string, AnyElement>
---@return GUI
function GUI.new(elements)
    element.checkTable(2, elements, "elements", {"number", "string"}, element.checkMetaName, "Element")
    return setmetatable(
        ---@class GUI
        {
            elements = elements,
            getElementById = GUI.getElementById,
            draw = GUI.draw,
            update = GUI.update,
            event = GUI.event,
            run = GUI.run,

            running = false
        },
        GUI.mt
    )
end
---@param self GUI
---@param id number|string|nil
---@return AnyElement|nil
function GUI:getElementById(id)
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
---@param self GUI
---@param window table|nil
function GUI:draw(window)
    term.clear()
    for _, element in pairs(self.elements) do
        if element.visible then
            element:draw(self, window)
        end
    end
end
---@param self GUI
---@param window table|nil
function GUI:update(window)
    for _, element in pairs(self.elements) do
        if element.active then
            element:update(self, window)
        end
    end
end
---@param self GUI
---@param window table|nil
function GUI:event(window)
    local event = { os.pullEvent() }
    term.setCursorBlink(false)
    for _, element in pairs(self.elements) do
        if element.active then
            element:event(self, event, window)
        end
    end
end
---@param self GUI
---@param window table|nil
function GUI:run(window)
    self.running = true
    while self.running do
        self:update(window)
        self:draw(window)
        self:event(window)
    end
end

local prompt = {}
---@param msg string
---@param width integer|nil
---@param height integer|nil
function prompt.info(msg, width, height)
    local mainWindow = term.current()
    local W, H = mainWindow.getSize()
    width = width or #msg + 2
    width = width >= 10 and width or 10
    width = width <= W and width or W
    height = height or 3
    height = height >= 3 and height or 3
    height = height <= H and height or H
    local x, y = math.floor(W / 2 - width / 2), math.floor(H / 2 - height / 2)
    local promptWindow = window.create(mainWindow, x, y, width, height)
    term.redirect(promptWindow)
    term.setBackgroundColor(colors.gray)
    local page = GUI.new {
        text.Text.new {
            x = 2, y = 1, w = width - 2, h = height - 2,
            text = msg
        },
        button.Button.new {
            x = 1, y = height,
            label = "OK", color = colors.green,
            braceColor = colors.lightGray,
            key = keys.enter,
            onClick = function (self, page)
                page.running = false
            end
        },
    }
    page:run(promptWindow)
    term.redirect(mainWindow)
    promptWindow.setVisible(false)
end
---@param msg string
---@param width integer|nil
---@param height integer|nil
---@return boolean
function prompt.confirm(msg, width, height)
    local mainWindow = term.current()
    local W, H = mainWindow.getSize()
    width = width or #msg + 2
    width = width >= 10 and width or 10
    width = width <= W and width or W
    height = height or 3
    height = height >= 3 and height or 3
    height = height <= H and height or H
    local x, y = math.floor(W / 2 - width / 2), math.floor(H / 2 - height / 2)
    local promptWindow = window.create(mainWindow, x, y, width, height)
    term.redirect(promptWindow)
    term.setBackgroundColor(colors.gray)
    local confirm = false
    local page = GUI.new {
        text.Text.new {
            x = 2, y = 1, w = width - 2, h = height - 2,
            text = msg
        },
        button.Button.new {
            x = 1, y = height,
            label = "OK", color = colors.green,
            braceColor = colors.lightGray,
            key = keys.enter,
            onClick = function (self, page)
                confirm = true
                page.running = false
            end
        },
        button.Button.new {
            x = 5, y = height,
            label = "CANCEL", color = colors.red,
            braceColor = colors.lightGray,
            key = keys.leftCtrl,
            onClick = function (self, page)
                confirm = false
                page.running = false
            end
        },
    }
    page:run(promptWindow)
    term.redirect(mainWindow)
    promptWindow.setVisible(false)
    return confirm
end
---@param msg string
---@param width integer|nil
---@param height integer|nil
---@return string
function prompt.input(msg, width, height)
    local mainWindow = term.current()
    local W, H = mainWindow.getSize()
    width = width or #msg + 2
    width = width >= 10 and width or 10
    width = width <= W and width or W
    height = height or 5
    height = height >= 5 and height or 5
    height = height <= H and height or H
    local x, y = math.floor(W / 2 - width / 2), math.floor(H / 2 - height / 2)
    local promptWindow = window.create(mainWindow, x, y, width, height)
    local W, H = promptWindow.getSize()
    term.redirect(promptWindow)
    term.setBackgroundColor(colors.gray)
    local page = GUI.new {
        text.Text.new {
            x = 2, y = 1, w = width - 2, h = height - 2,
            text = msg
        },
        input.Input.new {
            id = "input",
            x = 2, y = H - 2,  w = width - 2,
            empty = "...",
            bg = colors.black
        },
        button.Button.new {
            x = 1, y = height,
            label = "OK", color = colors.green,
            braceColor = colors.lightGray,
            key = keys.enter,
            onClick = function (self, page)
                page.running = false
            end
        },
    }
    page:run(promptWindow)
    term.redirect(mainWindow)
    promptWindow.setVisible(false)
    return page:getElementById("input").input
end

return {
    element = element,
    text = text,
    button = button,
    input = input,
    container = container,
    list = list,
    prompt = prompt,
    test = function()
        term.clear()
        term.setCursorPos(1, 1)
        local page = GUI.new {
            button.Button.new {
                x = 1, y = 1,
                label = "exit",
                color = colors.red,
                onClick = function (self, page)
                    if prompt.confirm("Are you sure you wanna exit?") then
                        page.running = false
                    end
                end
            },
            input.Input.new {
                x = 1, y = 3,
            },
            text.Text.new {
                id = "text",
                x = 1, y = 5,
                text = "this is a test",
                w = 20
            },
            button.Button.new {
                x = 1, y = 6,
                label = "change",
                color = colors.yellow,
                onClick = function (self, page)
                    page:getElementById("text").text = prompt.input("What is the text supposed to be?")
                end
            },
            list.List.new {
                list = {
                    button.Button.new {
                        label = "Banana",
                        onClick = function (self)
                            prompt.info(self.label)
                        end
                    },
                    button.Button.new {
                        label = "Apple",
                        onClick = function (self)
                            prompt.info(self.label)
                        end
                    },
                    button.Button.new {
                        label = "Melone",
                        onClick = function (self)
                            prompt.info(self.label)
                        end
                    },
                    button.Button.new {
                        label = "Pineapple",
                        onClick = function (self)
                            prompt.info(self.label)
                        end
                    },
                },
                x = 1, y = 8, h = 4,
            },
        }
        page:run()
        term.clear()
        term.setCursorPos(1, 1)
    end,
    GUI = GUI,
}