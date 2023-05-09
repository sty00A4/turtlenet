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
    run = function(path)
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
        local ast, err, epos = parser.parse(file, _tokens) if err then return nil, err, epos end
        if not ast then return end
        print(ast)
        local compiler, err, epos = compiler.compile(file, ast)if err then return nil, err, epos end
        if not compiler then return end
        print(bytecode.ByteCode.displayCode(compiler.code))
        return program.run(file, compiler)
    end
}