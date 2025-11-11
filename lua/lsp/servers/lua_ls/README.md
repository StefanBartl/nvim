# lsp/servers/lua_ls - Readme

## Table of content

    - [Modulstruktur](#modulstruktur)
    - [`ignoreDir` vs. `find_type_dirs`](#ignoredir-vs-find_type_dirs)
    - [LSP-Setup (`init.lua`)](#lsp-setup-initlua)
    - [Zusammenfassung](#zusammenfassung)

---

### Modulstruktur

```sh
lua\lsp\servers\lua_ls\
├─ rootresolver.lua
├─ init.lua
├─ ignore.lua
├─ find_type_dirs.lua
└─ build_library.lua
```

  * Saubere Trennung von Verantwortlichkeiten: `ignore.lua` kümmert sich um Ausschlussmuster, `build_library.lua` erzeugt den Workspace-Library-Pfad, `rootresolver.lua` übernimmt die Root-Ermittlung.
  * `init.lua` ist schlank und orchestriert die LSP-Konfiguration.
  * Klare Trennung zwischen LSP-spezifischem Code (`setup`) und Hilfsfunktionen (`debug_root`, `debug_library`).

---

### `ignoreDir` vs. `find_type_dirs`

* `ignore.as_luals_patterns()` erzeugt ein Muster, das LSP beim Indexieren ignoriert.
* `find_type_dirs` ist ein seprater Scanner, der gezielt `types`-Verzeichnisse findet.

**Unterschiede:**

| Zweck                                      | `ignoreDir`                  | `find_type_dirs`           |
| ------------------------------------------ | ---------------------------- | -------------------------- |
| Filter für LSP Preload / Workspace Scan    | Ja                           | Nein                       |
| Findet Typdefinitionen (`@types`, `types`) | Nein                         | Ja                         |
| Dynamik                                    | Statisch aus ignore-Patterns | Dynamisch über FS-Scan     |
| Verwendung                                 | Workspace-LSP                | Workspace-Library-Building |

* **Empfehlung:** Beide getrennt lassen, aber Patterns für `.git`, `node_modules` usw. könnten in einer gemeinsamen Konstanten stehen, um Redundanz zu vermeiden.

---

### LSP-Setup (`init.lua`)

* Sehr sauber aufgebaut, nutzt `shared` für gemeinsame Capabilities und Attach-Handler.
* `on_new_config` verwendet `build_library(new_root)` – das sorgt für eine pro-Root-spezifische Library.
* `ignoreDir` wird aus einem dedizierten Modul geliefert – saubere Trennung.
* `debug_*` Funktionen helfen beim Testen und Troubleshooting.

---

### Zusammenfassung

**Stärken:**
* Modularisierung: Jede Aufgabe hat ein eigenes Modul (`ignore`, `build_library`, `rootresolver`).
* Root-Logik robust, gut hierarchisiert.
* Flexible LSP-Konfiguration (Capabilites, on_attach, on_init).
* Optional Debug-Funktionen.

---
