local log = require("nvim-chezmoi.core.log")
local utils = require("nvim-chezmoi.core.utils")
local job = require("nvim-chezmoi.core.job")
local cache = require("nvim-chezmoi.chezmoi.cache")

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
---@field cacheable? boolean Cache successful results in `chezmoi.cache`.

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
---@return string[] Args after `cmd`: `{ ...args, ...self.args }`.
local function full_args(self, args)
    local all = {}
    vim.list_extend(all, args or {})
    vim.list_extend(all, self.args or {})
    return all
end

---@param self ChezmoiCommand
---@param args? string[]
---@return string[] Full argv: `{ "chezmoi", cmd, ...args, ...self.args }`.
local function full_argv(self, args)
    local argv = { "chezmoi", self.cmd }
    vim.list_extend(argv, full_args(self, args))
    return argv
end

---@param args? string[]
---@param stdin? string[]|string
---@return ChezmoiCommandResult
function M:exec(args, stdin)
    if self.cacheable then
        local cached = cache.find_success(self.cmd, full_args(self, args))
        if cached then
            return cached.result
        end
    end

    local result = job.run(full_argv(self, args), stdin)
    if not result.success then
        log.error(result.data)
    elseif self.cacheable then
        cache.new(self.cmd, full_args(self, args), result)
    end

    return result
end

---@param args? string[]
---@param callback? fun(result: ChezmoiCommandResult)
---@return vim.SystemObj? Process handle, `nil` on cache hit.
function M:async(args, callback)
    if self.cacheable then
        local cached = cache.find_success(self.cmd, full_args(self, args))
        if cached then
            if callback then
                vim.schedule(function() callback(cached.result) end)
            end
            return nil
        end

        local cmd, cmd_args = self.cmd, full_args(self, args)
        return job.run_async(full_argv(self, args), nil, nil, function(result)
            if result.success then
                cache.new(cmd, cmd_args, result)
            end
            if callback then
                callback(result)
            end
        end)
    end

    return job.run_async(full_argv(self, args), nil, nil, callback)
end

return M
