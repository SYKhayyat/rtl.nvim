# rtl.nvim

Right-to-left writing support for Neovim, aimed at Hebrew prose.

Neovim ships everything needed for RTL *layout* and has for years. What it does
not ship is anything that decides when to turn it on, and the options involved
are scoped in a way that bites you the first time you open a second file. This
plugin is the missing glue, plus an honest account of where the ceiling is.

**New here?** [docs/ONBOARDING.md](docs/ONBOARDING.md) walks the whole setup
including how to see it working. **Something misbehaving?**
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) is symptom-first.

## What it does

- Detects RTL buffers from their contents and turns on `rightleft`,
  `rightleftcmd`, and `keymap=hebrew` automatically.
- Turns it back **off** when you open a Latin-script file. `rightleft` is a
  *window* option, so without this, opening a Lua file in a window that was
  showing Hebrew leaves your whole editor mirrored. This is the bug that
  motivated the plugin.
- Leaves generated, column-aligned buffers alone — quickfix, help, netrw, the
  org agenda, Telescope's results — because mirroring them destroys the
  columns.
- `:Hebrew`, `:English`, `:RtlToggle`, and `<F8>` for explicit control,
  remembered per buffer so an override survives switching away and back.
- Optional, dependency-free hooks into Telescope and nvim-orgmode.

## What it does not do

It gives right-to-left **layout**, not the Unicode bidirectional algorithm.
Neovim mirrors the window and reverses the cell order; it does not reorder
mixed RTL/LTR runs within a line, because its rendering model assumes buffer
bytes map monotonically onto screen cells, and bidi breaks that assumption at
the foundation.

In practice:

- **Monolingual Hebrew prose renders correctly.** This is the case the plugin
  is for, and it is genuinely correct, not merely tolerable.
- **A line containing both scripts will render one of them backwards.** No
  configuration fixes this. See below.

If you need correct mixed-script rendering, you need an editor with a real
text-shaping stack underneath it — Emacs does the full UBA and has for a long
time. This plugin will not get you there and does not pretend to.

## Seeing it, rather than taking my word for it

RTL is the one Neovim feature you cannot verify by inspecting options —
`rightleft` changes which screen *cell* a character lands in. So the repo
ships a harness that drives real Neovim inside a pty and dumps the grid:

```
python -m pip install -r tests/requirements.txt
python tests/render.py --plugin
```

Neovim's default puts cell 0 on the left, so the first letter of a Hebrew word
lands on the left — backwards for a Hebrew reader. With the plugin, Neovim
reverses the cell order itself and the text is right-aligned, which on screen
is correct Hebrew.

Run the harness and read the grids in your own terminal. They are deliberately
not reproduced here: a grid dump is in *visual* order, and any viewer that
applies the bidirectional algorithm to this file — GitHub, your browser —
reorders it again and shows you the opposite of what the dump says. The output
is only trustworthy where it is produced.

Three things the grids show rather than assert:

1. Hebrew prose is correct.
2. Nikud survives, with the marks staying on the right base letters. How well
   they *stack* is your font's problem, not Neovim's.
3. The mixed-script line is the entire limitation in one row of output: the
   Hebrew is right, and the English, the parentheses and the number are all
   reversed. That is the absent bidi, visible.

One consequence worth knowing: Neovim does the mirroring itself, so your
terminal must **not** also apply bidi or you get a double reversal. Most
terminals (including Windows Terminal) do nothing, which is what you want.
`mlterm` is the notable one that tries.

## Install

**lazy.nvim**

```lua
{
  "SYKhayyat/rtl.nvim",
  ft = { "markdown", "text", "tex" },   -- or drop this to always load
  opts = {},
}
```

**packer.nvim**

```lua
use { "SYKhayyat/rtl.nvim", config = function() require("rtl").setup() end }
```

**No plugin manager** — clone anywhere on your `runtimepath` and call
`require("rtl").setup()` from your `init.lua`.

`setup()` is required for auto-detection. The commands work without it — which
is exactly what "the commands work but nothing is automatic" means when you see
it.

## Configuration

Every option, with its default. Pass any subset; the table is deep-merged, so
overriding one key inside `never_rtl` or `integrations` does not drop the rest.

