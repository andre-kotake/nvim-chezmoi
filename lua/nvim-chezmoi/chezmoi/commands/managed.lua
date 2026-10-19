local command = require("nvim-chezmoi.chezmoi.command")
local managed_file = require("nvim-chezmoi.chezmoi.managed_file")

---@class ChezmoiManaged:ChezmoiCommand
local M = setmetatable({
    cmd = "managed",
    args = {
        "--path-style",
        "all",
        "--format",
        "yaml",
        "--exclude",
        "dirs,externals,scripts",
    },
}, {
    __index = command,
})

function M:userCommands()
    return {
        {
            name = "ChezmoiManaged",
            desc = "Lists managed files.",
            callback = function(_)
                require("nvim-chezmoi.core.picker").pick_managed()
            end,
            opts = {
                nargs = "*",
            },
        },
    }
end

---@param result ChezmoiCommandResult
---@return ChezmoiCommandResult
local function parse(result)
    if not result.success or #result.data == 0 or result.data[1] == "{}" then
        return { args = result.args, success = false, data = {} }
    end

    local managed_files = {}
    local data = result.data

    for i = 1, #data, 4 do
        -- Remove the trailing ':' from the first string
        local relative = data[i]:gsub(":", "")
        -- Extract the paths from the other strings, stripping out the labels
        local absolute = data[i + 1]:match("absolute:%s*(.-)$")
        local source_absolute = data[i + 2]:match("sourceAbsolute:%s*(.-)$")
        local source_relative = data[i + 3]:match("sourceRelative:%s*(.-)$")

        managed_files[source_absolute] = managed_file:new({
            relative = relative,
            absolute = absolute,
            sourceAbsolute = source_absolute,
            sourceRelative = source_relative,
        })
    end

    return { args = result.args, success = true, data = managed_files }
end

---@param args? string[]
---@return ChezmoiCommandResult
function M:exec(args) return parse(command.exec(self, args)) end

---@param args? string[]
---@param callback? fun(result: ChezmoiCommandResult)
---@return vim.SystemObj Process handle.
function M:async(args, callback)
    return command.async(self, args, function(raw)
        if type(callback) == "function" then
            callback(parse(raw))
        end
    end)
end

return M
