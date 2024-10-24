--- A simple logging class that uses vim.notify for logging messages.
--- @class NvimChezmoi.Core.Log
--- @field print_debug boolean If `true`, enables printing debug messages.
local T = {
  print_debug = false,
}

--- @param message string: The message to log as info.
function T.info(message)
  vim.notify(":: [INFO]\n" .. message, vim.log.levels.INFO, {})
end

--- @param message string: The message to log as debug.
function T.debug(message)
  local logLevel = T.print_debug and vim.log.levels.INFO or vim.log.levels.DEBUG
  vim.notify(":: [DEBUG]\n" .. message, logLevel, {})
end

--- @param message string: The message to log as error.
function T.error(message)
  vim.notify(":: [ERROR]\n" .. message, vim.log.levels.ERROR, {})
end

return T
