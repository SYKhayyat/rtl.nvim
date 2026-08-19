-- rtl.nvim itself.
--
-- toggle_key is <leader>D rather than the default <F8>, because <F8> is the
-- dirvish sidebar key in the Emacs config and C-c D was the text-direction
-- hydra there. Keeping direction on D preserves the muscle memory that
-- actually exists.

return {
  {
    "SYKhayyat/rtl.nvim",
    version = "v1.0.0",   -- pinned; see "Frozen by design" in the README
    lazy = false,         -- detection has to run on every buffer read
    priority = 900,
    opts = {
      toggle_key = "<leader>D",
      keymap = "hebrew",
      prose_filetypes = {
        markdown = true, text = true, tex = true, org = true, typst = true,
      },
      integrations = {
        telescope = { enabled = true, keymap = true, rightleft = true },
        orgmode = { enabled = true, agenda_rtl = false },
      },
    },
    keys = {
      { "<leader>D", desc = "Toggle text direction" },
      { "<leader>Dh", "<cmd>Hebrew<cr>", desc = "Force RTL (Hebrew)" },
      { "<leader>De", "<cmd>English<cr>", desc = "Force LTR (English)" },
    },
  },
}
