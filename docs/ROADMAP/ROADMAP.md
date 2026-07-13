# Roadmap for `main-workstation` branch

- learn-cli.nvim vielleicht doch ?
- neotree-fs-refactora
- `mdview.nvim`: Das war eigentlich mein Websocket Lern Projekssssss      ....
- `lua/config/menu` nach `lua/wkdnvchad`?
- beim öfgfnen eienr datzei über harpoon aktualisere filetree.nvim den filetree noch nicht cwd_sync

**Wichtig:**
- nach ein paar sekundn anch dem start blkeiubt nvim für ca 3-5 sekunden freezen, egal awas ich gerade mache. Was kö nnte das sein? Könnte es sein, dass das verzögerte initieren in der `nvim/init.lua` damit zu tun hat und etwas zeitverzögert ausggelöst wird, dass nicht asynchron ist?

test: [test](./CDX.md)
lernen: https://www.browserstack.com/

```lua
local notify = require("lib.nvim.notify").create("[config.telescope.history]")

local M = {}


---@type HistoryState
local state = {
  backend = "none",
  path = "",
  limit = 3000,
  extensions = {},
}

---Ensure a directory exists
---@param dir_path string
---@return boolean
local function ensure_dir(dir_path)
  if vim.fn.isdirectory(dir_path) == 0 then
    local ok, err = pcall(vim.fn.mkdir, dir_path, "p")
    if not ok then
      notify.warn(string.format("Failed to create directory: %s (%s)", dir_path, err))
      return false
    end
  end
  return true
end

---Setup SQLite backend if possible
---@return boolean success
local function setup_sqlite()
  local ok_sqlite = pcall(require, "sqlite")
  local ok_smart = pcall(require, "telescope-smart-history")
  if not (ok_sqlite and ok_smart) then
    return false
  end

  local dir = vim.fn.stdpath("data") .. "/databases"
  if not ensure_dir(dir) then
    return false
  end

  state.backend = "sqlite"
  state.path = dir .. "/telescope_history.sqlite3"
  state.extensions = { "smart_history" }
  return true
end

---Setup file-based fallback backend
---@return boolean success
local function setup_file()
  local dir = vim.fn.stdpath("data") .. "/picker-history"
  if not ensure_dir(dir) then
    return false
  end

  state.backend = "file"
  state.path = dir .. "/_global.txt"
  state.extensions = {}
  return true
end

---Setup history backend (SQLite preferred)
function M.setup()
  if not setup_sqlite() then
    setup_file()
  end

  -- notify.info(string.format("Telescope history: Using %s backend at %s", state.backend, state.path))

  return {
    path = state.path,
    limit = state.limit,
  }
end

```

## Table of content

  - [ZIEL](#ziel)
  - [High](#high)
  - [LSP](#lsp)
  - [General](#general)
  - [Bugs](#bugs)

---

## ZIEL

1. ROADMAP.md durchgehen
2. Alle plugin fähigen Module augliedern
3. Funktionen/Module/ganze Custom Plugins, die man mit ffi über vc performanter machen könnte?
  1.  Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wir Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wirdd
4. `BINDINGS.lua`: In der Descrtiptionder Keymaps und Usrcmds: Das plugin selbst nicht nennen,, wie zb.: "[iletree]:" in fileteree.nvim keymap descreiption
5. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
6. Checklisten anwenden
  1. ToDo's duchgehen
7. Branch küren (so wenig commits wit möglch, damit die .git folder nicht groß ist)

---

## High

8. `leader wq`: Alle issues lösen
9. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
10. `nvim/init.lua` durchgehen
11. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - [ ] `/nvim/lua/` – alle Module durchgehen und checken, ob sie irgendwo hineinpassen
12. `C-a` markiert manchmal niucht mehr

---

## LSP

13. lightbulb: Manchmal stört sie und ich möchhte das schnell ausblenden können, am besten mit Keymap togglebnar (markdown lsp)

---

## General

14. lsp: Einen switch einbauen, mitdem ich regeln kann, was der root für lsp ist: Switch zwischen cwd/nächstes_git/pfad/ zb mit `leader lsp`öffnet ein `lib.nvim -> hover_select` und den scope den man wählt wir lua_ls nochmal neu berechnet auf den scope
15. `ZenMode` sollte auch eienen usrcmds toggle schalter haben
17. ✅ **[No Name]-Buffer-Guard** — wenn nvim aus irgendeinem Grund einen `[No Name]`-Buffer in einem Fenster anzeigen würde (Buffer gelöscht, Fenster geschlossen), aber ein echter benannter Buffer existiert, wird das Fenster stattdessen dorthin umgeleitet. Ausnahmen bleiben intakt: existiert kein Alternativ-Buffer (z.B. letzter Datei-Buffer schließt, oder ein Tree-Plugin ist mit `close_if_last_window = false` das letzte Fenster), bleibt der `[No Name]`-Buffer unangetastet; bewusst erzeugte Scratch-/Temp-Buffer (`:enew`, Plugin-eigene Buffer mit `buftype ~= ""` oder unlisted) werden nie umgeleitet, da die Erkennung rein zustandsbasiert ist (leer, unbenannt, `buftype=""`, gelistet, unmodifiziert) und nur auf `BufDelete`/`BufWipeout`/`WinClosed` reagiert, nie auf jeden Fensterwechsel. Implementiert in `lua/autocmds/general/{init,helpers,defaults,@types}.lua` (`no_name_guard`), verallgemeinert die bereits bewährte Logik aus `filetree.nvim`s `util/buffer.lua:close_for_path()`.

---

## Bugs

16. manchmal bricht `C-c` mit sigint nvim ab, es solte aber alles kopieren des buffers

---

