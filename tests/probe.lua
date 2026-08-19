-- Report which RTL-related options and runtime keymaps this Neovim has.
--
--   nvim --headless -u NONE -l tests/probe.lua
--
-- Useful because the answer has changed across versions and the internet is
-- confidently wrong about it. Options that were removed raise on access, so
-- the pcall distinguishes "present and off" from "gone".

local out = {}

local function opt(name)
  local ok, v = pcall(vim.api.nvim_get_option_value, name, {})
  out[#out + 1] = string.format("  %-14s %s", name,
    ok and ("present   = " .. tostring(v)) or "ABSENT")
end

out[#out + 1] = "neovim " .. tostring(vim.version())
out[#out + 1] = ""
out[#out + 1] = "options:"
for _, n in ipairs({
  "rightleft", "rightleftcmd", "revins", "keymap", "delcombine",
  "arabic", "arabicshape", "termbidi", "hkmap", "hkmapp",
  "encoding", "ambiwidth",
}) do
  opt(n)
end

out[#out + 1] = ""
out[#out + 1] = "runtime keymaps:"
for _, pat in ipairs({ "keymap/*hebrew*", "keymap/*arabic*", "keymap/*persian*" }) do
  for _, f in ipairs(vim.api.nvim_get_runtime_file(pat, true)) do
    out[#out + 1] = "  " .. f
  end
end

out[#out + 1] = ""
vim.bo.keymap = "hebrew"
local n = select(2, vim.fn.execute("lmap"):gsub("\n", "\n"))
out[#out + 1] = string.format("keymap=hebrew installs %d langmap lines", n)

io.write(table.concat(out, "\n"), "\n")
