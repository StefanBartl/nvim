# lsp.nvim — `:Lsp <subcommand>` Cheatsheet

Ein Command, gebaut über `lib.nvim.usercmd.composer` (`<Tab>`-Completion).

Source: `C:\repos\lsp.nvim\lua\lsp\bindings\usrcmds.lua`
Docs: `docs/BINDINGS.md`, `README.md`, `doc/lsp.nvim.txt`
Konzept: `docs/ROADMAP/personal/lsp.nvim.md` (Source of Truth), §8.2

> **Stand 2026-08-23: Gerüst.** Das Plugin konfiguriert noch keinen Language
> Server. Die Routen unten sind die, die nichts aus der Migration brauchen —
> sie lesen Neovims eigenen LSP-Zustand, nicht den des Plugins. Das Plugin ist
> in der Config **nicht installiert**; `lua/lsp/**` macht die Arbeit weiterhin
> selbst.

| Command | Args | Effekt |
| --- | --- | --- |
| `:Lsp status` | — | Was das Plugin aufgesetzt hat: aufgelöste Config, gebundene Keymaps, ob `:Lsp` registriert ist, Config-Warnungen |
| `:Lsp servers` | — | Aktuell attachte LSP-Clients mit Root-Verzeichnis und Buffer-Anzahl |
| `:Lsp health` | — | `:checkhealth lsp` |
| `:Lsp log open` | — | Neovims LSP-Logdatei in einem Split öffnen |
| `:Lsp log level` | `trace\|debug\|info\|warn\|error\|off` | LSP-Log-Level setzen (Completion über die Enum) |

Keine der Routen ist range-aware: sie berichten globalen Zustand, eine
Zeilen-Range hat dort keine Bedeutung. Bei den geplanten Routen `format` und
`diag` (§8.2) ist das neu zu prüfen.

Ausgabe geht in einen Scratch-Split, nicht in eine Notification — mehrzeilig
und zum Lesen/Kopieren gedacht.

## Geplant (§8.2)

`start`, `stop`, `restart [here]`, `format [on|off|toggle|status|which]`,
`diag [qf|loc|next|prev]`, `workspace [on|off|toggle|status|now]`,
`root [pick|show]`, `doctor [health|debug|quick|deep|all]`, `recover` — plus
die rund 30 heutigen `:Lsp*`-Einzelcommands als dünne Legacy-Aliase
(`usrcmds.legacy_aliases`, Default an).

## Notizen

- **Doku-Datei heißt `doc/lsp.nvim.txt`**, nicht `doc/lsp.txt`: Neovims Runtime
  liefert selbst ein `doc/lsp.txt` (`:h lsp`), zwei Dateien gleichen Namens
  machen `:help lsp.txt` mehrdeutig. Alle Tags sind `lsp.nvim-…` präfixiert.
- **Modulwurzel-Kollision:** solange die Config ihr eigenes `lua/lsp/**` hat,
  gewinnt sie auf der `runtimepath` und überschattet das Plugin komplett.
  Config-Ordner löschen und Plugin installieren müssen derselbe Schritt sein.
