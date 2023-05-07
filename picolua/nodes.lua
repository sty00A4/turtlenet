local IDNode = {
    mt = {
        __name = "id-node",
        ---@param self IDNode
        __tostring = function (self)
            return self.id
        end
    }
}
---@param id string
---@param pos Position
---@return IDNode
function IDNode.new(id, pos)
    return setmetatable(
        ---@class IDNode
        {
            type = IDNode.mt.__name,
            id = id, pos = pos
        },
        IDNode.mt
    )
end

local FieldNode = {
    mt = {
        __name = "field-node",
        ---@param self FieldNode
        __tostring = function (self)
            return ("%s %s"):format(self.head, self.field)
        end
    }
}
---@param head PathNode
---@param field IDNode
---@param pos Position
---@return FieldNode
function FieldNode.new(head, field, pos)
    return setmetatable(
        ---@class FieldNode
        {
            type = FieldNode.mt.__name,
            head = head, field = field, pos = pos,
        },
        FieldNode.mt
    )
end
local IndexNode = {
    mt = {
        __name = "index-node",
        ---@param self IndexNode
        __tostring = function (self)
            return ("%s[%s]"):format(self.head, self.index)
        end
    }
}
---@param head PathNode
---@param index EvalNode
---@param pos Position
---@return IndexNode
function IndexNode.new(head, index, pos)
    return setmetatable(
        ---@class IndexNode
        {
            type = IndexNode.mt.__name,
            head = head, index = index, pos = pos,
        },
        IndexNode.mt
    )
end

---@alias PathNode FieldNode|IndexNode|IDNode

local NumberNode = {
    mt = {
        __name = "number-node",
        ---@param self NumberNode
        __tostring = function (self)
            return tostring(self.value)
        end
    }
}
---@param value number
---@param pos Position
---@return NumberNode
function NumberNode.new(value, pos)
    return setmetatable(
        ---@class NumberNode
        {
            type = NumberNode.mt.__name,
            value = value, pos = pos,
        },
        NumberNode.mt
    )
end
local BooleanNode = {
    mt = {
        __name = "boolean-node",
        ---@param self BooleanNode
        __tostring = function (self)
            return tostring(self.value)
        end
    }
}
---@param value boolean
---@param pos Position
---@return BooleanNode
function BooleanNode.new(value, pos)
    return setmetatable(
        ---@class BooleanNode
        {
            type = BooleanNode.mt.__name,
            value = value, pos = pos,
        },
        BooleanNode.mt
    )
end
local StringNode = {
    mt = {
        __name = "string-node",
        ---@param self StringNode
        __tostring = function (self)
            return ("%q"):format(self.value)
        end
    }
}
---@param value string
---@param pos Position
---@return StringNode
function StringNode.new(value, pos)
    return setmetatable(
        ---@class StringNode
        {
            type = StringNode.mt.__name,
            value = value, pos = pos,
        },
        StringNode.mt
    )
end

---@alias BinaryOperator "+"|"-"|"*"|"/"|"%"|"^"|"=="|"~="|"<"|">"|"<="|">="|"and"|"or"
local BinaryNode = {
    mt = {
        __name = "binary-node",
        ---@param self BinaryNode
        __tostring = function (self)
            return ("(%s %s %s)"):format(self.left, self.op, self.right)
        end
    }
}
---@param op BinaryOperator
---@param left EvalNode
---@param right EvalNode
---@param pos Position
---@return BinaryNode
function BinaryNode.new(op, left, right, pos)
    return setmetatable(
        ---@class BinaryNode
        {
            type = BinaryNode.mt.__name,
            op = op, left = left, right = right, pos = pos,
        },
        BinaryNode.mt
    )
end
---@alias UnaryOperator "-"|"not"
local UnaryNode = {
    mt = {
        __name = "unary-node",
        ---@param self UnaryNode
        __tostring = function (self)
            return ("(%s %s)"):format(self.op, self.right)
        end
    }
}
---@param op UnaryOperator
---@param right EvalNode
---@param pos Position
---@return UnaryNode
function UnaryNode.new(op, right, pos)
    return setmetatable(
        ---@class UnaryNode
        {
            type = UnaryNode.mt.__name,
            op = op, right = right, pos = pos,
        },
        UnaryNode.mt
    )
end

---@alias EvalNode PathNode|NumberNode|BooleanNode|StringNode|BinaryNode|UnaryNode

local BlockNode = {
    mt = {
        __name = "block-node",
        ---@param self BlockNode
        __tostring = function (self)
            local s = "\n"
            for _, n in ipairs(self.nodes) do
                s = s .. tostring(n) .. "\n"
            end
            return s
        end
    }
}
---@param nodes table<integer, StatementNode>
---@param pos Position
---@return BlockNode
function BlockNode.new(nodes, pos)
    return setmetatable(
        ---@class BlockNode
        {
            type = BlockNode.mt.__name,
            nodes = nodes, pos = pos,
        },
        BlockNode.mt
    )
