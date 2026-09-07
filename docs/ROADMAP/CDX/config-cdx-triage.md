# CDX-Tag-Triage — Config `lua/`-Baum (2026-09-07)

Aufräum-Durchgang nach dem CDX-Kommentar-Sweep vom 2026-09-06. Der `lua/`-Baum
ist mechanisch sauber (kein `vim.loop`, kein Ternary-Kollaps, keine veralteten
APIs, praktisch keine deutschen Kommentare). Offen sind nur die **`--- CDX:`-Tags**
selbst — bewusste Autorenentscheidungen, die im Sweep gesetzt, aber nie
aufgelöst wurden.

Herkunft der Regeln: `E:/repos/WKDBooks/…/wkbook-Lua/Checklists/regeln/LUA_NVIM.md
§ Kommentar-Hygiene` (`CMT-01`…`CMT-15`).

Legende: **FIX** = direkt umgesetzt (kein Verhaltensänderung / strikt besser) ·
**FRAGE** = Autorenentscheidung nötig · **PARK** = bewusst offen, Tag bleibt.

---

## Gruppe 1 — direkt umgesetzt (kein Verhaltensrisiko)

| Ort | Fund | Aktion |
| --- | ---- | ------ |
| `config/menu/custom_menu/init.lua:339` | `ok_gs and "gitsigns" or "gitsigns"` — beide Zweige gleich, `ok_gs` ist im `if` oben schon `true` | → `items = "gitsigns"` |
| `autocmds/{general,git,terminals,text}/defaults.lua:3` | „config fields undocumented" | Ein-Zeilen-`#`-Notiz pro Feld ergänzt |
| `bindings/mappings/smart_del_key.lua:49` | `opts.map_cr` wird gesetzt aber nie gelesen; kein `<CR>`-Map existiert; `Features:`-Boilerplate-Header (`CMT-07`) | totes `map_cr` raus, `@param` korrigiert, Header auf `@brief` gekürzt |
| `config/todo_comments/init.lua:79` | `--- CDX:` beschreibt eine **erledigte** Änderung (`vim.pesc` entfernt) | auf normalen Kommentar zurückgestuft (`CMT-11`) |
| `wkdoptions/hl_config/features/mode_tint.lua:17` | `pcall(function() return vim.v.event end)` — `vim.v.event` kann nicht werfen | → `local event_tbl = vim.v.event` |
| `autocmds/init.lua:4,6,9` | drei Prozess-Notizen (Refactor-Wunsch, „move to wkdoptions/ui", „not exercised yet") | auf knappe `-- TODO`/`-- NOTE` gekürzt, `CDX:`-Präfix raus |
| `plugins/personal/init.lua:33` | `-- TODO:`-Marker (`CMT-06`: eigene Marker → `--- CDX:` oder Notiz) | zu neutraler Notiz umformuliert |
| `config/harpoon/types/init.lua:54` | `Cfg.Harpoon.NormKeyOpts` nie an `@param`/`@cast` gebunden (externe `normkey`-Option) | als lokale Doku behalten, Tag → normaler Kommentar |

---

## Gruppe 2 — FRAGE: totes Statusline-Gerüst in `wkdnvchad/`

