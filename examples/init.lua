-- A Hebrew-first Neovim configuration.
--
-- Structured to be read: options and keymaps in lua/config, one plugin module
-- per concern in lua/plugins. lazy.nvim imports the whole plugins directory,
-- which is the same "load every module in order" arrangement as the Emacs
-- config's modules/ loader, minus the tangling step.
--
-- See examples/README.md for the Emacs-to-Neovim package mapping.

require("config.options")

-- Bootstrap lazy.nvim.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("failed to clone lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- This config is FROZEN by design. See examples/README.md, "Frozen by
-- design", for the reasoning and the update procedure.
--
-- lazy-lock.json pins every plugin to an exact commit and is committed to the
-- repository. A fresh install reproduces those exact revisions, and nothing
-- moves on its own: the update checker is off, so no plugin is ever fetched
-- unless you type :Lazy update yourself.
--
-- Two upstream breakages hit this config on the day it was written --
-- nvim-treesitter changed its default branch to an incompatible rewrite, and
-- a grammar was removed from its registry. Both would have arrived silently
-- through an automatic update.
require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "onedark", "habamax" } },
  checker = { enabled = false },        -- never check for updates in the background
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  change_detection = { notify = false },
  performance = {
    rtp = {
      -- Neovim sources a pile of legacy runtime plugins by default. Dropping
      -- them is the cheapest startup win available, and is the same instinct
      -- as the Windows tuning in the Emacs config.
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin",
      },
    },
  },
})

require("config.keymaps")
