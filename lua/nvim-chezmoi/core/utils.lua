local M = {}

M.trim = function(s)
  return s:gsub("^%s*(.-)%s*$", "%1")
end

M.isChildPath = function(parent, child)
  -- Normalize paths (remove trailing slashes for consistency)
  parent = parent:gsub("/$", "")
  child = child:gsub("/$", "")

  -- Check if child starts with parent and has a separator after it
  return child:sub(1, #parent) == parent
    and (child:sub(#parent + 1, #parent + 1) == "/" or #child == #parent)
end

return M
