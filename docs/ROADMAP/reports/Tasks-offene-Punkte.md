# Hand-off tasks for the open roadmap items

**Date:** 2026-09-17
**Companion to:** [`Roadmap-Aufwand-Nutzen.md`](Roadmap-Aufwand-Nutzen.md)
**What this is:** one paste-ready prompt per open item, each carrying its own
paths, quotes and rules so it can be dropped into a fresh chat with no context.

The prompts are **German** because that is the language they get pasted into;
the surrounding text is English like every other document here.

---

## Read this before pasting anything

**Every prompt below carries a `Stand geprüft` line, and every prompt tells the
next session to re-verify it first.** That is not ceremony. Between the
cost/benefit review being written and these tasks being drafted — hours, not
days — **five items had already been built**, four of them by parallel
sessions:

| Item | Where it actually is now |
|---|---|
| `filetree.nvim` `get_node_at_line` | Built for neo-tree and nvim-tree, verified live against a real tree (19 checks). Its `FEATURES.md` entry also corrects the roadmap: **four** features were unlocked, not five — `filter`'s dim fallback never reaches its gate on those two adapters |
| `casedesk.nvim` anonymisation | `lua/casedesk/anonymize.lua` + `:Case anonymize`, with `TESTS/anonymize_spec.lua` |
| `casedesk.nvim` tests for the pure functions | The suite went from 5 specs to **40**, including `normalize_spec.lua` — the case-number guard with the real incident behind it |
| `lib.nvim` `deps.health` migration | Both consumers already use it: `open.nvim/health.lua:216`, `pdfport.nvim/health.lua:435` (`pointer_for`) |
| `gopath.nvim` frecency consolidation | `alternate/frecency.lua:43` calls `require("lib.nvim.frecency").store` — the local file is the saturation curve on top, not a second implementation |

So this file is a snapshot with a short half-life, and the fleet is worked on
from several directions at once. **A task that turns out to be done is not a
failure of the task — it is the expected case often enough to plan for it.**
Every prompt therefore opens with the same instruction: check first, report
back, and if it is done, strike it and write the `FEATURES.md` entry instead.

---

## A. High benefit, one session or less

### A1 — casedesk: redaction gate before any AI attachment

**Source:** `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/ROADMAP/ROADMAP.md`,
section "Privacy and AI", second bullet.
**Stand geprüft 2026-09-17:** open — `grep redact lua/casedesk/ki.lua` is empty.

```
Aufgabe: casedesk.nvim — Redaction-Gate, bevor ein Attachment an eine AI geht.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Privacy and AI", Punkt "Redaction gate for
attachments". Wortlaut dort: Screenshots und Logs dürfen eine AI nicht
ungeschwärzt erreichen; `:Image redact` in images.nvim macht die Schwärzung
bereits — was fehlt, ist die Regel in ki.lua, die eine Datei ohne
geschwärztes Gegenstück gar nicht erst anhängt.

Prüfe ZUERST, ob das noch offen ist (Stand 2026-09-17: ja, in
E:/repos/casedesk.nvim/lua/casedesk/ki.lua kommt "redact" nicht vor) und
sag mir Bescheid, falls es inzwischen gebaut wurde — dann streich stattdessen
den Roadmap-Punkt und trag den Ablieferungsnachweis in
casedesk.nvim/FEATURES.md ein (Muster: die FEATURES.md-Dateien der anderen
Plugins im selben Ordner).

Kern der Aufgabe: Das Gate ist eine VERWEIGERUNG, kein Hinweis. ki.lua darf
eine Datei nicht anhängen, für die kein geschwärztes Gegenstück existiert.
Überlege dabei:
- Woran erkennt man das Gegenstück? images.nvim's :Image redact schreibt
  wohin? (nachsehen, nicht raten)
- Was passiert bei Dateitypen, die gar nicht schwärzbar sind (z.B. .log)?
  Eine Textdatei hat keine Bildschwärzung — braucht sie einen eigenen Pfad
  oder eine bewusste Ausnahme? Das ist eine Entscheidung, bring sie mir.
- Was ist der Stale-Fall: Quelle neuer als das geschwärzte Gegenstück.
  casedesk hat dieses Muster schon in case/ocr.is_stale — nachbauen statt
  neu erfinden.

Es geht um echte Kundendaten (Namen, Kontakte, Firmennamen in Screenshots
und Logs). Im Zweifel verweigern, nicht durchlassen.

Repo: E:/repos/casedesk.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen. Roadmap-Punkt entfernen und
Ablieferungsnachweis in casedesk.nvim/FEATURES.md eintragen.
```

---

### A2 — media: SRT/VTT serialisers

**Source:** `.../media.nvim/ROADMAP/ROADMAP.md`, section "Transcription", item 3.
**Stand geprüft 2026-09-17:** open — `lua/media/output/` holds only
`init.lua` and `sidecar.lua`.

