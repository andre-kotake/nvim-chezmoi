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

local source_files = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Source Files",
      finder = finders.new_table({
        results = plugin_telescope.source_path(),
      }),
      sorter = conf.generic_sorter(opts),
      previewer = conf.file_previewer({}),
    })
    :find()
end

local managed = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Managed Files",
      finder = finders.new_table({
        results = (function()
          local managed_files = plugin_telescope.managed()
          return managed_files
        end)(),
        entry_maker = function(entry)
          return {
            value = entry,
            path = entry[2],
            display = entry[3],
            ordinal = entry[3],
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local source_file = action_state.get_selected_entry().value[2]
          vim.cmd("edit " .. source_file)
        end)

        return true
      end,
      previewer = conf.file_previewer({}),
    })
    :find()
end

return telescope.register_extension({
  setup = function(user_config, config) end,
  exports = {
    managed = managed,
    source_files = source_files,
  },
})
