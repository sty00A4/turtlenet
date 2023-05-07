local TokenKind
TokenKind = {
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
    ExprIn = {},
    ---@class TokenKind
    ExprOut = {},
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
    end,
    ---@param kind TokenKind
    tostring = function (kind)
        if kind == TokenKind.ID then
            return "id"
        elseif kind == TokenKind.Number then
            return "number"
        elseif kind == TokenKind.Boolean then
            return "boolean"
        elseif kind == TokenKind.String then
            return "string"
        elseif kind == TokenKind.Equal then
            return "equal"
        elseif kind == TokenKind.Call then
            return "call"
        elseif kind == TokenKind.Seprate then
            return "seperate"
        elseif kind == TokenKind.Expr then
            return "expr"
        elseif kind == TokenKind.Add then
            return "add"
        elseif kind == TokenKind.Sub then
            return "sub"
        elseif kind == TokenKind.Mul then
            return "mul"
        elseif kind == TokenKind.Div then
            return "div"
        elseif kind == TokenKind.Mod then
            return "mod"
        elseif kind == TokenKind.Pow then
            return "pow"
        elseif kind == TokenKind.EQ then
            return "eq"
        elseif kind == TokenKind.NE then
            return "ne"
        elseif kind == TokenKind.LT then
            return "lt"
        elseif kind == TokenKind.GT then
            return "gt"
        elseif kind == TokenKind.LE then
            return "le"
        elseif kind == TokenKind.GE then
            return "ge"
        elseif kind == TokenKind.And then
            return "and"
        elseif kind == TokenKind.Or then
            return "or"
        elseif kind == TokenKind.Not then
            return "not"
        elseif kind == TokenKind.BitAnd then
            return "bit-and"
        elseif kind == TokenKind.BitOr then
            return "bit-or"
        elseif kind == TokenKind.BitXor then
            return "bit-xor"
        elseif kind == TokenKind.BitNot then
            return "bit-not"
        elseif kind == TokenKind.BitLeft then
            return "bit-left"
        elseif kind == TokenKind.BitRight then
            return "bit-right"
        elseif kind == TokenKind.Do then
            return "do"
        elseif kind == TokenKind.Then then
            return "then"
        elseif kind == TokenKind.End then
            return "end"
        elseif kind == TokenKind.If then
            return "if"
        elseif kind == TokenKind.ElseIf then
            return "elseif"
        elseif kind == TokenKind.Else then
            return "else"
        elseif kind == TokenKind.For then
            return "for"
        elseif kind == TokenKind.While then
            return "while"
        elseif kind == TokenKind.Repeat then
            return "repeat"
        elseif kind == TokenKind.Wait then
            return "wait"
        end
    end
}

local Token = {
    mt = {
        __name = "token",
        ---@param self Token
        __tostring = function(self)
            if type(self.value) == "nil" then
                return ("[%s]"):format(TokenKind.tostring(self.kind))
            elseif type(self.value) == "string" then
                return ("[%s:%q]"):format(TokenKind.tostring(self.kind), self.value)
            else
                return ("[%s:%s]"):format(TokenKind.tostring(self.kind), self.value)
            end
        end
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