```lua
require("rtl").setup({
  auto_detect = true,        -- decide RTL from buffer contents
  sample_lines = 50,         -- how many lines to sample when detecting
  keymap = "hebrew",         -- 'keymap' value when RTL is on; "hebrewp" for
                             -- phonetic, or false to use your OS layout
  rightleftcmd = "search",   -- mirror the search prompt too
  revins = false,            -- see note below
  toggle_key = "<F8>",       -- false to skip the mapping

  -- Filetypes where a filename tag is honoured, and the tag itself.
  prose_filetypes = { markdown = true, text = true, tex = true,
                      asciidoc = true, org = true },
  filename_pattern = "%.he%.",  -- notes.he.md forces RTL for prose filetypes

  -- Generated, column-aligned buffers that are never mirrored, whatever they
  -- contain. Mirroring an agenda or a quickfix list destroys the columns.
  never_rtl = {
    orgagenda = true, help = true, qf = true, netrw = true,
    TelescopePrompt = true, TelescopeResults = true,
  },

  -- What rtl.statusline() returns in each state.
  statusline = { rtl = "עב", ltr = "" },

  -- Optional hooks into other plugins. Each is skipped silently when the
  -- plugin is not installed.
  integrations = {
    telescope = {
      enabled = true,
      keymap = true,     -- type Hebrew into the picker without switching
                         -- your OS layout
      rightleft = true,  -- mirror the prompt while RTL is active
    },
    orgmode = {
      enabled = true,
      agenda_rtl = false,  -- the agenda is column-aligned; mirroring it
                           -- destroys the alignment
    },
  },
})
```

`revins` is off deliberately. With `rightleft` the cursor already advances
leftward; enabling both cancels out. It is exposed only because someone will
want it for a setup I have not thought of.

`keymap = "hebrew"` installs 237 `lmap` entries — the standard Israeli layout,
`,`→ת and so on — so you type Hebrew inside Neovim without switching your OS
layout, and normal-mode commands keep working.

### Statusline

```lua
sections = { lualine_x = { require("rtl").statusline } }
```

Returns `statusline.rtl` when the current window is mirrored and
`statusline.ltr` otherwise.

## Integrations

Both are optional, both are off if the plugin is not installed, and `rtl.nvim`
declares no dependencies. A guard that fails warns and carries on rather than
taking startup down with it.

**Telescope.** Lets you type Hebrew into a picker without switching your OS
layout. The prompt follows the buffer you opened the picker from, so a picker
opened over an English buffer stays English; `<C-l>` flips it mid-search. Only
the prompt is mirrored — it is a one-line buffer, so that is safe — while the
results and preview windows are column-aligned and left alone.

**nvim-orgmode.** Re-decides direction on `FileType`, because orgmode often
opens org buffers itself and `BufReadPost` may run before the filetype is
known. The agenda is never mirrored.

Org files are worth one warning: under `rightleft` the structural markers move
to the right edge, so a heading reads with its stars on the right and
`#+TITLE:` keywords are reversed on screen. The prose looks right and the
keyword lines look wrong. Both are the same missing-bidi fact described above.

## Detection heuristic

Counts RTL versus Latin letters in the first `sample_lines` lines; RTL wins a
plurality and the buffer is marked RTL. The count is byte-level on purpose:
LuaJIT has no `utf8` library, and the ranges are compact in UTF-8 lead bytes
(Hebrew `0xD6`/`0xD7`, Arabic `0xD8`–`0xDB`), so the lead byte alone is signal
enough for a heuristic. Prose files can also be tagged by name —
`notes.he.md`.

When it guesses wrong, `:Hebrew` or `:English` settles it, and the choice
sticks to that buffer.

## API

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

`:help rtl` has the full reference, including what fixing bidi properly would
take.

## Example configuration

[`examples/`](examples/) is a complete, working Neovim configuration built
around Hebrew prose — a whole `init.lua` with a `lazy-lock.json`, not a
snippet. Worth reading even if you keep your own.

## Tests

```
nvim --headless -u NONE -l tests/spec.lua     # behaviour, exits non-zero on failure
nvim --headless -u NONE -l tests/probe.lua    # what RTL options this Neovim has
nvim --headless -u NONE -l tests/lint.lua     # Lua syntax, plugin and examples
python tests/render.py --plugin               # rendered screen grids
```

CI runs all four on Linux and Windows, against both `stable` and `nightly`.

`probe.lua` is worth running on your own build before believing anything
written about Vim's RTL support, this README included — the answer has changed
across versions. On Neovim 0.12.4 all of `rightleft`, `rightleftcmd`, `revins`,
`keymap`, `delcombine`, `arabic`, `arabicshape`, `termbidi`, `hkmap` and
`hkmapp` are present, and the runtime ships eight Hebrew keymap files.

Note that `spec.lua` cannot see the screen. Behaviour tests check options and
decisions; they cannot check cell placement, which is the actual product. A
change that keeps `spec.lua` green can still render backwards — which is why
the pty harness exists and why it runs in CI.

## License

MIT.
