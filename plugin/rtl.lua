-- Commands are defined here so they work whether or not setup() has run.
-- Auto-detection lives in setup(); see doc/rtl.txt.

if vim.g.loaded_rtl_nvim then
  return
end
vim.g.loaded_rtl_nvim = true

local function rtl()
  return require("rtl")
end

vim.api.nvim_create_user_command("Hebrew", function()
  rtl().override(true)
end, { desc = "Turn on RTL layout for this buffer" })

vim.api.nvim_create_user_command("English", function()
  rtl().override(false)
end, { desc = "Turn off RTL layout for this buffer" })

vim.api.nvim_create_user_command("RtlToggle", function()
  rtl().toggle()
end, { desc = "Toggle RTL layout for this buffer" })
