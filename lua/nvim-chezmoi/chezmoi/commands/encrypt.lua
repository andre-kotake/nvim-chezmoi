local command = require("nvim-chezmoi.chezmoi.command")

---@class ChezmoiEncrypt: ChezmoiCommand
local M = setmetatable({
  cmd = "encrypt",
}, {
  __index = command,
})

function M:exec(stdin)
  return command.exec(self, nil, stdin)
end

return M
