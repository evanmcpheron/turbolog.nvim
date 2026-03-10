local config = require("rocketlog.config")

local M = {}

local FILETYPE_BY_EXTENSION = {
	js = "javascript",
	jsx = "javascriptreact",
	mjs = "javascript",
	cjs = "javascript",
	ts = "typescript",
	tsx = "typescriptreact",
	mts = "typescript",
	cts = "typescript",
	lua = "lua",
	py = "python",
	go = "go",
	rs = "rust",
}

local function trim(text)
	return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function squeeze_spaces(text)
	return trim((text or ""):gsub("%s+", " "))
end

local function truncate(text, max_width)
	if #text <= max_width then
		return text
	end
	return text:sub(1, max_width - 1) .. "…"
end

local function path_basename(path)
	return vim.fn.fnamemodify(path, ":t")
end

local function normalize_path(path)
	if not path or path == "" then
		return "[No Name]"
	end

	if vim.fs and vim.fs.normalize then
		if path:match("^/") then
			return vim.fs.normalize(path)
		end
		return vim.fs.normalize(vim.fn.getcwd() .. "/" .. path)
	end

	if path:match("^/") then
		return path
	end
	return vim.fn.getcwd() .. "/" .. path
end

local function path_is_readable(path)
	return path ~= nil and path ~= "" and vim.fn.filereadable(path) == 1
end

local function should_skip_path(path, excluded_dirs)
	for _, dir in ipairs(excluded_dirs or {}) do
		if path:find("/" .. dir .. "/", 1, true) or path:match("/" .. dir .. "$") then
			return true
		end
	end
	return false
end

local function parse_embedded_location(line)
	local filename, line_number = line:match("~%s*([^:]+):(%d+)%s*~")
	return filename, tonumber(line_number)
end

local function is_single_line_console_call(line)
	return line:match("^%s*console%.[%a_][%w_]*%s*%b()%s*;?%s*$") ~= nil
end

local function count_char(text, needle)
	local count = 0
	for index = 1, #text do
		if text:sub(index, index) == needle then
			count = count + 1
		end
	end
	return count
end

local function collect_log_block(lines, start_line_number)
	local first_line = lines[start_line_number]
	local block_lines = { first_line }
	local end_line_number = start_line_number

	if is_single_line_console_call(first_line) then
		return block_lines, end_line_number
	end

	local template_closed = first_line:match("`.*`") ~= nil
	local paren_depth = count_char(first_line, "(") - count_char(first_line, ")")

	while end_line_number < #lines do
		end_line_number = end_line_number + 1
		local next_line = lines[end_line_number]
		table.insert(block_lines, next_line)

		if not template_closed and next_line:find("`", 1, true) then
			template_closed = true
		end

		paren_depth = paren_depth + count_char(next_line, "(") - count_char(next_line, ")")
		if template_closed and paren_depth <= 0 then
			break
		end
	end

	return block_lines, end_line_number
end

local function extract_multiline_expression(block_lines)
	if #block_lines <= 1 then
		return nil
	end

	local summary_pieces = {}
	for index, line in ipairs(block_lines) do
		local chunk = index == 1 and (line:match("~%s*[^:]+:%d+%s*~%s*(.*)$") or "") or line
		local before_tick = chunk:match("^(.-)`")
		if before_tick ~= nil then
			chunk = squeeze_spaces(before_tick)
			if chunk ~= "" and chunk ~= "," and chunk ~= ");" then
				table.insert(summary_pieces, chunk)
			end
			break
		end

		chunk = squeeze_spaces(chunk)
		if chunk ~= "" and chunk ~= "," and chunk ~= ");" then
			table.insert(summary_pieces, chunk)
		end
	end

	local summary = squeeze_spaces(table.concat(summary_pieces, " ")):gsub(",$", "")
	if summary == "" then
		return nil
	end
	return truncate(summary, 84)
end

local function parse_label(first_line, block_lines)
	local inline_label = first_line:match("~%s*[^:]+:%d+%s*~%s*(.-):`")
	if inline_label and inline_label ~= "" then
		return inline_label
	end

	return extract_multiline_expression(block_lines) or "<multiline>"
end

local function detect_filetype_from_path(path)
	return FILETYPE_BY_EXTENSION[vim.fn.fnamemodify(path, ":e")] or "text"
end

---@param lines string[]
---@param source table
---@return table[]
function M.parse_lines(lines, source)
	local entries = {}
	local marker = config.get_marker()
	local source_path = source.path or "[No Name]"
	local source_filename = path_basename(source_path)
	local line_number = 1

	while line_number <= #lines do
		local line = lines[line_number]
		if line and line:find(marker, 1, true) then
			local block_lines, end_line_number = collect_log_block(lines, line_number)
			local embedded_filename, embedded_line = parse_embedded_location(line)
			local label = parse_label(line, block_lines)
			local is_stale = embedded_filename and embedded_line and (embedded_filename ~= source_filename or embedded_line ~= line_number) or false

			table.insert(entries, {
				id = string.format("%s:%d:%d", source_path, line_number, end_line_number),
				path = source_path,
				filename = source_filename,
				lnum = line_number,
				end_lnum = end_line_number,
				log_type = line:match("^%s*console%.([%a_][%w_]*)%s*%(") or "log",
				label = label,
				summary = label,
				text = table.concat(block_lines, "\n"),
				marker = marker,
				stale = is_stale,
				bufnr = source.bufnr,
				filetype = detect_filetype_from_path(source_path),
			})

			line_number = end_line_number + 1
		else
			line_number = line_number + 1
		end
	end

	return entries
