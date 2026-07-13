# nvim user config cleanup

## Table of content

  - [Liste 1 — Module, die in ein bestehendes Plugin gehören](#liste-1-module-die-in-ein-bestehendes-plugin-gehren)
    - [→ `spelldesk.nvim` (geplant) — **Top-Priorität**](#spelldesknvim-geplant-top-prioritt)
    - [→ `pickers.nvim` (konsolidiert Picker-Module, `:Pickers`)](#pickersnvim-konsolidiert-picker-module-pickers)
    - [→ `filetree.nvim` (neo-tree-Ablösung — größter Block)](#filetreenvim-neo-tree-ablsung-grter-block)
    - [→ gezielte Einzel-Extraktionen](#gezielte-einzel-extraktionen)
    - [→ Eigene *neue* Plugins (passen in KEINES der bestehenden)](#eigene-neue-plugins-passen-in-keines-der-bestehenden)
  - [Liste 2 — Code für `lib.nvim` (Duplikate / generisch)](#liste-2-code-fr-libnvim-duplikate-generisch)
    - [A) Echte Code-Duplikation (3×/2× kopiert)](#a-echte-code-duplikation-32-kopiert)
    - [B) Konzept-Duplikation mit vorhandenen lib-Modulen (konsolidieren statt parallel pflegen)](#b-konzept-duplikation-mit-vorhandenen-lib-modulen-konsolidieren-statt-parallel-pflegen)
    - [C) Beobachtung zum Muster](#c-beobachtung-zum-muster)

---

## Liste 1 — Module, die in ein bestehendes Plugin gehören

Nach Ziel-Plugin gruppiert. „Konfidenz" = wie eindeutig die Zugehörigkeit ist.

---

### → `spelldesk.nvim` (geplant) — **Top-Priorität**
| Modul | Warum | Konfidenz |
|---|---|---|
| `config/trouble/spell/**` (`init.lua`, `@types`) | Vollständige Spell-Correction-Session mit `:SpellChecker`/`:TroubleSpell`, Buffer+cwd-Scope, `vim.diagnostic`, Trouble/Quickfix-Fallback, `z=` fix-and-advance, `]s`/`[s`. **Das ist der Kern von spelldesk** — nicht neu bauen, sondern als Provider/Session-Basis übernehmen. | **sehr hoch** |

---

### → `pickers.nvim` (konsolidiert Picker-Module, `:Pickers`)
Der natürliche Heimatort für **alle** picker-spezifischen Aktionen/Keymaps. Der picker-agnostische Kern wandert nach lib/fileops (siehe Liste 2), hier bleiben nur die dünnen Adapter.
| Modul | Konfidenz |
|---|---|
| `config/telescope/**` (actions/create_file, actions/open_badd, open_background, keymaps, file_browser, history) | hoch |
| `config/fzf/**` (actions/*, files, grep, fzf_opts, keymaps) | hoch |
| `config/snacks/picker/**` (actions/*, keymaps, init) | hoch |
| `config/search/init.lua` | mittel |

---

### → `filetree.nvim` (neo-tree-Ablösung — größter Block)
Fast alle neo-tree-Erweiterungslogiken. Migration läuft laut `git status` bereits (viele `config/neotree/*` gelöscht) — hier die *verbleibenden* echten Feature-Module:
| Modul | Konfidenz |
|---|---|
| `config/neotree/actions/{traverse,project_root,info/node}`, `commands/{add,diff_files,mark,source}`, `helper/{is_ignored_dir,renderer}`, `layout_guard`, `watcher_quarantine`, `sources/switcher`, `window/*` | hoch |
| `config/neotree/keymaps/**`, `event_handlers`, `checkhealth/**` | mittel (teils config-Glue, das bleibt) |

---

### → gezielte Einzel-Extraktionen
| Modul | Ziel-Plugin | Warum | Konfidenz |
|---|---|---|---|
| `config/neotree/actions/pdfport/init.lua` | **pdfport.nvim** | PDF-Extraktion ist dessen Domäne | sehr hoch |
| `config/neotree/commands/markdown/links.lua` | **mdlinks** / **markdown.nvim** | Markdown-Link-Logik | hoch |
| `config/neotree/actions/path/to_require/init.lua` | **project-insight.nvim** | rel-Path→`require()`, passt zu imports/`rel_path_to_require` | hoch |
| `config/neotree/actions/grep_picker/init.lua` | **mygrep.nvim** / pickers | find-or-grep-Menü | hoch |
| `config/urlview/open_in_browser_integration.lua` | **open.nvim** | „route URL/Pfad zum Ziel" ist genau `:Open` | hoch |
| `config/lazygit/actions/{badd,replace}`, `resolve_path` | pickers / buffer-ctx / lib | Badd = Background-Buffer (dupliziert, s. Liste 2) | mittel |

---

### → Eigene *neue* Plugins (passen in KEINES der bestehenden)
Der Vollständigkeit halber, da du „auslagern" fragst — diese Domänen haben kein bestehendes Zuhause:
| Modul | Vorschlag | Warum |
|---|---|---|
| `config/translate/**` | **`translate.nvim`** | `init.lua` nennt sich selbst schon `translate.nvim`; klar abgegrenzte Domäne (TranslateReplace) |
| `wkddap/**` (42 Dateien, DAP-Adapter für 9 Sprachen) | **`dap-kit.nvim`** o. ä. | Echtes **DAP** (Debug Adapter Protocol). **Nicht** debugging.nvim — das macht *Runtime-Editor-Inspektion*, nicht DAP. Andere Domäne. |
| `config/neotest/**` | eigenes / dap-kit-Sibling | Test-Runner-Adapter, große eigenständige Einheit |

---

## Liste 2 — Code für `lib.nvim` (Duplikate / generisch)

---

### A) Echte Code-Duplikation (3×/2× kopiert)
| Duplizierter Code | Fundstellen | lib.nvim-Ziel |
|---|---|---|
| **Datei/Ordner anlegen** (`create_entry`, `ends_with_separator`, `mkdir -p`, Existenz-Check) | `telescope/actions/create_file`, `fzf/actions/create_file`, `snacks/picker/actions/create_file` — **fast identisch** | `lib.nvim.fs.write` / neues `lib.nvim.fs.create_entry` (Kern), Picker-Adapter bleibt in pickers.nvim |
| **Background-Buffer öffnen** (`bufadd`+`bufload`, Pfad-Validierung) | `telescope/actions/open_badd`, `telescope/open_background`, `fzf/actions/open_badd`, `snacks/picker/actions/open_background`, `lazygit/actions/badd` — **5×** | `lib.nvim.buffer` / `lib.nvim.buf_win_tab` (z. B. `open_background(path)`) |
| **ANSI-Escape-Strip** (`gsub("\27%[[%d;]*m", …)`) | `fzf/actions/open_badd` (get_path_from_entry) | `lib.nvim.lua.strings` (`strip_ansi`) |

---

### B) Konzept-Duplikation mit vorhandenen lib-Modulen (konsolidieren statt parallel pflegen)
| Config-Modul | Überschneidet sich mit | Empfehlung |
|---|---|---|
| `config/harpoon/utils/normkey.lua` (Slash-Normalisierung, Drive-Upper, UNC, realpath) | `lib.nvim.cross.fs.separators.normalize`, `lib.nvim.fs.path` | In lib zusammenführen; Harpoon konsumiert lib |
| `config/harpoon/utils/path_label.lua` (Kürzung `<root>/…/<parent>/<file>`) | `lib.nvim.fs.path_shorten` | „`....`"-Elision als Option in `path_shorten` |
| `config/harpoon/utils/fs_project_key.lua` (Git-Root → cwd-Fallback, normalisiert) | `lib.nvim.fs.find_root` + `lib.nvim.git` | `lib.nvim.fs.project_key()` bauen, überall nutzen |
| `config/harpoon/utils/sanitize.lua` | generische Dedup-Logik über normkey | ggf. `lib.lua.tables` + lib-normkey |
| `config/lazygit/resolve_path.lua` | `lib.nvim.fs.path` / `relpath` | nach lib |
| `config/neotree/helper/is_ignored_dir/**` | `lib.nvim.fs.ignore.list` | konsolidieren |
| `config/treesitter/{guards,parser}.lua` (Parser-Verfügbarkeits-Guards) | — (noch nicht in lib) | Kandidat für `lib.nvim.treesitter.guard` (wird an mehreren Stellen gebraucht) |

---

### C) Beobachtung zum Muster
Alle drei Picker-Integrationen (telescope/fzf/snacks) folgen exakt derselben Struktur `actions/{create_file, open_badd/open_background}`. Das ist ein systematisches Auslager-Muster: **generischer Kern → lib.nvim, Entry-Extraktion → pickers.nvim**. Danach schrumpfen die drei Config-Ordner auf reine Verdrahtung.

---

**Empfohlene Reihenfolge:** (1) `trouble/spell` → spelldesk.nvim (fließt direkt in dein aktuelles Projekt ein), (2) die 5×/3× Duplikate → lib.nvim (sofortiger Wartungsgewinn), (3) Picker-Aktionen → pickers.nvim, (4) der große neotree-Block → filetree.nvim.

Soll ich für einen dieser Punkte einen konkreten Extraktions-Plan ausarbeiten — naheliegend `trouble/spell` → spelldesk.nvim, da es direkt an das eben geplante Plugin anknüpft?

---

