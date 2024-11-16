---@class Chezmoi
---@field source_path string
local M = {}

---Result of an executed command
---@class ChezmoiCommandResult
---@field args string[] Command arguments.
---@field success boolean `true` if command returned status code 0.
---@field data table The result data from command execution or error messages if `success` is `false`.

---Chezmoi command options
---@class ChezmoiCommandOpts
---@field args? string[] Additional args to append to `cmd`.
---@field callback? fun(result: ChezmoiCommandResult): any Callback to execute on exit.
---@field stdin? string[] `stdin` if needed for command.

---User command for chezmoi files
---@class ChezmoiUserCommand
---@field name string
---@field desc string
---@field callback function
---@field opts vim.api.keyset.user_command

---Autocmd for chezmoi files
---@class ChezmoiAutoCommand
---@field event string|string[]
---@field opts vim.api.keyset.create_autocmd

return M
