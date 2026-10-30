# config.noice

noice.nvim's own `opts` table (cmdline/lsp/messages/popupmenu/presets/routes/
views/notify), assembled here rather than inline in the plugin spec.

## Routes

`M.routes` in `init.lua` follows three rules, checked by
`TESTS/noice/routes_spec.lua`:

- **First match wins.** noice's router stops at the first matching route, so a
  skip rule sits before the generic route of the same event (the `notify` ->
  mini route and the `msg_show` catch-all come last).
- **Every route names `filter.event`**, skip and view routes alike. noice routes
  the command line itself through the same router (event `cmdline`), so a
  filter without an event also matches the line being typed and hides it (skip)
  or moves it into another view.
- **`cmdline_reason`**: a route whose `filter.event` includes `"cmdline"` on
  purpose carries a top-level `cmdline_reason` string that says why. noice's
  `Router.add` only reads `filter`/`opts`/`view`, so the key is inert; it only
  documents the intent, and the spec rejects a cmdline route without it.

```lua
{
  filter = { event = "cmdline", find = "^:lua " },
  view = "cmdline_popup",
  cmdline_reason = "show :lua lines in the popup while typing",
},
```
