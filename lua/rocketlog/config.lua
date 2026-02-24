local M = {}

---@class RocketLogKeymapsConfig
---@field operator string|false
---@field word string|false
---@field error_operator string|false
---@field error_word string|false

---@class RocketLogConfig
---@field keymaps RocketLogKeymapsConfig
---@field enabled boolean
---@field refresh_on_save boolean
---@field refresh_on_insert boolean
---@field prefer_treesitter boolean
---@field fallback_to_heuristics boolean
---@field allowed_filetypes table<string, boolean>|nil

-- Default plugin configuration.
---@type RocketLogConfig
M.defaults = {
	keymaps = {
		operator = "<leader>cl",
		word = "<leader>cL",
		error_operator = "<leader>ce",
		error_word = "<leader>cE",
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
