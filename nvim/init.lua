print("Luke setup running...")

require("config.lazy")


-- my_stuff
vim.opt.clipboard="unnamedplus"
-- remap esc
vim.keymap.set("i", "jf", "<Esc>")
vim.keymap.set("i", "JF", "<Esc>")
-- build makefile
--vim.api.nvim_set_keymap('n', '<leader>m', ':wa<CR>:botright split term://make<CR>:resize ' .. math.floor(vim.o.lines / 4) .. '<CR>i', { noremap = true, silent = true })

local kill_topaz = function()
    vim.fn.jobstart({
        "cmd.exe", "/C",
        'taskkill /IM "Topaz Video.exe" /F /T >nul 2>&1'
    })
end

-- kill
vim.keymap.set("n", "<leader>q", kill_topaz, {
    noremap = true,
    silent = true,
    desc = "Kill Topaz Video"
})

-- full build and run
vim.keymap.set("n", "<leader>m", function()
    kill_topaz()
    vim.cmd("wa")
    vim.cmd("botright split term://make")
    vim.cmd("resize " .. math.floor(vim.o.lines / 4))
    vim.cmd("startinsert")
end, {
    noremap = true,
    silent = true,
    desc = "Kill + Make"
})

-- run
vim.keymap.set("n", "<leader>r", function()
    kill_topaz()
    vim.cmd("wa")
    vim.cmd("botright split term://make run")
    vim.cmd("resize " .. math.floor(vim.o.lines / 4))
    vim.cmd("startinsert")
end, {
    noremap = true,
    silent = true,
    desc = "Kill + Make Run"
})

-- clean
vim.keymap.set("n", "<leader>c", function()
    kill_topaz()
    vim.cmd("wa")
    vim.cmd("botright split term://make clean")
    vim.cmd("resize " .. math.floor(vim.o.lines / 4))
    vim.cmd("startinsert")
end, {
    noremap = true,
    silent = true,
    desc = "Kill + clean "
})


-- show what we yank
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
    vim.highlight.on_yank()
    end,
})

vim.o.statuscolumn = "%s %l %r "

vim.opt.nu = true
vim.opt.relativenumber = true


vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

--vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"
vim.opt.numberwidth = 2
vim.opt.signcolumn = "no"
vim.opt.foldcolumn = "0"
vim.opt.statuscolumn = ""

vim.g.mapleader = " "

