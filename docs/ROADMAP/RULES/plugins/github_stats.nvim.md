# github_stats.nvim

## Zweck
Sammelt GitHub-Repo-Traffic-Statistiken (Clones, Views, Referrers, Paths) periodisch im
Hintergrund über die GitHub REST API, speichert sie lokal als JSON-Historie, und bietet
Commands, Charts, Export und ein interaktives TUI-Dashboard zur Analyse. Quelle: README.md,
lua/github_stats/api.lua, lua/github_stats/storage.lua, lua/github_stats/background.lua,
lua/github_stats/bindings/keymaps.lua.

## Nicht-standard Patterns / Algorithmen

1. `lua/github_stats/background.lua:22-93` — ein `vim.uv`-Timer läuft für die gesamte
   Neovim-Session (nicht nur einmal bei Start), triggert periodisch `run_cycle()`. Der erste
   Zyklus wird per `vim.defer_fn(run_cycle, 1000)` um 1s verzögert, "to avoid competing with
   startup". Das Poll-Intervall (`poll_interval_ms`) ist explizit von der tatsächlichen
   Fetch-Entscheidung entkoppelt: es bestimmt nur, wie oft geprüft wird, ob ein Fetch fällig
   ist (`fetcher.should_fetch()` innen entscheidet das eigentlich), gedeckelt auf max. 60
   Minuten selbst bei einem `fetch_interval_hours` von z.B. 24h. WARUM: verhindert, dass eine
   lang laufende Session bis zu 24h auf den nächsten fälligen Fetch wartet, nur weil sie
   beim letzten VimEnter knapp verpasst wurde — der Timer ist der "Wecker", nicht die
   Fetch-Uhr selbst. `M.start()` ist idempotent (`if timer then return end`).

2. `lua/github_stats/api.lua:50-75` (`fetch_json`) — GitHub liefert für viele Auth-/API-Fehler
   HTTP 200 mit `{"message": "..."}` im Body zurück; ein generischer HTTP-Client sieht das als
   Erfolg. Der Code prüft daher zusätzlich `data_or_err.message`, um diese Fälle als Fehler zu
   behandeln. WARUM: GitHub-API-spezifisches Verhalten hat keine Entsprechung im generischen
   `lib.nvim.net.curl`-Client und muss hier speziell abgefangen werden (Kommentar bestätigt
   das explizit).

3. `lua/github_stats/api.lua:143-229` (`list_user_repos`/`fetch_page`) — rekursive
   Pagination mit hartem Limit `MAX_USER_REPO_PAGES = 30` (100 Repos/Seite → max. 3000 Repos),
   und differenziertem Fehlerverhalten: schlägt Seite 1 fehl → Fehler propagieren (nichts
   zurückzugeben); schlägt eine spätere Seite fehl → bereits gesammelte Ergebnisse trotzdem
   zurückgeben statt alles zu verwerfen. WARUM: ein Nutzer mit sehr vielen Repos soll nicht
   unbegrenzt Pages abrufen (Rate-Limit-Schutz), und ein transienter Fehler auf Seite 5 soll
   nicht die bereits erfolgreich geladenen Seiten 1-4 wegwerfen.

4. `lua/github_stats/storage.lua:44-61,131-138` — Schreiben delegiert an
   `lib.nvim.fs.json.write`, explizit dokumentiert als "atomic write" (Parent-Dirs werden
   automatisch erstellt). WARUM: JSON-Historie darf bei einem Crash während des Schreibens
   nicht in einem korrupten Halbzustand landen — atomarer Write (write-to-temp + rename ist
   die übliche Implementierung dahinter) schützt davor.

5. `lua/github_stats/storage.lua:104-129` — `read_last_fetch()` unterscheidet explizit
   zwischen "Datei fehlt" (kein Fehler, leere Tabelle — es wurde einfach noch nie gefetcht)
   und "Datei existiert aber ist korrupt" (leere Tabelle MIT Fehlermeldung). WARUM: beide
   Fälle liefern denselben Rückgabewert-Typ, aber nur der zweite ist ein tatsächliches
   Problem, das der Aufrufer (`should_fetch`) unterschiedlich behandeln könnte/sollte —
   Kommentar bestätigt das als bewusst erhaltene Unterscheidung.

