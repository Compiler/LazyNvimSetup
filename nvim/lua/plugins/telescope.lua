return {

    {
	'nvim-telescope/telescope.nvim', tag = 'v0.2.0',
	dependencies = { 
	    'nvim-lua/plenary.nvim',
	    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
	},

	config = function()
	    print("Telescope doing things...")
	    local tsb = require('telescope.builtin')
	    vim.keymap.set("n", "<space>ff", tsb.find_files)
	    vim.keymap.set("n", "<space>en", function()
                tsb.find_files({
                    cwd = vim.fn.stdpath("config"),
                })
            end)
	    vim.keymap.set("n", "<space>fg", tsb.live_grep)
        end
    }
}
