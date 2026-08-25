# Plugin-Sweep 2026-08 — Archiv

Abgeschlossen am 2026-08-25. Lag vorher unter `docs/ROADMAP/personal/New/`.

## Was das war

Ein Durchgang durch **31 Personal-Plugins** plus nvim-config, der drei
Audit-Dateien abgearbeitet hat: Completion-Lücken `[C]`, Count-Lücken `[N]`
und Flag-/Options-Lücken `[F]`. Quelle der Audits war ein Scan vom 2026-08-08.

| Datei | Rolle |
| --- | --- |
| [SWEEP-LEDGER.md](SWEEP-LEDGER.md) | **Einstieg.** Arbeitsprotokoll pro Plugin, mit Befunden und Commits |
| [SWEEP-PLAN.md](SWEEP-PLAN.md) | Vorgehen, Doku-Pflichten, Definition of Done |
| [RULES-audit-completion.md](RULES-audit-completion.md) | Quelle der `[C]`-Einträge |
| [RULES-audit-count.md](RULES-audit-count.md) | Quelle der `[N]`-Einträge |
| [RULES-flags-options.md](RULES-flags-options.md) | Quelle der `[F]`-Einträge |

`RULES-plugin-ideas.md` war **nicht** Teil des Sweeps und ist deshalb nicht
hier — sie ist weiter offener Backlog unter
[`docs/ROADMAP/IDEAS/RULES-plugin-ideas.md`](../../../ROADMAP/IDEAS/RULES-plugin-ideas.md).

## Phase 3 — Quickfix-Audit — ERLEDIGT 2026-08-25

Direkt im Anschluss abgearbeitet. Ergebnis: **ein** echter Fund von vier
Kandidaten. Die Prämisse des Ledgers („replacer.nvim hat als einziges Plugin
bereits einen Quickfix-Export") war falsch.

| Plugin | Befund |
| --- | --- |
| `replacer.nvim` | Referenz bestätigt — `to_qf_entries` + `send_to_quickfix`, Flags `--to-quickfix`/`--to-loclist` |
| `documentation.nvim` | **Kein Kandidat, längst erledigt** — 13 Quickfix-Exporte, einheitliche `docmap <ding>`-Titel. Das quickfix-reichste Plugin überhaupt |
| `markdown.nvim` | **Echter Fund, behoben** — s. unten |
| `pickers.nvim` | **n/a** — die Engines besitzen das |

### markdown.nvim — der Fund war schlimmer als „fehlt"

`:Markdown links check` veröffentlichte Diagnosen und riet „see
`vim.diagnostic.open_float()` / `:lopen`". Die zweite Hälfte war **nie wahr**:
`vim.diagnostic.set` füllt die Location-List nicht, der Rat lief in
`E776: No location list`. Gegen den Vorzustand gemessen, nicht vermutet.

`check()` spiegelt die Funde jetzt in die Quickfix-Liste, die Meldung nennt
`:copen`. Quickfix statt Location-List, weil `refs.check` **im selben Plugin**
diesen Präzedenzfall für eine ebenso buffer-lokale Prüfung schon gesetzt hat —
zwei Geschwister-`check`-Subkommandos in verschiedenen Listen wären die
seltsamere Wahl. Beide Listen, nicht eine: die Diagnosen tragen die
Inline-Darstellung, die Quickfix-Liste macht die Funde mit `:cnext` begehbar.

Commit `0cf146f`, Branch `feat/link-check-quickfix-export`, Suite grün.

### pickers.nvim — warum n/a

pickers.nvim ist ein dünner Dispatcher über telescope/fzf-lua/snacks und
besitzt die Picker-UI nicht. Send-to-Quickfix ist **native Engine-Funktion**,
und die Defaults bleiben erhalten: `result_count.attach_mappings` gibt `true`
zurück, was in telescope „Default-Mappings behalten" heißt.

Der Zusatz „inkl. Marks" hat sogar seine **eigene** Taste — in telescope
gemessen: `<C-q>` = `send_to_qflist`, `<M-q>` = `send_selected_to_qflist`
(genau der Marks-Fall), `ctrl-q` ebenso in fzf-lua. Ein eigener Export in
pickers.nvim müsste den Selektionszustand dreier Engines nachbauen, um etwas
zu liefern, das es dort bereits differenzierter gibt.

## Was noch offen ist

Nichts aus diesem Sweep. Bewusst außerhalb geblieben:

- **`learn-cli.nvim`** — per Entscheidung ausgelassen.
- **Zwei Pre-existing-Failures**, als eigene Tasks abgelegt statt im
  Vorbeigehen gepatcht: `documentation.nvim`s vier rote Specs (davon
  `diagnostics` mit Bug-Verdacht) und der 8.3-Pfad-Fall in
  `images.nvim`/`mdview`.

## Warum das Archiv trotzdem lesenswert ist

Die zentrale Erkenntnis steht im Ledger und gilt über diesen Sweep hinaus:
**ein Audit altert schneller als der Code.** Mindestens zwölf Einträge waren
bei der Bearbeitung längst erledigt, gegenstandslos oder in der Prämisse
falsch — in einem Fall (`reposcope.nvim`s `nav_up`/`nav_down`) hätte blindes
Umsetzen eine Regression eingebaut, weil ein zweiter Count-Wrapper `3<Down>`
auf neun Zeilen geschickt hätte.

Daraus die Regel, die jede Welle bestätigt hat: **vor dem Bauen messen** — zur
Laufzeit, nicht durch Codelesen.

Was der Sweep nebenbei in `lib.nvim` gehoben hat (`lib.nvim.count`,
`lib.nvim.git.refs`, composer-Argtyp `WINDOW`, `FlagSpec.optional_value` und
zwei composer-Bugfixes), steht im Ledger unter „lib.nvim-Zuwachs".
