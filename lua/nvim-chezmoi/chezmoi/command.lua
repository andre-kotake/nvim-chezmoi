local log = require("nvim-chezmoi.core.log")
local utils = require("nvim-chezmoi.core.utils")
local Job = require("plenary.job")

---@class ChezmoiCommand
---@field cmd string
---@field args? string[] Default args for command.
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

---@return ChezmoiUserCommand[]
function M:userCommands()
  error(debug.traceback("bufUserCommands not implemented."))
end

function M:create_user_commands()
  local commands = self:userCommands()
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

---@param job Job
---@return ChezmoiCommandResult
local function getJobResult(job)
  local result = job:result()
  local success = job.code == 0

  if not success then
    -- Error, trim each and join with newline
    local stderr = {}
    for _, v in ipairs(job:stderr_result()) do
      stderr[#stderr + 1] = v:gsub("^%s*(.-)%s*$", "%1")
    end
    result = { table.concat(stderr, "\n") }
    success = false
  end

  return {
    args = job.args,
    success = success,
    data = result,
  }
end

---@param self ChezmoiCommand
---@param args string[]
local function newJob(self, args)
  vim.list_extend(args, self.args)
  args = vim.list_extend({ self.cmd }, args)
  return Job:new({
    command = "chezmoi",
    args = args,
  })
end

---@param args? string[]
---@return ChezmoiCommandResult
function M:exec(args)
  local job = newJob(self, args or {})
  job:sync()
  local result = getJobResult(job)

  if not result.success then
    log.error(result.data)
  end

  return result
end

return M
