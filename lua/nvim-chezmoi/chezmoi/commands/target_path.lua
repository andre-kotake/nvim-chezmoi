local command = require("nvim-chezmoi.chezmoi.command")

---@class ChezmoiTargetPath:ChezmoiCommand
local M = setmetatable({
    cmd = "target-path",
    cacheable = true,
}, {
    __index = command,
})

return M
