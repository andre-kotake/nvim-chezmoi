---@class ChezmoiCacheEntry
---@field args string[] Command arguments
---@field result ChezmoiCommandResult Command return

---@class ChezmoiCache
local M = {}

local log = require("nvim-chezmoi.core.log")

---@type table<string, table<string, ChezmoiCacheEntry>>
local store = {}

---@param args string[]|nil
---@return string
local function get_arg_key(args) return args and table.concat(args, "\0") or "" end

---@param cmd string
---@param args string[]|nil
---@return string
local function describe(cmd, args)
    return table.concat({ cmd, table.concat(args or {}, " ") }, " ")
end

---@param cache_state string
---@param cmd_str string
local function log_debug(cache_state, cmd_str)
    log.debug(cache_state .. ": '" .. cmd_str .. "'")
end

---@param cmd string
---@param args string[]|nil
---@return ChezmoiCacheEntry|nil
M.find = function(cmd, args)
    local bucket = store[cmd]
    local entry = bucket and bucket[get_arg_key(args)]

    if entry then
        log_debug("cache hit", describe(cmd, args))
    else
        log_debug("cache miss", describe(cmd, args))
    end

    return entry
end

---@param cmd string
---@param args string[]|nil
---@return ChezmoiCacheEntry|nil
M.find_success = function(cmd, args)
    local cached = M.find(cmd, args)
    if cached ~= nil and cached.result.success then
        return cached
    end

    if cached ~= nil then
        log_debug("cache entry not successful, ignoring", describe(cmd, args))
    end
    return nil
end

---@param cmd string
---@param args string[]|nil
---@param result ChezmoiCommandResult
---@return ChezmoiCacheEntry entry
---@return fun() invalidate Removes this entry only if it is still the stored one
M.new = function(cmd, args, result)
    local arg_key = get_arg_key(args)

    local entry = {
        args = args or {},
        result = result,
    }

    store[cmd] = store[cmd] or {}
    store[cmd][arg_key] = entry

    log_debug(
        "cache store success=" .. tostring(result.success),
        describe(cmd, args)
    )

    local function invalidate()
        local bucket = store[cmd]
        if bucket and bucket[arg_key] == entry then
            bucket[arg_key] = nil
            log_debug("cache invalidate", describe(cmd, args))
        else
            log_debug(
                "cache invalidate skipped (replaced or removed)",
                describe(cmd, args)
            )
        end
    end

    return entry, invalidate
end

return M
