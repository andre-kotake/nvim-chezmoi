local log = require("nvim-chezmoi.core.log")
local chezmoi = require("nvim-chezmoi.chezmoi")
local chezmoi_cache = require("nvim-chezmoi.chezmoi.cache")
local plenary = require("nvim-chezmoi.core.plenary_runner")

--- Creates the autocmds and user cmds
--- @class Commands
--- @field config NvimChezmoiConfig
local M = {}

local augroup = function(name)
  return vim.api.nvim_create_augroup("NvimChezmoi_" .. name, {})
end

local autocmd = function(args)
  vim.api.nvim_create_autocmd(args.events, {
    group = augroup(args.group),
    pattern = args.pattern,
    callback = args.callback,
  })
end

local buf_user_cmd = function(buf, opts)
  vim.api.nvim_buf_create_user_command(buf, opts.name, opts.callback, {
    desc = opts.desc,
    force = true,
  })
end

local user_cmd = function(opts)
  vim.api.nvim_create_user_command(opts.name, opts.callback, {
    desc = opts.desc,
    force = true,
    nargs = opts.nargs,
  })
end

local detect_filetype = function(buf)
  local set_filetype = vim.schedule_wrap(function(ft)
    if vim.bo[buf].filetype ~= ft then
      vim.bo[buf].filetype = ft
    end
  end)

  local file = vim.api.nvim_buf_get_name(buf)
  local source_file = vim.fn.fnamemodify(file, ":p")

  -- Try cache first
  local cached = chezmoi_cache.find_success("ft_detect", { source_file })
  if cached ~= nil then
    local ft = cached.result.data.ft
    if ft ~= vim.bo[buf].filetype then
      set_filetype(ft)
      return
    end
  end

  -- Get target path for source file
  local target_file_result = chezmoi.target_path({ source_file })
  if not target_file_result.success then
    log.warn(target_file_result.data)
    return
  end

  local target_file = target_file_result.data[1]

  -- Try match
  local ft = plenary.get_filetype(target_file)
  -- Could't find the filetype, try temp buf
  if ft == nil or ft == "" then
    local tmp_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(tmp_buf, target_file)
    ft = vim.filetype.match({ buf = tmp_buf }) or ""
    vim.api.nvim_buf_delete(tmp_buf, { force = true })
  end

  set_filetype(ft)

  vim.filetype.add({
    filename = {
      [file] = ft,
    },
  })

  -- Cache it
  chezmoi_cache.new("ft_detect", { source_file }, {
    success = true,
    data = { ft = ft },
  })
end

local edit = function(files)
  local result = chezmoi.edit(files)
  if result.success then
    for _, value in ipairs(result.data) do
      vim.cmd("edit " .. value)
    end
  end
end

local execute_template = function(buf)
  local filename = vim.fn.expand("%:p")
  if not filename:match("%.tmpl$") then
    log.warn("Not a chezmoi template.")
    return
  end

  log.info("Executing template for: " .. filename)

  local result = chezmoi.execute_template(filename)
  if result.success then
    local bufnr = vim.api.nvim_create_buf(false, true)
    for _, line in ipairs(result.data) do
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
    end
    -- Remove empty first line
    vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, {})
    vim.bo[bufnr].filetype = vim.bo[buf].filetype
    vim.api.nvim_set_current_buf(bufnr)
  end
end

---@param opts NvimChezmoiConfig
function M.init(opts)
  M.config = opts
  log.print_debug = M.config.debug

  autocmd({
    group = "SourcePath",
    pattern = M.config.source_path .. "/*",
    events = {
      "BufNewFile",
      "BufRead",
    },
    callback = function(ev)
      buf_user_cmd(ev.buf, {
        name = "ChezmoiDetectFileType",
        desc = "Detect the filetype for a source file",
        callback = function()
          detect_filetype(ev.buf)
        end,
      })

      buf_user_cmd(ev.buf, {
        name = "ChezmoiExecuteTemplate",
        desc = "Execute template for a source file",
        callback = function()
          execute_template(ev.buf)
        end,
      })

      vim.cmd("ChezmoiDetectFileType")
    end,
  })

  user_cmd({
    name = "ChezmoiEdit",
    desc = "Edit a chezmoi file.",
    callback = function(cmd)
      local files
      if #cmd.fargs > 0 then
        files = cmd.fargs
      else
        files = { vim.fn.expand("%:p") }
      end
      edit(files)
    end,
  })
end

return M
