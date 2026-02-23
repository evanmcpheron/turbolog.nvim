local M = {}

-- Default plugin configuration
M.defaults = {
	keymaps = {
		operator = "<leader>cl",
		word = "<leader>cL",
	},
	enabled = true,
	refresh_on_save = true,
	refresh_on_insert = true,
	allowed_filetypes = {
		javascript = true,
		javascriptreact = true,
		typescript = true,
		typescriptreact = true,
	},
}

-- Active runtime config (starts as a deepcopy of defaults)
M.config = vim.deepcopy(M.defaults)

---Merge user config over defaults.
---@param opts table|nil
function M.apply(opts)
	M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
	return M.config
end

return M
