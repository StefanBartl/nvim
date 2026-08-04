# Plugin-Review anhand von `runtime-analysis.nvim` + `documentation.nvim`

Ziel: nach ein paar Tagen echter Nutzung für **jedes eigene `*.nvim`-Plugin**
eine begründete Entscheidung treffen — löschen, refactorn, testen,
dokumentieren oder unverändert lassen — statt aus dem Bauch heraus.

Teil 1 ist das Konzept: wie die beiden Plugins zusammen gelesen werden.
Teil 2 ist der eigentliche Ablauf pro Plugin. Teil 3 sagt, was aus einem
Befund konkret folgt.

---

## Teil 1 — Das Konzept: statisch vs. real, und wo sie sich treffen

Die Grundidee, die alles andere hier begründet:

- **`documentation.nvim`** sagt, was der **Quellcode behauptet** — welche
  Funktionen deklariert sind, ob sie dokumentiert sind, wo Code dupliziert
  ist, welche Dateien sich oft ändern (Churn), welche Funktion laut
  statischer Erreichbarkeitsanalyse tot aussieht.
- **`runtime-analysis.nvim`** sagt, was **tatsächlich passiert ist** — in
  genau der laufenden Session: welche Funktion wie oft aufgerufen wurde,
  mit welchen Argumenten, von wo, wie lange es dauerte.

Keins von beiden allein reicht. Ein statischer Scan kann nicht wissen, ob
eine "tote" Funktion in Wirklichkeit von einem Callback aus aufgerufen
wird, den er nicht sieht (dynamischer Dispatch, `vim.keymap.set`-Callback,
Aufruf aus einem anderen Repo). Telemetrie allein kann nicht wissen, ob
eine drei Tage lang nie aufgerufene Funktion tot ist oder einfach ein
Feature ist, das man nur einmal im Monat braucht. **Die Kombination beider
— `:DocBrowse telemetry` — ist der eigentliche Wert.**

### Die vier Felder des Telemetry-Joins

`:DocBrowse telemetry` markiert jede Funktion mit genau einem von vier
Zuständen:

| Badge | Bedeutet | Was das nahelegt |
|---|---|---|
| `✕` | Kein statischer Aufrufer **und** nie aufgerufen | Echter Löschkandidat |
| `○` | Statischer Aufrufer vorhanden, aber nie aufgerufen | Erreichbar, aber ungenutzt — kalter Code |
| `!` | Aufgerufen, aber **kein** statischer Aufrufer gefunden | Falsch-positiver `dead-function`-Fund — Callback, dynamischer Dispatch, oder ein Aufruf aus einem anderen Repo |
| *(kein Badge)* | Aufrufer vorhanden **und** aufgerufen | Gesund, nichts zu tun |
| *(kein Eintrag)* | Für diese Funktion gibt es gar keine Telemetriedaten | Kein Befund — keine Aussage, auch keine negative |

Wichtig, weil es sich falsch anfühlt, wenn man es vergisst: **Abwesenheit
von Daten ist niemals ein Beweis für irgendetwas.** Ein Plugin, das diese
Session noch nicht geladen wurde, oder ein Modul, das von `deep = true`
nicht erreicht wurde, zeigt "keine Daten" — nicht "bestätigt tot".

### Die ehrlichen Grenzen (warum "ein paar Tage" wichtig ist)

- **Telemetrie sieht nur, was während der Aufzeichnung passiert ist.** Ein
  Feature, das man absichtlich selten nutzt (einmal im Monat, nur bei
  einem bestimmten Anlass), zeigt in einem 3-Tage-Fenster nichts — das ist
  kein Löschkandidat, nur ein seltener Pfad.
- **`package.loaded`-basierte Werkzeuge** (`:RA inspect`, der
  Loaded-vs-Declared-Diff `:DocBrowse loaded`) sehen nur **diese eine
  laufende Session**. Ein `ft`/`cmd`/`event`-lazy-geladenes Modul, das
  einfach noch nicht getriggert wurde, sieht aus wie "nicht geladen" —
  nicht wie "tot".
- **Argument-Fingerprints sind Bucket-basiert, nicht vollständig.** "91 %
  ein Fingerprint" ist ein Hinweis, kein Beweis — die echten Werte
  anschauen, bevor daraus eine Konsequenz gezogen wird.
