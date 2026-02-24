local M = {}

-- Default plugin configuration
M.defaults = {
	keymaps = {
		operator = "<leader>rl",
		word = "<leader>rL",
		error_operator = "<leader>re",
		error_word = "<leader>rE",
		delete_below = "<leader>rd",
		delete_above = "<leader>rD",
		delete_all_buffer = "<leader>ra",
	},
	enabled = true,
	refresh_on_save = true,
	refresh_on_insert = true,
	prefer_treesitter = true,
	fallback_to_heuristics = true,
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
