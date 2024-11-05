local log = require("nvim-chezmoi.core.log")

---Wrapper class for chezmoi commands.
---Functions here should provide nvim functionality for executed commands.
---@class ChezmoiCommandWrapper
local M = {}
M.__index = M

---Main function
function M:exec(_)
  log.error("Not implemented")
end

---Wraps a chezmoi command and execute callback if success.
---@param cmd fun(args: string[]|string): ChezmoiCommandResult
---@param cmd_args string[]|string
---@param callback fun(result: ChezmoiCommandResult): ChezmoiCommandResult|any
---@return ChezmoiCommandResult|nil|any
function M:check_result(cmd, cmd_args, callback)
  local cmd_result = cmd(cmd_args)
  if not cmd_result.success then
    return cmd_result
  end

  return callback(cmd_result)
end

function M:create_user_commands(commands)
  for _, cmd in pairs(commands) do
    local opts = vim.tbl_deep_extend("force", {
      desc = cmd.desc,
    }, cmd.opts or {})
    vim.api.nvim_create_user_command(cmd.name, cmd.callback, opts)
  end
end

function M:create_buf_user_commands(bufnr, commands)
  local existing_cmds = vim.api.nvim_buf_get_commands(bufnr, {})
  for _, cmd in ipairs(commands) do
    if not existing_cmds[cmd.name] then
      -- Create the user command if it doesn't exist
      vim.api.nvim_buf_create_user_command(bufnr, cmd.name, cmd.callback, {
        desc = cmd.desc,
      })
    end
  end
end

return M
