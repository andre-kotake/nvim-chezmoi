local command = require("nvim-chezmoi.chezmoi.command")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")
local utils = require("nvim-chezmoi.core.utils")

---@class ChezmoiDiff:ChezmoiCommand
local M = setmetatable({
    cmd = "diff",
}, {
    __index = command,
})

---Managed files keyed by both `sourceAbsolute` and `absolute`.
---@type table<string, ChezmoiManagedFile>
local managed_by_path = {}

---@param source string
---@param target string
local function open_diff(source, target)
    if chezmoi_helper.is_encrypted(source) then
        log.warn("'" .. target .. "' is encrypted; skipping diff")
        return
    end

    require("nvim-chezmoi.chezmoi.commands.cat"):async(
        { target },
        function(result)
            if not result.success then
                log.warn(
                    "could not render '"
                        .. target
                        .. "': "
                        .. table.concat(result.data, "\n")
                )
                return
            end

            local cat_buf = vim.api.nvim_create_buf(false, true)

            vim.api.nvim_buf_set_lines(cat_buf, 0, -1, false, result.data)
            vim.bo[cat_buf].buftype = "nofile"
            vim.bo[cat_buf].bufhidden = "wipe"
            vim.bo[cat_buf].modifiable = false
            vim.bo[cat_buf].filetype = vim.filetype.match({ filename = target })
                or ""

            local target_win = vim.api.nvim_get_current_win()
            local cat_win = vim.api.nvim_open_win(cat_buf, false, {
                win = target_win,
                split = "right",
            })

            vim.api.nvim_win_call(target_win, function()
                vim.cmd.edit(vim.fn.fnameescape(target))
                vim.cmd.diffthis()
            end)

            vim.api.nvim_win_call(cat_win, vim.cmd.diffthis)
        end
    )
end

---@return ChezmoiUserCommand[]
function M:userCommands()
    return {
        {
            name = "ChezmoiDiff",
            desc = "Performs a diff of the source and target",
            callback = function(cmd)
                local file = #cmd.fargs > 0 and cmd.fargs[1]
                    or vim.api.nvim_buf_get_name(0)
                if file == "" then
                    log.warn("no file to diff")
                    return
                end
                file = utils.fullpath(file)

                local source_path = require("nvim-chezmoi").opts.source_path
                if source_path == nil then
                    log.warn("chezmoi source path not ready")
                    return
                end

                if utils.is_child_of(source_path, file) then
                    require("nvim-chezmoi.chezmoi.commands.target_path"):async(
                        { file },
                        function(result)
                            if not result.success then
                                log.warn(
                                    "could not resolve target for '"
                                        .. file
                                        .. "'"
                                )
                                return
                            end
                            open_diff(file, result.data[1])
                        end
                    )
                    return
                end

                local managed_entry = managed_by_path[file]
                if managed_entry then
                    local abs_src, abs_tgt
                    if file == managed_entry.sourceAbsolute then
                        abs_src, abs_tgt = file, managed_entry.absolute
                    else
                        abs_src, abs_tgt = managed_entry.sourceAbsolute, file
                    end

                    open_diff(abs_src, abs_tgt)
                    return
                else
                    require("nvim-chezmoi.chezmoi.commands.source_path"):async(
                        { file },
                        function(result)
                            if not result.success then
                                log.warn("'" .. file .. "' is not managed")
                                return
                            end
                            open_diff(result.data[1], file)
                        end
                    )
                end
            end,
            opts = {
                nargs = "*",
            },
        },
    }
end

return M
