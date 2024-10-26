--- Plugin configuration
--- @class NvimChezmoiConfig
--- @field debug boolean
--- @field source_path string

--- @class NvimChezmoi
--- @field opts NvimChezmoiConfig
local M = {
  opts = {
    debug = false,
    source_path = vim.fn.expand("~/.local/share/chezmoi"),
  },
}

local log = require("nvim-chezmoi.core.log")
local _chezmoi_ok, chezmoi = pcall(require, "nvim-chezmoi.chezmoi")
if not _chezmoi_ok then
  log.error("An error has ocurred. Skipping nvim-chezmoi config.")
  error(chezmoi)
end

--- Detect Filetype for a source file
---@param buf integer
---@param filename string
local detect_filetype = function(buf, filename)
  chezmoi:get_target_path(filename, function(managed)
    local filetype = vim.bo[buf].filetype
    if filetype ~= managed.ft then
      log.debug(
        "Original filetype: "
          .. filetype
          .. "\nSetting nem filetype: "
          .. managed.ft
      )
      vim.bo[buf].filetype = managed.ft
    else
      log.debug("Original filetype: " .. filetype .. "\nNot changing it.")
    end
  end)
end

--- Executes the template for a file and sets the filetype
--- @param buf integer
--- @param file string
local execute_template = function(buf, file)
  local filename = vim.fn.expand("%:t")
  if filename:match("%.tmpl$") then
    log.debug("Executing template for file: " .. file)
    chezmoi:execute_template(buf, file, function(bufnr)
      vim.bo[bufnr].filetype = vim.bo[buf].filetype
    end)
  else
    log.info("Not a chezmoi template.")
  end
end

--- @param opts? NvimChezmoiConfig | nil
function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
  log.print_debug = M.opts.debug

  require("telescope").load_extension("nvim-chezmoi")

  local augroup = function(name)
    return vim.api.nvim_create_augroup("nvim-chezmoi_" .. name, {})
  end

  local autocmd = function(callback)
    vim.api.nvim_create_autocmd({
      "BufNewFile",
      "BufRead",
    }, {
      group = augroup("source-path"),
      pattern = M.opts.source_path .. "/*",
      callback = callback,
    })
  end

  local user_cmd = function(buf, name, desc, callback)
    vim.api.nvim_buf_create_user_command(buf, name, callback, {
      desc = desc,
      force = true,
    })
  end

  --- Set filetype for source file
  autocmd(function(ev)
    user_cmd(
      ev.buf,
      "ChezmoiDetectFileType",
      "Detect the filetype for a source file",
      function()
        detect_filetype(ev.buf, ev.file)
      end
    )

    user_cmd(
      ev.buf,
      "ChezmoiExecuteTemplate",
      "Preview the file template",
      function()
        execute_template(ev.buf, ev.file)
      end
    )

    vim.cmd("ChezmoiDetectFileType")
  end)
end

return M
