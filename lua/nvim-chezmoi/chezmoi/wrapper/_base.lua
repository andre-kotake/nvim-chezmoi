local log = require("nvim-chezmoi.core.log")
local utils = require("nvim-chezmoi.core.utils")

---Wrapper class for chezmoi commands.
---Functions here should provide nvim functionality for executed commands.
---@class ChezmoiCommandWrapper
local M = {}
M.__index = M

---Wraps a chezmoi command and execute callback if success.
---@param cmd fun(args: string[]|string): ChezmoiCommandResult
---@param cmd_args string[]|string
---@param callback fun(result: ChezmoiCommandResult): ChezmoiCommandResult|any
---@return ChezmoiCommandResult|nil|any
function M:exec(cmd, cmd_args, callback)
  local cmd_result = cmd(cmd_args)
  if cmd_result.success then
    callback(cmd_result)
  end

  return cmd_result
end

---@class ChezmoiAutoCommand
---@field event string[]|string
---@field opts? vim.api.keyset.create_autocmd

---Creates auto commands
---@param commands ChezmoiAutoCommand[]
function M.create_autocmds(commands)
  for _, cmd in ipairs(commands) do
    local opts = vim.tbl_deep_extend("force", cmd.opts or {}, {
      group = utils.augroup(cmd.opts.group),
    })
    vim.api.nvim_create_autocmd(cmd.event, opts)
  end
end

---@class ChezmoiUserCommand
---@field name string
---@field desc string
---@field callback fun(args: any)
---@field opts? vim.api.keyset.user_command

---Creates buf local user commands.
---@param bufnr integer
---@param commands ChezmoiUserCommand[]
function M.create_buf_user_commands(bufnr, commands)
  local existing_cmds = vim.api.nvim_buf_get_commands(bufnr, {})
  for _, cmd in ipairs(commands) do
    if not existing_cmds[cmd.name] then
      -- Create the user command if it doesn't exist
      local opts = vim.tbl_deep_extend("force", cmd.opts or {}, {
        desc = cmd.desc,
      })
      vim.api.nvim_buf_create_user_command(bufnr, cmd.name, cmd.callback, opts)
    end
  end
end

---Creates user commands.
---@param commands ChezmoiUserCommand[]
function M.create_user_commands(commands)
  for _, cmd in pairs(commands) do
    local opts = vim.tbl_deep_extend("force", {
      desc = cmd.desc,
    }, cmd.opts or {})
    vim.api.nvim_create_user_command(cmd.name, cmd.callback, opts)
  end
end

return M
