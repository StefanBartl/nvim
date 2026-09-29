# Beispiele für weirde docs

## `images.nvim`

### `$REPOS_DIR\images.nvim\lua\images\config\DEFAULTS.lua`

```lua
pdf = {
    enabled = true,
    -- Which page. There is no paging in a preview window -- the first page is    === REVIEW -> Das ist komisch geschreiben
    -- what says "this is that document", which is the whole question a
    -- preview answers.
    page = 1,
    -- Rasterization resolution. 120 puts an A4 page at ~1000x1400 px, which
    -- is more than a preview window (a few hundred pixels across) can show,
    -- and about a third of the bytes of the 216 hover.nvim rasterizes a
    -- full-screen float at. Raise it if you read pages in a large preview.
    dpi = 120,
  },

  -- Right-click context menu (nvzone/menu, soft dependency; entries from    === RE
  -- images.integrations.menu). Automatically inactive without nvzone/menu
  -- installed -- this only controls whether M.items()/M.submenu() return any
  -- entries at all.
  menu = {
    enable = true,
  },
```

---

