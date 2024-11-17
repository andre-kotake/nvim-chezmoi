---Plugin configuration
---@class NvimChezmoiConfig
---@field debug boolean
---@field source_path string|nil
---@field window {execute_template: vim.api.keyset.win_config}

---Main plugin class
---@class NvimChezmoi
---@field opts NvimChezmoiConfig
local M = {
  opts = {
    debug = false,
    source_path = nil,
    window = {
      execute_template = {
        relative = "editor",
        width = vim.o.columns,
        height = vim.o.lines,
        row = 0,
        col = 0,
        style = "minimal",
        border = "single",
      },
    },
  },
}

local setup_plugin = function()
  local chezmoi_edit = require("nvim-chezmoi.chezmoi.commands.edit")
  local chezmoi_apply = require("nvim-chezmoi.chezmoi.commands.apply")
  local chezmoi_exec_tmpl =
    require("nvim-chezmoi.chezmoi.commands.execute_template")
  local utils = require("nvim-chezmoi.core.utils")

  -- Create autocmds and cmds
  chezmoi_exec_tmpl:init(M.opts)
  chezmoi_edit:create_user_commands()
  chezmoi_apply:create_user_commands()

  vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
    group = utils.augroup("SourcePath"),
    pattern = M.opts.source_path .. "/*",
    callback = function(ev)
      chezmoi_exec_tmpl:create_buf_user_commands(ev.buf)
      chezmoi_edit:create_buf_user_commands(ev.buf)
      chezmoi_edit:detect_filetype(ev.buf)
    end,
  })

  require("nvim-chezmoi.core.telescope").init(M.opts.source_path)
end

--- @param opts? NvimChezmoiConfig | nil
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

  if M.opts.source_path ~= nil then
    setup_plugin()
  else
    require("nvim-chezmoi.chezmoi.commands.source_path"):async(
      {},
      function(result)
        if not result.success then
          return
        end

        M.opts.source_path = result.data[1]
        setup_plugin()

        -- Create buf user commands for already opened source file buffer.
        local utils = require("nvim-chezmoi.core.utils")
        for _, buf in ipairs(vim.fn.getbufinfo({ buf = "buflisted" })) do
          local file_path = vim.fn.bufname(buf.bufnr)
          -- Only check buffers with a valid file path
          if
            file_path ~= "" and utils.is_child_of(M.opts.source_path, file_path)
          then
            vim.api.nvim_exec_autocmds({ "BufRead" }, {
              buffer = buf.bufnr,
            })
          end
        end
      end
    )
  end
end

return M