```
Aufgabe: media.nvim — Segments zu SRT und VTT serialisieren
(Transkriptions-Phase 1).

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/media.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Transcription — the other half this plugin was
named for", Punkt 3. Wortlaut: "Segments → SRT/VTT. Still open — phase 1. Das
Datenmodell (Media.Segment/Media.Transcript) ist gebaut und jede Engine muss
es ohnehin produzieren; nur die Serialisierer fehlen."

Prüfe ZUERST, ob das noch gilt (Stand 2026-09-17: ja,
E:/repos/media.nvim/lua/media/output/ enthält nur init.lua und sidecar.lua).
Falls inzwischen gebaut: Roadmap-Punkt streichen, Ablieferungsnachweis in
media.nvim/FEATURES.md (Muster: die FEATURES.md der anderen Plugins) — und
mir Bescheid geben.

Datenmodell (steht in der Roadmap, gegen den echten Quelltext gegenprüfen):
  Media.Segment   = { s: number, e: number, text: string }   -- Sekunden
  Media.Transcript= { engine, model, lang, duration, segments, text }

Aufgabe: output/srt.lua und output/vtt.lua, eingehängt in output/init.lua,
erreichbar über --out=srt|vtt (die Option ist in der Roadmap schon
spezifiziert, prüfe was davon schon verdrahtet ist).

Worauf zu achten ist:
- Zeitformat: SRT nutzt Komma als Dezimaltrenner (00:00:01,500), WebVTT den
  Punkt (00:00:01.500). Das ist der klassische Fehler.
- WebVTT braucht den "WEBVTT"-Header, SRT eine 1-basierte laufende Nummer.
- Segmente ohne Text, und Segmente mit e <= s: entscheiden, ob überspringen
  oder durchreichen — und die Entscheidung kommentieren.
- Mehrzeiliger Segmenttext: beide Formate erlauben Zeilenumbrüche im Cue,
  aber eine Leerzeile beendet den Cue. Text mit "\n\n" muss also behandelt
  werden.
- Tests gegen ein Fixture, nicht nur "Funktion läuft".

Repo: E:/repos/media.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---

### A3 — media: progress handle during a transcription run

**Source:** same roadmap, "Also not built" paragraph.
**Stand geprüft 2026-09-17:** open — no `progress` reference in
`lua/media/core/dispatcher.lua`.

```
Aufgabe: media.nvim — lib.nvim.progress-Handle während eines
Transkriptionslaufs.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/media.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Transcription", Absatz "Also not built".
Wortlaut: kein lib.nvim.progress-Handle während eines Laufs — ein
":Media transcribe" sagt einmal "transcribing…" und wartet dann.

Der Punkt ist nicht Kosmetik: dieselbe Roadmap nennt Progress im eigenen
Design-Abschnitt ausdrücklich "non-negotiable", weil eine Stunde Audio
Minuten Arbeit ist — und ist dann ohne ausgeliefert worden.

Prüfe ZUERST, ob das noch gilt (Stand 2026-09-17: ja, "progress" kommt in
E:/repos/media.nvim/lua/media/core/dispatcher.lua nicht vor). Falls
inzwischen gebaut: Roadmap-Punkt streichen, Ablieferungsnachweis in
media.nvim/FEATURES.md.

Vorlage im Haus: replacer.nvim nutzt lib.nvim.progress bereits mit
progress_style notify/statusline/fidget/float — dort abschauen, nicht neu
erfinden. language.nvim's translate.files hat den Batch-Fall mit EINEM
Handle über mehrere Dateien, den media's Hub später auch braucht.

Zu klären und mir zu berichten: whisper.cpp meldet von sich aus keinen
Fortschritt in Prozent. Also entweder unbestimmter Progress (Spinner) oder
eine Schätzung aus der bekannten Audiodauer. Sag mir, was du vorschlägst,
bevor du die Schätzung baust — eine falsche Prozentzahl ist schlimmer als
gar keine.

Repo: E:/repos/media.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---

### A4 — casedesk: `:Case timeline` reports git pulls as work sessions

**Source:** `.../casedesk.nvim/ROADMAP/ROADMAP.md`, section "Workflow", fourth bullet.
**Stand geprüft 2026-09-17:** open — `timeline.lua` still derives sessions
from mtimes (11 `mtime` references).

```
Aufgabe: casedesk.nvim — entscheiden, was ":Case timeline" mit
Git-Pull-Sessions macht. Das Feature liefert derzeit messbar falsche Zahlen.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Workflow", Punkt ":Case timeline reports git
pulls as work sessions". Der Punkt ist gemessen, nicht vermutet: timeline.lua
rekonstruiert Sessions rein aus Datei-mtimes unter dem Case-Ordner, aber der
Korpus ist ein mit einer zweiten Maschine synchronisierter git-Working-Tree —
und git stempelt jede Datei, die es schreibt. Die Timeline zeigt also die
Pull-Historie:

  case 1135620: 1 session   2026-09-02 20:17 → 2026-09-02 20:17   7 files
  case 988483:  2 sessions  2026-08-19 14:48 → …  /  2026-09-02 20:17 → …

Das sind exakt die git-reflog-Einträge, und jede Session kollabiert auf Dauer
null, weil ein Pull alle Dateien in derselben Sekunde schreibt.

Prüfe ZUERST, ob das noch gilt (Stand 2026-09-17: ja, mtime-basiert).

Das ist ausdrücklich eine ENTSCHEIDUNG, kein Bau-Auftrag. Die Roadmap wiegt
drei Optionen gegeneinander ab, lies sie dort im Original:
  a) Feature fallenlassen — auf einem synchronisierten Korpus nicht tragfähig
  b) behalten, aber eine Session, deren Dateien alle dieselbe Sekunde
     tragen, als "nicht messbar" labeln
  c) Dauern künftig im Usage-Journal mitschreiben und nur zeigen, was es
     abdeckt (kann die Vergangenheit nicht rekonstruieren, startet leer)

Bring mir eine Empfehlung mit Begründung, BEVOR du etwas baust.

Mitbetroffen und im selben Zug anzusehen: detect.last_touched ruht auf
denselben mtimes und verdient denselben Blick.

Repo: E:/repos/casedesk.nvim (lua/casedesk/timeline.lua, 79 Zeilen)
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---

### A5 — mdview: hand-test `any_file` in real Neovim

**Source:** `.../mdview.nvim/ROADMAP/ROADMAP.md`, first section.
**Stand geprüft 2026-09-17:** open — the entry's own status line still says
"not yet tested in real Neovim".

```
Aufgabe: mdview.nvim — das any_file-Feature einmal von Hand im echten Neovim
durchtesten.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/mdview.nvim/
ROADMAP/ROADMAP.md, erster Abschnitt ("any_file — preview for non-markdown
files"). Status dort: implementiert am 2026-08-24, aber NICHT im echten
Neovim getestet.

Was bereits verifiziert ist (nicht nochmal machen): das Lua-Test-Harness
(55 Tests inkl. previewable_spec.lua), das Client-vitest (95 Tests), und ein
manueller Browser-Check über das Relay im standalone --watch-Modus.
Was fehlt: der echte Pfad durch Neovim.

Achtung, die Roadmap nennt das Flag inzwischen korrekt, aber falls dir
irgendwo "experimental.any_file" begegnet: das Flag ist am 2026-08-30 auf
Top-Level gezogen (any_file). config.merge liest die alte Schreibweise noch,
DEFAULTS trägt sie nicht mehr.

Die Testliste steht im Roadmap-Punkt und ist abzuarbeiten:
- Eine .lua/.py-Datei öffnen, :MDView start — rendert sie im Browser-Tab
  syntaxgehighlightet?
- Scroll-Sync (soll proportional sein, keine exakte Zeilenmarkierung)
- :MDViewBreadcrumbs auf einer .py/.sh mit #-Kommentaren — es dürfen KEINE
  Fake-Headings gesammelt werden
- Buffer, die ausgeschlossen sein sollen (terminal, :help, quickfix, mdviews
  eigener Log-Buffer) — bleiben sie ignoriert?
- any_file = false (der Default) — verhält es sich exakt wie vorher?

Berichte mir pro Punkt, was du tatsächlich gesehen hast. Ein "sollte
funktionieren" ist hier wertlos — der ganze Sinn dieses Tasks ist, dass
genau dieser Pfad nie unter einem echten Neovim lief.

Repo: E:/repos/mdview.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits.
Gefundene Bugs fixen, committen, direkt auf main pushen. Wenn alles grün ist:
Roadmap-Punkt streichen und Ablieferungsnachweis in mdview.nvim/FEATURES.md
(Muster: die FEATURES.md der anderen Plugins im selben Ordner).
```

---

### A6 — my.nvim: the breadcrumb `container` provider is a no-op

**Source:** `.../my.nvim/ROADMAP/ROADMAP.md`, section "Parked, no ticket yet".
**Stand geprüft 2026-09-17:** open — and the source says so itself, at
`hl_config/breadcrumbs/ctx/init.lua:156` ("CDX (parked)").

```
Aufgabe: my.nvim — den "container"-Breadcrumb-Provider entweder verdrahten
oder aus der Default-Reihenfolge nehmen.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/my.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Parked, no ticket yet", zweiter Punkt.

Das ist ein echter Defekt, kein Feature: die Provider-Kette in
E:/repos/my.nvim/lua/my/hl_config/breadcrumbs/ctx/init.lua enthält
"container" in providers_order (Zeile ~153), aber nichts setzt
cfg._base_symbol, bevor die Kette läuft. container.extract() feuert deshalb
nie — außer im Debug-Pfad M._ctx_with_container (Zeile 88), der ihm ein
base_symbol von Hand füttert. Der Quelltext trägt den Befund bereits als
Kommentar bei Zeile 156 ("CDX (parked)").

Prüfe ZUERST, ob das noch gilt (Stand 2026-09-17: ja).

Zwei Wege, und ich will deine Empfehlung BEVOR du baust:
  a) Eine echte Base-Symbol-Quelle in die Kette verdrahten — dann ist zu
     klären, woher das base_symbol im Live-Pfad kommt und ob der Provider
     dann überhaupt liefert, was er soll.
  b) "container" aus providers_order entfernen, bis es eine Quelle gibt —
     billig und ehrlich, kostet aber ein Feature, das auf dem Papier steht.