end

local function scan_loaded_buffers()
	local results = {}
	local seen_paths = {}
	local allowed_filetypes = config.config.allowed_filetypes or {}

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
			local path = vim.api.nvim_buf_get_name(bufnr)
			local filetype = vim.bo[bufnr].filetype
			if allowed_filetypes[filetype] and path ~= "" then
				local normalized_path = normalize_path(path)
				results[normalized_path] = M.parse_lines(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
					path = normalized_path,
					bufnr = bufnr,
				})
				seen_paths[normalized_path] = true
			end
		end
	end

	return results, seen_paths
end

local function rg_project_paths(cwd)
	if vim.fn.executable("rg") ~= 1 then
		return nil
	end

	local output = vim.fn.systemlist({ "rg", "-l", "-F", config.get_marker(), cwd })
	if vim.v.shell_error == 1 then
		return {}
	end
	if vim.v.shell_error ~= 0 then
		return nil
	end

	local paths = {}
	for _, path in ipairs(output) do
		if path ~= "" then
			if not path:match("^/") then
				path = normalize_path(cwd .. "/" .. path)
			else
				path = normalize_path(path)
			end
			table.insert(paths, path)
		end
	end

	return paths
end

local function glob_project_paths(cwd)
	local paths = {}
	for extension in pairs(config.get_allowed_extensions()) do
		for _, path in ipairs(vim.fn.globpath(cwd, "**/*." .. extension, false, true)) do
			table.insert(paths, normalize_path(path))
		end
	end
	return paths
end

local function collect_project_paths(cwd, seen_paths)
	local dashboard_config = config.config.dashboard or {}
	local excluded_dirs = dashboard_config.excluded_dirs or {}
	local max_files = dashboard_config.max_files or 2000
	local discovered_paths = rg_project_paths(cwd) or glob_project_paths(cwd)
	local unique_paths = {}
	local seen = {}

	for _, path in ipairs(discovered_paths) do
		local normalized_path = normalize_path(path)
		if not seen[normalized_path] and not seen_paths[normalized_path] and path_is_readable(normalized_path) and not should_skip_path(normalized_path, excluded_dirs) then
			table.insert(unique_paths, normalized_path)
			seen[normalized_path] = true
			if #unique_paths >= max_files then
				break
			end
		end
	end

	return unique_paths
end

---@param paths string[]
---@return table[]
function M.scan_paths(paths)
	local entries = {}
	for _, path in ipairs(paths) do
		if path_is_readable(path) then
			local normalized_path = normalize_path(path)
			for _, entry in ipairs(M.parse_lines(vim.fn.readfile(normalized_path), { path = normalized_path })) do
				table.insert(entries, entry)
			end
		end
	end
	return entries
end

local function collect_entries_for_scope(state)
	if state.scope == "current_file" then
		if state.source_bufnr and vim.api.nvim_buf_is_valid(state.source_bufnr) then
			return M.parse_lines(vim.api.nvim_buf_get_lines(state.source_bufnr, 0, -1, false), {
				path = normalize_path(vim.api.nvim_buf_get_name(state.source_bufnr)),
				bufnr = state.source_bufnr,
			})
		end
		if state.source_path and path_is_readable(state.source_path) then
			return M.scan_paths({ state.source_path })
		end
		return {}
	end

	local entries = {}
	local buffered_entries, seen_paths = scan_loaded_buffers()
	for _, file_entries in pairs(buffered_entries) do
		for _, entry in ipairs(file_entries) do
			table.insert(entries, entry)
		end
	end
	for _, entry in ipairs(M.scan_paths(collect_project_paths(state.cwd, seen_paths))) do
		table.insert(entries, entry)
	end
	return entries
end

local function entry_matches_filter(entry, filter_text)
	if filter_text == "" then
		return true
	end

	local searchable_text = table.concat({
		entry.path,
		entry.filename,
		entry.label,
		entry.summary or "",
		entry.log_type,
		entry.text,
	}, " "):lower()

	return searchable_text:find(filter_text:lower(), 1, true) ~= nil
end

---@param state table
---@return table[]
function M.collect_groups(state)
	local grouped = {}
	for _, entry in ipairs(collect_entries_for_scope(state)) do
		if entry_matches_filter(entry, state.filter or "") then
			grouped[entry.path] = grouped[entry.path] or {
				path = entry.path,
				filename = entry.filename,
				entries = {},
				count = 0,
			}
			table.insert(grouped[entry.path].entries, entry)
		end
	end

	local groups = {}
	for _, group in pairs(grouped) do
		table.sort(group.entries, function(left, right)
			if left.lnum == right.lnum then
				return left.id < right.id
			end
			return left.lnum < right.lnum
		end)
		group.count = #group.entries
		table.insert(groups, group)
	end

	table.sort(groups, function(left, right)
		return left.path < right.path
	end)

	state.groups = groups
	return groups
end

return M
