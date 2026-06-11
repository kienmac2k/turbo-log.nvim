local M = {}

function M.git_root()
  local out = vim.fn.systemlist({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
    return vim.fn.fnamemodify(out[1], ":p")
  end
  return vim.fn.getcwd()
end

function M.scan()
  local opts = require("turbo-log.config").get().panel
  if opts.scope == "git_root" then
    return M.git_root()
  end
  return vim.fn.getcwd()
end

return M
