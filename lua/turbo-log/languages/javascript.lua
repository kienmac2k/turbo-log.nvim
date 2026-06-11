local message = require("turbo-log.message")

local M = {}

M.filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

function M.build_line(method, var, ctx, log_line)
  return message.build_js_line(method, var, ctx, log_line)
end

function M.detect_patterns(_prefix)
  return {
    "console%.%w+%(",
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
