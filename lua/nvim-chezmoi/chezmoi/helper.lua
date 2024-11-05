---Auxiliary class to handle chezmoi file names
local M = {}

M.is_encrypted = function(file)
  return string.find(vim.fn.fnamemodify(file, ":t"), "^encrypted_") ~= nil
end

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
  filename = removePrefixes({
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
  }, filename)

  if filename:sub(-5) == ".tmpl" then
    filename = filename:sub(1, -6)
  end

  return filename
end

M.removeDirectoryPrefixes = function(dir)
  return removePrefixes({
    "remove_",
    "external_",
    "exact_",
    "private_",
    "readonly_",
    "dot_",
  }, dir)
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

M.expand_path_arg = function(args)
  if args == nil then
    return nil
  end

  if #args > 0 then
    if args[1] ~= nil and string.sub(args[1], 1, 2) ~= "--" then
      -- The first item is a path
      args[1] = vim.fn.fnamemodify(vim.fn.expand(args[1]), ":p")
    end
  end

  return args
end

---Creates a new buffer
---@param name string
---@return integer bufnr
M.create_buf = function(name, contents, listed, scratch, focus)
  local bufexists = vim.fn.bufexists(name)
  local bufnr

  if bufexists == 0 then
    bufnr = vim.api.nvim_create_buf(listed or true, scratch or false)

    if not scratch then
      vim.api.nvim_buf_set_name(bufnr, name)
    end

    if contents ~= nil and type(contents) == "table" then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    end
  else -- Buffer already exists, open that instead
    bufnr = vim.fn.bufnr(name)
    vim.api.nvim_command("buffer " .. bufnr)
  end

  if focus or true then
    vim.api.nvim_set_current_buf(bufnr)
  end

  return bufnr
end

return M
