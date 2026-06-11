local message = require("turbo-log.message")

local M = {}

M.filetypes = { "python" }

function M.build_line(method, var, ctx, log_line)
  return message.build_python_line(method, var, ctx, log_line)
end

function M.detect_patterns(_prefix)
  return {
    "print%(",
    "logging%.%w+%(",
    "logger%.%w+%(",
    "__import__%(\"pprint\"%).pformat%(",
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
