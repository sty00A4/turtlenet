local Lexer = {
    mt = {
        __name = "lexer"
    }
}
---@param file File
---@param text string
---@return Lexer
function Lexer.new(file, text)
    return setmetatable(
        ---@class Lexer
        {
            file = file, text = text,

            idx = 1, col = 1, ln = 1,

            advance = Lexer.advance, get = Lexer.get,
            whiteSpace = Lexer.whiteSpace,
            next = Lexer.next, lex = Lexer.lex
        },
        Lexer.mt
    )
end

return {
    Lexer = Lexer
}