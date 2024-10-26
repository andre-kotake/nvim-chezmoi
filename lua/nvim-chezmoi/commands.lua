local log = require("nvim-chezmoi.core.log")
local _chezmoi_ok, chezmoi = pcall(require, "nvim-chezmoi.chezmoi")
if not _chezmoi_ok then
  log.error("An error has ocurred. Skipping nvim-chezmoi config.")
  error(chezmoi)
end

--- Creates the autocmds and user cmds
--- @class Commands
--- @field config NvimChezmoiConfig
local M = {}

local augroup = function(name)
  return vim.api.nvim_create_augroup("nvim-chezmoi_" .. name, {})
end

local autocmd = function(args)
  vim.api.nvim_create_autocmd(args.events, {
    group = augroup("source-path"),
    pattern = args.pattern,
    callback = args.callback,
  })
end

local user_cmd = function(buf, name, desc, callback)
  vim.api.nvim_buf_create_user_command(buf, name, callback, {
    desc = desc,
    force = true,
  })
end

local source_autocmds = function()
  --- Detect Filetype for a source file
  --- @param buf integer
  --- @param filename string
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

  autocmd({
    group = "source-path",
    pattern = M.config.source_path .. "/*",
    events = {
      "BufNewFile",
      "BufRead",
    },
    callback = function(ev)
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
    end,
  })
end

--- Initializes the autocmds and user cmds.
--- @param opts NvimChezmoiConfig
function M.init(opts)
  M.config = opts
  log.print_debug = M.config.debug
  source_autocmds()
end

return M
