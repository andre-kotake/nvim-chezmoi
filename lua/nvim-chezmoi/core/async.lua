--- Minimal coroutine helpers for sequential async flows.
--- Lets multi-step chezmoi chains read top-down instead of nesting callbacks.
---
--- Usage:
--- ```lua
--- local async = require("nvim-chezmoi.core.async")
--- async.run(function()
---     local target_path = require("nvim-chezmoi.chezmoi.commands.target_path")
---     local target = async.await(function(cb)
---         target_path:async({ file }, cb)
---     end)
---     -- use target ...
--- end)
--- ```
--- @class NvimChezmoi.Core.Async
local M = {}

-- LuaJIT (Lua 5.1) has no table.pack/table.unpack; use select/unpack.
local unpack = table.unpack or unpack

--- Run `fn` in a new coroutine. Errors surface via `core.log`.
---@param fn function
---@vararg any Arguments forwarded to `fn`.
function M.run(fn, ...)
    local co = coroutine.create(fn)

    local function step(...)
        local ok, err = coroutine.resume(co, ...)
        if not ok then
            require("nvim-chezmoi.core.log").error(
                "Async task failed: " .. tostring(err)
            )
        end
    end

    step(...)
end

--- Inside `M.run`, await a callback-style async function.
--- Yields the coroutine; `fn` receives `...` plus an appended callback
--- and must invoke that callback exactly once.
---@param fn function Async function taking `...` plus a trailing callback.
---@vararg any Arguments forwarded to `fn` before the callback.
---@return any ... Whatever values the callback was invoked with.
function M.await(fn, ...)
    local co = coroutine.running()
    assert(co ~= nil, "async.await called outside async.run")

    local n = select("#", ...)
    local args = { ... }
    args[n + 1] = function(...)
        local res = { ... }
        coroutine.resume(co, unpack(res, 1, select("#", ...)))
    end
    fn(unpack(args, 1, n + 1))
    return coroutine.yield()
end

return M
