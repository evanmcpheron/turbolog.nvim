local M = {}

---Update RocketLog labels (filename + line number) in the current buffer.
---This only updates logs that match the standard RocketLog format:
---console.log(`🚀 ~ file.ts:123 ~ label:`, ...)
---@return integer changed_count
function M.refresh_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local filename = vim.fn.expand("%:t")
	local changed = 0

	for i, line in ipairs(lines) do
		-- Match the RocketLog prefix inside a template string and only replace the
		-- file:line portion so the original label text and expression stay intact.
		local updated_line, replacements =
			line:gsub("(`🚀%s*~%s*)[^:]+:%d+(%s*~%s*)", "%1" .. filename .. ":" .. i .. "%2", 1)

		if replacements > 0 and updated_line ~= line then
			lines[i] = updated_line
			changed = changed + 1
		end
	end

	if changed > 0 then
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	end

	return changed
end

return M
