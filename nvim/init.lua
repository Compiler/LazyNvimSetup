print("Luke setup running...")

require("config.lazy")


-- my_stuff
vim.opt.clipboard="unnamedplus"
-- remap esc
vim.keymap.set("i", "jf", "<Esc>")
vim.keymap.set("i", "JF", "<Esc>")

vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "jk", "<Esc>")
local kill_topaz = function()
    vim.fn.jobstart({
        "cmd.exe", "/C",
        'taskkill /IM "Topaz Video.exe" /F /T >nul 2>&1'
    })
end

local spawn_runner = function()

    vim.cmd("wa")
    vim.cmd("botright split term://make")
    vim.cmd("resize " .. math.floor(vim.o.lines / 4))
    -- vim.cmd("startinsert")
    vim.cmd("stopinsert")
    vim.cmd("normal! G")

end

local close_terminals = function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local ft = vim.bo[buf].filetype
      if ft == "" or ft == "unknown" then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end
end

-- kill
vim.keymap.set("n", "<leader>q", function() 
    kill_topaz()
    close_terminals() 
end, {
    noremap = true,
    silent = true,
    desc = "Kill Topaz Video"
})

vim.keymap.set("t", "<leader>q", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
        "n",
        false
    )
    kill_topaz()
    close_terminals()
end, {
    noremap = true,
    silent = true,
    desc = "Close terminals",
})

-- full build and run
vim.keymap.set("n", "<leader>m", function()
    kill_topaz()
    close_terminals()
    spawn_runner()
end, {
    noremap = true,
    silent = true,
    desc = "Kill + Make"
})

vim.keymap.set("t", "<leader>m", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
        "n",
        false
    )
    kill_topaz()
    close_terminals()
    spawn_runner()
end, {
    noremap = true,
    silent = true,
    desc = "Kill + Make "
})

-- run
vim.keymap.set("n", "<leader>r", function()
    kill_topaz()
    close_terminals()
    spawn_runner()
end, {
    noremap = true,
    silent = true,
    desc = "Kill + Make Run"
})

vim.keymap.set("t", "<leader>r", function()
    -- optional: go to normal mode after closing
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
        "n",
        false
    )
    kill_topaz()
    close_terminals()
    spawn_runner()
end, {
    noremap = true,
    silent = true,
    desc = "Kill + Make run"
})

vim.keymap.set("n", "<leader>c", function()
    close_terminals()
end, {
    noremap = true,
    silent = true,
    desc = "Close terminals"
})

vim.keymap.set("t", "<leader>c", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
        "n",
        false
    )
    close_terminals()
end, {
    noremap = true,
    silent = true,
    desc = "Close terminals",
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

