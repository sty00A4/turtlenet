local TokenKind = {
    ---@class TokenKind
    ID = {},
    ---@class TokenKind
    Number = {},
    ---@class TokenKind
    Boolean = {},
    ---@class TokenKind
    String = {},
}

local Token = {
    mt = {
        __name = "token"
    }
}
---@param kind TokenKind
---@param value any
---@param pos Position
---@return Token
function Token.new(kind, value, pos)
    return setmetatable(
        ---@class Token
        {
            kind = kind, value = value, pos = pos
        },
        Token.mt
    )
end

return {
    Token = Token,
    TokenKind = TokenKind
}