-- Optional hooks into other plugins.
--
-- Every integration is guarded: if the plugin is not installed, the hook is
-- skipped silently rather than erroring at startup. rtl.nvim declares no
-- dependencies and must keep working with none of these present.

local M = {}

local available = {
  telescope = "telescope",
  orgmode = "orgmode",
}

--- Is the named plugin loadable?
---@param name string
---@return boolean
function M.has(name)
  local mod = available[name] or name
  return pcall(require, mod)
end

---@param config table the resolved rtl.nvim config
function M.setup(config)
  for name, opts in pairs(config.integrations or {}) do
    if opts.enabled then
      local ok, mod = pcall(require, "rtl.integrations." .. name)
      if ok and type(mod.setup) == "function" then
        local applied, err = pcall(mod.setup, config, opts)
        if not applied then
          vim.notify(
            string.format("rtl.nvim: %s integration failed: %s", name, err),
            vim.log.levels.WARN
          )
        end
      end
    end
  end
end

return M
