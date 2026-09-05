# Handover — Checkhealth-Konventionen über alle Plugins

**Stand: 2026-09-06, Plan validiert und in [`docs/ROADMAP/ROADMAP.md`](../ROADMAP.md#checkhealth-konventionen)
eingetragen. Umsetzung noch nicht begonnen.**

Quelle der Analyse: [`docs/ROADMAP/personal/All/FINISH/checkhealt_conventions.md`](../personal/All/FINISH/checkhealt_conventions.md)
(2026-08-31). Regel in einem Satz: *Muss der Nutzer etwas tun? Nein → niemals
`warn`.*

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

## Reihenfolge (nach Hebelwirkung)

1. `lib.nvim` deps/health.lua:58 — "(optional)" → `info`
2. `pdfport.nvim:30` — gleiche Korrektur, eigene Kopie
3. Eine-von-N → `info`: filetree.nvim:70, pickers.nvim:39,45,51
4. `warn` → `error` wo Text "will fail" sagt: cascade.nvim:39, fileops.nvim:39, buffer-ctx.nvim:20, sessions.nvim:32
5. `setup()`-Zeilen: sessions.nvim:147,152,157, open.nvim:158,185, buffer-ctx.nvim:90,96,121,165
6. ADVICE-Nachzug (opportunistisch, kein Vollaudit)
7. Kosmetik: `ℹ️ INFO`-Tag + `after/syntax/checkhealth.vim` in dieser Config
8. Regel in wkdbook-Lua/Checklists/regeln/LUA_NVIM.md + gates/REVIEW.md

## Was pro Repo zu tun ist

Health.lua-Zeile ändern → falls vorhanden `stylua`/`luacheck` laufen lassen →
commit → push auf `main` des jeweiligen Plugin-Repos, damit es sofort nutzbar
ist. Kein Agent-Einsatz nötig, direkt in der Hauptkonversation, Repo für Repo.

## Was noch offen ist

Alles ab Schritt 1 — Umsetzung hat noch nicht begonnen.
