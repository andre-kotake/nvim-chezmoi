local base = require("nvim-chezmoi.chezmoi.wrapper._base")
local chezmoi = require("nvim-chezmoi.chezmoi")

---@class ChezmoiManaged: ChezmoiCommandWrapper
local M = setmetatable({}, {
  __index = base,
  __call = function(self, file)
    self:exec(file)
  end,
})

function M:create_user_commands()
  base.create_user_commands({
    {
      name = "ChezmoiMamaged",
      desc = "Lists managed files.",
      callback = function(cmd)
        local file
        if #cmd.args > 0 then
          file = cmd.fargs
        else
          file = { vim.fn.expand("%:p") }
        end
        M:exec(file)
      end,
      opts = {
        nargs = "*",
      },
    },
  })
end

---@param files? string[]
function M:exec(files)
  local managed_args = files or {}
  table.insert(managed_args, { "--path-style", "all", "--format", "yaml" })

  local managed_files = {}
  local managed_result = chezmoi.run("managed", {
    args = managed_args,
    force = true,
    callback = function(result) end,
  })

  -- Initial table
  local my_table = {
    ".bashrc:",
    "    absolute: /data/data/com.termux/files/home/.bashrc",
    "    sourceAbsolute: /data/data/com.termux/files/home/.local/share/chezmoi/private_dot_bashrc",
    "    sourceRelative: private_dot_bashrc",
  }

  for i = 1, #my_table, 4 do
    -- Remove the trailing ':' from the first string and assign to var
    local file_name = my_table[i]:gsub(":", "")

    -- Extract the paths from the other strings, stripping out the labels
    local absolute_path = my_table[i + 1]:match("absolute:%s*(.-)$")
    local source_absolute_path =
      my_table[i + 2]:match("sourceAbsolute:%s*(.-)$")
    local source_relative_path =
      my_table[i + 3]:match("sourceRelative:%s*(.-)$")

    -- Output the variables
    print("file_name:", file_name)
    print("absolute_path:", absolute_path)
    print("source_absolute_path:", source_absolute_path)
    print("source_relative_path:", source_relative_path)
  end
end

return M
