local message = require("turbo-console-log.message")

local M = {}

M.filetypes = { "python" }

function M.build_line(method, var, ctx, log_line)
  return message.build_python_line(method, var, ctx, log_line)
end

function M.detect_patterns(_prefix)
  return {
    "print%(",
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
