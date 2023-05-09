local bytecode = require "turtlenet.picolua.bytecode"
local ByteCode = bytecode.ByteCode
local Value = {
    mt = {
        __name = "value"
    }
}
---@param value any
---@return Value
function Value.new(value)
    return setmetatable(
        ---@class Value
        {
            value = value
        },
        Value.mt
    )
end

local Program = {
    mt = {
        __name = "program"
    }
}
---@param file File
---@param compiler Compiler
---@return Program
function Program.new(file, compiler)
    return setmetatable(
        ---@class Program
        {
            file = file,
            code = compiler.code,
            consts = compiler.consts,
            
            ip = 1,
            ---@type table<integer, Value>
            stack = {},
            ---@type table<integer, Addr>
            callStack = {},

            push = Program.push, pop = Program.pop,
            const = Program.const,
            newCall = Program.newCall, returnAddr = Program.returnAddr,
            run = Program.run,
        },
        Program.mt
    )
end

---@param self Program
function Program:push(value)
    return table.insert(self.stack, Value.new(value))
end
---@param self Program
function Program:pop()
    local value = table.remove(self.stack)
    if not value then error "stack underflow" end
    return value.value
end
---@param self Program
function Program:const(addr)
    return self.consts[addr]
end
---@param self Program
---@param addr Addr
function Program:newCall(addr)
    return table.insert(self.callStack, addr)
end
---@param self Program
function Program:returnAddr()
    return table.remove(self.callStack)
end

---@param self Program
function Program:run()
    while self.ip <= #self.code do
        local instr, addr, count = self.code[self.ip], self.code[self.ip + 1], self.code[self.ip + 2]
        if instr == ByteCode.Halt then
            break
        elseif instr == ByteCode.Jump then
            self.ip = addr
        elseif instr == ByteCode.JumpIf then
            if self:pop() then
                self.ip = addr
            end
        elseif instr == ByteCode.JumpIfNot then
            if not self:pop() then
                self.ip = addr
            end
        elseif instr == ByteCode.Return then
            if not self:returnAddr() then
                self.ip = addr
            end
        elseif instr == ByteCode.Get then
            local key = self:const(addr)
            for _ = 1, count do
                self:push(_G[key])
            end
        elseif instr == ByteCode.Set then
            local key = self:const(addr)
            for _ = 1, count do
                _G[key] = self:pop()
            end
        --- todo: Field and Index
        elseif instr == ByteCode.Call then
            local func = self:pop()
            local args = {}
            for _ = 1, count do
                table.insert(args, self:pop())
            end
            local returns = { func(table.unpack(args)) }
            for _, value in ipairs(returns) do
                self:push(value)
            end
        elseif instr == ByteCode.Nil then
            self:push()
        elseif instr == ByteCode.Number then
            self:push(addr)
        elseif instr == ByteCode.Boolean then
            self:push(addr == 1 and true or false)
        elseif instr == ByteCode.String then
            self:push(self:const(addr))
        elseif instr == ByteCode.Add then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left + right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.Sub then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left - right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.Mul then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left * right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.Div then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left / right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.Mod then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left % right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.Pow then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left ^ right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.EQ then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left == right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.NE then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left ~= right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.LT then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left < right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.GT then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left > right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.LE then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left <= right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.GE then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left >= right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.And then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left and right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.Or then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left or right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.Neg then
            local right = self:pop()
            local success, value = pcall(function()
                return -right
            end)
            if not success then return nil, value end
            self:push(value)
        elseif instr == ByteCode.Not then
            local right = self:pop()
            local success, value = pcall(function()
                return not right
            end)
            if not success then return nil, value end
            self:push(value)
        end
        self.ip = self.ip + 3
    end
end

return {
    Program = Program,
    ---@param file File
    ---@param compiler Compiler
    run = function (file, compiler)
        Program.new(file, compiler):run()
    end
}