local message = require("turbo-log.message")

local M = {}

M.filetypes = { "php" }

function M.build_line(method, var, ctx, log_line)
  return message.build_php_line(method, var, ctx, log_line)
end

function M.detect_patterns(_prefix)
  return {
    "error_log%(",
    "var_dump%(",
    "print_r%(",
  }
end

M.log_methods = {
  log = true,
  info = true,
  debug = true,
  warn = true,
  error = true,
  table = true,
  custom = true,
}

return M
