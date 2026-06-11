local M = {}

local EXPRESSION_TYPES = {
  identifier = true,
  property_identifier = true,
  member_expression = true,
  subscript_expression = true,
  call_expression = true,
  optional_chain = true,
  parenthesized_expression = true,
  object = true,
  array = true,
  string = true,
  number = true,
  ["true"] = true,
  ["false"] = true,
  ["null"] = true,
  ["undefined"] = true,
  binary_expression = true,
  unary_expression = true,
  ternary_expression = true,
  template_string = true,
  new_expression = true,
  spread_element = true,
  attribute = true,
  list = true,
  dictionary = true,
  variable_name = true,
  dynamic_variable_name = true,
  member_access_expression = true,
  scoped_call_expression = true,
  element_access_expression = true,
  invocation_expression = true,
  prefix_unary_expression = true,
  postfix_unary_expression = true,
  assignment_expression = true,
  object_creation_expression = true,
  implicit_array_creation_expression = true,
  string_literal = true,
  integer_literal = true,
  boolean_literal = true,
  null_literal = true,
  real_literal = true,
}

local function node_text(node, buf)
  local srow, scol, erow, ecol = node:range()
  return vim.api.nvim_buf_get_text(buf, srow, scol, erow, ecol, {})[1]
end

local function expand_expression(node, buf)
  while node and node:type() == "parenthesized_expression" do
    for child in node:iter_children() do
      if child:named() then
        node = child
        break
      end
    end
  end
  return node
end

--- Read the last visual selection using marks set when visual mode ends.
---@return string? text
---@return integer? start_row 0-indexed
---@return integer? end_row 0-indexed
function M.from_marks(buf)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end

  local srow, scol = start_pos[2], start_pos[3]
  local erow, ecol = end_pos[2], end_pos[3]
  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end

  local text
  if vim.fn.getregion then
    local ok, lines = pcall(vim.fn.getregion, srow, scol, erow, ecol)
    if ok and type(lines) == "table" and #lines > 0 then
      text = table.concat(lines, "\n")
    end
  end

  if not text or text == "" then
    if srow == erow then
      local line = vim.api.nvim_buf_get_lines(buf, srow - 1, srow, false)[1] or ""
      if scol == 1 and ecol >= #line then
        text = line
      else
        text = line:sub(scol, ecol)
      end
    elseif scol == 1 and ecol == 1 then
      text = table.concat(vim.api.nvim_buf_get_lines(buf, srow - 1, erow, false), "\n")
    else
      local lines = vim.api.nvim_buf_get_lines(buf, srow - 1, erow, false)
      if #lines > 0 then
        lines[1] = lines[1]:sub(scol)
        lines[#lines] = lines[#lines]:sub(1, ecol)
        text = table.concat(lines, "\n")
      end
    end
  end

  text = vim.trim(text or "")
  if text == "" then
    return nil
  end
  return text, srow - 1, erow - 1
end

function M.from_visual(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local srow, scol = start_pos[2], start_pos[3]
  local erow, ecol = end_pos[2], end_pos[3]
  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end
  if mode == "V" then
    scol = 1
    ecol = #(vim.api.nvim_buf_get_lines(buf, erow, erow, false)[1] or "")
  elseif mode == "v" or mode == "\22" then
    if srow ~= erow then
      local lines = vim.api.nvim_buf_get_lines(buf, srow - 1, erow, false)
      if #lines > 0 then
        lines[1] = lines[1]:sub(scol)
        lines[#lines] = lines[#lines]:sub(1, ecol)
        local text = vim.trim(table.concat(lines, "\n"))
        if text ~= "" then
          return text, srow - 1, erow - 1
        end
      end
      return nil
    end
  end

  local line = vim.api.nvim_buf_get_lines(buf, srow - 1, srow, false)[1] or ""
  local text = vim.trim(line:sub(scol, ecol))
  if text ~= "" then
    return text, srow - 1, erow - 1
  end
  return nil
end

function M.from_cursor(buf, row, col, ft)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, ft)
  if not ok or not parser then
    return vim.fn.expand("<cword>"), row
  end

  local tree = parser:trees()[1]
  if not tree then
    return vim.fn.expand("<cword>"), row
  end

  local root = tree:root()
  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then
    return vim.fn.expand("<cword>"), row
  end

  while node and not EXPRESSION_TYPES[node:type()] do
    node = node:parent()
  end

  if node then
    node = expand_expression(node, buf)
    local srow = node:range()
    return node_text(node, buf), srow
  end

  return vim.fn.expand("<cword>"), row
end

function M.resolve(buf, ft, opts)
  opts = opts or {}

  if opts.from_visual then
    local var, start_row, end_row = M.from_marks(buf)
    if var then
      return var, start_row, end_row
    end
  end

  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local var, start_row, end_row = M.from_visual(buf)
    if var then
      return var, start_row, end_row
    end
  end

  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local var, var_row = M.from_cursor(buf, row, col, ft)
  return var, var_row, nil
end

return M
