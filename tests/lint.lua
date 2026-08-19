local bad = 0
local files = vim.fn.globpath("examples", "**/*.lua", false, true)
vim.list_extend(files, vim.fn.globpath("lua", "**/*.lua", false, true))
vim.list_extend(files, vim.fn.globpath("plugin", "**/*.lua", false, true))
for _, f in ipairs(files) do
  local fn, err = loadfile(f)
  if not fn then
    bad = bad + 1
    print("SYNTAX ERROR  " .. f .. "\n    " .. err)
  else
    print("ok  " .. f)
  end
end
print(string.format("\n%d files, %d syntax errors", #files, bad))

-- The example config is pinned; the lockfile is the pin. Losing it silently
-- would turn a frozen config back into a floating one.
local lock = "examples/lazy-lock.json"
if vim.fn.filereadable(lock) == 1 then
  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(lock), "\n"))
  if ok and type(decoded) == "table" then
    print(string.format("lockfile ok: %d plugins pinned", vim.tbl_count(decoded)))
  else
    bad = bad + 1
    print("LOCKFILE INVALID  " .. lock)
  end
else
  bad = bad + 1
  print("LOCKFILE MISSING  " .. lock .. "  (the example config must stay pinned)")
end

if bad > 0 then vim.cmd("cquit 1") end
