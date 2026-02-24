local M = {}

local build = require("rocketlog.build")
local config = require("rocketlog.config")

---Update RocketLog labels (filename + line number) in the current buffer.
---This only updates logs that match the RocketLog marker and include a file:line segment.
---@return integer changed_count
function M.refresh_buffer()
	if config.config and config.config.show_file_line == false then
		return 0
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local filename = vim.fn.expand("%:t")
	local changed = 0
	local marker_pattern = vim.pesc(build.get_marker())

	for i, line in ipairs(lines) do
		-- Replace only the file:line segment immediately after the RocketLog marker.
		-- This keeps the console method, variable label, and expression payload untouched.
		local updated_line, replacements =
			line:gsub("(`" .. marker_pattern .. "%s*~%s*)[^:~`]+:%d+", "%1" .. filename .. ":" .. i, 1)

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
