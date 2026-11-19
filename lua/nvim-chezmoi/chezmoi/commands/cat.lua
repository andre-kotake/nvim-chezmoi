local command = require("nvim-chezmoi.chezmoi.command")

---@class ChezmoiCat:ChezmoiCommand
local M = setmetatable({
    cmd = "cat",
}, {
    __index = command,
})

return M
