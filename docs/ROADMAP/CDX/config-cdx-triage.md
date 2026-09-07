# CDX-Tag-Triage — Config `lua/`-Baum (2026-09-07)

Aufräum-Durchgang nach dem CDX-Kommentar-Sweep vom 2026-09-06. Der `lua/`-Baum
ist mechanisch sauber (kein `vim.loop`, kein Ternary-Kollaps, keine veralteten
APIs, praktisch keine deutschen Kommentare). Offen waren nur die
**`--- CDX:`-Tags** selbst — bewusste Autorenentscheidungen, im Sweep gesetzt,
nie aufgelöst.

Regeln: `E:/repos/WKDBooks/…/wkdbook-Lua/Checklists/regeln/LUA_NVIM.md
§ Kommentar-Hygiene` (`CMT-01`…`CMT-15`).

**Stand 2026-09-07:** dieser Durchgang abgeschlossen. Alle Entscheidungen mit
dem User geklärt und umgesetzt (Commits `docs(neotest)` … `refactor(config)`).
Was noch als `--- CDX:`-Tag im Code steht, ist **bewusst geparkt** — siehe
Gruppe 3 und die „behalten"-Zeilen unten.

---

## Gruppe 1 — umgesetzt (kein Verhaltensrisiko)

| Ort | Fund | Aktion |
| --- | ---- | ------ |
| `config/menu/custom_menu/init.lua` | `ok_gs and "gitsigns" or "gitsigns"` | → `items = "gitsigns"` ✅ |
| `autocmds/{general,git,terminals,text}/defaults.lua` | „config fields undocumented" | Tags raus — `@field`-Docs stehen vollständig in den jeweiligen `@types/` ✅ |
| `bindings/mappings/smart_del_key.lua` | totes `opts.map_cr`, `Features:`-Boilerplate | `map_cr` raus, Header gekürzt, Caller nachgezogen ✅ |
| `config/todo_comments/init.lua` | erledigter „removed vim.pesc"-Tag | → normaler Erklärkommentar ✅ |
| `wkdoptions/hl_config/features/mode_tint.lua` | `pcall`-um-`vim.v.event` | → direkter Read ✅ |
| `autocmds/init.lua` | 3 Prozess-Notizen | gekürzt, `CDX:`-Präfix raus ✅ |
| `plugins/personal/init.lua` | `-- TODO:`-Marker; `mdview`-Block „P1-5/P2-9 → works" | Marker → Notiz; P-Nummern raus, aktueller Zustand ✅ |
| `plugins/personal/source.lua` | „skips 25× isdirectory" | → „one per repo" (`CMT-10`) ✅ |
| `config/harpoon/types/init.lua` | `NormKeyOpts`-Tag | → normaler lokaler Doc-Kommentar ✅ |

## Gruppe 2 — totes Statusline-Gerüst in `wkdnvchad/`

**Entscheidung:** alle behalten, den einen echten Bug fixen.

| Modul | Aktion |
| ----- | ------ |
| `wkdnvchad/ui/statusline/modules/custom/` | behalten, Tags → „unused — revival target" (Verweis hierher). `render.lua`-Bruch dokumentiert für den Fall der Reaktivierung ✅ |
| `wkdnvchad/ui/statusline/modules/neotest_module/` | behalten, Tag → „revival target"; `neotest.run.get_status()`-Warnung im Tag ✅ |
| `wkdnvchad/config/statusline/lspbased.lua` | **Bug gefixt:** requirte nicht-existentes `wkdnvchad.config.chadrc` → jetzt `wkdnvchad.config.statusline.custom_light` (dort lebt `register_statusline_modules`) ✅ |
| `wkdnvchad/mappings/tabufline/init.lua` | `lib.lua.lazy.require` resolved eager → toter Re-Require-Zweig entfernt, Modul-Require als `pcall`-Guard ✅ |

## Gruppe 3 — neotest Adapter-Split-Brain — **GEPARKT**

**Entscheidung:** geparkt lassen (test.nvim-Extraktion), 7 wortreiche Tags zu je
einem Ein-Zeiler gekürzt, der hierher + auf `docs/ROADMAP/IDEAS/test.md §2.1`
zeigt.

