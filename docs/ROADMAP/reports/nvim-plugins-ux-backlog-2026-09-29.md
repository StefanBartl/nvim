# Bericht: nvim-Plugin-UX-Backlog — Session vom 2026-09-29

Zusammenfassung der gesamten Chat-Session: der ursprüngliche Auftrag (unten
bereinigt aus dem Original-Paste), was pro Punkt tatsächlich getan wurde, und
eine zusätzliche, nicht ursprünglich angefragte Bugfix-Serie, die sich aus
einem ultracode-Review der eigenen Session-Commits ergeben hat. Für die
konkrete Live-Test-Checkliste (Checkboxen zum Abhaken) siehe
[`Final_Checks/Running-Tasks_Checklist.md`](../Final_Checks/Running-Tasks_Checklist.md)
— dieser Bericht hier ist die erzählende Referenz dazu: was war der Auftrag,
was kam tatsächlich raus, welche Commits gehören dazu.

---

## Ursprünglicher Auftrag (bereinigt)

Der Original-Paste war roh/tippfehlerbehaftet; hier die bereinigte,
strukturierte Fassung der neun ursprünglichen Wünsche.

### 1. Einheitliches Chip/Toast/UI-Theme-System
In vielen Plugins gibt es Presets für den Style von Chips, Toasts usw., die
aber nicht aufeinander abgestimmt sind — weder Namensgebung noch die Styles
selbst. Gewünscht: ein System, das das vereinheitlicht und weit über
einfaches Colorscheme-Theming hinausgeht (ganze UIs gestaltbar), inklusive
zweier konkreter Stilrichtungen: "rounded chips" und ein ASCII-Stil im
Omarchy/Hacker-Look.

### 2. filetree.nvim: blinkendes "unsaved changes"-Icon
Das Icon blinkt weiterhin (bestehendes, bekanntes Problem).

### 3. lsp.nvim: keine Autocompletion bei `---` in Markdown
Wenn in Markdown ein Trennzeichen `---` getippt wird, poppt beim letzten `-`
die eigene Plugin-Namensliste als Vorschlag auf. Gewünscht: eine Art
"Nicht-Liste"/Guard, die das in diesem Kontext unterdrückt.

### 4. Doppelte Benachrichtigung: Chip UND "more"-Anzeige
Ausgaben wie `:Hover all off` erzeugen sowohl einen Chip rechts oben als auch
eine normale Meldung unten am Bildschirm. Gewünscht: nur der Chip, die
Meldung soll still (`silent`) in `:messages` landen — das sollte mit dem neu
gebauten `lib.nvim.output` bereits möglich/Default sein. Frage: warum ist das
nicht der Fall, und ob sich bei `noice.nvim` etwas abschauen lässt.

### 5. replacer.nvim / pickers.nvim: Preview-Pane zu schmal
Im dreigeteilten UI (Resultatsliste, Prompt, Preview) ist die Preview zu
schmal für lange Treffer (z. B. URLs). Gewünscht, für alle betroffenen
Picker-UIs:
1. Tasten zum Bewegen in der Preview (buffer-lokal, am besten
   `<C-Arrow>`/hjkl; PageUp/PageDown seitenweise statt zeilenweise).
2. Eine Legende an der unteren Kante, zentriert.
3. Ein Cheatsheet erreichbar über `<C-?>`.

### 6. lib.nvim output: Chip + `:messages` sauber trennen, plus Titel-Konzept
Zwei verwandte Wünsche:
- Schreiben in `:messages` soll standardmäßig `silent` passieren (kein
  zusätzliches "more" unten), konfigurierbar. Konkretes Beispiel: ein
  `git pull` im Gitsuite-Dashboard zeigt aktuell sowohl Chip als auch
  "more" — verwirrend.
- Für lange Chip-Inhalte (z. B. eine mehrzeilige Fehlermeldung): ein
  "Titel"-Konzept, sodass der Chip nur einen Titel + abgeschnittenen Text
  zeigt, der volle Text bleibt in `:messages`/`:noice` abrufbar. Zusätzlich
  gewünscht: für rohe, nicht von einem Plugin stammende Nvim-Meldungen
  (Beispiel: ein natives `E354: Invalid register name`) automatisch
  erkennen, was Titel und was Inhalt ist, und ob es sich um einen Fehler
  oder eine Debug-Notiz handelt — ohne dass ein Plugin das explizit liefert.

