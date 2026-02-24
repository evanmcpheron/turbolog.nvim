local M = {}

---@class RocketLogKeymapsConfig
---@field operator string|false
---@field word string|false
---@field error_operator string|false
---@field error_word string|false
---@field find string|false

---@class RocketLogConfig
---@field keymaps RocketLogKeymapsConfig
---@field enabled boolean
---@field refresh_on_save boolean
---@field refresh_on_insert boolean
---@field prefer_treesitter boolean
---@field fallback_to_heuristics boolean
---@field default_console_method string
---@field show_file_line boolean
---@field show_variable_name boolean
---@field allowed_filetypes table<string, boolean>|nil

-- Default plugin configuration.
---@type RocketLogConfig

M.defaults = {
	keymaps = {
		operator = "<leader>rl",
		word = "<leader>rr",
		error_operator = "<leader>re",
		error_word = "<leader>rE",
		warn_operator = "<leader>rw",
		warn_word = "<leader>rW",
		delete_below = "<leader>rdd",
		delete_above = "<leader>rdD",
		delete_all = "<leader>rda",
		delete_all_in_file = "<leader>rdf",
		find = "<leader>rf",
	},
	enabled = true,
	localfresh_on_save = true,
	refresh_on_insert = true,
	prefer_treesitter = true,
	fallback_to_heuristics = true,
	default_console_method = "log",
	show_file_line = true,
	show_variable_name = true,
	allowed_filetypes = {
		javascript = true,
		javascriptreact = true,
		typescript = true,
		typescriptreact = true,
	},
}

-- Active runtime config (starts as a deepcopy of defaults).
---@type RocketLogConfig
M.config = vim.deepcopy(M.defaults)

---Merge user config over defaults.
---@param opts table|nil
---@return RocketLogConfig
function M.apply(opts)
	M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
	return M.config
end

return M
