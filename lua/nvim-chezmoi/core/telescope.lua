local scan = require("plenary.scandir")
local path = require("plenary.path")

---@class NvimChezmoiTelescope
---@field source_path string
local M = {}

M.init = function(source_path)
  local telescope_ok, telescope = pcall(require, "telescope")
  if not telescope_ok then
    return
  end

  M.source_path = source_path

  local chezmoi_managed = require("nvim-chezmoi.chezmoi.commands.managed")
  chezmoi_managed:create_user_commands()

  local user_commands = {
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

  telescope.load_extension("nvim-chezmoi")
end

M.source_managed = function()
  local files = require("nvim-chezmoi.chezmoi.commands.managed"):exec()
  local managed_files = {}
  if files.success then
    for _, v in pairs(files.data) do
      managed_files[#managed_files + 1] = {
        file = v.sourceAbsolute,
        display = v.relative,
        target_file = v.absolute,
        isEncrypted = v:isEncrypted(),
      }
    end
  end
  return managed_files
end

M.chezmoi_files = function()
  local files = {}

  if type(M.source_path) ~= "string" then
    local result = require("nvim-chezmoi.chezmoi.commands.source_path"):exec()
    M.source_path = result.data[1]
  end

  local source_path = M.source_path
  local chezmoi_files = scan.scan_dir(source_path, {
    hidden = true,
    search_pattern = "%.chezmoi*",
  })

  for _, chezmoi_file in ipairs(chezmoi_files) do
    local file_path = path:new(chezmoi_file):normalize(source_path)
    files[#files + 1] = {
      file = chezmoi_file,
      display = file_path,
    }
  end

  return files
end

return M
