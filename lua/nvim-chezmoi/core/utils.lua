local M = {}

M.trim = function(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end

M.fullpath = function(s)
  return vim.fn.fnamemodify(s, ":p")
end

M.strip_path = function(s, prefix)
  return s:gsub("^" .. prefix, ""):gsub("^/", "")
end

M.isChildPath = function(parent, child)
  -- Normalize paths (remove trailing slashes for consistency)
  parent = parent:gsub("/$", "")
  child = child:gsub("/$", "")

  -- Check if child starts with parent and has a separator after it
  return child:sub(1, #parent) == parent
    and (child:sub(#parent + 1, #parent + 1) == "/" or #child == #parent)
end

M.table_append = function(t1, t2)
  for _, v in ipairs(t2) do
    table.insert(t1, v)
  end
  return t1
end

M.get_source_by_target = function(table, targetValue)
  for key, value in pairs(table) do
    if value.target == targetValue then
      return key
    end
  end
  return nil -- Return nil if the value is not found
end

M.augroup = function(name)
  return vim.api.nvim_create_augroup("NvimChezmoi_" .. name, {})
end

return M