Sag mir auch, was der Provider im Debug-Pfad tatsächlich produziert — das
ist die einzige Evidenz, ob (a) sich überhaupt lohnt.

Repo: E:/repos/my.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen. Roadmap-Punkt entfernen und
Ablieferungsnachweis in my.nvim/FEATURES.md eintragen.
```

---

### A7 — media: prefetch hint for frame stepping

**Source:** `.../media.nvim/ROADMAP/ROADMAP.md`, section "Frame stepping".
**Stand geprüft 2026-09-17:** listed as open; roughly ten lines by the
entry's own estimate.

```
Aufgabe: media.nvim — Prefetch-Hinweis beim Frame-Stepping.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/media.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Frame stepping — a poster frame you can
scrub", Absatz "Still open here". Wortlaut: ein Prefetch-Hinweis, damit beim
Vorwärts-Steppen bereits t + step gerendert wird, während der Leser t
ansieht. Geschätzt "roughly ten lines".

Wichtig — der Punkt nennt seine eigene Vorlage: der PLAYBACK-Pfad macht genau
das bereits für seine eigenen Fenster (die Roadmap beschreibt es im Abschnitt
"Block-graphics playback": das Transport fragt das nächste Fenster eine
Sekunde bevor es es braucht an, weil ein Decode plus Sampling mit ~0,6 s
gemessen wurde). Der Still-Stepping-Pfad hat das nie bekommen. Also: dort
abschauen, eine Ebene tiefer anwenden.

Der Zustand liegt bewusst NICHT in media.nvim, sondern beim Konsumenten —
hover.nvim's preview.playback steppt über video.at + (n-1) * video.step. Der
Grund steht im Roadmap-Punkt und ist beizubehalten: ein Fenster gehört dem,
der es besitzt, und zwei Konsumenten, die dieselbe Datei steppen, dürfen
sich keinen Cursor teilen. Der Prefetch-Hinweis muss diese Trennung
respektieren — media.nvim bietet an, hover.nvim entscheidet.

Prüfe zuerst, ob es noch offen ist, und ob die ~10-Zeilen-Schätzung nach
Lektüre des echten Codes noch trägt. Falls nicht: sag es mir, statt still
etwas Größeres zu bauen.

Repos: E:/repos/media.nvim und ggf. E:/repos/hover.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---

## B. A real sitting

### B1 — media: the hub dashboard

**Source:** `.../media.nvim/ROADMAP/ROADMAP.md`, section "The hub".
**Effort:** 3–4 sessions. The largest single open block in the collection.

