-- Prose: olivetti, focus, and the markdown/typst preview systems.
--
-- The Emacs config has a hand-written 185-line markdown preview and a
-- 120-line typst preview. Both have off-the-shelf equivalents here, which is
-- the one place where switching editors is a straight saving.

return {
  -- my/toggle-reading-room: olivetti plus visual-line plus no line numbers.
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    dependencies = { "folke/twilight.nvim" },   -- focus.el
    opts = {
      window = { width = 90, options = { number = false, relativenumber = false } },
      plugins = { twilight = { enabled = true } },
    },
    keys = {
      { "<leader>wz", "<cmd>ZenMode<cr>", desc = "Reading room" },
      { "<leader>wt", "<cmd>Twilight<cr>", desc = "Dim inactive text" },
    },
  },

  -- In-buffer markdown rendering. Closer to org-modern than to a preview
  -- pane: headings, tables and code blocks are styled in place, so there is
  -- no second window to keep in sync.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = { heading = { sign = false } },
    keys = {
      { "<leader>wm", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown rendering" },
    },
  },

  -- Browser preview, for when the in-buffer rendering is not enough. Needs
  -- node; skipped automatically if it is missing.
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview" },
    ft = { "markdown" },
    build = "cd app && npm install",
    cond = function() return vim.fn.executable("node") == 1 end,
    init = function() vim.g.mkdp_filetypes = { "markdown" } end,
    keys = {
      { "<leader>wp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview" },
    },
  },

  -- typst-ts-mode plus the hand-rolled PDF preview, replaced by one plugin
  -- with incremental compilation and cursor sync.
  {
    "chomosuke/typst-preview.nvim",
    ft = "typst",
    version = "1.*",
    opts = {},
    keys = {
      { "<leader>wT", "<cmd>TypstPreviewToggle<cr>", desc = "Typst preview", ft = "typst" },
    },
  },
}
