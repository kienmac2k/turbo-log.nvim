local M = {}

--- Normalize a path from ripgrep into an absolute path.
---@param path string
---@param root string search root (rg cwd)
function M.resolve(path, root)
  if not path or path == "" then
    return nil
  end

  root = vim.fn.fnamemodify(root, ":p")

  if path:sub(1, 1) == "~" then
    return vim.fn.fnamemodify(path, ":p")
  end

  if vim.fn.has("win32") == 1 and path:match("^%a:[/\\]") then
    return vim.fn.fnamemodify(path, ":p")
  end

  if path:sub(1, 1) == "/" then
    return vim.fn.fnamemodify(path, ":p")
  end

  if path:sub(1, 2) == "./" then
    path = path:sub(3)
  end

  local abs = vim.fn.fnamemodify(vim.fn.resolve(root .. "/" .. path), ":p")
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(abs)
  end
  return abs
end

function M.display(path)
  local home = vim.env.HOME or ""
  if home ~= "" and vim.startswith(path, home) then
    return "~" .. path:sub(#home + 1)
  end
  return path
end

return M
