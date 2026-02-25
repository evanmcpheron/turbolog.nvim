describe("rocketlog.guards", function()
	local guards
	local config

	before_each(function()
		vim.cmd("enew!")
		package.loaded["rocketlog.config"] = nil
		config = require("rocketlog.config")
		config.apply(nil)

		package.loaded["rocketlog.guards"] = nil
		guards = require("rocketlog.guards")
	end)

	after_each(function()
		pcall(vim.cmd, "bwipeout!")
	end)

	it("returns true for supported filetypes", function()
		vim.bo.filetype = "typescript"
		config.config.allowed_filetypes = { typescript = true }
		assert.is_true(guards.is_supported_filetype())
	end)

	it("returns false for unsupported filetypes", function()
		vim.bo.filetype = "lua"
		config.config.allowed_filetypes = { typescript = true }
		assert.is_false(guards.is_supported_filetype())
	end)

	it("allows all filetypes when allowed_filetypes is nil if supported", function()
		vim.bo.filetype = "lua"
		config.config.allowed_filetypes = nil
		assert.is_true(guards.is_supported_filetype())
	end)

	it("handles empty allowed_filetypes tables predictably", function()
		vim.bo.filetype = "typescript"
		config.config.allowed_filetypes = {}
		assert.is_false(guards.is_supported_filetype())
	end)
end)
