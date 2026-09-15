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
Ein-Kommando-Sweep absichtlich nicht anbietet. Statt die 389 IDs einzeln
abzuklappern, wurde stattdessen der dafür vorgesehene, kuratierte
Einstiegspunkt benutzt: `WKDBooks/Development/wkdbook-Lua/Checklists/WORKFLOW.md`
§ C ("Vor jedem Merge") verweist genau hierfür auf `gates/REVIEW.md`
(Schnell-Check → Detailprüfung §1–9 → Anti-Pattern-Check) — dieselben
Regel-IDs, aber nach Review-Relevanz gruppiert statt nach Familie. Andere
Laufwerke (`E:\repos\...`) lassen sich von hier (`C:\...\nvim\...`) aus
nicht relativ verlinken, daher unten überall Klartext-Pfade statt Links.

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

### Detailprüfung — Auffälligkeiten

Alle neun Abschnitte durchgegangen; nur folgende drei Punkte sind **nicht**
glatt `pass`:

| # | Regel | Befund | Einschätzung |
| - | ----- | ------ | ------------- |
| 1 | `LUA-30` (Zentraler State) | `lua/ai/bindings/usrcmds.lua:49` — `:Ai provider <name>` schreibt mit `require("ai").config().provider = ctx.args.name` direkt auf das von `ai.config.get()` zurückgegebene Live-Objekt, statt über einen Setter in `ai.config` zu gehen. | 🟢 gering: der Wert ist durch den Composer-`enum` bereits auf existierende Provider-IDs beschränkt, kein Validierungsloch. Reine Kapselungsfrage, keine Bugquelle. |
| 2 | `LUA-30`/`PERF-14` (State-Lebenszyklus) | `lua/ai/ui/panel.lua:20,52` — `active_panels` wächst bei jedem `M.open()` und wird nie verkleinert, auch nicht wenn ein Panel längst geschlossen/`cancel()`t ist. | 🟢 gering: kleine Structs, nur pro `:Ai ask/stream`-Aufruf einer Session — erst in sehr langen Sessions mit vielen Aufrufen überhaupt spürbar. |
| 3 | `PRIN-31`/`PRIN-32` (Testbarkeit), REVIEW.md §6 | Provider-Antwort-Parsing ist überall als reine Funktion geschnitten (`claude.to_response`, `gemini.candidate_text`/`prompt_block_reason`, `sse.recover_error_body`, analog in `openai`/`ollama`/`loomai`) — aber nur `ai.completion.prompt` (`build`/`parse`) und ein `ai.providers`-Registry-Roundtrip haben tatsächlich Tests unter `TESTS/`. | 🟡 mittel: genau die Art Logik, die laut eigener Architektur-Doku "straightforward to unit test headlessly" ist, bleibt ungetestet — u. a. die Gemini-`promptFeedback.blockReason`-Erkennung und die SSE-Fehlerkörper-Recovery, beides mit dokumentierten Edge-Cases im Code-Kommentar selbst. |

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
grün über den ganzen Katalog, luacheck/stylua grün, und die manuelle
Review-Checkliste hat außer den drei oben genannten Kleinigkeiten (zwei
🟢, ein 🟡 — allesamt keine Sicherheits- oder Korrektheitsfragen) nichts
gefunden. Keiner der drei Punkte blockiert etwas; alle drei sind
Backlog-Kandidaten, keine Sofortmaßnahmen.

**Offen für eine Folgesession, falls gewünscht:**
- `PRIN-31`/`PRIN-32`-Fund (Testlücke) schließen: Unit-Tests für die reinen
  Provider-Parsing-Funktionen ergänzen (`claude.lua`, `gemini.lua`,
  `sse.lua` mindestens).
- `LUA-30`-Fund #1 (Config-Mutation) nur falls ein zweiter Schreibzugriff
  von außen dazukommt — aktuell einziger Fall, kein Muster.
- `LUA-30`-Fund #2 (`active_panels`-Wachstum) nur falls in der Praxis
  spürbar (sehr lange Sessions).
