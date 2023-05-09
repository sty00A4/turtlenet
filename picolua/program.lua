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
            
            ip = 1,
            consts = compiler.consts, varAddrs = compiler.varAddrs,
            funcs = compiler.funcs, luaFuncs = compiler.luaFuncs,

            run = Program.run
        },
        Program.mt
    )
end

return {
    Program = Program,
    ---@param file File
    ---@param compiler Compiler
    run = function (file, compiler)
        return Program.new(file, compiler):run()
    end
}