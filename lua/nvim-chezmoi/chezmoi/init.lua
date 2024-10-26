-- Validate if chezmoi exists in PATH
if vim.fn.executable("chezmoi") == 0 then
  error(debug.traceback("chezmoi executable not found in PATH."))
end

local runner = require("nvim-chezmoi.core.runner")
local utils = require("nvim-chezmoi.core.utils")

--- @class Chezmoi
--- @field source-path string
--- @field target-path string
--- @field managed { [string]: {target:string,ft:string} }
local M = {
  managed = {},
}

---@param args string[]
---@param stdin? string[]
local function exec(args, stdin)
  runner.exec({
    args = args,
    stdin = stdin or {},
  })
end

---@param args string[]
---@param stdin? string[]
--- @param on_exit? fun(args: any)
local function exec_async(args, stdin, on_exit)
  runner.exec_async({
    args = args,
    stdin = stdin or {},
    on_exit = on_exit,
  })
end

function M:get_target_path(source_file, callback)
  source_file = utils.fullpath(source_file)

  exec_async({ "target-path", source_file }, nil, function(result)
    local managed_file = M.managed[source_file]

    if managed_file == nil or managed_file.ft == nil then
      local target_file = result.data[1]

      -- Try filetype from plenary first
      local ft = runner.get_filetype(target_file)
      -- Plenary could't find the filetype, try temp buf
      if ft == nil or ft == "" then
        local tmp_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(tmp_buf, target_file)
        ft = vim.filetype.match({ buf = tmp_buf }) or ""
        vim.api.nvim_buf_delete(tmp_buf, { force = true })
      end

      -- Add new filetype
      vim.filetype.add({
        filename = {
          [source_file] = ft,
        },
      })

      -- Cache it.
      M.managed[source_file] = {
        target = target_file,
        ft = ft,
      }
    end

    callback(M.managed[source_file])
  end)
end

function M:execute_template(buf, source_file, callback)
  source_file = utils.fullpath(source_file)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  exec_async({ "execute-template" }, table.concat(lines, "\n"), function(result)
    -- Create a new buffer
    local bufnr = vim.api.nvim_create_buf(false, true)
    -- Set the buffer as the current one
    vim.api.nvim_set_current_buf(bufnr)
    -- Append each line from the array to the buffer
    for _, line in ipairs(result.data) do
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
    end
    -- Remove empty first line
    vim.api.nvim_buf_set_lines(0, 0, 1, false, {})

    callback(bufnr)
  end)
end

function M.get_managed_files()
  local managed_files = exec({
    "managed",
    "--path-style",
    "source-absolute",
    "--include",
    "files",
    "--exclude",
    "externals",
  })
end

return M

---

--
-- local utils = require("nvim-chezmoi.core.utils")
-- local runner = require("nvim-chezmoi.core.runner")
--
-- --- @class NvimChezmoi.Chezmoi
-- --- @field source-path string
-- --- @field target-path string
-- --- @field managed_files table<string,string>
-- local M = {}
--
-- --- @param args string[] The arguments to pass to the `chezmoi` command.
-- --- @param on_exit? on_exit
-- local function execute(args, on_exit, callback)
--   command:new(args, on_exit):run()
-- end
--
-- function M.init(on_init)
--   local function getPath(key)
--     return function(code, data)
--       if code == 0 then
--         M[key] = code == 0 and data[1]
--       end
--     end
--   end
--   execute("source-path", getPath("source-path"))
--   execute("target-path", getPath("target-path"))
--
--   runner:new({
--     cmd = "chezmoi",
--     args = "source-path",
--     on_exit = function(result)
--       vim.print(vim.inspect(result.data))
--     end,
--   })
--   return M
-- end
--
-- -- M["source-path"] = "dj"
-- -- M.managed = setmetatable({}, {
-- --   __index = function(t, k)
-- --     vim.notify("index", vim.log.levels.INFO, {})
-- --
-- --     if utils.isChildPath(M["source-path"], k) then
-- --       rawset(t, k, "")
-- --       return t[k]
-- --     end
-- --
-- --     return nil
-- --   end,
-- -- })
--
-- --- @param callback? NvimChezmoi.Core.Runner.Callback
-- function M.managed(callback)
--   execute({ "managed" }, function(code, data)
--     -- for i, v in ipairs(data) do
--     --   cache.managed[v] = tostring(i)
--     -- end
--
--     if callback ~= nil then
--       callback(code, data)
--     end
--   end)
-- end
--
-- return M
