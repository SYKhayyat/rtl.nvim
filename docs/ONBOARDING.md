# Onboarding

Getting from "installed" to "writing Hebrew comfortably in Neovim", and
understanding what you are looking at while you do it.

Fifteen minutes. The first five are setup; the rest is the part that saves you
from thinking the plugin is broken when it is doing exactly what it says.

---

## Contents

- [1. Before you install: know the ceiling](#1-before-you-install-know-the-ceiling)
- [2. Install](#2-install)
- [3. See it working](#3-see-it-working)
- [4. The five minutes that matter](#4-the-five-minutes-that-matter)
- [5. How the decision gets made](#5-how-the-decision-gets-made)
- [6. Typing Hebrew](#6-typing-hebrew)
- [7. Tune it](#7-tune-it)
- [8. Integrations](#8-integrations)
- [9. A worked setup](#9-a-worked-setup)
- [10. Contributing](#10-contributing)

---

## 1. Before you install: know the ceiling

Read this first. It will save you filing a bug that cannot be fixed.

**This plugin gives right-to-left *layout*, not the Unicode bidirectional
algorithm.**

Neovim mirrors the window and reverses the cell order. It does not reorder
mixed RTL/LTR runs within a line, because its rendering model assumes buffer
bytes map monotonically onto screen cells, and bidi breaks that assumption at
the foundation. That is Neovim, not this plugin, and no configuration changes
it.

What that means in practice:

| | |
|---|---|
| Monolingual Hebrew prose | **Correct.** Genuinely correct, not merely tolerable. This is the case the plugin is for. |
| A line with both scripts | One of them renders backwards. Always. |
| Nikud | Survives, on the correct base letters. How well it *stacks* is your font's problem. |

If you need correct mixed-script rendering, you need an editor with a real
text-shaping stack underneath it. Emacs does the full UBA and has for a long
time. This plugin will not get you there and does not pretend to.

Still here? Good — for Hebrew prose it works well, and the rest of this page is
about making it work well for you.

## 2. Install

### lazy.nvim

```lua
{
  "SYKhayyat/rtl.nvim",
  ft = { "markdown", "text", "tex" },   -- or drop this to always load
  opts = {},
}
```

`opts = {}` is what calls `setup()`. Without `setup()`, the commands work but
nothing is automatic — that distinction accounts for most "it does nothing"
reports.

Note the trade-off in `ft`: lazy-loading by filetype means the plugin is not
installed until the first matching file opens, so the mirrored-editor bug can
still bite you once, before it loads. Drop `ft` if that bothers you.

### packer.nvim

```lua
use { "SYKhayyat/rtl.nvim", config = function() require("rtl").setup() end }
```

### No plugin manager

Clone anywhere on your `runtimepath` and call `require("rtl").setup()` from
your `init.lua`.

### Verify

```vim
:lua print(vim.g.loaded_rtl_nvim)   " true  -> the plugin is on runtimepath
:autocmd rtl.nvim                   " non-empty -> setup() has run
```

## 3. See it working

RTL is the one Neovim feature you cannot verify by inspecting options.
`rightleft` changes which screen *cell* a character lands in, so the only
honest check is a rendered grid. The repository ships a harness that drives
real Neovim inside a pty and dumps the grid:

```sh
python -m pip install -r tests/requirements.txt
python tests/render.py --plugin
```

**Run it in your own terminal, and read the grids there.** They are
deliberately not reproduced in any file in this repository: a grid dump is in
*visual* order, and any viewer that applies the bidirectional algorithm to the
file — GitHub, your browser — reorders it again and shows you the opposite of
what the dump says. The output is only trustworthy where it is produced.

Three things the grids show rather than assert:

1. Hebrew prose is correct.
2. Nikud survives with the marks on the right base letters.
3. The mixed-script line is the entire limitation in one row: the Hebrew is
   right, and the English, the parentheses and the number are all reversed.
   That is the absent bidi, visible.

While you are here, run the probe on your own build:

```sh
nvim --headless -u NONE -l tests/probe.lua
```

It reports which RTL options your Neovim actually has, and how many Hebrew
keymap files its runtime ships. Worth doing before believing anything written
about Vim's RTL support — this documentation included. The answer has changed
across versions.

## 4. The five minutes that matter

Open a Hebrew file. It should mirror itself.

```vim
:English      " turn it off for this buffer
:Hebrew       " turn it back on
<F8>          " toggle
```

Now the important part: **open a Lua file in the same window.**

It should be left-to-right, and the whole editor should not be mirrored. That
is the bug the plugin exists to fix — `rightleft` is a *window* option, so
without something re-applying the decision every time a buffer is displayed,
opening a Lua file in a window that was showing Hebrew leaves your entire
editor backwards.

Switch back to the Hebrew file. It should still be RTL, and if you used
`:English` on it earlier, it should still be English — explicit choices are
remembered per buffer and survive switching away and back.

That round trip is the whole behavioural contract. If it works, you are set up
correctly.

## 5. How the decision gets made

Three inputs, checked in this order.

### Never-RTL filetypes win outright

```lua
never_rtl = {
  orgagenda = true, help = true, qf = true, netrw = true,
  TelescopePrompt = true, TelescopeResults = true,
}
```

These are generated, column-aligned buffers. Mirror an agenda or a quickfix
list and the date column, the tags and the filenames stop lining up. Whatever
they contain, they are not mirrored.

Add your own with `:set filetype?` to find the name. The table is merged, so
adding one entry does not drop the defaults.

### Content detection

Counts RTL versus Latin letters in the first `sample_lines` (default 50) lines;
RTL wins a plurality and the buffer is marked RTL.

The count is byte-level on purpose. LuaJIT has no `utf8` library, and the
ranges are compact in UTF-8 lead bytes — Hebrew `0xD6`/`0xD7`, Arabic
`0xD8`–`0xDB` — so the lead byte alone is signal enough for a heuristic.

It loses the vote on a Hebrew file with a long English preamble, YAML front
matter, or a code fence at the top. Raise `sample_lines`, or use the filename
tag.

### The filename tag

```
notes.he.md
```

`filename_pattern` (default `%.he%.`) forces RTL — but **only for prose
filetypes**:

```lua
prose_filetypes = { markdown = true, text = true, tex = true,
                    asciidoc = true, org = true },
```

A correctly-named file whose filetype is not in that table is the usual reason
the tag appears to be ignored.

### And your explicit choice beats all of them

`:Hebrew`, `:English` and `:RtlToggle` record the decision against the buffer.
It survives switching away and back, and is forgotten when the buffer is
deleted.

## 6. Typing Hebrew

```lua
keymap = "hebrew",     -- standard Israeli layout; "hebrewp" for phonetic
```

This installs 237 `lmap` entries — `,` to ת and so on — so you type Hebrew
inside Neovim **without switching your OS layout**, and normal-mode commands
keep working. `lmap` applies to insert mode, the command line and search; `dd`
is still `dd`.

It follows the direction: when the plugin turns RTL on for a buffer it sets
`keymap`, and when it turns RTL off it clears it.

If your OS already switches layouts for you, set `keymap = false` and let it.
Running both means your keystrokes get translated twice.

Two related settings:

```lua
rightleftcmd = "search",   -- mirror the search prompt too
revins = false,            -- leave this alone
```

`revins` is off deliberately: with `rightleft` the cursor already advances
leftward, and enabling both cancels out. It is exposed only because someone
will want it for a setup nobody has thought of.

### Fixing a mis-typed vowel

The plugin sets `delcombine`, so `x` removes combining characters one at a time
before removing the base letter. You can correct nikud without retyping the
word.

## 7. Tune it

Every option, with its default:

```lua
require("rtl").setup({
  auto_detect = true,
  sample_lines = 50,
  keymap = "hebrew",
  rightleftcmd = "search",
  revins = false,
  toggle_key = "<F8>",

  prose_filetypes = { markdown = true, text = true, tex = true,
                      asciidoc = true, org = true },
  filename_pattern = "%.he%.",

  never_rtl = {
    orgagenda = true, help = true, qf = true, netrw = true,
    TelescopePrompt = true, TelescopeResults = true,
  },

  statusline = { rtl = "עב", ltr = "" },

  integrations = {
    telescope = { enabled = true, keymap = true, rightleft = true },
    orgmode   = { enabled = true, agenda_rtl = false },
  },
})
```

Pass any subset — the table is deep-merged, so overriding one key inside
`never_rtl` or `integrations` does not drop the rest.

### Statusline

```lua
sections = { lualine_x = { require("rtl").statusline } }
```

Returns `statusline.rtl` when the current window is mirrored and
`statusline.ltr` otherwise. Useful mostly because "which direction am I in" is
otherwise invisible until you type something.

### The Lua API

```lua
local rtl = require("rtl")
rtl.setup(opts)            -- configure and install autocommands
rtl.set(on)                -- apply to the current window/buffer, no memory
rtl.override(on, buf)      -- apply and remember against the buffer
rtl.toggle()               -- flip the current buffer
rtl.is_rtl(buf)            -- is this buffer marked RTL
rtl.detect(buf, sample)    -- run the heuristic, return a boolean
rtl.statusline()           -- statusline component
```

`:help rtl` has the full reference; `doc/rtl.txt` is the source.

## 8. Integrations

Both are optional and both are **guarded**: if the plugin is not installed, the
hook is skipped silently rather than erroring at startup. `rtl.nvim` declares no
dependencies and must keep working with none of them present.

A failing integration warns with `rtl.nvim: <name> integration failed: ...`
rather than taking startup down.

### Telescope

```lua
integrations = { telescope = { enabled = true, keymap = true, rightleft = true } }
```

The useful half is `keymap` on the prompt buffer: you type Hebrew into a picker
without switching your OS layout, which is otherwise the most annoying part of
searching a Hebrew notes directory.

The prompt follows **the buffer you opened the picker from** — a picker opened
over an English buffer stays English. Mid-search, `<C-l>` flips it, for finding
an English filename from inside a Hebrew buffer.

Only the prompt is mirrored. It is a one-line buffer, so that is safe; the
results and preview windows are column-aligned and deliberately left alone,
which is why `TelescopePrompt` and `TelescopeResults` are in `never_rtl`.

### nvim-orgmode

```lua
integrations = { orgmode = { enabled = true, agenda_rtl = false } }
```

Org files are both the case where RTL layout works best and the case where it is
most surprising, so be ready for this: under `rightleft` the structural markers
move to the right edge. A heading reads with its stars on the right, and
`#+TITLE:` keywords are reversed on screen because they are Latin runs on an
otherwise Hebrew line.

The prose looks right and the keyword lines look wrong. Both are the same
missing-bidi fact from §1.

The integration also re-decides on `FileType`, because orgmode often opens org
buffers itself rather than by `:edit`, and `BufReadPost` may have run before the
filetype was known.

The agenda is left alone — `agenda_rtl` defaults to `false` and `orgagenda` is
in `never_rtl`. It is a generated, column-aligned buffer; mirror it and the date
column, the tags and the filenames stop lining up.

## 9. A worked setup

`examples/` is a complete, working Neovim configuration built around Hebrew
prose — not a snippet, a whole `init.lua` with a `lazy-lock.json`. Read
`examples/lua/plugins/rtl.lua` for this plugin's spec in context, and the
others for how the rest of a writing setup fits around it.

Worth copying from even if you keep your own config.

## 10. Contributing

```sh
nvim --headless -u NONE -l tests/spec.lua     # behaviour; exits non-zero on failure
nvim --headless -u NONE -l tests/probe.lua    # what RTL options this Neovim has
nvim --headless -u NONE -l tests/lint.lua     # Lua syntax, plugin and examples
python tests/render.py --plugin               # rendered screen grids
```

CI runs all four on Linux and Windows against both `stable` and `nightly`
Neovim.

The important thing to understand before changing anything: **`spec.lua` cannot
see the screen.** Behaviour tests check options and decisions; they cannot check
cell placement, which is the actual product. A change that keeps `spec.lua`
green can still render backwards. That is why the repository ships a pty
harness, and why `render.py` runs in CI.

If your change affects what is drawn, run `render.py` and read the grids.

---

## Where to go next

- [../README.md](../README.md) — the summary, the ceiling, and the options.
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — symptom-first. Worth skimming the
  headings now.
- `:help rtl` (or [`../doc/rtl.txt`](../doc/rtl.txt)) — the reference, including
  what fixing bidi properly would actually take.
- [`../examples/`](../examples/) — a whole config that uses this.
