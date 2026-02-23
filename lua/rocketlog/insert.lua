local M = {}

---Insert a log statement after the "end" of the current JS/TS statement.
---This uses heuristics to avoid inserting into the middle of chained/multiline expressions.
---@param log_line string|string[] A single line or list of lines to insert
---@param start_line integer The line where the original selection/operator started
function M.insert_after_statement(log_line, start_line)
	local last_buffer_line = vim.fn.line("$")
	local insertion_line = start_line

	-- Track bracket nesting depth so we can detect when multiline expressions close.
	local paren_depth, brace_depth, bracket_depth = 0, 0, 0
	local has_started_multiline_expression = false

	---Trim trailing whitespace from a string.
	---@param text string
	---@return string
	local function trim_right(text)
		return (text:gsub("%s+$", ""))
	end

	---Find the next non-blank line after `from_line`.
	---@param from_line integer
	---@return integer|nil, string|nil
	local function next_nonblank_line(from_line)
		for line_number = from_line + 1, last_buffer_line do
			local line_text = vim.fn.getline(line_number)
			if line_text and line_text:match("%S") then
				return line_number, line_text
			end
		end
		return nil, nil
	end

	---Check if a line ends with a comma (ignoring trailing whitespace).
	---@param text string|nil
	---@return boolean
	local function line_ends_with_comma(text)
		local trimmed_text = trim_right(text or "")
		return trimmed_text:match(",$") ~= nil
	end

	---Heuristic check for whether a line looks like a continuation of the previous line.
	---Examples:
	---  .map(...)
	---  && foo
	---  ?? bar
	---  , something
	---@param text string|nil
	---@return boolean
	local function is_continuation_line(text)
		if not text then
			return false
		end

		local trimmed_left = text:gsub("^%s+", "")

		-- Continuation starts with punctuation/closing delimiters followed by comma
		if
			trimmed_left:match("^,")
			or trimmed_left:match("^},")
			or trimmed_left:match("^%],")
			or trimmed_left:match("^%),")
		then
			return true
		end

		-- Continuation starts with chaining/operators
		if
			trimmed_left:match("^%.")
			or trimmed_left:match("^%?%.")
			or trimmed_left:match("^%?%?")
			or trimmed_left:match("^&&")
			or trimmed_left:match("^||")
			or trimmed_left:match("^%+")
			or trimmed_left:match("^-")
			or trimmed_left:match("^%*")
			or trimmed_left:match("^/")
			or trimmed_left:match("^%%")
		then
			return true
		end

		return false
	end

	-- Walk downward from the anchor line until we find the best insertion point.
	for line_number = start_line, last_buffer_line do
		local line_text = vim.fn.getline(line_number)

		-- Track nesting depth (heuristic parser, character-by-character).
		for char_index = 1, #line_text do
			local char = line_text:sub(char_index, char_index)

			if char == "(" then
				paren_depth = paren_depth + 1
				has_started_multiline_expression = true
			elseif char == ")" then
				paren_depth = math.max(0, paren_depth - 1)
			elseif char == "{" then
				brace_depth = brace_depth + 1
				has_started_multiline_expression = true
			elseif char == "}" then
				brace_depth = math.max(0, brace_depth - 1)
			elseif char == "[" then
				bracket_depth = bracket_depth + 1
				has_started_multiline_expression = true
			elseif char == "]" then
				bracket_depth = math.max(0, bracket_depth - 1)
			end
		end

		local compact_line = line_text:gsub("%s+", "")
		local _, next_nonblank_text = next_nonblank_line(line_number)

		-- 1) Semicolon is the strongest signal of statement end.
		if line_text:find(";") and paren_depth == 0 and brace_depth == 0 and bracket_depth == 0 then
			insertion_line = line_number
			break
		end

		-- 2) Multiline expression closes (no semicolon case)
		if has_started_multiline_expression and paren_depth == 0 and brace_depth == 0 and bracket_depth == 0 then
			if line_ends_with_comma(line_text) then
				goto continue
			end

			if is_continuation_line(next_nonblank_text) then
				goto continue
			end

			insertion_line = line_number
			break
		end

		-- 3) Single-line-looking expression with no semicolon
		if line_number == start_line and not has_started_multiline_expression and compact_line ~= "" then
			if line_ends_with_comma(line_text) then
				goto continue
			end

			if is_continuation_line(next_nonblank_text) then
				goto continue
			end

			insertion_line = line_number
			break
		end

		::continue::
	end

	-- Normalize to a list of lines (nvim_buf_set_lines expects a table)
	local lines_to_insert = type(log_line) == "table" and log_line or { log_line }

	-- Insert *after* the detected statement line.
	-- (API is 0-indexed for line insertion positions)
	vim.api.nvim_buf_set_lines(0, insertion_line, insertion_line, false, lines_to_insert)
end

---Adjust the anchor line in cases where the operator starts inside a multiline structure.
---Example: if the prior line ends with "{", "(", or "[", we may want to insert relative
---to that opening line instead of the selected line.
---@param anchor_line integer|nil
---@param selection_start_line integer
---@return integer
function M.normalize_anchor_line(anchor_line, selection_start_line)
	local normalized_line = anchor_line or selection_start_line
	if not normalized_line or normalized_line < 1 then
		return selection_start_line
	end

	local previous_line_text = vim.fn.getline(normalized_line - 1)
	local current_line_text = vim.fn.getline(normalized_line)

	if normalized_line > 1 and previous_line_text and current_line_text then
		local previous_line_trimmed_right = previous_line_text:gsub("%s+$", "")
		local current_line_trimmed_left = current_line_text:gsub("^%s+", "")

		-- If previous line ends in an opener and current line doesn't look like
		-- a declaration/assignment, shift anchor up one line.
		if
			previous_line_trimmed_right:find("{%s*$")
			or previous_line_trimmed_right:find("%(%s*$")
			or previous_line_trimmed_right:find("%[%s*$")
		then
			if
				not current_line_trimmed_left:match("^[%w_]+%s*=")
				and not current_line_trimmed_left:match("^const%s+")
				and not current_line_trimmed_left:match("^let%s+")
			then
				return normalized_line - 1
			end
		end
	end

	return normalized_line
end

return M
