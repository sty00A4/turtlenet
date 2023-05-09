INSTRUCTION_SIZE = 5
INSTRUCTION_ADDR_OFFSET = 1
INSTRUCTION_COUNT_OFFSET = 2
INSTRUCTION_LN_OFFSET = 3
INSTRUCTION_COL_OFFSET = 4

---@alias ByteCode integer
---@alias Addr integer
---@alias VarAddr integer
---@alias ConstAddr integer
---@alias FuncAddr integer
---@alias LuaFuncAddr integer

--- [INSTR] [ARG1] [ARG2]
local ByteCode = {
    None = 0x00,
    Halt = 0x01,
    Jump = 0x02, -- addr
    JumpIf = 0x03, -- addr
    JumpIfNot = 0x04, -- addr
    Return = 0x05,

    Get = 0x10, -- constAddr
    Set = 0x11,
    Field = 0x12, -- constAddr
    SetField = 0x13, -- constAddr
    Index = 0x14,
    SetIndex = 0x15,
    Call = 0x16, -- funcAddr argAmount
    CallReturn = 0x17, -- funcAddr argAmount

    Nil = 0x20,
    Number = 0x21, -- value
    Boolean = 0x22, -- value
    String = 0x23, -- value
    
    CreateTable = 0x30, -- pairAmount

    Add = 0x40,
    Sub = 0x41,
    Mul = 0x42,
    Div = 0x43,
    Mod = 0x44,
    Pow = 0x45,
    EQ = 0x46,
    NE = 0x47,
    LT = 0x48,
    GT = 0x49,
    LE = 0x4a,
    GE = 0x4b,
    And = 0x4c,
    Or = 0x4d,
    Neg = 0x4e,
    Not = 0x4f,
    Copy = 0x60,
    Swap = 0x61,
}

---@param code Code
---@param start integer|nil
---@param stop integer|nil
function ByteCode.displayCode(code, start, stop)
    start = start or 0
    stop = stop or math.floor(#code / INSTRUCTION_SIZE)
    local s = ""
    local idx = (start * INSTRUCTION_SIZE) + 1
    while idx <= (stop * INSTRUCTION_SIZE) + 1 do
        local instr, addr, count = code[idx], code[idx + INSTRUCTION_ADDR_OFFSET], code[idx + INSTRUCTION_COUNT_OFFSET]
        if not (instr and addr and count) then break end
        local instrName = "?"
        for name, number in pairs(ByteCode) do
            if instr == number then
                instrName = name:upper()
            end
        end
        s = s .. ("%s: %s"):format(idx, ByteCode.tostring(instr, addr, count)) .. "\n"
        idx = idx + INSTRUCTION_SIZE
    end
    return s
end
---@param instr ByteCode
---@param addr Addr
---@param count integer
function ByteCode.tostring(instr, addr, count)
    local instrName = "?"
    for name, number in pairs(ByteCode) do
        if instr == number then
            instrName = name:upper()
        end
    end
    return ("%s\t%s\t%s"):format(
        instrName,
        addr == 0 and " " or addr,
        (count == 1 and instr ~= ByteCode.Call and instr ~= ByteCode.CreateTable) and " " or count
    )
end
---@param instr ByteCode
function ByteCode.name(instr)
    local names = {
        [ByteCode.Add] = "add",
        [ByteCode.Sub] = "sub",
        [ByteCode.Mul] = "mul",
        [ByteCode.Div] = "div",
        [ByteCode.Mod] = "mod",
        [ByteCode.Pow] = "pow",
        [ByteCode.EQ] = "eq",
        [ByteCode.NE] = "ne",
        [ByteCode.LT] = "lt",
        [ByteCode.GT] = "gt",
        [ByteCode.LE] = "le",
        [ByteCode.LT] = "ge",
        [ByteCode.And] = "and",
        [ByteCode.Or] = "or",
        [ByteCode.Neg] = "neg",
        [ByteCode.Not] = "not",
    }
    return names[instr] or "?"
end

return {
    ByteCode = ByteCode
}