```
Aufgabe: media.nvim — das Hub-Dashboard bauen (":Media", ":Media text").

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/media.nvim/
ROADMAP/ROADMAP.md, Abschnitt "The hub — one dashboard across image / pdf /
audio / video". Der Punkt ist ungewöhnlich vollständig spezifiziert: Modul-
Layout, Zeilenformat, Scope-Vokabular, Aktionstabelle pro Art, und die
Risiken. Lies ihn ganz, bevor du anfängst — und halte dich daran, statt neu
zu entwerfen.

Das ist der Grund, warum das Plugin "media" heißt und nicht "transcribe":
ein Dashboard, das Bilder, PDFs und Videos nebeneinander listet, darf alle
drei kennen — aber keines der drei darf gezwungen sein, die anderen zwei zu
kennen. media.nvim ist die eine Stelle, die sich per pcall zu allen
durchhangeln darf. Jede Abhängigkeit bleibt weich: ein fehlendes images.nvim
entfernt OCR-Zeilen, statt das Dashboard zu brechen.

Der kernagnostische Verb ist der eigentliche Punkt:
  :Media text [path]  -- Bild → images.ocr.run, PDF → pdfport.extract,
                         Audio/Video → der eigene Dispatcher, sonst notify

Nicht neu erfinden, die Roadmap nennt die Vorlagen beim Namen:
- Scope-Vokabular (cfile/cwd/path=<dir>): dasselbe, das images.browse.roots()
  und language.scope schon benutzen — drei Wörter, drei Bedeutungen, über
  alle Plugins gleich.
- Discovery: die Form von images.browse.walk(root, exclude, exts) —
  iteratives fs_scandir, Ausschluss-Set, Eintrags-Obergrenze, kein Abstieg
  in node_modules.
- Stale-Erkennung: wie case/ocr.is_stale (Sidecar-mtime gegen Quell-mtime).
  "stale" muss ein eigener Zustand neben "missing" bleiben — es ist der, der
  still falsche Antworten produziert.
- UI: ui.kit.picker (Multi-Select + Preview), snacks.picker wenn installiert,
  dieselbe weiche Erkennung wie images.browse. Dazu integrations/menu.lua
  für das RightMouse-Menü über lib.nvim.contextmenu.

Achtung: ui.kit ist seit 2026-09-14 nach ui.nvim umgezogen (require("ui.kit"),
nicht mehr lib.nvim.ui.kit) — die Roadmap ist an dieser Stelle älter als der
Umzug. Prüfe den echten Require-Pfad, bevor du ihn schreibst.

Arbeite in Etappen und berichte nach jeder: erst hub/kinds + hub/scan, dann
":Media text", dann das Dashboard, dann die Aktionen. Nicht alles auf einmal.

Repo: E:/repos/media.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Nach
jeder Etappe committen und direkt auf main pushen.
```

---

### B2 — media: first real whisper.cpp run

**Blocked:** needs a whisper.cpp binary and a GGML model on the machine.

```
Aufgabe: media.nvim — den Transkriptionspfad zum ersten Mal gegen ein echtes
whisper.cpp laufen lassen.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/media.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Transcription", Punkt 2. Dort steht ehrlich,
was NICHT verifiziert ist: es gab beim Bauen weder Binary noch GGML-Modell
auf der Maschine.

Verifiziert ist (nicht nochmal machen): die WAV-Extraktion gegen echtes
ffmpeg (16 kHz mono pcm_s16le, durch Probing der Ausgabe geprüft), und die
volle Dispatcher-Pipeline (probe → normalize → resolve → cache → Sidecar)
gegen eine Fake-Engine.

Was diese Aufgabe klären muss — die Roadmap benennt es punktgenau:
1. Die JSON-Form. engines/whisper_cpp.lua's from_json ist gegen ein
   handgeschriebenes Dokument unit-getestet, dessen Form aus whisper.cpps
   Quelltext ABGESCHRIEBEN und nicht beobachtet ist. Lauf "whisper-cli -oj"
   einmal echt und vergleiche.
2. Ob "-np" tatsächlich alles unterdrückt, was sonst über stderr/stdout
   käme. Aktuell wird für den Fehlerpfad nur result.code ~= 0 gelesen —
   wenn -np nicht alles schluckt, ist das zu wenig.

Vorbedingung: whisper.cpp und ein GGML-Modell müssen auf der Maschine sein.
Modelle sind gigabytegroß — lade NICHTS automatisch herunter. Sag mir, was
gebraucht wird, und lass mich die Installation bestätigen. Das ist auch die
Regel der Roadmap ("never fetch one automatically").

Es gibt einen fertigen Live-Testplan, arbeite ihn ab statt einen neuen zu
schreiben: nvim/docs/ROADMAP/reports/media/live-testing-plan.md, Abschnitt 9
ist genau dieser Fall.

Repo: E:/repos/media.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Kein Claude-Co-Author in Commits. Gefundene Abweichungen fixen,
committen, direkt auf main pushen — und mir berichten, was die echte
JSON-Ausgabe anders macht als das Fixture.
```

---

### B3 — filetree: `TESTS/refs/` is 52 of 54

**Stand geprüft 2026-09-17:** open. Note that a parallel session has just
finished `get_node_at_line` in this repo — coordinate before starting.

```
Aufgabe: filetree.nvim — die zwei fehlschlagenden refs-Tests (52 von 54)
reparieren.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/filetree.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Known issues".

Der Befund, wörtlich: Ein Rename aktualisiert lua/proj/nested/b.lua, aber
nicht lua/proj/nested/deep/c.lua eine Ebene tiefer — obwohl beide Dateien
das byte-identische require("proj.util.shared") enthalten. Der einfache
Rename und der Verzeichnis-Kaskaden-Fall scheitern jeweils an genau dieser
einen Datei.

Was es NICHT ist (steht so in der Roadmap, damit es niemand nochmal prüft):
- keine Regression — identisch vor und nach der Cross-Platform-Runde vom
  2026-08-25
- nicht das Scan-Backend — identisch mit ripgrep und mit dem libuv-Fallback,
  und rg selbst listet nested/deep/c.lua, wenn man es von Hand mit denselben
  Argumenten aufruft
- nicht die Kandidatenmenge — die Kandidaten kommen an

Der Defekt sitzt also im Apply-Layer, unterhalb von refs/scan.lua.

Eine konkrete Spur, von der aus zu starten ist: für einen ripgrep-relativen
Treffer liefert filetree.util.path.to_absolute
  C:\repos\…\.\lua\proj\nested\deep\c.lua
— Backslashes beibehalten und ein wörtliches "\.\"-Segment mitten drin. Wenn
irgendwas weiter unten auf diesem String dedupliziert oder matcht, ist ein
unnormalisierter Pfad die erste Stelle zum Nachsehen.
(E:/repos/filetree.nvim/lua/filetree/util/path.lua, 284 Zeilen)

WICHTIG: An diesem Repo hat gerade eine parallele Session gearbeitet
(get_node_at_line für neo-tree/nvim-tree). Prüfe erst git status und git log,
und arbeite nicht gegen uncommittete Änderungen.

Repo: E:/repos/filetree.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen. Roadmap-Punkt entfernen und
Ablieferungsnachweis in filetree.nvim/FEATURES.md eintragen.
```

