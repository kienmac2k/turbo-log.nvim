local message = require("turbo-log.message")

local M = {}

M.filetypes = { "cs", "csharp" }

function M.build_line(method, var, ctx, log_line)
  return message.build_csharp_line(method, var, ctx, log_line)
end

function M.detect_patterns(_prefix)
  return {
    "Console%.WriteLine%(",
    "Console%.Error%.WriteLine%(",
    "System%.Diagnostics%.Debug%.WriteLine%(",
    "Debug%.WriteLine%(",
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
