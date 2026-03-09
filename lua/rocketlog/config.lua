local M = {}

---Trim leading/trailing whitespace from a string.
---@param text string
---@return string
local function trim(text)
	return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

---Normalize a user-provided RocketLog label into a safe single-line string.
---@param label any
---@return string
function M.normalize_label(label)
	if label == nil then
		return "ROCKETLOG"
	end

	local normalized = tostring(label)
	normalized = normalized:gsub("[%c]+", " ")
	normalized = normalized:gsub("%s+", " ")
	normalized = trim(normalized)

	if normalized == "" then
		return "ROCKETLOG"
	end

	return normalized
end

-- Default plugin configuration
M.defaults = {
	keymaps = {
		motions = "<leader>rl",
		word = "<leader>rL",
		error_motions = "<leader>re",
		error_word = "<leader>rE",
		warn_motions = "<leader>rw",
		warn_word = "<leader>rW",
		info_motions = "<leader>ri",
		info_word = "<leader>rI",
		delete_below = "<leader>rd",
		delete_above = "<leader>rD",
		delete_all_buffer = "<leader>ra",
		find = "<leader>rf",
	},
	label = "ROCKETLOG",
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

---Get the active RocketLog label with fallback to defaults.
---@return string
function M.get_label()
	local active_label = M.config and M.config.label or M.defaults.label
	return M.normalize_label(active_label)
end

---Get the exact marker prefix used in generated logs.
---@return string
function M.get_marker()
	return "🚀[" .. M.get_label() .. "]"
end

---Merge user config over defaults.
---@param opts table|nil
function M.apply(opts)
	local merged = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
	merged.label = M.normalize_label(merged.label)
	M.config = merged
	return M.config
end

return M