---

### B4 — lsp: provoke errors in `:LspDoctor deep`

```
Aufgabe: lsp.nvim — Fehler provozieren als Test, in ":LspDoctor deep" bzw.
in der Test-Suite.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/lsp.nvim/
ROADMAP/ROADMAP.md, Abschnitt "From MyPlugin-Notes/LSPDoctor/", Punkt
"Provoking errors as a testing aid". Es ist die einzige verbliebene offene
Checkbox in diesem Abschnitt.

Wortlaut: einen Scratch-Buffer mit garantiert fehlerhaftem Inhalt erzeugen
(Go: fehlende Klammer, JS: "const x =") und prüfen, ob innerhalb eines
Timeouts Diagnosen ankommen. Das unterscheidet "keine Fehler" von
"Diagnosen kommen überhaupt nicht an" — genau der Fall, der sonst Stunden
kostet.

Warum das wertvoll ist: es ist der einzige Check im Plugin, der die KETTE
Ende-zu-Ende verifiziert, statt Zustände abzufragen. Alles andere in
lspdoctor fragt, ob etwas installiert/konfiguriert/attached ist.

Zu beachten:
- Der Test darf nicht rot werden, weil auf dieser Maschine gerade kein
  gopls/ts_ls installiert ist. Unterscheide "Server fehlt" (skip, mit
  klarer Meldung) von "Server da, Diagnosen kommen nicht" (fail). Die
  Roadmap von documentation.nvim hat zu genau dieser Falle einen teuren
  Lehrsatz: ein Gate, das sich still selbst überspringt und trotzdem als
  grün zählt, ist schlimmer als keins. Die Meldung muss sagen, WAS fehlt.
- Timeout großzügig, aber endlich. Ein hängender Test ist schlimmer als ein
  fehlschlagender.
- Der Scratch-Buffer braucht einen echten Dateinamen/filetype, damit
  überhaupt ein Client attached.

Repo: E:/repos/lsp.nvim (lua/lsp/lspdoctor/, TESTS/lsp/)
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen. Roadmap-Punkt entfernen und
Ablieferungsnachweis in lsp.nvim/FEATURES.md eintragen (die Datei existiert
schon, Muster übernehmen).
```

---

### B5 — `rules.nvim` pass over ui.nvim

**Evidence for the value:** the same pass over `my.nvim` on 2026-09-15 found
a shell-injection-shaped clipboard call, missing `pcall`s around external
processes, an unthrottled rebuild on a hot path, and about a dozen more.

```
Aufgabe: rules.nvim über ui.nvim laufen lassen.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/ui.nvim/
NOTES.md, Abschnitt "Offene Punkte (Backlog)", Punkt 2. Dort steht auch die
Reihenfolge-Begründung: my.nvim zuerst (länger in Benutzung, stärker
durchgetestet) — das ist am 2026-09-15 passiert, also ist ui.nvim jetzt dran.

Was der Durchgang über my.nvim gefunden hat, als Maßstab dafür, dass das
keine Formalie ist: einen shell-injection-förmigen Clipboard-Aufruf (SEC),
fehlende pcalls um externe Prozesse (ERR), tote doc-only @types-Klassen, die
still in eine echte hineingemerged sind (CMT), ein Nerd-Font-Glyph ohne
have_nerd_font-Prüfung (UI), einen camelCase-Ausreißer, ein kaputtes
vim.g-Rezept im README, ein eager require eines lazy geladenen Fremdplugins
(LUA), mehrere LuaLS-Annotationsbugs (LLS), ein ungedrosseltes
build_matchers() auf einem heißen Pfad (PERF), fehlende checkhealth-Abdeckung
einer weichen Abhängigkeit (REL), und .stylua.toml → stylua.toml (NEW-45).

Vorgehen: alle Families, sowohl die automatischen Checks als auch die
manuellen/Urteils-Regeln. rules.nvim liegt in E:/repos/rules.nvim, die
Regelsammlung im Checklists-Baum.

Berichte mir die Funde, BEVOR du sie fixt — ich will entscheiden, was davon
gefixt wird und was ein bewusster Waiver ist (rules.nvim hat dafür
.rules-waivers.json).

Repo: E:/repos/ui.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen, und den Punkt in ui.nvim/
NOTES.md abhaken bzw. nach ui.nvim/FEATURES.md überführen.
```

---

### B6 — data.nvim: phase 1 register scope

```
Aufgabe: data.nvim — Phase 1 fertigstellen (Register-Scope und Ziel-Flags).

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/data.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Phase 1 — Register-Scope". Der filter-Teil
ist erledigt; offen sind laut Punkt:

- --reg=<name>: Inhalt aus einem Register lesen (Default +/") statt aus dem
  Buffer, Ergebnis in einen neuen Scratch-Split (lib.nvim.window /
  buf_win_tab) statt in den Buffer zu schreiben.
- --inplace/--split/--reg=<name> als Ziel-Flags. Der Default hängt vom Scope
  ab: Buffer/Selektion → inplace, Register → split.
- Danach ggf. nachziehen: diff.nvim-Vorher/Nachher für einen filter-Lauf,
  bevor er in-place ersetzt. Hing an filter, das jetzt gebaut ist.

Stand geprüft 2026-09-17: "--reg" kommt im Quelltext nur als Ankündigung vor
(lua/data/scope/resolve.lua:12 nennt es als Phase 1) — also noch offen.
Prüfe das nochmal, bevor du anfängst.

Beachte die zwei bewussten Abweichungen, die beim filter-Bau getroffen
wurden und die auch hier gelten (stehen im Roadmap-Punkt): keine
Objekt-Rekonstruktion/unflatten, und pickers.nvim ist Hard-Requirement für
filter statt eines eigenen Fallback-UIs.

Repo: E:/repos/data.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen. Roadmap-Punkt entfernen und
Ablieferungsnachweis in data.nvim/FEATURES.md eintragen (Muster: die
FEATURES.md der anderen Plugins im selben Ordner).
```

