local M = {}

---Read the text selected by operatorfunc using Neovim's '[' and ']' marks.
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

	if optype == "line" then
		local selected_lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
		if #selected_lines == 0 then
			return nil, nil, nil, nil, nil, nil, nil
		end

		return table.concat(selected_lines, "\n"),
			start_row,
			end_row,
			0,
			math.max(0, #selected_lines[#selected_lines] - 1),
			start_row - 1,
			end_row - 1
	end

	-- nvim_buf_get_text preserves indentation for middle lines in multiline selections.
	-- end_col is exclusive for this API, while marks are inclusive, so add 1.
	local selected_lines =
		vim.api.nvim_buf_get_text(0, start_row - 1, start_col, end_row - 1, end_col + 1, {})

	if #selected_lines == 0 then
		return nil, nil, nil, nil, nil, nil, nil
	end

	return table.concat(selected_lines, "\n"),
		start_row,
		end_row,
		start_col,
		end_col,
		start_row - 1,
		end_row - 1
end

return M
