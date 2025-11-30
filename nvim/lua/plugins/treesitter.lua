return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate", -- rebuild on new query
    opts = {
      ensure_installed = { "lua", "vim", "vimdoc", "query", "c", "cpp", "qmldir", "qmljs"},
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
