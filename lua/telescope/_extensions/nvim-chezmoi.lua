local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

-- TODO: Refactor this, use the source path or chezmoi managed.
local source_files = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Source Files",
      finder = finders.new_table({
        results = (function()
          local nvim_chezmoi = require("nvim-chezmoi")

          if nvim_chezmoi.opts == nil then
            return {}
          end

          local files =
            vim.fn.glob(nvim_chezmoi.opts.source_path .. "/**/*", true, true)
          local file_list = {}

          for _, file in ipairs(files) do
            if vim.fn.isdirectory(file) == 0 then
              table.insert(file_list, file)
            end
          end

          return file_list
        end)(),
      }),
      sorter = conf.generic_sorter(opts),
    })
    :find()
end

return telescope.register_extension({
  setup = function(user_config, config) end,
  exports = {
    source_files = source_files,
  },
})
