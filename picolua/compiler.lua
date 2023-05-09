local bytecode = require "turtlenet.picolua.bytecode"
local ByteCode = bytecode.ByteCode

---@alias Code table<integer, ByteCode>

---@param code Code
---@param instr ByteCode
---@param addr Addr|nil
---@param count integer|nil
local function writeCode(code, instr, addr, count)
    addr = addr or 0
    count = count or 1
    table.insert(code, instr)
    table.insert(code, addr)
    table.insert(code, count)
end
---@param code Code
---@param pos Addr
---@param instr ByteCode
---@param addr Addr|nil
---@param count integer|nil
local function insertCode(code, pos, instr, addr, count)
    addr = addr or 0
    count = count or 1
    table.insert(code, pos, count)
    table.insert(code, pos, addr)
    table.insert(code, pos, instr)
end
---@param code Code
---@param pos Addr
---@param instr ByteCode
---@param addr Addr|nil
---@param count integer|nil
local function overwriteCode(code, pos, instr, addr, count)
    addr = addr or 0
    count = count or 1
    code[pos] = instr
    code[pos + INSTRUCTION_ADDR_OFFSET] = addr
    code[pos + INSTRUCTION_COUNT_OFFSET] = count
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
            currentPos = Compiler.currentPos,

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
function Compiler:currentPos()
    return #self.code + 1
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
    if statement.type == "block-node" then
        local nodes = statement.nodes
        for _, statement in ipairs(nodes) do
            local _, err, epos = self:statement(statement) if err then return nil, err, epos end
        end
    end
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
    if statement.type == "repeat-node" then
        local count, body = statement.count, statement.body
        local typ, err, epos = self:expression(count) if err then return nil, err, epos end
        local addr = self:currentPos()
        local _, err, epos = self:statement(body) if err then return nil, err, epos end
        writeCode(self.code, ByteCode.Number, 1)
        writeCode(self.code, ByteCode.Sub)
        writeCode(self.code, ByteCode.Copy)
        writeCode(self.code, ByteCode.Number, 0)
        writeCode(self.code, ByteCode.LE)
        writeCode(self.code, ByteCode.JumpIfNot, addr)
    end
    if statement.type == "if-node" then
        local conds, cases, elseCase = statement.conds, statement.cases, statement.elseCase
        local addExitAddrQueue = {}
        for i = 1, #conds do
            local cond, case = conds[i], cases[i]
            local typ, err, epos = self:expression(cond) if err then return nil, err, epos end
            local bodyAddr = self:currentPos()
            writeCode(self.code, ByteCode.None) -- placeholder
            local _, err, epos = self:statement(case) if err then return nil, err, epos end
            local exitAddr = self:currentPos()
            overwriteCode(self.code, bodyAddr, ByteCode.JumpIfNot, exitAddr + INSTRUCTION_SIZE)
            table.insert(addExitAddrQueue, self:currentPos())
            writeCode(self.code, ByteCode.Jump)
        end
        if elseCase then
            local _, err, epos = self:statement(elseCase) if err then return nil, err, epos end
        end
        local exitAddr = self:currentPos()
        for _, addr in ipairs(addExitAddrQueue) do
            self.code[addr + INSTRUCTION_ADDR_OFFSET] = exitAddr
        end
    end
    if statement.type == "while-node" then
        local cond, body = statement.cond, statement.body
        local condAddr = self:currentPos()
        local typ, err, epos = self:expression(cond) if err then return nil, err, epos end
        local bodyAddr = self:currentPos()
        writeCode(self.code, ByteCode.None) -- placeholder
        local _, err, epos = self:statement(body) if err then return nil, err, epos end
        local exitAddr = self:currentPos()
        writeCode(self.code, ByteCode.Jump, condAddr)
        overwriteCode(self.code, bodyAddr, ByteCode.JumpIfNot, exitAddr + INSTRUCTION_SIZE * 2)
    end
    if statement.type == "wait-node" then
        local cond = statement.cond
        local addr = self:currentPos()
        local typ, err, epos = self:expression(cond) if err then return nil, err, epos end
        writeCode(self.code, ByteCode.JumpIfNot, addr)
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
            local instr1, addr1, count1 = self.code[ip], self.code[ip + INSTRUCTION_ADDR_OFFSET], self.code[ip + INSTRUCTION_COUNT_OFFSET]
            ip = ip + INSTRUCTION_SIZE
            if instr1 ~= ByteCode.Call and instr1 ~= ByteCode.CreateTable then
                local instr2, addr2, count2 = self.code[ip], self.code[ip + INSTRUCTION_ADDR_OFFSET], self.code[ip + INSTRUCTION_COUNT_OFFSET]
                if instr1 == instr2 and addr1 == addr2 then
                    local newCount = count1 + count2
                    while instr1 == instr2 and addr1 == addr2 do
                        table.remove(self.code, ip) table.remove(self.code, ip) table.remove(self.code, ip) -- remove instruction
                        instr2, addr2, count2 = self.code[ip], self.code[ip + INSTRUCTION_ADDR_OFFSET], self.code[ip + INSTRUCTION_COUNT_OFFSET]
                        newCount = newCount + count2
                    end
                    ip = ip - INSTRUCTION_SIZE
                    self.code[ip], self.code[ip + INSTRUCTION_ADDR_OFFSET], self.code[ip + INSTRUCTION_COUNT_OFFSET] = instr1, addr1, newCount
                    ip = ip + INSTRUCTION_SIZE
                end
            end
        end
    end,
    ---@param self Compiler
    jumpNegation = function (self)
        local ip = 1
        while ip <= #self.code do
            local instr1, _, count1 = self.code[ip], self.code[ip + INSTRUCTION_ADDR_OFFSET], self.code[ip + INSTRUCTION_COUNT_OFFSET]
            ip = ip + INSTRUCTION_SIZE
            if instr1 == ByteCode.Not and count1 == 1 then
                local instr2, addr = self.code[ip], self.code[ip + INSTRUCTION_ADDR_OFFSET]
                if instr2 == ByteCode.JumpIfNot then
                    ip = ip - INSTRUCTION_SIZE
                    table.remove(self.code, ip) table.remove(self.code, ip) table.remove(self.code, ip)
                    self.code[ip], self.code[ip + INSTRUCTION_ADDR_OFFSET], self.code[ip + INSTRUCTION_COUNT_OFFSET] = ByteCode.JumpIf, addr, 0
                    ip = ip + INSTRUCTION_SIZE
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