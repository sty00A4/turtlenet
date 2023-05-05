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
    program = program
}