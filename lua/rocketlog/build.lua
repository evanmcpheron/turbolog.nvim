local M = {}

---Build the console.log line(s) for the selected expression.
---If the expression spans multiple lines, generates a multiline console.log call.
---@param file string Filename only (not full path)
---@param line_num integer Source line number used in the rocket label
---@param expr string Expression text captured from operator selection
---@return string[]
function M.build_rocket_log_lines(file, line_num, expr)
	local expression_lines = vim.split(expr, "\n", { plain = true })

	-- Single-line expression => one-line console.log
	if #expression_lines == 1 then
		local label_text = expr:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		return {
			string.format("console.log(`🚀 ~ %s:%d ~ %s:`, %s);", file, line_num, label_text, expr),
		}
	end

	-- Multiline expression => multiline console.log to preserve readability
	local output_lines = {
		"console.log(",
		string.format("  `🚀 ~ %s:%d ~", file, line_num),
	}

	-- Add the expression itself into the label section (multiline template string)
	for _, expression_line in ipairs(expression_lines) do
		table.insert(output_lines, expression_line)
	end

	table.insert(output_lines, "`:,")

	-- Add the actual expression argument (again), preserving multiline formatting
	for index, expression_line in ipairs(expression_lines) do
		if index == 1 then
			table.insert(output_lines, "  " .. expression_line)
		else
			table.insert(output_lines, expression_line)
		end
	end

	table.insert(output_lines, ");")

	return output_lines
end

return M
