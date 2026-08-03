# `runtime-analysis.nvim`

- [x] `E:\repos\Notes\MyNotes\Checklists\Lua\NEW_PROJECT.md` durchgehen und implementieren —
      **erledigt (2026-08-03)**. Nachgezogen: `.luarc.json`, `config/init.lua`
      + `config/DEFAULTS.lua`, `bindings/usrcmds.lua`, ein Top-Level
      `@types/init.lua`, `health.lua` (`:checkhealth runtime-analysis`),
      `doc/runtime-analysis.txt`, `docs/BINDINGS.md`, `docs/COMMANDS.md`,
      README mit ASCII-Art/Badges/TOC, `docs/ROADMAP.md` in Phasen (quick
      wins/medium/langfristig) eingeteilt. Ein Compound-`:RA`-Usercommand
      (`lib.nvim.usercmd.composer`, `:RA request`/`:RA send`) ist ebenfalls
      erledigt — `:RARequest`/`:RASend` bleiben zusätzlich als Aliase
      bestehen, nicht ersetzt. Bewusst nicht nachgezogen:
      `scripts/gen_map.lua` + documentation.nvim als Dev-Dependency (eigenes,
      größeres CI-Vorhaben). Details: `runtime-analysis.nvim/docs/ROADMAP.md`
      § Housekeeping.

---

