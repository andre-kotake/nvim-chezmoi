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
  instance.absolute = args.absolute
  instance.relative = args.relative
  instance.sourceAbsolute = args.sourceAbsolute
  instance.sourceRelative = args.sourceRelative
  return instance
end

function M:isEncrypted()
  return string.find(
    vim.fn.fnamemodify(self.sourceAbsolute, ":t"),
    "^encrypted_"
  ) ~= nil
end

function M:isTemplate()
  return vim.fn.fnamemodify(self.sourceAbsolute, ":t"):match("%.tmpl") ~= nil
end

return M
