local log = require("nvim-chezmoi.core.log")

---Auxiliary class to handle chezmoi file names
local M = {}

M.is_encrypted = function(file)
    return string.find(vim.fs.basename(file), "^encrypted_") ~= nil
end

local function removePrefixes(prefixes, name)
    for _, prefix in ipairs(prefixes) do
        if name:sub(1, #prefix) == prefix then
            if prefix == "dot_" then
                name = name:gsub(prefix, ".")
            else
                name = name:sub(#prefix + 1) -- Remove the prefix
            end

            if prefix == "literal_" then
                break
            end
        end
    end

    return name
end

M.removeFilePrefixes = function(filename)
    filename = removePrefixes({
        "literal_",
        "create_",
        "modify_",
        "remove_",
        "symlink_",
        "run_",
        "once_",
        "onchange_",
        "before_",
        "after_",
        "encrypted_",
        "private_",
        "readonly_",
        "empty_",
        "executable_",
        "dot_",
    }, filename)

    if filename:sub(-5) == ".tmpl" then
        filename = filename:sub(1, -6)
    end

    return filename
end

M.removeDirectoryPrefixes = function(dir)
    return removePrefixes({
        "remove_",
        "external_",
        "exact_",
        "private_",
        "readonly_",
        "dot_",
    }, dir)
end

M.resolvePath = function(file)
    -- Remove suffixes from each folder in the path
    local pathWithoutSuffixes = vim.fs.dirname(file)
    if pathWithoutSuffixes == "." then
        pathWithoutSuffixes = ""
    else
        local path_tmp = ""
        for part in pathWithoutSuffixes:gmatch("[^/]+") do
            path_tmp = path_tmp .. M.removeDirectoryPrefixes(part) .. "/"
        end
        pathWithoutSuffixes = path_tmp
    end

    -- Remove the file suffix
    local filenameWithoutSuffix = M.removeFilePrefixes(vim.fs.basename(file)) -- Remove file suffix

    -- Combine the processed path and filename
    local processedFile = pathWithoutSuffixes .. filenameWithoutSuffix
    return processedFile
end

M.expand_path_arg = function(args)
    if args == nil then
        return nil
    end

    if #args > 0 then
        if args[1] ~= nil and string.sub(args[1], 1, 2) ~= "--" then
            -- The first item is a path (`expand` keeps `~`/env/`%` working)
            args[1] = require("nvim-chezmoi.core.utils").fullpath(
                vim.fs.normalize(args[1])
            )
        end
    end

    return args
end

--- Find a buffer by name (compared as full paths), or -1.
---@param name string Buffer name to look for.
---@return integer Buffer handle, or -1 when no buffer matches.
local function find_buf_by_name(name)
    local want = vim.fs.normalize(vim.fs.abspath(name))
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local existing = vim.api.nvim_buf_get_name(b)
        if existing ~= "" and vim.fs.normalize(existing) == want then
            return b
        end
    end
    return -1
end

---Creates a new buffer
---@param name string
---@param contents string[]|nil
---@param listed boolean|nil
---@param scratch boolean|nil
---@param focus boolean|nil
---@return integer bufnr
M.create_buf = function(name, contents, listed, scratch, focus)
    local bufnr = find_buf_by_name(name)

    if bufnr == -1 then
        bufnr = vim.api.nvim_create_buf(listed or true, scratch or false)

        if not scratch then
            vim.api.nvim_buf_set_name(bufnr, name)
        end

        if contents ~= nil and type(contents) == "table" then
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
        end
    else -- Buffer already exists, open that instead
        vim.api.nvim_command("buffer " .. bufnr)
    end

    if focus or true then
        vim.api.nvim_set_current_buf(bufnr)
    end

    if bufnr == -1 then
        log.error("Could not create buffer: " .. name)
    end

    return bufnr
end

return M
