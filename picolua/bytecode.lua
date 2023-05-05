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

    Get = 0x10, -- varAddr
    Const = 0x11, -- constAddr
    Set = 0x12, -- varAddr
    SetConst = 0x13, -- constAddr
    Call = 0x14, -- funcAddr argAmount
    CallConst = 0x15, -- luaFuncAddr argAmount

    Number = 0x20, -- value
    Boolean = 0x21, -- value
    String = 0x22, -- value
    
    CreateTable = 0x30, -- pairAmount
}