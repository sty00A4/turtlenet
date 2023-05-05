local Parser = {
    mt = {
        __name = "parser"
    }
}
---@param file File
---@param tokens table<integer, Token>
---@return Parser
function Parser.new(file, tokens)
    return setmetatable(
        ---@class Parser
        {
            file = file, tokens = tokens,

            token = Parser.token, tokenRef = Parser.tokenRef,
            tokenCheck = Parser.tokenCheck, tokenExpect = Parser.tokenExpect
        },
        Parser.mt
    )
end

return {
    Parser = Parser
}