local M = {}

local function escape_template_text(text)
	local escaped = text:gsub("\\", "\\\\")
	escaped = escaped:gsub("`", "\\`")
	escaped = escaped:gsub("%${", "\\${")
	return escaped
end

local function trim_blank_edges(lines)
	local start_idx = 1
	local end_idx = #lines

	while start_idx <= end_idx and not lines[start_idx]:match("%S") do
		start_idx = start_idx + 1
	end

	while end_idx >= start_idx and not lines[end_idx]:match("%S") do
		end_idx = end_idx - 1
	end

	local trimmed = {}
	for i = start_idx, end_idx do
		table.insert(trimmed, lines[i])
	end

	return trimmed
end

local function leading_indent_width(line)
	local indent = line:match("^(%s*)") or ""
	return #indent
end

local function strip_indent(line, width)
	if not line:match("%S") then
		return ""
	end
	return line:sub(width + 1)
end

local function dedent_lines_smart(lines)
	local normalized = trim_blank_edges(lines)
	if #normalized <= 1 then
		return normalized
	end

	-- Step 1: remove common outer indentation from all non-empty lines
	local common_min = nil
	for _, line in ipairs(normalized) do
		if line:match("%S") then
			local indent = leading_indent_width(line)
			if common_min == nil or indent < common_min then
				common_min = indent
			end
		end
	end

	local base = {}
	if not common_min or common_min == 0 then
		base = vim.deepcopy(normalized)
	else
		for _, line in ipairs(normalized) do
			table.insert(base, strip_indent(line, common_min))
		end
	end

	-- Step 2: wrapped block normalization (canonicalize to { ... } with 2-space inner indent)
	local first_text = (base[1] or ""):gsub("^%s*", "")
	local last_text = (base[#base] or ""):gsub("^%s*", "")

	local is_wrapped_block = (first_text == "{" and last_text == "}")
		or (first_text == "[" and last_text == "]")
		or (first_text == "(" and last_text == ")")

	if not is_wrapped_block then
		return base
	end

	local out = {}
	table.insert(out, first_text)

	-- Find the minimum indent across middle non-empty lines
	local middle_min = nil
	for i = 2, #base - 1 do
		local line = base[i]
		if line and line:match("%S") then
			local indent = leading_indent_width(line)
			if middle_min == nil or indent < middle_min then
				middle_min = indent
			end
		end
	end

	-- Rebase middle lines so the shallowest middle line is exactly 2 spaces
	for i = 2, #base - 1 do
		local line = base[i] or ""
		if not line:match("%S") then
			table.insert(out, "")
		else
			local rebased = line
			if middle_min and middle_min > 0 then
				rebased = strip_indent(line, middle_min)
			end
			table.insert(out, "  " .. rebased)
		end
	end

	table.insert(out, last_text)
	return out
end

local function normalize_label_text_single_line(expr)
	return expr:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

---Build the console statement line(s) for the selected expression.
---If the expression spans multiple lines, emits a multiline console call that preserves expression formatting.
---@param file string Filename only (not full path)
---@param line_num integer Source line number used in the rocket label
---@param expr string Expression text captured from operator selection
---@param log_type string|nil Optional console method (log, error, warn, info, etc.)
---@return string[]
function M.build_rocket_log_lines(file, line_num, expr, log_type)
	local method = log_type or "log"
	local expression_lines = vim.split(expr, "\n", { plain = true })
	local rocketlog_label = RocketLogs.config.label or "ROCKETLOG"

	if #expression_lines == 1 then
		local label_text = escape_template_text(normalize_label_text_single_line(expr))
		return {
			string.format(
				"console.%s(`🚀[%s] ~ %s:%d ~ %s:`, %s);",
				method,
				rocketlog_label,
				file,
				line_num,
				label_text,
				expr
			),
		}
	end

	local normalized_lines = dedent_lines_smart(expression_lines)

	local output_lines = {
		string.format("console.%s(`🚀[%s] ~ %s:%d ~", method, rocketlog_label, file, line_num),
	}

	-- Template string body (preserve normalized formatting)
	for _, expression_line in ipairs(normalized_lines) do
		table.insert(output_lines, escape_template_text(expression_line))
	end

	output_lines[#output_lines] = output_lines[#output_lines] .. "`,"

	-- Logged value block (always indent consistently)
	for _, expression_line in ipairs(normalized_lines) do
		table.insert(output_lines, "  " .. expression_line)
	end

	table.insert(output_lines, ");")

	return output_lines
end

return M
