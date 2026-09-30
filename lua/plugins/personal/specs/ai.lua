---@module 'plugins.personal.specs.ai'
--- AI -- personal plugin specs (Provider-agnostic ask/stream layer and buffer-context helpers.)
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  -- Provider-agnostic ask/stream layer (claude/ollama/openai/gemini/loomai),
  -- built on lib.nvim.net.curl. `keys`/`cmd` load it lazily. `ai_prefix` is
  -- shared with opts so the keys table and the plugin's own mappings cannot
  -- drift apart.
  (function()
    -- ai.nvim's default keymap prefix "<leader>a" collides with the Avante
    -- mappings ("<leader>aa/ae/ar/af/as") of config/ai/anthropic, so the prefix
    -- is moved one level down to "<leader>ai" to let both coexist.
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
      -- Inline completion's keymaps (trigger/accept/dismiss, insert mode) are
      -- installed by ai.nvim's setup(), and neither `cmd` nor `keys` fires from
      -- plain typing. `InsertEnter` loads the plugin the first time any buffer
      -- enters insert mode, so those keymaps exist from then on without
      -- resorting to `lazy = false`.
      event = "InsertEnter",
      -- ui.nvim: the panel, the badge and the actions render exclusively
      -- through ui.kit, with no fallback. Completion itself does not need it
      -- (the ghost text uses raw extmarks), so this dependency only matters
      -- for the other features.
      dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
      opts = {
        -- Active provider id, or "auto" to pick the first available one in
        -- `provider_order`.
        -- provider = "auto",
        -- Order that "auto" walks. "loomai" is last because it needs a local
        -- server you run yourself. Replaces the list, so give it in full.
        -- provider_order = { "claude", "ollama", "openai", "gemini", "loomai" },
        -- Default model per provider id, e.g. { claude = "claude-opus-4-5" };
        -- empty = each provider's own built-in default.
        -- model = {},
        -- Request timeout in ms.
        -- timeout_ms = 60000,

        -- ui = {
        --   -- Render the streaming answer panel and the explain badge.
        --   enable = true,
        --   -- Progress indicator: "auto" | "notify" | "statusline" | "fidget" | "float".
        --   progress_style = "auto",
        --   -- ui.kit theme/preset of the answer panel.
        --   panel_theme = "rounded",
        --   -- Auto-dismiss delay of the explain badge, in ms.
        --   badge_timeout_ms = 6000,
        -- },

        keymaps = {
          -- Install the action keymaps (<prefix>a / s / e).
          -- enable = true,
          -- Moved one level down so the actions do not collide with the Avante
          -- mappings (see `ai_prefix` above).
          -- Default: "<leader>a".
          prefix = ai_prefix,
        },

        -- which_key = {
        --   -- Label the configured keymaps in which-key when it is installed.
        --   enable = true,
        -- },

        -- usercmds = {
        --   -- Register the :Ai command.
        --   enable = true,
        -- },

        -- Default context assembly for the quick-action keymaps (:Ai ask/stream
        -- build no context of their own).
        -- context = {
        --   -- The whole current buffer.
        --   buffer = false,
        --   -- The current visual selection, if any.
        --   selection = true,
        --   -- vim.diagnostic.get() of the current buffer.
        --   diagnostics = false,
        --   -- A harvest sweep of the cwd (expensive).
        --   cwd = false,
        --   -- The flattened JSON/YAML/XML block under the cursor (needs data.nvim).
        --   structured_data = false,
        --   -- Both sides of every unresolved merge conflict (needs gitsuite.nvim).
        --   conflict = false,
        -- },

        -- Ghost-text completion at the cursor (see docs/configuration.md in the
        -- ai.nvim repo).
        completion = {
          -- Turn inline completion on.
          -- Default: true (equals the default, set explicitly to keep it on).
          enable = true,
          -- "manual": only the trigger keymap (<C-\><C-a> by default) fires a
          -- suggestion. Kept off "auto" on purpose: auto fires an API call
          -- (possibly a paid one) on every idle pause while typing.
          -- Default: "manual" (equals the default, set explicitly so the
          -- choice stays visible).
          trigger = "manual",
          -- Idle debounce before an "auto" suggestion fires, in ms; unused in
          -- "manual" mode.
          -- idle_ms = 500,
          -- Lines of buffer context sent before/after the cursor.
          -- max_context_lines = 60,
          -- string; overrides `provider` for completion requests only (false = unset).
          -- provider = false,
          -- string; overrides the provider's default model for completion requests only (false = unset).
          -- model = false,
          -- keymap = {
          --   -- Insert mode: request a suggestion (manual mode only).
          --   trigger = "<C-\\><C-a>",
          --   -- Insert mode: insert the shown suggestion.
          --   accept = "<Tab>",
          --   -- Insert mode: clear the shown suggestion.
          --   dismiss = "<C-]>",
          -- },
        },

        -- vim.log.levels threshold of ai.nvim's own notifications.
        -- log_level = vim.log.levels.WARN,
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
    -- globally (Format file, see BINDINGS-RUNTIME-CHECKLIST.md); <leader>o* is
    -- free across the ecosystem. The keys listed here only lazy-load the
    -- plugin; the mappings themselves are installed by its setup() (see the
    -- keymap options in `opts`).
    keys = {
      "<leader>cnl",
      "<leader>cnm",
      "<leader>cnf",
      "<S-m>",
      "<C-p>",
      "<leader>of",
      "<leader>ob",
    },
    opts = {
      -- Lhs of the copy keymaps; `false` disables all of them.
      -- keymaps = {
      --   -- Copy path:line.
      --   location_copy = "<leader>cnl",
      --   -- Copy the module path.
      --   module_copy = "<leader>cnm",
      --   -- Copy the relative filepath.
      --   filepath_copy = "<leader>cnf",
      -- },
      -- Register the :Insert / :Copy / ... commands.
      -- commands = true,

      -- timestamp = {
      --   -- Emit every :Insert/:Copy timestamp in UTC without passing --utc
      --   -- (an explicit --utc still works).
      --   utc = false,
      -- },

      -- snippets = {
      --   -- VSCode-format snippet files loaded by :Insert snippet {name}.
      --   paths = {}, -- string[], e.g. { vim.fn.stdpath("config") .. "/snippets/lua.json" }
      -- },

      -- `false` switches the whole feature off.
      -- format = {
      --   -- Register the :Format command.
      --   enable = true,
      --   -- Name of that command.
      --   command = "Format",
      -- },

      -- `false` switches the whole feature off.
      -- mark = {
      --   -- Register the :Mark command.
      --   enable = true,
      --   -- Name of that command.
      --   command = "Mark",
      --   -- `false` disables the mark keymaps.
      --   keymaps = {
      --     -- Toggle a mark on the current line (or N lines with a count).
      --     toggle = "<S-m>",
      --     -- Yank all marked lines.
      --     yank = "<C-p>",
      --     -- clear = nil, -- string; remove every mark in the buffer (unset by default)
      --   },
      --   -- Appearance of the `default` category.
      --   sign = {
      --     text = "●",
      --     hl = "ErrorMsg",
      --   },
      --   -- Extra named appearances, used by `:Mark toggle {name}` / `:Mark yank {name}`.
      --   categories = {}, -- { name, text?, hl? }[], e.g. { { name = "todo", text = "●", hl = "WarningMsg" } }
      -- },

      -- `false` switches the whole feature off.
      -- reveal = {
      --   -- Register :RevealInFm / :OpenInBrowser.
      --   enable = true,
      --   -- `false` disables the reveal keymaps.
      --   keymaps = {
      --     -- Reveal the current buffer in the system file manager.
      --     fm = "<leader>of",
      --     -- Open the current buffer in the OS-registered application / browser.
      --     browser = "<leader>ob",
      --   },
      -- },

      -- Label the configured keymaps in which-key when it is installed.
      -- which_key = true,
    },
  },
}
