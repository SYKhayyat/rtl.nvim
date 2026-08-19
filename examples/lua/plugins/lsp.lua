-- LSP, completion, syntax, formatting.
--
-- Neovim's built-in LSP client is the eglot analogue: in-tree, minimal
-- configuration, no separate framework. mason handles server binaries, which
-- on Windows is worth more than it is on NixOS.

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      { "mason-org/mason-lspconfig.nvim", opts = {
        ensure_installed = { "lua_ls", "pyright", "rust_analyzer" },
      } },
    },
    config = function()
      vim.diagnostic.config({
        virtual_text = { spacing = 2 },
        severity_sort = true,
        float = { border = "rounded" },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", "<cmd>Telescope lsp_references<cr>", "References")
          map("gi", vim.lsp.buf.implementation, "Implementation")
          map("K", vim.lsp.buf.hover, "Hover")
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })
    end,
  },

  -- corfu. blink.cmp ships prebuilt fuzzy binaries, so there is nothing to
  -- compile on Windows, and it is the fastest of the current crop.
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "*",
    dependencies = { "rafamadriz/friendly-snippets", "L3MON4D3/LuaSnip" },
    opts = {
      keymap = { preset = "default" },
      snippets = { preset = "luasnip" },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },

  -- Tree-sitter is foundational in Neovim in a way it is not in Emacs:
  -- highlighting, indent, and textobjects all hang off it.
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "lua", "vim", "vimdoc", "python", "rust", "toml", "json", "yaml",
        "markdown", "markdown_inline", "org", "bash", "regex",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      -- expand-region, done structurally.
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          node_decremental = "<BS>",
        },
      },
    },
  },

  -- Formatting on demand rather than on save, which keeps prose buffers safe.
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        rust = { "rustfmt" },
      },
    },
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end,
        desc = "Format buffer" },
    },
  },
}
