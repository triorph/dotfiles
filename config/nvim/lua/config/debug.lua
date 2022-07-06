local dap = require("dap")
require("dapui").setup()
dap.adapters.lldb = {
	type = "executable",
	command = "/usr/bin/lldb-vscode", -- adjust as needed
	name = "lldb",
}
dap.adapters.python = {
	type = "executable",
	command = "path/to/virtualenvs/debugpy/bin/python",
	args = { "-m", "debugpy.adapter" },
}

dap.configurations.rust = {
	{
		name = "Launch",
		type = "lldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		args = {},

		-- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
		--
		--    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
		--
		-- Otherwise you might get the following error:
		--
		--    Error on launch: Failed to attach to the target process
		--
		-- But you should be aware of the implications:
		-- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
		runInTerminal = false,
	},
}

dap.configurations.python = {
	{
		-- The first three options are required by nvim-dap
		type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
		request = "launch",
		name = "Launch file",

		-- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options

		program = "${file}", -- This configuration will launch the current file if used.
		pythonPath = function()
			-- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
			-- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
			-- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
			local cwd = vim.fn.getcwd()
			if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
				return cwd .. "/venv/bin/python"
			elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
				return cwd .. "/.venv/bin/python"
			else
				return "/usr/bin/python"
			end
		end,
	},
}

local nnoremap_func = function(keys, call)
	vim.api.nvim_set_keymap("n", keys, ":lua " .. call .. "<CR>", { noremap = true, silent = true })
end

nnoremap_func("<leader>dso", 'require("dap").step_over()')
nnoremap_func("<leader>dsi", 'require("dap").step_into()')
nnoremap_func("<leader>dsO", 'require("dap").step_out()')
nnoremap_func("<leader>dc", 'require("dap").continue()')
nnoremap_func("<leader>db", 'require("dap").toggle_breakpoint()')
nnoremap_func("<leader>dB", 'require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))')
nnoremap_func("<leader>dlp", "require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))")
nnoremap_func("<leader>dr", 'require("dap").repl.open()')
nnoremap_func("<leader>dl", 'require("dap").run_last()')
nnoremap_func("<leader>dw", 'require("dapui").float_element("watches", {})')
nnoremap_func("<leader>di", '<cmd>lua require"dap.ui.variables".hover()')
nnoremap_func("<leader>dv", 'require("dapui").toggle()')
