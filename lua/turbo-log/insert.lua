local config = require("turbo-log.config")
local context = require("turbo-log.context")
local target = require("turbo-log.target")
local message = require("turbo-log.message")
local langs = require("turbo-log.languages")
local python_setup = require("turbo-log.python_setup")

local M = {}

local function get_indent(line)
  return line:match("^(%s*)") or ""
end

local function statement_end_line(buf, row, col, ft)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, ft)
  if ok and parser then
    local tree = parser:trees()[1]
    if tree then
      local root = tree:root()
      local node = root:named_descendant_for_range(row, col, row, col)
      while node do
        local ntype = node:type()
        if
          ntype == "statement_block"
          or ntype == "expression_statement"
          or ntype == "lexical_declaration"
          or ntype == "variable_declaration"
          or ntype == "return_statement"
          or ntype == "if_statement"
          or ntype == "for_statement"
          or ntype == "while_statement"
          or ntype == "function_declaration"
          or ntype == "method_definition"
          or ntype == "class_declaration"
          or ntype == "assignment"
          or ntype == "augmented_assignment"
          or ntype == "expression_list"
          or ntype == "import_statement"
          or ntype == "export_statement"
          or ntype == "block"
          or ntype == "local_declaration_statement"
          or ntype == "foreach_statement"
          or ntype == "method_declaration"
          or ntype == "constructor_declaration"
        then
          local _, _, erow = node:range()
          return erow
        end
        node = node:parent()
      end
    end
  end
  return row
end

function M.insert(method, insert_opts)
  insert_opts = insert_opts or {}
  local buf = vim.api.nvim_get_current_buf()
  local ft = vim.bo[buf].filetype
  local lang = langs.for_filetype(ft)
  if not lang then
    vim.notify("turbo-log: unsupported filetype " .. ft, vim.log.levels.WARN)
    return
  end

  if lang.log_methods and not lang.log_methods[method] then
    vim.notify("turbo-log: unsupported method " .. method, vim.log.levels.WARN)
    return
  end

  local var, var_row, var_end_row = target.resolve(buf, ft, insert_opts)
  if not var or var == "" then
    vim.notify("turbo-log: no variable found", vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local ctx_row = type(var_row) == "number" and var_row or (cursor[1] - 1)
  local ctx_col = cursor[2]

  local statement_row = ctx_row
  local statement_col = ctx_col
  if insert_opts.from_visual and type(var_end_row) == "number" then
    statement_row = var_end_row
    local line = vim.api.nvim_buf_get_lines(buf, statement_row, statement_row + 1, false)[1] or ""
    statement_col = math.max(0, #line - 1)
  end

  local end_row = statement_end_line(buf, statement_row, statement_col, ft)
  local insert_row = end_row + 1

  local setup_offset = 0
  if ft == "python" then
    setup_offset = python_setup.ensure(buf)
    insert_row = insert_row + setup_offset
  end

  local opts = config.get()
  local indent = get_indent(vim.api.nvim_buf_get_lines(buf, end_row, end_row + 1, false)[1] or "")

  local log_line_num = insert_row + 1
  if opts.insertEmptyLineBeforeLogMessage then
    log_line_num = log_line_num + 1
  end
  if opts.wrapLogMessage then
    log_line_num = log_line_num + 1
  end

  local ctx = context.get(buf, ctx_row + setup_offset, ctx_col, ft)
  local built = message.build_lines(method, var, ctx, log_line_num, ft)

  local lines = {}
  if opts.insertEmptyLineBeforeLogMessage then
    lines[#lines + 1] = ""
  end
  for _, line in ipairs(built) do
    lines[#lines + 1] = indent .. line
  end
  if opts.insertEmptyLineAfterLogMessage then
    lines[#lines + 1] = ""
  end

  vim.api.nvim_buf_set_lines(buf, insert_row, insert_row, false, lines)
  vim.api.nvim_buf_set_option(buf, "modified", true)
end

return M
