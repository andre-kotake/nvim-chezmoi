---@class ChezmoiManagedFile
---@field absolute string
---@field relative string
---@field targetPath string
---@field sourceAbsolute string
---@field sourceRelative string
---@field sourcePath string
local M = {}
M.__index = M

function M.new(absolute, relative, source_absolute, source_relative)
  local self = setmetatable({}, M)
  self.absolute = absolute
  self.relative = relative
  self.sourceAbsolute = source_absolute
  self.sourceRelative = source_relative
  return self
end

function M:isEncrypted()
  return string.find(
    vim.fn.fnamemodify(self.sourceAbsolute, ":t"),
    "^encrypted_"
  ) ~= nil
end

function M:isTemplate() end

return M
