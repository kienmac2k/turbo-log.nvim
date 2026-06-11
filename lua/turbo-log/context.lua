local M = {}

local function node_text(node, buf)
  if not node then
    return nil
  end
  local srow, scol, erow, ecol = node:range()
  return vim.api.nvim_buf_get_text(buf, srow, scol, erow, ecol, {})[1]
end

local function name_from_node(node, buf)
  if not node then
    return nil
  end
  local ntype = node:type()
  if ntype == "identifier" or ntype == "property_identifier" then
    return node_text(node, buf)
  end
  for child in node:iter_children() do
    local ctype = child:type()
    if ctype == "identifier" or ctype == "property_identifier" then
      return node_text(child, buf)
    end
  end
  return nil
end

local function walk_ancestors(node, buf, ft)
  local class_name, function_name

  while node do
    local ntype = node:type()

    if ft == "php" then
      if not class_name and (ntype == "class_declaration" or ntype == "interface_declaration") then
        class_name = name_from_node(node, buf)
      end
      if not function_name and (ntype == "function_definition" or ntype == "method_declaration") then
        function_name = name_from_node(node, buf)
      end
    elseif ft == "python" then
      if not class_name and ntype == "class_definition" then
        class_name = name_from_node(node, buf)
      end
      if not function_name and (ntype == "function_definition" or ntype == "lambda") then
        function_name = name_from_node(node, buf)
      end
    elseif ft == "cs" or ft == "csharp" then
      if
        not class_name
        and (
          ntype == "class_declaration"
          or ntype == "struct_declaration"
          or ntype == "record_declaration"
          or ntype == "interface_declaration"
        )
      then
        class_name = name_from_node(node, buf)
      end
      if
        not function_name
        and (ntype == "method_declaration" or ntype == "constructor_declaration" or ntype == "local_function_statement")
      then
        function_name = name_from_node(node, buf)
      end
    else
      if not class_name and (ntype == "class_declaration" or ntype == "class") then
        class_name = name_from_node(node, buf)
      end
      if
        not function_name
        and (
          ntype == "function_declaration"
          or ntype == "method_definition"
          or ntype == "arrow_function"
          or ntype == "function"
        )
      then
        function_name = name_from_node(node, buf)
        if not function_name and ntype == "arrow_function" then
          function_name = "anonymous"
        end
      end
    end

    node = node:parent()
  end

  return class_name, function_name
end

function M.get(buf, row, col, ft)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  local class_name, function_name

  local ok, parser = pcall(vim.treesitter.get_parser, buf, ft)
  if ok and parser then
    local tree = parser:trees()[1]
    if tree then
      local root = tree:root()
      local node = root:named_descendant_for_range(row, col, row, col)
      if node then
        class_name, function_name = walk_ancestors(node, buf, ft)
      end
    end
  end

  return {
    filename = filename,
    class_name = class_name or "",
    function_name = function_name or "",
  }
end

return M
