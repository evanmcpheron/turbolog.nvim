local M = {}

---Read the text selected by operatorfunc using Neovim's '[' and ']' marks.
---@param optype string Operator type ("line", "char", "block" etc. from operatorfunc)
---@return string|nil, integer|nil, integer|nil expr_text, start_line, end_line
function M.get_text_from_marks(optype)
	local start_mark = vim.api.nvim_buf_get_mark(0, "[")
	local end_mark = vim.api.nvim_buf_get_mark(0, "]")

	local start_row, start_col = start_mark[1], start_mark[2]
	local end_row, end_col = end_mark[1], end_mark[2]

	-- Marks not set
	if start_row == 0 or end_row == 0 then
		return nil, nil, nil
	end

	local selected_lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
	if #selected_lines == 0 then
		return nil, nil, nil
	end

	-- Linewise operator: return full lines as-is
	if optype == "line" then
		return table.concat(selected_lines, "\n"), start_row, end_row
	end

	-- Characterwise operator: trim first/last lines to selected columns
	if #selected_lines == 1 then
		selected_lines[1] = string.sub(selected_lines[1], start_col + 1, end_col + 1)
	else
		selected_lines[1] = string.sub(selected_lines[1], start_col + 1)
		selected_lines[#selected_lines] = string.sub(selected_lines[#selected_lines], 1, end_col + 1)
	end

	return table.concat(selected_lines, "\n"), start_row, end_row
end

return M
