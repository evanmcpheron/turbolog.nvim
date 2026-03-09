local M = {}

---Read the text selected by motionsfunc using Neovim's '[' and ']' marks.
---@param optype string Motions type ("line", "char", "block" etc. from operatorfunc)
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

---Read the current visual selection using live visual positions when available.
---@return string|nil, integer|nil, integer|nil, integer|nil, integer|nil, integer|nil, integer|nil
--- expr_text, start_line, end_line, start_col, end_col, start_row0, end_row0
function M.get_visual_selection_text()
	local mode = vim.fn.visualmode()

	-- Live visual positions are more reliable than '< and '> while still in visual mode.
	local start_pos = vim.fn.getpos("v")
	local end_pos = vim.fn.getpos(".")

	local start_row = start_pos[2]
	local start_col1 = start_pos[3]
	local end_row = end_pos[2]
	local end_col1 = end_pos[3]

	-- Fallback to marks if live positions are unavailable.
	if start_row == 0 or end_row == 0 then
		local start_mark = vim.api.nvim_buf_get_mark(0, "<")
		local end_mark = vim.api.nvim_buf_get_mark(0, ">")

		start_row = start_mark[1]
		end_row = end_mark[1]
		start_col1 = start_mark[2] + 1
		end_col1 = end_mark[2] + 1
	end

	if start_row == 0 or end_row == 0 then
		return nil, nil, nil, nil, nil, nil, nil
	end

	-- Normalize reversed selections.
	if start_row > end_row or (start_row == end_row and start_col1 > end_col1) then
		start_row, end_row = end_row, start_row
		start_col1, end_col1 = end_col1, start_col1
	end

	if mode == "V" then
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

	-- Convert 1-based Vim cols to 0-based nvim_buf_get_text coords.
	local start_col0 = math.max(start_col1 - 1, 0)
	local end_col0_inclusive = math.max(end_col1 - 1, 0)
	local end_col0_exclusive = end_col0_inclusive + 1

	local selected_lines =
		vim.api.nvim_buf_get_text(0, start_row - 1, start_col0, end_row - 1, end_col0_exclusive, {})

	if #selected_lines == 0 then
		return nil, nil, nil, nil, nil, nil, nil
	end

	local text = table.concat(selected_lines, "\n")
	if text == "" then
		return nil, nil, nil, nil, nil, nil, nil
	end

	return text, start_row, end_row, start_col0, end_col0_inclusive, start_row - 1, end_row - 1
end

return M
