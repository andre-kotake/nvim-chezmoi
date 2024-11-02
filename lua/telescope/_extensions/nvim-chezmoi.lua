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

local source_files = function(opts, title, filesFn)
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

          value = entry,
          path = entry[1] .. "/" .. entry[2],
          display = entry[3],
          ordinal = entry[3],
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
      vim.tbl_deep_extend(
        "force",
        source_files(opts, "Chezmoi Files", plugin_telescope.chezmoi_files),
        {
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local source_file = action_state.get_selected_entry().path
              vim.cmd("edit " .. source_file)
            end)

            return true
          end,
        }
      )
    )
    :find()
end

local managed = function(opts)
  opts = opts or {}
  pickers
    .new(
      opts,
      vim.tbl_deep_extend(
        "force",
        source_files(opts, "Managed Files", plugin_telescope.source_managed),
        {
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local source_file = action_state.get_selected_entry().path
              vim.cmd("edit " .. source_file)
            end)

            return true
          end,
        }
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
