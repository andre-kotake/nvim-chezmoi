local command = require("nvim-chezmoi.chezmoi.command")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")

---@class ChezmoiDecrypt: ChezmoiCommand
local M = setmetatable({
  cmd = "decrypt",
}, {
  __index = command,
})

function M:autoCommands(bufnr)
  return {
    {
      event = "BufWritePre",
      opts = {
        group = "Decrypt",
        buffer = bufnr,
        callback = function(ev)
          -- Encrypt lines and save to original encripted file.
          local decrypted_lines =
            vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
          local encrypted_lines =
            vim.fn.systemlist("chezmoi encrypt", decrypted_lines)
          local code = vim.v.shell_error
          if code == 0 then
            local source_path = chezmoi_helper.get_encrypted_path(ev.file)
            vim.fn.writefile(encrypted_lines, source_path)
            log.info("Saved to: " .. source_path)
          end
        end,
      },
    },
    {
      event = { "BufDelete", "BufUnload", "VimLeave", "ExitPre" },
      opts = {
        group = "DeleteDecryptedFile",
        buffer = bufnr,
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
  if not result.success then
    return result
  end

  local bufnr = chezmoi_helper.create_buf(
    chezmoi_helper.get_decrypted_path(file),
    result.data,
    true,
    false,
    true
  )
  vim.bo[bufnr].modified = false
  self:create_autocmds(bufnr)

  return {
    success = bufnr ~= -1,
    data = { bufnr },
  }
end

return M
