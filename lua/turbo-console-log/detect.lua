local config = require("turbo-console-log.config")
local langs = require("turbo-console-log.languages")
local paths = require("turbo-console-log.paths")

local M = {}

local function is_turbo_line(line, prefix, ft)
  if not line:find(prefix, 1, true) then
    return false
  end

  local lang = langs.for_filetype(ft)
  if not lang then
    return false
  end

  local patterns = lang.detect_patterns(prefix)
  for _, pat in ipairs(patterns) do
    if line:match(pat) then
      return true
    end
  end

  return false
end

local function infer_ft(ft, line)
  if ft and ft ~= "" then
    return ft
  end
  if line:find("console%.") then
    return "typescript"
  end
  if line:find("print%(") then
    return "python"
  end
  if line:find("error_log") or line:find("var_dump") or line:find("print_r") then
    return "php"
  end
  return "typescript"
end

function M.is_separator_line(line, ft)
  ft = infer_ft(ft, line)
  local prefix = config.get().logMessagePrefix
  if not line:find(prefix, 1, true) then
    return false
  end
  if M.extract_var(line, ft) then
    return false
  end
  return line:find("-+", 1) ~= nil
end

function M.is_content_line(line, ft)
  ft = infer_ft(ft, line)
  local prefix = config.get().logMessagePrefix
  if not is_turbo_line(line, prefix, ft) then
    return false
  end
  return M.extract_var(line, ft) ~= nil
end

---@return table[] groups with start_lnum, end_lnum, content_lnum
function M.log_groups(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local groups = {}
  local i = 1

  while i <= #lines do
    local line = lines[i]
    if M.is_separator_line(line, ft) and i + 2 <= #lines then
      if M.is_content_line(lines[i + 1], ft) and M.is_separator_line(lines[i + 2], ft) then
        groups[#groups + 1] = {
          start_lnum = i,
          end_lnum = i + 2,
          content_lnum = i + 1,
        }
        i = i + 3
      else
        i = i + 1
      end
    elseif M.is_content_line(line, ft) then
      groups[#groups + 1] = {
        start_lnum = i,
        end_lnum = i,
        content_lnum = i,
      }
      i = i + 1
    else
      i = i + 1
    end
  end

  return groups
end

function M.in_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local prefix = config.get().logMessagePrefix
  local results = {}

  for _, group in ipairs(M.log_groups(buf)) do
    local line = vim.api.nvim_buf_get_lines(buf, group.content_lnum - 1, group.content_lnum, false)[1] or ""
    results[#results + 1] = {
      buf = buf,
      lnum = group.content_lnum,
      line = line,
      start_lnum = group.start_lnum,
      end_lnum = group.end_lnum,
      commented = ((ft == "python" or ft == "php") and vim.trim(line):sub(1, 1) == "#")
        or vim.trim(line):sub(1, 2) == "//",
    }
  end

  return results
end

function M.extract_var(line, ft)
  if ft == "python" then
    local var = line:match(",%s*([%w_%.%[%]%(%)]+%.?%w*)%s*%)%s*$")
    if not var then
      var = line:match(',%s*([%w_%.%[%]%(%)]+)%s*$')
    end
    return var
  end

  if ft == "php" then
    local var = line:match(",%s*(%$[%w_]+)%s*%)")
    if not var then
      var = line:match('print_r%(%$[%w_]+%s*,%s*true%)')
    end
    return var
  end

  return line:match(",%s*([%w_%.%[%]%(%)]+%.?%w*)%s*%)%s*;?%s*$")
end

function M.extract_method(line, ft)
  if ft == "python" then
    return "log"
  end
  if ft == "php" then
    if line:find("var_dump") then
      return "debug"
    end
    if line:find("print_r") then
      return "table"
    end
    return "log"
  end
  return line:match("console%.(%w+)%(") or "log"
end

local function parse_rg_line(row)
  local path, lnum, text = row:match("^(.-):(%d+):(.*)$")
  if not path then
    return nil
  end
  return path, tonumber(lnum), text
end

function M.workspace_scan(root)
  root = vim.fn.fnamemodify(root or vim.fn.getcwd(), ":p")
  local prefix = config.get().logMessagePrefix
  local escaped = vim.pesc(prefix)
  local rg = vim.fn.exepath("rg")
  local results = {}

  if rg == "" then
    return results
  end

  local cmd = {
    rg,
    "--no-heading",
    "--line-number",
    "--glob",
    "!node_modules",
    "--glob",
    "!.git",
    escaped,
    ".",
  }

  local output = ""
  if vim.system then
    local job = vim.system(cmd, { cwd = root, text = true }):wait()
    if job.code ~= 0 and (job.stdout or "") == "" then
      return results
    end
    output = job.stdout or ""
  else
    local prev = vim.fn.getcwd()
    vim.cmd("lcd " .. vim.fn.fnameescape(root))
    output = vim.fn.system(cmd)
    vim.cmd("lcd " .. vim.fn.fnameescape(prev))
    if vim.v.shell_error ~= 0 and output == "" then
      return results
    end
  end

  for row in (output .. "\n"):gmatch("([^\n]*)\n") do
    if row ~= "" then
      local rel, lnum, text = parse_rg_line(row)
      if rel and lnum then
        local abs = paths.resolve(rel, root)
        if abs and vim.fn.filereadable(abs) == 1 then
          if not M.is_separator_line(text, vim.filetype.match({ filename = abs }) or "") then
            results[#results + 1] = {
              path = abs,
              display_path = paths.display(abs),
              lnum = lnum,
              line = text,
            }
          end
        end
      end
    end
  end

  table.sort(results, function(a, b)
    if a.path == b.path then
      return a.lnum < b.lnum
    end
    return a.path < b.path
  end)

  return results
end

return M
