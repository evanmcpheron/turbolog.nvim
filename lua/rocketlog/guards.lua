local M = {}

local config = require("rocketlog.config")

---Checks whether the current buffer filetype is allowed.
---@return boolean
function M.is_supported_filetype()
	local current_filetype = vim.bo.filetype
	return config.config.allowed_filetypes == nil or config.config.allowed_filetypes[current_filetype] == true
end

return M
