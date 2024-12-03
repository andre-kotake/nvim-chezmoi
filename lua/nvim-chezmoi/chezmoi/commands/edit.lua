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
            local result =
              require("nvim-chezmoi.chezmoi.commands.target_path"):exec({
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
            local choice =
              vim.fn.confirm("Apply " .. ev.file .. "?", "&Yes\n&No", 2)
            if choice == 1 then
              apply()
            end
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
      callback = function()
        self:detect_filetype(bufnr)
      end,
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

---Detects and sets filetype for `buf` using the target path.
---@param buf integer
function M:detect_filetype(buf)
  local set_filetype = vim.schedule_wrap(function(ft)
    if vim.bo[buf].filetype ~= ft then
      vim.bo[buf].filetype = ft
    end
  end)

  local source_file = vim.api.nvim_buf_get_name(buf)

  if vim.fn.fnamemodify(source_file, ":e") == "tmpl" then
    local filetype = vim.filetype.match({
      filename = vim.fn.fnamemodify(source_file, ":t"),
    })

    if filetype ~= "template" then
      set_filetype(filetype)
      return
    end
  end

  local ok, s = pcall(vim.api.nvim_buf_get_var, buf, "encrypted_source_path")
  if ok then
    source_file = s
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

  local target_file = target_file_result.data[1]

  -- Try match
  local ft = plenary_filetype.detect(target_file, {})
  if ft == nil or ft == "" then
    ft = vim.filetype.match({ filename = target_file }) or ""
  end

  -- Could't find the filetype, try temp buf
  if ft == nil or ft == "" then
    local tmp_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(tmp_buf, target_file)
    ft = vim.filetype.match({ buf = tmp_buf }) or ""
    vim.api.nvim_buf_delete(tmp_buf, { force = true })
  end

  if ft ~= nil and ft ~= "" then
    set_filetype(ft)

    vim.filetype.add({
      filename = {
        [vim.fn.fnamemodify(source_file, ":t")] = ft,
      },
    })

    -- Cache it
    chezmoi_cache.new("ft_detect", { source_file }, {
      args = {},
      success = true,
      data = { ft = ft },
    })
  end
end

return M
