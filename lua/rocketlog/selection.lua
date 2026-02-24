local M = {}

---Read the text selected by operatorfunc using Neovim's '[' and ']' marks.
---Returns both 1-based line coordinates and 0-based row coordinates so callers can
---use normal Vim APIs and Tree-sitter APIs without recomputing ranges.
---@param optype string Operator type ("line", "char", "block" etc. from operatorfunc)
---@return string|nil, integer|nil, integer|nil, integer|nil, integer|nil, integer|nil, integer|nil
--- expr_text, start_line, end_line, start_col, end_col, start_row0, end_row0
function M.get_text_from_marks(optype)
  local start_mark = vim.api.nvim_buf_get_mark(0, "[")
  local end_mark = vim.api.nvim_buf_get_mark(0, "]")

  local start_row, start_col = start_mark[1], start_mark[2]
  local end_row, end_col = end_mark[1], end_mark[2]

  if start_row == 0 or end_row == 0 then
    return nil, nil, nil, nil, nil, nil, nil
  end

  local selected_lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  if #selected_lines == 0 then
    return nil, nil, nil, nil, nil, nil, nil
  end

  -- Linewise operators include full lines, so column bounds are synthetic.
  if optype == "line" then
    return table.concat(selected_lines, "\n"), start_row, end_row, 0, math.max(0, #selected_lines[#selected_lines] - 1), start_row - 1, end_row - 1
  end

  -- Characterwise selections need to be trimmed to the exact start/end columns.
  if #selected_lines == 1 then
    selected_lines[1] = string.sub(selected_lines[1], start_col + 1, end_col + 1)
  else
    selected_lines[1] = string.sub(selected_lines[1], start_col + 1)
    selected_lines[#selected_lines] = string.sub(selected_lines[#selected_lines], 1, end_col + 1)
  end

  return table.concat(selected_lines, "\n"), start_row, end_row, start_col, end_col, start_row - 1, end_row - 1
end

return M
