Runde 1 ist fertig: nur Analyse, es wurde noch nichts umgestellt. Der Bericht liegt in deiner Config unter `docs/ROADMAP/reports/notify-popup-migration-analyse-2026-09-25.md` (Commit `3337ed0e`, gepusht). Im Anhang steht die vollständige Trefferliste mit Datei:Zeile, Art, Level und Textanfang.

**Wichtigste Erkenntnisse**
- 37 Repos gescannt. Rund 30 nutzen schon `lib.nvim.notify` (345 Stellen, in denen ein Notifier erzeugt wird). Direktes `vim.notify` gibt es nur 79-mal, `nvim_echo` 10-mal, `print(` 69-mal. Sieben Stellen binden `vim.notify` schon beim Modulladen.
- **Größter Hebel:** ein globaler Schalter in `lib.nvim` (`notify.setup({ popup = true })`), einmal in deiner Installations-Spec gesetzt. Damit wären die rund 30 lib-Nutzer ohne Änderung in den Plugins umgestellt. Dazu ein `toast_min_level`, damit chatty Plugins wie `lsp.nvim` die Ecke nicht zumüllen. Alternativ oder ergänzend deckt `ui.notify` aus `ui.nvim` jedes `vim.notify` ab, aber weder `print` noch `nvim_echo`.
- **Direkt anfassen:** etwa 16 Repos mit eigenem Wrapper. Wichtigste Fälle sind `sessions` (sieben fast identische Wrapper), `rules` (lange Config-Fehler), `mdview` (stderr-Meldungen per `nvim_echo`), `media`, `my`, `dap`, `sandbox`, `insights`. Es reicht, jeweils den Wrapper zu ändern.
- **Fehler wie ursprünglich in reposcope:** `color_my_ascii.nvim` bindet `vim.notify` in vier Dateien beim Laden. `filetree` und `sandbox` sichern `vim.notify` nur und müssen vor einer Änderung geprüft werden. Beim `mdview`-Treffer handelt es sich um den Test-Runner, den ich ignoriere.
- **`print`-Ausgaben** sind meist mehrzeilige Debug- und Inspect-Befehle (color_my_ascii 35 Zeilen, replacer 14). Ein Toast wäre dafür falsch. Ich empfehle einen Viewer (`popup.show_lines`) oder sie so zu lassen.

**Deine Zusatzaufgabe, ob sich die Kappung konfigurieren lässt:** Ja, das ist machbar und klein.
- Global per `popup.setup({ max_lines, toast_max_bytes, entry_max_bytes, width, toast_min_level, timeouts })`.
- Pro Aufruf oder Notifier über `deliver`/`create`.
- Umschalten zwischen gekürzt und voll: Der Toast ist bewusst nicht fokussierbar und kann keine eigenen Tasten annehmen. Stattdessen eine globale Taste aus deiner Config, mit `popup.expand_last()` (volle Meldung im Viewer) und `popup.toggle_full()`.
- Offen: Welche Taste, und ob "voll" im Toast oder im Viewer erscheinen soll. Ich empfehle den Viewer.

**Neues Tool:** `lib.nvim.dev.notify_scan` (`:LibNotifyScan [path]`, lib.nvim `17afe44`) mit Test und README. Es steht als neue Zeile in `TOOLS/lua-plugin-tools.md` (wkdbook `1b47842`, Pfad in `bc8a83a` korrigiert). Ich setze es in Runde 2 zur Verifikation nach jedem Repo wieder ein. Im `notify`-README von `lib.nvim` war ein Beispiel durch einen Escape-Fehler kaputt, das ist jetzt behoben (`d3d746f`).

**Zwei Dinge dazu:**
- Im Config-Repo liegen ungespeicherte Änderungen von dir (`ROADMAP.md`, github-stats-Daten). Ich habe nur die Report-Datei committet.
- `nvim -u NONE`-Skripte über die Shell zerstören `\\n`. Im Bericht steht dazu nichts, ich habe es nur beim Scanner-Test gemerkt und mit dem Edit-Tool umgangen.

**Was ich für Runde 2 vorschlage** (Reihenfolge im Bericht, Abschnitt 8): erst lib.nvim (globaler Default, Kappung, `expand_last`/`toggle_full`), dann die Aktivierung in deiner Spec, dann Wrapper-Repos, dann Load-Time-Bindungen, zuletzt die `print`-Dumps. Sag mir, ob ich so starten soll und welche Taste du für "Meldung voll anzeigen" willst.
