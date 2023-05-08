local tokens = require "turtlenet.picolua.tokens"
local TokenKind = tokens.TokenKind
local nodes = require "turtlenet.picolua.nodes"

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

            ln = 1, col = 1,

            token = Parser.token, advance = Parser.advance, advanceLine = Parser.advanceLine,
            check = Parser.check, expect = Parser.expect, skip = Parser.skip,

            chunk = Parser.chunk, block = Parser.block,
            statement = Parser.statement, expression = Parser.expression,
            binary = Parser.binary, unary = Parser.unary,
            atom = Parser.atom, path = Parser.path,
        },
        Parser.mt
    )
end

---@param self Parser
function Parser:token()
    return (self.tokens[self.ln] or {})[self.col]
end
---@param self Parser
function Parser:advance()
    self.col = self.col + 1
end
---@param self Parser
function Parser:advanceLine()
    self.ln = self.ln + 1
    self.col = 1
end
---@param self Parser
function Parser:check()
    local token = self:token() if not token then
        return nil, ("unexpected end of input")
    end
    return token
end
---@param self Parser
---@param kind TokenKind
function Parser:expect(kind)
    local token, err = self:check() if err then return nil, err end
    if not token then return end
    if token.kind ~= kind then
        return nil, ("expected %s, got %s"):format(TokenKind.tostring(kind), TokenKind.tostring(token.kind)), token.pos
    end
    self:advance()
    return token
end
---@param self Parser
---@param kind TokenKind
function Parser:skip(kind)
    local token = self:token() if not token then return end
    if token.kind == kind then
        self:advance()
    end
end

---@param self Parser
function Parser:chunk()
    local chunk = {}
    while self:token() do
        local node, err, epos = self:statement() if err then return nil, err, epos end
        if not node then break end
        self:advanceLine()
        table.insert(chunk, node)
    end
    return nodes.ChunkNode.new(chunk)
end
---@param self Parser
---@param endTokens table<integer, TokenKind>|nil
function Parser:statement(endTokens)
    local token, err, epos = self:check() if err then return nil, err, epos end
    if not token then
        if not endTokens then endTokens = { TokenKind.End } end
        return self:block(endTokens)
    end
    local pos = token.pos
    if token.kind == TokenKind.ID then
        local path, err, epos = self:path() if err then return nil, err, epos end
        if not path then return end
        local token = self:token()
        if token then
            if token.kind == TokenKind.Equal then
                self:advance()
                local value, err, epos = self:expression() if err then return nil, err, epos end
                if not value then return end
                pos:extend(value.pos)
                return nodes.AssignNode.new(path, value, pos)
            elseif token.kind == TokenKind.Call then
                self:advance()
                local args = {}
                while self:token() do
                    local arg, err, epos = self:expression() if err then return nil, err, epos end
                    if not arg then break end
                    pos:extend(arg.pos)
                    table.insert(args, arg)
                end
                return nodes.CallNode.new(path, args, pos)
            else
                return nil, ("unexpected %s"):format(TokenKind.tostring(token.kind)), token.pos
            end
        else
            pos:extend(path.pos)
            return nodes.CallNode.new(path, {}, pos)
        end
    elseif token.kind == TokenKind.If then
        self:advance()
        local conds = {}
        local cases = {}
        local else_case
        while self:token() do
            local cond, err, epos = self:expression() if err then return nil, err, epos end
            if not cond then return nil, ("expected expression, got %s"):format(self:token() and TokenKind.tostring(self:token().kind) or "end of input") end
            table.insert(conds, cond)
            self:expect(TokenKind.Then)
            local case, err, epos = self:statement({ TokenKind.End, TokenKind.ElseIf, TokenKind.Else }) if err then return nil, err, epos end
            if not case then return nil, ("expected statement, got %s"):format(self:token() and TokenKind.tostring(self:token().kind) or "end of input") end
            table.insert(cases, case)
            pos:extend(case.pos)
            local token = self:token()
            if token then
                pos:extend(token.pos)
                if token.kind == TokenKind.End then self:advanceLine() break
                elseif token.kind == TokenKind.ElseIf then self:advance()
                elseif token.kind == TokenKind.Else then break
                else return nil, ("unexpected %s"):format(TokenKind.tostring(token.kind)) end
            else
                self:advanceLine()
                local token = self:token()
                if token then
                    pos:extend(token.pos)
                    if token.kind == TokenKind.End then self:advanceLine() break
                    elseif token.kind == TokenKind.ElseIf then self:advance()
                    elseif token.kind == TokenKind.Else then break
                    else return nil, ("unexpected %s"):format(TokenKind.tostring(token.kind)) end
                end
            end
        end
        local token = self:token()
        if token then
            pos:extend(token.pos)
            if token.kind == TokenKind.Else then
                self:advance()
                local err
                else_case, err, epos = self:statement() if err then return nil, err, epos end
            end
        end
        return nodes.IfNode.new(conds, cases, else_case, pos)
    else
        return nil, ("unexpected %s"):format(TokenKind.tostring(token.kind)), token.pos
    end
