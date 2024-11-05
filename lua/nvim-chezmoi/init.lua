---Plugin configuration
---@class NvimChezmoiConfig
---@field debug boolean
---@field source_path string
---@field window {execute_template: vim.api.keyset.win_config}

---Main plugin class
---@class NvimChezmoi
---@field opts NvimChezmoiConfig
local M = {
  opts = {
    debug = false,
    source_path = vim.fn.expand("~/.local/share/chezmoi"),
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
  local commands = require("nvim-chezmoi.core.commands")
  commands.init(M.opts)

  local telescope_ok, telescope = pcall(require, "telescope")
  if telescope_ok then
    telescope.load_extension("nvim-chezmoi")
    commands.telescope_init()
  end
end

return M
