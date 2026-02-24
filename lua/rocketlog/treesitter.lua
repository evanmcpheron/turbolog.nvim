local M = {}

local SAFE_AFTER_STATEMENTS = {
  expression_statement = true,
  lexical_declaration = true,
  variable_declaration = true,
  import_statement = true,
  export_statement = true,
  class_declaration = true,
  function_declaration = true,
  generator_function_declaration = true,
  break_statement = true,
  continue_statement = true,
  debugger_statement = true,
  do_statement = true,
  empty_statement = true,
  for_statement = true,
  for_in_statement = true,
  for_of_statement = true,
  if_statement = true,
  switch_statement = true,
  throw_statement = true,
  try_statement = true,
  while_statement = true,
  with_statement = true,
  labeled_statement = true,
}

local ALWAYS_BEFORE_STATEMENTS = {
  return_statement = true,
}

local FUNCTION_LIKE = {
  arrow_function = true,
  function_declaration = true,
  function_expression = true,
  generator_function = true,
  generator_function_declaration = true,
  method_definition = true,
}

local SCOPE_BREAK = {
  program = true,
  statement_block = true,
}

local CONTROL_FLOW_HEADERS_PREFER_BEFORE = {
  if_statement = true,
  for_statement = true,
  for_in_statement = true,
  for_of_statement = true,
  while_statement = true,
  switch_statement = true,
  try_statement = true,
  with_statement = true,
  do_statement = true,
}

local function get_parser_root(bufnr)
  local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok_parser or not parser then
    return nil, "parser_unavailable"
  end

  local ok_parse, trees = pcall(parser.parse, parser)
  if not ok_parse or not trees or not trees[1] then
    return nil, "parse_failed"
  end

  local root = trees[1]:root()
  if not root then
    return nil, "no_root"
  end

  return root, nil
end

local function node_range_1_based(node)
  local sr, sc, er, ec = node:range()
  return {
    start_row = sr + 1,
    start_col = sc,
    end_row = er + 1,
    end_col = ec,
  }
end

local function is_descendant(node, possible_ancestor)
  local current = node
  while current do
    if current:id() == possible_ancestor:id() then
      return true
    end
    current = current:parent()
  end
  return false
end

local function first_child_of_type(node, wanted_type)
  if not node then
    return nil
  end

  for child in node:iter_children() do
    if child:named() and child:type() == wanted_type then
      return child
    end
  end

  return nil
end

local function nearest_function_ancestor(node)
  local current = node
  while current do
    if FUNCTION_LIKE[current:type()] then
      return current
    end
    current = current:parent()
  end
  return nil
end

local function nearest_named_node_for_range(root, start_row0, start_col0, end_row0, end_col0)
  if end_row0 < start_row0 or (end_row0 == start_row0 and end_col0 < start_col0) then
    end_row0, start_row0 = start_row0, end_row0
    end_col0, start_col0 = start_col0, end_col0
  end

  local ok, node = pcall(root.named_descendant_for_range, root, start_row0, start_col0, end_row0, end_col0)
  if not ok then
    return nil
  end
  return node
end

local function prefer_before_for_header_context(selected_node, statement_node)
  local statement_type = statement_node:type()
  if not CONTROL_FLOW_HEADERS_PREFER_BEFORE[statement_type] then
    return false
  end

  -- If the selection is inside the statement body block, don't move it before.
  local body_block = first_child_of_type(statement_node, "statement_block")
  if body_block and is_descendant(selected_node, body_block) then
    return false
  end

  -- Header/condition selections are safer before the control statement.
  return true
end

local function resolve_function_scope_restriction(selected_node)
  local fn = nearest_function_ancestor(selected_node)
  if not fn then
    return true, nil
  end

  local body_block = first_child_of_type(fn, "statement_block")
  if body_block then
    if is_descendant(selected_node, body_block) then
      return true, body_block
    end

    return false, "selection_in_function_header"
  end

  -- Arrow function with implicit expression body: no statement slot exists in local scope.
  if fn:type() == "arrow_function" then
    return false, "implicit_arrow_body"
  end

  return false, "unsupported_function_scope"
end

local function ascend_to_statement(selected_node)
  local current = selected_node
  while current do
    local node_type = current:type()
    if ALWAYS_BEFORE_STATEMENTS[node_type] or SAFE_AFTER_STATEMENTS[node_type] then
      return current
    end

    if SCOPE_BREAK[node_type] then
      return nil
    end

    current = current:parent()
  end

  return nil
end

---Resolve a syntax-aware insertion point using Tree-sitter.
---Returns nil + reason if unavailable or no safe placement exists.
---@param opts table { bufnr?, start_row, start_col, end_row, end_col }
---@return table|nil, string|nil
function M.resolve_insertion(opts)
  local bufnr = opts.bufnr or 0
  local root, root_err = get_parser_root(bufnr)
  if not root then
    return nil, root_err
  end

  local selected_node = nearest_named_node_for_range(root, opts.start_row, opts.start_col, opts.end_row, opts.end_col)
  if not selected_node then
    return nil, "node_not_found"
  end

  local scope_ok, scope_info = resolve_function_scope_restriction(selected_node)
  if not scope_ok then
    return nil, scope_info
  end

  local statement_node = ascend_to_statement(selected_node)
  if not statement_node then
    return nil, "statement_not_found"
  end

  local statement_type = statement_node:type()
  local r = node_range_1_based(statement_node)

  local mode = "after"
  local line = r.end_row
  local reference_line = r.start_row

  if ALWAYS_BEFORE_STATEMENTS[statement_type] then
    mode = "before"
    line = r.start_row
    reference_line = r.start_row
  elseif prefer_before_for_header_context(selected_node, statement_node) then
    mode = "before"
    line = r.start_row
    reference_line = r.start_row
  end

  return {
    mode = mode,
    line = line,
    reference_line = reference_line,
    statement_type = statement_type,
    source = "treesitter",
  }, nil
end

return M
