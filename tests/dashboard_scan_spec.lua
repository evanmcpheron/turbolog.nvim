describe("rocketlog.dashboard.scan", function()
	local scan
	local config
	local tmp_path

	before_each(function()
		package.loaded["rocketlog.config"] = nil
		config = require("rocketlog.config")
		config.apply({ label = "ROCKETLOG" })

		package.loaded["rocketlog.dashboard.scan"] = nil
		scan = require("rocketlog.dashboard.scan")

		tmp_path = vim.fn.tempname() .. ".ts"
		vim.fn.writefile({
			"const a = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ a:`, a);",
			"console.warn(`🚀[ROCKETLOG] ~ test.ts:3 ~ warning:`, warning);",
		}, tmp_path)
	end)

	after_each(function()
		vim.fn.delete(tmp_path)
	end)

	it("parses RocketLog entries from file paths", function()
		local entries = scan.scan_paths({ tmp_path })

		assert.are.equal(2, #entries)
		assert.are.equal("log", entries[1].log_type)
		assert.are.equal("a", entries[1].label)
		assert.are.equal(2, entries[1].lnum)
		assert.are.equal("warn", entries[2].log_type)
		assert.are.equal("warning", entries[2].label)
		assert.is_true(entries[1].stale)
	end)

	it("parses multiline entries as a single block", function()
		vim.fn.writefile({
			"const users = [];",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~",
			"users",
			"  .filter(Boolean)`,",
			"  users,",
			");",
		}, tmp_path)

		local entries = scan.scan_paths({ tmp_path })
		assert.are.equal(1, #entries)
		assert.are.equal(2, entries[1].lnum)
		assert.are.equal(6, entries[1].end_lnum)
	end)

	it("builds a richer summary for multiline entries", function()
		vim.fn.writefile({
			"const users = [];",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~",
			"users",
			"  .filter(Boolean)",
			"  .map(formatUser)`,",
			"  users,",
			");",
		}, tmp_path)

		local entries = scan.scan_paths({ tmp_path })
		assert.are.equal(1, #entries)
		assert.are.equal("users .filter(Boolean) .map(formatUser)", entries[1].summary)
	end)

	it("detects end_lnum correctly when closing paren is not on its own line", function()
		vim.fn.writefile({
			"const obj = {};",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ obj:`,",
			"  obj);",
		}, tmp_path)

		local entries = scan.scan_paths({ tmp_path })
		assert.are.equal(1, #entries)
		assert.are.equal(2, entries[1].lnum)
		assert.are.equal(3, entries[1].end_lnum)
	end)

	it("detects end_lnum correctly when args follow the template on the closing line", function()
		vim.fn.writefile({
			"const data = {};",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~",
			"data:`,",
			"  data);",
		}, tmp_path)

		local entries = scan.scan_paths({ tmp_path })
		assert.are.equal(1, #entries)
		assert.are.equal(2, entries[1].lnum)
		assert.are.equal(4, entries[1].end_lnum)
	end)

	it("does not over-extend end_lnum past the console call", function()
		vim.fn.writefile({
			"const a = 1;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ a:`,",
			"  a);",
			"const b = 2;",
			"const c = 3;",
		}, tmp_path)

		local entries = scan.scan_paths({ tmp_path })
		assert.are.equal(1, #entries)
		assert.are.equal(2, entries[1].lnum)
		assert.are.equal(3, entries[1].end_lnum)
	end)

	it("includes commented RocketLogs and marks them disabled", function()
		vim.fn.writefile({
			"// console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ disabled:`, disabled);",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ active:`, active);",
		}, tmp_path)

		local entries = scan.scan_paths({ tmp_path })
		assert.are.equal(2, #entries)
		assert.are.equal("disabled", entries[1].label)
		assert.are.equal(1, entries[1].lnum)
		assert.is_true(entries[1].commented)
		assert.are.equal("active", entries[2].label)
		assert.are.equal(2, entries[2].lnum)
		assert.is_false(entries[2].commented)
	end)

end)
