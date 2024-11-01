local j = require("plenary.job")
local plenary_filetype = require("plenary.filetype")

--- @alias callback fun(args:ChezmoiCommandResult)

--- @class PlenaryRunner
--- @field package job Job
local M = {}

local function get_result(job)
  local result = job:result()
  local success = true

  if #result == 0 then
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

local function new(opts)
  return j:new({
    command = "chezmoi",
    args = opts.args,
    writer = opts.stdin,
    cwd = opts.cwd,
    on_exit = function(_job, _)
      -- Execute callback if provided.
      if type(opts.on_exit) == "function" then
        local result = get_result(_job)
        vim.schedule_wrap(opts.on_exit)(result)
      end
    end,
  })
end

function M.exec(opts)
  local job = new(opts)
  job:start()
  job:wait()
  return get_result(job)
end

function M.exec_async(opts)
  new(opts):sync()
end

function M.get_filetype(filepath)
  local ft = plenary_filetype.detect(filepath, {})
  return ft
end

return M
