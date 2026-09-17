# Testabdeckung aller `.nvim`-Plugins — Statusreport

> Stand: 2026-09-17. Dieser Report ist die **Übersicht**; die ausführliche Runden-Doku
> (was je Repo abgedeckt/ausgelassen wurde, gefundene Bugs, Commit-SHAs) steht im Handover
> [`../handovers/test-coverage/test-coverage-campaign.md`](../handovers/test-coverage/test-coverage-campaign.md).

## Table of content

  - [Ziel und Vorgehen](#ziel-und-vorgehen)
  - [Fortschritt](#fortschritt)
  - [Warteschlange](#warteschlange)
  - [Survey aller Repos](#survey-aller-repos)
  - [Gefundene Bugs](#gefundene-bugs)
  - [Historie: der ursprüngliche 3-Repo-Report](#historie-der-ursprngliche-3-repo-report)

---

## Ziel und Vorgehen

Jedes `.nvim`-Plugin soll idealerweise 100% Abdeckung im eigenen `TESTS/`-Ordner haben.
Ein Repo gilt als "fertig", wenn jedes Modul mit echter Logik eine Assertion-Suite hat und
jede bewusste Auslassung im jeweiligen `TESTS/README.md` **mit Begründung** dokumentiert ist.

Regeln, die sich über die Runden eingespielt haben:

- Bestehende Test-Konvention des Repos beibehalten (eigener `H.eq`/`check()`-Harness vs.
  plenary/busted vs. eigenständige `TESTS/*.lua`-Skripte) — kein Framework-Wechsel nebenbei.
- Bewusst ausgelassen: reine `@types`/`---@meta`-Dateien, deklarative Tabellen ohne
  Verzweigung, Rendering-Wrapper, die ein echtes Backend (telescope/fzf-lua/snacks) brauchen,
  und alles, was einen echten externen Prozess oder Netzwerkzugriff erfordert.
- Gefundene Bugs werden **nicht stillschweigend wegrefactored**: entweder trivialer Blocker →
  Fix mit Begründung, oder `BUG:`-Assertion als Pin plus separater Fix-Task.
- Pro Repo: `luacheck`/`stylua` mit exakt den CI-Befehlen grün, Suite real headless gelaufen,
  Commit direkt auf `main` des jeweiligen Repos.
- Immer nur **ein** Agent gleichzeitig, repo-für-repo.

## Fortschritt

**10 von 36 Repos abgeschlossen**, Runde 11 läuft.

| # | Repo | Runde | Commit | Kurzfassung |
|---:|---|---:|---|---|
| 1 | pickers.nvim | 1 | `fbaed4c` | 19 ungetestete Logikdateien ergänzt; 400 → 575 Checks |
| 2 | cmdlog.nvim | 2 | `a43edc9` | `core/*`, `config/`, `bindings/*`, Picker-Merge; 35 → 257 Checks |
| 3 | dap.nvim | 3 | `5f2da6e` | 11 Sprach-Tabellen über 2 generische Contract-Specs; 4 → 30 Specs |
| 4 | casedesk.nvim | 4 | `3cc4cd9` | 32 neue Specs; 40 → 386 Assertions |
| 5 | buffer-ctx.nvim | 5 | `6290f8b` | 6 neue Specs; 24 → 40 von 46 Dateien abgedeckt |
| 6 | debugging.nvim | 6 | `7b05563` | 10 neue Specs; ~6 → ~23 von 34 Dateien |
| 7 | recommender.nvim | 7 | `6e7fb65` | 6 neue Specs; 5 → 11 von 23 Dateien |
| 8 | language.nvim | 8 | `51dd7d1` | 21 neue Specs; ~6 → 43 von 51 Dateien |
| 9 | open.nvim | 9 | `a8dbe1d` | 9 neue Specs; ~12 → 24 von 26 Dateien |
| 10 | replacer.nvim | 10 | `053e1d6` | 5 neue Suiten + CI-Verdrahtung; 8 → 13 Dateien |
| 11 | github_stats.nvim | 11 | *läuft* | — |

Details je Runde: siehe Handover, Abschnitt "Fortschritt".

## Warteschlange

Nach github_stats.nvim in dieser Reihenfolge (🟠 vor 🟡, siehe Survey):

insights.nvim → sessions.nvim → pdfport.nvim → emojis.nvim → fileops.nvim →
reposcope.nvim → gopath.nvim → color_my_ascii.nvim → diff.nvim → cascade.nvim →
sandbox.nvim → data.nvim → spotlight.nvim → mdview.nvim → filetree.nvim → lsp.nvim

Die 🟢-Repos (`images.nvim`, `ai.nvim`, `hover.nvim`, `runtime-analysis.nvim`, `lib.nvim`,
`markdown.nvim`, `documentation.nvim`, `media.nvim`, `ui.nvim`) bekommen keine volle Runde,
außer eine konkrete Prüfung findet doch eine Lücke.

## Survey aller Repos

Lua-Quelldateien in `lua/` vs. Testdateien (grober Proxy, keine echte %-Abdeckung);
Erhebung 2026-09-15, die ✅-Zeilen sind seither abgearbeitet.

| Plugin | lua_src | lua_test | Status |
|---|---:|---:|---|
| pickers.nvim | 73 | 2 | ✅ fertig |
| cmdlog.nvim | 40 | 1 | ✅ fertig |
| dap.nvim | 41 | 5 | ✅ fertig |
| casedesk.nvim | 46 | 6 | ✅ fertig |
| buffer-ctx.nvim | 45 | 7 | ✅ fertig |
| debugging.nvim | 34 | 7 | ✅ fertig |
| recommender.nvim | 23 | 7 | ✅ fertig |
| language.nvim | 51 | 8 | ✅ fertig |
| open.nvim | 26 | 8 | ✅ fertig |
| replacer.nvim | 40 | 8 | ✅ fertig |
| github_stats.nvim | 44 | 9 | 🔄 Runde 11 läuft |
| insights.nvim | 49 | 9 | 🟠 schwach |
| sessions.nvim | 17 | 9 | 🟠 schwach |
| pdfport.nvim | 50 | 10 | 🟠 schwach |
| emojis.nvim | 23 | 11 | 🟠 schwach |
| fileops.nvim | 18 | 11 | 🟠 schwach |
| reposcope.nvim | 113 | 12 | 🟠 schwach (großes Repo) |
| gopath.nvim | 77 | 16 | 🟠 schwach |
| color_my_ascii.nvim | 95 | 17 | 🟠 schwach |
| diff.nvim | 23 | 17 | 🟡 mittel |
| cascade.nvim | 48 | 18 | 🟡 mittel |
| sandbox.nvim | 270 | 19 | 🟡 mittel (sehr großes Repo) |
| data.nvim | 16 | 20 | 🟡 mittel |
| spotlight.nvim | 27 | 19 | 🟡 mittel |
| mdview.nvim | 78 | 24 | 🟡 mittel |
| filetree.nvim | 129 | 26 | 🟡 mittel |
| lsp.nvim | 176 | 29 | 🟡 mittel (großes Repo) |
| images.nvim | 37 | 29 | 🟢 gut |
| ai.nvim | 25 | 35 | 🟢 gut |
| hover.nvim | 40 | 38 | 🟢 gut |
| runtime-analysis.nvim | 43 | 54 | 🟢 gut |
| lib.nvim | 497 | 159 | 🟢 gut (Basis-Lib) |
| markdown.nvim | 81 | 102 | 🟢 gut |
| documentation.nvim | 139 | 104 | 🟢 gut |
| media.nvim | 31 | 98 | ✅ fertig (eigene Session) |
| ui.nvim | 93 | 232 | ✅ sehr gut |

## Gefundene Bugs

Sieben echte Bugs sind über die Kampagne aufgefallen; **alle sind gefixt** — sechs davon in
je eigenem Nachzieh-Commit, der casedesk-Fix direkt in der Coverage-Runde selbst:

| Repo | Bug | Fix |
|---|---|---|
| cmdlog.nvim | `:history`'s `>`-Marker der letzten Zeile wurde vom Parser verschluckt | `240ca1d` |
| buffer-ctx.nvim | `alpha_marker()` Off-by-one (`za.`/`zb.` statt `a.`/`b.`) | `79893f9` |
| buffer-ctx.nvim | `format/text_width.lua` dupliziert Bullet-Marker beim Reflow (+ Folgefehler in `wrap_words()`) | `3c99c3c` |
| recommender.nvim | Tree-sitter-Query nutzte veraltete Knotennamen (+ `iter_matches`-Listen-Semantik) | `cc338f6` |
| debugging.nvim | `inline_debug.lua` baute den Log-Pfad ohne Trenner zusammen | `8ac567e` |
| replacer.nvim | `config.get()` gab verschachtelte Tabellen per Referenz statt Deep-Copy zurück (+ toter Debug-Code) | `7031f73` |
| casedesk.nvim | `doctor.lua`'s `x and nil or y`-Idiom ließ den Ambiguitäts-Guard nie greifen | in `3cc4cd9` |

## Historie: der ursprüngliche 3-Repo-Report

Die erste Fassung dieses Reports (2026-09-15) deckte nur `pickers.nvim`, `dap.nvim` und
`cmdlog.nvim` ab und schätzte deren Aufwand auf 24–39 Stunden. Alle drei sind inzwischen
abgeschlossen (Runden 1–3); der Aufwandsschätzer hat sich als grob passend erwiesen, die
Reihenfolge-Empfehlung (pickers → dap → cmdlog) wurde zu pickers → cmdlog → dap umsortiert,
weil cmdlogs Harness bereits existierte und nur ausgebaut werden musste.
