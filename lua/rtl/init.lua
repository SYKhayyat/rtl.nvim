-- rtl.nvim -- right-to-left writing support for Neovim.
--
-- Scope, stated up front: this gives right-to-left *layout*, not the Unicode
-- bidirectional algorithm. Neovim mirrors the window and reverses the cell
-- order; it does not reorder mixed RTL/LTR runs within a line. Monolingual
-- Hebrew prose renders correctly. A line containing both scripts will render
-- one of them backwards. That is a limitation of Neovim itself -- see
-- doc/rtl.txt for what it would take to fix, and tests/ for a screen dump
-- that demonstrates it.

local M = {}

local defaults = {
  -- Decide RTL automatically from buffer contents.
  auto_detect = true,

  -- How many lines to sample when detecting.
  sample_lines = 50,

  -- Value for 'keymap' when RTL is on. Neovim ships "hebrew" (standard
  -- Israeli layout) and "hebrewp" (phonetic). Set to false to leave
  -- 'keymap' alone and rely on your OS layout instead.
  keymap = "hebrew",

  -- Mirror the search prompt too.
  rightleftcmd = "search",

  -- 'revins' is off on purpose: with 'rightleft' the cursor already
  -- advances leftward, and enabling both cancels out. Exposed anyway.
  revins = false,

  -- Key that toggles RTL for the current buffer. Set to false to skip.
  toggle_key = "<F8>",

  -- Filetypes treated as prose, where a filename tag is honoured.
  prose_filetypes = { markdown = true, text = true, tex = true, asciidoc = true },

  -- Filename tag that forces RTL for prose filetypes, e.g. notes.he.md
  filename_pattern = "%.he%.",
}

M.config = vim.deepcopy(defaults)

-- Per-buffer RTL decision, so an explicit :Hebrew / :English survives
-- switching away from the buffer and back.
local decided = {}

--- Count RTL vs Latin letters in the first N lines of a buffer.
---
--- Byte-level on purpose: LuaJIT has no utf8 library, and the relevant
--- ranges are compact in UTF-8 lead bytes --
---   Hebrew   U+0590-U+05FF -> 0xD6 0x90 .. 0xD7 0xBF
---   Arabic   U+0600-U+06FF -> 0xD8 0x80 .. 0xDB 0xBF
--- so the lead byte alone is signal enough for a heuristic.
---@param buf integer
---@param sample integer|nil
---@return boolean
function M.detect(buf, sample)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, sample or M.config.sample_lines, false)
  local rtl, ltr = 0, 0
  for _, line in ipairs(lines) do
    for i = 1, #line do
      local b = line:byte(i)
      if b == 0xD6 or b == 0xD7 or (b >= 0xD8 and b <= 0xDB) then
        rtl = rtl + 1
      elseif (b >= 0x41 and b <= 0x5A) or (b >= 0x61 and b <= 0x7A) then
        ltr = ltr + 1
      end
    end
  end
  return rtl > ltr
end

--- Apply RTL to the current window and buffer.
---
--- 'rightleft' is a *window* option and 'keymap' is a buffer option, which is
--- why this has to run on BufWinEnter and not just once per buffer.
---@param on boolean
function M.set(on)
  local c = M.config
  vim.wo.rightleft = on
  vim.wo.rightleftcmd = on and c.rightleftcmd or ""
  if c.keymap then
    vim.bo.keymap = on and c.keymap or ""
  end
  if c.revins then
    vim.wo.revins = on
  end
  vim.opt.delcombine = true
end

--- Set RTL and remember the choice against the buffer.
---@param on boolean
---@param buf integer|nil
function M.override(on, buf)
  decided[buf or vim.api.nvim_get_current_buf()] = on
  M.set(on)
end

--- Flip RTL for the current buffer.
function M.toggle()
  local on = not vim.wo.rightleft
  M.override(on)
  vim.notify("RTL " .. (on and "on" or "off"))
end

--- Whether the given buffer is currently marked RTL.
---@param buf integer|nil
---@return boolean
function M.is_rtl(buf)
  return decided[buf or vim.api.nvim_get_current_buf()] == true
end

---@param opts table|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  local c = M.config
  local group = vim.api.nvim_create_augroup("rtl.nvim", { clear = true })

  if c.toggle_key then
    vim.keymap.set({ "n", "i" }, c.toggle_key, M.toggle,
      { desc = "Toggle RTL layout for this buffer" })
  end

  if c.auto_detect then
    -- Decide once, when the buffer's contents first exist.
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      group = group,
      callback = function(ev)
        local name = vim.fn.fnamemodify(ev.file or "", ":t")
        local tagged = c.prose_filetypes[vim.bo[ev.buf].filetype] == true
          and name:find(c.filename_pattern) ~= nil
        decided[ev.buf] = M.detect(ev.buf) or tagged
      end,
    })
  end

  -- Re-apply the buffer's decision every time it is displayed. Without this,
  -- opening an LTR file in a window that was showing Hebrew leaves the whole
  -- editor mirrored -- 'rightleft' belongs to the window, not the buffer.
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(ev) M.set(decided[ev.buf] == true) end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(ev) decided[ev.buf] = nil end,
  })
end

return M
