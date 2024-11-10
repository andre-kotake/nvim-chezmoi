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

--- @param opts? NvimChezmoiConfig | nil
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

  local setup_plugin = function()
    local chezmoi_edit = require("nvim-chezmoi.chezmoi.wrapper.edit")
    local chezmoi_apply = require("nvim-chezmoi.chezmoi.wrapper.apply")
    local chezmoi_exec_tmpl =
      require("nvim-chezmoi.chezmoi.wrapper.execute_template")
    local chezmoi_managed = require("nvim-chezmoi.chezmoi.wrapper.managed")
    local utils = require("nvim-chezmoi.core.utils")

    -- Create autocmds and cmds
    chezmoi_exec_tmpl:init(M.opts)
    chezmoi_edit:create_user_commands()
    chezmoi_apply:create_user_commands()
    chezmoi_managed:create_user_commands()

    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
      group = utils.augroup("SourcePath"),
      pattern = M.opts.source_path .. "/*",
      callback = function(ev)
        chezmoi_edit:create_buf_user_commands(ev.buf)
      end,
    })
  end

  local setup_plugin_no_source_path = function()
    local chezmoi = require("nvim-chezmoi.chezmoi")
    chezmoi.runAsync("source-path", {
      callback = function(result)
        if not result.success then
          return
        end

        local source_path = result.data[1]
        M.opts.source_path = source_path
        setup_plugin()

        -- Create buf user commands for already opened source file buffer.
        local utils = require("nvim-chezmoi.core.utils")
        local chezmoi_edit = require("nvim-chezmoi.chezmoi.wrapper.edit")
        for _, buf in ipairs(vim.fn.getbufinfo({ buf = "buflisted" })) do
          -- Get the file name of the buffer (bufname is under the `bufname` field)
          local file_path = vim.fn.bufname(buf.bufnr)
          -- Only check buffers with a valid file path
          if file_path ~= "" and utils.is_child_of(source_path, file_path) then
            chezmoi_edit:create_buf_user_commands(buf.bufnr)
          end
        end
      end,
    })
  end

  if M.opts.source_path ~= nil then
    setup_plugin()
  else
    setup_plugin_no_source_path()
  end

  -- Load telescope load_extension
  M.telescope_init()
end

function M.telescope_init()
  local telescope_ok, telescope = pcall(require, "telescope")
  if not telescope_ok then
    return
  end

  telescope.load_extension("nvim-chezmoi")

  local user_commands = {
    {
      name = "ChezmoiManaged",
      callback = function()
        vim.cmd("Telescope nvim-chezmoi managed")
      end,
      opts = {
        desc = "Chezmoi managed files under source path",
        nargs = 0,
      },
    },
    {
      name = "ChezmoiFiles",
      callback = function()
        vim.cmd("Telescope nvim-chezmoi special_files")
      end,
      opts = {
        desc = "Chezmoi special files under source path",
        nargs = 0,
      },
    },
  }

  for _, cmd in ipairs(user_commands) do
    vim.api.nvim_create_user_command(cmd.name, cmd.callback, cmd.opts)
  end
end

return M