---

### B7 — lib.nvim: the autocmd dispatcher

```
Aufgabe: lib.nvim — den autocmd-dispatcher bauen (ein Autocmd, viele
Handler).

Konzeptdokument: E:/repos/WKDBooks/Development/wkdbook-myplugins/lib.nvim/
ROADMAP/autocmd-dispatcher.md, verlinkt aus ROADMAP/ROADMAP.md unter "Open
concepts (not implemented)".

Das Konzept ist bereits gegen die Realität geprüft — 17 echte
FileType-Registrierungen über die Flotte — und die Empfehlung lautet: bauen,
generisch über das Event. Zwei Fixes sind beim Lesen des Config-Prototyps
schon gefunden und stehen im Dokument:
  1. Sortieren bei der Registrierung, nicht bei jedem Feuern
  2. eine eigene ID pro Registrierung statt tostring(handler.load) für "once"

Lies das Dokument ganz, bevor du anfängst, und halte dich an seine
Empfehlung statt neu zu entwerfen.

Danach zu klären und mir zu berichten: wer wird der erste echte Konsument?
Ein generischer Dispatcher ohne Umstellung eines echten Call-Sites ist
unbewiesener Code. Die 17 gefundenen Registrierungen sind die Kandidaten —
schlag mir eine oder zwei vor, an denen sich der Nutzen zeigen lässt.

Repo: E:/repos/lib.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen — lib.nvim-Module haben eine eigene
README je Modul, das ist Hausstil. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen, und das Konzeptdokument aus
der "Open concepts"-Liste in lib.nvim/ROADMAP/ROADMAP.md herausnehmen.
```

---

### B8 — hover.nvim: the demo GIF

**Now unblocked:** `ui.nvim` shipped a screenkey HUD
(`lua/ui/screenkey/init.lua`) — the tool this recording wants.

```
Aufgabe: hover.nvim — das Demo-GIF aufnehmen (REL-09).

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/hover.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Features > A demo GIF". Es ist das letzte
offene 🟢 im Release-Gate.

Wortlaut dort: Das README trägt ein ASCII-Mockup des Floats, das die IDEE
erklärt, aber nicht das GEFÜHL — und genau das ist das Zeigenswerte: wie
wenig der Hover beim Lesen unterbricht. Ein Standbild kann das nicht.

Neu, und der Grund, warum das jetzt dran ist: ui.nvim hat inzwischen ein
Screenkey-HUD (E:/repos/ui.nvim/lua/ui/screenkey/init.lua, Route in
bindings/usrcmds). Das ist genau das Werkzeug für so eine Aufnahme —
eingeblendete Tastendrücke, damit der Betrachter sieht, was ausgelöst hat,
was er sieht. Es ist per Default aus, muss also bewusst eingeschaltet werden.

Stand geprüft 2026-09-17: E:/repos/hover.nvim/docs/assets/ ist leer.

Zu beachten:
- Das GIF gehört ins Repo und wird damit dauerhaft mitgeschleppt —
  Dateigröße im Blick behalten. Andere Plugins der Flotte haben PNGs unter
  docs/assets/ (z.B. cmdlog.nvim/docs/assets/Cmdlog-Picker-UI.png), das ist
  das Vorbild für Ort und Benennung.
- Keine echten Kundendaten, keine privaten Pfade im Bild.
- Zeig die Sache, um die es geht: den Hover im Lesefluss, nicht eine
  Feature-Parade.

Repo: E:/repos/hover.nvim
Regeln: Antworte auf Deutsch. Kein Claude-Co-Author in Commits. README
mitpflegen (das ASCII-Mockup kann bleiben oder weichen — sag mir, was du
vorschlägst). Wenn fertig: committen und direkt auf main pushen, den
Roadmap-Punkt entfernen und den Ablieferungsnachweis in hover.nvim/
FEATURES.md eintragen (Datei neu anlegen, Muster: die FEATURES.md der
anderen Plugins im selben Ordner).
```

---

### B9 — mdview: cooperative tab closing in `default` browser mode

```
Aufgabe: mdview.nvim — kooperatives Tab-Schließen im browser.mode="default".

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/mdview.nvim/
ROADMAP/ROADMAP.md, Abschnitt "Cooperative tab closing in the default
browser mode". Status dort: offen, mittlerer Aufwand.

Das Problem: in browser.mode = "default" öffnet mdview die URL im normalen
Browser des Nutzers (dessen Extensions, dessen Profil). Der Preis: mdview
kann den Tab nicht programmatisch schließen, also sind browser_autoclose und
stop_on_browser_exit dort stille No-Ops.

Der vorgeschlagene Weg steht im Punkt: kooperatives Schließen — der Client
reagiert auf ein WebSocket-"close"-Event mit window.close(). Auto-Close
würde dann auch im default-Modus funktionieren, ohne ein isoliertes Profil
zu erzwingen.

Zu prüfen, bevor du baust: window.close() darf in modernen Browsern nur ein
Tab schließen, den das Skript selbst geöffnet hat. Ob das hier greift, hängt
davon ab, wie der Tab entstanden ist — das ist die entscheidende Frage
dieses Tasks. Finde es heraus und sag es mir, bevor du die Mechanik baust.
Wenn es nicht geht, ist das ein legitimes Ergebnis und gehört als
Begründung in den Roadmap-Punkt, statt dass der offen weiterliegt.

Repo: E:/repos/mdview.nvim (Client: src/client/, Lua: lua/mdview/)
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün, und die Client-Tests (vitest) ebenso. Docs/README mitpflegen.
Kein Claude-Co-Author in Commits. Wenn fertig: committen und direkt auf main
pushen.
```

