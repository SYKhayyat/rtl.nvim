-- Theme, modeline, tabs, icons, and the RTL statusline marker.

return {
  -- doom-one.
  {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "dark" },
    config = function(_, opts)
      require("onedark").setup(opts)
      require("onedark").load()
    end,
  },

  -- doom-modeline. The RTL marker sits next to the encoding, which is where
  -- you look when something renders oddly anyway.
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      return {
        options = {
          theme = "onedark",
          globalstatus = true,
          section_separators = "",
          component_separators = "|",
        },
        sections = {
          lualine_c = { { "filename", path = 1 } },
          lualine_x = {
            { function() return require("rtl").statusline() end },
            "encoding", "filetype",
          },
        },
      }
    end,
  },

  -- centaur-tabs.
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { diagnostics = "nvim_lsp", separator_style = "slant" } },
    keys = {
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    },
  },

  { "HiPhish/rainbow-delimiters.nvim", event = "BufReadPost" },

  -- pulsar: flash the line after a jump so you do not lose the cursor.
  {
    "rainbowhxch/beacon.nvim",
    event = "VeryLazy",
    opts = { minimal_jump = 10 },
  },
}
