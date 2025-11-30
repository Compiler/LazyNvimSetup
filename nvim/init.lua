print("Luke setup running...")

require("config.lazy")


-- my_stuff
vim.opt.clipboard="unnamedplus"
vim.opt.shiftwidth = 4
-- remap esc
vim.keymap.set("i", "jf", "<Esc>")
vim.keymap.set("i", "JF", "<Esc>")


-- show what we yank
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
    vim.highlight.on_yank()
    end,
})