end

local CallNode = {
    mt = {
        __name = "call-node",
        ---@param self CallNode
        __tostring = function (self)
            local args = ""
            for _, arg in ipairs(self.args) do
                args = args .. tostring(arg) .. " "
            end
            return ("%s: %s"):format(self.head, args)
        end
    }
}
---@param head PathNode
---@param args table<integer, EvalNode>
---@param pos Position
---@return CallNode
function CallNode.new(head, args, pos)
    return setmetatable(
        ---@class CallNode
        {
            type = CallNode.mt.__name,
            head = head, args = args, pos = pos,
        },
        CallNode.mt
    )
end
local AssignNode = {
    mt = {
        __name = "assign-node",
        ---@param self AssignNode
        __tostring = function (self)
            return ("%s = %s"):format(self.path, self.value)
        end
    }
}
---@param path table<integer, PathNode>
---@param value table<integer, EvalNode>
---@param pos Position
---@return AssignNode
function AssignNode.new(path, value, pos)
    return setmetatable(
        ---@class AssignNode
        {
            type = AssignNode.mt.__name,
            path = path, value = value, pos = pos,
        },
        AssignNode.mt
    )
end

local IfNode = {
    mt = {
        __name = "if-node",
        ---@param self IfNode
        __tostring = function (self)
            local s = "if"
            for i = 1, #self.conds do
                s = s .. tostring(self.conds[i]) .. " then " .. tostring(self.cases[i])
                if i ~= #self.conds then
                    s = s .. " elseif "
                end
            end
            s = s .. "end"
            return s
        end
    }
}
---@param conds table<integer, EvalNode>
---@param cases table<integer, StatementNode>
---@param elseCase StatementNode|nil
---@param pos Position
---@return IfNode
function IfNode.new(conds, cases, elseCase, pos)
    return setmetatable(
        ---@class IfNode
        {
            type = IfNode.mt.__name,
            conds = conds, cases = cases, elseCase = elseCase, pos = pos,
        },
        IfNode.mt
    )
end
local WhileNode = {
    mt = {
        __name = "while-node"
    }
}
---@param cond EvalNode
---@param body StatementNode
---@param pos Position
---@return WhileNode
function WhileNode.new(cond, body, pos)
    return setmetatable(
        ---@class WhileNode
        {
            type = WhileNode.mt.__name,
            cond = cond, body = body, pos = pos,
        },
        WhileNode.mt
    )
end
local ForNode = {
    mt = {
        __name = "for-node"
    }
}
---@param ids table<integer, IDNode>
---@param iter EvalNode
---@param body StatementNode
---@param pos Position
---@return ForNode
function ForNode.new(ids, iter, body, pos)
    return setmetatable(
        ---@class ForNode
        {
            type = ForNode.mt.__name,
            ids = ids, iter = iter, body = body, pos = pos,
        },
        ForNode.mt
    )
end

local RepeatNode = {
    mt = {
        __name = "repeat-node"
    }
}
---@param count EvalNode
---@param body StatementNode
---@param pos Position
---@return RepeatNode
function RepeatNode.new(count, body, pos)
    return setmetatable(
        ---@class RepeatNode
        {
            type = RepeatNode.mt.__name,
            count = count, body = body, pos = pos,
        },
        RepeatNode.mt
    )
end
local WaitNode = {
    mt = {
        __name = "wait-node"
    }
}
---@param cond EvalNode
---@param body StatementNode
---@param pos Position
---@return WaitNode
function WaitNode.new(cond, body, pos)
    return setmetatable(
        ---@class WaitNode
        {
            type = WaitNode.mt.__name,
            cond = cond, body = body, pos = pos,
        },
        WaitNode.mt
    )
end


---@alias StatementNode BlockNode|CallNode|AssignNode|IfNode|WhileNode|ForNode|RepeatNode|WaitNode

local ChunkNode = {
    mt = {
        __name = "chunk-node",
        ---@param self ChunkNode
        __tostring = function (self)
            local s = ""
            for _, n in ipairs(self.nodes) do
                s = s .. tostring(n) .. "\n"
            end
            return s
        end
    }
}
---@param nodes table<integer, StatementNode>
---@return ChunkNode
function ChunkNode.new(nodes)
    return setmetatable(
        ---@class ChunkNode
        {
            type = ChunkNode.mt.__name,
            nodes = nodes,
        },
        ChunkNode.mt
    )
end

return {
    IDNode = IDNode, FieldNode = FieldNode, IndexNode = IndexNode,
    NumberNode = NumberNode, BooleanNode = BooleanNode, StringNode = StringNode,
    BinaryNode = BinaryNode, UnaryNode = UnaryNode,
    BlockNode = BlockNode,
    CallNode = CallNode, AssignNode = AssignNode,
    IfNode = IfNode, WhileNode = WhileNode, ForNode = ForNode,
    RepeatNode = RepeatNode, WaitNode = WaitNode,
    ChunkNode = ChunkNode
}