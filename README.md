# rtl.nvim

Right-to-left writing support for Neovim, aimed at Hebrew prose.

Neovim ships everything needed for RTL *layout* and has for years. What it does
not ship is anything that decides when to turn it on, and the options involved
are scoped in a way that bites you the first time you open a second file. This
plugin is the missing glue, plus an honest account of where the ceiling is.

## What it does

- Detects RTL buffers from their contents and turns on `rightleft`,
  `rightleftcmd`, and `keymap=hebrew` automatically.
- Turns it back **off** when you open a Latin-script file. `rightleft` is a
  *window* option, so without this, opening a Lua file in a window that was
  showing Hebrew leaves your whole editor mirrored. This is the bug that
  motivated the plugin.
- `:Hebrew`, `:English`, `:RtlToggle`, and `<F8>` for explicit control,
  remembered per buffer so an override survives switching away and back.

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

Neovim's default, cell 0 on the left, so the first letter of שלום lands on the
left — backwards for a Hebrew reader:

```
|שלום עולם                                                 |
|זה שורה שלישית בעברית                                     |
|בְּרֵאשִׁית בָּרָא אֱלֹהִים                                          |
|mixed line: עברית and English (42)                        |
```

With the plugin, Neovim reverses the cell order itself. The grid content now
reads `םלוע םולש` and is right-aligned, which on screen is correct Hebrew:

```
|                                                 םלוע םולש|
|                                     תירבעב תישילש הרוש הז|
|                                          םיהִלֹאֱ ארָבָּ תישִׁארֵבְּ|
|                        )24( hsilgnE dna תירבע :enil dexim|
```

Three things that grid demonstrates rather than asserts:

1. Hebrew prose is correct.
2. Nikud survives — `בְּרֵאשִׁית בָּרָא אֱלֹהִים` keeps its marks on the right base
   letters. How well they *stack* is your font's problem, not Neovim's.
3. The last line is the entire limitation in one row of output: the Hebrew is
   right, and the English, the parentheses and the number are all reversed.
   That is the absent bidi, visible.

One consequence worth knowing: Neovim does the mirroring itself, so your
terminal must **not** also apply bidi or you get a double reversal. Most
terminals (including Windows Terminal) do nothing, which is what you want.
`mlterm` is the notable one that tries.

## Install

**lazy.nvim**

```lua
{
  "USER/rtl.nvim",
  ft = { "markdown", "text", "tex" },   -- or drop this to always load
  opts = {},
}
```

**packer.nvim**

```lua
use { "USER/rtl.nvim", config = function() require("rtl").setup() end }
```

**No plugin manager** — clone anywhere on your `runtimepath` and call
`require("rtl").setup()` from your `init.lua`.

`setup()` is required for auto-detection. The commands work without it.

## Configuration

Defaults shown; pass any subset.

```lua
require("rtl").setup({
  auto_detect = true,        -- decide RTL from buffer contents
  sample_lines = 50,         -- how many lines to sample when detecting
  keymap = "hebrew",         -- 'keymap' value when RTL is on; "hebrewp" for
                             -- phonetic, or false to use your OS layout
  rightleftcmd = "search",   -- mirror the search prompt too
  revins = false,            -- see note below
  toggle_key = "<F8>",       -- false to skip the mapping
  prose_filetypes = { markdown = true, text = true, tex = true, asciidoc = true },
  filename_pattern = "%.he%.",  -- notes.he.md forces RTL for prose filetypes
})
```

`revins` is off deliberately. With `rightleft` the cursor already advances
leftward; enabling both cancels out. It is exposed only because someone will
want it for a setup I have not thought of.

`keymap = "hebrew"` installs 237 `lmap` entries — the standard Israeli layout,
`,`→ת and so on — so you type Hebrew inside Neovim without switching your OS
layout, and normal-mode commands keep working.

## Detection heuristic

Counts RTL versus Latin letters in the first `sample_lines` lines; RTL wins a
plurality and the buffer is marked RTL. The count is byte-level on purpose:
LuaJIT has no `utf8` library, and the ranges are compact in UTF-8 lead bytes
(Hebrew `0xD6`/`0xD7`, Arabic `0xD8`–`0xDB`), so the lead byte alone is signal
enough for a heuristic. Prose files can also be tagged by name —
`notes.he.md`.

When it guesses wrong, `:Hebrew` or `:English` settles it, and the choice
sticks to that buffer.

## Tests

```
nvim --headless -u NONE -l tests/spec.lua     # behaviour, exits non-zero on failure
nvim --headless -u NONE -l tests/probe.lua    # what RTL options this Neovim has
python tests/render.py --plugin               # rendered screen grids
```

`probe.lua` is worth running on your own build before believing anything
written about Vim's RTL support, this README included — the answer has changed
across versions. On Neovim 0.12.4 all of `rightleft`, `rightleftcmd`, `revins`,
`keymap`, `delcombine`, `arabic`, `arabicshape`, `termbidi`, `hkmap` and
`hkmapp` are present, and the runtime ships eight Hebrew keymap files.

## License

MIT.
