describe("rocketlog.config", function()
	local config

	before_each(function()
		package.loaded["rocketlog.config"] = nil
		config = require("rocketlog.config")
	end)

	it("returns defaults when apply is called with nil", function()
		local applied = config.apply(nil)
		assert.are.same(config.defaults, applied)
	end)

	it("returns defaults when apply is called with an empty table", function()
		local applied = config.apply({})
		assert.are.same(config.defaults, applied)
	end)

	it("overrides top-level config values", function()
		local applied = config.apply({
			enabled = false,
			label = "MYLABEL",
			prefer_treesitter = false,
		})

		assert.is_false(applied.enabled)
		assert.are.equal("MYLABEL", applied.label)
		assert.is_false(applied.prefer_treesitter)
	end)

	it("deep merges nested keymaps", function()
		local applied = config.apply({
			keymaps = {
				operator = "gL",
			},
		})

		assert.are.equal("gL", applied.keymaps.operator)
		-- Unspecified keymaps should remain at their defaults.
		assert.are.equal(config.defaults.keymaps.word, applied.keymaps.word)
		assert.are.equal(config.defaults.keymaps.delete_above, applied.keymaps.delete_above)
	end)

	it("does not mutate defaults when applying user config", function()
		local original_defaults = vim.deepcopy(config.defaults)

		config.apply({
			keymaps = { operator = "ZZ" },
			allowed_filetypes = { typescript = false },
		})

		assert.are.same(original_defaults, config.defaults)
	end)

	it("preserves unspecified nested defaults during merge", function()
		local applied = config.apply({
			keymaps = {
				delete_all_buffer = "<leader>XX",
			},
		})

		assert.are.equal("<leader>XX", applied.keymaps.delete_all_buffer)
		assert.are.equal(config.defaults.keymaps.operator, applied.keymaps.operator)
	end)

	it("overrides boolean flags like refresh_on_save", function()
		local applied = config.apply({ refresh_on_save = false })
		assert.is_false(applied.refresh_on_save)
	end)

	it("overrides boolean flags like refresh_on_insert", function()
		local applied = config.apply({ refresh_on_insert = false })
		assert.is_false(applied.refresh_on_insert)
	end)

	it("overrides allowed_filetypes entries", function()
		local applied = config.apply({
			allowed_filetypes = {
				typescript = false,
				lua = true,
			},
		})

		-- Deep-merge should override the specified entries.
		assert.is_false(applied.allowed_filetypes.typescript)
		assert.is_true(applied.allowed_filetypes.lua)
		-- And preserve unspecified defaults.
		assert.is_true(applied.allowed_filetypes.javascript)
	end)

	it("accepts a custom label", function()
		local applied = config.apply({ label = "X" })
		assert.are.equal("X", applied.label)
	end)
end)
