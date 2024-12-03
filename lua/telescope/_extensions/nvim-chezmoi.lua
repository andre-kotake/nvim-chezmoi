local telescope = require("telescope")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local plugin_telescope = require("nvim-chezmoi.core.telescope")

local picker_config_default = function(opts, title, filesFn)
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
          value = entry,
          path = entry.file,
          display = entry.display,
          ordinal = entry.display,
        }
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local value = selection.value
        if value.isEncrypted then
          require("nvim-chezmoi.chezmoi.commands.edit"):exec(
            selection.value.target_file
          )
          return
        end

        vim.cmd.edit(selection.path)
      end)
      return true
    end,
  }
end

local new_picker = function(opts, title, filesFn)
  opts = opts or {}
  local picker_config = picker_config_default(opts, title, filesFn)
  pickers.new(opts, picker_config):find()
end

local special_files = function(opts)
  new_picker(opts, "Chezmoi Special Files", plugin_telescope.chezmoi_files)
end

local managed = function(opts)
  new_picker(opts, "Managed Files", plugin_telescope.source_managed)
end

return telescope.register_extension({
  setup = function(user_config, config) end,
  exports = {
    managed = managed,
    special_files = special_files,
  },
})
