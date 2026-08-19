-- Editor options. Deliberately small; plugins carry the rest.

local o = vim.opt

o.number = true
o.relativenumber = true   -- matches display-line-numbers-type 'relative
o.signcolumn = "yes"      -- stop the gutter shifting when gitsigns appear
o.cursorline = true
o.termguicolors = true
o.scrolloff = 6
o.splitright = true
o.splitbelow = true       -- both splits open where my/split-and-follow-* put them

o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true

o.ignorecase = true
o.smartcase = true
o.inccommand = "split"    -- live substitution preview

o.wrap = true
o.linebreak = true        -- wrap at word boundaries, which matters for prose
o.breakindent = true

o.undofile = true         -- persistent undo, the undo-tree habit
o.swapfile = false
o.backup = false          -- backups/autosave/lockfiles are off in the Emacs
o.writebackup = false     -- config too
o.updatetime = 200
o.timeoutlen = 400        -- which-key popup delay

o.confirm = true          -- ask instead of refusing to quit, ~ y-or-n-p
o.mouse = "a"
o.clipboard = "unnamedplus"

-- UTF-8 everywhere. Not optional when half the buffers are Hebrew.
o.encoding = "utf-8"
o.fileencoding = "utf-8"

-- Windows: the Emacs config tunes pipe reads for the same reason. Neovim's
-- equivalent lever is keeping shell startup cheap.
if vim.fn.has("win32") == 1 then
  o.shellslash = false
end

vim.g.mapleader = " "
vim.g.maplocalleader = ","
