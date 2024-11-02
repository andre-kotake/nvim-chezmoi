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

local function get_files(path, glob)
  local target_files = {}
  for _, file in ipairs(vim.fn.glob(path .. glob, false, true)) do
    if vim.fn.filereadable(file) == 1 then
      file = file:gsub("^" .. path .. "/", "")
      local resolved_path = _name_resolver.resolvePath(file)
      target_files[#target_files + 1] = {
        path,
        file,
        resolved_path,
      }
    end
  end

  return target_files
end

M.source_managed = function()
  local result = chezmoi.source_path()
  if not result.success then
    return {}
  end

  local source_path = vim.fn.fnamemodify(vim.fn.expand(result.data[1]), ":p")
  local target_files = get_files(source_path, "/**/*")

  return target_files
end

M.chezmoi_files = function()
  local result = chezmoi.source_path()
  if not result.success then
    return {}
  end

  local target_files = {}
  local source_path = vim.fn.fnamemodify(vim.fn.expand(result.data[1]), ":p")

  for _, file in ipairs(vim.fn.glob(source_path .. "/**/.*/**/*", false, true)) do
    if vim.fn.filereadable(file) == 1 then
      file = file:gsub("^" .. source_path .. "/", "")
      vim.list_extend(target_files, {
        {
          source_path,
          file,
          _name_resolver.resolvePath(file),
        },
      })
    end
  end

  return target_files
end

return M
