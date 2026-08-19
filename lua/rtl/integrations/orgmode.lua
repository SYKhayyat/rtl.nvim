-- nvim-orgmode integration.
--
-- Org files are the case where RTL layout works best and the case where it is
-- most surprising, so it is worth being explicit about what happens.
--
-- Under 'rightleft' the structural markers move to the right edge: a heading
-- reads `כותרת **` with the stars on the right, and `#+TITLE:` keywords are
-- reversed on screen because they are Latin runs on an otherwise Hebrew line.
-- That is the same missing-bidi limitation described in doc/rtl.txt, and it is
-- why the drawer and keyword lines look wrong while the prose looks right.
--
-- The agenda is left alone. It is a generated, column-aligned buffer; mirror
-- it and the date column, the tags and the file names stop lining up.

local M = {}

---@param config table resolved rtl.nvim config
---@param opts table the integrations.orgmode sub-table
function M.setup(config, opts)
  local integrations = require("rtl.integrations")
  if not integrations.has("orgmode") then
    return
  end

  local rtl = require("rtl")
  local group = vim.api.nvim_create_augroup("rtl.nvim.orgmode", { clear = true })

  -- Org buffers are often opened by orgmode itself rather than by :edit, so
  -- BufReadPost may have run before the filetype was known. Re-decide on
  -- FileType, which orgmode always triggers.
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "org",
    callback = function(ev)
      if rtl.detect(ev.buf) then
        rtl.override(true, ev.buf)
      end
    end,
  })

  if not opts.agenda_rtl then
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = { "orgagenda", "orgmessages" },
      callback = function(ev)
        rtl.override(false, ev.buf)
      end,
    })
  end
end

return M
