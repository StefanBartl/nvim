Ich schreibe die Änderungen per Skript in die Übergabe und nehme dabei nur diese Datei.

Die Übergabe ist aktualisiert und auf `main` im Vault (`f7bd853`). Die Datei behält den Namen `handovers/tasks-desktop-stand-2026-10-15_HANDOVER.md`, damit die Verweise gültig bleiben, der Titel sagt „Stand 2026-10-16 (Nacht)“.

## Zusammenfassung

**Stand**
- **Pins:** Engine `tasks.nvim@98a1d02`, lib.nvim `@6f30218`.
- **CI:** Beide Repos sind grün, zuletzt `tasks-desktop@ae79d64`.
- **Tests:** Engine 70 Specs, Oberfläche 358 Unit-Tests und 75 Browser-Tests.

**Seit dem letzten Stand**
- **Zweiter Chat:**
  - Hub-Umbau: `server.rs` ist ein Ordner von Modulen, die Aufrufe der Engine eine Tabelle, dazu `AppIdentity`, `GuardRules` und `Core<R>` für die spätere Herauslösung nach `appkit`.
  - Die Engine nutzt jetzt `lib.nvim.contract.*`.
  - Das Review von `1d7768f` und `aac65a0` samt Fixes.
- **Produktfehler hinter einem flackernden Test (`54136ee`, `a8827db`):** Eine Seite mit gespeicherter Sitzung und Cache fragte vor `hello` ohne Sitzung, bekam 401 und landete auf der Kopplungsseite. Jetzt hält sie die Sitzung sofort.
- **Hover-Erklärungen** (`f6c7a6b`, `ae79d64`):
  - Board, Inbox und Matrix sind erklärt, dazu die Marken der Zeilen.
  - Das Popup zieht in ein offenes modales Dialogfenster um.
  - Escape bei offener Erklärung schließt nur sie.

**Reviews:** Alle Code-Commits sind 🟢 oder Fix-Commits. Bewusst offen sind die Last von `finished`, der Seitensprung bei „Mehr zeigen“, ein möglicher Screenreader-Wiederholungseffekt in der Matrix und die Heuristik im Kachel-Test.

**Was noch offen ist**
- **A. Zuerst:**
  - Rust-Tests für die Routen `finished` und `links` sowie ein Browser-Test für „Mehr zeigen“. Das läuft im zweiten Chat.
  - Den flackernden Board-Test untersuchen (Task `flackernder-browser-test-the-board-cards-move-by-key-and-by`).
- **B. Aus diesem Chat:**
  - **Hover-Erklärungen:** Rest sind die Codes der Befunde des Checks, der Graph, der Zustand der Vaults, die Akteur-Etiketten in den Listen, die Bestandsaufnahme und der Rundgang durch die ganze Oberfläche.
  - **Erledigte Tasks:** Im Plan fehlt eine Stufe, Board und Matrix zeigen sie nicht, der Zeitraum der Liste wird nicht gemerkt, und Debounce oder Cache für große Vaults fehlt.
  - **Verbindungen:** Es fehlen erledigte Tasks, die Gruppierung nach „berührt mehrere Bereiche“ und eine Netz-Darstellung.
  - **Filter:** Spannen für Aufwand und Wert, Filter merken, Filter in Board, Inbox und Matrix.
  - **`.exe`:** Linux-Build, ein Lauf auf sauberem Konto (von dir) und `release.yml`.
  - **Claim-Task:** wartet auf deine Entscheidung zum Speicherort.
- **C. Aus früheren Übergaben:**
  - Lücken beim Verwalten von Tasks, Ansichten gruppieren (fünf Entscheidungen von dir).
  - Standalone-Web-Version, Touch-Bedienung der Kacheln und Datenklassen-Entscheidung.
  - P6a-Rest, P7 (Tauri-Hülle, Installer, Updater-Schlüssel, Neovim bündeln, About und Bugreport).
  - Engine-Verträge, Regelwerk-Stände, P9, P10, P12 und weitere kleine Tasks.
  - Das Kill-Kriterium-Review ab 2026-10-26.
  - Die Co-Autor-Zeile in alten Commits entfernst du nur per Force-Push auf dein Wort.

