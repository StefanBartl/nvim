# Gitsigns — Autocmds

Registriert über
[lua/autocmds/git/init.lua](../../../../../lua/autocmds/git/init.lua)
(`require('autocmds.git').enable(cfg)`, aufgerufen mit `cfg = true` aus
[lua/autocmds/init.lua](../../../../../lua/autocmds/init.lua) — d.h. es
gelten die Defaults aus
[lua/autocmds/git/defaults.lua](../../../../../lua/autocmds/git/defaults.lua)
unverändert).

Beide Autocmds sind **[custom]** — gitsigns selbst registriert intern eigene
Autocmds für die Sign-Aktualisierung, aber diese beiden hier sind zusätzliche,
config-eigene Wrapper, die gezielt `require("gitsigns").refresh()` bzw.
`blame_line()` aufrufen.

---

| Gruppe | Event(s) | Quelle | Zweck | Status |
|---|---|---|---|---|
| `gitsigns_refresh` | `BufEnter`, `FocusGained` (konfigurierbar via `gitsigns_refresh.events`) | [autocmds/git/gitsigns_refresh.lua](../../../../../lua/autocmds/git/gitsigns_refresh.lua) | Ruft `gitsigns.refresh()` auf, damit die Sign-Spalte nach Fokuswechsel/Buffer-Wechsel aktuell bleibt. **Aktiv** (`enable = true` im Default). | [custom] |
| `blame_on_hold` | `CursorHold` | [autocmds/git/blame_on_hold.lua](../../../../../lua/autocmds/git/blame_on_hold.lua) | Zeigt Inline-Blame via `gitsigns.blame_line({ full = false, ignore_whitespace = true, virt_text = … })` für die Zeile unter dem Cursor. Buftype-Ausschluss über `ignore_buftypes` (Default `{ "nofile", "prompt" }`), optionale Verzögerung über `delay`. **Inaktiv per Default** (`enable = false` in `defaults.lua`) — wird also derzeit nicht ausgeführt, obwohl der Code registriert würde, sobald `enable = true` gesetzt wird. | [custom] |

---

## Details

- `gitsigns_refresh`: Default-Events `{ "BufEnter", "FocusGained" }`, überschreibbar
  über `cfg.gitsigns_refresh.events` (wird durch `shared.norm_events`
  normalisiert). Der Refresh-Aufruf ist `pcall`-geschützt, falls gitsigns
  gerade nicht geladen ist.
- `blame_on_hold`: obwohl per Default deaktiviert, ist die Implementierung
  vollständig vorhanden — bei `delay > 0` wird der Blame-Aufruf über
  `vim.defer_fn` verzögert, sonst synchron im `CursorHold`-Callback
  ausgeführt.
- Beide Submodule laufen unter derselben Orchestrierung wie `commit_ft`
  (siehe [autocmds/git/init.lua](../../../../../lua/autocmds/git/init.lua));
  `commit_ft` selbst ist aber allgemeines `gitcommit`-Filetype-Tuning (Spell,
  Textwidth, `startinsert`, …) und nicht gitsigns-spezifisch — daher hier
  nicht aufgeführt.
