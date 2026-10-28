local command = require("nvim-chezmoi.chezmoi.command")

---@class ChezmoiApply:ChezmoiCommand
local M = setmetatable({
    cmd = "apply",
    args = { "--force" },
}, {
    __index = command,
})

---@return ChezmoiUserCommand[]
function M:userCommands()
    return {
        {
            name = "ChezmoiApply",
            desc = "Applies current chezmoi file. Accepts optional files arguments.",
            callback = function(cmd)
                local args = cmd.fargs
                if #args > 0 then
                    local utils = require("nvim-chezmoi.core.utils")
                    for i, value in ipairs(args) do
                        -- `expand` keeps `~`/env working
                        args[i] = utils.fullpath(vim.fs.normalize(value))
                    end
                end
                self:exec(args)
            end,
            opts = {
                nargs = "*",
            },
        },
    }
end

return M
