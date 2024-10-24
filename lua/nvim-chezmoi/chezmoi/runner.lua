local j = require("plenary.job")
local plenary = require("plenary")
local plenary_filetype = require("plenary.filetype")

--- @alias callback_args {code:integer, data:string[]}
--- @alias callback fun(args:callback_args)

--- @class ChezmoiCommand
--- @field package job Job
local M = {}
M.__index = M

function M.get_filetype(target_path, source_path)
  local ft = plenary_filetype.detect(target_path, {})
  return ft
end

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

--- Creates a chezmoi command
--- @param args string[]
--- @param stdin string|string[]
--- @param on_exit? callback
--- @return ChezmoiCommand
function M:new(args, stdin, on_exit)
  local instance = setmetatable({}, self)
  instance.job = j:new({
    command = "chezmoi",
    args = args,
    writer = stdin,
    on_exit = function(_job, _code)
      -- Execute callback if provided.
      if type(on_exit) == "function" then
        vim.schedule_wrap(on_exit)(get_result(_job, _code))
      end
    end,
  })
  return instance
end

--- @param and_then_on_success? callback|ChezmoiCommand
function M:run(and_then_on_success)
  if self.job == nil then
    error(debug.traceback("Chezmoi command wasn't created."))
    return
  end

  self.job:add_on_exit_callback(function(job, code)
    if and_then_on_success ~= nil and code == 0 then
      if type(and_then_on_success) == "function" then
        and_then_on_success(get_result(job, code))
      else
        self.job:and_then_on_success(and_then_on_success.job)
      end
    end

    self.job:add_on_exit_callback(function()
      self.job = nil
    end)

    self.job:_stop()
  end)

  self.job:start()
end

return M
