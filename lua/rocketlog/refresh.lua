local M = {}

---Update RocketLog labels (filename + line number) in the current buffer.
---This only updates logs that match the standard RocketLog format:
---console.log(`🚀[ROCKETLOG] ~ file.ts:123 ~ label:`, ...)
function M.refresh_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local filename = vim.fn.expand("%:t")
	local changed = 0

	for i, line in ipairs(lines) do
		-- Match the RocketLog prefix inside a template string:
		-- `🚀[ROCKETLOG] ~ something.ts:123 ~
		--
		-- Capture groups:
		-- 1) everything before filename+line inside the template string
		-- 2) the "label and rest" after " ~ "
		--
		-- We replace only the file:line part.
		local updated_line, replacements =
			line:gsub("(`🚀%[ROCKETLOG%]%s*~%s*)[^:]+:%d+(%s*~%s*)", "%1" .. filename .. ":" .. i .. "%2", 1)

		if replacements == 0 then
			updated_line, replacements =
				line:gsub("(`🚀%s*~%s*)[^:]+:%d+(%s*~%s*)", "%1" .. filename .. ":" .. i .. "%2", 1)
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