### 7. runtime-analysis.nvim: 7-Tage-Reminder als Popup
Der Reminder läuft aktuell als reines `notify`; er soll stattdessen als
Popup laufen, das zusätzlich in `:messages` schreibt — vermutlich über
`lib.nvim.output`.

### 8. `:MyPlugins reclone`: Popup statt Text-Prompt
Der Ja/Nein-Prompt vor dem Reclone mehrerer Plugins soll ein richtiges Popup
mit Zusammenfassung sein (`lib.nvim` Selection/Prompt), nicht der bisherige
Text-Prompt.

### 9. Statusline-Progress: Live-State im Hover + zentraler Popup-Befehl
Wenn ein Plugin seinen Fortschritt über ein Statusline-Modul anzeigt, soll
das Hovern über dieses Modul nicht nur eine statische Beschreibung zeigen,
sondern den aktuellen Live-State. Zusätzlich: ein genereller Befehl (Vorschlag
`:Ui statusline showProgress`), der denselben Fortschritt als Popup zeigt —
damit nicht jedes der mehreren Plugins mit eigenem Statusline-Modul einen
eigenen Toggle-Popup bauen muss.

---

## Was tatsächlich passiert ist — Übersicht

Zuerst wurden alle neun Punkte gegen den aktuellen Code verifiziert (nicht
blind umgesetzt) — dabei stellte sich heraus, dass mehrere Punkte bereits
ganz oder teilweise erledigt waren, und dass Punkt 1 (Theme-System) einen
Großteil seiner Infrastruktur bereits hatte. Alle neun Punkte wurden
abgeschlossen. Im Anschluss wurde auf expliziten Wunsch ein mehrstufiger
"ultracode"-Review (Multi-Agent, adversarial verifiziert) über alle
Code-Commits gefahren, der mehrere echte Bugs in den eigenen Session-Änderungen
fand — insbesondere eine tiefe Kette rund um die neue Chip-Titel-Funktion in
`lib.nvim`, die über sechs Nachbesserungsrunden lief, plus eine
nachgelagerte, separat gestartete Session für zwei dabei entdeckte
*vorbestehende* (nicht von dieser Session verursachte) Bugs.

---

## Task für Task

### 1. Theme-System — größtenteils schon vorhanden, Rest ergänzt

**Befund:** Die Namensgebung/Style-Vereinheitlichung existierte bereits
fleet-weit: `ui.kit/presets.lua` (kanonische Shape-Namen `classic`/`chip`/
`rounded_chip`) und `ui.kit/theme.lua` (Rahmen+Farben-Presets, von praktisch
jeder `ui.kit`-Oberfläche genutzt). "Rounded chips" war bereits der
ausgelieferte Standard.

**Umgesetzt:**
- Neuer Befehl `:UI kit-preset <name>` / `:UI kit-presets` in ui.nvim —
  schaltet den Popup/Toast-Preset interaktiv um (vorher nur per Lua-`setup()`
  erreichbar) und schaltet passende Tabline-Styles automatisch mit
  ("kombinierter Schalter").
- Neuer Preset `hacker`: Monochrom-Grün auf Schwarz, ASCII-Box — als
  bewusste einzige Ausnahme von "jeder Preset bleibt Colorscheme-adaptiv"
  (feste Hex-Farben statt Standard-Group-Links), Name bewusst ohne
  Omarchy-Bezug (Nutzerwunsch).
- Audit über den Fleet nach UI-Flächen mit hartkodiertem "immer rounded,
  nie themed": 4 echte Fälle gefunden und gefixt (Statusline-Hover-Tooltip,
  filetree.nvim-Float-Preview, replacer.nvim `:ReplaceTest`-Panel,
  sessions.nvim Marks-Preview). Ein fünfter Fall (pickers.nvim
  Quickfix-Preview) wurde bewusst **nicht** angefasst — eigenes
  dokumentiertes Config-Feld plus Wiederverwendungs-Logik, die nicht zu
  `ui.kit.surface`s Einmal-Erzeugung passt.
- Nebenfund: `ui.kit`s in `lib.nvim` eingefrorene Kopie war reindriftet
  (reiner Kommentarumbruch, vom Drift-Guard erkannt) — synchronisiert.

