# Hand-off tasks for the open roadmap items

**Date:** 2026-09-17
**Companion to:** [`Roadmap-Aufwand-Nutzen.md`](./Roadmap-Aufwand-Nutzen.md)
**What this is:** one paste-ready prompt per open item, each carrying its own
paths, quotes and rules so it can be dropped into a fresh chat with no context.

The prompts are **German** because that is the language they get pasted into;
the surrounding text is English like every other document here.

---

## Table of content

  - [Read this before pasting anything](#read-this-before-pasting-anything)
  - [A. High benefit, one session or less](#a-high-benefit-one-session-or-less)
    - [~~A1 — casedesk: redaction gate before any AI attachment~~ — DONE](#a1-casedesk-redaction-gate-before-any-ai-attachment-done)
    - [~~A2 — media: SRT/VTT serialisers~~ — DONE](#a2-media-srtvtt-serialisers-done)
    - [~~A3 — media: progress handle during a transcription run~~ — DONE](#a3-media-progress-handle-during-a-transcription-run-done)
    - [A4 — casedesk: `:Case timeline` reports git pulls as work sessions](#a4-casedesk-case-timeline-reports-git-pulls-as-work-sessions)
    - [A5 — mdview: hand-test `any_file` in real Neovim](#a5-mdview-hand-test-any_file-in-real-neovim)
    - [~~A6 — my.nvim: the breadcrumb `container` provider is a no-op~~ — DONE](#a6-mynvim-the-breadcrumb-container-provider-is-a-no-op-done)
    - [~~A7 — media: prefetch hint for frame stepping~~ — DONE](#a7-media-prefetch-hint-for-frame-stepping-done)
  - [B. A real sitting](#b-a-real-sitting)
    - [~~B1 — media: the hub dashboard~~ — DONE](#b1-media-the-hub-dashboard-done)
    - [~~B2 — media: first real whisper.cpp run~~ — DONE](#b2-media-first-real-whispercpp-run-done)
    - [~~B3 — filetree: `TESTS/refs/` is 52 of 54~~ — DONE](#b3-filetree-testsrefs-is-52-of-54-done)
    - [~~B4 — lsp: provoke errors in `:LspDoctor deep`~~ — DONE](#b4-lsp-provoke-errors-in-lspdoctor-deep-done)
    - [B7 — lib.nvim: the autocmd dispatcher](#b7-libnvim-the-autocmd-dispatcher)
    - [~~B9 — mdview: cooperative tab closing in `default` browser mode~~ — REJECTED](#b9-mdview-cooperative-tab-closing-in-default-browser-mode)
  - [C. Cheap, low stakes — collected per plugin](#c-cheap-low-stakes-collected-per-plugin)
  - [Not in this file, on purpose](#not-in-this-file-on-purpose)

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
| `lib.nvim` `deps.health` migration | Both consumers already use it: `open.nvim/health.lua:216`, `pdfport.nvim/health.lua:435` (`pointer_for`). **But only the entry's own wording was done** — five plugins still check binaries by hand (`ai`, `debugging`, `emojis`, `fileops`, `sandbox`) and none of them declares an `install.json`, so `deps.health` does not apply to them yet. Recorded as a separate open question, not migrated |
| `gopath.nvim` frecency consolidation | `alternate/frecency.lua:43` calls `require("lib.nvim.frecency").store` — the local file is the saturation curve on top, not a second implementation |

All five are now struck from their roadmaps and recorded in each plugin's
`FEATURES.md` — except `filetree.nvim`, deliberately held back while a parallel
session still has uncommitted work there.

So this file is a snapshot with a short half-life, and the fleet is worked on
from several directions at once. **A task that turns out to be done is not a
failure of the task — it is the expected case often enough to plan for it.**
Every prompt therefore opens with the same instruction: check first, report
back, and if it is done, strike it and write the `FEATURES.md` entry instead.

---

## A. High benefit, one session or less

### ~~A1 — casedesk: redaction gate before any AI attachment~~ — DONE

**Source:** `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/casedesk.nvim/ROADMAP/ROADMAP.md`,
section "Privacy and AI", second bullet.
**Built 2026-09-18** (`casedesk.nvim`, new `lua/casedesk/redaction.lua` +
rewritten `ui/ki.lua`'s `M.ki`, `TESTS/redaction_spec.lua`, 16 cases). Struck
from the roadmap, recorded in `casedesk.nvim/FEATURES.md`.

**A real finding on the way in:** `ki.lua` never attached any file at all —
`:Case ki` only builds a text prompt for the clipboard. The actual leak path
was `ocr.render`'s `{screenshots}` block, which puts `:Case ocr`'s
recognized text straight into that prompt regardless of whether the source
screenshot was ever redacted. That's the thing this gate had to guard, not
a binary attachment.

**Changed from the prompt's own instruction, on request mid-build:** a
CONFIRMATION gate instead of the refusal asked for below — a case worker
sometimes has to hand over exactly the unredacted detail, and a hard
refusal would just push that detail into the AI chat by hand, outside
casedesk entirely. One combined `kit.confirm` per `:Case ki` call lists
every affected screenshot by name, not one dialog per file. A source image
with a *current* redacted copy (`images.convert.redact`'s own
`shot.png` -> `shot.redacted.png` naming, read off its real source, not
guessed) has its own unredacted OCR text dropped unconditionally — the
gap a naive "does a redacted copy exist" check would have left open, since
both the original's and the redacted copy's sidecars can exist at once.
Log files stay uncovered on purpose: no path sends raw log content to an
AI yet ("Log analysis" is its own, unbuilt roadmap item in the same
section). Full writeup: `casedesk.nvim/FEATURES.md`, "Redaction gate for
attachments, 2026-09-18". The prompt below is kept for the record.

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

### ~~A2 — media: SRT/VTT serialisers~~ — DONE

**Source:** `.../media.nvim/ROADMAP/ROADMAP.md`, section "Transcription", item 3.
**Built 2026-09-17** (`media.nvim@f6a2ca8`): `output/srt.lua`, `output/vtt.lua`,
`core.segments.cues`, `:Media transcribe out=srt|vtt`, two new specs. Struck
from the roadmap, recorded in `media.nvim/FEATURES.md`. A silent fall-through
was fixed on the way — any mode that was not `sidecar` used to open a buffer,
so `out=str` honoured a typo after minutes of transcription. The prompt below
is kept for the record.

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

### ~~A3 — media: progress handle during a transcription run~~ — DONE

**Source:** same roadmap, "Also not built" paragraph.
**Built 2026-09-17** (`media.nvim@feeb08a`): `opts.on_phase` on the dispatcher,
the `lib.nvim.progress` handle in `bindings/usrcmds.lua`, `progress_style` in
the config, a health line. The open question was answered as **phase text plus
an elapsed clock, no percentage** — whisper.cpp reports none of its own and a
figure from the audio duration would be calibrated to one machine. The larger
find: `:Media transcribe` was **not cancellable at all** — `transcribe()` has
returned a cancel handle since it was written and the command dropped it. It
now has one (`progress_style = "float"`, `<Esc>`). The prompt below is kept for
the record.

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

### ~~A6 — my.nvim: the breadcrumb `container` provider is a no-op~~ — DONE

**Source:** `.../my.nvim/ROADMAP/ROADMAP.md`, section "Parked, no ticket yet".
**Resolved 2026-09-17** (`my.nvim@fdeacd4`, `WKDBooks@3627ccd`): route (b),
retired rather than deferred, because the evidence the entry asked for came
back against (a).

The no-op was real. Two things the entry did not know: it also *leaked* —
`_ctx_with_container` wrote `_base_symbol` onto the table `C.get_cfg()` hands
back, the live config rather than a copy, and never cleared it, so after one
`:My hl debug` the winbar reported a frozen symbol until restart. And the
answer to "what does the provider actually produce": measured against a real
Lua tree at four cursor positions, **its own input, unchanged, all four times**
— `ts_symbol` already yields the qualified name for Lua (`M.run()`,
`Klass:method()`), so `container.extract()` hits its own "base already starts
with the container" guard every time. No case contributes a segment, so (a) had
nothing to wire up.

Delivered: `container` out of the shipped and fallback `providers_order`, the
probe on a copy, five assertions in `TESTS/breadcrumbs_ctx_container_spec.lua`
(two fail against the old code), docs and both `@types` updated.

Two larger defects surfaced underneath, were parked, and **were then fixed the
same day** (`my.nvim@c622695`, `lib.nvim@91e7532` and `@34925b4`).

`node_at_cursor` resolved through `nvim-treesitter.ts_utils`, which that
plugin's `main` branch removed — so **no Tree-sitter node reached any
breadcrumb provider in a live session**. Together with the dead `lsp_func` the
cross-feature check found, the winbar had been running on `<cword>` alone, with
no error anywhere to say so. It uses core's `vim.treesitter.get_node()` now.
Underneath that, `lib.nvim`'s `memo.fn` threw on userdata keys and would have
broken the same path the moment the first fix landed; its key builder takes
every type now, and the node helpers are not memoized at all any more, because
a cache keyed on a TSNode keys on its *address* — which Tree-sitter recycles
across a reparse.

`memo.fn` also rejects unknown options instead of ignoring them (`weak` was
accepted in silence by ten call sites and could never have worked), and that
check immediately exposed a third defect: `time.diff`'s memoized stats
calculator misspelled both of its options, so it threw on first call for as
long as it had existed — uncalled, and therefore unnoticed.

`TESTS/breadcrumbs_ctx_treesitter_spec.lua` (8 assertions against a real parsed
tree) and `lib.nvim`'s new `TESTS/memo_spec.lua` cover it; recorded in both
plugins' `FEATURES.md`. The prompt below is kept for the record.

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

### ~~A7 — media: prefetch hint for frame stepping~~ — DONE

**Source:** `.../media.nvim/ROADMAP/ROADMAP.md`, section "Frame stepping".
**Built 2026-09-17** (`media.nvim@c72d8ba`, `hover.nvim@d47107e`): the
ten-line estimate held — `cache.ensure` already joins an in-flight render, so
`prefetch` is `frame` with nobody listening. The step cursor stays in
hover.nvim as the entry demanded. The prompt below is kept for the record.

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

### ~~B1 — media: the hub dashboard~~ — DONE

**Source:** `.../media.nvim/ROADMAP/ROADMAP.md`, section "The hub".
**Built 2026-09-17** in the four stages this prompt asked for
(`media.nvim@37db33b`, `@d80026f`, `@8c08f06`, `@a2ebcb3`):
`hub/{kinds,scan,dashboard,actions}.lua`, `integrations/menu.lua`,
`docs/install.json`, `:Media dashboard` and `:Media text`. Struck from the
roadmap, written up in `media.nvim/FEATURES.md`.

The warning in this prompt was right and did not go far enough: `ui.kit` is not
only a moved require path, it is also **not** the "multi-select + preview"
picker the roadmap describes — one selection, no preview, no `<Tab>`. The
dashboard is a scratch float with its own keymaps instead. Two more places the
section had gone stale, two defects found by running it rather than reading it,
and four things deliberately not built are all in `FEATURES.md`. The prompt
below is kept for the record.

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

### ~~B2 — media: first real whisper.cpp run~~ — DONE

~~**Blocked:** needs a whisper.cpp binary and a GGML model on the machine.~~
**Unblocked and done 2026-09-17** (`media.nvim@a2adf38`), against a real build
and `ggml-base.en.bin` on `samples/jfk.wav`.

Both questions answered. The **JSON shape was right** — transcribed from
whisper.cpp's source, never observed, and the real `-oj` output matches
exactly; the fixture needed no change. **`-np` does not suppress everything**,
and the sharper finding is that `whisper-cli` **exits 0 on some failures**: a
file it cannot decode returns code 0, writes no JSON, and reports the reason
only on stderr. Reading `result.code ~= 0` was never a sufficient test.

And the reason this task existed: **caching a real transcription crashed, and
always had.** `vim.system`'s `on_exit` is a fast event context, the dispatcher
computed a cache key there through `vim.fn.sha256`, and every consumer callback
after it ran in a context the plugin had promised they would not. It survived
all of phase 0 because the pipeline was verified against a *fake* engine — and
"which execution context does the callback arrive in" is exactly what a fake
cannot reproduce. Written up in `media.nvim/FEATURES.md`. The prompt below is
kept for the record.

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

### ~~B3 — filetree: `TESTS/refs/` is 52 of 54~~ — DONE

**Source:** `.../filetree.nvim/ROADMAP/ROADMAP.md`, section "Known issues" —
its only entry, so the section went with it.

**Already fixed on 2026-08-27** (`filetree.nvim@41395fc`), three weeks before
this entry was read. Verified by running the suite at `85b2561`, the last
commit before the session that picked this up: 96 passed, 0 failed, with both
`nested/deep/c.lua` checks green by name.

The entry's premise was the bug. It said the two files hold the byte-identical
`require("proj.util.shared")`; they do not. The spec expects the
parenthesis-less `require "proj.util.shared"` in `c.lua` (mirroring how
`c.tsx` covers the deepest ts import), while the fixture used the
parenthesised form. So "updated" searched for a string that could never
appear, and "old reference gone" passed vacuously — two failures, one per
rename shape. Not the apply layer, and the `to_absolute` lead is gone too
(`fnamemodify(":p")` collapses the `\.\` segment; the `C:\repos\…` paths in
the entry predate this machine's `E:\repos` layout).

**What did need doing:** a spec/fixture mismatch produced one failure that
reads like an engine bug plus a passing partner that hid it. `TESTS/refs/run.lua`
now asserts up front that every fixture really contains what its spec expects
to be rewritten, so the same drift names its own cause. Recorded in
`filetree.nvim/FEATURES.md`; refs 148 passed, 0 failed.

---

### ~~B4 — lsp: provoke errors in `:LspDoctor deep`~~ — DONE

**Source:** `.../lsp.nvim/ROADMAP/ROADMAP.md`, section "From
`MyPlugin-Notes/LSPDoctor/`", the last open checkbox there.
**Built 2026-09-17** (`lsp.nvim@60ba2c6`): `TESTS/lsp/probe_live_spec.lua`,
plus a CI step that installs a server for it. Struck from the roadmap — with
the whole section, which carried nothing else — and recorded in
`lsp.nvim/FEATURES.md`.

Half of the task turned out to be already built: `:LspDoctor probe` exists
(`lspdoctor/probe.lua`, 20 filetype snippets, all syntax errors so they hold in
an unindexed directory), and `lspdoctor_spec.lua` covered it — against fakes
that stub `get_clients`, `buf_attach_client`, `get_namespace` and
`vim.diagnostic.get`, i.e. every link the report exists to verify. So the open
part was the live gate, and the finding is that the existing spec looked like
coverage of exactly the thing it could not cover.

The skip trap the prompt warned about is worse than it reads: plenary prints
`Pending` and still tallies the case under `Success`. So the gate names every
candidate and what was missing about each, writes that to stderr as well, and
**fails instead of skipping under `CI`**, where the workflow now installs
`typescript-language-server`. Candidates were measured, not assumed — lua_ls
~0.8s, ts_ls ~1.1s, gopls ~15s cold, `jsonls` tried and dropped because it
publishes nothing unless the client answers `workspace/configuration`. Side
finding, found by running it: `vim.fn.exepath("typescript-language-server")`
returns npm's extension-less shim on Windows and spawning it fails with "not
installed, missing from PATH, or not executable" — about a server that is
installed and on PATH. Both failure paths were provoked, not reasoned about.

The prompt below is kept for the record.

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

### ~~B9 — mdview: cooperative tab closing in `default` browser mode~~ — REJECTED

**Source:** `.../mdview.nvim/ROADMAP/ROADMAP.md`, section "Cooperative tab
closing in the `default` browser mode".
**Investigated 2026-09-18, not built.** The question this prompt asked for
first has a clear answer: a script may only `window.close()` a tab it did not
open itself (no `window.opener`, always true for mdview's OS-level
`open_default`) if that tab's session history never left entry 1 (MDN). mdview's
own `src/client/render/history.ts` calls `history.pushState()` on every
switch to a different previewed document, which is exactly what happens on
**every ordinary buffer switch** under `browser.behavior = "reuse"` — the
default follow mode. So the tab becomes permanently script-unclosable the
moment a second file is previewed in it, silently (a browser console warning,
not an error mdview can see) — reliable only for a tab that never switches
documents (`new_tab`/`manual`, or `reuse` without a switch). That is not the
primary workflow `browser_autoclose`/`stop_on_browser_exit` exist for. A
best-effort, no-regression variant (always attempt `window.close()`, harmless
no-op when refused) was considered and explicitly declined — flaky,
session-pattern-dependent close behavior wasn't judged worth shipping over
documenting the limit. Full writeup, including the caveat on why a
CDP-automated browser test result was not trusted for this verdict, in
`mdview.nvim/ROADMAP/ROADMAP.md`. The prompt below is kept for the record.

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

## C. Cheap, low stakes — collected per plugin

**Built 2026-09-18, all four bundles — a fleet-wide bug/security/performance
re-check is running now before this is called closed.** Sequential, one
repo at a time.

| Bundle | Built | Commits |
|---|---|---|
| my.nvim (3 points) | Persisted overrides (opt-in, `stdpath("data")` JSON), guicursor presets (`block_only`/`classic_vim`/`mode_coloured`, modelled on `set_diff_profile`), `:My hl why` (explains exactly why the current buffer is skipped) | `my.nvim@3f8be49`, `c2f33ef`, `e253494` |
| media.nvim (3 points) | All three were already done — in `hover.nvim`/`images.nvim`, the same evening the roadmap note was written. No media.nvim code change needed; the note itself was just never struck. | — (doc-only) |
| lsp.nvim (2 points) | Hover cache was already built (record only, nothing to build); keymap-collision check added to `:checkhealth lsp` via `lib.nvim.bindings.keymap.conflicts()` | `lsp.nvim@49b4dfa` |
| casedesk.nvim (2 points) | `routed_to` sidecar field replaces the dual filename/Status-section routing marker, with `:Cases doctor` migration findings for legacy cases; `ui.lua` (3,922 lines) split into 24 topical modules under `ui/`, verified as a pure move (line-for-line, generated command tree byte-identical) | `casedesk.nvim@718404f`, `2d49c2d` |

luacheck/stylua/full test suites green throughout; docs and each plugin's
`FEATURES.md` updated; no Claude co-authorship. One defect found and
deliberately **not** fixed in the same commit (out of this bundle's scope):
casedesk.nvim's `:Case info` edit-and-save handler silently dropped every
sidecar field its form doesn't manage (`outcome`, `routed_to`,
`sap_component`, …) — reported, then fixed separately
(`casedesk.nvim@f2cf86e`). This same session's diffopt/gitsigns move
(F1/F2, `ui-my-Kreuzfeature-Analyse.md`) is covered by the same re-check,
not tracked here since it never had its own entry in this file.

**Not struck as DONE yet, on purpose:** an independent adversarial
bug/security/performance pass over every commit in this bundle plus F1/F2
is running as this line is written — three lenses per commit, findings
verified by three independent skeptics before being trusted. This entry
gets its final status (and any follow-up fixes) once that lands.

The prompts below are kept for the record.

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

---

