local M = {}

local defaults = {
	keymaps = {
		operator = "<leadercl",
		word = "<leader>cL",
	},
	enabled = true,
	allowed_filetypes = {
		javascript = true,
		javascriptreact = true,
		typescript = true,
		typescriptreact = true,
	},
}

M.config = vim.deepcopy(defaults)

-- Store where the operator started (cursor line before g@)
_G.__rocket_log_anchor_line = nil

local function is_supported_filetype()
	local ft = vim.bo.filetype
	return M.config.allowed_filetypes == nil or M.config.allowed_filetypes[ft] == true
end

local function insert_after_statement(log_line, start_line)
	local last_line = vim.fn.line("$")
	local insert_at = start_line
	local depth_paren, depth_brace, depth_bracket = 0, 0, 0
	local started_multiline = false

	local function rtrim(s)
		return (s:gsub("%s+$", ""))
	end

	local function next_nonblank_line(from_line)
		for i = from_line + 1, last_line do
			local t = vim.fn.getline(i)
			if t and t:match("%S") then
				return i, t
			end
		end
		return nil, nil
	end

	local function line_ends_with_comma(text)
		local trimmed = rtrim(text or "")
		return trimmed:match(",$") ~= nil
	end

	local function is_continuation_line(text)
		if not text then
			return false
		end
		local trimmed = text:gsub("^%s+", "")

		if trimmed:match("^,") or trimmed:match("^},") or trimmed:match("^%],") or trimmed:match("^%),") then
			return true
		end

		if
			trimmed:match("^%.")
			or trimmed:match("^%?%.")
			or trimmed:match("^%?%?")
			or trimmed:match("^&&")
			or trimmed:match("^||")
			or trimmed:match("^%+")
			or trimmed:match("^-")
			or trimmed:match("^%*")
			or trimmed:match("^/")
			or trimmed:match("^%%")
		then
			return true
		end

		return false
	end

	for lnum = start_line, last_line do
		local text = vim.fn.getline(lnum)

		-- Track nesting (heuristic)
		for i = 1, #text do
			local ch = text:sub(i, i)
			if ch == "(" then
				depth_paren = depth_paren + 1
				started_multiline = true
			elseif ch == ")" then
				depth_paren = math.max(0, depth_paren - 1)
			elseif ch == "{" then
				depth_brace = depth_brace + 1
				started_multiline = true
			elseif ch == "}" then
				depth_brace = math.max(0, depth_brace - 1)
			elseif ch == "[" then
				depth_bracket = depth_bracket + 1
				started_multiline = true
			elseif ch == "]" then
				depth_bracket = math.max(0, depth_bracket - 1)
			end
		end

		local compact = text:gsub("%s+", "")
		local _, next_text = next_nonblank_line(lnum)

		-- 1) Semicolon is best signal
		if text:find(";") and depth_paren == 0 and depth_brace == 0 and depth_bracket == 0 then
			insert_at = lnum
			break
		end

		-- 2) Multiline closure with no semicolon
		if started_multiline and depth_paren == 0 and depth_brace == 0 and depth_bracket == 0 then
			if line_ends_with_comma(text) then
				goto continue
			end

			if is_continuation_line(next_text) then
				goto continue
			end

			insert_at = lnum
			break
		end

		-- 3) One-line-looking statement with no semicolon
		if lnum == start_line and not started_multiline and compact ~= "" then
			if line_ends_with_comma(text) then
				goto continue
			end

			if is_continuation_line(next_text) then
				goto continue
			end

			insert_at = lnum
			break
		end

		::continue::
	end

	local to_insert = type(log_line) == "table" and log_line or { log_line }
	vim.api.nvim_buf_set_lines(0, insert_at, insert_at, false, to_insert)
end

local function build_rocket_log_lines(file, line_num, expr)
	local expr_lines = vim.split(expr, "\n", { plain = true })

	if #expr_lines == 1 then
		local label = expr:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		return {
			string.format("console.log(`🚀 ~ %s:%d ~ %s:`, %s);", file, line_num, label, expr),
		}
	end

	local lines = {
		"console.log(",
		string.format("  `🚀 ~ %s:%d ~", file, line_num),
	}

	for _, l in ipairs(expr_lines) do
		table.insert(lines, l)
	end

	table.insert(lines, "`:,")

	for i, l in ipairs(expr_lines) do
		if i == 1 then
			table.insert(lines, "  " .. l)
		else
			table.insert(lines, l)
		end
	end

	table.insert(lines, ");")

	return lines
