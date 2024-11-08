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

M.table_append = function(t1, t2)
  for _, v in ipairs(t2) do
    table.insert(t1, v)
  end
  return t1
end

M.augroup = function(name)
  return vim.api.nvim_create_augroup("NvimChezmoi_" .. name, {})
end

return M
