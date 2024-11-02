local chezmoi = require("nvim-chezmoi.chezmoi")
local _name_resolver = require("nvim-chezmoi.chezmoi._name_resolver")
local chezmoi_cache = require("nvim-chezmoi.chezmoi.cache")
local scan = require("plenary.scandir")
local path = require("plenary.path")

local M = {}

M.managed = function()
  local result = chezmoi.managed({
    "--path-style",
    "absolute",
    "--exclude",
    "externals,dirs,scripts",
  })
  if not result.success then
    return {}
  end

  local chezmoi_source_path = chezmoi.target_path()
  local source_files = {}

  for _, value in ipairs(result.data) do
    local source_file
    local target_file
    local cached = chezmoi_cache.find("managed_full_" .. value, { value })
    if cached ~= nil then
      source_file = cached.result[2]
      target_file = cached.result[3]
    else
      local source_path = chezmoi.source_path({ value })
      if source_path.success then
        source_file = source_path.data[1]
        target_file = value
      end
    end

    if source_file ~= nil and source_file ~= "" then
      local data = {
        chezmoi_source_path.data[1],
        source_file,
        target_file:gsub("^" .. chezmoi_source_path.data[1] .. "/?", ""),
      }
      source_files[#source_files + 1] = data
      chezmoi_cache.new("managed_full_" .. value, { value }, data)
    end
  end

  return source_files
end

M.source_files = function(hidden, pattern)
  local result = chezmoi.source_path()
  if not result.success then
    return {}
  end

  local files = {}
  local source_path = result.data[1]
  local chezmoi_files = scan.scan_dir(source_path, {
    hidden = hidden or false,
    search_pattern = pattern,
  })

  for _, chezmoi_file in ipairs(chezmoi_files) do
    local file_path = path:new(chezmoi_file):normalize(source_path)
    files[#files + 1] = {
      chezmoi_file,
      file_path,
    }
  end

  return files
end

M.source_managed = function()
  local managed_files = M.source_files(false)
  for i, file in ipairs(managed_files) do
    local target_path = _name_resolver.resolvePath(file[2])
    managed_files[i][2] = target_path
  end
  return managed_files
end

M.chezmoi_files = function()
  return M.source_files(true, "%.chezmoi*")
end

return M
