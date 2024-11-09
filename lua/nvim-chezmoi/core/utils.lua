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

M.is_child_of = function(parent_dir, file_path)
  -- Normalize paths for consistent comparison
  local parent_dir_norm = vim.fn.fnamemodify(parent_dir, ":p")
  local file_path_norm = vim.fn.fnamemodify(file_path, ":p")

  -- Check if file_path is a child of parent_dir
  return file_path_norm:sub(1, #parent_dir_norm) == parent_dir_norm
end

M.augroup = function(name)
  return vim.api.nvim_create_augroup("NvimChezmoi_" .. name, {})
end

M.autocmd = function(args)
  vim.api.nvim_create_autocmd(args.events, {
    group = M.augroup(args.group),
    pattern = args.pattern,
    callback = args.callback,
  })
end

return M
