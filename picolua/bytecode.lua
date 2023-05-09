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
    Return = 0x05, -- value?

    Get = 0x10, -- constAddr
    Set = 0x11,
    Field = 0x12, -- constAddr
    SetField = 0x13, -- constAddr
    Index = 0x14,
    SetIndex = 0x15,
    Call = 0x16, -- funcAddr argAmount

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
}

---@param code Code
function ByteCode.displayCode(code)
    local s = ""
    local idx = 1
    while idx <= #code do
        local instr, addr, count = code[idx], code[idx + 1], code[idx + 2]
        local instrName = "?"
        for name, number in pairs(ByteCode) do
            if instr == number then
                instrName = name:upper()
            end
        end
        s = s .. ("%s\t%s\t%s"):format(instrName, addr, count) .. "\n"

        idx = idx + 3
    end
    return s
end

return {
    ByteCode = ByteCode
}