Alle drei sind **von keinem der 6 Statusline-Varianten** referenziert; die
`README.md` von `wkdnvchad/ui/statusline/modules/` sagt das selbst
(„currently unreferenced … pending a closer look").

| Modul | Zustand |
| ----- | ------- |
| `wkdnvchad/ui/statusline/modules/custom/` (`init.lua`, `breadcrumbs/helpers.lua`, `breadcrumbs/render.lua`) | 0 Requires. `render.lua` ist zusätzlich kaputt (ruft `M.repo_relative`/`M.symbol_context`/… ohne `breadcrumbs/helpers.lua` zu requiren → nil-call) |
| `wkdnvchad/ui/statusline/modules/neotest_module/` | 0 Requires. `neotest.run.get_status()` ist **keine** neotest-API → würde beim Verdrahten sofort nil-callen |
| `wkdnvchad/config/statusline/lspbased.lua` | Variante „lspbased" lädt `wkdnvchad.config.chadrc` — **existiert nicht**. Registriert nie Statusline-Module, trifft immer den `notify.error`-Pfad. Aktive Variante ist „normal", daher latent |

**Optionen:** (a) alle drei löschen · (b) alle behalten (Tags → `CDX: unused —
revival target`) · (c) `custom/` + `neotest_module/` löschen, `lspbased.lua`
reparieren (`require` auf `wkdnvchad.config.statusline.custom_light` zeigen).

---

## Gruppe 3 — PARK/FRAGE: neotest Adapter-Split-Brain

7 Tags, alle zeigen auf **`docs/ROADMAP/IDEAS/test.md §2.1`** und die geplante
`test.nvim`-Extraktion. `plugins/neotest.lua` hardcodet `opts.adapters` auf
plenary/vitest/go; die ganze Registry-Maschinerie darunter ist tot.

| Ort | tote Einheit |
| --- | ------------ |
| `config/neotest/adapters/factory.lua:4` | `M.get_all()` — 0 Aufrufer |
| `config/neotest/init/utils.lua:6` | `M.build_adapters()` — 0 Aufrufer |
| `config/neotest/init/dependencies.lua:17` | `neotest-vim-test` installiert, kein Builder in `ADAPTER_BUILDERS` |
| `config/neotest/autocmds/auto_discovery.lua:6` | `M.attach()` — require auskommentiert |
| `config/neotest/init/checks/adapter.lua:5` | nie required — Call-Site auskommentiert |
| `config/neotest/@types/init.lua:4` | `AdapterConfig`/`Position`/`Result`/`RunOpts` — keine Call-Site |
| `config/neotest/debug/init.lua:135` | `ts_config.adapter` existiert nicht → `NeotestDebugRoot` löst nie einen TS-Root auf |
| `config/neotest/whichkey/init.lua:66` | `actions.stop_tests` existiert nicht (`actions/init.lua` hat es nicht) — **live**, `whichkey.setup()` läuft aus `plugins/neotest.lua:96` |
| `plugins/neotest.lua:18,101` | „hardcoded, ignoriert factory"; „check how many adapters wired up" |

**Optionen:** (a) totes Gerüst **jetzt** löschen (factory, build_adapters,
auto_discovery, checks/adapter, orphan-@types, vim-test-Dep) und die 2 echten
Bugs — `whichkey stop_tests`, `debug ts_config.adapter` — fixen · (b) geparkt
lassen, die 7 Tags zu **einem** Pointer auf `test.md §2.1` zusammenfassen ·
(c) Registry jetzt richtig verdrahten.

---

## Gruppe 4 — FRAGE: echte Verhaltens-Bugs, klein

| Ort | Fund | Vorschlag |
| --- | ---- | --------- |
| `config/noice/init.lua:148` | Catch-all-Route `{ event = "msg_show" }` steht **vor** allen `skip=true`-Routen; noice stoppt beim ersten Match → „search hit BOTTOM/TOP", E23/E20/E37/E31/E351/E418, „No signature help" u.a. werden **nie versteckt** | Catch-all ans **Ende** der Routen-Liste verschieben |
| `config/neotree/init.lua:12` | `window_debug`/`window_open` werden akzeptiert + von `plugins/neotree.lua` übergeben, aber `M.setup()` liest keins → tote Knöpfe | löschen (Config + `plugins/neotree.lua` + `@types/config.lua`) |
| `config/neotree/@types/config.lua:21` | deklarierte Methode, die `M` nie implementiert | Feld löschen |
| `config/harpoon/preview.lua:33` | `config.harpoon.preview_layout` existiert nirgends | Zweig entfernen bzw. echten Config-Key einsetzen |
| `wkdoptions/hl_config/breadcrumbs/ctx/utils/text_utils.lua:184` | `text:match("^%[(['\"])(.-)%1%]%s*=")` liefert 2 Captures, `local quoted` fängt nur den **Quote-Char**; quoted Table-Keys lösen zu `"`/`'` auf | `local q, key = …; if key then return key end` |
| `wkdoptions/hl_config/breadcrumbs/ctx/init.lua:156,197` | `cfg._base_symbol` wird nie gesetzt (Container-Provider); eine Fn ohne Aufrufer (`invalidate_tick` & Ziele) | `_base_symbol`-Pfad prüfen/entfernen; tote Fn löschen |
| `wkdoptions/hl_config/cword_occurrences/init.lua:14` | `H` wird zur Modul-Ladezeit aus `C.cfg` gefroren (nicht `C.get_cfg()`); vor `get_cfg()` → `H = {}`, alle Reads no-op | `H` in `get_cfg()`-Getter umbauen |
| `bindings/mappings/buffer_jump.lua:140` | `tabufline.go_to` — spekulativ, kein bekannter Build hat es | Zweig löschen |
| `autocmds/git/init.lua:38` | `true`/`false`/`nil`-Zweige nötig, weil Submodule „missing required field" melden | Config-Shape aufräumen (größer) |

---

## Gruppe 5 — FRAGE: Stil / kleine Aufräumer

| Ort | Fund | Vorschlag |
| --- | ---- | --------- |
| `bindings/usrcmds/bindings_explorer/init.lua:32` | jeder User-String von `:Bindings` ist **bewusst deutsch** | behalten (deutsche UX ist Absicht, `CMT-06`) — Tag entfernen |
| `bindings/usrcmds/bindings_explorer/config.lua:7` | `roots()[1]` zeigt auf gelöschten `docs/NOTES/PersonelPlugins/BINDINGS/`; `:Bindings path personal` kopiert toten Pfad | `roots()` auf Extern-only kürzen |
| `bindings/mappings/sourrounding.lua:2` | Dateiname falsch geschrieben („sourrounding" → „surrounding") | umbenennen + den einen `require` in `mappings/init.lua` |
| `bindings/mappings/snacks.lua:4` | ganze Datei tot — `mappings.init.setup()` requiret sie nie; `GD` doppelt gemappt | löschen (pickers.nvim + git/fzf/telescope decken es ab) |
| `bindings/mappings/general.lua:44` | `<leader>date` auch in buffer-ctx.nvim | hier droppen, Plugin gewinnt |
| `bindings/mappings/toggle_comment.lua:5` | Annotation-vs-Regular-Branch zwischen 2 Fns copy-paste | eine Zeilen-Transform extrahieren |
| `bindings/usrcmds/init.lua:68` | `:CwdHere` triggert keinen Tree-Reload | Tree-Refresh anhängen |
| `config/fzf/init.lua:26` | „unclear which part does not work" | Tag entfernen (kein Fund) oder konkretisieren |
| `wkdnvchad/mappings/tabufline/init.lua:140` | `lib.lua.lazy.require` resolved eager → `if not nvchad_tabufline`-Zweig tot | toten Zweig löschen |
| `plugins/workflow.lua:67` | auskommentierte wakatime/autolist-Specs | löschen oder als bewussten „deaktiviert"-Block markieren |
| `bindings/mappings/buffer_jump.lua:6` | 5 Fallback-Strategien + spekulatives API-Probing | auf `vim.t.bufs` reduzieren, wenn tabufline harte Dep ist |

---

## Ortsunabhängiges Wissen → `wkdbook-myplugins/nvim-config/`

Kandidaten aus dem Sweep (noch nicht verschoben):
- `plugins/personal/init.lua` `mdview`-Block: die „P0-3/P1-5/P2-9"-Roadmap-
  Punkt-Notizen — gehören in `mdview.nvim`s eigene Session-Notes, im Config
  bleibt der aktuelle Zustand ohne P-Nummern.
- `plugins/personal/source.lua:50` „skips 25× isdirectory checks" — zählende
  Zahl (`CMT-10`), entfernen.
