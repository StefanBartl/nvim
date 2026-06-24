# Plugin-Bündelungs-Plan

## Table of content

  - [Bundle 1: `insert.nvim` — **Stärkster Kandidat**](#bundle-1-insertnvim-strkster-kandidat)
  - [Bundle 2: `fileops.nvim`](#bundle-2-fileopsnvim)
  - [Bundle 3: `lua-dev.nvim` (Lua-spezifisch)](#bundle-3-lua-devnvim-lua-spezifisch)
  - [Standalone (je ein Plugin)](#standalone-je-ein-plugin)
  - [Skip (zu nischig / zu persönlich)](#skip-zu-nischig-zu-persnlich)
  - [Empfohlene Reihenfolge](#empfohlene-reihenfolge)

---

## Bundle 3: `lua-dev.nvim` (Lua-spezifisch)

| Modul | Befehl | Warum hier |
|---|---|---|
| `usrcmds/reload` | `:ReloadCurrentModule` | Lua-Modul neu laden |
| `usrcmds/gather` | `:GatherLua [cwd]` | Lua-Symbole sammeln/anzeigen |

Beide sind ausschließlich für Lua-Entwicklung — sinnvoll zusammen, aber auch separat vertretbar.

---

## Standalone (je ein Plugin)

| Modul | Plugin-Name | Aufwand | Wert |
|---|---|---|---|
| `custom/format` | `format.nvim` | Groß | Hoch |
| `custom/line_marker` | in `insert.nvim` einfalten oder eigen | Minimal | Niedrig |

---

## Skip (zu nischig / zu persönlich)

| Modul | Grund |
|---|---|
| `usrcmds/compress_dir` | Niche-Workflow, keine allgemeine Relevanz |
| `usrcmds/update_repos` | REPOS_DIR-spezifisch, zu personal |
| `usrcmds/migrate` | Einmal-Migrations-Tool |
| `custom/mynotes` | Persönlich |

---

