# Troubleshooting

RTL is the one Neovim feature you cannot verify by inspecting options —
`rightleft` changes which screen *cell* a character lands in, so the only
honest check is a rendered grid. Two commands are worth running before
anything else on this page:

```sh
nvim --headless -u NONE -l tests/probe.lua    # what RTL support this Neovim has
python tests/render.py --plugin               # what the screen actually shows
```

Run the grids **in your own terminal**. They are deliberately not reproduced
in any document in this repository: a grid dump is in *visual* order, and any
viewer that applies the bidirectional algorithm to the file — GitHub, your
browser — reorders it again and shows you the opposite of what the dump says.
The output is only trustworthy where it is produced.

---

## Contents

- [Text renders backwards](#text-renders-backwards)
- [RTL turns on or off when it should not](#rtl-turns-on-or-off-when-it-should-not)
- [Typing Hebrew](#typing-hebrew)
- [Nikud and fonts](#nikud-and-fonts)
- [Specific buffers look scrambled](#specific-buffers-look-scrambled)
- [Integrations](#integrations)
- [Installation and loading](#installation-and-loading)
- [Terminals and environments](#terminals-and-environments)
- [Running the tests](#running-the-tests)

---

## Text renders backwards

### A line with both Hebrew and English shows one of them reversed

**Not fixable, and not a bug in this plugin.** This is the ceiling, stated in
the README and in `doc/rtl.txt`.

Neovim gives right-to-left *layout*, not the Unicode bidirectional algorithm.
It mirrors the window and reverses the cell order; it does not reorder mixed
RTL/LTR runs within a line, because its rendering model assumes buffer bytes
map monotonically onto screen cells and bidi breaks that assumption at the
foundation.

So on a mixed line the Hebrew is right and the English, the parentheses and the
numbers are all reversed. No configuration changes this. `tests/render.py`
shows it in one row of output.

If you need correct mixed-script rendering, you need an editor with a real
text-shaping stack underneath. Emacs does the full UBA and has for a long time.

### Everything renders backwards, in both scripts

Double reversal. Neovim does the mirroring itself, so your terminal must **not**
also apply bidi — if it does, the two cancel into nonsense.

Most terminals do nothing, which is what you want. Windows Terminal does
nothing. `mlterm` is the notable one that tries; disable its bidi handling or
use a different terminal.

Check by opening the same file with the plugin off (`:English`). If it looks
*correct* with the plugin off and wrong with it on, and the file is monolingual
Hebrew, your terminal is doing the reordering.

### Hebrew prose is left-aligned with the first letter on the left

That is Neovim's default — cell 0 on the left — which is backwards for a Hebrew
reader. It means `rightleft` is not on for this window.

```vim
:set rightleft?
:Hebrew
```

If `:Hebrew` fixes it, auto-detection did not fire. See the next section.

## RTL turns on or off when it should not

### Detection guessed wrong

The heuristic counts RTL versus Latin letters in the first `sample_lines`
(default 50) lines and takes a plurality. A Hebrew file with a long English
preamble, a YAML front-matter block, or a code fence at the top will lose that
vote.

Three fixes, in increasing order of permanence:

```vim
:Hebrew
```

The choice sticks to that buffer and survives switching away and back.

```lua
sample_lines = 200      -- look further before deciding
```

```
notes.he.md             -- the filename tag
```

The filename tag (`filename_pattern`, default `%.he%.`) forces RTL — but **only
for prose filetypes**. If your file's filetype is not in `prose_filetypes`
(`markdown`, `text`, `tex`, `asciidoc`, `org` by default), the tag is ignored.
That is the usual reason a correctly-named file is not detected.

### Auto-detection never fires at all

`setup()` is required for auto-detection. The commands (`:Hebrew`, `:English`,
`:RtlToggle`) work without it, because they are defined in `plugin/rtl.lua`,
which loads unconditionally — so "the commands work but nothing is automatic"
is exactly the symptom of `setup()` not having run.

With lazy.nvim, `opts = {}` calls it for you. With packer or a manual install
you must call `require("rtl").setup()` yourself.

Also check you have not disabled it:

```lua
auto_detect = true      -- the default
```

### Opening a Lua file leaves my whole editor mirrored

This is the bug the plugin exists to fix, so if you are seeing it, the plugin
is not active in that window.

`rightleft` is a **window** option, not a buffer option. Without something
re-applying the decision on `BufWinEnter`, opening an LTR file in a window that
was showing Hebrew leaves the window mirrored. The plugin hooks `BufWinEnter`
for exactly this.

Confirm the autocommand group exists:

```vim
:autocmd rtl.nvim
```

If that is empty, `setup()` has not run.

### A split shows the wrong direction

Both windows show the same buffer but `rightleft` belongs to the window. The
plugin re-applies on `BufWinEnter`, which fires when a buffer is displayed in a
window — including a new split. If a split is stale, switching away and back
will fix it; if it happens repeatedly, that is worth reporting with the exact
sequence.

### `:RtlToggle` and `<F8>` do nothing

`toggle_key` may be set to `false`, or something else may have claimed `<F8>`.

```vim
:verbose nmap <F8>
```

Pick another key:

```lua
toggle_key = "<leader>r"
```

## Typing Hebrew

### The Hebrew keymap is not active

`keymap = "hebrew"` installs 237 `lmap` entries — the standard Israeli layout,
`,` to ת and so on — so you type Hebrew inside Neovim without switching your OS
layout, and normal-mode commands keep working.

```vim
:set keymap?
```

Empty means it is off. Causes, in order of likelihood:

1. `rightleft` is off for this window, so the plugin left `keymap` alone. Fix
   the direction first.
2. `keymap = false` in your config, which is the setting for "I use my OS
   layout".
3. Your Neovim's runtime does not ship the Hebrew keymap files. `probe.lua`
   reports how many it found; a stock build has eight.

### I want the phonetic layout instead

```lua
keymap = "hebrewp"
```

### Typing Hebrew fights with my OS layout

Pick one. If your OS is already switching layouts, set `keymap = false` and let
it. Running both means your keystrokes are translated twice.

### Normal-mode commands broke while in Hebrew

They should not — `lmap` applies to insert mode, command-line mode and search,
not to normal mode. If `dd` has stopped working while `keymap` is set, that is
a real bug worth reporting.

### The search prompt is not mirrored

```lua
rightleftcmd = "search"    -- the default
```

Set to `""` to leave the prompt alone.

### The cursor moves the wrong way in insert mode

Check `revins`. It is off deliberately: with `rightleft` the cursor already
advances leftward, and enabling both cancels out. It is exposed only for setups
nobody has thought of yet.

```lua
revins = false             -- the default; leave it
```

## Nikud and fonts

### Nikud marks land on the wrong letter

They should not — the grids in `tests/render.py` show nikud surviving with the
marks on the correct base letters. If you are seeing otherwise, capture a grid
dump and report it.

### Nikud stacks badly, overlaps, or clips

**Your font's problem, not Neovim's and not this plugin's.** Neovim places the
combining marks on the right base characters; how they are composed and drawn
is the font and the terminal's shaping.

Terminal fonts vary enormously here. If nikud matters to you, try a font with
good Hebrew coverage and mark positioning.

### Deleting a vowelled letter deletes only the mark

The plugin sets `delcombine = true`, so `x` removes combining characters one at
a time before removing the base letter. That is deliberate — it is how you fix
a mis-typed nikud without retyping the word.

If you want the whole character gone at once:

```vim
:set nodelcombine
```

Note this is a global option and the plugin sets it whenever it applies a
direction.

## Specific buffers look scrambled

### The quickfix list, help, or netrw is mirrored

They should not be. These are generated, column-aligned buffers where
`rightleft` destroys the layout, so they are in the default `never_rtl` set:

```lua
never_rtl = {
  orgagenda = true, help = true, qf = true, netrw = true,
  TelescopePrompt = true, TelescopeResults = true,
}
```

If one of yours is mirrored, add its filetype:

```vim
:set filetype?
```

```lua
never_rtl = { ["your-filetype"] = true },
```

Note that `vim.tbl_deep_extend("force", ...)` merges this table, so adding one
entry does not drop the defaults.

### An org file's headings and `#+KEYWORD:` lines look reversed

Expected, and it is the missing-bidi limitation again, not an orgmode problem.

Under `rightleft` the structural markers move to the right edge: a heading
reads with its stars on the right, and `#+TITLE:` keywords are reversed on
screen because they are Latin runs on an otherwise Hebrew line. The prose looks
right; the drawer and keyword lines look wrong. Both are the same fact.

### The org agenda is mirrored and the columns no longer line up

It should not be. `agenda_rtl` defaults to `false` and `orgagenda` is in
`never_rtl`. If it is happening, check you have not turned it on:

```lua
integrations = { orgmode = { agenda_rtl = false } }
```

## Integrations

Every integration is guarded: if the plugin is not installed, the hook is
skipped **silently** rather than erroring at startup. `rtl.nvim` declares no
dependencies and must keep working with none of them present.

A failing integration produces a `vim.notify` warning naming which one and why,
rather than taking startup down with it. If you see
`rtl.nvim: <name> integration failed: ...`, that message is the whole diagnosis.

### Telescope: I cannot type Hebrew into the picker

The prompt follows **the buffer you opened the picker from**. A picker opened
over an English buffer stays English, deliberately.

Mid-search, `<C-l>` flips the prompt — for finding an English filename from
inside a Hebrew buffer, and the reverse.

Check it is enabled:

```lua
integrations = { telescope = { enabled = true, keymap = true, rightleft = true } }
```

### Telescope: the results or preview window is mirrored

It should not be. Only the prompt is mirrored — it is a one-line buffer, so
mirroring it is safe. The results and preview windows are column-aligned and
deliberately left alone; `TelescopePrompt` and `TelescopeResults` are both in
the default `never_rtl` set.

### Orgmode: an org file opened by orgmode itself is not detected

Handled. Org buffers are often opened by orgmode rather than by `:edit`, so
`BufReadPost` may have run before the filetype was known. The integration
re-decides on `FileType`, which orgmode always triggers.

If it is still not firing, confirm the integration is on and that `orgmode` is
actually loadable at the time `setup()` runs — a lazy-loaded orgmode that has
not loaded yet will fail the `pcall(require, "orgmode")` guard.

## Installation and loading

### The commands exist but nothing is automatic

`setup()` has not run. See
[auto-detection never fires](#auto-detection-never-fires-at-all).

### Nothing works at all

```vim
:lua print(vim.g.loaded_rtl_nvim)
```

`nil` means `plugin/rtl.lua` never loaded — the plugin is not on your
`runtimepath`. With a plugin manager, check its status; without one, confirm
the clone location.

### With lazy.nvim, the plugin does not load for my filetype

The suggested spec lazy-loads:

```lua
{ "SYKhayyat/rtl.nvim", ft = { "markdown", "text", "tex" }, opts = {} }
```

Add your filetype, or drop `ft` entirely to always load. Note that lazy-loading
by filetype means the `BufWinEnter` handler is not installed until the first
matching file is opened — so the "mirrored editor" bug can still bite you once,
before the plugin loads.

If that matters, load it eagerly.

## Terminals and environments

### It works in one terminal and not another

See [double reversal](#everything-renders-backwards-in-both-scripts). The
terminal must not apply bidi of its own.

### It works in the terminal and not in a GUI client

GUI clients (Neovide, nvim-qt, and the various embedders) do their own text
rendering and may or may not honour `rightleft` the way a terminal grid does.
`probe.lua` reports what the *Neovim* supports; how the front end draws it is
separate.

### Which Neovim versions are supported?

CI runs Linux and Windows against both `stable` and `nightly`.

`probe.lua` is worth running on your own build before believing anything
written about Vim's RTL support, this documentation included — the answer has
changed across versions. On Neovim 0.12.4 all of `rightleft`, `rightleftcmd`,
`revins`, `keymap`, `delcombine`, `arabic`, `arabicshape`, `termbidi`, `hkmap`
and `hkmapp` are present, and the runtime ships eight Hebrew keymap files.

## Running the tests

```sh
nvim --headless -u NONE -l tests/spec.lua     # behaviour; exits non-zero on failure
nvim --headless -u NONE -l tests/probe.lua    # what RTL options this Neovim has
nvim --headless -u NONE -l tests/lint.lua     # Lua syntax, plugin and example config
python -m pip install -r tests/requirements.txt
python tests/render.py --plugin               # rendered screen grids
```

### `render.py` fails to start

It drives real Neovim inside a pty. Requirements:

- Python 3.12 (what CI uses).
- `pip install -r tests/requirements.txt`.
- A `nvim` on `PATH`, or the `NVIM` environment variable pointing at one —
  which is how CI passes a specific build.

```sh
NVIM=/path/to/nvim python tests/render.py --plugin
```

### `probe.lua` reports missing options

Then this Neovim genuinely lacks them, and the plugin can only do what the
editor supports. That is the point of the probe: it tells you what is true of
*your* build rather than what was true of the author's.

### `spec.lua` passes but the screen still looks wrong

Expected and important. Behaviour tests check options and decisions; they
cannot check cell placement. That is what `render.py` is for, and it is why the
repository ships a pty harness at all.

---

## Reporting something not on this page

Include:

- `nvim --version`
- the output of `nvim --headless -u NONE -l tests/probe.lua`
- your terminal, and whether it applies bidi
- a `tests/render.py` grid if the complaint is about what you see on screen —
  described in words, since the grid itself will be reordered by whatever you
  paste it into
