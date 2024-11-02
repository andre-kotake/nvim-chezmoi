local M = {}

local function removePrefixes(prefixes, name)
  for _, prefix in ipairs(prefixes) do
    if name:sub(1, #prefix) == prefix then
      if prefix == "dot_" then
        name = name:gsub(prefix, ".")
      else
        name = name:sub(#prefix + 1) -- Remove the prefix
      end

      if prefix == "literal_" then
        break
      end
    end
  end

  return name
end

M.removeFilePrefixes = function(filename)
  local groups = {
    "literal_",
    "create_",
    "modify_",
    "remove_",
    "symlink_",
    "run_",
    "once_",
    "onchange_",
    "before_",
    "after_",
    "encrypted_",
    "private_",
    "readonly_",
    "empty_",
    "executable_",
    "dot_",
  }
  filename = removePrefixes(groups, filename)

  if filename:sub(-5) == ".tmpl" then
    filename = filename:sub(1, -6)
  end

  return filename
end

M.removeDirectoryPrefixes = function(dir)
  local prefixes = {
    "remove_",
    "external_",
    "exact_",
    "private_",
    "readonly_",
    "dot_",
  }

  dir = removePrefixes(prefixes, dir)

  return dir
end

M.resolvePath = function(file)
  -- Remove suffixes from each folder in the path
  local pathWithoutSuffixes = vim.fn.fnamemodify(file, ":h")
  if pathWithoutSuffixes == "." then
    pathWithoutSuffixes = ""
  else
    local path_tmp = ""
    for part in pathWithoutSuffixes:gmatch("[^/]+") do
      path_tmp = path_tmp .. M.removeDirectoryPrefixes(part) .. "/"
    end
    pathWithoutSuffixes = path_tmp
  end

  -- Remove the file suffix
  local filenameWithoutSuffix =
    M.removeFilePrefixes(vim.fn.fnamemodify(file, ":t")) -- Remove file suffix

  -- Combine the processed path and filename
  local processedFile = pathWithoutSuffixes .. filenameWithoutSuffix
  return processedFile
end

return M
