local base = require("nvim-chezmoi.chezmoi.wrapper._base")
local chezmoi = require("nvim-chezmoi.chezmoi")

---@class ChezmoiApply: ChezmoiCommandWrapper
local M = setmetatable({}, {
  __index = base,
  __call = function(self)
    self:exec()
  end,
})

function M:create_user_commands()
  base.create_user_commands({
    {
      name = "ChezmoiApply",
      desc = "Applies current chezmoi file. Accepts optional files arguments.",
      callback = function(cmd)
        local files = {}
        if #cmd.args > 0 then
          files = cmd.fargs
        else
          files = { vim.fn.expand("%:p") }
        end
        M:exec(files)
      end,
      opts = {
        nargs = "*",
      },
    },
  })
end

---@param files? string[]
---@return ChezmoiCommandResult
function M:exec(files)
  local args = { "--force" }
  if type(files) == "table" then
    for _, file in ipairs(files) do
      table.insert(args, file)
    end
  end

  return chezmoi.run("apply", {
    force = true,
    args = args,
  })
end

return M