6. `lua/github_stats/bindings/keymaps.lua:58-83` (`block_cursor_movement`) — im
   Dashboard-Buffer werden native Cursor-Bewegungstasten (h/l, Pfeiltasten, PageUp/Down,
   Home/End) explizit auf `<Nop>` gemappt, mit dem Kommentar "CRITICAL: Blocks native cursor
   movement to prevent race conditions". WARUM: die Dashboard-UI verwaltet Selektions-Index
   und Scroll-Offset selbst in `dashboard_state`; native Cursorbewegung würde den
   Buffer-Cursor bewegen, ohne den internen State zu synchronisieren, und zu Inkonsistenzen
   zwischen sichtbarer Selektion und internem Zustand führen.

7. `lua/github_stats/bindings/keymaps.lua:93-106` (`jump_to_repo`) — `Ngg`/`NgG` springt zu
   Repository-Index N (geclamped auf `[1, #state.repos]`), inklusive Auto-Scroll, falls das
   Ziel außerhalb des sichtbaren Bereichs liegt. WARUM: repliziert Vims eigene `gg`/`G`-Konvention
   (count = Zielzeile) im Kontext eines virtuellen State statt echter Bufferzeilen, mit
   Clamping, damit ein zu hoher Count nie einen Fehler wirft.

## Abgeleitete Guidelines

1. Bei periodischen Hintergrundprozessen: Polling-Intervall vom eigentlichen
   Fälligkeits-Intervall entkoppeln, und das Polling-Intervall deckeln (z.B. max. 60 Minuten),
   damit lange Sessions nicht bis zum nächsten Neustart auf eine fällige Aktion warten.
2. Hintergrund-Timer-Start immer idempotent gestalten (`if timer then return end`) und einen
   expliziten `stop()`-Gegenpart für Tests/Reload anbieten.
3. Erste Ausführung nach Plugin-Load leicht verzögern (`vim.defer_fn`), um nicht mit dem
   Neovim-Startup um Ressourcen zu konkurrieren.
4. Bei Drittanbieter-APIs, die Fehler in einem "erfolgreichen" HTTP-Status kodieren (200 +
   Error-Body), diese API-spezifische Prüfung explizit im API-Client-Modul verorten, nicht im
   generischen HTTP-Layer.
5. Paginierte externe API-Abfragen immer mit hartem Seitenlimit versehen; bei Teilfehlern
   nach erfolgreichen Seiten die bereits gesammelten Ergebnisse zurückgeben statt alles zu
   verwerfen (Best-Effort statt All-or-Nothing).
6. Lokale Persistenzschreibvorgänge (JSON-Historie, Konfiguration) immer atomar
   durchführen (write-temp-then-rename), niemals direkt in die Zieldatei schreiben.
7. "Datei fehlt" und "Datei ist korrupt" beim Lesen von Persistenzdateien unterschiedlich
   behandeln/signalisieren, auch wenn der Rückgabetyp gleich bleibt (leere Struktur vs. leere
   Struktur + Fehlermeldung) — Aufrufer können dann bewusst entscheiden, ob sie warnen wollen.
8. In benutzerdefinierten TUI/Dashboard-Buffern, die einen eigenen visuellen State (Cursor,
   Scroll) außerhalb der nativen Vim-Bufferzeilen führen, alle Tasten, die diesen State
   umgehen könnten (native Cursorbewegung), explizit auf `<Nop>` blocken.
9. Vim-Konventionen (count-Semantik von `gg`/`G`/`<C-d>`/`<C-f>`) auch in eigenen
   virtuellen Widgets nachbilden statt eigene Konventionen zu erfinden — Nutzer erwarten das.
10. Konfigurierbare Keybindings (`dashboard.keybindings`) klar von festen (Pfeiltasten,
    Ctrl-Kombinationen, Esc) trennen und dokumentieren, welche welche Kategorie sind.

