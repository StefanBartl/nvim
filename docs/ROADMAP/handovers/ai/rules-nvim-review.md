# `rules.nvim` gegen `ai.nvim` — laufender Review-Stand

> Lebendes Dokument, wird bei jedem erneuten Durchlauf **an Ort und Stelle**
> aktualisiert (nicht append-only wie `ai.nvim.md`). Zeigt den *aktuellen*
> Stand des Katalogs gegen `ai.nvim`, nicht eine Historie. Große
> Session-Ereignisse ("Review erstmals durchgearbeitet") bekommen trotzdem
> einen neuen Abschnitt in `ai.nvim.md`, siehe dort.

Hintergrund: [ai.nvim.md § "rules.nvim gegen ai.nvim laufen lassen"](./ai.nvim.md#rulesnvim-gegen-ainvim-laufen-lassen-erledigt-kein-auftrag-mehr-offen)
hat 2026-09-14 den **automatischen** Teil laufen lassen und den
**manuellen** Teil (mehrere hundert judgment-Regeln) bewusst offengelassen.
Diese Datei holt das nach und wird ab jetzt bei jedem Re-Run aktualisiert.

**Katalog:** `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists`
(`regeln/{PRINCIPLES,LUA_NVIM,PERFORMANCE}.md`, `gates/{NEW_PROJECT,RELEASE,REVIEW}.md`).
**Engine:** `E:\repos\rules.nvim`. **Geprüft gegen:** `E:\repos\ai.nvim`
(Stand 2026-09-15, Worktree `rules-nvim-ai-nvim-841638`, `main` zu diesem
Zeitpunkt identisch — sauberer Checkout, keine offenen Änderungen).

---

## Re-Run-Snippet

```lua
vim.opt.rtp:append("E:/repos/rules.nvim")
vim.opt.rtp:append("E:/repos/lib.nvim") -- oder ein Sibling-Checkout

require("rules").setup({
  rulesets = { "E:/repos/WKDBooks/Development/wkdbook-Lua/Checklists" },
  gates = {
    new_project = { "NEW" },
    release = { "REL" },
    review = { "ERR", "LUA", "UI", "CMT", "SEC", "PRIN", "PERF" },
  },
})

local target = "E:/repos/ai.nvim" -- oder ein Worktree-Pfad
require("rules").run_gate("review", target)      -- interaktiv: Buffer + Quickfix
require("rules").check_family("DEP", target)
-- headless/CI-Variante: run_gate_json / check_family_json, siehe rules.nvim/docs/BINDINGS.md
```

Entspricht der echten `opts` aus
`nvim/lua/plugins/personal/init.lua` (dort ist `rules.nvim` genauso
konfiguriert) — kein Sonderfall nur für diesen Report.

---

## 1. Automatischer Teil — vollständig, alle 13 Familien

Jede Familie mit mindestens einer `check`-Regel wurde einzeln laufen
lassen (`check_family_json`/`run_gate_json`, headless). Kein Gate-Sammel-
Sweep — `rules.nvim` bietet den absichtlich nicht an (`README.md`: "a
whole-catalog sweep in one command is exactly the shape that produced an
unreadable, multi-hour report").

| Familie | geprüft (`check`) | davon `pass` | `fail`/`error` |
| ------- | -----------------: | ------------: | --------------: |
| ERR, LUA, UI, CMT, SEC, PRIN, PERF (`review`-Gate) | 4 | 4 | 0 |
| DEP | 6 (+1 manual: `DEP-05`, bewusst ohne Check) | 6 | 0 |
| NEW | 14 | 14 | 0 |
| REL | 8 | 8 | 0 |
| TS, XP, LLS | 0 (vollständig `manual`) | – | – |
| **Summe** | **32** | **32** | **0** |

**`exit_code = 0` in jedem einzelnen Lauf.** Kein automatisch geprüfter
kritischer Fund, kein `fail`, kein `error`, keine Waiver nötig.

**`NEW-08` gegengeprüft (war der einzige automatisierte `fail` im
2026-09-14-Lauf, s. `ai.nvim.md`):** jetzt `pass`. Die Umbenennung
`bindings/usercmds.lua` → `bindings/usrcmds.lua` (Commit `2bed0d6`) hat den
Fund tatsächlich behoben — mit diesem Re-Run frisch verifiziert, nicht nur
aus dem Commit-Namen angenommen.

`stylua --check` und `luacheck` liefen zusätzlich direkt (nicht Teil von
`rules.nvim`, aber `NEW-45`/`NEW-49`/§8 der Detailprüfung verlangen genau
das): beide grün, 0 Warnungen/Fehler über alle 31 Lua-Dateien.

---

## 2. Manueller Teil — `gates/REVIEW.md` durchgearbeitet

389 der 421 Katalog-Regeln haben keinen automatischen `check` (judgment
calls) — ein Mehrstunden-Task, jede einzeln gegen den ganzen Code zu
verifizieren, laut `rules.nvim`s eigener Doku genau der Aufwand, den ein
Ein-Kommando-Sweep absichtlich nicht anbietet. Zuerst wurde dafür der
kuratierte Einstiegspunkt benutzt: `WKDBooks/Development/wkdbook-Lua/
Checklists/WORKFLOW.md` § C ("Vor jedem Merge") verweist genau hierfür auf
`gates/REVIEW.md` (Schnell-Check → Detailprüfung §1–9 → Anti-Pattern-
Check) — dieselben Regel-IDs, aber nach Review-Relevanz gruppiert statt
nach Familie. Andere Laufwerke (`E:\repos\...`) lassen sich von hier
(`C:\...\nvim\...`) aus nicht relativ verlinken, daher unten überall
Klartext-Pfade statt Links.

**Nachtrag (2026-09-15, noch dieselbe Sitzung):** auf expliziten Wunsch
zusätzlich alle 389 Einzel-IDs durchgegangen, nicht nur die kuratierte
Teilmenge — Ergebnis in einer eigenen Datei, da zu umfangreich für dieses
Zusammenfassungsdokument:
[`rules-nvim-review-full.md`](./rules-nvim-review-full.md) (13 weitere,
noch offene Funde, davon 4 mit kritischer Katalog-Schwere — am
gewichtigsten: `LUA-16` fehlende `vim.NIL`-Sanitisierung nach
`vim.json.decode()` in allen Providern, und `XP-05` ungecachte
`executable()`-Probes in der `"auto"`-Provider-Resolution).

**Vorgehen:** alle 27 `lua/`-Dateien von `ai.nvim` vollständig gelesen
(nicht nur gegrept), dazu `docs/*.md`/`doc/ai.txt` auf Drift gegen die
echte `BUILTIN`/`provider_order`-Liste geprüft, `--- CDX:`/`PRÜFEN:`/
`@diagnostic disable`/veraltete APIs/`_G.*`/`vim.fn.expand()` gezielt
gegrept.

### Schnell-Check (10 Punkte) — alle ✅

Fehlerbehandlung (`pcall` um jeden `setup()`-Teilschritt in `lua/ai/init.lua`),
Type Guards (`type(...)`-Checks vor jedem `vim.api`-Zugriff, z. B.
`ai.completion.init`s Stale-Response-Guard), Buffer/Window-Validierung
(`nvim_buf_is_valid` vor jedem Callback-Zugriff, `ai.completion`/`ai.ui.ghost`),
kein globaler State (`_G.*`: keine Treffer), Single Responsibility pro
Modul, UI-Cleanup (`ui/panel.lua`s `cancel`/`cancel_all`, an `VimLeavePre`
gehängt), Annotationen vollständig (`@module`/`@class`/`@param`/`@return`
überall), Kommentare driftfrei (Provider-Liste in 6 Dateien identisch),
`lib.nvim` konsequent genutzt (kein Eigenbau für Curl/Notify/Progress/
Keymap/Usercmd), keine Shell-Strings (`os.execute`/`io.popen`: keine
Treffer, alles über `lib.nvim.net.curl`), Secrets nie als Argv
(`secret_headers`/`bearer_token`, nie in der URL — inkl. `gemini.lua`s
bewusster `x-goog-api-key`-Header statt `?key=...`-Query-Param),
`health.lua`: `vim.health.info` (nicht `warn`) für "ein Provider von
fünf nicht verfügbar" — genau die Eine-von-N-Ausnahme aus `UI-57`.

### Detailprüfung — Auffälligkeiten (alle drei erledigt, 2026-09-15)

Alle neun Abschnitte durchgegangen; drei Punkte waren **nicht** glatt
`pass` und sind inzwischen gefixt (Commit `c8ff0ca` in `ai.nvim`, `main`,
`luacheck`/`stylua` grün, volle `plenary`-Suite grün — 48 Tests über 7
Spec-Dateien, 19 davon neu):

| # | Regel | Befund | Fix |
| - | ----- | ------ | --- |
| 1 | `LUA-30` (Zentraler State) | `lua/ai/bindings/usrcmds.lua:49` — `:Ai provider <name>` schrieb mit `require("ai").config().provider = ctx.args.name` direkt auf das von `ai.config.get()` zurückgegebene Live-Objekt. | ✅ `ai.config.set_provider(id)` ergänzt, `usrcmds.lua` ruft jetzt den Setter statt das Feld direkt zu schreiben. Test in `config_spec.lua`. |
| 2 | `LUA-30`/`PERF-14` (State-Lebenszyklus) | `lua/ai/ui/panel.lua:20,52` — `active_panels` wuchs bei jedem `M.open()` und wurde nie verkleinert. | ✅ `M.cancel()` entfernt das Panel jetzt aus `active_panels` (`untrack()`, idempotent); `cancel_all()` iteriert dafür über eine Kopie, da `cancel()` die Liste selbst mutiert. |
| 3 | `PRIN-31`/`PRIN-32` (Testbarkeit), REVIEW.md §6 | Provider-Antwort-Parsing (`claude.to_response`, `gemini.candidate_text`/`prompt_block_reason`, `sse.recover_error_body`) hatte keine Tests. | ✅ Drei neue Spec-Dateien: `sse_spec.lua` (testet die bereits öffentlichen `M.data_payload`/`M.recover_error_body` direkt), `providers_claude_spec.lua`, `providers_gemini_spec.lua` (beide über `M.ask`/`M.stream` mit gestubtem `lib.nvim.net.curl` via `package.loaded`, gleiches Muster wie `providers_spec.lua`s Registry-Reset) — 19 neue Tests, decken Erfolgsfall, API-Fehlerkörper, Geminis `promptFeedback.blockReason`-Sonderfall und die Non-SSE-Fehlerkörper-Recovery ab. |

Bereits bekannte, in `ai.nvim.md` dokumentierte und **bewusst offen
gelassene** Findings (nicht hier erneut aufgeführt, kein neuer Fund):
`ui/panel.lua`s Voll-Buffer-`set_lines()` pro Stream-Chunk (PERF, Punkt 4
der "Nächste Schritte"-Liste dort).

### Anti-Pattern-Check — keine Treffer

`_G.*`, `vim.loop`/`tbl_flatten`/`nvim_buf_add_highlight`/`nvim_err_writeln`
(veraltete APIs, deckt sich mit `DEP-01`…`DEP-07`s automatischem `pass`
oben), `pcall(f(args))`-Fehlform, `os.tmpname()`/hartkodierte Temp-Pfade,
Autocommand statt `:Command` für explizite Nutzeraktionen — keine Treffer.

---

## 3. Fazit

`ai.nvim` ist zum Stand 2026-09-15 **sauber**: 32/32 automatisierte Checks
grün über den ganzen Katalog, luacheck/stylua grün, und die kuratierte
`REVIEW.md`-Checkliste hat außer den drei oben genannten Kleinigkeiten
nichts gefunden — die sind gefixt. Der zusätzliche vollständige
Einzel-Durchgang aller 389 Regel-IDs
([`rules-nvim-review-full.md`](./rules-nvim-review-full.md)) fand 13
weitere, noch offene Punkte — keiner davon ein ausnutzbares Sicherheits-
leck, aber vier mit kritischer Katalog-Schwere (Details dort, § „Neue
Funde"). **Diese 13 sind noch nicht gefixt** — Priorisierungsvorschlag
steht in der verlinkten Datei.

Nächster sinnvoller Zeitpunkt für einen Re-Run: vor `gates/RELEASE.md`
(Phase 10, s. `ai.nvim.md`), oder nach dem nächsten größeren Feature-Zuwachs
— Snippet oben.
