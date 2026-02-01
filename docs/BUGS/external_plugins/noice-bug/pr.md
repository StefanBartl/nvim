# PR title

noice(lsp/signature): avoid programmatic focus in the signature path; respect non-enter/non-focusable views and reduce spurious triggers

# Summary

This change keeps Noice’s LSP signature help fully enabled while preventing the signature popup from stealing focus. In affected setups, the current code path briefly shifts focus into the signature view even when that view is configured with `enter = false` and `focusable = false`, which causes the editor to leave Insert mode and makes the cursor appear “trapped” in the popup. The patch removes the programmatic focus attempt from the signature flow and, optionally, trims noisy triggers (notably `,`) that tend to produce empty signature results and race conditions.

# Motivation

Multiple users report that opening LSP signature help intermittently (or reliably on `,`) causes a focus jump into the Noice signature popup and an Insert→Normal mode flip, despite view settings designed to avoid focus. Disabling `lsp.signature.enabled` “fixes” the symptom but removes a valuable feature. The goal is to keep signature help visible and reactive, but never pull focus away from the editing window.

# Reproduction (minimal)

1. Neovim with `noice.nvim` and a language server that declares `signatureHelpProvider.triggerCharacters`. For `lua_ls`: `{ "(", "," }`.
2. Enable Noice’s signature auto-open (defaults).
3. Type a function call and press `(`, then type a space or a comma inside the argument list.
4. Actual: the signature popup sometimes appears empty, sometimes with content, and the focus flips to the popup, leaving Insert mode.
5. Expected: the popup should appear but never steal focus; Insert mode should continue uninterrupted.

# Root cause analysis

The focus switch originates in the signature render path:

```lua
-- noice/lsp/signature.lua (current)
local message = Docs.get("signature")

-- If auto-open (config.trigger) or when the signature message window is not "focused",
-- we format and show.
if config.trigger or not message:focus() then
  result.ft = vim.bo[ctx.bufnr].filetype
  result.message = message
  M.new(result):format()
  if message:is_empty() then
    if not config.trigger then
      vim.notify("No signature help available")
    end
    return
  end
  Docs.show(message, config.stay)
end
```

Calling `message:focus()` attempts to focus the signature view. Even if the configured view sets `enter = false` and `focusable = false`, the programmatic focus attempt is sufficient for Neovim to treat the float as the current window for a moment, which triggers an Insert→Normal mode transition. This is aggravated when servers declare `,` as a trigger (e.g., `lua_ls`) and when the “char before cursor” heuristic effectively treats a space after `(` as if the last significant char were still `(`, leading to frequent, sometimes empty signature updates.

# Proposed change

1. Remove the programmatic focus attempt from `on_signature` and show/update the signature message without ever trying to focus it. In other words, replace the `message:focus()` gate with a non-focusing check and always use `Docs.show(...)` to render.
2. Optionally, make the “char before cursor” check strictly use the real cursor-preceding character (including spaces), rather than trimming the line end. This reduces unintended re-triggers after `(` followed by a space.
3. Optionally, allow trimming particularly noisy trigger characters (notably `,`) at runtime for the active client. This does not change server behavior, but prevents auto-open from firing on cases that often yield empty signature payloads.

# Implementation (minimal patch sketch)

The exact internals may differ; the essence is to stop calling `message:focus()` in the signature path and rely on the view options to control focus behavior.

```lua
-- noice/lsp/signature.lua

-- before:
-- if config.trigger or not message:focus() then
--   ...
--   Docs.show(message, config.stay)
-- end

-- after (illustrative):
local message = Docs.get("signature")

-- Do not try to focus the message programmatically. Just prepare and show/update it.
result.ft = vim.bo[ctx.bufnr].filetype
result.message = message
M.new(result):format()

if message:is_empty() then
  if not config.trigger then
    vim.notify("No signature help available")
  end
  return
end

Docs.show(message, config.stay)  -- view.enter=false / focusable=false will be respected
```

Optional, safer character probe (used by auto-open debounce callback) to avoid treating a trailing space as a re-trigger on `(`:

```lua
-- instead of trimming, read the exact char immediately before the cursor
local function get_char(buf)
  local curwin = vim.api.nvim_get_current_win()
  local win = (vim.api.nvim_win_get_buf(curwin) == buf) and curwin or vim.fn.bufwinid(buf)
  if win == -1 then win = 0 end
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  row = row - 1
  if col <= 0 then return "" end
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1] or ""
  return line:sub(col, col)
end
```

Optional, runtime sanitization of particularly noisy signature triggers:

```lua
-- during LspAttach: keep '(' but drop ',' for auto-open; server still supports ',' manually
local shp = client.server_capabilities and client.server_capabilities.signatureHelpProvider
if shp and shp.triggerCharacters then
  local keep = {}
  for _, ch in ipairs(shp.triggerCharacters) do
    if ch ~= "," then table.insert(keep, ch) end
  end
  shp.triggerCharacters = keep
end
```

All of the above preserve the existing feature set: signature help still appears automatically and updates while typing. The only behavior change is that Noice never programmatically focuses the signature view anymore.

# Backward compatibility

• Existing configurations continue to work.
• Users who relied on focusing the signature view programmatically can still click or map a key to jump to the popup, but auto-open no longer changes focus.
• The optional trigger sanitization and character probe are additive and can be guarded behind a config flag if preferred.

# Alternatives considered

• Keep `message:focus()` but introduce an additional configuration flag to bypass it for auto-open. This adds a new option surface while solving the same problem; the minimal change above may be sufficient for most users.
• Force a focus bounce-back (`startinsert`) after the popup opens. This treats the symptom and introduces timing concerns; avoiding the focus attempt is simpler and more robust.

# Tests

• With `lua_ls` (`triggerCharacters = { "(", "," }`), type `foo(` then space: signature should open without stealing focus.
• Type a comma inside the arglist: signature updates or stays quiet depending on payload, with no focus change.
• Try multiple consecutive signature updates; the popup should update in place without any Insert→Normal transitions.

# Performance and stability

• The change removes a focus attempt and does not add extra redraws or requests.
• Debounced auto-open remains as before.
• In manual testing the change reduces flicker and eliminates the focus jump.

# Documentation

• A short note could be added under the LSP signature section: “Signature views never steal focus; to interact, click or use a mapping that explicitly focuses the popup.”

# Acknowledgements

Thanks for Noice and for the LSP integration work. This PR aims to align the signature UX with user expectations around focus while keeping the feature fully functional. If a different internal check is preferred over removing `message:focus()`, happy to adapt the patch to the existing message/docs API.
