-- Terminal and local AI.

return {
  -- The tabbed shell panel from 23-terminal.el. toggleterm gives the panel,
  -- the numbered terminals and the toggle key; the shell picker below keeps
  -- the PowerShell / Nushell / Git-bash preference order.
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    opts = {
      direction = "horizontal",
      size = function(term)
        return term.direction == "horizontal" and math.floor(vim.o.lines * 0.32) or 80
      end,
      open_mapping = [[<C-\>]],
      shell = function()
        for _, sh in ipairs({ "pwsh", "nu", "powershell", "bash" }) do
          if vim.fn.executable(sh) == 1 then
            return sh
          end
        end
        return vim.o.shell
      end,
      shade_terminals = false,
    },
    keys = {
      { "<C-\\>", desc = "Toggle terminal" },
      { "<leader>tn", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "New terminal" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Floating terminal" },
    },
  },

  -- gptel against local Ollama. CodeCompanion speaks to the same
  -- localhost:11434 endpoint and, like gptel, keeps the conversation in a
  -- normal buffer you can edit.
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    opts = {
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            env = { url = "http://localhost:11434" },
            parameters = { sync = true },
          })
        end,
      },
      strategies = {
        chat = { adapter = "ollama" },
        inline = { adapter = "ollama" },
      },
    },
    keys = {
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI chat" },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "AI actions" },
      { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI inline" },
    },
  },
}
