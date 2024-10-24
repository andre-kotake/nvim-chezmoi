--- Plugin configuration
--- @class NvimChezmoiConfig
local config = {
  debug = false,
  source_path = vim.fn.expand("~/.local/share/chezmoi"),
}

--- @class NvimChezmoi
local M = {}

--- @type NvimChezmoi.Core.Log
local log = require("nvim-chezmoi.core.log")

--- @type boolean,Chezmoi
local _chezmoi_ok, chezmoi = pcall(require, "nvim-chezmoi.chezmoi")
if not _chezmoi_ok then
  log.error("An error has ocurred. Skipping nvim-chezmoi config.")
  error(chezmoi)
end

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

local execute_template = function(buf, file)
  local filename = vim.fn.expand("%:t")
  if filename:match("%.tmpl$") then
    log.debug("Executing template for file: " .. file)

    chezmoi:execute_template(buf, file, function(bufnr)
      -- Set filetype for the executed template buffer
      vim.bo[bufnr].filetype = vim.bo[buf].filetype
    end)
  else
    log.info("Not a chezmoi template.")
  end
end

--- @param opts? NvimChezmoiConfig | nil
--- @return NvimChezmoi | nil
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
  log.print_debug = config.debug

  local augroup = function(name)
    return vim.api.nvim_create_augroup("nvim-chezmoi_" .. name, {})
  end

  local autocmd = function(events, group, pattern, callback)
    vim.api.nvim_create_autocmd(events, {
      group = augroup(group),
      pattern = pattern,
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
  autocmd(
    { "BufNewFile", "BufRead" },
    "source-path",
    config.source_path .. "/*",
    function(ev)
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

      if config.edit.detect_filetype then
        vim.cmd("ChezmoiDetectFileType")
      end
    end
  )

  return M
end

return M
