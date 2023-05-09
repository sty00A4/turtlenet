local bytecode = require "turtlenet.picolua.bytecode"
local ByteCode = bytecode.ByteCode

---@alias Code table<integer, ByteCode>

---@param code Code
---@param bytecode ByteCode
---@param addr integer
---@param count integer
local function writeCode(code, bytecode, addr, count)
    table.insert(code, bytecode)
    table.insert(code, addr)
    table.insert(code, count)
end

local Compiler = {
    mt = {
        __name = "compiler"
    }
}
---@param file File
---@return Compiler
function Compiler.new(file)
    return setmetatable(
        ---@class Compiler
        {
            file = file,

            ---@type Code
            code = {},
            ---@type table<ConstAddr, any>
            consts = {},
            ---@type table<VarAddr, boolean>
            varAddrs = {},
            ---@type table<string, VarAddr>
            vars = {},
            ---@type table<FuncAddr, Addr>
            funcs = {},
            ---@type table<LuaFuncAddr, function>
            luaFuncs = {},

            chunk = Compiler.chunk,
            statement = Compiler.statement,
            expression = Compiler.expression,
            path = Compiler.path,
            getPath = Compiler.getPath,
        },
        Compiler.mt
    )
end

---@param self Compiler
---@param chunk ChunkNode
function Compiler:chunk(chunk)
    for _, statement in ipairs(chunk.nodes) do
        local _, err, epos = self:statement(statement) if err then return nil, err, epos end
    end
end
---@param self Compiler
---@param statement StatementNode
function Compiler:statement(statement)
    if statement.type == "assign-node" then
        local path, value = statement.path, statement.value
        local typ, err, epos = self:expression(value) if err then return nil, err, epos end
        local _, err, epos = self:getPath(path) if err then return nil, err, epos end
        writeCode(self.code, ByteCode.Set, 0, 0)
    end
    if statement.type == "call-node" then
        local head, args = statement.head, statement.args
        for _, arg in ipairs(args) do
            local typ, err, epos = self:expression(arg) if err then return nil, err, epos end
        end
        local _, err, epos = self:path(head) if err then return nil, err, epos end
        writeCode(self.code, ByteCode.Call, 0, #args)
    end
end
---@param self Compiler
---@param expression EvalNode
function Compiler:expression(expression)
    if expression.type == "id-node" or expression.type == "field-node" or expression.type == "index-node" then
        return self:path(expression)
    elseif expression.type == "number-node" then
        ---@type number
        ---@diagnostic disable-next-line: assign-type-mismatch
        local value = expression.value
        writeCode(self.code, ByteCode.Number, value, 0)
    elseif expression.type == "boolean-node" then
        ---@type boolean
        ---@diagnostic disable-next-line: assign-type-mismatch
        local value = expression.value
        writeCode(self.code, ByteCode.Boolean, value and 1 or 0, 0)
    elseif expression.type == "string-node" then
        local addr = #self.consts + 1
        table.insert(self.consts, expression.value)
        writeCode(self.code, ByteCode.String, addr, 0)
    elseif expression.type == "binary-node" then
        ---@type BinaryOperator
        ---@diagnostic disable-next-line: assign-type-mismatch
        local op, left, right = expression.op, expression.left, expression.right
        local leftType, err, epos = self:expression(left) if err then return nil, err, epos end
        local rightType, err, epos = self:expression(right) if err then return nil, err, epos end
        ---@type table<BinaryOperator, ByteCode>
        local binaryByteCode = {
            ["+"] = ByteCode.Add,
            ["-"] = ByteCode.Sub,
            ["*"] = ByteCode.Mul,
            ["/"] = ByteCode.Div,
            ["%"] = ByteCode.Mod,
            ["^"] = ByteCode.Pow,
            ["=="] = ByteCode.EQ,
            ["~="] = ByteCode.NE,
            ["<"] = ByteCode.LT,
            [">"] = ByteCode.GT,
            ["<="] = ByteCode.LE,
            [">="] = ByteCode.GE,
            ["and"] = ByteCode.And,
            ["or"] = ByteCode.Or,
        }
        writeCode(self.code, binaryByteCode[op], 0, 0)
    elseif expression.type == "unary-node" then
        ---@type UnaryOperator
        ---@diagnostic disable-next-line: assign-type-mismatch
        local op, right = expression.op, expression.right
        local rightType, err, epos = self:expression(right) if err then return nil, err, epos end
        ---@type table<UnaryOperator, ByteCode>
        local unaryByteCode = {
            ["-"] = ByteCode.Neg,
            ["not"] = ByteCode.Not,
        }
        writeCode(self.code, unaryByteCode[op], 0, 0)
    end
end
---@param self Compiler
---@param path PathNode
function Compiler:path(path)
    if path.type == "id-node" then
        local id = path.id
        local addr = #self.consts + 1
        table.insert(self.consts, id)
        writeCode(self.code, ByteCode.Get, addr, 0)
    elseif path.type == "field-node" then
        local head, field = path.head, path.field
        local _, err, epos = self:path(head) if err then return nil, err, epos end
        local addr = #self.consts + 1
        table.insert(self.consts, field)
        writeCode(self.code, ByteCode.Field, addr, 0)
    elseif path.type == "index-node" then
        local head, index = path.head, path.field
        local _, err, epos = self:path(head) if err then return nil, err, epos end
        local typ, err, epos = self:expression(index) if err then return nil, err, epos end
        writeCode(self.code, ByteCode.Index, 0, 0)
    end
end
---@param self Compiler
---@param path PathNode
function Compiler:getPath(path)
    if path.type == "id-node" then
        local id = path.id
        writeCode(self.code, ByteCode.GetAddr, self.vars[id] or -1, 0)
    elseif path.type == "field-node" then
        local head, field = path.head, path.field
        local _, err, epos = self:path(head) if err then return nil, err, epos end
        local addr = #self.consts + 1
        table.insert(self.consts, field)
        writeCode(self.code, ByteCode.Field, addr, 0)
    elseif path.type == "index-node" then
        local head, index = path.head, path.field
        local _, err, epos = self:path(head) if err then return nil, err, epos end
        local typ, err, epos = self:expression(index) if err then return nil, err, epos end
        writeCode(self.code, ByteCode.Index, 0, 0)
    end
end

return {
    Compiler = Compiler,
    writeCode = writeCode,
    ---@param file File
    ---@param ast ChunkNode
    compile = function (file, ast)
        local compiler = Compiler.new(file)
        local _, err, epos = compiler:chunk(ast) if err then return nil, err, epos end
        return compiler
    end
}