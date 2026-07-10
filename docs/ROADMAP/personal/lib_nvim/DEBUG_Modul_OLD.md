# Neues Debug Modul

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

## Features

 Enwticklung einer Strategie für miene custom Plugins, um möglischt sinnvoll logs & messages / notifys auszugeben. Ein `lib.nvim`-Modul dazu wäre ideal, denn dann mus das nicht jedes plugin selbst implementieren... Ein paar Gedanken dazu:
  - Ein Objekt bereitstellen, dass ein funktnoin bereitstellt, dass neben dem normalen notify("") weitere Möglichkeiten ermöglicht, Informationen weiterzugeben. zb.: `lib.nvim.SOMENAME("Some normal notify message", 5, { SOME_KEY = VAL, ..., DUMPINGPATH = "c:/Project/logs" })`
    Dann msüste ein Mechanismus kreirt werden, der zuverlässig bei einen Crash diees Objekt aufrufen und ausgeben kann.
    `DUMPINGPATH` bzw ein besserer Key - wenn dieser angegeben wird, werden alle diese Informationen aller `lib.nvim.SOMENAME` calls dorthin geschrieben
    ... weitere features...

---

# Spezifikation: Zentrales Logging- & Notification-Modul (`lib.logger`)

## 1. Kern-Konzept

Ziel ist die Entwicklung eines robusten, konfigurierbaren Logging- und Benachrichtigungs-Moduls innerhalb von `lib.nvim`. Es kapselt sowohl die Benachrichtigung des Nutzers im UI (`vim.notify`) als auch das strukturierte Schreiben von Debug-Informationen im Hintergrund (Logfiles/Dumps).

Besonderer Fokus liegt auf der **Tragbarkeit** (Transparenz bei Fehlern) und einem **Crash-Recovery-Mechanismus**, der bei kritischen Fehlern den Zustand der Plugins rekonstruierbar macht.

---

## 2. API-Design & Funktionsumfang

Das Modul soll über eine intuitive, flexible Funktion aufgerufen werden können. Statt starrer Argumente nutzen wir ein strukturiertes Options-Table für maximale Flexibilität.

### Vorgeschlagene Signatur:

```lua
local logger = require('lib.logger').new({
    plugin_name = "my_plugin",
    default_dump_path = vim.fn.stdpath("state") .. "/log"
})

-- Beispiel-Aufruf im Code:
logger.log("Repository sync failed", vim.log.levels.ERROR, {
    dump = true,              -- Erzwingt das Schreiben in die Log-Datei
    context = {               -- Beliebige Metadaten für das Debugging
        repo_path = "/home/user/dev/repo",
        active_branch = "main",
        clones_count = 30
    }
})

```

### Parameter-Aufschlüsselung:

* **`message` (String):** Die lesbare Nachricht, die primär im UI (z. B. via `nvim-notify` oder `noice.nvim`) angezeigt wird.
* **`level` (VimLogLevel):** Nutzt die nativen Neovim-Level (`DEBUG`, `INFO`, `WARN`, `ERROR`).
* **`opts` (Table, optional):**
* `context`: Ein Key-Value-Table, das den Zustand der Anwendung zum Zeitpunkt des Logs festhält.
* `dump`: Ein Boolean oder spezifischer Pfad (ersetzt `DUMPINGPATH`). Wenn `true`, wird die Nachricht samt Context sofort serialisiert und persistiert.



---

## 3. Erweiterte Features & Architektur-Ideen

### A. Der In-Memory Ring-Buffer (Für Crash-Dumps)

Ständiges Schreiben auf die Festplatte bremst Neovim aus. Um bei einem Absturz dennoch alle Informationen zu haben, implementieren wir einen **Ring-Buffer** im RAM.

* **Funktionsweise:** Das Modul merkt sich standardmäßig die letzten 50–100 Log-Einträge (auch `DEBUG` und `INFO`) rein im Arbeitsspeicher.
* **Der Crash-Mechanismus:** Tritt ein `ERROR` auf oder stürzt ein Plugin ab (abgefangen via `pcall` / `xpcall`), flusht das Modul den *gesamten* Ring-Buffer gesammelt in die Log-Datei. Du siehst also nicht nur *dass* es gekracht hat, sondern die Historie der letzten Schritte direkt davor.

### B. Automatischer Stack-Trace via `xpcall`

Um den Crash-Mechanismus perfekt zu machen, kann `lib.nvim` einen Wrapper für geschützte Funktionsaufrufe bereitstellen:

```lua
-- In lib.nvim
function M.safe_call(plugin_logger, func, ...)
    local success, err = xpcall(func, debug.traceback, ...)
    if not success then
        plugin_logger.log("Fatal Crash detected", vim.log.levels.ERROR, {
            context = { traceback = err },
            dump = true
        })
    end
    return success, err
end

```

### C. Intelligente Serialisierung (Dumping)

Wenn `context` komplexe Lua-Tables (oder Neovim-Userdata) enthält, müssen diese sauber lesbar gemacht werden.

* **Lösung:** Nutzung von `vim.inspect()`, um die Tables in valide, lesbare Strings zu konvertieren, bevor sie in die Datei geschrieben werden.
* **Pfad-Standardisierung:** Statt hartcodierten Windows- oder Linux-Pfaden nutzen wir `vim.fn.stdpath("state") .. "/your_plugin.log"`. Das ist plattformunabhängig und sauber im Neovim-Ökosystem integriert.

---

## 4. Konfigurations-Beispiel für den Endnutzer

Nutzer deiner Plugins können das Logging-Verhalten global oder pro Plugin steuern:

```lua
require('your_plugin').setup({
    logging = {
        level = vim.log.levels.WARN, -- Nur Warnungen und Fehler im UI anzeigen
        file_logging = true,         -- Im Hintergrund trotzdem Logfiles schreiben
        clear_on_startup = true,     -- Logfile bei jedem Neovim-Start leeren
    }
})

```

---

## 5. Vorteile dieses Ansatzes

1. **DRY (Don't Repeat Yourself):** Einmal stabil in `lib.nvim` geschrieben, profitieren alle deine aktuellen und zukünftigen Plugins davon.
2. **Leistungsstark:** Durch den Ring-Buffer bleibt Neovim performant, da Festplattenzugriffe nur im Ernstfall oder dediziert getriggert werden.
3. **Wartungsfreundlich:** Wenn User ein Issue auf GitHub eröffnen, kannst du sie einfach bitten, den Inhalt von `stdpath("state")/plugin.log` zu posten. Du hast sofort den exakten Context und den Stacktrace.

