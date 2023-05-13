local Page = require "turtlenet.gui.page"
local element = require "turtlenet.gui.element"
local Container = require "turtlenet.gui.container"
local Text = require "turtlenet.gui.text"
local Button = require "turtlenet.gui.button"
local Input = require "turtlenet.gui.input"
local List = require "turtlenet.gui.list"

---@alias AnyElement Element|Button|Input|Text|Container|List

local GUI = {
    mt = {
        __name = "gui"
    }
}
---@param pages table<string, Page>
---@return GUI
function GUI.new(pages)
    element.checkTable(2, pages, "elements", {"number", "string"}, element.checkMetaName, "Page")
    return setmetatable(
        ---@class GUI
        {
            pages = pages,
            currentPage = pages["main"],
            getElementById = GUI.getElementById,
            exit = GUI.exit,
            getCurrentPage = GUI.getCurrentPage,
            changePage = GUI.changePage,
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
---@param id string|integer
function GUI:getElementById(id)
    return self.currentPage:getElementById(id)
end
---@param self GUI
function GUI:exit()
    self.currentPage.running = false
    self.running = false

end
---@param self GUI
---@return Page|nil
function GUI:getCurrentPage()
    return self.currentPage
end
---@param self GUI
---@param id string
function GUI:changePage(id)
    self.currentPage.running = false
    self.currentPage = self.pages[id]
    ---@diagnostic disable-next-line: undefined-field
    os.queueEvent("page_change", id)
    self.currentPage.running = true
end
---@param self GUI
---@param window table|nil
function GUI:draw(window)
    term.clear()
    self.currentPage:draw(self, window)
end
---@param self GUI
---@param window table|nil
function GUI:update(window)
    self.currentPage:update(self, window)
end
---@param self GUI
---@param window table|nil
function GUI:event(window)
    self.currentPage:event(self, window)
end
---@param self GUI
---@param window table|nil
function GUI:run(window)
    self.running = true
    while self.running do
        self.currentPage:run(self, window)
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
    local pages = GUI.new {
        main = Page.new {
            Text.new {
                x = 2, y = 1, w = width - 2, h = height - 2,
                text = msg
            },
            Button.new {
                x = 1, y = height,
                label = "OK", color = colors.green,
                braceColor = colors.lightGray,
                key = keys.enter,
                onClick = function (self, gui, page)
                    gui:exit()
                end
            },
        }
    }
    pages:run(promptWindow)
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
    local pages = GUI.new {
        main = Page.new {
            Text.new {
                x = 2, y = 1, w = width - 2, h = height - 2,
                text = msg
            },
            Button.new {
                x = 1, y = height,
                label = "OK", color = colors.green,
                braceColor = colors.lightGray,
                key = keys.enter,
                onClick = function (self, gui, page)
                    confirm = true
                    page.running = false
                end
            },
            Button.new {
                x = 5, y = height,
                label = "CANCEL", color = colors.red,
                braceColor = colors.lightGray,
                key = keys.leftCtrl,
                onClick = function (self, gui, page)
                    confirm = false
                    gui:exit()
                end
            },
        }
    }
    pages:run(promptWindow)
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
    local pages = GUI.new {
        main = Page.new {
            Text.new {
                x = 2, y = 1, w = width - 2, h = height - 2,
                text = msg
            },
            Input.new {
                id = "input",
                x = 2, y = H - 2,  w = width - 2,
                empty = "...",
                bg = colors.black
            },
            Button.new {
                x = 1, y = height,
                label = "OK", color = colors.green,
                braceColor = colors.lightGray,
                key = keys.enter,
                onClick = function (self, gui, page)
                    gui:exit()
                end
            },
        }
    }
    pages:run(promptWindow)
    term.redirect(mainWindow)
    promptWindow.setVisible(false)
    return pages:getElementById("input").input
end

return {
    Page = Page,
    element = element,
    Text = Text,
    Button = Button,
    Input = Input,
    Container = Container,
    List = List,
    prompt = prompt,
    test = function()
        term.clear()
        term.setCursorPos(1, 1)
        local pages = GUI.new {
            main = {
                Button.new {
                    x = 1, y = 1,
                    label = "exit",
                    color = colors.red,
                    onClick = function (self, gui, page)
                        if prompt.confirm("Are you sure you wanna exit?") then
                            page.running = false
                        end
                    end
                },
                Input.new {
                    x = 1, y = 3,
                },
                Text.new {
                    id = "text",
                    x = 1, y = 5,
                    text = "this is a test",
                    w = 20
                },
                Button.new {
                    x = 1, y = 6,
                    label = "change",
                    color = colors.yellow,
                    onClick = function (self, gui, page)
                        page:getElementById("text").text = prompt.input("What is the text supposed to be?")
                    end
                },
                List.new {
                    list = {
                        Button.new {
                            label = "Banana",
                            onClick = function (self)
                                prompt.info(self.label)
                            end
                        },
                        Button.new {
                            label = "Apple",
                            onClick = function (self)
                                prompt.info(self.label)
                            end
                        },
                        Button.new {
                            label = "Melone",
                            onClick = function (self)
                                prompt.info(self.label)
                            end
                        },
                        Button.new {
                            label = "Pineapple",
                            onClick = function (self)
                                prompt.info(self.label)
                            end
                        },
                    },
                    x = 1, y = 8, h = 4,
                },
            }
        }
        pages:run()
        term.clear()
        term.setCursorPos(1, 1)
    end,
    GUI = GUI,
}