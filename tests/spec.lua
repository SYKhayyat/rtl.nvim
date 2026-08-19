-- Behavioural tests. No test framework on purpose -- the whole thing runs as
--
--   nvim --headless -u NONE --cmd "set runtimepath+=." -l tests/spec.lua
--
-- and exits non-zero on the first failure.

local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:append(repo)

local fixtures = repo .. "/tests/fixtures"
local HEB = fixtures .. "/hebrew.txt"
local ENG = fixtures .. "/english.lua"

-- -u NONE skips plugin/ entirely, so source it by hand to get the commands.
vim.cmd("runtime! plugin/rtl.lua")

local rtl = require("rtl")
rtl.setup()

local failures, checks = 0, 0

local function check(label, got, want)
  checks = checks + 1
  if got ~= want then
    failures = failures + 1
    print(string.format("  FAIL  %s\n          got %s, want %s",
      label, vim.inspect(got), vim.inspect(want)))
  else
    print("  ok    " .. label)
  end
end

local function open(f)
  vim.cmd("edit " .. vim.fn.fnameescape(f))
end

print("detection")
open(HEB)
check("hebrew buffer turns on rightleft", vim.wo.rightleft, true)
check("hebrew buffer sets keymap", vim.bo.keymap, "hebrew")

open(ENG)
check("latin buffer leaves rightleft off", vim.wo.rightleft, false)
check("latin buffer clears keymap", vim.bo.keymap, "")

print("\nwindow-option leakage")
-- 'rightleft' belongs to the window, so switching buffers in one window has
-- to re-decide it. This is the regression that motivated BufWinEnter.
open(HEB)
check("back to hebrew re-enables", vim.wo.rightleft, true)
open(ENG)
check("back to latin re-disables", vim.wo.rightleft, false)

print("\nexplicit override")
open(HEB)
vim.cmd("English")
check(":English wins over detection", vim.wo.rightleft, false)
open(ENG)
open(HEB)
check("override survives a round trip", vim.wo.rightleft, false)
vim.cmd("Hebrew")
check(":Hebrew turns it back on", vim.wo.rightleft, true)

print("\nheuristic")
check("pure hebrew detected", rtl.detect(vim.fn.bufnr(HEB)), true)
check("pure latin not detected", rtl.detect(vim.fn.bufnr(ENG)), false)

print("\nstatusline")
open(HEB)
check("shows the RTL marker", rtl.statusline(), "עב")
open(ENG)
check("empty when LTR", rtl.statusline(), "")

print("\nnever_rtl filetypes")
-- Generated, column-aligned buffers must not be mirrored even if their
-- contents are mostly Hebrew, or the columns stop lining up.
vim.cmd("enew")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "שלום", "עולם", "עברית" })
vim.bo.filetype = "orgagenda"
check("orgagenda stays LTR", vim.wo.rightleft, false)

print("\nintegrations degrade without their plugins")
local integrations = require("rtl.integrations")
check("telescope absent is reported", integrations.has("telescope"), false)
check("orgmode absent is reported", integrations.has("orgmode"), false)
-- setup() already ran with both integrations enabled; reaching here at all
-- means neither raised on a missing dependency.
check("setup survived missing plugins", true, true)

print(string.format("\n%d checks, %d failures", checks, failures))
if failures > 0 then
  vim.cmd("cquit 1")
end
