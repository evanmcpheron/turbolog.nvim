local h = require("tests.helpers")

describe("rocketlog.dashboard.actions", function()
	local actions
	local layout
	local state_mod
	local render
	local scan

	before_each(function()
		package.loaded["rocketlog.config"] = nil
		require("rocketlog.config").apply({ label = "ROCKETLOG" })

		package.loaded["rocketlog.dashboard.actions"] = nil
		package.loaded["rocketlog.dashboard.layout"] = nil
		package.loaded["rocketlog.dashboard.state"] = nil
		package.loaded["rocketlog.dashboard.render"] = nil
		package.loaded["rocketlog.dashboard.scan"] = nil

		actions = require("rocketlog.dashboard.actions")
		layout = require("rocketlog.dashboard.layout")
		state_mod = require("rocketlog.dashboard.state")
		render = require("rocketlog.dashboard.render")
		scan = require("rocketlog.dashboard.scan")
	end)

	after_each(function()
		state_mod.close(state_mod.get_current())
		pcall(vim.cmd, "only")
	end)

	it("updates the live filter value when the filter buffer changes", function()
		local source_bufnr = h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ warning:`, warning);",
		}, { filetype = "typescript", name = "test.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)
		layout.open(state)
		scan.collect_groups(state)
		render.refresh(state)

		actions.open_live_filter(state)
		vim.api.nvim_buf_set_lines(state.ui.filter_buf, 0, -1, false, { "warn" })
		vim.api.nvim_exec_autocmds("TextChanged", { buffer = state.ui.filter_buf })
		assert.are.equal("warn", state.filter)

		vim.api.nvim_buf_set_lines(state.ui.filter_buf, 0, -1, false, { "error" })
		vim.api.nvim_exec_autocmds("TextChanged", { buffer = state.ui.filter_buf })
		assert.are.equal("error", state.filter)
	end)

	it("opens the selected entry in the source window with edit behavior", function()
		local source_bufnr = h.set_buffer({ "const source = true;" }, { filetype = "typescript", name = "source.ts" })
		local source_win = vim.api.nvim_get_current_win()
		local target_path = vim.fn.tempname() .. ".ts"
		vim.fn.writefile({ "const fromDisk = true;" }, target_path)

		local state = state_mod.new(source_bufnr)
		state.source_win = source_win
		state.selection = { kind = "entry", id = target_path .. ":1:1", path = target_path }
		state.groups = {
			{
				path = target_path,
				filename = vim.fn.fnamemodify(target_path, ":t"),
				count = 1,
				entries = {
					{
						id = target_path .. ":1:1",
						path = target_path,
						filename = vim.fn.fnamemodify(target_path, ":t"),
						lnum = 1,
						end_lnum = 1,
						log_type = "log",
						label = "fromDisk",
						summary = "fromDisk",
						text = "console.log(...)",
						marker = "🚀[ROCKETLOG]",
						stale = false,
					},
				},
			},
		}

		layout.open(state)
		render.refresh(state)
		vim.api.nvim_win_set_cursor(state.ui.list_win, { 1, 0 })
		state.line_map = {
			[1] = { kind = "group", group = state.groups[1] },
			[2] = { kind = "entry", group = state.groups[1], entry = state.groups[1].entries[1] },
		}
		vim.api.nvim_win_set_cursor(state.ui.list_win, { 2, 0 })

		actions.open_selected(state, "edit")
		vim.wait(100, function()
			return vim.api.nvim_get_current_win() == source_win and vim.api.nvim_buf_get_name(0) == target_path
		end)

		assert.are.equal(source_win, vim.api.nvim_get_current_win())
		assert.are.equal(vim.loop.fs_realpath(target_path), vim.loop.fs_realpath(vim.api.nvim_buf_get_name(0)))
		assert.is_nil(state_mod.get_current())
		vim.fn.delete(target_path)
	end)

	it("closes the dashboard and clears current state", function()
		local source_bufnr = h.set_buffer({ "const source = true;" }, { filetype = "typescript", name = "source.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)
		layout.open(state)
		render.refresh(state)

		local root_win = state.ui.root_win
		state_mod.close(state)

		assert.is_nil(state_mod.get_current())
		assert.is_false(vim.api.nvim_win_is_valid(root_win))
	end)

	it("allows q to be triggered from non-list dashboard panes", function()
		local source_bufnr = h.set_buffer({ "const source = true;" }, { filetype = "typescript", name = "source.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)
		layout.open(state)
		render.refresh(state)
		actions.attach(state)

		local called = false
		local restore_close = h.stub(state_mod, "close", function(target_state)
			called = true
			assert.are.equal(state, target_state)
		end)

		vim.api.nvim_buf_call(state.ui.header_buf, function()
			vim.api.nvim_feedkeys("q", "xt", false)
		end)
		vim.wait(100, function()
			return called
		end)

		restore_close()
		assert.is_true(called)
	end)

	it("toggles and resets fold state for file groups", function()
		local source_bufnr = h.set_buffer({ "const source = true;" }, { filetype = "typescript", name = "source.ts" })
		local state = state_mod.new(source_bufnr)
		state.groups = {
			{ path = "/tmp/a.ts", filename = "a.ts", count = 1, entries = { { id = "a", path = "/tmp/a.ts" } } },
			{ path = "/tmp/b.ts", filename = "b.ts", count = 1, entries = { { id = "b", path = "/tmp/b.ts" } } },
		}
		state.line_map = {
			[1] = { kind = "group", group = state.groups[1] },
		}
		state.list_line_count = 1
		layout.open(state)
		state_mod.set_current(state)
		vim.api.nvim_win_set_cursor(state.ui.list_win, { 1, 0 })

		local restore_render = h.stub(render, "refresh", function() end)
		local restore_scan = h.stub(scan, "collect_groups", function()
			return state.groups
		end)

		actions.toggle_fold(state)
		assert.is_true(state.collapsed_paths["/tmp/a.ts"])

		actions.open_fold(state)
		assert.is_nil(state.collapsed_paths["/tmp/a.ts"])

		actions.collapse_all(state)
		assert.is_true(state.collapsed_paths["/tmp/a.ts"])
		assert.is_true(state.collapsed_paths["/tmp/b.ts"])

		actions.expand_all(state)
		assert.are.same({}, state.collapsed_paths)

		restore_render()
		restore_scan()
	end)

	it("toggles the selected log into a commented dashboard entry", function()
		local source_bufnr = h.set_buffer({
			"const before = true;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ before:`, before);",
			"const after = true;",
		}, { filetype = "typescript", name = "/tmp/test.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)
		layout.open(state)
		scan.collect_groups(state)
		render.refresh(state)
		vim.api.nvim_win_set_cursor(state.ui.list_win, { 2, 0 })

		actions.comment_selected(state)

		assert.are.same({
			"const before = true;",
			"// console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ before:`, before);",
			"const after = true;",
		}, h.get_lines())
		assert.are.equal(1, #(state.groups or {}))
		assert.are.equal(1, #state.groups[1].entries)
		assert.is_true(state.groups[1].entries[1].commented)
		assert.are.same({ 2, 0 }, vim.api.nvim_win_get_cursor(state.ui.list_win))
	end)

	it("toggles all logs in the selected file from an entry row", function()
		local source_bufnr = h.set_buffer({
			"console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ first:`, first);",
			"const middle = true;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:3 ~ second:`, second);",
		}, { filetype = "typescript", name = "/tmp/test.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)
		layout.open(state)
		scan.collect_groups(state)
		render.refresh(state)
		vim.api.nvim_win_set_cursor(state.ui.list_win, { 2, 0 })

		local restore_confirm = h.stub(vim.fn, "confirm", function()
			return 1
		end)

		actions.comment_selected_file(state)
		restore_confirm()

		assert.are.same({
			"// console.log(`🚀[ROCKETLOG] ~ test.ts:1 ~ first:`, first);",
			"const middle = true;",
			"// console.log(`🚀[ROCKETLOG] ~ test.ts:3 ~ second:`, second);",
		}, h.get_lines())
		assert.are.equal(1, #(state.groups or {}))
		assert.are.equal(2, #state.groups[1].entries)
		assert.is_true(state.groups[1].entries[1].commented)
		assert.is_true(state.groups[1].entries[2].commented)
		assert.are.same({ 2, 0 }, vim.api.nvim_win_get_cursor(state.ui.list_win))
	end)

	it("uncomments a previously commented selected log", function()
		local source_bufnr = h.set_buffer({
			"const before = true;",
			"// console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ before:`, before);",
			"const after = true;",
		}, { filetype = "typescript", name = "/tmp/test.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)
		layout.open(state)
		scan.collect_groups(state)
		render.refresh(state)
		vim.api.nvim_win_set_cursor(state.ui.list_win, { 2, 0 })

		actions.comment_selected(state)

		assert.are.same({
			"const before = true;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ before:`, before);",
			"const after = true;",
		}, h.get_lines())
		assert.are.equal(1, #(state.groups or {}))
		assert.is_false(state.groups[1].entries[1].commented)
		assert.are.same({ 2, 0 }, vim.api.nvim_win_get_cursor(state.ui.list_win))
	end)

	it("keeps the cursor on the same entry when toggling repeatedly", function()
		local source_bufnr = h.set_buffer({
			"const before = true;",
			"console.log(`🚀[ROCKETLOG] ~ test.ts:2 ~ before:`, before);",
			"const after = true;",
		}, { filetype = "typescript", name = "/tmp/test.ts" })
		local state = state_mod.new(source_bufnr)
		state_mod.set_current(state)
		layout.open(state)
		scan.collect_groups(state)
		render.refresh(state)
		vim.api.nvim_win_set_cursor(state.ui.list_win, { 2, 0 })

		actions.comment_selected(state)
		assert.are.same({ 2, 0 }, vim.api.nvim_win_get_cursor(state.ui.list_win))
		assert.is_true(state.groups[1].entries[1].commented)

		actions.comment_selected(state)
		assert.are.same({ 2, 0 }, vim.api.nvim_win_get_cursor(state.ui.list_win))
		assert.is_false(state.groups[1].entries[1].commented)
	end)
end)
