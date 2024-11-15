local command = require("nvim-chezmoi.chezmoi.command")

---@class ChezmoiTargetPath:ChezmoiCommand
local M = setmetatable({
  cmd = "target-path",
}, {
  __index = command,
})

return M