---

### B10 — documentation.nvim: the shim that behaves differently

```
Aufgabe: documentation.nvim — den verbliebenen blinden Fleck des
standalone-Gates schließen.

Roadmap-Punkt: E:/repos/WKDBooks/Development/wkdbook-myplugins/
documentation.nvim/ROADMAP/ROADMAP.md, Abschnitt "The one open finding worth
knowing about", letzter Absatz.

Zwei Hälften sind bereits gefixt (nicht nochmal machen):
- TESTS/shim_contract_spec.lua fängt seit 2026-08-20, was STATISCH sichtbar
  ist — jeder vim.*-Pfad und jeder Methodenname, den core/ aufruft, gegen
  das, was der Shim implementiert.
- Die Schlusszeile lügt nicht mehr: sie sagt "4 gates passed, 1 skipped:
  standalone" statt "All 5 gates passed", plus der Satz, der es erklärt: ein
  übersprungenes Gate hat nichts geprüft. Die Meldung nennt jetzt auch den
  Interpreter, das fehlende Rock und die Installationszeile.

Was offen bleibt, wörtlich: "a shim function that EXISTS and BEHAVES
DIFFERENTLY is invisible to a static contract."

Das ist die eigentliche Aufgabe, und sie ist zuerst eine Denkaufgabe:
Wie prüft man Verhaltensgleichheit zwischen dem Neovim-Original und dem
PUC-Lua-Shim, ohne den Shim zu einer zweiten Implementierung mit eigenen
Tests aufzublähen? Bring mir einen Vorschlag mit Aufwand, BEVOR du baust.
Denkbare Richtungen (nicht als Vorgabe, als Startpunkt): dieselben Eingaben
durch beide Seiten schicken und die Ausgaben vergleichen; oder die paar
Funktionen identifizieren, wo Abweichung überhaupt plausibel ist, und nur
die gegenprüfen.

Kontext, der die Dringlichkeit erklärt: genau hinter diesem Gate sind schon
drei echte Defekte in ein Release gerutscht, weil "grün" lokal "vier Gates
und ein Achselzucken" hieß.

Repo: E:/repos/documentation.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Wenn
fertig: committen und direkt auf main pushen.
```

---

### B11 — ui.nvim + my.nvim: cross-feature check against the sibling plugins

**Explicitly one pass for both**, per both roadmaps — not two spot-checks.

```
Aufgabe: Kreuzfeature-Check von ui.nvim und my.nvim gegen die ~30
Schwesterplugins — ein Durchgang für beide, mit schriftlichem Report.

Roadmap-Punkte (derselbe Punkt, in beiden Dateien):
- E:/repos/WKDBooks/Development/wkdbook-myplugins/my.nvim/ROADMAP/ROADMAP.md,
  Abschnitt "Cross-plugin checks", Punkt "Cross-feature check against sibling
  plugins"
- E:/repos/WKDBooks/Development/wkdbook-myplugins/ui.nvim/NOTES.md,
  Abschnitt "Offene Punkte (Backlog)", Punkt 3

Beide sagen ausdrücklich dasselbe: EIN eigener Analyse-Durchgang mit
schriftlichem Report für beide Plugins zusammen, nicht zwei Stichproben
unterwegs.

Frage: Gibt es Überlappung oder sinnvoll teilbare Funktionalität zwischen
ui.nvim/my.nvim und den übrigen Plugins unter E:/repos? Die Arbeitsteilung
der beiden ist dabei die Leitlinie: my.nvim malt INNERHALB des Fensters
(Cursorline, Mode-Tinting, Indent-Guides, Breadcrumbs-Inhalt), ui.nvim ist
der RAHMEN (Statusline, Tabline, Theme). Das steht in beiden Roadmaps als
Scope-Grenze und ist der Maßstab, an dem ein Overlap-Befund zu messen ist.

Es gibt eine Vorlage für Form und Tiefe, halte dich daran:
nvim/docs/ROADMAP/reports/Externe-Plugins-Nachbau-Analyse.md — Methode,
was NICHT geprüft wurde, Zahlen, dann die Befunde mit Aufwand in
Arbeits-Sessions.

WICHTIG, aus einer teuren Lektion derselben Flotte: Verlass dich nicht auf
die Beschreibung eines Features, sondern lies den echten Quelltext. Eine
Analyse vom 2026-09-17 hat 15 Roadmap-Punkte gefunden, die als offen
gelistet, aber längst gebaut waren. Jeder Overlap-Befund braucht die Datei,
die ihn belegt.

Report ablegen unter: C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/reports/
Regeln: Antworte auf Deutsch, Report auf Englisch (wie die Nachbarreports
dort). Kein Claude-Co-Author in Commits. Wenn fertig: committen und direkt
auf main pushen, und den Punkt in BEIDEN Roadmaps abhaken.
```

---

## C. Cheap, low stakes — collected per plugin

These are one-sitting bundles rather than one task each; each bullet is small
enough that splitting it into its own prompt would cost more than the work.

```
Aufgabe: my.nvim — drei kleine offene Punkte aus der Roadmap abarbeiten.

Roadmap: E:/repos/WKDBooks/Development/wkdbook-myplugins/my.nvim/ROADMAP/
ROADMAP.md. Prüfe bei JEDEM Punkt zuerst am Quelltext, ob er noch offen ist
— in dieser Flotte sind Roadmap-Punkte wiederholt still veraltet.

1. Persisted overrides (Abschnitt "Configuration"): ":My hl set" ist
   runtime-only, ein jetzt gesetzter Wert ist nach dem Neustart weg. Ein
   Opt-in-Write in eine kleine Datei unter stdpath("data"), bei setup()
   wieder eingelesen. Die Roadmap nennt den Grund, warum das jetzt billig
   ist: modified(ns) ist exakt die Schlüsselmenge, die so eine Datei halten
   muss — die teure Hälfte existiert also schon.
2. guicursor-Presets (Abschnitt "Configuration"): options_config bildet
   guicursor auf eigene Highlight-Gruppen ab und hat einen Fallback.
   Benannte Presets ("block only", "classic vim", "mode-coloured") wären
   ein Ein-Kommando-Umschalter für einen heute handgeschriebenen
   Options-String. Vorbild im selben Plugin: ":My hl profile" ist genau
   dieses Muster und ist schon gebaut — dort abschauen.
3. ":My hl why" (Abschnitt "Highlights"): ":checkhealth my" sagt, WAS
   übersprungen wird, kann aber nicht sagen, warum GENAU DIESER Buffer
   übersprungen wird — buftype, filetype oder ein Namensmuster, und welches
   davon. Ein ":My hl why" gegen den aktuellen Buffer würde es sagen.

Repo: E:/repos/my.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Pro
Punkt ein Commit, direkt auf main pushen. Erledigte Punkte aus der Roadmap
entfernen und in my.nvim/FEATURES.md eintragen.
```

