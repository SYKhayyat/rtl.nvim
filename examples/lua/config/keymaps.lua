-- Keymaps that are not owned by a plugin spec.
--
-- Leader is <Space>. The Emacs config has no leader -- it uses C-c as a
-- personal prefix with which-key and hydras for discovery. <Space> plus
-- which-key is the same idea with a key that is free in normal mode.

local map = vim.keymap.set

-- Buffers. Mirrors my/kill-current-buffer and my/kill-other-buffers.
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bo", function()
  local cur = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= cur and vim.bo[b].buflisted and not vim.bo[b].modified then
      vim.api.nvim_buf_delete(b, {})
    end
  end
end, { desc = "Delete other buffers" })

-- Splits already land you in the new window: 'splitright'/'splitbelow' plus
-- Neovim's default focus behaviour give my/split-and-follow-below|right.
map("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Split right" })
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Split below" })

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Config editing, the C-c e i / e m / e r habit.
map("n", "<leader>ei", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Edit init.lua" })
map("n", "<leader>em", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/lua/plugins")
end, { desc = "Edit plugin modules" })

-- Clear search highlight. Escape is free in normal mode.
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Diagnostics, the flycheck-shaped hole.
map("n", "<leader>xd", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Previous diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })

-- Move lines, the move-text binding.
map("n", "<M-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<M-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<M-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<M-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
