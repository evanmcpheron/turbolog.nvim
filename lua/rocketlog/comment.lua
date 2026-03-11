local M = {}

local COMMENT_PREFIX_BY_FILETYPE = {
	javascript = "//",
	javascriptreact = "//",
	typescript = "//",
	typescriptreact = "//",
	go = "//",
	rust = "//",
	c = "//",
	cpp = "//",
	java = "//",
	kotlin = "//",
	lua = "--",
	python = "#",
	ruby = "#",
	sh = "#",
	bash = "#",
	zsh = "#",
}

local COMMENT_PREFIX_BY_EXTENSION = {
	js = "//",
	jsx = "//",
	mjs = "//",
	cjs = "//",
	ts = "//",
	tsx = "//",
	mts = "//",
	cts = "//",
	go = "//",
	rs = "//",
	c = "//",
	cc = "//",
	cpp = "//",
	cxx = "//",
	java = "//",
	kt = "//",
	kts = "//",
	lua = "--",
	py = "#",
	rb = "#",
	sh = "#",
	bash = "#",
	zsh = "#",
}

---@param path string|nil
---@return string|nil
local function extension_from_path(path)
	if not path or path == "" or path == "[No Name]" then
		return nil
	end

	local extension = vim.fn.fnamemodify(path, ":e")
	if extension == "" then
		return nil
	end

	return extension:lower()
end

---@param line_text string|nil
---@return string, string
local function split_indent(line_text)
	local indent, body = (line_text or ""):match("^(%s*)(.*)$")
	return indent or "", body or ""
end

---@param line_text string|nil
---@param insert_indent string|nil
---@return string, string
local function split_at_comment_indent(line_text, insert_indent)
	local full_indent, body = split_indent(line_text)
	if not insert_indent or insert_indent == "" then
		return full_indent, body
	end

	local insert_width = math.min(#insert_indent, #full_indent)
	return (line_text or ""):sub(1, insert_width), (line_text or ""):sub(insert_width + 1)
end

---@param lines string[]
---@return string|nil
local function shared_comment_indent(lines)
	local minimum_indent

	for _, line_text in ipairs(lines or {}) do
		if line_text:match("%S") then
			local indent = line_text:match("^(%s*)") or ""
			if not minimum_indent or #indent < #minimum_indent then
				minimum_indent = indent
			end
		end
	end

	return minimum_indent
end

---@param opts table|nil
---@return string|nil
function M.resolve_comment_prefix(opts)
	opts = opts or {}

	local filetype = opts.filetype
	if not filetype and opts.bufnr and vim.api.nvim_buf_is_valid(opts.bufnr) then
		filetype = vim.bo[opts.bufnr].filetype
	end

	if filetype and COMMENT_PREFIX_BY_FILETYPE[filetype] then
		return COMMENT_PREFIX_BY_FILETYPE[filetype]
	end

	local path = opts.path
	if (not path or path == "") and opts.bufnr and vim.api.nvim_buf_is_valid(opts.bufnr) then
		path = vim.api.nvim_buf_get_name(opts.bufnr)
	end

	local extension = extension_from_path(path)
	if extension then
		return COMMENT_PREFIX_BY_EXTENSION[extension]
	end

	return nil
end

---@param line_text string|nil
---@param opts table|nil
---@return boolean
function M.is_commented_line(line_text, opts)
	if not line_text or line_text == "" then
		return false
	end

	local comment_prefix = opts and opts.prefix or M.resolve_comment_prefix(opts)
	if not comment_prefix then
		return false
	end

	local _, body = split_indent(line_text)
	if body == "" then
		return false
	end

	return body:sub(1, #comment_prefix) == comment_prefix
end

---@param line_text string
---@param opts table|nil
---@return string|nil, string|nil
function M.comment_line(line_text, opts)
	local comment_prefix = opts and opts.prefix or M.resolve_comment_prefix(opts)
	if not comment_prefix then
		return nil, "unsupported_comment_prefix"
	end

	if not line_text:match("%S") or M.is_commented_line(line_text, { prefix = comment_prefix }) then
		return line_text, nil
	end

	local indent, body = split_at_comment_indent(line_text, opts and opts.insert_indent)
	if body == "" then
		return indent .. comment_prefix, nil
	end

	return string.format("%s%s %s", indent, comment_prefix, body), nil
end

---@param line_text string
---@param opts table|nil
---@return string|nil, string|nil
function M.uncomment_line(line_text, opts)
	local comment_prefix = opts and opts.prefix or M.resolve_comment_prefix(opts)
	if not comment_prefix then
		return nil, "unsupported_comment_prefix"
	end

	if not line_text:match("%S") or not M.is_commented_line(line_text, { prefix = comment_prefix }) then
		return line_text, nil
	end

	local indent, body = split_indent(line_text)
	body = body:sub(#comment_prefix + 1)
	if body:sub(1, 1) == " " then
		body = body:sub(2)
	end

	return indent .. body, nil
end

---@param line_text string
---@param opts table|nil
---@return string|nil, string|nil
function M.toggle_line(line_text, opts)
	local comment_prefix = opts and opts.prefix or M.resolve_comment_prefix(opts)
	if not comment_prefix then
		return nil, "unsupported_comment_prefix"
	end

	if M.is_commented_line(line_text, { prefix = comment_prefix }) then
		return M.uncomment_line(line_text, opts)
	end

	return M.comment_line(line_text, opts)
end

---@param bufnr integer
---@param start_line integer 1-based inclusive
---@param end_line integer 1-based inclusive
---@param opts table|nil
---@param line_transformer fun(line_text: string, opts: table): string|nil, string|nil
---@return boolean, string|nil
local function transform_range(bufnr, start_line, end_line, opts, line_transformer)
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		return false, "invalid_buffer"
	end

	opts = vim.tbl_extend("keep", opts or {}, { bufnr = bufnr })
	local comment_prefix = M.resolve_comment_prefix(opts)
	if not comment_prefix then
		return false, "unsupported_comment_prefix"
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
	local updated = false
	local insert_indent = (line_transformer == M.comment_line or line_transformer == M.toggle_line) and shared_comment_indent(lines) or nil

	for index, line_text in ipairs(lines) do
		if line_text:match("%S") then
			local updated_line, line_error = line_transformer(line_text, {
				prefix = comment_prefix,
				insert_indent = insert_indent,
			})
			if line_error then
				return false, line_error
			end
			if updated_line ~= line_text then
				lines[index] = updated_line
				updated = true
			end
		end
	end

	if not updated then
		return false, nil
	end

	vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)
	return true, nil
end

---@param bufnr integer
---@param start_line integer 1-based inclusive
---@param end_line integer 1-based inclusive
---@param opts table|nil
---@return boolean, string|nil
function M.comment_range(bufnr, start_line, end_line, opts)
	return transform_range(bufnr, start_line, end_line, opts, M.comment_line)
end

---@param bufnr integer
---@param start_line integer 1-based inclusive
---@param end_line integer 1-based inclusive
---@param opts table|nil
---@return boolean, string|nil
function M.uncomment_range(bufnr, start_line, end_line, opts)
	return transform_range(bufnr, start_line, end_line, opts, M.uncomment_line)
end

---@param bufnr integer
---@param start_line integer 1-based inclusive
---@param end_line integer 1-based inclusive
---@param opts table|nil
---@return boolean, string|nil
function M.toggle_range(bufnr, start_line, end_line, opts)
	return transform_range(bufnr, start_line, end_line, opts, M.toggle_line)
end

return M
