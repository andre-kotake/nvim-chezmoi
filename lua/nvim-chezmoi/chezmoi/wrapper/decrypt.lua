local base = require("nvim-chezmoi.chezmoi.wrapper._base")
local chezmoi = require("nvim-chezmoi.chezmoi")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")

---@class ChezmoiDecrypt: ChezmoiCommandWrapper
local M = setmetatable({}, {
  __index = base,

  ---@return ChezmoiCommandResult
  __call = function(self, file)
    return self:exec(file)
  end,
})

function M:create_autocmds(bufnr)
  base.create_autocmds({
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
  })
end

---@param file string
---@return ChezmoiCommandResult
function M:exec(file)
  local decrypted_result = vim.fn.systemlist("chezmoi decrypt " .. file)
  local code = vim.v.shell_error
  local bufnr = -1
  if code ~= 0 then
    log.error(decrypted_result)
  else
    bufnr = chezmoi_helper.create_buf(
      chezmoi_helper.get_decrypted_path(file),
      decrypted_result,
      true,
      false,
      true
    )
    vim.bo[bufnr].modified = false
    self:create_autocmds(bufnr)
  end

  return {
    success = bufnr ~= -1,
    data = bufnr,
  }
end

return M
