--  if client.name == "clangd" then
 --   map("n", "<leader>fo", "<cmd>ClangdSwitchSourceHeader<CR>", opts)
  --end

return {
  {
    "neovim/nvim-lspconfig",
    config = function()
        local group = vim.api.nvim_create_augroup("UserLspGd", { clear = true })

	vim.api.nvim_create_autocmd("LspAttach", { group = group, callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "clangd" then
            vim.keymap.set("n", "<space>gd", vim.lsp.buf.definition, {
              buffer = args.buf,
              desc = "clangd: goto definition",
            })

	    vim.keymap.set("n","<leader>fo", function()
		vim.lsp.buf_request(0,"textDocument/switchSourceHeader",{uri=vim.uri_from_bufnr(0)},function(_,r)
		if r then vim.cmd("e "..vim.uri_to_fname(r)) end
	    end)
	    end,{buffer=args.buf})

          end
        end,
      })
      vim.lsp.enable({
        "lua_ls",
        "mesonlsp",
      })
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = {}, -- default setup() is called by lazy.nvim
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "mason-org/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "lua_ls",
        "mesonlsp",
      },
    },
  },
}
