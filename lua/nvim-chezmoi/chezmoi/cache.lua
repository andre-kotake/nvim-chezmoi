---@class ChezmoiCacheEntry
---@field args string[] Command arguments
---@field result ChezmoiCommandResult Command return

---@class ChezmoiCache
local M = {}

local function contains_all(arr1, arr2)
  -- Check if lengths are the same
  if #arr1 ~= #arr2 then
    return false
  end

  local set = {}
  for _, v in ipairs(arr2) do
    set[v] = true
  end

  for _, v in ipairs(arr1) do
    if not set[v] then
      return false
    end
  end
  return true
end

---@param cmd string
---@param args string[]|nil
---@return ChezmoiCacheEntry|nil
M.find = function(cmd, args)
  local cmd_args = { cmd }
  vim.list_extend(cmd_args, args or {})

  local cached = M[cmd]

  if cached ~= nil then
    if not contains_all(cached.args, cmd_args) then
      return nil
    end

    return cached
  end

  return nil
end

---@param cmd string
---@param args string[]|nil
---@return ChezmoiCacheEntry|nil
M.find_success = function(cmd, args)
  local cached = M.find(cmd, args)
  if cached ~= nil and cached.result.success then
    return cached
  end

  return nil
end

---@param cmd string
---@param args string[]|nil
---@param result ChezmoiCommandResult
---@return ChezmoiCacheEntry
M.new = function(cmd, args, result)
  local cmd_args = { cmd }
  vim.list_extend(cmd_args, args or {})

  M[cmd] = {
    args = cmd_args,
    result = result,
  }

  return M[cmd]
end

return M
