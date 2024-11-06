local base = require("nvim-chezmoi.chezmoi.wrapper._base")
local chezmoi = require("nvim-chezmoi.chezmoi")
local chezmoi_cache = require("nvim-chezmoi.chezmoi.cache")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")
local plenary = require("nvim-chezmoi.core.plenary_runner")
local utils = require("nvim-chezmoi.core.utils")

local _decrypted_sufix = "_decripted"

---Detects amd sets filetype for `buf` using the target path.
---@param buf integer
local detect_filetype = function(buf)
  local set_filetype = vim.schedule_wrap(function(ft)
    if vim.bo[buf].filetype ~= ft then
      vim.bo[buf].filetype = ft
    end
  end)

  local file = vim.api.nvim_buf_get_name(buf)
  local source_file = vim.fn.fnamemodify(file, ":p")

  -- remove decrypted sufix
  if
    string.match(vim.fn.fnamemodify(source_file, ":t"), _decrypted_sufix .. "$")
  then
    source_file = string.gsub(source_file, _decrypted_sufix .. "$", "")
  end

  -- Try cache first
  local cached = chezmoi_cache.find_success("ft_detect", { source_file })
  if cached ~= nil then
    local ft = cached.result.data.ft
    if ft ~= vim.bo[buf].filetype then
      set_filetype(ft)
      return
    end
  end

  -- Get target path for source file
  local target_file_result = chezmoi.target_path({ source_file })
  if not target_file_result.success then
    return
  end

  local target_file = target_file_result.data[1]
  -- Try match
  local ft = plenary.get_filetype(target_file)

  if ft == nil or ft == "" then
    vim.schedule(function()
      ft = vim.filetype.match({ filename = target_file })

      -- Could't find the filetype, try temp buf
      if ft ~= nil and ft ~= "" then
        local tmp_buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(tmp_buf, target_file)
        ft = vim.filetype.match({ buf = tmp_buf })
        vim.api.nvim_buf_delete(tmp_buf, { force = true })
      end
    end)
  end

  if ft ~= nil and ft ~= "" then
    set_filetype(ft)

    vim.filetype.add({
      filename = {
        [target_file] = ft,
      },
    })

    -- Cache it
    chezmoi_cache.new("ft_detect", { source_file }, {
      success = true,
      data = { ft = ft },
    })
  end
end

local function edit_encrypted(self, file)
  local decrypted_file = vim.fn.system("chezmoi decrypt " .. file)

  -- Creatr temp buf for editing the decrypted file
  local bufnr = chezmoi_helper.create_buf(
    file .. _decrypted_sufix,
    vim.split(decrypted_file, "\n"),
    true,
    false,
    true
  )

  if bufnr ~= nil then
    -- Should write the encrypted data back to original file
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = utils.augroup("DecryptedFileSave"),
      buffer = bufnr,
      callback = function(ev)
        -- Handling it via vim.fn.system is better for password
        -- encrypted_lines = self:check_result(
        --   chezmoi.encrypt,
        --   table.concat(decrypted_lines, "\n"),
        --   function(result)
        --     vim.print(vim.inspect(result))
        --   end
        -- )

        local decrypted_lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)
        local encrypted_lines =
          vim.fn.systemlist("chezmoi encrypt", decrypted_lines)
        local code = vim.v.shell_error

        if code == 0 then
          local source_path = ev.file:gsub(_decrypted_sufix .. "$", "")
          vim.fn.writefile(encrypted_lines, source_path)
          log.info("Saved to: " .. source_path)
        end
      end,
    })

    -- Remove temp buf
    vim.api.nvim_create_autocmd("BufDelete", {
      group = utils.augroup("DeleteDecryptedFile"),
      buffer = bufnr,
      callback = function(ev)
        vim.fn.delete(ev.file)
      end,
    })
    -- Create the user commands because AutoCmd is not triggering here.
    self:create_buf_user_commands(bufnr)
  end

  log.warn("Consider using `chezmoi edit` instead.")
end

---@class ChezmoiEdit: ChezmoiCommandWrapper
local M = setmetatable({}, {
  __index = base,
  __call = function(self, file)
    self:exec(file)
  end,
})

function M:create_buf_user_commands(bufnr)
  local commands = {
    {
      name = "ChezmoiDetectFiletype",
      desc = "Detects filetype for a source file based on the target file name.",
      callback = function()
        detect_filetype(bufnr)
      end,
    },
  }

  base.create_buf_user_commands(self, bufnr, commands)
  detect_filetype(bufnr)
end

function M:create_user_commands()
  local commands = {
    {
      name = "ChezmoiEdit",
      desc = "Edit a chezmoi file.",
      callback = function(cmd)
        local file
        if #cmd.fargs > 0 then
          file = cmd.fargs[1]
        else
          file = vim.fn.expand("%:p")
        end
        M:exec(file)
      end,
      opts = {
        nargs = "?",
      },
    },
  }
  base.create_user_commands(self, commands)
end

---Opens the specified `files` in new buffers.
---@param file string
---@return ChezmoiCommandResult|nil
function M:exec(file)
  return self:check_result(chezmoi.edit, { file }, function(result)
    file = result.data[1]

    if not chezmoi_helper.is_encrypted(file) then
      -- Regular file, just open it.
      vim.cmd.edit(file)
    else
      vim.schedule(function()
        edit_encrypted(file)
      end)
    end
  end)
end

return M
