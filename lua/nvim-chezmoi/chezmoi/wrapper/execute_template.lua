local base = require("nvim-chezmoi.chezmoi.wrapper._base")
local chezmoi = require("nvim-chezmoi.chezmoi")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")

---@class ChezmoiExecuteTemplate: ChezmoiCommandWrapper
---@field opts NvimChezmoiConfig
local M = setmetatable({ opts = {} }, {
  __index = base,
  __call = function(self, opts)
    self:init(opts)
  end,
})

---@param opts NvimChezmoiConfig
function M:init(opts)
  self.opts = opts
end

---@param bufnr integer
function M:create_buf_user_commands(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  base.create_buf_user_commands(bufnr, {
    {
      name = "ChezmoiExecuteTemplate",
      desc = "Executes chezmoi template in a new buffer",
      callback = function()
        M:exec(file)
      end,
    },
  })
end

---@param file string
---@return ChezmoiCommandResult|nil
function M:exec(file)
  file = vim.fn.fnamemodify(file, ":p")
  local bufnr = vim.fn.bufnr(file, true)
  local buflines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local args = { table.concat(buflines, "\n") }

  chezmoi.run("execute-template", {
    args = args,
    force = true,
    callback = function(result)
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
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"

        -- Create window to display it
        local win_opts =
          vim.tbl_deep_extend("force", self.opts.window.execute_template, {
            title = file,
          })
        local win = vim.api.nvim_open_win(buf, true, win_opts)
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
      end

      return result
    end,
  })
end

return M
