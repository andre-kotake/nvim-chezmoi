local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local plugin_telescope = require("nvim-chezmoi.core.telescope")

vim.api.nvim_create_user_command("ChezmoiManaged", function()
  vim.cmd("Telescope nvim-chezmoi managed")
end, {
  desc = "Chezmoi managed files",
  force = true,
})

local source_files_finder = function(opts, title, filesFn)
  opts = opts or {}
  return {
    prompt_title = title,
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer({}),
    finder = finders.new_table({
      results = (function()
        return filesFn()
      end)(),
      entry_maker = function(entry)
        return {
          value = entry[1],
          path = entry[1],
          display = entry[2],
          ordinal = entry[2],
        }
      end,
    }),
  }
end

local chezmoi_files = function(opts)
  opts = opts or {}
  pickers
    .new(
      opts,
      source_files_finder(opts, "Chezmoi Files", plugin_telescope.chezmoi_files)
    )
    :find()
end

local managed = function(opts)
  opts = opts or {}
  pickers
    .new(
      opts,
      source_files_finder(
        opts,
        "Managed Files",
        plugin_telescope.source_managed
      )
    )
    :find()
end

return telescope.register_extension({
  setup = function(user_config, config) end,
  exports = {
    managed = managed,
    chezmoi_files = chezmoi_files,
  },
})
