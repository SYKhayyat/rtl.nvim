-- org + org-modern.
--
-- nvim-orgmode is a genuine reimplementation, not a syntax file: agenda,
-- capture, TODO state cycling, refile, tags. The TODO keywords, tags and
-- capture templates below are transcribed from the Emacs config so the org
-- files stay interchangeable between the two editors.
--
-- Note on RTL: rtl.nvim's orgmode integration mirrors Hebrew org buffers but
-- never the agenda, which aligns by column. See :help rtl-orgmode for what a
-- mirrored heading actually looks like -- the stars move to the right edge,
-- and #+KEYWORD lines render reversed because they are Latin runs.

return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    opts = {
      org_agenda_files = { "~/org/**/*" },
      org_default_notes_file = "~/org/notes.org",

      org_todo_keywords = {
        "TODO", "IN-PROGRESS", "WAITING", "|", "DONE", "CANCELLED",
      },
      org_todo_keyword_faces = {
        ["IN-PROGRESS"] = ":foreground orange :weight bold",
        WAITING = ":foreground yellow",
        CANCELLED = ":foreground gray :slant italic",
      },
      org_tags_column = -80,

      org_capture_templates = {
        t = {
          description = "Todo",
          template = "* TODO %?\n  %u",
          target = "~/org/tasks.org",
        },
        n = {
          description = "Note",
          template = "* %?\n  %u",
          target = "~/org/notes.org",
        },
        j = {
          description = "Journal",
          template = "\n*** %<%Y-%m-%d> %<%A>\n**** %U\n\n%?",
          target = "~/org/journal.org",
          datetree = true,
        },
      },

      mappings = {
        global = {
          org_agenda = "<leader>oa",
          org_capture = "<leader>oc",
        },
      },
    },
    keys = {
      { "<leader>oa", desc = "Org agenda" },
      { "<leader>oc", desc = "Org capture" },
    },
  },

  -- org-modern.
  {
    "nvim-orgmode/org-bullets.nvim",
    ft = "org",
    opts = {},
  },
}
