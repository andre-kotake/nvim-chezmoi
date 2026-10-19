---@class NvimChezmoiPicker
---@field source_path string
local M = {}

M.init = function(source_path)
    if not _G.Snacks then
        vim.notify(
            "nvim-chezmoi: snacks.nvim is required for picker support",
            vim.log.levels.ERROR
        )
        return
    end
    M.source_path = source_path

    local chezmoi_managed = require("nvim-chezmoi.chezmoi.commands.managed")
    chezmoi_managed:create_user_commands()

    vim.api.nvim_create_user_command(
        "ChezmoiFiles",
        function() M.pick_special_files() end,
        { desc = "Chezmoi special files under source path", nargs = 0 }
    )
end

--- Custom preview: chezmoi diff output for regular files, plain file view for encrypted.
---@param ctx snacks.picker.preview.ctx
local function chezmoi_diff_preview(ctx)
    if ctx.item.isEncrypted then
        return Snacks.picker.preview.file(ctx)
    end
    return Snacks.picker.preview.cmd(
        { "chezmoi", "diff", ctx.item.target_file },
        ctx,
        { ft = "diff" }
    )
end

local NOTIF_ID = "nvim-chezmoi.managed"

M.pick_managed = function()
    Snacks.notifier("Loading managed files…", vim.log.levels.INFO, {
        id = NOTIF_ID,
        title = "Chezmoi",
        timeout = false,
        opts = function(n) n.icon = Snacks.util.spinner() end,
    })

    require("nvim-chezmoi.chezmoi.commands.managed"):async({}, function(files)
        Snacks.notifier.hide(NOTIF_ID)

        local items = {}
        if files.success then
            for _, v in pairs(files.data) do
                items[#items + 1] = {
                    text = v.relative,
                    file = v.absolute,
                    source_file = v.sourceAbsolute,
                    isEncrypted = v:isEncrypted(),
                }
            end
        end

        Snacks.picker({
            title = "Managed Files",
            items = items,
            format = "file",
            -- preview = chezmoi_diff_preview,   -- intentionally disabled (too slow)
            confirm = function(picker, item)
                picker:close()
                if not item then
                    return
                end
                if item.isEncrypted then
                    require("nvim-chezmoi.chezmoi.commands.edit"):exec(
                        item.file
                    )
                else
                    vim.cmd.edit(item.source_file)
                end
            end,
        })
    end)
end

M.pick_special_files = function()
    if type(M.source_path) ~= "string" then
        local result =
            require("nvim-chezmoi.chezmoi.commands.source_path"):exec()
        M.source_path = result.data[1]
    end
    local source_path = M.source_path
    local prefix = source_path:sub(-1) == "/" and source_path
        or source_path .. "/"
    local found = vim.fs.find(
        function(name) return name:match("^%.chezmoi") end,
        { path = source_path, limit = math.huge, type = "file" }
    )
    local items = {}
    for _, f in ipairs(found) do
        local rel = f:sub(#prefix + 1)
        items[#items + 1] = { text = rel, file = f }
    end
    Snacks.picker({
        title = "Chezmoi Special Files",
        items = items,
        format = "file",
        preview = "file",
    })
end

return M
