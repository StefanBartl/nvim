---@module 'plugins.personal.specs.ai'
--- AI -- personal plugin specs (Provider-agnostic ask/stream layer and buffer-context helpers.)
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  -- Provider-agnostic ask/stream layer (claude/ollama/openai/gemini/loomai),
  -- built on lib.nvim.net.curl. `keys`/`cmd` loads it lazily, same reasoning
  -- as dap.nvim above. `ai_prefix` is shared with opts so the two cannot
  -- drift apart, mirroring dap_prefix/dap_keys.
  (function()
    -- ai.nvim's own default keymap prefix is "<leader>a", which collides
    -- with config/ai/anthropic's Avante mappings ("<leader>aa/ae/ar/af/as",
    -- an unrelated, pre-existing AI chat plugin). Moved one level to
    -- "<leader>ai" so both coexist.
    local ai_prefix = "<leader>ai"

    ---@type table[]
    local ai_keys = {}
    for _, m in ipairs({
      { "a", "Ask (prompt for text)" },
      { "s", "Quick action: stream context + a typed task" },
      { "e", "Explain (badge, no panel)" },
    }) do
      ai_keys[#ai_keys + 1] = { ai_prefix .. m[1], desc = "[AI] " .. m[2] }
    end
    -- Every action also binds in visual mode (selection instead of buffer/cwd).
    for _, m in ipairs({
      { "a", "Ask about the selection" },
      { "s", "Quick action: stream selection + a typed task" },
      { "e", "Explain selection (badge, no panel)" },
    }) do
      ai_keys[#ai_keys + 1] = { ai_prefix .. m[1], mode = "v", desc = "[AI] " .. m[2] }
    end

    return {
      "StefanBartl/ai.nvim",
      cmd = "Ai",
      keys = ai_keys,
      -- Inline completion's own keymaps (trigger/accept/dismiss, all insert
      -- mode) are installed by ai.nvim's own setup() -- `cmd`/`keys` above
      -- only cover the :Ai command and the <leader>ai* actions, neither of
      -- which fires from plain typing. Without this, completion's keymaps
      -- would not exist until :Ai (or a <leader>ai* key) had been used at
      -- least once in the session. `InsertEnter` loads it the first time
      -- any buffer goes into insert mode -- effectively "on", same lazy-load
      -- intent as everything else in this file, not `lazy = false`.
      event = "InsertEnter",
      -- ui.nvim: ui/panel.lua, ui/badge.lua and bindings/actions.lua all
      -- render exclusively through ui.kit, no fallback. Already loaded
      -- lazy=false above, listed here for documentation. Completion itself
      -- does NOT need ui.nvim (lua/ai/ui/ghost.lua renders through raw
      -- extmarks), so this dependency stays scoped to the other features.
      dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
      opts = {
        keymaps = { prefix = ai_prefix },
        -- Ghost-text completion at the cursor (lua/ai/completion/, see
        -- docs/configuration.md in the ai.nvim repo). "manual": only the
        -- trigger keymap (<C-\><C-a> by default) fires a suggestion --
        -- deliberately not "auto", since that fires an API call on every
        -- idle pause while typing, not just on deliberate action. Replaces
        -- the third-party copilot.lua spec (plugins/ai/copilot.lua, removed
        -- 2026-09-14 -- it was fully commented out/inert anyway) for the
        -- same inline-suggestion use case.
        completion = {
          enable = true,
          trigger = "manual",
        },
      },
    }
  end)(),

  {
    "StefanBartl/buffer-ctx.nvim",
    cmd = {
      "Insert",
      "Copy",
      "Format",
      "Mark",
      "MarkLineToggle",
      "MarkLinesYank",
      "CopyFilepathAbsolute",
      "CopyFilepathRelative",
      "CopyFilepathRepos",
      "CopyFilepathEnv",
      "RevealInFm",
      "OpenInBrowser",
    },
    -- <leader>of/<leader>ob (reveal-in-filemanager / open-in-browser): picked
    -- over the more obvious <leader>fm because that key is already taken
    -- globally (Format file, see BINDINGS-RUNTIME-CHECKLIST.md) — <leader>o*
    -- was entirely free across the ecosystem at the time this was added.
    keys = {
      "<leader>cnl",
      "<leader>cnm",
      "<leader>cnf",
      "<S-m>",
      "<C-p>",
      "<leader>of",
      "<leader>ob",
    },
    opts = {},
  },
}
