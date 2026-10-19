local command = require("nvim-chezmoi.chezmoi.command")
local chezmoi_cache = require("nvim-chezmoi.chezmoi.cache")
local chezmoi_decrypt = require("nvim-chezmoi.chezmoi.commands.decrypt")
local chezmoi_execute_template =
    require("nvim-chezmoi.chezmoi.commands.execute_template")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")
local async = require("nvim-chezmoi.core.async")

-- Noticed different behavior with different sets of template file types, so it's worth having one global toggle while we figure this out
local all_template_types = {
    "gotmpl",
    "template",
    "tmpl",
    "tpl",
}

local TEMPLATE_TYPE = "gotmpl"
local SCM_FILE_NAME = "gotmpl_injection.scm"

---Cached contents of scm (lazy-loaded, module-local).
local template_injection_scm = nil

---@class ChezmoiEdit: ChezmoiCommand
local M = setmetatable({
    cmd = "edit",
}, {
    __index = command,
})

function M:init(opts)
    self.opts = opts
    self:create_user_commands()
end

function M:on_edit(bufnr)
    chezmoi_execute_template:create_buf_user_commands(bufnr)

    self:create_buf_user_commands(bufnr)
    self:detect_filetype(bufnr)
    if
        type(self.opts.edit.apply_on_save) ~= nil
        and self.opts.edit.apply_on_save ~= "never"
    then
        self:create_autocmds(bufnr)
    end
end

---@return ChezmoiAutoCommand[]
function M:autoCommands(bufnr)
    return {
        {
            event = "BufWritePost",
            opts = {
                group = "ApplyOnSave",
                buffer = bufnr,
                callback = function(ev)
                    local apply = function()
                        local result = require(
                            "nvim-chezmoi.chezmoi.commands.target_path"
                        ):exec({
                            ev.file,
                        })
                        if
                            result.success
                            and require("nvim-chezmoi.chezmoi.commands.apply"):exec({
                                result.data[1],
                            }).success
                        then
                            log.info("Applied " .. result.data[1])
                        end
                    end

                    if self.opts.edit.apply_on_save == "confirm" then
                        local choice = vim.ui.select({ "Yes", "No" }, {
                            prompt = "Apply " .. ev.file .. "?",
                        }, function(_, choice_idx)
                            if choice_idx == 1 then
                                apply()
                            end
                        end)
                    elseif self.opts.edit.apply_on_save == "auto" then
                        apply()
                    end
                end,
            },
        },
    }
end

---@param bufnr integer
---@return ChezmoiUserCommand[]
function M:bufUserCommands(bufnr)
    return {
        {
            name = "ChezmoiDetectFiletype",
            desc = "Detects filetype for a source file based on the target file name.",
            callback = function() self:detect_filetype(bufnr) end,
        },
    }
end

---@return ChezmoiUserCommand[]
function M:userCommands()
    return {
        {
            name = "ChezmoiEdit",
            desc = "Edit a chezmoi file.",
            callback = function(cmd)
                local file
                if #cmd.fargs > 0 then
                    file = cmd.fargs[1]
                else
                    file = vim.api.nvim_buf_get_name(0)
                end
                M:exec(file)
            end,
            opts = {
                nargs = "?",
            },
        },
    }
end

---Opens the specified `file` in new buffer.
---@param file string
---@return ChezmoiCommandResult|nil
function M:exec(file)
    file = vim.fs.normalize(file)
    local result =
        require("nvim-chezmoi.chezmoi.commands.source_path"):exec({ file })
    if not result.success then
        return result
    end

    file = result.data[1]

    if chezmoi_helper.is_encrypted(file) then
        vim.schedule(function()
            local decrypt_result = chezmoi_decrypt:exec(file)
            if decrypt_result.success then
                local bufnr = decrypt_result.data[1]
                if bufnr ~= -1 then
                    self:on_edit(bufnr)
                    log.warn("Consider using `chezmoi edit` instead.")
                end
            end
        end)
    else
        vim.cmd.edit(file)
    end
end

---Opens the specified `file` in a new buffer asynchronously.
---Identical to `exec` but replaces the blocking `source_path:exec` call
---with `source_path:async`, so the caller is not blocked.
---@param file string
---@param callback? fun(result: ChezmoiCommandResult)
---@return vim.SystemObj Process handle.
function M:async(file, callback)
    file = vim.fs.normalize(file)
    local job = require("nvim-chezmoi.chezmoi.commands.source_path"):async(
        { file },
        function(result)
            if not result.success then
                if type(callback) == "function" then
                    callback(result)
                end
                return
            end

            file = result.data[1]

            if chezmoi_helper.is_encrypted(file) then
                local decrypt_result = chezmoi_decrypt:exec(file)
                if decrypt_result.success then
                    local bufnr = decrypt_result.data[1]
                    if bufnr ~= -1 then
                        self:on_edit(bufnr)
                        log.warn("Consider using `chezmoi edit` instead.")
                    end
                end
                if type(callback) == "function" then
                    callback(decrypt_result)
                end
            else
                vim.cmd.tabedit(file)
                if type(callback) == "function" then
                    callback({ args = {}, success = true, data = {} })
                end
            end
        end
    )

    return job
