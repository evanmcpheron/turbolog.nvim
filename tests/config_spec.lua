describe("rocketlog.config", function()
	local config

	before_each(function()
		package.loaded["rocketlog.config"] = nil
		config = require("rocketlog.config")
	end)

	it("applies nested keymap overrides without dropping defaults", function()
		local applied = config.apply({
			keymaps = {
				motions = "gm",
			},
		})

		assert.are.equal("gm", applied.keymaps.motions)
		assert.are.equal(config.defaults.keymaps.word, applied.keymaps.word)
		assert.are.equal(config.defaults.keymaps.delete_above, applied.keymaps.delete_above)
	end)

	it("does not mutate defaults when applying user config", function()
		local original_defaults = vim.deepcopy(config.defaults)

		config.apply({
			keymaps = { motions = "ZZ" },
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
		assert.are.equal(config.defaults.keymaps.motions, applied.keymaps.motions)
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

		assert.is_false(applied.allowed_filetypes.typescript)
		assert.is_true(applied.allowed_filetypes.lua)
		assert.is_true(applied.allowed_filetypes.javascript)
	end)

	it("accepts a custom label", function()
		local applied = config.apply({ label = "X" })
		assert.are.equal("X", applied.label)
		assert.are.equal("X", config.get_label())
	end)

	it("normalizes blank or multi-line labels", function()
		local applied = config.apply({ label = "  first\nsecond  " })
		assert.are.equal("first second", applied.label)
		assert.are.equal("first second", config.get_label())
	end)
end)
