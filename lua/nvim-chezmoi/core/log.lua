local LOG_FILE = vim.fn.stdpath("log") .. "/nvim-chezmoi.log"

-- Truncate once per Neovim session, lazily the first time debugging is
-- observed enabled
local session_truncated = false
local function truncate_logs()
    session_truncated = true
    local fh = io.open(LOG_FILE, "w")
    if fh then
        fh:close()
    end
end

--- A simple logging class that uses vim.notify for logging messages.
--- @class NvimChezmoi.Core.Log
--- @field show_debug_logs fun(): boolean If `true`, enables printing debug messages.
local T = {
    show_debug_logs = function()
        local debug = require("nvim-chezmoi").opts.debug
        if debug and not session_truncated then
            truncate_logs()
        end
        return debug
    end,
}

--- @param ret boolean|any caller-supplied value to return to allow
--- chaining within expressions, defaults to "false" to halt 'and' chain
local notify = function(message, level, ret)
    vim.schedule(function()
        if type(message) == "string" then
            vim.notify(message, level, { title = "nvim-chezmoi" })
        elseif type(message) == "table" then
            vim.notify(
                table.concat(message, "\n"),
                level,
                { title = "nvim-chezmoi" }
            )
        end
    end)

    return ret or false
end

function T.info(message) return notify(message, vim.log.levels.INFO) end

function T.debug(message, ret)
    if not T.show_debug_logs() then
        return
    end
    local text = type(message) == "string" and message
        or table.concat(message, "\n")
    local fh = io.open(LOG_FILE, "a")
    if fh then
        fh:write(os.date("%Y-%m-%d %H:%M:%S") .. " [DEBUG] " .. text .. "\n")
        fh:close()
    end
    local logLevel = vim.log.levels.DEBUG
    return notify(message, logLevel)
end

function T.error(message) return notify(message, vim.log.levels.ERROR) end

function T.warn(message) return notify(message, vim.log.levels.WARN) end

return T
