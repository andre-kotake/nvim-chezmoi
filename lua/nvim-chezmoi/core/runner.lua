local j = require("plenary.job")
local plenary_filetype = require("plenary.filetype")

--- @alias callback_args {code:integer, data:string[]}
--- @alias callback fun(args:callback_args)

--- @class ChezmoiCommand
--- @field package job Job
local M = {}

local function get_result(job, code)
  local result = job:result()

  if code ~= 0 then
    -- Error, trim each and join with newline
    local stderr = {}
    for _, v in ipairs(job:stderr_result()) do
      stderr[#stderr + 1] = v:gsub("^%s*(.-)%s*$", "%1")
    end
    result = { table.concat(stderr, "\n") }
  end

  return {
    code = code,
    data = result,
  }
end

local function new(opts)
  return j:new({
    command = "chezmoi",
    args = opts.args,
    writer = opts.stdin,
    on_exit = function(_job, _code)
      -- Execute callback if provided.
      if type(opts.on_exit) == "function" then
        local result = get_result(_job, _code)
        vim.schedule_wrap(opts.on_exit)(result)
      end
    end,
  })
end

function M.exec(opts)
  local result = {}

  opts.on_exit = function(command_result)
    result = command_result
  end

  new(opts):start()

  return result
end

function M.exec_async(opts)
  new(opts):sync()
end

function M.get_filetype(filepath)
  local ft = plenary_filetype.detect(filepath, {})
  return ft
end

return M
