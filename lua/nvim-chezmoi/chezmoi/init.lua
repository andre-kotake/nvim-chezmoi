if vim.fn.executable("chezmoi") == 0 then
  error(debug.traceback("chezmoi executable not found in PATH."))
end

local runner = require("nvim-chezmoi.core.plenary_runner")
local cache = require("nvim-chezmoi.chezmoi.cache")
local helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")

---Main class for chezmoi command.
---All command results are cached to speed up future invocations.
---@class ChezmoiCommand
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

---

---Executes a chezmoi command and caches the result.
---If cached result was found, return it instead of executing again, unless `force` is `true`.
---@param cmd string Command to execute, e.g. "source-path"
---@param args string[]|nil Additional args to append to `cmd`, e.g. ".bashrc"
---@param stdin? string[]|nil Stdin if needed for command.
---@param success_only? boolean Only returns from cache if result was successful.
---@param force? boolean Force execution ignoring cache.
---@return ChezmoiCommandResult
M.exec = function(cmd, args, stdin, success_only, force)
  local cached

  if not force or true then
    if success_only or false then
      cached = cache.find_success(cmd, args)
    else
      cached = cache.find(cmd, args)
    end

    if cached ~= nil then
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
  end

  cache.new(cmd, args, result)

  return result
end

---Returns the source path for given `files`
---@param files string[]
---@return ChezmoiCommandResult ChezmoiCommandResult where `data` is a string containing the path or the error message.
M.edit = function(files)
  return M.source_path(files)
end

---@param args? string[]|nil Arguments to append to command.
---@return ChezmoiCommandResult ChezmoiCommandResult where `data` is a string containing the path or the error message.
M.managed = function(args)
  local cmd = "managed"
  return M.exec(cmd, args, nil, true)
end

---@param args? string[]|nil Arguments to append to command.
---@return ChezmoiCommandResult ChezmoiCommandResult where `data` is a string containing the path or the error message.
M.source_path = function(args)
  local cmd = "source-path"
  args = helper.expand_path_arg(args)
  return M.exec(cmd, args, nil, true)
end

---@param args? string[]|nil Arguments to append to command.
---@return ChezmoiCommandResult ChezmoiCommandResult where `data` is a string containing the path or the error message.
M.target_path = function(args)
  local cmd = "target-path"
  args = helper.expand_path_arg(args)
  return M.exec(cmd, args, nil, true)
end

return M