end

---Reads scm once and caches it.
---@return string?
local function get_template_injection_scm()
    if template_injection_scm then
        return template_injection_scm
    end

    local path = vim.api.nvim_get_runtime_file(SCM_FILE_NAME, false)[1]
    if not path then
        log.warn(
            SCM_FILE_NAME
                .. " not found on runtimepath, treesitter attach skipped for buffer"
        )
        return nil
    end

    template_injection_scm = table.concat(vim.fn.readfile(path), "\n")
    return template_injection_scm
end

local function is_file_template(ft, filename)
    if filename and filename ~= "" and filename:match("%.tmpl$") then
        return true
    end

    if ft == "" then
        return false
    end

    for _, template_ft in ipairs(all_template_types) do
        if template_ft == ft then
            return true
        end
    end

    return false
end

---@param buf integer
---@param target_ft string
function M:attach_template_ts(buf, target_ft)
    if not vim.api.nvim_buf_is_valid(buf) then
        log.debug(
            TEMPLATE_TYPE
                .. " treesitter attach skipped: buffer "
                .. tostring(buf)
                .. " is no longer valid"
        )
        return
    end

    if not target_ft or target_ft == "" then
        log.debug(
            TEMPLATE_TYPE
                .. " treesitter attach skipped for buffer "
                .. buf
                .. ": no distinct target filetype to inject (target_ft="
                .. tostring(target_ft)
                .. ")"
        )
        return
    end

    local combined_ft = string.format("%s.%s", target_ft, TEMPLATE_TYPE)

    if not vim.treesitter.language.add(TEMPLATE_TYPE) then
        log.warn(
            TEMPLATE_TYPE
                .. " treesitter parser is not installed; cannot attach dual '"
                .. combined_ft
                .. "' highlighting for buffer "
                .. buf
        )
        return
    end

    if not pcall(vim.treesitter.language.add, target_ft) then
        log.debug(
            "no treesitter parser installed for target filetype '"
                .. target_ft
                .. "'; attaching template-only highlighting for buffer "
                .. buf
        )

        vim.treesitter.start(buf, TEMPLATE_TYPE)
        return
    end

    local template_scm = get_template_injection_scm()
    if not template_scm then
        return
    end
    local injections = string.format(template_scm, target_ft)

    local ok, parser, err =
        pcall(vim.treesitter.get_parser, buf, TEMPLATE_TYPE, {
            injections = { [TEMPLATE_TYPE] = injections },
        })

    if not ok or not parser then
        log.warn(
            "failed to create combined '"
                .. combined_ft
                .. "' parser for buffer "
                .. buf
                .. ": "
                .. tostring(err)
        )
        return
    end

    vim.treesitter.highlighter.new(parser)

    log.debug(
        TEMPLATE_TYPE
            .. "treesitter parser attached to buffer "
            .. buf
            .. " with '"
            .. target_ft
            .. "' injected (combined) into (text) regions"
    )
end

