-- Telescope integration.
--
-- The useful half is 'keymap' on the prompt buffer: it lets you type Hebrew
-- into a picker without switching your OS layout, which is otherwise the most
-- annoying part of searching a Hebrew notes directory.
--
-- The prompt is a one-line buffer, so mirroring it is safe -- unlike the
-- results and preview windows, which are column-aligned and are deliberately
-- left alone. Telescope's own filetypes are in the default `never_rtl` set for
-- exactly that reason.

local M = {}

---@param config table resolved rtl.nvim config
---@param opts table the integrations.telescope sub-table
function M.setup(config, opts)
  local integrations = require("rtl.integrations")
  if not integrations.has("telescope") then
    return
  end

  local group = vim.api.nvim_create_augroup("rtl.nvim.telescope", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "TelescopePrompt",
    callback = function(ev)
      -- Only follow the buffer we were called from; a picker opened over an
      -- English buffer should stay English.
      if not require("rtl").is_rtl(vim.fn.bufnr("#")) then
        return
      end
      if opts.keymap and config.keymap then
        vim.bo[ev.buf].keymap = config.keymap
      end
      if opts.rightleft then
        vim.wo.rightleft = true
      end
    end,
  })

  -- <C-l> flips the prompt mid-search, for when you want to find an English
  -- filename from inside a Hebrew buffer.
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "TelescopePrompt",
    callback = function(ev)
      vim.keymap.set("i", "<C-l>", function()
        local on = vim.bo[ev.buf].keymap == ""
        vim.bo[ev.buf].keymap = on and (config.keymap or "hebrew") or ""
        vim.wo.rightleft = on
      end, { buffer = ev.buf, desc = "Toggle Hebrew input in this picker" })
    end,
  })
end

return M
