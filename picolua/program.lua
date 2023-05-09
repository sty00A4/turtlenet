local location = require "turtlenet.picolua.location"
local Position = location.Position
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

local function fromLuaError(error)
    if type(error) == "string" then
        local idx = 1
        while error:sub(idx, idx) ~= ":" do
            idx = idx + 1
        end
        idx = idx + 1
        while error:sub(idx, idx) ~= ":" do
            idx = idx + 1
        end
        idx = idx + 2
        return error:sub(idx)
    elseif type(error) then
        return error.msg
    else
        return "unknown error"
    end
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

            push = Program.push, pop = Program.pop, popSafe = Program.popSafe,
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
    if not value then error("stack underflow", 2) end
    return value.value
end
---@param self Program
function Program:popSafe()
    return table.remove(self.stack)
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

---@param instr ByteCode
---@param left any
---@param right any
local function attemptBinaryError(instr, left, right)
    return ("attempt to perform '%s' on %s with %s"):format(ByteCode.name(instr), type(left), type(right))
end
---@param instr ByteCode
---@param right any
local function attemptUnaryError(instr, right)
    return ("attempt to perform '%s' on %s"):format(ByteCode.name(instr), type(right))
end
---@param self Program
function Program:run()
    while self.ip <= #self.code do
        local instr, addr, count, ln, col = self.code[self.ip], self.code[self.ip + INSTRUCTION_ADDR_OFFSET], self.code[self.ip + INSTRUCTION_COUNT_OFFSET],
        self.code[self.ip + INSTRUCTION_LN_OFFSET], self.code[self.ip + INSTRUCTION_COL_OFFSET]
        if instr == ByteCode.None then
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Halt then
            break
        elseif instr == ByteCode.Jump then
            self.ip = addr
        elseif instr == ByteCode.JumpIf then
            if self:pop() then
                self.ip = addr
            else
                self.ip = self.ip + INSTRUCTION_SIZE
            end
        elseif instr == ByteCode.JumpIfNot then
            if not self:pop() then
                self.ip = addr
            else
                self.ip = self.ip + INSTRUCTION_SIZE
            end
        elseif instr == ByteCode.Return then
            local addr = self:returnAddr()
            if addr then
                self.ip = addr
            else
                return nil, "no where to return to"
            end
        elseif instr == ByteCode.Get then
            local key = self:const(addr)
            for _ = 1, count do
                self:push(_G[key])
            end
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Set then
            local key = self:const(addr)
            for _ = 1, count do
                _G[key] = self:popSafe()
            end
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Field then
            local field = self:const(addr)
            local head = self:pop()
            if type(head) ~= "table" then
                return nil, ("attempt to index into a %s"):format(type(head)), Position.new(self.file, ln, ln, col, col)
            end
            self:push(head[field])
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Index then
            local index = self:pop()
            local head = self:pop()
            if type(head) ~= "table" then
                return nil, ("attempt to index into a %s"):format(type(head)), Position.new(self.file, ln, ln, col, col)
            end
            if type(index) ~= "number" and type(index) ~= "string" then
                return nil, ("attempt to index with a %s"):format(type(index)), Position.new(self.file, ln, ln, col, col)
            end
            self:push(head[index])
            self.ip = self.ip + INSTRUCTION_SIZE
        --- todo: Field and Index
        elseif instr == ByteCode.Call or instr == ByteCode.CallReturn then
            local func = self:pop()
            if type(func) ~= "function" then
                return nil, ("attempt to call a %s"):format(type(func)), Position.new(self.file, ln, ln, col, col)
            end
            local args = {}
            for i = count, 1, -1 do
                args[i] = self:pop()
            end
            local returns = { pcall(func, table.unpack(args)) }
            local success = table.remove(returns, 1)
            if not success then
                return nil, fromLuaError(returns), Position.new(self.file, ln, ln, col, col)
            end
            if instr == ByteCode.CallReturn then
                for _, value in ipairs(returns) do
                    self:push(value)
                end
            end
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Nil then
            for i = 1, count do
                self:push()
            end
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Number then
            for i = 1, count do
                self:push(addr)
            end
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Boolean then
            for i = 1, count do
                self:push(addr == 1 and true or false)
            end
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.String then
            for i = 1, count do
                self:push(self:const(addr))
            end
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Add then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left + right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Sub then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left - right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Mul then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left * right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Div then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left / right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Mod then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left % right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Pow then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left ^ right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.EQ then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left == right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.NE then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left ~= right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.LT then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left < right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.GT then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left > right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.LE then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left <= right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.GE then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left >= right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.And then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left and right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Or then
            local right, left = self:pop(), self:pop()
            local success, value = pcall(function()
                return left or right
            end)
            if not success then return nil, attemptBinaryError(instr, left, right), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Neg then
            local right = self:pop()
            local success, value = pcall(function()
                return -right
            end)
            if not success then return nil, attemptUnaryError(instr, type(right)), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Not then
            local right = self:pop()
            local success, value = pcall(function()
                return not right
            end)
            if not success then return nil, attemptUnaryError(instr, type(right)), Position.new(self.file, ln, ln, col, col) end
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Copy then
            local value = self:pop()
            self:push(value)
            self:push(value)
            self.ip = self.ip + INSTRUCTION_SIZE
        elseif instr == ByteCode.Swap then
            local b, a = self:pop(), self:pop()
            self:push(b)
            self:push(a)
            self.ip = self.ip + INSTRUCTION_SIZE
        else
            error(("todo: %s (raw = 0x%x %s %s)"):format(ByteCode.tostring(instr, addr, count), instr, addr, count))
        end
    end
end

return {
    Program = Program,
    ---@param file File
    ---@param compiler Compiler
    run = function (file, compiler)
        return Program.new(file, compiler):run()
    end
}