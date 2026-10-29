# docmap-desktop — Live-Test-Checkliste (Stand 2026-10-02)

Alles, was zu `v0.6.0` und zur Traffic-Integration (L11) gebaut ist, aber nie in einem echten
Fenster oder mit echten Daten lief. Gebaut und mit Fixtures bzw. `cargo test` (129 grün) und
`node --test` geprüft ist alles; was hier steht, kann keine Sitzung ohne deine Maschine, deine
GUI oder deinen GitHub-Token. Checkbox-Konvention: `- [ ]` offen, `- [x]` verifiziert. Bei jedem
Punkt eine Zeile `Notiz:` für Beobachtungen. Findet sich etwas, ist `v0.6.1` die billige Antwort.

Hintergrund: Plan und Entscheidungen in
`$REPOS_DIR/tasks-vault/docmap-desktop/` (`ROADMAP/PLAN.md`,
`Backlog/TASKS/docmap-desktop_HANDOVER.md`); Bau-Protokoll der Traffic-Integration in
`ALL/Backlog/FEATURES/github-stats-traffic-integration*.md`.

---

## Wie starte ich das?

Installer: <https://github.com/WKDSteve/docmap-desktop/releases/latest>
→ `docmap-desktop_0.6.0_x64-setup.exe`. **`v0.6.0` wurde am 2026-10-02 neu geschnitten.** Hast du
die erste Fassung schon installiert, jetzt neu installieren; die richtige erkennst du in
*Help → About* am Engine-Commit **`440bfb7`** (die alte hatte `4bd684e`).

---

## A1 — die installierte App durchklicken (`docs/RELEASING.md`)

- [ ] **Help → About** nennt Engine `440bfb7` und einen Build.
  Notiz:
- [ ] Ein Projekt ist wählbar, seine Karte lädt.
  Notiz:
- [ ] **Generate map** läuft, die Statuszeile meldet es.
  Notiz:
- [ ] **File → Settings…** öffnet, der Theme-Wechsel greift.
  Notiz:
- [ ] **Add from a parent folder** (z. B. `E:\repos`): Checkliste erscheint, Import läuft,
      bereits vorhandene Projekte werden gemeldet statt doppelt angelegt.
  Notiz:
- [ ] **View as matrix…**: Raster öffnet, Zelle = Aufrufstellen, der Tooltip nennt die Module.
  Notiz:

---

## A3 — Traffic (L11) gegen einen echten Fetch

Voraussetzung: in Neovim mit deinem Token `:GithubStats fetch`. Danach in der App.

**Die sieben Punkte der Ende-zu-Ende-Prüfung:**

- [ ] **Zwei Maschinen.** Fetch auf A, synchronisieren, B öffnen: Der Digest von B wird beim
      Start neu aufgebaut (nicht veraltet), und B hat im Intervall nicht erneut gefetcht.
  Notiz:
- [ ] **Plugin fehlt.** App und `documentation.nvim` verhalten sich wie vorher; kein Fehler,
      nichts Leeres gerendert.
  Notiz:
- [ ] **`ui.nvim` fehlt, Plugin da.** Die Sonde findet trotzdem `github_stats.digest`.
  Notiz:
- [ ] **Lazy-geladenes Plugin.** `soft_require.probe` lädt es; kein User-Command nötig.
  Notiz:
- [ ] **Überschriebenes `digest_dir`.** `root.json` am Standardort verweist darauf; App und
      Plugin finden es ohne Einstellung.
  Notiz:
- [ ] **Feindlicher Digest.** Fixture mit `<img onerror=…>` als Referrer, `../../etc/passwd` und
      `C:\Windows` als Pfaden, einer 3-MiB-Datei und `schema: 99`: Text ist inert, nichts
      außerhalb der Projektwurzel bekommt einen Link, die Datei wird mit Meldung abgelehnt.
  Notiz:
- [ ] **Privates Repo + Opt-out.** Für ein ausgeschlossenes Projekt wird nichts angezeigt, und in
      keinem exportierten Artefakt steht etwas davon.
  Notiz:

**Die Oberfläche dazu (nie in einem echten Fenster gesehen):**

- [ ] Seitenleiste: die Traffic-Zeile eines Projekts mit GitHub-Remote zeigt echte Zahlen.
  Notiz:
