# nvim user config cleanup

## Table of content

    - [→ gezielte Einzel-Extraktionen](#gezielte-einzel-extraktionen)
    - [→ Eigene *neue* Plugins (passen in KEINES der bestehenden)](#eigene-neue-plugins-passen-in-keines-der-bestehenden)

---

## → gezielte Einzel-Extraktionen
| Modul | Ziel-Plugin | Warum | Konfidenz |
|---|---|---|---|
| `config/neotree/actions/pdfport/init.lua` | **pdfport.nvim** | PDF-Extraktion ist dessen Domäne | sehr hoch |
| `config/lazygit/actions/{badd,replace}`, `resolve_path` | pickers / buffer-ctx / lib | Badd = Background-Buffer (dupliziert, s. Liste 2) | mittel |

---

## → Eigene *neue* Plugins (passen in KEINES der bestehenden)
Der Vollständigkeit halber, da du „auslagern" fragst — diese Domänen haben kein bestehendes Zuhause:
| Modul | Vorschlag | Warum |
|---|---|---|
| `wkddap/**` (42 Dateien, DAP-Adapter für 9 Sprachen) | **`dap-kit.nvim`** o. ä. | Echtes **DAP** (Debug Adapter Protocol). **Nicht** debugging.nvim — das macht *Runtime-Editor-Inspektion*, nicht DAP. Andere Domäne. |
| `config/neotest/**` | eigenes / dap-kit-Sibling | Test-Runner-Adapter, große eigenständige Einheit |

---


