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

function M.from_visual()
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local srow, scol = start_pos[2] - 1, start_pos[3] - 1
  local erow, ecol = end_pos[2] - 1, end_pos[3]
  if vim.fn.mode() == "V" or vim.fn.mode() == "v" then
    ecol = 0
    erow = erow + 1
  end
  local lines = vim.api.nvim_buf_get_text(0, srow, scol, erow, ecol, {})
  local text = table.concat(lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
  if text ~= "" then
    return text, srow
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

function M.resolve(buf, ft)
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local var, row = M.from_visual()
    if var then
      return var, row
    end
  end

  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return M.from_cursor(buf, row, col, ft)
end

return M