- [ ] Übersicht: 30-Tage-Zahl an den Zeilen, die welche haben; die Sortierung nach Traffic
      stimmt mit den Zahlen überein; ein Projekt ohne Remote zeigt nichts.
  Notiz:
- [ ] **Detaildialog** (Klick auf die Traffic-Zeile): Sparkline pro Serie über die ganze
      gespeicherte Spanne, Referrer, Top-10-Seiten. Mindestbreite der App: nichts abgeschnitten,
      kein horizontales Scrollen.
  Notiz:
- [ ] Eine Top-Seite, die im Projekt existiert, ist ein Link und öffnet die Datei in deinem
      Editor an der richtigen Stelle; eine, die es nicht gibt, bleibt Text.
  Notiz:
- [ ] **Look again** liest nach einem neuen Fetch die neuen Zahlen.
  Notiz:
- [ ] Opt-out an einem Projekt: Zeile und Dialog verschwinden sofort, ohne Neustart.
  Notiz:

**Die Härtungen, die erst im Review dazukamen:**

- [ ] **Ask Neovim** findet bei normaler Konfiguration den Ordner (Knopf in den Einstellungen).
  Notiz:
- [ ] **Ask Neovim, hängende Konfiguration:** in `init.lua` vorübergehend etwas Blockierendes
      (z. B. `vim.fn.input("x")`) einbauen. Der Knopf bricht nach ca. 30 s mit der Meldung
      „no answer within 30 s … does the Neovim configuration wait for input?" ab und ist danach
      wieder bedienbar. Konfiguration zurückbauen.
  Notiz:
- [ ] `root.json` mit einem **relativen** `digest_dir` (z. B. `"somewhere/else"`) wird ignoriert;
      die Auffindung fällt auf `<Ordner>/digest` zurück.
  Notiz:
- [ ] **Zwei Repos, gleicher Dateiname** (`a_b/c` und `a/b_c` teilen den Stem `a_b_c`): sagt die
      Seitenleiste „nicht erfasst", zeigt auch der Dialog nichts Fremdes.
  Notiz:

---

## documentation.nvim und rules.nvim in Neovim

- [ ] `:DocBrowse traffic` im Browser-Modus zeigt dieselben Zahlen wie die App (P3).
  Notiz:
- [ ] `:Rules stats` auf dem echten Regelsatz
      (`$REPOS_DIR/WKDBooks/Development/wkdbook-lua/checklists`) lädt weiter alle Regeln, nachdem
      der Parser Titel, Section und Text mitführt und die Blöcke in der Sandbox laufen
      (erwartet: 421 Regeln, 13 Familien, 32 mit `check`; Abweichung = Fund).
  Notiz:
- [ ] Windows-Pfad mit `%` (z. B. ein Projektordner `100%`): ein Panel, das die Engine über
      `--api=` fragt (Commits, Telemetry), meldet eine klare Verweigerung statt eines falschen
      Ergebnisses. Nur relevant, wenn du so einen Ordner hast; sonst überspringen.
  Notiz:

---

## Von `documentation.nvim` noch nie visuell geprüft

Beides ist syntaktisch und strukturell geprüft, aber nicht in einem echten Fenster gesehen.
`docmap-desktop/tools/preview/` löst das nur für die Oberfläche der App, und ein Browser ist
nicht WebView2 — also in der App öffnen, nicht im Browser.

- [ ] Das **eingeklappte Engine-Panel** auf der generierten Seite.
  Notiz:
- [ ] Das **Kanten-Popup** im Aufrufgraphen.
  Notiz:
- [ ] Phase 4 (UI-Politur): die Typografie-Skala (16 verschiedene `font-size`-Werte gemessen) und
      die Zebra-Streifen brauchen ein Urteil von dir, bevor jemand sie anfasst.
  Notiz:

---

# Neue Live-Checks (Stand 2026-10-29)

Ergänzung zu den Abschnitten oben, ohne sie zu ändern. Jeder Block gehört zu einer offenen Task im
`tasks-vault` (Area `docmap-desktop`). Die Einzelpunkte stehen oben in A1, A3 und den beiden
Neovim-Blöcken; hier steht, was die Tasks **zusätzlich oder anders** festhalten, und die Reihenfolge
für eine Sitzung. Haken setzt du an beiden Stellen (oben und hier), oder nur hier und oben
„siehe Stand 2026-10-29“ in die Notiz. Ist ein Block durch, die Task mit `done` schließen. Ein
Befund: eine Zeile unter „Falls rot“, daraus wird eine `kind: bug`-Task.

