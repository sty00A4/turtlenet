local location = require "turtlenet.picolua.location"
local tokens = require "turtlenet.picolua.tokens"
local lexer = require "turtlenet.picolua.lexer"
local nodes = require "turtlenet.picolua.nodes"
local parser = require "turtlenet.picolua.parser"
local bytecode = require "turtlenet.picolua.bytecode"
local compiler = require "turtlenet.picolua.compiler"
local program = require "turtlenet.picolua.program"

---@param path string
local function compile(path)
    local file = io.open(path, "r") if not file then
        return nil, ("path %q not found"):format(path)
    end
    local text = file:read("*a")
    file:close()
    local file = location.File.new(path)

    local _tokens, err, epos = lexer.lex(file, text) if err then return nil, err, epos end
    if not _tokens then return end
    local ast, err, epos = parser.parse(file, _tokens)
    if not ast then return end
    return compiler.compile(file, ast)
end
---@param code string
local function compileCode(code)
    local file = location.File.new("<input>")
    local _tokens, err, epos = lexer.lex(file, code) if err then return nil, err, epos end
    if not _tokens then return end
    local ast, err, epos = parser.parse(file, _tokens)
    if not ast then return end
    return compiler.compile(file, ast)
end
---@param code string
local function parseCode(code)
    local file = location.File.new("<input>")
    local _tokens, err, epos = lexer.lex(file, code) if err then return nil, err, epos end
    if not _tokens then return end
    return parser.parse(file, _tokens)
end
---@param path string
local function run(path)
    local compiler, err, epos = compile(path) if err then return nil, err, epos end
    if not compiler then return end
    return program.run(compiler.file, compiler)
end
---@param code string
local function runCode(code)
    local compiler, err, epos = compileCode(code) if err then return nil, err, epos end
    if not compiler then return end
    return program.run(compiler.file, compiler)
end
---@param path string
local function debug(path)
    if not term then print "debug for this system not supported" return end
    local compiler, err, epos = compile(path) if err then
        print(err) return
    end
    if not compiler then return end
    local program = program.Program.new(compiler.file, compiler)

    local W, H = term.getSize()

    local codeOffset = 0
    local codeOffsetMax = #program.code / INSTRUCTION_SIZE

    local mainWindow = term.current()
    local codeWindow = window.create(term.current(), 1, 1, W / 2, H)
    local stackWindow = window.create(term.current(), W / 2, 1, W / 2, H)
    local terminalWindow = window.create(term.current(), W / 2, 1, W / 2, H, false)
    local function drawInstr()
        term.redirect(codeWindow)
        term.clear()
        codeWindow.setVisible(true)
        local W, H = term.getSize()
        for i = 0, H - 1 do
            term.setCursorPos(1, i + 1)
            local ip = (i + codeOffset) * INSTRUCTION_SIZE + 1
            local instr, addr, count = program.code[ip], program.code[ip + INSTRUCTION_ADDR_OFFSET], program.code[ip + INSTRUCTION_COUNT_OFFSET]
            term.setTextColor(ip == program.ip and (colors.lime or colors.lightGray) or colors.white)
            if instr and addr and count then
                term.write(ip)
                term.write(": ")
                term.write(bytecode.ByteCode.tostring(instr, addr, count))
            end
            term.setTextColor(colors.white)
        end
        term.redirect(mainWindow)
    end
    local function drawStack()
        term.redirect(stackWindow)
        term.clear()
        stackWindow.setVisible(true)
        local W, H = term.getSize()
        if #program.stack == 0 then
            term.setCursorPos(1, 1)
            term.setTextColor(colors.lightGray)
            term.write("<empty stack>")
            term.setTextColor(colors.white)
            return
        end
        for i = H - 2, 0, -1 do
            term.setCursorPos(1, i + 1)
            local idx = #program.stack - i
            local value = program.stack[idx]
            if value then
                term.write(idx)
                term.write(": ")
                if type(value.value) == "string" then
                    term.write(("%q"):format(value.value))
                else
                    term.write(tostring(value.value))
                end
            end
        end
        term.redirect(mainWindow)
    end

    while true do
        term.clear()
        drawInstr()
        drawStack()
        if program.halt then
            break
        else
            stackWindow.setVisible(false)
            terminalWindow.setVisible(true)
            term.redirect(terminalWindow)
            term.clear()
            term.setCursorPos(1, 1)
            program:step()
            term.redirect(mainWindow)
            terminalWindow.setVisible(false)
        end
        while true do
            drawInstr()
            drawStack()
            term.setCursorPos(1, 1)
            ---@diagnostic disable-next-line: undefined-field
            local event, p1, p2, p3 = os.pullEvent()
            if event == "key" then
                local key = p1
                if key == keys.space then break end
            elseif event == "mouse_scroll" then
                local dir, x, y = p1, p2, p3
                local codeX, codeY, codeW, codeH = codeWindow.getPosition(), codeWindow.getSize()
                if x >= codeX and x <= codeX + codeW - 1 or y >= codeY and y <= codeY + codeH - 1 then
                    -- error(("%s %s"):format(codeOffset, codeOffsetMax))
                    codeOffset = codeOffset + dir
                    if codeOffset < 0 then codeOffset = 0 end
                    if codeOffset > codeOffsetMax then codeOffset = codeOffsetMax end
                end
            end
        end
    end
    term.redirect(mainWindow)
    codeWindow.setVisible(false)
    stackWindow.setVisible(false)
    terminalWindow.setVisible(false)
    term.clear()
    term.setCursorPos(1, 1)
end

---@class Picolua
return {
    location = location,
    tokens = tokens,
    lexer = lexer,
    nodes = nodes,
    parser = parser,
    bytecode = bytecode,
    compiler = compiler,
    program = program,
    compile = compile,
    run = run,
    compileCode = compileCode,
    parseCode = parseCode,
    runCode = runCode,
    debug = debug,
}