```
Aufgabe: media.nvim — drei kleine Darstellungs-Punkte aus der Roadmap.

Roadmap: E:/repos/WKDBooks/Development/wkdbook-myplugins/media.nvim/ROADMAP/
ROADMAP.md, Abschnitt "Block-graphics playback", Absatz "Still open". Prüfe
jeden Punkt zuerst am Quelltext gegen.

1. Auflösung an den Float binden statt an eine feste Pixelbreite: heute wird
   der Lauf mit fester Pixelbreite dekodiert und erst beim Sampling auf
   Zellen gefittet. Sinnvoll wäre max_width minus Rahmen.
2. "levels" pro Material: 16 Stufen reichen für Video; ein Standbild könnte
   mehr vertragen, solange die Decke hält. Die Decke ist real und der Grund,
   warum es levels überhaupt gibt — nvim_set_hl hat ein hartes Limit, das
   ein Truecolor-Zellraster in sieben verrauschten Frames erreicht. Nicht
   anheben, ohne nachzurechnen.
3. Ein größerer Default-Float für die spielende Ansicht. "+"/"-" skalieren
   ihn bereits.

Repo: E:/repos/media.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Pro
Punkt ein Commit, direkt auf main pushen.
```

```
Aufgabe: lsp.nvim — zwei kleine offene Punkte aus der §14-Tabelle.

Roadmap: E:/repos/WKDBooks/Development/wkdbook-myplugins/lsp.nvim/ROADMAP/
ROADMAP.md, Abschnitt "14. Roadmap: new features". Die Tabelle hat seit dem
2026-09-17 nur noch offene Zeilen; acht erledigte sind nach lsp.nvim/
FEATURES.md gewandert. Prüfe trotzdem jeden Punkt am Quelltext gegen.

1. Hover-Cache via lib.lua.memo: wiederholter Hover auf derselben
   Position/Version spart einen Roundtrip. Klein.
2. Keymap-Kollisionscheck in ":checkhealth lsp": halb erledigt.
   keymaps_spec.lua prüft zur BAUZEIT, dass keine zwei Katalogeinträge
   dieselbe Taste im selben Modus beanspruchen — dort kostet ein Fehler
   nichts. Offen ist die LAUFZEIT-Frage, die nur :checkhealth sehen kann:
   kollidiert der Katalog mit einer Taste, die DU oder ein anderes Plugin
   gesetzt hat?

Nicht anfassen (steht als "nur beobachten" in derselben Tabelle): das
Signature-Hilfe-Modul schrumpfen. Es ist von ~800 auf 1.322 LOC gewachsen
und niemand meldet ein Problem damit.

Repo: E:/repos/lsp.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Pro
Punkt ein Commit, direkt auf main pushen. Erledigte Zeilen aus §14 entfernen
und in lsp.nvim/FEATURES.md eintragen.
```

```
Aufgabe: casedesk.nvim — zwei mittelgroße Struktur-/Workflow-Punkte.

Roadmap: E:/repos/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/
ROADMAP/ROADMAP.md. Prüfe jeden Punkt zuerst am Quelltext gegen — in diesem
Repo wurde zuletzt viel gebaut (u.a. anonymize.lua und ~35 neue Specs).

1. "One routing-status system" (Abschnitt "Workflow"): Fälle, die an eine
   andere Abteilung gegangen sind, sind heute DOPPELT markiert — per
   Dateiname (Solution_PAC.md, Solution_PSO.md) UND per "## Status"-
   Abschnitt. Ziel: ein Feld, eine aufgezählte Wertemenge, und ":Cases" kann
   darauf filtern. "Alles, was je an PAC ging" wird damit eine Abfrage statt
   einer Erinnerung.
2. "Split ui.lua" (Abschnitt "Structure"): 3.840 Zeilen, ein Drittel des
   Plugins, und das Modul, in das alle anderen hineinrufen. Die Roadmap
   sagt ausdrücklich, warum es nicht Teil des Extraktions-Commits war: ein
   Move soll als Move überprüfbar bleiben. Also: reiner Move, keine
   Verhaltensänderung nebenbei — und wenn dir beim Verschieben ein Bug
   auffällt, melde ihn, statt ihn im selben Commit mitzufixen.

Repo: E:/repos/casedesk.nvim
Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. luacheck und
stylua grün. Docs/README mitpflegen. Kein Claude-Co-Author in Commits. Pro
Punkt ein Commit, direkt auf main pushen. Erledigte Punkte aus der Roadmap
entfernen und in casedesk.nvim/FEATURES.md eintragen.
```

---

## Not in this file, on purpose

- **The fifteen struck items** from the review's §3 — they are built, and
  recorded in each plugin's `FEATURES.md`.
- **The five found built while drafting this file** (table at the top).
- **Everything in the review's §7 "Do not do these"**: the gopath Treesitter
  migration (a week, for patterns that were chosen deliberately), shrinking
  the lsp signature module, the mdview PDF hover, `area` in `.case.json`, a
  terminal implementation of ui.nvim's own, and the skipped `lib.nvim` shim
  from the ui-kit migration.
- **`open.nvim`'s non-Windows reveal verification** — understood, but it
  needs a Linux or macOS host this fleet does not have.
- **The `docmap-desktop` queue** that `documentation.nvim` and
  `runtime-analysis.nvim` both defer to — it lives outside this collection.