- **Churn-Hotspots sind kein Bug-Indikator.** Häufig geänderter,
  komplexer Code ist ein Wartungsrisiko, keine Aussage über Qualität — er
  kann genauso gut gerade aktiv weiterentwickelt werden.

### Nachschlagetabelle: welches Signal wofür Beweis ist — und wofür nicht

| Signal | Quelle | Legt nahe | Beweist NICHT |
|---|---|---|---|
| `✕`, keine Telemetriedaten dagegen | `:DocBrowse telemetry` | Echter Löschkandidat | Dass es wirklich tot ist — kann ein selten genutzter, aber bewusst öffentlicher Einstiegspunkt sein |
| `○`, Aufrufer vorhanden, 0 Calls | `:DocBrowse telemetry` | Erreichbar, aber ungenutzt | Ob es wirklich ungenutzt ist oder nur in diesem Fenster nicht getriggert wurde |
| `!`, aufgerufen, kein statischer Aufrufer | `:DocBrowse telemetry` | Callback / dynamischer Dispatch / Cross-Repo-Konsument | Nichts Negatives — nicht löschen, ggf. annotieren, damit der statische Scan es nicht weiter meldet |
| Hohe Argument-Fingerprint-Konzentration | `:RATelemetry cost`/`export` | Memoisierungs- oder Vereinfachungskandidat | Dass die übrigen Fingerprints nicht real erreichbar sind |
| Churn × Komplexität | `:DocMap churn` | Refactor-würdig | Dass der Code fehlerhaft ist |
| Code-Duplikate | `:DocMap check` | Extraktionskandidat | In welche Richtung extrahiert werden sollte |
| `declared_only` (Loaded-Diff) | `:DocBrowse loaded` | Tote Datei **oder** korrekt lazy-geladen, nur noch nicht getriggert | Welches von beiden — dafür `ft`/`cmd`/`event` im Spec nachsehen |
| `loaded_only` (Loaded-Diff) | `:DocBrowse loaded` | Generiertes Feld / gewrapptes Objekt / Tippfehler im Export | Welches der drei — dafür den echten Code lesen |
| Route mit `○` (nie gesendet) | `:DocBrowse endpoints` | Ungetesteter API-Pfad | Dass die Route kaputt ist — kann einfach selten genutzt sein |
| `undocumented-param` / fehlendes `@return` | `:DocMap check` | Doku-Schuld | Priorität — das hängt vom Call-Count ab (siehe unten) |
| Heiß **und** langsam (bei aktiviertem `timing`) | `:RATelemetry cost` | Performance-Untersuchung wert | Wo die Zeit tatsächlich hingeht — vor jeder Optimierung erst profilen |
| Kalte Keymap/Kommando | `:RA usage` | Bindung, die real nie gedrückt wird — Kandidat für Änderung/Entfernung | Ob andere Nutzer sie brauchen würden (zählt nur die eigene Nutzung) |
| Wrapper-Herkunft unklar | `:RA provenance <path>` | Wer eine Funktion aktuell überschreibt — exakt für eigene Telemetry-Wraps, best-effort sonst | Bei fremden Wraps: nur die Quellposition, nicht WER/WANN gewrapped hat |

---

## Teil 2 — Ablauf pro Plugin

### Einmalige Voraussetzung

- [ ] `:RATelemetry` läuft bereits — ist über
      `plugins/personal/init.lua` → `config.telemetry` automatisch für
      **jedes aktivierte eigene Plugin** aktiv (`deep = true`,
      `profile_args = true`), dynamisch aus dem echten lazy-Spec
      abgeleitet. Kein manuelles Setup nötig — nur prüfen mit
      `:checkhealth runtime-analysis` oder einem bloßen `:RATelemetry`.
- [ ] Die Plugins ein paar echte Tage lang normal benutzen — ein Review
      direkt nach einem frischen Neustart beweist nichts.