**Vorher (für alle Blöcke 1 bis 4):**

- Windows-Maschine mit GUI; die **installierte** App, kein Browser (WebView2 ist nicht der Browser,
  `tools/preview/` beweist nur das Layout der App-Oberfläche).
- Notieren, **welcher Build** installiert ist (*Help -> About*: Version und Engine-Commit).
  `v0.6.0` hat Engine `440bfb7`. Gibt es inzwischen `v0.6.1`, den Walkthrough auf dieser Fassung
  machen und den Engine-Commit in *About* neu prüfen (Task `release-v0-6-1-decision`).
- Neovim mit Token für `:GithubStats fetch` (nötig für Block 3 und 4).

Empfohlene Reihenfolge in einer Sitzung: 1, 2, dann einmal `:GithubStats fetch` und 3 und 4 mit
demselben Fetch, danach 5 (`github_stats.nvim`, siehe unten) und 6.

## 1. Installierte App einmal durchgehen (A1) — offen

Task: `docmap-desktop/live-test-installed-app`. Code: `docmap-desktop@0e66563`. Einzelpunkte:
Abschnitt **A1** oben.

- [ ] Installer `docmap-desktop_0.6.0_x64-setup.exe` aus dem neuesten Release installieren
      (<https://github.com/WKDSteve/docmap-desktop/releases/latest>); *Help -> About* nennt Engine
      `440bfb7` und einen Build (Build hier notieren: ______)
- [ ] Projekt wählbar, Karte lädt; **Generate map** läuft, die Statuszeile meldet es
- [ ] **File -> Settings...** öffnet, Theme-Wechsel greift
- [ ] **Add from a parent folder** (z. B. `E:\repos`): Checkliste erscheint, Import läuft,
      bereits bekannte Projekte werden gemeldet statt doppelt angelegt
- [ ] **View as matrix...**: Raster öffnet, Zelle = Anzahl Aufrufstellen, Tooltip nennt die Module
- [ ] **NEU, steht oben nicht:** Workspace-Übersicht („All projects“): Zeilen sichtbar, das
      Abhängigkeits-Panel (Dependency panel) zeigt etwas Sinnvolles, **Generate the out-of-date
      ones** erzeugt genau die veralteten Karten. Hintergrund: gebaut (M4, `src/lib/overview.js`,
      Befehl `workspace_deps` in `src-tauri/src/main.rs`), bisher nur über `tools/preview/` mit
      Stub-Bridge gesehen, nie in der installierten App.

Falls rot:

- [ ] Welcher Punkt, welche Meldung, Screenshot; Task `kind: bug` in `docmap-desktop` mit `refs:`
      auf die Zeile oben. Jeder rote Punkt hier führt laut Task zu einem `v0.6.1`.

Danach: Task `live-test-installed-app` mit `done` schließen; Ergebnis je Punkt oben in den `Notiz:`-Zeilen.

## 2. Engine-Panel (eingeklappt) und Kanten-Popup im Aufrufgraphen — offen

Task: `docmap-desktop/live-test-engine-panel-and-call-edge-popup`. Einzelpunkte: letzter Block
oben („Von `documentation.nvim` noch nie visuell geprüft“, jetzt Repo `docmap.nvim`, siehe unten).
Beides **in der installierten App** prüfen, nicht im Browser.

**Engine-Panel** (Seitenleiste, `<details id="engine">`):

- [ ] Panel lässt sich öffnen und schließen (Maus)
- [ ] Per Tastatur erreichbar und bedienbar (Tab bis zum Panel, Enter bzw. Leertaste klappt auf/zu)
- [ ] Die Summary-Zeile ist eingeklappt lesbar und zeigt genau eines von: `ready`,
      `N of M grammars`, `no grammars`, `not found` (Wert hier notieren: ______). Passt der Wert zum
      Zustand im aufgeklappten Panel und in *File -> Settings...* (Abschnitt Engine)?

**Kanten-Popup im Aufrufgraphen** (Hierarchy -> Calls einer Projektkarte, in der App geöffnet):

- [ ] Klick auf eine Kante zeigt ein Popup; es schließt sich wieder (Escape, Klick daneben)
- [ ] Offene Frage zur Task: im Code (`docmap.nvim`, `core/render/html.lua`, Klasse `hedge-tip`)
      ist die Kantenanzeige eine **Hover**-Anzeige (`pointer-events:none`), die Task sagt „Klick“.
      Notieren, was in der App tatsächlich passiert (Hover, Klick oder beides).

Falls rot: Defekt am Panel = `kind: bug` in `docmap-desktop`; am Popup = `kind: bug` in `docmap.nvim`.

Danach: Task mit `done` schließen; Ergebnis in den `Notiz:`-Zeilen des letzten Blocks oben.

Hinweis (kein Prüfpunkt): Der Punkt „Phase 4 (UI-Politur)“ im letzten Block oben ist veraltet. Er
wurde am 2026-08-12 entschieden (Typografie-Skala von fünfzehn auf zehn Werte vereinheitlicht,
Zebra-Streifen abgelehnt) und braucht kein Urteil mehr; er hat keine Task.

## 3. Traffic-Oberfläche gegen einen echten Fetch (A3) — offen

Task: `docmap-desktop/live-test-traffic-surface`. Einzelpunkte: Abschnitt **A3** oben, die Blöcke
„Die Oberfläche dazu“ und „Die Härtungen“. Der erste A3-Block (sieben Ende-zu-Ende-Punkte) gehört
zu `github_stats.nvim`, siehe Block 5 und die Datei `github_stats-live-checks-2026-10-29.md`;
beides mit **demselben Fetch** in einer Sitzung.

Vorbereitung: in Neovim `:GithubStats fetch`, App neu öffnen bzw. **Look again**.

- [ ] Seitenleiste: Traffic-Zeile eines Projekts mit GitHub-Remote zeigt echte Zahlen
- [ ] Übersicht: 30-Tage-Zahl an den Zeilen mit Daten, Sortierung nach Traffic stimmt mit den Zahlen
      überein, Projekt ohne Remote zeigt nichts
- [ ] Detaildialog (Klick auf die Traffic-Zeile): Sparkline pro Serie über die ganze gespeicherte
      Spanne, Referrer, Top-10-Seiten; bei Mindestbreite der App nichts abgeschnitten, kein
      horizontales Scrollen
- [ ] Top-Seite, die im Projekt existiert, ist ein Link und öffnet die Datei im konfigurierten
      Editor an der richtigen Stelle; eine nicht existierende bleibt Text
- [ ] **Look again** liest nach einem neuen Fetch die neuen Zahlen
- [ ] Opt-out an einem Projekt: Zeile und Dialog verschwinden sofort, ohne Neustart
- [ ] **Ask Neovim** (Settings) findet bei normaler Konfiguration den Ordner
- [ ] **Ask Neovim** mit hängender Konfiguration (`vim.fn.input("x")` vorübergehend in `init.lua`):
      der Knopf gibt nach ca. 30 s auf mit „no answer within 30 s ...“ und ist danach wieder
      bedienbar; `init.lua` zurückbauen!
- [ ] `root.json` mit **relativem** `digest_dir` (z. B. `"somewhere/else"`) wird ignoriert, die
      Auffindung fällt auf `<Ordner>/digest` zurück
- [ ] Zwei Repos mit gleichem Dateistamm (`a_b/c` und `a/b_c` ergeben beide `a_b_c`): Seitenleiste
      sagt „not tracked“, der Dialog zeigt nichts Fremdes

**Wichtig laut Task:** Drei Härtungen sind erst **nach** dem Tag `v0.6.0` (`bb44b41`) gelandet
(`3d0af4a`, `d411d94`, `c3b1a9a`, alle auf `origin/main`): der erklärende Fehlertext, wenn ein
abgelehntes `digest_dir` nichts übrig lässt; der einmalige Durchlauf der Auffindungskette pro Liste;
UNC-Zeiger und Gerätenamen werden abgelehnt; das Töten des Kindprozesses bei einem `try_wait`-Fehler.
Im Installer `v0.6.0` sind sie nicht enthalten. Also notieren, welcher Build getestet wurde
(______), und diese Teilpunkte nur gegen einen Build mit diesen Commits bewerten.

Falls rot: Zeile, Build, Screenshot; `kind: bug` in `docmap-desktop` mit `refs:` auf die Zeile oben.

Danach: Task `live-test-traffic-surface` mit `done` schließen.

## 4. Neovim-Seite: Browse-Modus, Regelwerk-Lader, `%`-Pfad — offen

Task: `docmap-desktop/live-test-neovim-side-checks`. Einzelpunkte: Block „documentation.nvim und
rules.nvim in Neovim“ oben. Gleiche Sitzung wie Block 3.

- [ ] `:DocBrowse traffic` zeigt für ein Projekt nach einem Fetch dieselben Zahlen wie die App
      (Block 3). Hinweis: `documentation.nvim` heißt seit 2026-10-24 `docmap.nvim`; die Befehle
      `:DocMap` und `:DocBrowse` sind gleich geblieben.
- [ ] `:Rules stats` auf `wkdbook-lua/checklists` (bzw. `$RULES_VAULT/rulesets/lua`) lädt ohne
      Ladefehler. **Erwartung ist korrigiert:** nicht „421 Regeln“, sondern gemessen am 2026-10-04
      **430 Regeln, 13 Familien, 32 mit `check` (398 ohne), 0 Ladefehler**. Eine Abweichung von 430
      (nicht von 421) ist ein Befund. Gemessenes hier: ______
- [ ] Projektordner mit `%` im Windows-Pfad (z. B. `100%`), falls vorhanden: ein Panel, das die
      Engine über `--api=` fragt (Commits, Telemetry), zeigt eine klare Verweigerung statt eines
      falschen Ergebnisses. Sonst notieren: „übersprungen, kein solcher Ordner“.

Falls rot: Befehl, Ausgabe, Zahlen; `kind: bug` in der zuständigen Area (`docmap.nvim` bzw. `rules.nvim`).

Danach: Task `live-test-neovim-side-checks` mit `done` schließen; Ergebnis in den `Notiz:`-Zeilen oben.

## 5. Verweis: Traffic-Digest-Kette (`github_stats.nvim`)

Die sieben Ende-zu-Ende-Punkte (erster A3-Block oben) haben in `github_stats.nvim` die Task
`traffic-digest-e2e-check`. Schritte, Befehle und Falls-rot-Abschnitt stehen in
`github_stats-live-checks-2026-10-29.md` in diesem Ordner. Haken können hier oben in A3 und dort
gesetzt werden.

## 6. Mac: Menüleiste und erster Start — offen, braucht einen Mac

Task: `docmap-desktop/macos-menu-bar-variant` (Aufwand M, Tags `macos`, `ui`, `needs-user`). Die
Task ist überwiegend Entwicklungsarbeit; **live prüfbar** ist nur der erste Punkt. Der Rest (macOS-
Menüvariante in `menu.rs`, Test, Engine-Entscheidung, Release-Assets) wird nicht hier abgehakt.

Voraussetzung: ein Mac (oder CI-Runner mit Display und einer Person), `.dmg` für x64 oder aarch64
aus `v0.6.0`. Die macOS-Installer enthalten **keine Engine**; die App startet ohne Fallback und sucht
eine Engine auf `PATH`, sonst meldet sie, keine gefunden zu haben (erwartetes Verhalten, kein Fund).

- [ ] App aus dem `.dmg` installieren und starten (Gatekeeper-Meldung notieren, falls sie kommt)
- [ ] Fenster, Menüleiste, *About*, *Quit*, Sprachumschalter: was steht in der Menüleiste, was ist
      an der macOS-Konvention falsch (Anwendungsmenü mit About, Preferences, Quit; File ohne Quit;
      Tastenkürzel in macOS-Schreibweise)? Eine Zeile je Abweichung
- [ ] Erste-Start-Meldung ohne Engine: verständlich? Findet **Locate...** bzw. `PATH` eine Engine,
      wenn man eine bereitstellt?

Falls rot / Ergebnis: alle Abweichungen als Liste in die Task-Notizen; die Umsetzung (Menüvariante,
Test, Engine-Entscheidung oder Assets aus dem Release nehmen) bleibt offen und ist eigene Arbeit.
Frage: soll diese Task in eine Live-Check-Task (Mac-Begehung) und eine Entwicklungs-Task geteilt werden?

Danach: Task **nicht** schließen, nur Ergebnis des ersten Punktes in den Notizen festhalten.
