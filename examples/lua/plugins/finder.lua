-- Completion-style navigation: the vertico + consult + marginalia + embark
-- stack, and projectile.
--
-- Telescope is the closest single analogue to consult: one interface, many
-- sources, live preview. fzf-native is the sorter speedup and is optional --
-- it needs a C toolchain, which on this machine means MSYS2 mingw64. Without
-- it Telescope still works, just with the Lua sorter.

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release "
          .. "&& cmake --build build --config Release",
        cond = function() return vim.fn.executable("cmake") == 1 end,
      },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    keys = {
      { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep project" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      { "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace symbols" },
    },
    opts = function()
      return {
        defaults = {
          -- ripgrep already handles Hebrew here; the Emacs config's note about
          -- not forcing a UTF-8 process coding system on Windows is the same
          -- trap in a different editor. Leave the encoding alone.
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename",
            "--line-number", "--column", "--smart-case",
          },
          layout_strategy = "flex",
          sorting_strategy = "ascending",
          layout_config = { prompt_position = "top" },
          path_display = { "truncate" },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")
    end,
  },

  -- projectile. project.nvim detects roots and feeds Telescope.
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    main = "project_nvim",
    opts = {
      detection_methods = { "pattern", "lsp" },
      patterns = { ".git", "Cargo.toml", "pyproject.toml", "package.json", ".projectile" },
    },
    config = function(_, opts)
      require("project_nvim").setup(opts)
      pcall(require("telescope").load_extension, "projects")
    end,
    keys = {
      { "<leader>pp", "<cmd>Telescope projects<cr>", desc = "Switch project" },
    },
  },

  -- which-key. Same role as in Emacs, same 0.4s-ish delay.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>D", group = "direction" },
        { "<leader>e", group = "edit config" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>o", group = "org" },
        { "<leader>p", group = "project" },
        { "<leader>t", group = "terminal / toggle" },
        { "<leader>w", group = "writing" },
        { "<leader>x", group = "diagnostics" },
      },
    },
  },
}
