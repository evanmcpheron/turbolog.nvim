local M = {}

local config = require("rocketlog.config")

local function escape_lua_pattern(text)
	return (text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

---Update RocketLog labels (filename + line number) in the current buffer.
---This only updates logs that match the standard RocketLog format:
---console.log(`🚀[ROCKETLOG] ~ file.ts:123 ~ label:`, ...)
---@return integer
function M.refresh_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local filename = vim.fn.expand("%:t")
	local changed = 0

	local escaped_label = escape_lua_pattern(config.get_label())
	local pattern_with_label = "(`🚀%[" .. escaped_label .. "%]%s*~%s*)[^:]+:%d+(%s*~%s*)"
	local fallback_pattern = "(`🚀%s*~%s*)[^:]+:%d+(%s*~%s*)"

	for i, line in ipairs(lines) do
		local updated_line, replacements =
			line:gsub(pattern_with_label, "%1" .. filename .. ":" .. i .. "%2", 1)

		if replacements == 0 then
			updated_line, replacements =
				line:gsub(fallback_pattern, "%1" .. filename .. ":" .. i .. "%2", 1)
		end

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
