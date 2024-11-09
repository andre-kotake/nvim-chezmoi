if vim.fn.executable("chezmoi") == 0 then
  error(debug.traceback("chezmoi executable not found in PATH."))
end

local runner = require("nvim-chezmoi.core.plenary_runner")
local cache = require("nvim-chezmoi.chezmoi.cache")
local helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")
local Job = require("plenary.job")

---Main class for chezmoi commands.
---All command results are cached to speed up future invocations.
---@class NvimChezmoiCmd
local M = {}

---Result of an executed command
---@class ChezmoiCommandResult
---@field success boolean `true` if command returned status code 0.
---@field data table The result data from command execution or error messages if `success` is `false`.

---@alias ChezmoiCmd
---| '"apply"'
---| '"execute-template"'
---| '"source-path"'
---| '"target-path"'

---@class ChezmoiCmdOpts
---@field args? string[] Additional args to append to `cmd`, e.g. ".bashrc"
---@field callback? fun(result: ChezmoiCommandResult): any Callback to execute on success
---@field force? boolean Force execution ignoring cache always. Default `false`.
---@field stdin? string[] `stdin` if needed for command.
---@field success_only? boolean Only returns from cache if result was succesful. Default `false`.

---Executes a chezmoi command and caches the result.
---If cached result was found, return it instead of executing again, unless `force` is `true`.
---@param cmd ChezmoiCmd|string Command to execute
---@param opts ChezmoiCmdOpts
---@return ChezmoiCommandResult
M.run = function(cmd, opts)
  local cached
  local args = opts.args or {}
  local force = opts.force or false
  local callback = opts.callback or nil
  local stdin = opts.stdin or {}
  local success_only = opts.success_only or true

  if not force or true then
    if success_only or false then
      cached = cache.find_success(cmd, args)
    else
      cached = cache.find(cmd, args)
    end

    if cached ~= nil then
      if cached.result.success and type(callback) == "function" then
        callback(cached.result)
      end

      return cached.result
    end
  end

  local cmd_args = { cmd }
  vim.list_extend(cmd_args, args or {})

  local result = runner.exec({
    args = cmd_args,
    stdin = stdin,
  })

  if not result.success then
    log.error(result.data)
  else
    if type(callback) == "function" then
      callback(result)
    end
  end

  cache.new(cmd, args, result)

  return result
end

---@param job Job
local function get_result(job)
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
    success = success,
    data = result,
  }
end

---@param cmd ChezmoiCmd|string Command to execute
---@param opts ChezmoiCmdOpts Opts for command
M.runAsync = function(cmd, opts)
  local args = { cmd }
  table.insert(args, opts.args or {})

  Job:new({
    command = "chezmoi",
    args = args,
    writer = opts.stdin,
    on_exit = function(_job, _)
      if type(opts.callback) == "function" then
        local result = get_result(_job)
        vim.schedule_wrap(opts.callback)(result)
      end
    end,
  }):sync()
end

return M
