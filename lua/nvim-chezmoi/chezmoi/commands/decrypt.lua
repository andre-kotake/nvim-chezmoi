local command = require("nvim-chezmoi.chezmoi.command")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")

---@class ChezmoiDecrypt: ChezmoiCommand
local M = setmetatable({
  cmd = "decrypt",
}, {
  __index = command,
})

function M:autoCommands(args)
  return {
    {
      event = "BufWritePre",
      opts = {
        group = "Decrypt",
        buffer = args.bufnr,
        callback = function(ev)
          -- Encrypt lines and save to original encripted file.
          local decrypted_lines =
            vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)

          local cmd = require("nvim-chezmoi.chezmoi.commands.encrypt")
          local result = cmd:exec(decrypted_lines)

          if result.success then
            local source_path = args.file
            vim.fn.writefile(result.data, source_path)
            log.info("Saved to: " .. source_path)

            vim.bo[ev.buf].modified = false
          end
        end,
      },
    },
    {
      event = { "BufDelete", "BufUnload", "VimLeave", "ExitPre" },
      opts = {
        group = "DeleteDecryptedFile",
        buffer = args.bufnr,
        callback = function(ev)
          vim.fn.delete(ev.file)
        end,
      },
    },
  }
end

---@param file string
---@return ChezmoiCommandResult
function M:exec(file)
  local result = command.exec(self, { file })
  vim.cmd([[redraw!]])

  if not result.success then
    return result
  end

  local bufnr =
    chezmoi_helper.create_buf(vim.fn.tempname(), result.data, true, false, true)

  self:create_autocmds({ bufnr = bufnr, file = file })
  vim.api.nvim_buf_set_var(bufnr, "encrypted_source_path", file)
  vim.bo[bufnr].modified = false

  return {
    args = result.args,
    success = bufnr ~= -1,
    data = { bufnr },
  }

  -- local result =
  --   vim.fn.systemlist("gpg --batch --yes --quiet --decrypt " .. file)
  --
  -- -- Print the result of the command (e.g., error messages or success)
  -- if vim.v.shell_error == 0 then
  --   local bufnr =
  --     chezmoi_helper.create_buf(vim.fn.tempname(), result, true, false, true)
  --
  --   self:create_autocmds({ bufnr = bufnr, file = file })
  --   vim.api.nvim_buf_set_var(bufnr, "encrypted_source_path", file)
  --   vim.bo[bufnr].modified = false
  --   vim.cmd([[redraw!]])
  --
  --   return {
  --     success = bufnr ~= -1,
  --     data = { bufnr },
  --   }
  -- else
  --   log.error(result)
  --   vim.cmd([[redraw!]])
  --   return {
  --     success = false,
  --     data = result,
  --   }
  -- end
end

return M
