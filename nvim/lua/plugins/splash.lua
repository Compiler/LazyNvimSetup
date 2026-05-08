
return {
    {
        "amansingh-afk/milli.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.opt.termguicolors = true

            require("milli").vimenter({
                splash = "blackhole",
                loop = true,
            })
        end,
    },
}
