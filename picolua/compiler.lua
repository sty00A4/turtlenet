---@alias Code table<integer, ByteCode>

---@param code Code
---@param bytecode ByteCode
local function writeCode(code, bytecode)
    table.insert(code, bytecode)
end

local Compiler = {
    mt = {
        __name = "compiler"
    }
}
---@return Compiler
function Compiler.new()
    return setmetatable(
        ---@class Compiler
        {
            ---@type table<ConstAddr, any>
            consts = {},
            ---@type table<VarAddr, boolean>
            varAddrs = {},
            ---@type table<FuncAddr, Addr>
            funcs = {},
            ---@type table<LuaFuncAddr, function>
            luaFuncs = {},
        },
        Compiler.mt
    )
end

return {
    Compiler = Compiler,
    writeCode = writeCode
}