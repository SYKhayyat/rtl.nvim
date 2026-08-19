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
if bad > 0 then vim.cmd("cquit 1") end
