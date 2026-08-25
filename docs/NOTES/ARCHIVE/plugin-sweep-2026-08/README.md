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

## Was noch offen ist

Nichts aus diesem Sweep. Bewusst außerhalb geblieben:

- **Quickfix-Audit (Phase 3)** — im Ledger als `[QF]` markiert. Kandidaten:
  markdown.nvim, pickers.nvim, documentation.nvim. `replacer.nvim` hat als
  einziges Plugin bereits einen Quickfix-Export (`export.lua`) und dient als
  Referenz.
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
