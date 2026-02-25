local M = {}

-- Monotonic counter used to generate unique buffer names across tests.
-- This avoids:
--   - E95 (buffer name already exists)
--   - swapfile prompts (E325) when using real filesystem-looking names
local _name_counter = 0

---@param base_name string|nil
---@return string
local function next_bufname(base_name)
	_name_counter = _name_counter + 1
	local base = base_name or "test.ts"

	-- Custom scheme prevents Neovim from treating it like a real file,
	-- but keeps the tail (test.ts) so `%:t` behaves normally.
	return string.format("rocketlog://%d/%s", _name_counter, base)
end

---Set the current buffer's lines, filetype, and optional name.
---@param lines string[]
---@param opts table|nil { filetype?: string, name?: string }
---@return integer bufnr
function M.set_buffer(lines, opts)
	opts = opts or {}

	-- Delete the previous scratch buffer so names never collide.
	if M._last_bufnr and vim.api.nvim_buf_is_valid(M._last_bufnr) then
		pcall(vim.api.nvim_buf_delete, M._last_bufnr, { force = true })
	end

	-- Create a scratch buffer (no swapfile, no disk IO).
	local bufnr = vim.api.nvim_create_buf(false, true)
	M._last_bufnr = bufnr
	vim.api.nvim_set_current_buf(bufnr)

	vim.bo[bufnr].buftype = "nofile"
	vim.bo[bufnr].bufhidden = "wipe"
	vim.bo[bufnr].swapfile = false
	vim.bo[bufnr].undofile = false
	vim.bo[bufnr].modifiable = true

	if opts.filetype then
		vim.bo[bufnr].filetype = opts.filetype
	end

	vim.api.nvim_buf_set_name(bufnr, next_bufname(opts.name))
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

	return bufnr
end

---Get all current buffer lines.
---@return string[]
function M.get_lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

---Set the cursor to a 1-based {line, col0}.
---@param line integer
---@param col0 integer
function M.set_cursor(line, col0)
	vim.api.nvim_win_set_cursor(0, { line, col0 })
end

---Temporarily replace a table field and return a restore function.
---@generic T
---@param tbl T
---@param key any
---@param value any
---@return fun()
function M.stub(tbl, key, value)
	local original = tbl[key]
	tbl[key] = value
	return function()
		tbl[key] = original
	end
end

---Create a simple spy wrapper that records calls.
---@param fn function|nil
---@return function wrapper, table calls
function M.spy(fn)
	local calls = {}
	local function wrapper(...)
		table.insert(calls, { ... })
		if fn then
			return fn(...)
		end
	end
	return wrapper, calls
end

---Capture vim.notify calls during a test.
---@return fun() restore, table messages
function M.capture_notify()
	local messages = {}
	local restore = M.stub(vim, "notify", function(msg, level)
		table.insert(messages, { msg = msg, level = level })
	end)
	return restore, messages
end

---Set Neovim's '[' and ']' marks for selection tests.
---@param start_line integer
---@param start_col integer
---@param end_line integer
---@param end_col integer
function M.set_operator_marks(start_line, start_col, end_line, end_col)
	-- `nvim_buf_set_mark` expects 1-based line, 0-based col.
	vim.api.nvim_buf_set_mark(0, "[", start_line, start_col, {})
	vim.api.nvim_buf_set_mark(0, "]", end_line, end_col, {})
end

return M