local function get_computed_filetype(file)
    -- First, just check the file name
    local ft = vim.filetype.match({ filename = file })
    local hasnoft = function() return (not ft or ft == "") end -- says: "We still have no ft, we must keep checking"

    -- Could't find the filetype, try harder. Check if a buffer already has the
    -- file.
    -- This path is highly likely if the user used the plugin's ChezmoiEdit command to
    -- invoke open the currently open source file.
    if hasnoft() then
        log.debug(
            "filename-based match on path '"
                .. file
                .. "' found nothing; probing loaded buffers for a match"
        )

        local existing = -1
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_get_name(b) == file then
                existing = b
                break
            end
        end

        if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
            log.debug(
                "found existing buffer "
                    .. existing
                    .. " for path '"
                    .. file
                    .. "'; matching filetype from its contents"
            )

            ft = vim.filetype.match({ buf = existing }) or ""
        end
    end

    -- The file type is still not determined, need to try more
    if hasnoft() then
        log.debug(
            "no existing buffer for path '"
                .. file
                .. "'; detecting type from contents"
        )

        local contents = {}
        local h = io.open(file, "r")
        if h then
            for _ = 1, 2 do
                local l = h:read("*l")
                if not l then
                    break
                end
                contents[#contents + 1] = l
            end
            h:close()
        end

        ft = vim.filetype.match({ filename = file, contents = contents }) or ""
    end

    if hasnoft() then
        log.debug(
            "checking file contents alone did not work '"
                .. file
                .. "'; detecting by loading the file in as a buffer"
        )

        local tmp_buf = vim.api.nvim_create_buf(true, true)

        vim.api.nvim_buf_set_name(tmp_buf, file)
        ft = vim.filetype.match({ buf = tmp_buf }) or ""
        vim.api.nvim_buf_delete(tmp_buf, { force = true })
    end

    return ft
end

---Detects and sets filetype for `buf` using various heuristics
---@param buf integer
function M:detect_filetype(buf)
    local source_file = vim.api.nvim_buf_get_name(buf)

    log.debug(
        "detect_filetype: starting detection for buffer "
            .. buf
            .. " (source file '"
            .. source_file
            .. "')"
    )

    local is_tmpl = is_file_template(vim.bo[buf].filetype)

    local set_file_type = vim.schedule_wrap(function(ft)
        if is_tmpl then
            local compound_ft = (ft and ft ~= "" and ft .. "." or "")
                .. TEMPLATE_TYPE
            log.debug(
                "setting filetype of buffer "
                    .. buf
                    .. " to '"
                    .. compound_ft
                    .. "' (was '"
                    .. vim.bo[buf].filetype
                    .. "')"
            )

            if vim.bo[buf].filetype ~= compound_ft then
                vim.bo[buf].filetype = compound_ft
            end

            self:attach_template_ts(buf, ft)

            return
        end

        if vim.bo[buf].filetype ~= ft then
            log.debug(
                "setting filetype of buffer "
                    .. buf
                    .. " to '"
                    .. ft
                    .. "' (was '"
                    .. vim.bo[buf].filetype
                    .. "')"
            )

            vim.bo[buf].filetype = ft
        end
    end)

    -- if not a template but has a non-empty file type
    if not (is_tmpl or (vim.bo[buf].filetype or "") == "") then
        log.debug(
            "Non-template source file '"
                .. vim.fs.basename(source_file)
                .. "' already has a filetype '"
                .. vim.bo[buf].filetype
                .. "'; using it directly"
        )

        return
    end

    local ok, s = pcall(vim.api.nvim_buf_get_var, buf, "encrypted_source_path")
    if ok then
        log.debug(
            "buffer "
                .. buf
                .. " is a decrypted scratch buffer; using its"
                .. " encrypted_source_path '"
                .. s
                .. "' for filetype detection instead of '"
                .. source_file
                .. "'"
        )
        source_file = s
    end

    -- Try cache first
    local cached = chezmoi_cache.find_success("ft_detect", { source_file })

    -- if cache exists, get the ft
    local ft = cached and cached.result.data.ft
        or log.debug(
            "no ft_detect cache entry for '"
                .. source_file
                .. "'; resolving target path to derive filetype",
            false
        )

    if ft then
        log.debug(
            "ft_detect cache hit for '"
                .. source_file
                .. "': filetype '"
                .. tostring(ft)
                .. "'"
        )
        set_file_type(ft)
        return
    end

    -- Get target path for source file, then derive the filetype from it.
    local target_path = require("nvim-chezmoi.chezmoi.commands.target_path")

    async.run(function()
        local target_file_result = async.await(
            function(cb) target_path:async({ source_file }, cb) end
        )

        if not target_file_result.success then
            log.warn(
                "could not resolve target path for source file '"
                    .. source_file
                    .. "'; skipping filetype detection"
            )

            return
        end

        local target_file = target_file_result.data[1]

        log.debug(
            "resolved target path '"
                .. target_file
                .. "' for source file '"
                .. source_file
                .. "'"
        )

        local tgt_ft = get_computed_filetype(target_file)
        if not tgt_ft or tgt_ft == "" then
            log.warn(
                "could not determine filetype for target file '"
                    .. target_file
                    .. "' (source file '"
                    .. source_file
                    .. "')"
            )
            return
        end

        if
            not (
                vim.api.nvim_buf_is_valid(buf)
                and vim.api.nvim_buf_get_name(buf) == source_file
            )
        then
            log.debug(
                "target-path based detection resolved filetype '"
                    .. tgt_ft
                    .. "' for '"
                    .. source_file
                    .. "', but buffer "
                    .. buf
                    .. " no longer matches (renamed/closed); not reassigning"
            )
            return
        end

        log.debug(
            "target-path based detection resolved filetype '"
                .. tgt_ft
                .. "' for source file '"
                .. source_file
                .. "'"
        )

        set_file_type(tgt_ft)

        vim.filetype.add({
            filename = {
                [vim.fs.basename(source_file)] = tgt_ft,
            },
        })

        -- Cache it
        chezmoi_cache.new("ft_detect", { source_file }, {
            args = {},
            success = true,
            data = { ft = tgt_ft },
        })

        log.debug(
            "stored ft_detect result '"
                .. tgt_ft
                .. "' for source file '"
                .. source_file
                .. "' to cache"
        )
    end)
end

return M
