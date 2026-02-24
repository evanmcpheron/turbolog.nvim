local M = {}

local config = require("rocketlog.config")

---Check whether the current buffer filetype is allowed by plugin config.
---If `allowed_filetypes` is nil, all filetypes are accepted.
---@return boolean
function M.is_supported_filetype()
	local current_filetype = vim.bo.filetype
	return config.config.allowed_filetypes == nil or config.config.allowed_filetypes[current_filetype] == true
end

return M
