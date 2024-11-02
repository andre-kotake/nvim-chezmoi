local chezmoi = require("nvim-chezmoi.chezmoi")
local chezmoi_cache = require("nvim-chezmoi.chezmoi.cache")

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

M.source_path = function()
  local result = chezmoi.source_path()
  if not result.success then
    return {}
  end
  local files = vim.fn.glob(result.data[1] .. "/**/*", true, true)
  local file_list = {}

  for _, file in ipairs(files) do
    if vim.fn.isdirectory(file) == 0 then
      table.insert(file_list, file)
    end
  end

  return file_list
end

return M
