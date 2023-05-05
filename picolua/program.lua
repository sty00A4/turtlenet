local Program = {
    mt = {
        __name = "program"
    }
}
---@param code Code
---@param compiler Compiler
---@return Program
function Program.new(code, compiler)
    return setmetatable(
        ---@class Program
        {
            code = code,
            
            ip = 1,
            consts = compiler.consts, varAddrs = compiler.varAddrs,
            funcs = compiler.funcs, luaFuncs = compiler.luaFuncs,

            run = Program.run
        },
        Program.mt
    )
end