--- Thin `vim.system` wrapper with legacy-compatible result shaping.
--- @class NvimChezmoi.Core.Job
local M = {}

--- Default timeout for blocking `:wait()`, in milliseconds.
M.TIMEOUT_MS = 60000

--- Split process output into lines.
--- Matches the old job semantics: strips `\r`, splits on `\n`,
--- no trailing `""` when output ends with a newline.
---@param s string|nil
---@return string[]
local function split_lines(s)
    if s == nil or s == "" then
        return {}
    end

    local lines = vim.split(s:gsub("\r", ""), "\n", { plain = true })
    if lines[#lines] == "" then
        lines[#lines] = nil
    end
    return lines
end

--- Normalize stdin for `vim.system`.
--- Matches the old `writer` semantics: each table item is followed
--- by `"\n"`, including a trailing newline after the last item.
---@param stdin string|string[]|nil
---@return string|nil
local function normalize_stdin(stdin)
    if type(stdin) == "table" then
        if #stdin == 0 then
            return nil
        end
        return table.concat(stdin, "\n") .. "\n"
    end
    return stdin
end

---@param stdin string|string[]|nil
---@param cwd string|nil
---@return vim.SystemOpts
local function system_opts(stdin, cwd)
    return {
        stdin = normalize_stdin(stdin),
        cwd = cwd,
    }
end

--- Shape a `vim.system` completion into a `ChezmoiCommandResult`.
--- On success `data` holds stdout lines; on failure it holds the
--- trimmed stderr lines joined with newline (legacy parity).
---@param argv string[]
---@param out vim.SystemCompleted
---@return ChezmoiCommandResult
local function shape(argv, out)
    local success = out.code == 0
    local data
    if success then
        data = split_lines(out.stdout)
    else
        local stderr = split_lines(out.stderr)
        for i, v in ipairs(stderr) do
            stderr[i] = v:gsub("^%s*(.-)%s*$", "%1")
        end
        data = { table.concat(stderr, "\n") }
    end

    return {
        args = argv,
        success = success,
        data = data,
    }
end

---@class NvimChezmoi.Core.JobRunOpts
---@field cwd? string Working directory for the child process.
---@field timeout? integer Blocking wait timeout in milliseconds.

--- Run `argv` and block until it exits.
---@param argv string[] Full argv, e.g. `{ "chezmoi", "managed", ... }`.
---@param stdin string|string[]|nil Lines (or blob) fed to stdin.
---@param opts NvimChezmoi.Core.JobRunOpts|nil
---@return ChezmoiCommandResult
function M.run(argv, stdin, opts)
    opts = opts or {}
    local sys = vim.system(argv, system_opts(stdin, opts.cwd))

    local ok, out = pcall(sys.wait, sys, opts.timeout or M.TIMEOUT_MS)
    if not ok then
        sys:kill("sigterm")
        return {
            args = argv,
            success = false,
            data = { "Timed out waiting for: " .. table.concat(argv, " ") },
        }
    end

    return shape(argv, out)
end

--- Run `argv` without blocking. `callback` runs on the main loop.
---@param argv string[] Full argv, e.g. `{ "chezmoi", "managed", ... }`.
---@param stdin string|string[]|nil Lines (or blob) fed to stdin.
---@param opts NvimChezmoi.Core.JobRunOpts|nil
---@param callback? fun(result: ChezmoiCommandResult) Exit callback (main loop).
---@return vim.SystemObj Process handle.
function M.run_async(argv, stdin, opts, callback)
    opts = opts or {}
    return vim.system(argv, system_opts(stdin, opts.cwd), function(out)
        if type(callback) ~= "function" then
            return
        end
        local result = shape(argv, out)
        vim.schedule(function() callback(result) end)
    end)
end

return M
