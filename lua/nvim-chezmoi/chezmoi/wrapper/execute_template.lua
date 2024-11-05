local base = require("nvim-chezmoi.chezmoi.wrapper._base")
local chezmoi = require("nvim-chezmoi.chezmoi")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")

---@class ChezmoiExecuteTemplate: ChezmoiCommandWrapper
local M = setmetatable({}, {
  __index = base,
  __call = function(self, file)
    self:exec(file)
  end,
})

function M:create_buf_user_commands(bufnr)
  local commands = {
    {
      name = "ChezmoiExecuteTemplate",
      desc = "Executes chezmoi template in a new buffer",
      callback = function()
        local file = vim.api.nvim_buf_get_name(bufnr)
        M:exec(file)
      end,
    },
  }

  base.create_buf_user_commands(self, bufnr, commands)
end

---@param file string
---@return ChezmoiCommandResult|nil
function M:exec(file)
  file = vim.fn.fnamemodify(file, ":p")
  local bufnr = vim.fn.bufnr(file, true)
  local buflines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- TODO: Some chezmoi files are templates without .tmpl extension
  if not file:match("%.tmpl$") then
    return
  end

  return self:check_result(chezmoi.execute_template, buflines, function(result)
    if result.success then
      local buf = chezmoi_helper.create_buf(
        file .. "_executed_template",
        result.data,
        false,
        true,
        false
      )

      -- Set filetype
      vim.bo[buf].filetype = vim.bo[bufnr].filetype
      vim.bo[buf].buflisted = false
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"

      -- Create window to display it
      local win = vim.api.nvim_open_win(buf, true, {
        title = file,
        relative = "editor",
        width = vim.o.columns,
        height = vim.o.lines,
        row = 0,
        col = 0,
        style = "minimal",
        border = "single",
      })

      vim.wo[win].number = true

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
            desc = "Close executed template.",
            buffer = buf,
            silent = true,
          })
        end
      end

      -- TODO: Close on q or esc
    end

    return result
  end)
end

return M
