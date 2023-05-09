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
    GetAddr = 0x11,
    Field = 0x12, -- constAddr
    FieldAddr = 0x13,
    Index = 0x14,
    IndexAddr = 0x15,
    Set = 0x16,
    Call = 0x17, -- funcAddr argAmount

    Number = 0x20, -- value
    Boolean = 0x21, -- value
    String = 0x22, -- value
    
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

return {
    ByteCode = ByteCode
}