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

return M
