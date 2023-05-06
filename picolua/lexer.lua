local Position = (require "turtlenet.picolua.location").Position
local tokens = require "turtlenet.picolua.tokens"
local Token, TokenKind = tokens.Token, tokens.TokenKind

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
            ---@alias Lines table<integer, table<integer, Token>>
            ---@type Lines
            lines = {{}},

            advance = Lexer.advance, get = Lexer.get, pos = Lexer.pos,
            whiteSpace = Lexer.whiteSpace,
            next = Lexer.next, lex = Lexer.lex
        },
        Lexer.mt
    )
end

---@param self Lexer
function Lexer:get()
    local c = self.text:sub(self.idx, self.idx)
    if #c == 0 then return nil else return c end
end
---@param self Lexer
function Lexer:pos()
    return Position.new(self.file, self.ln, self.ln, self.col, self.col)
end
---@param self Lexer
function Lexer:advance()
    if self:get() == "\n" then
        self.ln = self.ln + 1
        table.insert(self.lines, {})
        self.col = 1
    else
        self.col = self.col + 1
    end
    self.idx = self.idx + 1
end
---@param self Lexer
function Lexer:whiteSpace()
    while true do
        local c = self:get() if not c then break end
        if not c:match("%s") then break end
        self:advance()
    end
end
---@param self Lexer
function Lexer:next()
    self:whiteSpace()
    local c = self:get() if not c then return nil end
    local pos = self:pos()
    self:advance()
    if c == "=" then
        if self:get() == "=" then
            pos:extend(self:pos())
            self:advance()
            return Token.new(TokenKind.EQ, nil, pos)
        end
        return Token.new(TokenKind.Equal, nil, pos)
    elseif c == ":" then
        return Token.new(TokenKind.Call, nil, pos)
    elseif c == "(" then
        return Token.new(TokenKind.Expr, false, pos)
    elseif c == ")" then
        return Token.new(TokenKind.Expr, true, pos)
    elseif c == "+" then
        return Token.new(TokenKind.Add, nil, pos)
    elseif c == "-" then
        return Token.new(TokenKind.Sub, nil, pos)
    elseif c == "*" then
        return Token.new(TokenKind.Mul, nil, pos)
    elseif c == "/" then
        return Token.new(TokenKind.Div, nil, pos)
    elseif c == "%" then
        return Token.new(TokenKind.Mod, nil, pos)
    elseif c == "^" then
        return Token.new(TokenKind.Pow, nil, pos)
    elseif c == "~" then
        if self:get() == "=" then
            pos:extend(self:pos())
            self:advance()
            return Token.new(TokenKind.NE, nil, pos)
        end
        return Token.new(TokenKind.BitNot, nil, pos)
    elseif c == "<" then
        if self:get() == "=" then
            pos:extend(self:pos())
            self:advance()
            return Token.new(TokenKind.LE, nil, pos)
        end
        return Token.new(TokenKind.LT, nil, pos)
    elseif c == ">" then
        if self:get() == "=" then
            pos:extend(self:pos())
            self:advance()
            return Token.new(TokenKind.GE, nil, pos)
        end
        return Token.new(TokenKind.GT, nil, pos)
    elseif c == "\"" or c == "'" then
        local endChar = c
        local str = ""
        while true do
            local c = self:get() if not c then break end
            if c == endChar then break end
            str = str .. c
            pos:extend(self:pos())
            self:advance()
        end
        self:advance()
        return Token.new(TokenKind.String, str, pos)
    elseif c:match("%d") then
        local number = c
        while true do
            local c = self:get() if not c then break end
            if not c:match("%d") then break end
            number = number .. c
            pos:extend(self:pos())
            self:advance()
        end
        if self:get() == "." then
            number = number .. "."
            pos:extend(self:pos())
            self:advance()
            while true do
                local c = self:get() if not c then break end
                if not c:match("%d") then break end
                number = number .. c
                pos:extend(self:pos())
                self:advance()
            end
        end
        return Token.new(TokenKind.Number, tonumber(number), pos)
    elseif c:match("%w") or c == "_" then
        local id = c
        while true do
            local c = self:get() if not c then break end
            if not c:match("%w") and not c:match("%d") and c ~= "_" then break end
            id = id .. c
            pos:extend(self:pos())
            self:advance()
        end
        local kind, value = TokenKind.fromWord(id)
        return Token.new(kind, value, pos)
    else
        return nil, ("bad character %q"):format(c), pos
    end
end
---@param self Lexer
function Lexer:lex()
    while self:get() do
        local token, err, epos = self:next() if err then return nil, err, epos end
        if not token then break end
        table.insert(self.lines[self.ln], token)
    end
    return self.lines
end

return {
    Lexer = Lexer,
    lex = function(file, text)
        return Lexer.new(file, text):lex()
    end
}