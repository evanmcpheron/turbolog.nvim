local h = require("tests.helpers")

describe("rocketlog.refresh", function()
	local refresh

	before_each(function()
		_G.RocketLogs = {
			config = {
				label = "ROCKETLOG",
				refresh_on_save = true,
			},
		}

		h.set_buffer({}, { filetype = "typescript", name = "/tmp/test-file.ts" })

		package.loaded["rocketlog.refresh"] = nil
		refresh = require("rocketlog.refresh")
	end)

	after_each(function()
		pcall(vim.cmd, "bwipeout!")
	end)

	it("refreshes RocketLog line numbers in a simple file", function()
		h.set_buffer({
			"const x = 1;",
			"console.log(`🚀[ROCKETLOG] ~ wrong.ts:999 ~ x:`, x);",
			"const y = 2;",
		}, { filetype = "typescript", name = "/tmp/test-file.ts" })

		local changed = refresh.refresh_buffer()
		local lines = h.get_lines()

		assert.are.equal(1, changed)
		assert.are.equal("console.log(`🚀[ROCKETLOG] ~ test-file.ts:2 ~ x:`, x);", lines[2])
	end)

	it("updates only RocketLog lines and preserves other code", function()
		h.set_buffer({
			"const x = 1;",
			"console.log('not rocketlog');",
			"console.log(`🚀[ROCKETLOG] ~ wrong.ts:1 ~ x:`, x);",
			"const y = 2;",
		}, { filetype = "typescript", name = "/tmp/test-file.ts" })

		refresh.refresh_buffer()
		local lines = h.get_lines()

		assert.are.equal("console.log('not rocketlog');", lines[2])
		assert.are.equal("console.log(`🚀[ROCKETLOG] ~ test-file.ts:3 ~ x:`, x);", lines[3])
	end)

	it("handles files with no RocketLogs without changes", function()
		h.set_buffer({
			"const x = 1;",
			"console.log('no marker here');",
		}, { filetype = "typescript", name = "/tmp/test-file.ts" })

		local before = h.get_lines()
		local changed = refresh.refresh_buffer()
		local after = h.get_lines()

		assert.are.equal(0, changed)
		assert.are.same(before, after)
	end)

	it("refreshes multiple RocketLogs in the same buffer", function()
		h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ wrong.ts:999 ~ a:`, a);",
			"console.log(`🚀[ROCKETLOG] ~ wrong.ts:999 ~ b:`, b);",
			"console.log(`🚀[ROCKETLOG] ~ wrong.ts:999 ~ c:`, c);",
		}, { filetype = "typescript", name = "/tmp/test-file.ts" })

		local changed = refresh.refresh_buffer()
		local lines = h.get_lines()

		assert.are.equal(3, changed)
		assert.is_true(lines[1]:find("test-file.ts:1", 1, true) ~= nil)
		assert.is_true(lines[2]:find("test-file.ts:2", 1, true) ~= nil)
		assert.is_true(lines[3]:find("test-file.ts:3", 1, true) ~= nil)
	end)

	it("updates multiline RocketLog blocks if supported", function()
		-- Only the first line of the multiline block includes the label marker.
		h.set_buffer({
			"const x = 1;",
			"console.log(`🚀[ROCKETLOG] ~ wrong.ts:999 ~",
			"x",
			"`,",
			"  x",
			");",
			"const y = 2;",
		}, { filetype = "typescript", name = "/tmp/test-file.ts" })

		local changed = refresh.refresh_buffer()
		local lines = h.get_lines()

		assert.are.equal(1, changed)
		assert.are.equal("console.log(`🚀[ROCKETLOG] ~ test-file.ts:2 ~", lines[2])
	end)

	it("uses current buffer filename when rebuilding labels", function()
		h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ wrong.ts:1 ~ x:`, x);",
		}, { filetype = "typescript", name = "/tmp/my-file.ts" })

		refresh.refresh_buffer()
		local lines = h.get_lines()
		assert.is_true(lines[1]:find("my-file.ts:1", 1, true) ~= nil)
	end)

	it("respects configured label when refreshing", function()
		_G.RocketLogs.config.label = "MYLABEL"
		h.set_buffer({
			"console.log(`🚀[MYLABEL] ~ wrong.ts:10 ~ x:`, x);",
		}, { filetype = "typescript", name = "/tmp/test-file.ts" })

		refresh.refresh_buffer()
		local lines = h.get_lines()
		assert.are.equal("console.log(`🚀[MYLABEL] ~ test-file.ts:1 ~ x:`, x);", lines[1])
	end)
end)
