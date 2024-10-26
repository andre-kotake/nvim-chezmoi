--- Plugin configuration
--- @class NvimChezmoiConfig
--- @field debug boolean
--- @field source_path string

--- Main plugin class
--- @class NvimChezmoi
--- @field opts NvimChezmoiConfig
local M = {
  opts = {
    debug = false,
    source_path = vim.fn.expand("~/.local/share/chezmoi"),
  },
}

--- @param opts? NvimChezmoiConfig | nil
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
  require("nvim-chezmoi.commands").init(M.opts)
  require("telescope").load_extension("nvim-chezmoi")
end

return M
