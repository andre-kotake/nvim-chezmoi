local chezmoi = require("nvim-chezmoi.chezmoi")
local _name_resolver = require("nvim-chezmoi.chezmoi._name_resolver")
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

M.source_managed = function()
  local result = chezmoi.source_path()
  if not result.success then
    return {}
  end

  local files = {}

  -- Remove .chezmoi files and dirs
  for _, file in ipairs(vim.fn.glob(result.data[1] .. "/*", true, true)) do
    if not file:match("^%.chezmoi") then
      vim.list_extend(files, { file })
    end
  end

  local target_files = {}
  -- Use vim.fn.glob to get a list of files in the directory
  local source_path = vim.fn.fnamemodify(vim.fn.expand(result.data[1]), ":p")
  for _, file in ipairs(vim.fn.glob(source_path .. "/**/*", false, true)) do
    -- Check if the file is a regular file
    if vim.fn.filereadable(file) == 1 then
      file = file:gsub("^" .. source_path .. "/", "")
      -- Remove suffixes from each folder in the path
      local pathWithoutSuffixes = vim.fn.fnamemodify(file, ":h")
      if pathWithoutSuffixes == "." then
        pathWithoutSuffixes = ""
      else
        local path_tmp = ""
        for part in pathWithoutSuffixes:gmatch("[^/]+") do
          path_tmp = _name_resolver.removeDirectoryPrefixes(part) .. "/"
        end
        pathWithoutSuffixes = path_tmp
      end

      -- Remove the file suffix
      local filenameWithoutSuffix =
        _name_resolver.removeFilePrefixes(vim.fn.fnamemodify(file, ":t")) -- Remove file suffix

      -- Combine the processed path and filename
      local processedFile = pathWithoutSuffixes .. filenameWithoutSuffix
      vim.list_extend(target_files, {
        {
          source_path,
          file,
          processedFile,
        },
      }) -- Add the processed file path to the list
    end
  end
  vim.print(vim.inspect(target_files))
  return target_files
end

return M