**Commits:** `ui.nvim@b6343b0`, `ui.nvim@542383a`, `ui.nvim@b98a0a9`,
`lib.nvim@8f96c69`, `lib.nvim@638a03a`, `filetree.nvim@8dbdfd1`,
`replacer.nvim@27fc1e2` (Doku), `sessions.nvim@ff0a23d`

### 2. filetree.nvim blinkendes Icon — bestätigte, nicht behebbare Grenze

**Befund:** Kein eigenes Icon von filetree — natives Neo-tree-Marker-Feature.
Der Rest-Blink ist bereits im Code dokumentiert (`redraw_soon()`/Debounce)
und laut Code-Kommentar von filetree aus nicht vollständig eliminierbar, da
Neo-tree eigene, nicht abfangbare Redraw-Zyklen fährt. Geprüft, ob ein
zusätzlicher Neo-tree-Hook existiert — gibt es nicht (keine
Debounce/Throttle-Option in Neo-trees eigenen Defaults).

**Umgesetzt:** Nichts — dokumentierte, bestätigte Grenze, kein Codeänderung.

### 3. lsp.nvim `---`-Completion — gefixt

**Befund:** Unter blink.cmp hat die `personal_names`-Completion-Quelle
keinen Keyword-Filter für Satzzeichen; `-` zählt nicht als Keyword-Zeichen,
wodurch nach `---` ein leerer Kontext entsteht und die volle ~30-Item-Liste
ungefiltert erscheint.

**Umgesetzt:** `min_keyword_length = 1` für die `personal_names`-Quelle
ergänzt — blockt den leeren Keyword-Kontext, lässt normales Tippen ab einem
Zeichen unverändert.

**Commit:** `lsp.nvim@79b5714`

### 4. + 6. Chip/`:messages`-Duplikat und Titel-Konzept — umgesetzt (siehe auch Zusatzarbeit unten)

**Befund:** `messages = true` war bereits Default (Chip UND `:messages`
liefen parallel, gewollt) — das eigentliche Problem war der zwangsläufige,
kurze Bildschirm-Flash beim Schreiben in `:messages` (Neovim hat keine API,
eine Message in die History aufzunehmen, ohne sie kurz anzuzeigen — bereits
zwei frühere Lösungsversuche waren im Code als gescheitert dokumentiert).

**Nutzerentscheidung:** Auf Rückfrage entschieden: `messages`-Default von
`true` auf `false` umgestellt — Chip bleibt, landet aber nicht mehr
automatisch in echten `:messages`; `:Lib notify history`/`:Lib notify last`
(liest weiterhin unconditional die eigene History) ist die Anlaufstelle für
den vollen Text. Pro Call/Notifier/global weiterhin mit `messages = true`
reaktivierbar. **Breaking Change** für ~30 Plugins, die `lib.nvim.notify`
nutzen.

**Titel-Konzept umgesetzt:** Ohne explizites `opts.title` wird bei einer
mehrzeiligen Message jetzt die erste Zeile zum Chip-Titel (z. B.
`"[gitsuite] docmap-desktop: push failed"` statt generisch
`"[gitsuite] error"`), der Rest wandert in den abgeschnittenen Chip-Body.

**Automatische Titel-Erkennung für rohe, native Nvim-Fehler (das
`E354`-Beispiel): technisch nicht umsetzbar.** Native `:echoerr`/
Message-Subsystem-Ausgaben laufen nie durch `vim.notify` oder irgendeinen
von Lua aus erreichbaren Hook — nur ein vollständiges `ext_messages`-UI
(das, was `noice.nvim` tatsächlich tut) könnte das abfangen, was kein
Feature-Zusatz mehr wäre, sondern im Kern ein eigenes noice.nvim
nachbauen. Bewusst nicht umgesetzt statt eine Scheinlösung zu bauen.

**Commits:** `lib.nvim@27d8251` (Default-Flip), `lib.nvim@53db016` (Titel,
erste Fassung) — siehe "Zusatzarbeit" unten für die vollständige
Nachbesserungskette.

### 5. replacer.nvim Preview-Navigation — bereits vorhanden, nur dokumentiert

**Überraschender Befund:** replacer.nvim rendert sein Picker-UI gar nicht
selbst — das dreigeteilte UI ist **fzf-lua** (Standard-Engine, da
installiert). Beide möglichen Engines (fzf-lua, Telescope) bringen die
gewünschten Features bereits nativ mit: fzf-lua `<S-Up>/<S-Down>`
(Preview seitenweise), `<M-S-Up>/<M-S-Down>` (Preview zeilenweise), `<F3>`
(Preview-Zeilenumbruch togglen — löst "lange URL abgeschnitten" eleganter
als Scrollen), `<F1>` (volles Keymap-Cheatsheet — entspricht genau dem
gewünschten Legend-Popup). Nichts davon war dokumentiert.

