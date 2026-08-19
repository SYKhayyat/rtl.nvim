# A Hebrew-first Neovim configuration

A complete starter config built around `rtl.nvim`, mapped deliberately onto an
existing Emacs setup rather than assembled from whatever is fashionable.

## Install

```
git clone https://github.com/SYKhayyat/rtl.nvim
cp -r rtl.nvim/examples ~/.config/nvim          # or %LOCALAPPDATA%\nvim
nvim
```

To try it without touching your existing config, use a separate app name:

```
cp -r rtl.nvim/examples "$LOCALAPPDATA/rtl-example"   # Windows
NVIM_APPNAME=rtl-example nvim
```

Requires Neovim 0.10+, `git`, and `ripgrep`. Optional: `cmake` and a C
toolchain for the Telescope fzf sorter (MSYS2 mingw64 supplies both on
Windows), `node` for browser markdown preview, `ollama` for the AI chat.
Everything guarded by `cond` skips itself cleanly when its dependency is
missing.

## The mapping

| Emacs | Neovim | Note |
|---|---|---|
| `package.el` + `use-package` | **lazy.nvim** | Lazy by default, lockfile, same "load modules in order" shape as your `modules/` loader |
| vertico + consult + marginalia + orderless | **telescope.nvim** | One interface over many sources, with preview. `fzf-native` is the sorter speedup |
| embark | telescope actions | Not a direct equivalent; the act-on-candidate idea lives inside the picker |
| corfu | **blink.cmp** | Ships prebuilt binaries, so nothing to compile on Windows |
| yasnippet | **LuaSnip** + friendly-snippets | |
| which-key | **which-key.nvim** | Same plugin, same role |
| **eglot** | built-in `vim.lsp` + nvim-lspconfig | In-tree, minimal config — the same reason you picked eglot over lsp-mode |
| (server binaries by hand) | **mason.nvim** | Worth more on Windows than on NixOS |
| tree-sitter (barely used) | **nvim-treesitter** (pinned to `master`) | Foundational here: highlight, indent, textobjects, incremental selection. See the note below on the branch |
| magit | **neogit** + diffview | Explicit magit port, popup-driven |
| git-gutter | **gitsigns.nvim** | Plus hunk staging git-gutter never had |
| git-timemachine | `DiffviewFileHistory` | |
| projectile | **project.nvim** | Feeds Telescope, same root-pattern detection |
| dirvish | **oil.nvim** | The directory is a buffer you edit and write — the dired idea, done properly |
| undo-tree | **undotree** + `'undofile'` | Persistent history without the separate database |
| avy + ace-window | **flash.nvim** | Both jobs, one plugin |
| expand-region | treesitter incremental selection + mini.ai | Structural rather than heuristic |
| multiple-cursors | **multicursor.nvim** | |
| wgrep + visual-regexp | **grug-far.nvim** | Editable project-wide search and replace |
| anzu | **nvim-hlslens** | |
| electric-pair | mini.pairs | |
| move-text | `<M-j>`/`<M-k>` in keymaps.lua | Built-in `:m`, no plugin needed |
| org + org-modern | **nvim-orgmode** + org-bullets | A real reimplementation: agenda, capture, TODO cycling, refile |
| olivetti + focus | **zen-mode** + twilight | Your `my/toggle-reading-room`, on `<leader>wz` |
| your 185-line markdown preview | **render-markdown.nvim** + markdown-preview.nvim | In-buffer rendering, plus a browser pane when you want one |
| your 120-line typst preview | **typst-preview.nvim** | Incremental compile with cursor sync |
| doom-themes (doom-one) | **onedark.nvim** | |
| doom-modeline | **lualine.nvim** | Carries the RTL marker next to the encoding |
| centaur-tabs | **bufferline.nvim** | |
| nerd-icons | nvim-web-devicons | |
| pulsar | beacon.nvim | |
| rainbow-delimiters | rainbow-delimiters.nvim | |
| your tabbed `shell` panel | **toggleterm.nvim** | Keeps the pwsh → nu → bash preference order. `vterm` never built on Windows; this has no such problem |
| gptel → local Ollama | **codecompanion.nvim** | Same `localhost:11434`, conversation still lives in an editable buffer |
| savehist / recentf / save-place | shada (built in) + persistence.nvim | |
| editorconfig, so-long | built in since 0.9 | |
| gcmh, diminish, restart-emacs | not needed | |

### The nvim-treesitter branch pin

`nvim-treesitter` is pinned to `branch = "master"`. Its default branch is now
`main`, a rewrite that removes `nvim-treesitter.configs` entirely along with
the incremental-selection and indent modules. Incremental selection is this
config's `expand-region` replacement, so master it is. This was not a
precaution — the unpinned spec was installed, it broke on the first buffer
read, and pinning is the fix. Revisit when the rewrite grows those modules
back.

`org` is also absent from `ensure_installed` on purpose: master's registry no
longer carries that grammar, and nvim-orgmode installs and owns its own. Ask
for it here and `ensure_installed` waits forever on a parser that never
arrives — which is exactly how this was found.

### Deliberately not included

- **hydra.** `hydra.nvim` exists, but which-key in `helix` preset covers the
  discovery job, and a second popup system competing with it is noise. If you
  miss the sticky-transient-state feel specifically, add it then.
- **A spell checker.** Your Emacs config skips it on Windows on purpose.
  Neovim's built-in `'spell'` has no Hebrew dictionary, so nothing changes.
- **noice.nvim.** Popular, and it replaces core UI plumbing in ways that break
  interestingly. Not on a config where rendering is already the hard part.

## Keymaps

Leader is `<Space>`. Your Emacs config has no leader — `C-c` is the personal
prefix, with which-key and hydras for discovery. `<Space>` plus which-key is
that idea with a key that is free in normal mode.

| Key | Action | Emacs equivalent |
|---|---|---|
| `<leader>D` | Toggle text direction | the `C-c D` direction hydra |
| `<leader>Dh` / `<leader>De` | Force RTL / LTR | |
| `<leader><space>` | Find files | `C-c p f` |
| `<leader>fg` | Grep project | `C-c p s` |
| `<leader>fr` | Recent files | `recentf` |
| `<leader>gg` | Neogit | `C-x g` |
| `<leader>e` | File manager | `<f8>` dirvish sidebar |
| `<leader>u` | Undo tree | |
| `<leader>wz` | Reading room | `C-c w` |
| `<leader>oa` / `<leader>oc` | Org agenda / capture | `C-c a` / `C-c c` |
| `<C-\>` | Terminal panel | `` C-` `` |
| `<leader>ac` | AI chat | gptel |

`<F8>` is left free deliberately: it is your dirvish sidebar key in Emacs, so
direction lives on `<leader>D` instead of `rtl.nvim`'s default.

## The one thing that will not carry over

Emacs implements the full Unicode bidirectional algorithm. Neovim does not —
it mirrors the window, and mixed Hebrew/Latin lines render one script
backwards. Your `00-core.el` sets `bidi-paragraph-direction` to
`left-to-right` for redisplay speed, so this particular machine has never
exercised the Emacs bidi engine either; the difference will only show up
against the NixOS config.

Read `:help rtl-limits` before deciding how much this matters to you. For
Hebrew prose it does not. For a Hebrew comment above English code it does,
immediately.
