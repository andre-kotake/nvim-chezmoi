---@class ChezmoiManagedFile
---@field absolute string
---@field relative string
---@field sourceAbsolute string
---@field sourceRelative string
local M = {}
M.__index = M

---@class ChezmoiManagedFileNewArgs
---@field absolute string
---@field relative string
---@field sourceAbsolute string
---@field sourceRelative string

---@param args ChezmoiManagedFileNewArgs
---@return ChezmoiManagedFile
function M:new(args)
    local instance = setmetatable({}, self)
    local try_set = function(k, v)
        if v then
            instance[k] = v
        end
    end

    try_set("absolute", args.absolute)
    try_set("relative", args.relative)
    try_set("sourceAbsolute", args.sourceAbsolute)
    try_set("sourceRelative", args.sourceRelative)

    return instance
end

function M:isEncrypted()
    return string.find(vim.fs.basename(self.sourceAbsolute), "^encrypted_")
        ~= nil
end

function M:isTemplate()
    return vim.fs.basename(self.sourceAbsolute):match("%.tmpl") ~= nil
end

return M
