local command = require("nvim-chezmoi.chezmoi.command")

---@class ChezmoiSourcePath:ChezmoiCommand
local M = setmetatable({
  cmd = "source-path",
}, {
  __index = command,
})

return M
