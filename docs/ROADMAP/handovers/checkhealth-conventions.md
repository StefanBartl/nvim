# Handover — Checkhealth-Konventionen über alle Plugins

## Table of content

  - [Intro](#intro)
  - [Validierung 2026-09-06](#validierung-2026-09-06)
  - [Reihenfolge (nach Hebelwirkung)](#reihenfolge-nach-hebelwirkung)
  - [Was pro Repo zu tun ist](#was-pro-repo-zu-tun-ist)
  - [Was noch offen ist](#was-noch-offen-ist)
  - [Nebenfund](#nebenfund)

---

## Intro

**Stand: 2026-09-06. Schritte 1-5, 7, 8 fertig. Schritt 6 (ADVICE) läuft
gerade über den kompletten Plugin-Bestand (User-Entscheidung: alle ~20
weiteren Repos, nicht nur die neun aus Schritt 1-5).**

## ADVICE-Vollaudit, Fortschritt

Repo für Repo, direkt in der Hauptkonversation (kein Agent-Einsatz).
Fertig: casedesk.nvim `b1a55ec`, cmdlog.nvim `a0fb129`, color_my_ascii.nvim
`47592ec`, dap.nvim `dd3ddc0`, debugging.nvim `57e98c9`, diff.nvim `33ceed5`,
documentation.nvim (bereits vorbildlich, keine Änderung nötig), emojis.nvim
`83e5b09`, github_stats.nvim `6f37933`.

Noch offen: gopath, hover, images, insights, language, lsp, markdown,
mdview, recommender, replacer, reposcope, runtime-analysis, sandbox,
spotlight.

**Nebenfund während des Audits — eigene Background-Task angelegt
(`task_c18f86fd`):** `lib.nvim`s geteilter `check_require()`-Helfer
(`lua/lib/nvim/health/init.lua:33`) kann strukturell nie `error` melden,
nur `warn` oder `info` — `debugging.nvim:28` meldet damit seine harte
`lib.nvim.bindings.usercmd.composer`-Abhängigkeit nur als `warn`, obwohl
jedes andere Plugin in diesem Durchgang dieselbe Abhängigkeit als `error`
meldet. Nicht selbst gefixt, weil das eine Signaturänderung am geteilten
Helfer bräuchte (betrifft dap.nvim und debugging.nvim). Wird gerade
zusätzlich direkt bearbeitet (User-Anweisung).

Quelle der Analyse: [`docs/ROADMAP/personal/All/FINISH/checkhealt_conventions.md`](../personal/All/FINISH/checkhealt_conventions.md)
(2026-08-31). Regel in einem Satz: *Muss der Nutzer etwas tun? Nein → niemals
`warn`.*

---

## Validierung 2026-09-06

Alle Fundstellen gegen aktuellen Code geprüft. Zwei Korrekturen gegenüber der
Original-Analyse:

- **`neotree-fs-refactor.nvim` ist archiviert** (`E:\repos\ARCHIV_NICHT_BEARBEITEN\neotree-fs-refactor.nvim`)
  — die beiden dort zitierten Zeilen (`:30`, `:55`) fallen aus dem Plan.
- **`MATERIALS/CHECKLIST.md` existiert nicht.** Zielort für die neue Regel ist
  `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md`
  (ID-basiert, `ERR-20/21/22` und `LLS-29` behandeln bereits angrenzende
  `:checkhealth`-Themen) + Schnell-Check-Eintrag in `gates/REVIEW.md`.

Alle übrigen Zeilen (lib.nvim:58, pdfport.nvim:30/131/221, filetree.nvim:70/88,
pickers.nvim:39/45/51, cascade.nvim:39, fileops.nvim:39,
buffer-ctx.nvim:20/90/96/121/165, sessions.nvim:32/147/152/157,
open.nvim:158/185) stimmen zeilengenau mit dem aktuellen Stand überein.

---

## Reihenfolge (nach Hebelwirkung)

1. `lib.nvim` deps/health.lua:58 — "(optional)" → `info`
2. `pdfport.nvim:30` — gleiche Korrektur, eigene Kopie
3. Eine-von-N → `info`: filetree.nvim:70, pickers.nvim:39,45,51
4. `warn` → `error` wo Text "will fail" sagt: cascade.nvim:39, fileops.nvim:39, buffer-ctx.nvim:20, sessions.nvim:32
5. `setup()`-Zeilen: sessions.nvim:147,152,157, open.nvim:158,185, buffer-ctx.nvim:90,96,121,165
6. ADVICE-Nachzug (opportunistisch, kein Vollaudit)
7. Kosmetik: `ℹ️ INFO`-Tag + `after/syntax/checkhealth.vim` in dieser Config
8. Regel in wkdbook-Lua/Checklists/regeln/LUA_NVIM.md + gates/REVIEW.md

---

## Was pro Repo zu tun ist

Health.lua-Zeile ändern → falls vorhanden `stylua`/`luacheck` laufen lassen →
commit → push auf `main` des jeweiligen Plugin-Repos, damit es sofort nutzbar
ist. Kein Agent-Einsatz nötig, direkt in der Hauptkonversation, Repo für Repo.

---

## Was noch offen ist

- [x] Schritt 1 — lib.nvim `41297a1` (ein Amend nötig: Backticks in der ersten `-m`-Message wurden von Bash als Command-Substitution gelesen und haben sie zerschossen)
- [x] Schritt 2 — pdfport.nvim `6ab9667`
- [x] Schritt 3 — filetree.nvim `259d4e5`, pickers.nvim `1770d50`
- [x] Schritt 4 — cascade.nvim `681cccf`, fileops.nvim `820dfc2`, buffer-ctx.nvim `e533b99`, sessions.nvim `2edffa7` (warn → error, libuv/lib.nvim-Fälle)
- [x] Schritt 5 — sessions.nvim `0181dce`, open.nvim `4a7c44d`, buffer-ctx.nvim `a84532c` (setup()-Zeilen → info; jeweils auch die im Original nicht zitierten, aber identischen Nachbarstellen im selben Muster mitgefixt)
- [x] Schritt 6 (Teil) — ADVICE-Argument statt in die Message eingebettetem Fix-Hinweis, für die neun bereits angefassten Repos: `lib.nvim` `5d95b49`, `pdfport.nvim` `976d8e4`, `filetree.nvim` `8656406`, `pickers.nvim` `14e06a7`, `cascade.nvim` `053e1dd`, `fileops.nvim` `35cdd4b` (dabei einen echten UI-58-Fund nachgezogen: "will fail to register" war nur `warn`), `buffer-ctx.nvim` `810498c` (gleicher UI-58-Fund), `sessions.nvim` `e3f9592`, `open.nvim` `7d95d0e`. Nebenbei: `sessions.nvim`s Remote-URL auf `StefanBartl` (groß) korrigiert.
  Noch nicht angefasst: casedesk, cmdlog, color_my_ascii, dap, debugging, diff, documentation, emojis, github_stats, gopath, hover, images, insights, language, lsp, markdown, mdview, recommender, replacer, reposcope, runtime-analysis, sandbox, spotlight (~20 Repos) — bewusst noch offen, siehe Frage an den User.
- [x] Schritt 7 — `ℹ️ INFO`-Tag in filetree.nvim `78198b1` + pickers.nvim `f2e433e` (die beiden bereits auf `info` umgestellten Statuslisten), `after/syntax/checkhealth.vim` in nvim-config (per `synID()` gegen einen synthetischen Buffer verifiziert: `DiagnosticInfo` greift). pdfport.nvim bewusst ausgelassen — dessen übrige Backend-`warn`s sind nicht validiert als Eine-von-N, das wäre Schritt 6.
- [x] Schritt 8 — wkdbook-Lua `1d31313`: `UI-57`..`UI-61` in `regeln/LUA_NVIM.md` (neue Sektion "Checkhealth-Konventionen" unter "UI und Bedienbarkeit") + Schnell-Check-Zeile in `gates/REVIEW.md`. Achtung beim nächsten Mal: `UI-50`..`UI-56` und `UI-40`..`UI-44` waren schon vergeben (Buffer/Window-UI bzw. Count-Unterstützung) — vor dem Anlegen neuer IDs immer erst per grep über die *ganze* Datei nach vergebenen `UI-<N>`-Nummern suchen, nicht nur über den Abschnitt, in den man schreibt.

---

## Nebenfund

`sessions.nvim`s Remote-URL zeigt noch auf `stefanbartl` (klein) statt
`StefanBartl` -- GitHub leitet um, aber `git remote set-url origin` waere
Hausputz.

---

