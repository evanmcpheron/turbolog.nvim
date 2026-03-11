local M = {}

local DEFAULT_LABEL = "ROCKETLOG"

local EXTENSIONS_BY_FILETYPE = {
	javascript = { "js", "mjs", "cjs" },
	javascriptreact = { "jsx" },
	typescript = { "ts", "mts", "cts" },
	typescriptreact = { "tsx" },
	lua = { "lua" },
	python = { "py" },
	go = { "go" },
	rust = { "rs" },
}

local function trim(text)
	return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function collapse_whitespace(text)
	return trim((text or ""):gsub("[%c]+", " "):gsub("%s+", " "))
end

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
		dashboard = "<leader>rr",
	},
	label = DEFAULT_LABEL,
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
	dashboard = {
		width = 0.96,
		height = 0.92,
		preview_context = 4,
		max_files = 2000,
		excluded_dirs = {
			".git",
			"node_modules",
			"dist",
			"build",
			"coverage",
			".next",
			".turbo",
		},
	},
}

M.config = vim.deepcopy(M.defaults)

---@param label any
---@return string
function M.normalize_label(label)
	if label == nil then
		return DEFAULT_LABEL
	end

	local normalized = collapse_whitespace(tostring(label))
	if normalized == "" then
		return DEFAULT_LABEL
	end

	return normalized
end

---@return string
function M.get_label()
	return M.normalize_label(M.config.label)
end

---@return string
function M.get_marker()
	return "🚀[" .. M.get_label() .. "]"
end

---@return table<string, boolean>
function M.get_allowed_extensions()
	local allowed_extensions = {}

	for filetype, enabled in pairs(M.config.allowed_filetypes or {}) do
		if enabled and EXTENSIONS_BY_FILETYPE[filetype] then
			for _, extension in ipairs(EXTENSIONS_BY_FILETYPE[filetype]) do
				allowed_extensions[extension] = true
			end
		end
	end

	return allowed_extensions
end

---@param opts table|nil
---@return table
function M.apply(opts)
	M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
	M.config.label = M.normalize_label(M.config.label)
	return M.config
end

return M
