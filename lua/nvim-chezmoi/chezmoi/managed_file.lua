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
  return string.find(
    vim.fn.fnamemodify(self.sourceAbsolute, ":t"),
    "^encrypted_"
  ) ~= nil
end

function M:isTemplate()
  return vim.fn.fnamemodify(self.sourceAbsolute, ":t"):match("%.tmpl") ~= nil
end

return M