## Keybindings-Audit
Aus `lua/github_stats/bindings/keymaps.lua`, im Dashboard-Buffer (buffer-local):

- Navigation (`navigate_down`/`navigate_up`, Default vermutlich j/k, plus feste `<Down>`/`<Up>`):
  - count: JA — `vim.v.count1` wird direkt an `movement.move_cursor_down/up` durchgereicht
    (z.B. `5j` bewegt 5 Repos). Korrekt implementiert.
  - Autocompletion: n.a. (reine Navigation).
  - Fehlende Flags: keine ersichtlich.

- `<C-d>`/`<C-u>` (Scroll halbe Seite):
  - count: JA — `vim.v.count > 0` nutzt den expliziten Count als Zeilenzahl, sonst fixer
    Default von 10 Zeilen. Korrekt und idiomatisch (raw count statt count1, weil 0 einen
    eigenen Default-Fall triggert statt "1 Zeile").
  - Autocompletion: n.a.
  - Fehlende Flags: keine.

- `<C-f>`/`<C-b>` (Seite vor/zurück):
  - count: JA — `vim.v.count1` multipliziert die Seitengröße (`3<C-f>` = 3 Seiten).
  - Autocompletion: n.a.

- `gg`/`G` (Sprung Anfang/Ende):
  - count: JA — `Ngg`/`NgG` springt zu Repo-Index N (`jump_to_repo`, geclamped). Vorbildliche
    1:1-Nachbildung der Vim-Semantik in einem virtuellen State.
  - Autocompletion: n.a.

- `show_details` (Default `<CR>`), `refresh_selected` (Default `r`), `refresh_all` (Default
  `R`), `force_refresh` (Default `f`), `cycle_sort` (Default `s`), `cycle_time_range`
  (Default `t`), `quit` (Default `q`, plus fixes `<Esc>`), `show_help` (Default `?`):
  - count: n.a. für alle — Ein-Repo-Aktionen bzw. Zustandswechsel ohne sinnvolle
    Mengen-Semantik (cycle_sort mit count "N mal weiterschalten" wäre denkbar, ist aber
    nicht implementiert — kleine potenzielle Lücke, kein Bug).
  - Autocompletion: n.a. (keine Ex-Command-Args in diesem Kontext, reine Keymaps im
    Dashboard-Buffer).
  - Fehlende Flags: `cycle_sort`/`cycle_time_range` könnten von einem Count profitieren
    ("3s" = 3 Kriterien weiterspringen), aktuell nicht unterstützt.

- Alle Bindings sind über `dashboard.keybindings` remapbar/deaktivierbar (`""` deaktiviert);
  which-key-Integration ist optional und automatisch (`register_which_key`), fällt still
  zurück, wenn which-key.nvim fehlt.

Ex-Commands (`:GithubStats <subcommand>`, in `bindings/usrcmds/*`, nicht im Detail gelesen)
sind hier nicht auditiert — nur Dashboard-Keymaps.

## Ideen für andere Plugins
1. Ein generisches "Adaptive Background Poller"-Modul in lib.nvim, das das
   Poll-Intervall-vs-Fälligkeits-Intervall-Muster aus `background.lua` kapselt (inkl.
   Startup-Defer, Cap, idempotentem Start/Stop) — direkt wiederverwendbar für jedes Plugin
   mit periodischem externem Datenabruf.
2. Ein generisches "Paginierte externe API mit Seitenlimit + Best-Effort-Teilergebnisse"
   Hilfsmodul, das das Muster aus `api.lua:list_user_repos` (max. Seiten, Teilfehler-Handling)
   für andere Plugins mit paginierten REST-APIs bereitstellt.
3. Ein eigenständiges Plugin/Modul "TUI Dashboard Kit" (Cursor-Blocking, virtueller
   Selektions-State, Auto-Scroll, count-fähige gg/G/Ctrl-d/u/f/b-Nachbildung) als
   wiederverwendbare Basis für andere Dashboard-artige Plugins (Selbst hier sichtbar als
   sich wiederholendes Muster, das gopath.nvim's alternate/ui.lua evtl. auch braucht).
