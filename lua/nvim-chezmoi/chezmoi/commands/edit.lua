local command = require("nvim-chezmoi.chezmoi.command")
local chezmoi_cache = require("nvim-chezmoi.chezmoi.cache")
local chezmoi_decrypt = require("nvim-chezmoi.chezmoi.commands.decrypt")
local chezmoi_execute_template =
  require("nvim-chezmoi.chezmoi.commands.execute_template")
local chezmoi_helper = require("nvim-chezmoi.chezmoi.helper")
local log = require("nvim-chezmoi.core.log")
local plenary_filetype = require("plenary.filetype")

---@class ChezmoiEdit: ChezmoiCommand
local M = setmetatable({
  cmd = "edit",
}, {
  __index = command,
})

---@param bufnr integer
---@return ChezmoiUserCommand[]
function M:bufUserCommands(bufnr)
  local commands = {
    {
      name = "ChezmoiDetectFiletype",
      desc = "Detects filetype for a source file based on the target file name.",
      callback = function()
        self:detect_filetype(bufnr)
      end,
    },
  }

  vim.tbl_deep_extend(
    "force",
    commands,
    chezmoi_execute_template:bufUserCommands(bufnr)
  )

  self:detect_filetype(bufnr)

  return commands
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
          file = vim.fn.expand("%:p")
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
  file = vim.fn.expand(file)
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
        self:create_buf_user_commands(decrypt_result.data[1])
      end
      log.warn("Consider using `chezmoi edit` instead.")
    end)
  else
    vim.cmd.edit(file)
  end
end

---Detects and sets filetype for `buf` using the target path.
---@param buf integer
function M:detect_filetype(buf)
  local set_filetype = vim.schedule_wrap(function(ft)
    if vim.bo[buf].filetype ~= ft then
      vim.bo[buf].filetype = ft
    end
  end)

  local file = vim.api.nvim_buf_get_name(buf)
  local source_file = vim.fn.fnamemodify(file, ":p")

  -- remove decrypted sufix and leading dot
  if string.match(source_file, chezmoi_helper._decrypted_sufix .. "$") then
    source_file = chezmoi_helper.get_encrypted_path(source_file)
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
  local target_file_result =
    require("nvim-chezmoi.chezmoi.commands.target_path"):exec({ source_file })

  if not target_file_result.success then
    return
  end
  --
  local target_file = target_file_result.data[1]
  -- Try match
  local ft = plenary_filetype.detect(target_file, {})
  if ft == nil or ft == "" then
    ft = vim.filetype.match({ filename = target_file }) or ""

    -- Could't find the filetype, try temp buf
    if ft == nil or ft == "" then
      local tmp_buf = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_buf_set_name(tmp_buf, target_file)
      ft = vim.filetype.match({ buf = tmp_buf }) or ""
      vim.api.nvim_buf_delete(tmp_buf, { force = true })
    end
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

return M
