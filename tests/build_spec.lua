describe("rocketlog.build", function()
	local build
	local config

	before_each(function()
		_G.RocketLogs = {}
		package.loaded["rocketlog.config"] = nil
		config = require("rocketlog.config")
		config.apply({ label = "ROCKETLOG" })

		package.loaded["rocketlog.build"] = nil
		build = require("rocketlog.build")
	end)

	it("builds a single-line console.log", function()
		local lines = build.build_rocket_log_lines("test.ts", 12, "user.name", "log")

		assert.are.same({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:12 ~ user.name:`, user.name);",
		}, lines)
	end)

	it("builds a single-line console.error", function()
		local lines = build.build_rocket_log_lines("test.ts", 20, "err", "error")

		assert.are.same({
			"console.error(`🚀[ROCKETLOG] ~ test.ts:20 ~ err:`, err);",
		}, lines)
	end)

	it("builds a single-line console.warn", function()
		local lines = build.build_rocket_log_lines("test.ts", 20, "warning", "warn")

		assert.are.same({
			"console.warn(`🚀[ROCKETLOG] ~ test.ts:20 ~ warning:`, warning);",
		}, lines)
	end)

	it("builds a single-line console.info", function()
		local lines = build.build_rocket_log_lines("test.ts", 20, "user.info", "info")

		assert.are.same({
			"console.info(`🚀[ROCKETLOG] ~ test.ts:20 ~ user.info:`, user.info);",
		}, lines)
	end)

	it("builds multiline output for multiline expressions", function()
		local expr = "users\n  .filter(Boolean)\n  .map(function(x) return x end)"
		local lines = build.build_rocket_log_lines("test.ts", 99, expr, "log")

		assert.is_true(#lines > 3)
		assert.is_true(lines[1]:match("^console%.log%(") ~= nil)
		assert.is_true(lines[#lines] == ");")
	end)

	it("builds exact multiline output shape for a known expression", function()
		local expr = "users\n  .filter(Boolean)\n  .map((x) => return x)"
		local lines = build.build_rocket_log_lines("test.ts", 99, expr, "log")
		local expected = {
			"console.log(`🚀[ROCKETLOG] ~ test.ts:99 ~",
			"users",
			"  .filter(Boolean)",
			"  .map((x) => return x)`,",
			"  users",
			"    .filter(Boolean)",
			"    .map((x) => return x)",
			");",
		}

		assert.are.same(expected, lines)
	end)

	it("escapes backticks in labels", function()
		local expr = "`weird`"
		local lines = build.build_rocket_log_lines("test.ts", 1, expr, "log")

		assert.is_true(lines[1]:find("~ \\`weird\\`:", 1, true) ~= nil)
	end)

	it("escapes template interpolation markers in labels", function()
		local expr = "${danger}"
		local lines = build.build_rocket_log_lines("test.ts", 1, expr, "log")

		assert.is_true(lines[1]:find("~ \\${danger}:", 1, true) ~= nil)
	end)

	it("escapes backslashes in labels", function()
		local expr = "path\\to\\file"
		local lines = build.build_rocket_log_lines("test.ts", 1, expr, "log")

		assert.is_true(lines[1]:find("~ path\\\\to\\\\file:", 1, true) ~= nil)
	end)

	it("uses configured label in output", function()
		config.apply({ label = "MYLABEL" })
		local lines = build.build_rocket_log_lines("test.ts", 1, "x", "log")
		assert.are.same({ "console.log(`🚀[MYLABEL] ~ test.ts:1 ~ x:`, x);" }, lines)
	end)

	it("escapes dangerous characters in the configured label", function()
		config.apply({ label = "`${boom}`" })
		local lines = build.build_rocket_log_lines("test.ts", 1, "x", "log")
		assert.are.same({ "console.log(`🚀[\\`\\${boom}\\`] ~ test.ts:1 ~ x:`, x);" }, lines)
	end)

	it("falls back safely when log type is omitted", function()
		local lines = build.build_rocket_log_lines("test.ts", 1, "x")
		assert.are.same({ "console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);" }, lines)
	end)

	it("handles arbitrary/unknown console methods if supported", function()
		local lines = build.build_rocket_log_lines("test.ts", 1, "x", "debug")
		assert.are.same({ "console.debug(`🚀[ROCKETLOG] ~ test.ts:1 ~ x:`, x);" }, lines)
	end)

	it("preserves expression text in the second argument", function()
		local expr = "user  .  name"
		local lines = build.build_rocket_log_lines("test.ts", 1, expr, "log")

		assert.is_true(lines[1]:find("~ user . name:", 1, true) ~= nil)
		assert.is_true(lines[1]:find(", " .. expr .. ");", 1, true) ~= nil)
	end)

	it("normalizes label text for weird spacing if intended", function()
		local single = build.build_rocket_log_lines("test.ts", 1, "  a\t\t+  b ", "log")[1]
		assert.is_true(single:find("~ a + b:", 1, true) ~= nil)
	end)
end)