**Umgesetzt:** Nur Dokumentation ergänzt (`docs/BINDINGS.md`), kein
Verhalten geändert. Dabei einen Nebenbefund dokumentiert:
`keymaps.filter` (Default `<C-f>`) überschreibt auf beiden Engines eine
vorhandene Standard-Bindung.

**Commit:** `replacer.nvim@27fc1e2`

### 7. runtime-analysis.nvim 7-Tage-Reminder — bereits korrekt

**Befund:** Läuft bereits über eine `lib.nvim.notify`-Instanz (nicht rohes
`vim.notify`), gebatcht. Seit dem globalen
`require("lib.nvim.notify").setup({ popup = true })` in der nvim-Config
profitieren automatisch alle ~30 `lib.nvim.notify`-Consumer (inkl.
runtime-analysis.nvim) von Chip + `:messages`.

**Umgesetzt:** Nichts — bereits korrekt, verifiziert.

### 8. `:MyPlugins reclone` — bereits erledigt

**Befund:** Läuft bereits über `ui.kit.confirm` async statt der alten
Text-Prompt-Lösung (Migration am 23.09. abgeschlossen laut Backlog). Der
Summary-Text vor Ja/Nein zeigt bereits Anzahl, alle Repo-Namen und den
Zielordner.

**Umgesetzt:** Nichts — bereits erledigt, verifiziert.

### 9. Statusline-Progress Live-Hover + zentraler Popup — umgesetzt

**Befund:** Das zentrale Statusline-Modul existierte bereits (jedes Plugin
mit `progress_style = "statusline"` taucht automatisch auf), ebenso der
Hover-Tooltip — er zeigte aber nur den statischen `summary`-Text, nie den
echten Live-State.

**Umgesetzt:**
- `ui.statusline.catalog`-Einträge können jetzt ein optionales `live()`
  deklarieren; der Hover-Tooltip zeigt dessen Text statt der statischen
  Beschreibung, solange er nicht leer ist (`plugin_progress` an
  `lib.nvim.progress.styles.statusline` angebunden).
- Neuer Befehl `:UI progress` (Namensgebung an die bestehende
  `:UI`-Konvention angepasst statt des vorgeschlagenen `:Ui statusline
  showProgress`) zeigt dieselbe Registry als Popup, ganz ohne Hover/Maus.

**Commit:** `ui.nvim@9f1e792`

---

## Zusatzarbeit: der ultracode-Bug-Hunt (nicht ursprünglich angefragt)

Auf Wunsch wurde nach Abschluss der neun Punkte ein mehrstufiger
Multi-Agent-Review (Fund → Fix → adversariale Gegenprüfung) über alle
Code-Commits dieser Session gefahren. Ergebnis, kurz zusammengefasst:

- **Zwei echte Fokus-Diebstahl-Regressionen** gefunden und gefixt: der
  Statusline-Hover-Tooltip und die filetree.nvim-Float-Preview klauten beim
  Umbau auf `ui.kit.surface` versehentlich den Cursor-Fokus (fehlendes
  `enter = false`) — inkl. Fokus-Diebstahl mitten im Insert-Mode.
- **Eine Race Condition** im neuen Live-Refresh-Timer des Hover-Tooltips
  gefunden und gefixt (ein veralteter Timer-Tick konnte einen neueren Timer
  stoppen statt sich selbst).
- **Eine tiefe Kette rund um die neue Chip-Titel-Funktion** in `lib.nvim`
  (`derive_title`): über sechs Nachbesserungsrunden wurden nacheinander
  gefunden und gefixt — ein doppelt angehängtes Präfix bei der
  Standard-Nutzung, eine Breiten-Budget-Überschreitung bei langen/breiten
  Quellnamen, ein Zeichen-vs-Spalten-Messfehler bei asiatischen
  Schriftzeichen/Emojis, ein ungeschützter Absturz bei falschem Options-Typ,
  und eine Korruption bei kombinierenden Unicode-Zeichen (z. B. zerlegte
  Akzent-Buchstaben).
