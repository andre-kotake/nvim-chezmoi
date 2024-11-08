local log = require("nvim-chezmoi.core.log")
local chezmoi = require("nvim-chezmoi.chezmoi")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local chezmoi_edit = require("nvim-chezmoi.chezmoi.wrapper.edit")
local chezmoi_apply = require("nvim-chezmoi.chezmoi.wrapper.apply")
local chezmoi_execute_template =
  require("nvim-chezmoi.chezmoi.wrapper.execute_template")
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

local user_cmd = function(opts)
  vim.api.nvim_create_user_command(opts.name, opts.callback, {
    desc = opts.desc,
    force = true,
    nargs = opts.nargs,
  })
end

---@param opts NvimChezmoiConfig
function M.init(opts)
  M.config = opts
  log.print_debug = M.config.debug
  chezmoi_execute_template(M.config)

  --TODO: Validate if file exists
  autocmd({
    group = "SourcePath",
    pattern = M.config.source_path .. "/*",
    events = {
      "BufNewFile",
      "BufRead",
    },
    callback = function(ev)
      chezmoi_edit:create_buf_user_commands(ev.buf)
    end,
  })

  chezmoi_edit:create_user_commands()
  chezmoi_apply:create_user_commands()
end

M.telescope_init = function()
  local user_commands = {
    {
      name = "ChezmoiManaged",
      desc = "Chezmoi managed files under " .. M.config.source_path,
      callback = function()
        vim.cmd("Telescope nvim-chezmoi managed")
      end,
    },
    {
      name = "ChezmoiFiles",
      desc = "Chezmoi special files under " .. M.config.source_path,
      callback = function()
        vim.cmd("Telescope nvim-chezmoi special_files")
      end,
    },
  }

  for _, cmd in ipairs(user_commands) do
    user_cmd(cmd)
  end
end

return M
