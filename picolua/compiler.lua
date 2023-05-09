local bytecode = require "turtlenet.picolua.bytecode"
local ByteCode = bytecode.ByteCode

---@alias Code table<integer, ByteCode>

---@param code Code
---@param bytecode ByteCode
---@param addr integer|nil
---@param count integer|nil
local function writeCode(code, bytecode, addr, count)
    addr = addr or 0
    count = count or 1
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

            newConst = Compiler.newConst,

            chunk = Compiler.chunk,
            statement = Compiler.statement,
            expression = Compiler.expression,
            path = Compiler.path,

            optimisations = Compiler.optimisations
        },
        Compiler.mt
    )
end

---@param self Compiler
function Compiler:newConst(value)
    for addr, const in pairs(self.consts) do
        if value == const then
            return addr
        end
    end
    local addr = #self.consts + 1
    self.consts[addr] = value
    return addr
end

---@param self Compiler
---@param chunk ChunkNode
function Compiler:chunk(chunk)
    for _, statement in ipairs(chunk.nodes) do
        local _, err, epos = self:statement(statement) if err then return nil, err, epos end
    end
    writeCode(self.code, ByteCode.Halt)
end
---@param self Compiler
---@param statement StatementNode
function Compiler:statement(statement)
    if statement.type == "assign-node" then
        local paths, values = statement.paths, statement.values
        for i = 1, #paths do
            local path, value = paths[i], values[i]
            if value then
                local typ, err, epos = self:expression(value) if err then return nil, err, epos end
            else
                writeCode(self.code, ByteCode.Nil)
            end
            if path.type == "id-node" then
                local addr = self:newConst(path.id)
                writeCode(self.code, ByteCode.Set, addr)
            else
                return nil, "field assignment not supported yet", path.pos
            end
        end
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
        writeCode(self.code, ByteCode.Number, value)
    elseif expression.type == "boolean-node" then
        ---@type boolean
        ---@diagnostic disable-next-line: assign-type-mismatch
        local value = expression.value
        writeCode(self.code, ByteCode.Boolean, value and 1 or 0)
    elseif expression.type == "string-node" then
        local addr = self:newConst(expression.value)
        writeCode(self.code, ByteCode.String, addr)
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
        writeCode(self.code, binaryByteCode[op])
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
        writeCode(self.code, unaryByteCode[op])
    end
end
---@param self Compiler
---@param path PathNode
function Compiler:path(path)
    if path.type == "id-node" then
        local id = path.id
        local addr = self:newConst(id)
        writeCode(self.code, ByteCode.Get, addr)
    elseif path.type == "field-node" then
        local head, field = path.head, path.field
        local _, err, epos = self:path(head) if err then return nil, err, epos end
        local addr = self:newConst(field)
        writeCode(self.code, ByteCode.Field, addr)
    elseif path.type == "index-node" then
        local head, index = path.head, path.field
        local _, err, epos = self:path(head) if err then return nil, err, epos end
        local typ, err, epos = self:expression(index) if err then return nil, err, epos end
        writeCode(self.code, ByteCode.Index)
    end
end

Compiler.optimisations = {
    ---@param self Compiler
    count = function (self)
        local ip = 1
        while ip <= #self.code do
            local instr1, addr1, count1 = self.code[ip], self.code[ip + 1], self.code[ip + 2]
            ip = ip + 3
            if instr1 ~= ByteCode.Call and instr1 ~= ByteCode.CreateTable then
                local instr2, addr2, count2 = self.code[ip], self.code[ip + 1], self.code[ip + 2]
                if instr1 == instr2 and addr1 == addr2 then
                    local newCount = count1 + count2
                    while instr1 == instr2 and addr1 == addr2 do
                        table.remove(self.code, ip) table.remove(self.code, ip) table.remove(self.code, ip) -- remove instruction
                        instr2, addr2, count2 = self.code[ip], self.code[ip + 1], self.code[ip + 2]
                        newCount = newCount + count2
                    end
                    ip = ip - 3
                    self.code[ip], self.code[ip + 1], self.code[ip + 2] = instr1, addr1, newCount
                    ip = ip + 3
                end
            end
        end
    end,
    ---@param self Compiler
    jumpNegation = function (self)
        local ip = 1
        while ip <= #self.code do
            local instr1, _, count1 = self.code[ip], self.code[ip + 1], self.code[ip + 2]
            ip = ip + 3
            if instr1 == ByteCode.Not and count1 == 1 then
                local instr2, addr = self.code[ip], self.code[ip + 1]
                if instr2 == ByteCode.JumpIfNot then
                    ip = ip - 3
                    table.remove(self.code, ip) table.remove(self.code, ip) table.remove(self.code, ip)
                    self.code[ip], self.code[ip + 1], self.code[ip + 2] = ByteCode.JumpIf, addr, 0
                    ip = ip + 3
                end
            end
        end
    end,
}

return {
    Compiler = Compiler,
    writeCode = writeCode,
    ---@param file File
    ---@param ast ChunkNode
    compile = function (file, ast)
        local compiler = Compiler.new(file)
        local _, err, epos = compiler:chunk(ast) if err then return nil, err, epos end
        compiler.optimisations.count(compiler)
        return compiler
    end
}