- **Zwei vorbestehende, nie von dieser Session verursachte Bugs** wurden
  dabei zusätzlich gefunden (derselbe Zeichen-vs-Spalten-Fehler in der
  Toast-**Body**-Umbruchfunktion `wrap()`, sowie ein Byte-basierter Schnitt
  mitten durch Mehrbyte-Zeichen) — bewusst **nicht** in dieselbe Kette
  gezogen, sondern als eigener Task ausgelagert und in einer separaten
  Session erledigt (siehe Commits `bb5461d`, `9d972e8`, `bc2f06a` unten —
  auch dort trat iterativ noch ein Off-by-one-Nachbesserungsfund auf).

Alle in dieser Serie gefundenen und gefixten Bugs betrafen ausschließlich
Code, der in dieser Session selbst neu geschrieben wurde (mit den zwei oben
genannten, bewusst ausgelagerten Ausnahmen) — keine bereits vorher
bestehende, produktiv genutzte Funktionalität wurde dabei rückwirkend als
kaputt entdeckt.

---

## Alle Commits dieser Session (nach Repo)

**nvim (Config)** — 11× `docs(handover|final-checks): ...` (Handover +
Live-Test-Checkliste), `docs(personal): correct the notify comment ...`

**lsp.nvim** — `fix(completion): stop personal_names flooding suggestions on bare punctuation` (`79b5714`)

**WKDBooks** — `docs(myplugins): mark the --- completion fix as implemented`

**replacer.nvim** — `docs(bindings): document the engine-native preview navigation keys` (`27fc1e2`),
`fix(regex): :ReplaceTest panel now themed via ui.kit` (`cb3c4fb`)

**ui.nvim** — `feat(statusline): live hover state for progress modules, plus :UI progress` (`9f1e792`),
`fix(statusline): hover tooltip now themed via ui.kit` (`b98a0a9`),
`feat(usrcmds): add :UI kit-preset/:UI kit-presets` (`b6343b0`),
`feat(kit): add the hacker preset` (`542383a`),
`fix(statusline): hover tooltip stole focus, merged multi-line live text, went stale` (`bc9f22a`),
`fix(statusline): live-refresh timer no longer stops a newer timer` (`5986861`)

**lib.nvim** — `feat(notify): derive the toast title from a multi-line message's first line` (`53db016`),
`feat(notify)!: popup no longer writes real :messages by default` (`27d8251`),
`docs(ui.kit): re-sync theme.lua's frozen copy comment wrapping` (`8f96c69`),
`feat(ui.kit): sync the hacker preset into the frozen copy` (`638a03a`),
`fix(notify): derive_title no longer doubles the tag or overflows the budget` (`5e1329f`),
`fix(notify): derive_title matches the exact baked-in prefix, not a guess` (`4b8128a`),
`fix(notify): derive_title truncation is now display-width-aware, not character-count-based` (`2d87f0c`),
`fix(notify): the single-line fallback title also respects the 40-column budget` (`90e3d3a`),
`fix(notify): title truncation now measures and cuts with the same vim.fn pair` (`29fdc0b`),
`fix(notify): truncate_to_width respects combining marks, derive_title never crashes on a bad type` (`db617af`),
`fix(notify): wrap() respects display width for CJK/emoji, byte caps no longer split multibyte chars` (`bb5461d`, separate Folge-Session),
`fix(notify): width_cut_chars is O(n log n) not O(n^2), utf8_safe_cut no longer discards malformed input wholesale` (`9d972e8`, separate Folge-Session),
`fix(notify): utf8_safe_cut's 3-byte backoff bound had an off-by-one, splitting well-formed 4-byte characters` (`bc2f06a`, separate Folge-Session)

**filetree.nvim** — `fix(preview): float-mode preview now themed via ui.kit` (`8dbdfd1`),
`fix(preview): float-mode preview stole focus from the tree` (`989196e`)

**sessions.nvim** — `fix(marks): preview float now themed via ui.kit when installed` (`ff0a23d`)

Alle Commits sind auf `main` in ihrem jeweiligen Repo, kein offener Branch.

---

## Live-Testen

Die konkrete, abhakbare Checkliste mit allen Punkten, die eine echte
interaktive nvim-Session brauchen (Fokus-Verhalten, Live-Refresh-Timing,
visuelles Theming), liegt in
[`docs/ROADMAP/Final_Checks/Running-Tasks_Checklist.md`](../Final_Checks/Running-Tasks_Checklist.md).