end
---@param self Parser
function Parser:expression()
    local token, err, epos = self:check() if err then return nil, err, epos end
    if not token then return end
    if token.kind == TokenKind.ID then
        return self:path()
    end
    local pos = token.pos
    if token.kind == TokenKind.Number then
        self:advance()
        return nodes.NumberNode.new(token.value, pos)
    end
    if token.kind == TokenKind.Boolean then
        self:advance()
        return nodes.BooleanNode.new(token.value, pos)
    end
    if token.kind == TokenKind.String then
        self:advance()
        return nodes.StringNode.new(token.value, pos)
    end
    if token.kind == TokenKind.ExprIn then
        self:advance()
        local token, err, epos = self:check() if err then return nil, err, epos end
        if not token then return end
        -- unary
        if token.kind == TokenKind.Sub then
            self:advance()
            local right, err, epos = self:expression() if err then return nil, err, epos end
            if not right then return end
            pos:extend(right.pos)
            return nodes.UnaryNode.new("-", right, pos)
        end
        if token.kind == TokenKind.Not then
            self:advance()
            local right, err, epos = self:expression() if err then return nil, err, epos end
            if not right then return end
            pos:extend(right.pos)
            return nodes.UnaryNode.new("not", right, pos)
        end
        -- binary
        local left, err, epos = self:expression() if err then return nil, err, epos end
        if not left then return end
        local token, err, epos = self:check() if err then return nil, err, epos end
        if not token then return end
        local op = "+"
        if token.kind == TokenKind.Add then
            op = "+"
        elseif token.kind == TokenKind.Sub then
            op = "-"
        elseif token.kind == TokenKind.Mul then
            op = "*"
        elseif token.kind == TokenKind.Div then
            op = "/"
        elseif token.kind == TokenKind.Mod then
            op = "%"
        elseif token.kind == TokenKind.Pow then
            op = "^"
        elseif token.kind == TokenKind.EQ then
            op = "=="
        elseif token.kind == TokenKind.NE then
            op = "~="
        elseif token.kind == TokenKind.LT then
            op = "<"
        elseif token.kind == TokenKind.GT then
            op = ">"
        elseif token.kind == TokenKind.LE then
            op = "<="
        elseif token.kind == TokenKind.GE then
            op = ">="
        elseif token.kind == TokenKind.And then
            op = "and"
        elseif token.kind == TokenKind.Or then
            op = "or"
        else
            return nil, ("unexpected binary operator %s"):format(TokenKind.tostring(token.kind))
        end
        self:advance()
        local right, err, epos = self:expression() if err then return nil, err, epos end
        if not right then return end
        local token, err, epos = self:expect(TokenKind.ExprOut) if err then return nil, err, epos end
        if not token then return end
        pos:extend(token.pos)
        return nodes.BinaryNode.new(op, left, right, pos)
    end
    -- return nil, ("unexpected %s"):format(TokenKind.tostring(token.kind))
end
---@param self Parser
function Parser:path()
    local token, err, epos = self:check() if err then return nil, err, epos end
    if not token then return end
    if token.kind ~= TokenKind.ID then
        return nil, ("expected %s, got %s"):format(TokenKind.tostring(TokenKind.ID), TokenKind.tostring(token.kind)), token.pos
    end
    ---@type PathNode
    local head = nodes.IDNode.new(token.value, token.pos)
    local pos = token.pos:clone()
    self:advance()
    while true do
        local token = self:token() if not token then break end
        if token.kind == TokenKind.ID then
            self:advance()
            pos:extend(token.pos)
            head = nodes.FieldNode.new(head, nodes.IDNode.new(token.value, token.pos), pos:clone())
        elseif token.kind == TokenKind.Number or token.kind == TokenKind.String or token.kind == TokenKind.ExprIn then
            local index, err, epos = self:expression() if err then return nil, err, epos end
            if not index then return end
            pos:extend(index.pos)
            head = nodes.IndexNode.new(head, index, pos:clone())
        else
            break
        end
    end
    return head
end

return {
    Parser = Parser,
    ---@param file File
    ---@param tokens Lines
    parse = function(file, tokens)
        return Parser.new(file, tokens):chunk()
    end
}