local File = {
    mt = {
        __name = "file"
    }
}
---@param path string
---@return File
function File.new(path)
    return setmetatable(
        ---@class File
        {
            path = path
        },
        File.mt
    )
end

local Position = {
    mt = {
        __name = "position",
        ---@param self Position
        __tostring = function(self)
            return ("%s:%s:%s"):format(self.file.path, self.ln.start, self.col.start)
        end
    }
}
---@param file File
---@param lnStart integer
---@param lnStop integer
---@param colStart integer
---@param colStop integer
---@return Position
function Position.new(file, lnStart, lnStop, colStart, colStop)
    return setmetatable(
        ---@class Position
        {
            file = file,
            ln = { start = lnStart, stop = lnStop },
            col = { start = colStart, stop = colStop },

            extend = Position.extend, clone = Position.clone,
        },
        Position.mt
    )
end

---@param self Position
---@param other Position
function Position:extend(other)
    self.ln.stop = other.ln.stop
    self.col.stop = other.col.stop
end
---@param self Position
function Position:clone()
    return Position.new(self.file, self.ln.start, self.ln.stop, self.col.start, self.col.stop)
end

return {
    File = File,
    Position = Position
}