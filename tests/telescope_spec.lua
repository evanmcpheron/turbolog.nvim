local h = require("tests.helpers")

describe("rocketlog.telescope", function()
	local telescope_mod
	local config

	before_each(function()
		_G.RocketLogs = {}
		package.loaded["rocketlog.config"] = nil
		config = require("rocketlog.config")
		config.apply({ label = "ROCKETLOG" })

		package.loaded["rocketlog.telescope"] = nil
		telescope_mod = require("rocketlog.telescope")
	end)

	it("loads without error", function()
		assert.is_true(type(telescope_mod.find_logs) == "function")
	end)

	it("handles missing picker dependency gracefully", function()
		package.loaded["snacks"] = nil
		package.preload["snacks"] = nil

		local restore_notify, messages = h.capture_notify()

		telescope_mod.find_logs()

		restore_notify()

		assert.is_true(#messages >= 1)
		assert.is_true(messages[1].msg:find("snacks.nvim picker is not available", 1, true) ~= nil)
	end)

	it("builds a picker search scoped to the RocketLog marker", function()
		local captured

		package.loaded["snacks"] = {
			picker = {
				pick = function(opts)
					captured = opts
				end,
			},
		}

		telescope_mod.find_logs()

		assert.is_truthy(captured)
		assert.are.equal("grep", captured.source)
		assert.are.equal("RocketLog", captured.title)
		assert.are.equal("🚀[ROCKETLOG]", captured.search)
		assert.is_false(captured.live)
		assert.is_false(captured.regex)
	end)

	it("merges caller options into the picker config", function()
		local captured

		package.loaded["snacks"] = {
			picker = {
				pick = function(opts)
					captured = opts
				end,
			},
		}

		telescope_mod.find_logs({ cwd = "/tmp/project" })

		assert.are.equal("/tmp/project", captured.cwd)
	end)
end)
