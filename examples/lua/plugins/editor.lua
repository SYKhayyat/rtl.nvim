-- Editing and navigation: avy, ace-window, dirvish, undo-tree, wgrep,
-- expand-region, multiple-cursors, electric-pair, anzu.

return {
  -- avy and ace-window in one plugin.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
    },
  },

  -- dirvish. oil.nvim is the same idea: the directory is a buffer, you edit
  -- it with normal editing commands and the changes are applied on write.
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      view_options = { show_hidden = true },
      keymaps = { ["<C-h>"] = false },   -- keep the window-left binding
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
      { "<leader>e", "<cmd>Oil<cr>", desc = "File manager" },
    },
  },

  -- undo-tree, including the persistent history 'undofile' gives us.
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" } },
  },

  -- wgrep plus visual-regexp: search and replace across the project with an
  -- editable results buffer.
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
    keys = {
      { "<leader>sr", function() require("grug-far").open() end, desc = "Search and replace" },
    },
  },

  -- expand-region's textobject half. Tree-sitter incremental selection in
  -- lsp.lua covers the growing-selection half.
  {
    "echasnovski/mini.nvim",
    version = false,
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup()       -- richer textobjects
      require("mini.surround").setup() -- add/change/delete surrounding pairs
      require("mini.pairs").setup()    -- electric-pair
    end,
  },

  -- multiple-cursors.
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    event = "VeryLazy",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()
      vim.keymap.set({ "n", "v" }, "<C-n>", function() mc.matchAddCursor(1) end,
        { desc = "Add cursor at next match" })
      vim.keymap.set("n", "<Esc>", function()
        if mc.hasCursors() then mc.clearCursors() else vim.cmd("nohlsearch") end
      end, { desc = "Clear cursors or highlight" })
    end,
  },

  -- anzu: search match counts. Neovim has this built in, it just needs the
  -- 'S' flag removed from 'shortmess'.
  {
    "kevinhwang91/nvim-hlslens",
    keys = { "/", "?", "n", "N" },
    config = function()
      vim.opt.shortmess:append("S")
      require("hlslens").setup()
    end,
  },

  -- savehist / save-place / desktop, in one.
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
    },
  },
}
