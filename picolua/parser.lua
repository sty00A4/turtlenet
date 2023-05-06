local Parser = {
    mt = {
        __name = "parser"
    }
}
---@param file File
---@param tokens Lines
---@return Parser
function Parser.new(file, tokens)
    return setmetatable(
        ---@class Parser
        {
            file = file, tokens = tokens,

            token = Parser.token, tokenRef = Parser.tokenRef,
            tokenCheck = Parser.tokenCheck, tokenExpect = Parser.tokenExpect,
            chunk = Parser.chunk, block = Parser.block,
            statement = Parser.statement, expression = Parser.expression,
            binary = Parser.binary, unary = Parser.unary,
            atom = Parser.atom, path = Parser.path,
        },
        Parser.mt
    )
end

return {
    Parser = Parser,
    ---@param file File
    ---@param tokens Lines
    parse = function(file, tokens)
        return Parser.new(file, tokens):chunk()
    end
}