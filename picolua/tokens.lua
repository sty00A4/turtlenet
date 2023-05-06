local TokenKind
local TokenKind = {
    ---@class TokenKind
    ID = {},
    ---@class TokenKind
    Number = {},
    ---@class TokenKind
    Boolean = {},
    ---@class TokenKind
    String = {},
    
    ---@class TokenKind
    Equal = {},
    ---@class TokenKind
    Call = {},
    ---@class TokenKind
    Seprate = {},
    
    ---@class TokenKind
    Expr = {}, -- value: boolean (true = '(', false = ')')
    ---@class TokenKind
    Add = {},
    ---@class TokenKind
    Sub = {},
    ---@class TokenKind
    Mul = {},
    ---@class TokenKind
    Div = {},
    ---@class TokenKind
    Mod = {},
    ---@class TokenKind
    Pow = {},
    ---@class TokenKind
    EQ = {},
    ---@class TokenKind
    NE = {},
    ---@class TokenKind
    LT = {},
    ---@class TokenKind
    GT = {},
    ---@class TokenKind
    LE = {},
    ---@class TokenKind
    GE = {},
    ---@class TokenKind
    And = {},
    ---@class TokenKind
    Or = {},
    ---@class TokenKind
    Not = {},
    ---@class TokenKind
    BitNot = {},
    ---@class TokenKind
    BitAnd = {},
    ---@class TokenKind
    BitOr = {},
    ---@class TokenKind
    BitXor = {},
    ---@class TokenKind
    BitLeft = {},
    ---@class TokenKind
    BitRight = {},

    ---@class TokenKind
    Do = {},
    ---@class TokenKind
    Then = {},
    ---@class TokenKind
    End = {},
    ---@class TokenKind
    If = {},
    ---@class TokenKind
    ElseIf = {},
    ---@class TokenKind
    Else = {},
    ---@class TokenKind
    While = {},
    ---@class TokenKind
    For = {},
    ---@class TokenKind
    Repeat = {},
    ---@class TokenKind
    Wait = {},

    ---@param id string
    ---@return TokenKind, any
    fromWord = function(id)
        local kw = {
            ["true"] = function()
                return TokenKind.Boolean, true
            end,
            ["false"] = function()
                return TokenKind.Boolean, false
            end,
            ["and"] = function()
                return TokenKind.And
            end,
            ["or"] = function()
                return TokenKind.Or
            end,
            ["not"] = function()
                return TokenKind.Not
            end,
            ["do"] = function()
                return TokenKind.Do
            end,
            ["then"] = function()
                return TokenKind.Then
            end,
            ["end"] = function()
                return TokenKind.End
            end,
            ["if"] = function()
                return TokenKind.If
            end,
            ["elseif"] = function()
                return TokenKind.ElseIf
            end,
            ["else"] = function()
                return TokenKind.Else
            end,
            ["while"] = function()
                return TokenKind.While
            end,
            ["for"] = function()
                return TokenKind.For
            end,
            ["repeat"] = function()
                return TokenKind.Repeat
            end,
            ["wait"] = function()
                return TokenKind.Wait
            end,
        }
        local handle = kw[id] if not handle then
            return TokenKind.ID, id
        end
        return handle()
    end
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