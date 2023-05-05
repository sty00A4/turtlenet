local IDNode = {
    mt = {
        __name = "id-node"
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
        __name = "field-node"
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
        __name = "index-node"
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
        __name = "number-node"
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
        __name = "boolean-node"
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
        __name = "string-node"
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

---@alias BinaryOperator "+"|"-"|"*"|"/"|"%"|"^"
local BinaryNode = {
    mt = {
        __name = "binary-node"
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
---@alias UnaryOperator "+"|"-"|"*"|"/"|"%"|"^"
local UnaryNode = {
    mt = {
        __name = "unary-node"
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

local CallNode = {
    mt = {
        __name = "call-node"
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
        __name = "assign-node"
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

---@alias StatementNode CallNode|AssignNode|IfNode|RepeatNode|WhileNode|ForNode

return {
    IDNode = IDNode, FieldNode = FieldNode, IndexNode = IndexNode,
    NumberNode = NumberNode, BooleanNode = BooleanNode, StringNode = StringNode,
    BinaryNode = BinaryNode, UnaryNode = UnaryNode,
    CallNode = CallNode, AssignNode = AssignNode,
}