**Text zum Einfügen im nächsten Chat**

> Mach weiter mit `E:\repos\tasks-vault\wkdbook-tasks.nvim\handovers\tasks-desktop-stand-2026-10-15_HANDOVER.md` (Stand 2026-10-16 Nacht). Lies danach die `CLAUDE.md` in `tasks.nvim` und `tasks-desktop`. Zuerst: `gh run list --branch main` in beiden Repos ansehen und `git log origin/main` (ein zweiter Chat arbeitet am Hub-Umbau und an den Rust-Tests der Routen: nichts doppelt machen), dann Abschnitt A3 und B der Übergabe, zuerst die Erklärungen für Check-Codes, Graph und Vaults. Antworte auf Deutsch, Code und Commit-Bodies auf Englisch, nie mehr als einen Agenten zugleich, Commits direkt auf `main`, keine Co-Autor-Zeile; am Ende jeder Antwort die laufende Commit-Liste mit Review-Markierung. Force-Push für die Co-Autor-Zeile nur auf mein ausdrückliches Wort.

**Commits dieses Chats**

| Repo | Commit | Beschreibung | Review |
| --- | --- | --- | --- |
| tasks-vault | `f7bd853` | Übergabe, Stand 2026-10-16 (Nacht) | 🟢 nur Doku |
| tasks-desktop | `ae79d64` | Fixes aus dem Review von `f6c7a6b` | Fix-Commit |
| tasks-desktop | `f6c7a6b` | Hinweise für Board, Inbox, Matrix; Popup im modalen Dialog | 🟢 (Agent-Review, hoch) |
| tasks-vault | `e72ee3b`, `3586b83` | Task „Hover-Erklärungen“, Task Board-Flackern | 🟢 nur Doku |
| tasks-desktop | `a8827db` | Fixes aus dem Review von `54136ee` | Fix-Commit |
| tasks-desktop | `54136ee` | Sitzung sofort setzen | 🟢 (Agent-Review, hoch) |
| tasks-desktop | `aac65a0` | Verbindungen Stufe 2 | 🟢 (Review vom anderen Chat, Fixes `2bf9ec5`, `42c0e06`) |
| tasks.nvim | `1d7768f` | `tasks.links` | 🟢 (Review vom anderen Chat, Fixes `7573242`, `e34f847`) |
| tasks-vault | `16509c2`, `069b8dc`, `6f10d79` | Übergabe, Kopfzeilen-Fix, Task „Querverbindungen“ | 🟢 nur Doku |
| tasks-desktop | `2d62618`, `f8d919c`, `830ff18`, `7ac536a` | Fix-Commits früherer Reviews | Fix-Commit |
| tasks.nvim | `6ebe777`, `a0ba4ae` | Fix-Commits früherer Reviews | Fix-Commit |
| terminal.nvim | `908a771` | Fix aus dem Review von `0ab0268` | Fix-Commit |
| tasks-desktop | `8f6f773`, `d56b2d2`, `2ba3cf2`, `3d4a520`, `d7ada48`, `8612ebb` | Erledigt in Liste/Plan, Ansicht Erledigt, Plan-Kopf, Hover, Filter, Verbindungen Stufe 1 | 🟢 (Agent-Review, hoch) |
| tasks.nvim | `b3b2eae`, `fcda275`, `6f72cd2` | `finished` mit Plan, `completion.finished`, `tasks.finished` | 🟢 (Agent-Review, hoch) |
| tasks-vault | `7440f3b`, `56fcb93`, `cd2fee4`, `3fe026f` | Tasks „Erledigte Tasks“, Claim, Filter, Verbindungen | 🟢 nur Doku |
