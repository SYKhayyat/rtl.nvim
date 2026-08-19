-- magit, git-gutter, git-timemachine.
--
-- Neogit is an explicit magit port and keeps the same popup-driven flow.
-- Diffview covers the review and history side, which is where magit's
-- log/diff buffers do their work.

return {
  {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
    cmd = { "Neogit", "NeogitCommit" },
    opts = { graph_style = "unicode", integrations = { diffview = true, telescope = true } },
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit status" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Commit" },
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff view" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
    },
  },

  -- git-gutter, plus hunk staging that git-gutter never had.
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" }, change = { text = "▎" },
        delete = { text = "契" }, topdelete = { text = "契" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
        end
        map("]h", gs.next_hunk, "Next hunk")
        map("[h", gs.prev_hunk, "Previous hunk")
        map("<leader>gs", gs.stage_hunk, "Stage hunk")
        map("<leader>gr", gs.reset_hunk, "Reset hunk")
        map("<leader>gp", gs.preview_hunk, "Preview hunk")
        map("<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
      end,
    },
  },
}
