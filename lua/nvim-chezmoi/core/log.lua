--- A simple logging class that uses vim.notify for logging messages.
--- @class NvimChezmoi.Core.Log
--- @field print_debug boolean If `true`, enables printing debug messages.
local T = {
  print_debug = false,
}

local notify = function(message, level)
  vim.notify(message, level, { title = "nvim-chezmoi" })
end

function T.info(message)
  notify(":: [INFO]\n" .. message, vim.log.levels.INFO)
end

function T.debug(message)
  local logLevel = T.print_debug and vim.log.levels.INFO or vim.log.levels.DEBUG
  notify(":: [DEBUG]\n" .. message, logLevel)
end

function T.error(message)
  notify(":: [ERROR]\n" .. message, vim.log.levels.ERROR)
end

return T
