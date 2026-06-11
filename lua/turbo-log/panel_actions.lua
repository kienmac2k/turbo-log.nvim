local bulk = require("turbo-log.bulk")
local detect = require("turbo-log.detect")

local M = {}

function M.entry_from_item(item)
  if not item then
    return nil
  end
  local data = item.item or {}
  return {
    path = item.filename or data.path,
    lnum = item.pos and item.pos[1] or data.lnum,
    line = item.text or data.line or "",
  }
end

function M.mutate_log_group(buf, entry, mutator)
  local groups = detect.log_groups(buf)
  for _, g in ipairs(groups) do
    if g.content_lnum == entry.lnum or (entry.lnum >= g.start_lnum and entry.lnum <= g.end_lnum) then
      mutator(buf, g)
      return true
    end
  end
  return false
end

function M.with_entry_buf(entry, fn)
  local path = vim.fs.normalize(entry.path)
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify("turbo-log: file not found: " .. path, vim.log.levels.ERROR)
    return false
  end

  local buf = vim.fn.bufadd(path)
  if buf == -1 then
    return false
  end
  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end

  vim.api.nvim_buf_call(buf, function()
    fn(buf)
  end)

  if vim.api.nvim_buf_get_option(buf, "modified") then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("silent! write")
    end)
  end

  return true
end

function M.delete_entry(entry)
  return M.with_entry_buf(entry, function(buf)
    M.mutate_log_group(buf, entry, function(b, g)
      vim.api.nvim_buf_set_lines(b, g.start_lnum - 1, g.end_lnum, false, {})
    end)
  end)
end

function M.comment_entry(entry)
  return M.with_entry_buf(entry, function(buf)
    local ft = vim.bo[buf].filetype
    M.mutate_log_group(buf, entry, function(b, g)
      local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
      local prefix = (ft == "python" or ft == "php") and "# " or "// "
      for i = g.start_lnum, g.end_lnum do
        local line = lines[i]
        if line and vim.trim(line) ~= "" then
          lines[i] = (line:match("^(%s*)") or "") .. prefix .. vim.trim(line)
        end
      end
      vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
    end)
  end)
end

function M.uncomment_entry(entry)
  return M.with_entry_buf(entry, function(buf)
    local ft = vim.bo[buf].filetype
    M.mutate_log_group(buf, entry, function(b, g)
      local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
      for i = g.start_lnum, g.end_lnum do
        local line = lines[i]
        local trimmed = vim.trim(line)
        if ft == "python" or ft == "php" then
          if trimmed:sub(1, 1) == "#" then
            lines[i] = (line:match("^(%s*)") or "") .. trimmed:sub(2):gsub("^%s*", "")
          end
        elseif trimmed:sub(1, 2) == "//" then
          lines[i] = (line:match("^(%s*)") or "") .. trimmed:sub(3):gsub("^%s*", "")
        end
      end
      vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
    end)
  end)
end

function M.correct_entry(entry)
  return M.with_entry_buf(entry, function(buf)
    bulk.correct_all(buf)
  end)
end

function M.run_on_item(item, action, view)
  local entry = M.entry_from_item(item)
  if not entry then
    return
  end
  if action(entry) and view then
    view:refresh()
  end
end

return M
