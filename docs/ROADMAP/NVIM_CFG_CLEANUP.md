# nvim user config cleanup

## Table of content

  - [Liste 1 — Module, die in ein bestehendes Plugin gehören](#liste-1-module-die-in-ein-bestehendes-plugin-gehren)
    - [→ `pickers.nvim` (konsolidiert Picker-Module, `:Pickers`)](#pickersnvim-konsolidiert-picker-module-pickers)
    - [→ gezielte Einzel-Extraktionen](#gezielte-einzel-extraktionen)
    - [→ Eigene *neue* Plugins (passen in KEINES der bestehenden)](#eigene-neue-plugins-passen-in-keines-der-bestehenden)

---

## Liste 1 — Module, die in ein bestehendes Plugin gehören

Nach Ziel-Plugin gruppiert. „Konfidenz" = wie eindeutig die Zugehörigkeit ist.

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
| `wkddap/**` (42 Dateien, DAP-Adapter für 9 Sprachen) | **`dap-kit.nvim`** o. ä. | Echtes **DAP** (Debug Adapter Protocol). **Nicht** debugging.nvim — das macht *Runtime-Editor-Inspektion*, nicht DAP. Andere Domäne. |
| `config/neotest/**` | eigenes / dap-kit-Sibling | Test-Runner-Adapter, große eigenständige Einheit |

---