- [ ] `:DocMap`/`:DocBrowse` brauchen kein Setup pro Plugin: beide mappen
      bewusst das aktuelle Arbeitsverzeichnis
      (`plugins/personal/init.lua`'s eigener Kommentar dazu), also reicht
      es, im jeweiligen `e:\repos\<name>.nvim` zu sein.

### Pro Plugin (für jede Zeile der Tabelle unten wiederholen)

1. **Ins Repo wechseln** — `e:\repos\<name>.nvim`, damit `:DocMap`/
   `:DocBrowse` automatisch richtig verwurzeln (cwd-basiert).
2. **`:DocBrowse telemetry`** — die Liste durchgehen, gezielt nach `✕`
   und `!` suchen (kein automatisches Sortieren nach "schlimmstem
   zuerst", also wirklich durchscrollen).
   - Jedes `✕`: wirklich tot, oder ein dokumentierter, aber seltener
     Einstiegspunkt? → Verdict notieren.
   - Jedes `!`: ist es wirklich ein Callback (Autocmd-/Keymap-Rhs)? Wenn
     ja, nichts tun. Wenn nicht klar, nachsehen, warum der statische
     Scan den Aufrufer nicht findet.
3. **`:DocBrowse loaded`** — der `runtime-analysis.nvim`-eigene §5.3-Diff,
   nur aussagekräftig, weil dieses Plugin in der laufenden Session
   tatsächlich geladen ist.
   - `declared_only`: tote Datei, oder ein Lazy-Load-Pfad
     (`ft`/`cmd`/`event`), der diese Session einfach noch nicht gefeuert
     hat? Im eigenen Spec in `plugins/personal/init.lua` nachsehen.
   - `loaded_only`: zur Laufzeit generiert / von etwas gewrapped /
     Tippfehler im Export — den echten Code lesen.
4. **`:DocMap check`** (oder `:DocMap full` für den LuaLS-angereicherten
   Durchlauf) — die statischen Befunde des Plugins:
   - `dead-function` — gegen Schritt 2 gegenprüfen, bevor man ihm traut
     (`documentation.nvim` unterdrückt einen `dead-function`-Fund bereits
     automatisch, sobald Telemetrie die Funktion als lebendig beweist —
     was hier noch gemeldet wird, hat diesen Check also schon überstanden).
   - `code-duplicates` — Extraktionskandidaten.
   - `churn-hotspot` — Refactor-Kandidaten.
   - `undocumented-param` / fehlendes `@return` — Doku-Schuld.
5. **`:RATelemetry cost <namespace>`** (oder `:RATelemetry export` nach
   Markdown) — heiße Pfade und Argument-Fingerprints:
   - Höchste Call-Counts — lohnt sich Memoisierung, oder legt ein stark
     konzentrierter Argument-Fingerprint nahe, dass ein Parameter gar
     keiner sein müsste?
   - Falls `timing` je für dieses Plugin aktiviert war: heiß **und**
     langsam zuerst untersuchen, bevor irgendwo optimiert wird.
6. **Falls das Plugin HTTP-Requests sendet** (z. B. `github_stats.nvim`,
   `sandbox.nvim`, `pdfport.nvim`s Ollama-Aufrufe): `:DocBrowse endpoints`
   — irgendeine Route, die laut `runtime-analysis.nvim`s eigener History
   nie gesendet wurde?
7. **Verdict eintragen** — `behalten` / `refactor` / `löschkandidat` /
   `tests-ergänzen` / `docs-ergänzen` / `untersuchen`.

### Snapshot — zu prüfende Plugins

Aktuelle Liste der aktivierten eigenen Plugins (Stand 2026-08-04, vor dem
eigentlichen Durchgang neu ableiten — `plugins.personal.list` liest den
echten lazy-Spec live, also nie von Hand pflegen; im Zweifel den
zugehörigen `:MyPlugins`-Befehl fragen, falls der eine `list`-Ausgabe
druckt, sonst `:lua vim.print(require("plugins.personal.list").read())`).

`lib.nvim` steht separat: es bekommt standardmäßig **keine**
Argument-Profilierung (`lib_profile_args = false` in
`config/telemetry.lua`, bewusst — die Aggregat-Primitive laufen oft in
Loops, wo 0,6 µs/Call ein echter Preis für eine ungefragte Antwort wäre),
nur Call-Counting. Entsprechend weniger Tiefe bei den Argument-Befunden
für dieses eine Repo einplanen.

| Plugin | `✕` gefunden | `!` gefunden | Loaded-Diff-Befund | Churn/Duplikate | Verdict |
|---|---|---|---|---|---|
| buffer-ctx.nvim | | | | | |
| cascade.nvim | | | | | |
| cmdlog.nvim | | | | | |
| color_my_ascii.nvim | | | | | |
| dap.nvim | | | | | |
| debugging.nvim | | | | | |
| diff.nvim | | | | | |
| documentation.nvim | | | | | |
| emojis.nvim | | | | | |
| fileops.nvim | | | | | |
| filetree.nvim | | | | | |
| github_stats.nvim | | | | | |
| gopath.nvim | | | | | |
| insights.nvim | | | | | |
| language.nvim | | | | | |
| lib.nvim *(separat, s.o.)* | | | | | |
| markdown.nvim | | | | | |
| mdview.nvim | | | | | |
| open.nvim | | | | | |
| pdfport.nvim | | | | | |
| pickers.nvim | | | | | |
| recommender.nvim | | | | | |
| replacer.nvim | | | | | |
| reposcope.nvim | | | | | |
| runtime-analysis.nvim | | | | | |
| sandbox.nvim | | | | | |
| sessions.nvim | | | | | |
| spotlight.nvim | | | | | |

Nicht aktiv geladen, daher hier nicht sinnvoll prüfbar (kein
`package.loaded`, keine Telemetrie) — falls relevant, separat per
`:DocMap` von außen (ohne laufende Session) prüfen: `filetreepicker.nvim`,
`mygrep.nvim`, `neotree-fs-refactor`, `migrate.nvim` (letzteres hat laut
`plugins.personal.list`'s eigenem Kommentar aktuell gar keinen echten
Plugin-Spec, taucht nur in `github_stats`' Repo-Liste auf).
`learn-cli.nvim` ist über `source.lua`s Mode-Tabelle bewusst deaktiviert.

---

## Teil 3 — Was aus einem Verdict konkret folgt

- **löschkandidat**: vor dem Löschen trotzdem einmal übers ganze
  Ökosystem grep'en — eine Funktion, die nur von einem ANDEREN eigenen
  Plugin aus aufgerufen wird (nicht von diesem selbst), zeigt hier `!`,
  nicht `✕`, aber ein Cross-Repo-Aufruf aus einem Plugin, das gerade
  nicht geladen war, würde trotzdem nicht auftauchen.
- **refactor**: Churn × Komplexität ist ein Signal zum Einplanen, kein
  Grund, alles stehen und liegen zu lassen.
- **tests-ergänzen**: die höchstwertige Stelle ist "heiß und ungetestet"
  — Call-Count aus Schritt 5 gegen `:DocMap check`s Testabdeckungsbefund
  von Hand gegenlesen, bis es dafür einen eigenen Join gibt.
- **docs-ergänzen**: nach Call-Count priorisieren — eine oft aufgerufene,
  undokumentierte Funktion wiegt schwerer als eine kalte.
- **untersuchen**: `loaded_only`- und `!`-Befunde gehören hierher, bis
  der Code tatsächlich gelesen wurde — beide sind absichtlich keine
  automatischen Urteile.

## Literatur und Referenzen

- `runtime-analysis.nvim` — [`README.md`](https://github.com/StefanBartl/runtime-analysis.nvim/blob/main/README.md), [`docs/FINISHED.md`](https://github.com/StefanBartl/runtime-analysis.nvim/blob/main/docs/FINISHED.md) (§3.1 Call trees, §5.1 `:RA inspect`, §5.3 Loaded-vs-Declared, §6.1–6.3 die Joins)
- `documentation.nvim` — [`docs/ECOSYSTEM.md`](https://github.com/StefanBartl/documentation.nvim/blob/main/docs/ECOSYSTEM.md), [`docs/FEATURES.md`](https://github.com/StefanBartl/documentation.nvim/blob/main/docs/ROADMAP/FEATURES.md)
- Diese Config — `lua/config/telemetry.lua` (die Policy), `lua/plugins/personal/list.lua` (die live abgeleitete Plugin-Liste)
