# LSP Completion Debug Guide

## Table of content

- [LSP Completion Debug Guide](#lsp-completion-debug-guide)
  - [🔍 Schritt 1: Sofort-Checks](#schritt-1-sofort-checks)
    - [Check 1: Ist nvim-cmp installiert?](#check-1-ist-nvim-cmp-installiert)
    - [Check 2: Sind Capabilities geladen?](#check-2-sind-capabilities-geladen)
    - [Check 3: Ist lua_ls attached?](#check-3-ist-lua_ls-attached)
    - [Check 4: Completion triggern](#check-4-completion-triggern)
  - [🚨 Häufigste Probleme & Fixes](#hufigste-probleme-fixes)
    - [Problem 1: nvim-cmp fehlt komplett](#problem-1-nvim-cmp-fehlt-komplett)
    - [Problem 2: Capabilities werden nicht applied](#problem-2-capabilities-werden-nicht-applied)
    - [Problem 3: LSP startet zu spät](#problem-3-lsp-startet-zu-spt)
    - [Problem 4: Server-spezifische Probleme](#problem-4-server-spezifische-probleme)
      - [lua_ls:](#lua_ls)
      - [ts_ls/eslint:](#ts_lseslint)
  - [🧪 Test-Snippet](#test-snippet)
  - [🔧 Nuclear Option: Kompletter Reset](#nuclear-option-kompletter-reset)
- [1. Backup](#1-backup)
- [2. Minimal Config testen](#2-minimal-config-testen)
- [3. Neovim starten](#3-neovim-starten)
- [4. Test in test.lua:](#4-test-in-testlua)
- [vim.api.nvim_  <-- Ctrl+Space drücken](#vimapinvim_-ctrlspace-drcken)
- [Sollte Completion zeigen!](#sollte-completion-zeigen)
  - [📋 Checklist für komplette Fix](#checklist-fr-komplette-fix)
  - [💡 Debug Commands](#debug-commands)
  - [🎯 Quick Win: Ein-Zeilen-Test](#quick-win-ein-zeilen-test)
  - [📞 Wenn GAR NICHTS hilft](#wenn-gar-nichts-hilft)

---

## 🔍 Schritt 1: Sofort-Checks

### Check 1: Ist nvim-cmp installiert?

```vim
:lua print(vim.inspect(package.loaded["cmp"]))
```

**Erwartet:** Eine Table (nicht `nil`)
**Falls nil:** nvim-cmp ist NICHT installiert! → Fix in `lua/plugins/lsp.lua`

### Check 2: Sind Capabilities geladen?

```vim
:lua local caps = require("lsp.core.capabilities").get(); print(vim.inspect(caps.textDocument.completion))
```

**Erwartet:** Eine Table mit `completionItem`, `contextSupport` etc.
**Falls nil/error:** Capabilities fehlen → Fix `lsp/core/capabilities.lua`

### Check 3: Ist lua_ls attached?

```vim
:LspInfo
```

**Erwartet:** lua_ls läuft und ist "Attached"
**Falls "Not running":** Server startet nicht → Check `:checkhealth lsp`

### Check 4: Completion triggern

Im Lua-File:

```lua
vim.uv.  -- <-- Cursor hier, dann Ctrl+Space
```

**Erwartet:** Completion-Menu erscheint
**Falls nichts:** Completion ist blockiert

---

## 🚨 Häufigste Probleme & Fixes

### Problem 1: nvim-cmp fehlt komplett

**Symptom:** `:lua print(package.loaded["cmp"])` → `nil`

**Fix:** Füge zu `lua/plugins/lsp.lua` hinzu:

```lua
{
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip", -- Optional: Snippets
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp = require("cmp")
    cmp.setup({
      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "lazydev", group_index = 0 }, -- Für Lua-spezifische completion
      }, {
        { name = "buffer" },
        { name = "path" },
      }),
    })
  end,
},
```

### Problem 2: Capabilities werden nicht applied

**Symptom:** LSP läuft, aber keine Completion-Vorschläge

**Fix 1:** In `init.lua` MUSS `apply_globally()` VOR `lsp.setup()` aufgerufen werden:

```lua
-- BEFORE require("lsp").setup()
local ok_caps, caps = pcall(require, "lsp.core.capabilities")
if ok_caps and type(caps.apply_globally) == "function" then
  caps.apply_globally()
end
```

**Fix 2:** Verify in `:LspInfo`:

```vim
:lua vim.print(vim.lsp.get_clients()[1].server_capabilities.completionProvider)
```

**Erwartet:** Eine Table, NICHT `nil`

### Problem 3: LSP startet zu spät

**Symptom:** Completion funktioniert erst nach Reload (`:e`)

**Fix:** LSP MUSS VOR dem ersten Buffer laden:

```lua
-- ❌ FALSCH (zu spät):
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    require("lsp").setup()
  end
})

-- ✅ RICHTIG (sofort):
vim.defer_fn(function()
  require("lsp.core.capabilities").apply_globally()
  require("lsp").setup()
end, 80) -- Nach Keymaps, aber VOR Buffer-Load
```

### Problem 4: Server-spezifische Probleme

#### lua_ls:

```vim
:lua require("lsp.servers.lua_ls.debug").print_debug_info()
```

**Check:** Sind `${3rd}/luv/library` und Neovim-Runtime in der Library?

#### ts_ls/eslint:

```vim
:LspInfo
```

**Check:** Root directory korrekt? (muss `package.json` oder `tsconfig.json` enthalten)

---

## 🧪 Test-Snippet

Kopiere diesen Code in ein neues Lua-File:

```lua
-- test.lua
local M = {}

function M.test_completion()
  -- HIER sollte Completion funktionieren:
  vim.api.nvim_  -- <-- Ctrl+Space hier
  vim.fn.       -- <-- Ctrl+Space hier
  vim.uv.       -- <-- Ctrl+Space hier

  local tbl = { foo = 1, bar = 2 }
  tbl.  -- <-- Ctrl+Space hier (sollte foo/bar zeigen)
end

return M
```

**Erwartetes Verhalten:**

- Bei `vim.api.nvim_` → Liste mit `nvim_buf_get_lines` etc.
- Bei `vim.fn.` → Liste mit `expand`, `getcwd` etc.
- Bei `vim.uv.` → Liste mit `fs_stat`, `cwd` etc.
- Bei `tbl.` → `foo`, `bar`

---

## 🔧 Nuclear Option: Kompletter Reset

Falls nichts hilft:

```bash
# 1. Backup
mv ~/.config/nvim ~/.config/nvim.backup
mv ~/.local/share/nvim ~/.local/share/nvim.backup

# 2. Minimal Config testen
mkdir -p ~/.config/nvim/lua
cat > ~/.config/nvim/init.lua << 'EOF'
-- Minimal LSP + Completion Test
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- LSP Server
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
          },
        },
      })
    end,
  },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
        },
      })
    end,
  },
})
EOF

# 3. Neovim starten
nvim test.lua

# 4. Test in test.lua:
# vim.api.nvim_  <-- Ctrl+Space drücken
# Sollte Completion zeigen!
```

**Wenn das funktioniert:** Problem liegt in deiner bestehenden Config
**Wenn das NICHT funktioniert:** Neovim oder lua_ls Installation kaputt

---

## 📋 Checklist für komplette Fix

- [ ] nvim-cmp ist in `lua/plugins/lsp.lua` installiert
- [ ] `capabilities.apply_globally()` wird in `init.lua` aufgerufen
- [ ] LSP Setup läuft SOFORT (nicht erst nach BufReadPost)
- [ ] `:LspInfo` zeigt "Attached" für lua_ls
- [ ] `:lua print(vim.inspect(vim.lsp.get_clients()[1].server_capabilities.completionProvider))` zeigt Table
- [ ] `vim.api.nvim_` + Ctrl+Space zeigt Completion
- [ ] `:checkhealth lsp` zeigt keine Errors

---

## 💡 Debug Commands

```vim
" Show loaded LSP clients
:lua vim.print(vim.lsp.get_clients())

" Show capabilities of first client
:lua vim.print(vim.lsp.get_clients()[1].server_capabilities)

" Test manual completion trigger
:lua vim.lsp.buf.completion()

" Show nvim-cmp status
:lua vim.print(require("cmp").get_config())

" Check if cmp_nvim_lsp is loaded
:lua print(package.loaded["cmp_nvim_lsp"])
```

---

## 🎯 Quick Win: Ein-Zeilen-Test

Öffne Lua-File und tippe:

```vim
:lua vim.lsp.buf.completion()
```

**Sollte:** Completion-Menu öffnen
**Falls nichts:** LSP oder Completion komplett broken

---

## 📞 Wenn GAR NICHTS hilft

1. **Check Neovim Version:**

   ```bash
   nvim --version  # Muss >= 0.10.0 sein
   ```

2. **Check lua_ls Installation:**

   ```bash
   which lua-language-server
   lua-language-server --version
   ```

3. **Enable LSP Logging:**

   ```vim
   :lua vim.lsp.set_log_level("debug")
   :lua print(vim.lsp.get_log_path())
   " Dann tail -f <path> in anderem Terminal
   ```

4. **Create Minimal Repro:**
   - Nutze den "Nuclear Option" Minimal Config von oben
   - Wenn das funktioniert → schrittweise deine Config zurück mergen
   - Wenn das NICHT funktioniert → Neovim neu installieren