end

local function get_text_from_marks(optype)
	local start_pos = vim.api.nvim_buf_get_mark(0, "[")
	local end_pos = vim.api.nvim_buf_get_mark(0, "]")
	local srow, scol = start_pos[1], start_pos[2]
	local erow, ecol = end_pos[1], end_pos[2]

	if srow == 0 or erow == 0 then
		return nil, nil, nil
	end

	local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
	if #lines == 0 then
		return nil, nil, nil
	end

	if optype == "line" then
		return table.concat(lines, "\n"), srow, erow
	end

	if #lines == 1 then
		lines[1] = string.sub(lines[1], scol + 1, ecol + 1)
	else
		lines[1] = string.sub(lines[1], scol + 1)
		lines[#lines] = string.sub(lines[#lines], 1, ecol + 1)
	end

	return table.concat(lines, "\n"), srow, erow
end

local function normalize_anchor_line(anchor_line, selection_start_line)
	local line = anchor_line or selection_start_line
	if not line or line < 1 then
		return selection_start_line
	end

	local prev = vim.fn.getline(line - 1)
	local cur = vim.fn.getline(line)

	if line > 1 and prev and cur then
		local prev_trim = prev:gsub("%s+$", "")
		local cur_trim = cur:gsub("^%s+", "")

		if prev_trim:find("{%s*$") or prev_trim:find("%(%s*$") or prev_trim:find("%[%s*$") then
			if
				not cur_trim:match("^[%w_]+%s*=")
				and not cur_trim:match("^const%s+")
				and not cur_trim:match("^let%s+")
			then
				return line - 1
			end
		end
	end

	return line
end

function M.operator(optype)
	if not is_supported_filetype() then
		vim.notify("RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
		_G.__rocket_log_anchor_line = nil
		return
	end

	local expr, selection_start_line, _ = get_text_from_marks(optype)
	if not expr or expr == "" then
		_G.__rocket_log_anchor_line = nil
		return
	end

	local file = vim.fn.expand("%:t")
	local log_lines = build_rocket_log_lines(file, selection_start_line, expr)
	local anchor_line = normalize_anchor_line(_G.__rocket_log_anchor_line, selection_start_line)

	insert_after_statement(log_lines, anchor_line)
	_G.__rocket_log_anchor_line = nil
end

-- Must be global for operatorfunc (Neovim limitation)
_G.__rocket_log_operator = function(optype)
	require("rocketlog").operator(optype)
end

function M.log_word_under_cursor()
	if not is_supported_filetype() then
		vim.notify("RocketLog: unsupported filetype '" .. vim.bo.filetype .. "'", vim.log.levels.WARN)
		return
	end

	local word = vim.fn.expand("<cword>")
	local line_num = vim.fn.line(".")
	local file = vim.fn.expand("%:t")
	local log_line = string.format("console.log(`🚀 ~ %s:%d ~ %s:`, %s);", file, line_num, word, word)
	insert_after_statement(log_line, line_num)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

	if not M.config.enabled then
		return
	end

	local km = M.config.keymaps

	if km.operator and km.operator ~= false then
		vim.keymap.set("n", km.operator, function()
			_G.__rocket_log_anchor_line = vim.fn.line(".")
			vim.o.operatorfunc = "v:lua.__rocket_log_operator"
			return "g@"
		end, { expr = true, desc = "Rocket log operator (motion/textobject)" })
	end

	if km.word and km.word ~= false then
		vim.keymap.set("n", km.word, function()
			require("rocketlog").log_word_under_cursor()
		end, { desc = "Rocket log word under cursor" })
	end

	vim.api.nvim_create_user_command("RocketLogWord", function()
		require("rocketlog").log_word_under_cursor()
	end, { desc = "Insert rocket log for word under cursor" })
end

return M
