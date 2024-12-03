local command = require("nvim-chezmoi.chezmoi.command")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")

---@class ChezmoiExecuteTemplate:ChezmoiCommand
local M = setmetatable({
  cmd = "execute-template",
}, {
  __index = command,
})

---@param opts NvimChezmoiConfig
function M:init(opts)
  self.opts = opts
end

---@param bufnr integer
---@return ChezmoiUserCommand[]
function M:bufUserCommands(bufnr)
  return {
    {
      name = "ChezmoiExecuteTemplate",
      desc = "Executes chezmoi template in a new window.",
      callback = function()
        self:exec(vim.api.nvim_buf_get_name(bufnr))
      end,
      opts = {
        nargs = 0,
      },
    },
  }
end

---@param file string
---@return ChezmoiCommandResult
function M:exec(file)
  if type(file) ~= "string" then
    log.error("execute-template needs a file.")
    return {
      success = false,
      data = {},
    }
  end

  file = vim.fn.fnamemodify(file, ":p")
  local bufnr = vim.fn.bufnr(file, true)
  local buflines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local result = command.exec(self, { table.concat(buflines, "\n") })
  if not result.success or #result.data == 0 then
    return result
  end

  if self.opts.open_in == "split" or self.opts.open_in == "vsplit" then
    vim.cmd(self.opts.open_in)
  end

  -- Create buf for executed template
  local buf = chezmoi_helper.create_buf(
    file .. "_executed_template",
    result.data,
    false,
    true,
    false
  )

  -- Set filetype
  vim.bo[buf].filetype = vim.bo[bufnr].filetype
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"

  if self.opts.open_in == "window" then
    -- Create window to display it
    local win = vim.api.nvim_open_win(
      buf,
      true,
      vim.tbl_deep_extend("force", self.opts.window, {
        title = file,
      })
    )
    vim.wo[win].number = true
  end

  -- Set keymaps
  local keymaps = {
    { -- Close on esc or q
      keys = { "q", "<esc>" },
      command = "<cmd>bd!<cr>",
    },
  }

  for _, keymap in ipairs(keymaps) do
    for _, k in ipairs(keymap.keys) do
      vim.keymap.set("n", k, keymap.command, {
        desc = "Close chezmoi executed template.",
        buffer = buf,
        silent = true,
      })
    end
  end

  return result
end

return M
