if vim.fn.executable("chezmoi") == 0 then
  error(debug.traceback("chezmoi executable not found in PATH."))
end

local runner = require("nvim-chezmoi.core.plenary_runner")
local cache = require("nvim-chezmoi.chezmoi.cache")
local log = require("nvim-chezmoi.core.log")

---Main class for chezmoi command.
---All command results are cached to speed up future invocations.
---@class ChezmoiCommand
local M = {}

---Result of an executed command
---@class ChezmoiCommandResult
---@field success boolean `true` if command returned status code 0.
---@field data table The result data from command execution or error messages if `success` is `false`.

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
    log.warn(result.data)
  end

  cache.new(cmd, args, result)

  return result
end

local function expand_path_arg(args)
  if args == nil then
    return nil
  end

  if #args > 0 then
    if args[1] ~= nil and string.sub(args[1], 1, 2) ~= "--" then
      -- The first item is a path
      args[1] = vim.fn.fnamemodify(vim.fn.expand(args[1]), ":p")
    end
  end

  return args
end

---@param file string
---@return ChezmoiCommandResult
M.execute_template = function(file)
  local get_lines = function(buf_name)
    local bufnr

    for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if buf.name == buf_name then
        bufnr = buf.bufnr
        return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      end
    end

    -- If buffer is not found, create a new scratch buffer
    bufnr = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(bufnr, buf_name)

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    vim.api.nvim_buf_delete(bufnr, { force = true })

    return lines
  end

  return M.exec("execute-template", {
    table.concat(get_lines(file), "\n"),
  }, nil, true)
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
  args = expand_path_arg(args)
  return M.exec(cmd, args, nil, true)
end

---@param args? string[]|nil Arguments to append to command.
---@return ChezmoiCommandResult ChezmoiCommandResult where `data` is a string containing the path or the error message.
M.target_path = function(args)
  local cmd = "target-path"
  args = expand_path_arg(args)
  return M.exec(cmd, args, nil, true)
end

---Returns the source path for given `files`
---@param files string[]
---@return ChezmoiCommandResult ChezmoiCommandResult where `data` is a string containing the path or the error message.
M.edit = function(files)
  return M.source_path(files)
end

return M
