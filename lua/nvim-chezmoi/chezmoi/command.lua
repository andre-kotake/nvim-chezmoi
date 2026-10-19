local log = require("nvim-chezmoi.core.log")
local utils = require("nvim-chezmoi.core.utils")
local job = require("nvim-chezmoi.core.job")

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
---@field opts? vim.api.keyset.create_autocmd
---@class ChezmoiCommand
---@field cmd string
---@field args? string[] Default args for command.

---@class ChezmoiCommand
local M = {
    args = {},
}
M.__index = M

---@param args? string|table
---@return ChezmoiAutoCommand[]
function M:autoCommands(args)
    error(debug.traceback("autoCommands not implemented."))
end

function M:create_autocmds(args)
    local commands = self:autoCommands(args)
    for _, cmd in ipairs(commands) do
        vim.api.nvim_create_autocmd(
            cmd.event,
            vim.tbl_deep_extend("force", cmd.opts or {}, {
                group = utils.augroup(cmd.opts.group),
            })
        )
    end
end

---@param args? string|table
---@return ChezmoiUserCommand[]
function M:userCommands(args)
    error(debug.traceback("bufUserCommands not implemented."))
end

function M:create_user_commands(args)
    local commands = self:userCommands(args)
    for _, cmd in pairs(commands) do
        vim.api.nvim_create_user_command(
            cmd.name,
            cmd.callback,
            vim.tbl_deep_extend("force", cmd.opts or {}, {
                desc = cmd.desc,
            })
        )
    end
end

---@param bufnr integer
---@return ChezmoiUserCommand[]
function M:bufUserCommands(bufnr)
    error(debug.traceback(bufnr .. ": bufUserCommands not implemented."))
end

---@param bufnr integer
function M:create_buf_user_commands(bufnr)
    local commands = self:bufUserCommands(bufnr)
    local existing_cmds = vim.api.nvim_buf_get_commands(bufnr, {})

    for _, cmd in ipairs(commands) do
        if not existing_cmds[cmd.name] then
            -- Create the user command if it doesn't exist
            vim.api.nvim_buf_create_user_command(
                bufnr,
                cmd.name,
                cmd.callback,
                vim.tbl_deep_extend("force", cmd.opts or {}, {
                    desc = cmd.desc,
                })
            )
        end
    end
end

---@param self ChezmoiCommand
---@param args? string[]
---@return string[] Full argv: `{ "chezmoi", cmd, ...args, ...self.args }`.
local function full_argv(self, args)
    local argv = { "chezmoi", self.cmd }
    vim.list_extend(argv, args or {})
    vim.list_extend(argv, self.args or {})
    return argv
end

---@param args? string[]
---@param stdin? string[]|string
---@return ChezmoiCommandResult
function M:exec(args, stdin)
    local result = job.run(full_argv(self, args), stdin)
    if not result.success then
        log.error(result.data)
    end

    return result
end

---@param args? string[]
---@param callback? fun(result: ChezmoiCommandResult)
---@return vim.SystemObj Process handle.
function M:async(args, callback)
    return job.run_async(full_argv(self, args), nil, nil, callback)
end

return M