Offen (als `CDX: parked` im Code): `adapters/factory.lua`, `init/utils.lua`,
`init/dependencies.lua`, `autocmds/auto_discovery.lua`, `init/checks/adapter.lua`,
`@types/init.lua`, `debug/init.lua`, `plugins/neotest.lua` (2×).

**Ein echter Bug im Cluster war ein Ein-Wort-Fix und ist erledigt:**
`config/neotest/whichkey` `<leader>ntS` rief `actions.stop_tests()` (existiert
nicht) → `actions.stop()` ✅

## Gruppe 4 — echte Verhaltens-Bugs — umgesetzt

| Ort | Fund | Aktion |
| --- | ---- | ------ |
| `config/noice/init.lua` | Catch-all-Route `{ event = "msg_show" }` vor allen `skip`-Routen; Router stoppt beim ersten Match | Catch-all ans **Ende** verschoben, doppelte E37-Zeile weg ✅ |
| `config/neotree/init.lua` + `plugins/neotree.lua` + `@types/config.lua` | `window_debug`/`window_open`/`busy_guard` akzeptiert + übergeben, aber `M.setup()` liest keins; `busy_guard` zusätzlich als nie implementierte Methode typisiert | überall entfernt ✅ |
| `config/harpoon/preview.lua` | `pcall(require, "config.harpoon.preview_layout")` — Modul existiert nicht | toter `require` raus, Fallback direkt; Boilerplate-Header gekürzt ✅ |
| `wkdoptions/hl_config/breadcrumbs/ctx/utils/text_utils.lua` | quoted-key-Match hat 2 Captures, `local quoted` fing nur den Quote-Char → quoted Table-Keys lieferten `"`/`'` | zweiter Capture ✅ |
| `wkdoptions/hl_config/cword_occurrences/init.lua` | `H` zur Modul-Ladezeit aus `C.cfg` gefroren (nicht `get_cfg()`) → vor `get_cfg()` alle Reads no-op | lazy `HL()`-Accessor ✅ |
| `bindings/mappings/buffer_jump.lua` | spekulativer `tabufline.go_to`-Zweig | entfernt ✅ |
| `breadcrumbs/ctx` `_base_symbol` + `invalidate_caches`; `autocmds/git` enable | keine echten Laufzeit-Bugs / Fix wäre größer | Tags → knappe Notizen, bewusst offen ✅ |

## Gruppe 5 — Stil / Aufräumer — umgesetzt

| Ort | Aktion |
| --- | ------ |
| `bindings/mappings/snacks.lua` | **gelöscht** (272 Z., `M.setup()` nie aufgerufen; `config/snacks/mappings/` deckt dieselben lhs ab, ist verdrahtet) ✅ |
| `bindings/mappings/toggle_comment.lua` | `transform_line()` + Helfer extrahiert, ~40 Z. Duplikat weg, Verhalten identisch ✅ |
| `plugins/workflow.lua` | auskommentierte wakatime- (8 Z.) + autolist.nvim-Blöcke (84 Z.) gelöscht (autolist → cascade.nvim) ✅ |
| `bindings/mappings/sourrounding.lua` | → `surrounding.lua` (`git mv`), `@module` + `require` nachgezogen ✅ |
| `wkdoptions/qflist/` | **gelöscht** — `vim.diagnostic.config()` war voll redundant zu `set_diagnostic_signs()` zwei Zeilen später; `docs/BINDINGS.md` nachgezogen ✅ |
| `bindings_explorer/config.lua` `roots()` | Tag → Notiz (Personal-Slot leer, aber wegen Index-Kontrakt in `plugin_scope`/`records`/`status` bewusst behalten) ✅ |
| `bindings_explorer/init.lua` deutsche UX | Tag → Notiz, bleibt deutsch ✅ |
| `config/fzf/init.lua` „unclear which part does not work" | Tag raus (kein Fund) ✅ |
| `bindings/usrcmds` `:CwdHere`, `bindings/mappings/general` `<leader>date` | Tags → Notizen, beide bleiben ✅ |

## Ortsunabhängiges Wissen → WKDBooks

- `plugins/personal/init.lua` `mdview`-Block: „P0-3/P1-5/P2-9 → works"-
  Roadmap-Punkt-Notizen — im Config auf den aktuellen Zustand reduziert, das
  Feedback-Log bleibt in `mdview.nvim`s eigener ROADMAP. ✅
- `plugins/personal/source.lua` zählende Zahl entfernt. ✅
