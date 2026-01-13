# `lib.map`-Roadmap

* Buffer-Scoping
* Batch-Keymaps
* Debug-Flag
* Typprüfung
* Optional Conditional Keymaps
* Logging

## Table of content

- [`lib.map`-Roadmap](#libmap-roadmap)
  - [1. **Performance**](#1-performance)
  - [2. **Sicherheit / Robustheit**](#2-sicherheit-robustheit)
  - [3. **Features**](#3-features)
  - [4. **API-Verbesserungen**](#4-api-verbesserungen)
  - [5. **Weitere kleine Optimierungen**](#5-weitere-kleine-optimierungen)

---

## ideas

- Bei vielen mappoings in einem Modul statt `require("lib.map")` besser eine memoization Variante

---

## 1. **Performance**

* **Fast-path optimieren:**
  Typprüfungen und Debug-Logik nur im Fehlerfall ausführen, wie bisher umgesetzt.
  Zusätzlich könnte man `vim.keymap.set`-Optionen standardisieren, sodass die Tabelle nicht bei jedem Aufruf neu gebaut werden muss, z. B.:

  ```lua
  local default_opts = { noremap = true, silent = true }
  local opts_copy = vim.tbl_extend("force", default_opts, opts)
  ```

  Das spart wiederholtes Setzen von Defaults.

* **Memoisierung von Debug-Info (optional):**
  Falls du viele Keymaps in einer Datei setzt, kann man die Quelle der aufrufenden Datei (info.source) einmal pro Datei cachen, um `debug.getinfo` seltener aufzurufen.

---

## 2. **Sicherheit / Robustheit**

* **Vermeidung von globalen Variablen:**
  Alle temporären Variablen im Funktions- oder Modul-Scopes halten, wie bisher umgesetzt.

* **Striktere Typprüfung:**

  * Prüfen, ob `modes`-Array nur Strings enthält.
  * Prüfen, dass `opts.buffer` nur gültige Buffer-IDs oder `true` sind.
  * Optional `opts.desc` auf String erzwingen.

* **Fail-Safe:**
  Wenn `vim.keymap.set` aus irgendeinem Grund fehlschlägt, könnte man einen `pcall` einfügen und einen Fehlerlog schreiben.

---

## 3. **Features**

* **Chained/Batch Keymaps:**
  Eine kleine Utility hinzufügen, die mehrere Keymaps auf einmal setzt, z. B.:

  ```lua
  map.batch({
    { "n", "<leader>ff", function() ... end },
    { "v", "<leader>fc", function() ... end },
  }, opts)
  ```

* **Modes-Abkürzungen:**
  Kürzel wie `"n"` für normal, `"i"` für insert, `"v"` für visual, `"x"` für visual block, etc.
  Intern automatisch in die Long-Version übersetzen.

* **Conditional Keymaps:**
  Optionales Flag, um Keymaps nur unter bestimmten Bedingungen zu setzen, z. B. abhängig von Plugin-Verfügbarkeit:

  ```lua
  map.set("n", "<leader>dc", dbg.toggle, { cond = function() return dap.loaded end })
  ```

* **Logging / Debug-Level:**
  Ein globales `map.debug = true`-Flag, das `vim.notify`-Meldungen aktiviert oder deaktiviert.
  Damit kann man die Fehlermeldungen in produktiven Setups stummschalten.

* **Silent Wrapper für bestimmte Keys:**
  Man könnte automatisch `silent=true` für alle Keymaps setzen, die keine Benutzerinteraktion brauchen, um Tippen flüssiger zu machen.

---

## 4. **API-Verbesserungen**

* **Optionale Rückgabe der Keymap-Objekte:**
  `vim.keymap.set` gibt keine Handles zurück. Man könnte selbst ein kleines Table bauen, um später die Keymaps nach Key, Mode, Buffer wiederfinden zu können.

* **Autodokumentation:**
  Man könnte die `desc`-Felder der Keymaps in einer Tabelle sammeln, um später automatisch ein Cheat-Sheet der Keymaps zu erzeugen.

* **Support für `<buffer>` in desc:**
  Optional könnten die Buffer-Keymaps automatisch im `desc` markiert werden, z. B. `"Toggle DAP UI [buf]"`.

---

## 5. **Weitere kleine Optimierungen**

* **Vermeidung mehrfacher `type()`-Aufrufe:**
  Für jeden Parameter einmal auswerten und dann Flags setzen (bereits umgesetzt).

* **Erweiterbare Helper-Funktion:**
  `notify_caller` könnte Parameter wie `opts.expr` oder `opts.nowait` prüfen, falls man Keymaps für spezielle Plugins setzt.

* **Optionales Debug-Only Logging:**
  Keymaps könnten beim Setzen automatisch loggen, nur wenn ein globaler Debug-Flag aktiv ist. Das hilft besonders beim Aufbau großer Konfigurationen.

---

