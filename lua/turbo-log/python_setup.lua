local config = require("turbo-log.config")

local M = {}

local function has_logging_import(lines)
  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed:match("^import%s+logging%s*$") or trimmed:match("^import%s+logging%s+as%s+") then
      return true
    end
    if trimmed:match("^from%s+logging%s+import") then
      return true
    end
  end
  return false
end

local function has_basic_config(lines)
  for _, line in ipairs(lines) do
    if line:find("logging%.basicConfig%(") then
      return true
    end
  end
  return false
end

local function find_import_insert_row(lines)
  local last_import_row = nil
  for i, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed:match("^import ") or trimmed:match("^from ") then
      last_import_row = i - 1
    elseif trimmed ~= "" and not trimmed:match("^#") and last_import_row then
      break
    end
  end
  return last_import_row
end

function M.ensure(buf)
  if vim.bo[buf].filetype ~= "python" then
    return 0
  end

  local opts = config.get()
  if opts.pythonAutoSetup == false then
    return 0
  end

  local logger = opts.pythonLogger or "logging"
  if logger ~= "logging" then
    return 0
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local need_import = not has_logging_import(lines)
  local need_config = not has_basic_config(lines)

  if not need_import and not need_config then
    return 0
  end

  local setup_lines = {}
  if need_import then
    setup_lines[#setup_lines + 1] = "import logging"
  end
  if need_config then
    setup_lines[#setup_lines + 1] = 'logging.basicConfig(level=logging.DEBUG, format="%(message)s")'
  end

  local insert_row = find_import_insert_row(lines)
  if insert_row then
    insert_row = insert_row + 1
  else
    insert_row = 0
  end

  vim.api.nvim_buf_set_lines(buf, insert_row, insert_row, false, setup_lines)
  vim.api.nvim_buf_set_option(buf, "modified", true)
  return #setup_lines
end

return M
