function table.contains(t, item)
    for k, v in pairs(t) do
        if v == item then
            return true
        end
    end
    return false
end

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
    -- for ln, line in ipairs(_tokens) do
    --     io.write(("%s: "):format(ln))
    --     for _, token in ipairs(line) do
    --         io.write(tostring(token), " ")
    --     end
    --     print()
    -- end
    local ast, err, epos = parser.parse(file, _tokens)
    if not ast then return end
    -- print(ast)
    return compiler.compile(file, ast)
end
---@param path string
local function run(path)
    local compiler, err, epos = compile(path) if err then return nil, err, epos end
    if not compiler then return end
    -- print(bytecode.ByteCode.displayCode(compiler.code))
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
    local codeOffset = 0
    local W, H = term.getSize()
    local function drawInstr()
        for i = 0, H - 2 do
            term.setCursorPos(1, i + 1)
            local ip = (i + codeOffset) * INSTRUCTION_SIZE + 1
            local instr, addr, count = program.code[ip], program.code[ip + INSTRUCTION_ADDR_OFFSET], program.code[ip + INSTRUCTION_COUNT_OFFSET]
            term.setTextColor(ip == program.ip and colors.lime or colors.white)
            if instr and addr and count then
                term.write(ip)
                term.write(": ")
                term.write(bytecode.ByteCode.tostring(instr, addr, count))
            end
            term.setTextColor(colors.white)
        end
    end
    local function drawStack()
        for i = H - 2, 0, -1 do
            term.setCursorPos(W / 2, i + 1)
            term.write((" "):rep(math.ceil(W / 2)))
            term.setCursorPos(W / 2, i + 1)
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
    end

    while true do
        term.clear()
        drawInstr()
        drawStack()
        if program.halt then
            break
        else
            local msg = "proccessing instr ... "
            term.setCursorPos(W / 2 - #msg, H)
            term.write(msg)
            program:step()
            term.clearLine()
        end
        while true do
            drawInstr()
            drawStack()
            ---@diagnostic disable-next-line: undefined-field
            local _, key = os.pullEvent("key")
            if key == keys.space then break end
        end
    end
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
    debug = debug,
}