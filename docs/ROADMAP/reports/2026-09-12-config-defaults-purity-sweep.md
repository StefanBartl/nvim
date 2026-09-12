# Config-DEFAULTS-Purity-Sweep & color_my_ascii-Timer-Leak

**Datum:** 2026-09-12
**Auslöser:** Ein offener Task-Punkt aus einer früheren Session ("pickers.nvim's
`plugin/pickers.lua` materialisiert beim Start die volle Default-Config — nach
dem lib.nvim-Fix kostet das nur noch ~3ms statt 19, das Muster bleibt aber
diskutabel").

Betroffene Repos: `pickers.nvim`, `casedesk.nvim`, `reposcope.nvim`,
`color_my_ascii.nvim`, `WKDBooks` (Checklist). Keine Änderung an dieser
nvim-Config selbst — der Report liegt trotzdem hier, auf ausdrücklichen
Wunsch.

---

## 1. Ausgangspunkt: der pickers.nvim-Fund war schon erledigt

Commit [`a0fef68`](https://github.com/StefanBartl/pickers.nvim/commit/a0fef68)
(09.09.2026) hatte das eigentliche Problem bereits gelöst:
`plugin/pickers.lua` rief vor `setup()` `require("pickers.config").get()` auf,
nur um das immer-leere Feld `cfg.collections` zu lesen — das zwang aber einen
vollen `vim.deepcopy` der kompletten `DEFAULTS`-Tabelle. Der Fix übergibt an
dieser Stelle stattdessen direkt `{ collections = {} }`.

→ Kein Handlungsbedarf mehr an dieser konkreten Stelle.

## 2. Analyse: gibt es das Muster noch woanders?

Frage: wie viel Arbeit wäre es, denselben Fix (falls nötig) in **allen**
eigenen Plugins nachzuziehen? Dafür alle ~33 Plugin-Repos unter `$REPOS_DIR`
systematisch durchsucht (zwei parallele Explore-Agents, je eine Hälfte der
Liste) nach: registriert ein `plugin/*.lua`-Autoload-File vor `setup()` etwas,
das dafür echte Config-**Werte** braucht (nicht nur eine statische
Command-Tabelle)?

**Ergebnis:** Das exakte Bug-Muster (eager Materialisierung *wegen* einer
dynamischen Registrierung vor `setup()`) existiert **nirgendwo sonst** — die
meisten `plugin/*.lua`-Dateien sind reine Load-Guards, viele Plugins haben gar
kein `plugin/`-Verzeichnis, und die, die eager registrieren (`hover`,
`sandbox`, `media`, `reposcope`), tun das mit rein statischen, config-
unabhängigen Command-Tabellen — genau das "richtige" Muster.

**Aber:** zwei Plugins trugen dieselbe *Wurzelursache* wie pickers.nvim vor
dem Fix, nur (noch) folgenlos, weil bei ihnen nichts eager davor liest:
`casedesk.nvim` und `reposcope.nvim` hatten in ihrer jeweiligen
`config/DEFAULTS.lua` ebenfalls ein `require("lib.nvim.system.env").get()`
**auf Modul-Ebene** — das bloße `require()` dieses eigentlich reinen
Daten-Moduls hatte damit einen Seiteneffekt (Env-Lookup), unabhängig davon, ob
gerade jemand danach fragt.

## 3. Umgesetzt: DEFAULTS.lua-Purity in drei Repos

Auf Wunsch ("wenn wir da eh dran sind, dann gleich machen") in allen drei
betroffenen Plugins bereinigt — inklusive pickers.nvim selbst, wo die
Call-Site zwar schon gefixt war, das Modul-Ebene-Problem in `DEFAULTS.lua`
aber weiterhin bestand.

| Repo | Datei(en) | Commit |
| --- | --- | --- |
| pickers.nvim | `config/DEFAULTS.lua`, `config/init.lua` | [`35eb577`](https://github.com/StefanBartl/pickers.nvim/commit/35eb577) |
| casedesk.nvim | `config/DEFAULTS.lua`, `config/init.lua` | [`06d1d5b`](https://github.com/StefanBartl/casedesk.nvim/commit/06d1d5b) |
| reposcope.nvim | `config/DEFAULTS.lua`, `config/init.lua` | [`2af74af`](https://github.com/StefanBartl/reposcope.nvim/commit/2af74af) |

**Prinzip:** der env-abhängige Default wird nicht mehr inline in der
`DEFAULTS`-Tabelle berechnet, sondern als Platzhalter dort belassen und im
jeweiligen Config-Accessor (`config/init.lua`) unmittelbar nach dem `require`
aufgelöst — `require("<plugin>.config.DEFAULTS")` allein hat danach keinen
Seiteneffekt mehr.

Bei `casedesk.nvim` war das der aufwendigste der drei Fälle: `repo_root` zieht
dort eine ganze Kaskade abgeleiteter Felder nach sich (`root`, `cases_root`,
`workflow_templates_dir`, `sla_doc_path`, Areas-Verzeichnisse). Statt diese
Kaskade ein zweites Mal von Hand nachzubauen, wird in `config/init.lua` einmal
mit leerem `explicit`-Set genau die `rebuild_derived`/`reconcile_areas`-
Maschinerie aufgerufen, die `setup()` für einen User-Override ohnehin schon
hat — bewiesen identisch per Nachverfolgung der Aufruf-Reihenfolge und durch
die grüne Test-Suite.

**Kein Performance-Gewinn, reine Architektur-Hygiene:** `lib.nvim.system.env`
cached sein Ergebnis bereits fleet-weit; der eigentliche `env.get()`-Call war
nie das teure daran. Der Wert des Fixes ist, dass ein zukünftiger früher
Call-Site (wie der, den pickers.nvim mal hatte) den Bug nicht wiederholen
kann, weil die Quelle des Seiteneffekts jetzt gar nicht mehr in `DEFAULTS.lua`
sitzt.

**Verifiziert:** alle drei Spec-Suiten liefen vor und nach dem Umbau
komplett grün (casedesk: 14/14, reposcope: volle Suite inkl. `config_spec.lua`,
pickers: 358/358). `luacheck`/`stylua` clean in allen sechs geänderten Dateien.

`cmdlog.nvim` wurde ebenfalls geprüft (auf Wunsch, da es unter `$REPOS_DIR`
existiert, obwohl es in der ursprünglichen Plugin-Liste fehlte) — dessen
`DEFAULTS.lua` ist bereits reine Daten, kein Handlungsbedarf.

## 4. Nebenfund: echter Timer-Leak in color_my_ascii.nvim

Auf Nachfrage ("schau dir das an") den bereits dokumentierten doppelten
`setup()`-Aufruf in color_my_ascii.nvim untersucht (`plugin/color_my_ascii.lua`
ruft `setup()` eager mit Defaults auf, ein Lazy-Manager mit `opts` ruft ihn
danach nochmal mit der echten Config auf — laut Kommentar in `init.lua`
bewusstes Design, robust gegen Plugin-Manager ohne `opts`-Unterstützung).

Fast alles dabei ist bereits idempotent (Augroups werden vor jedem
Re-Register gecleart). Eine Stelle war es nicht:
`cache_manager.setup_auto_cleanup()` erzeugte bei **jedem** Aufruf einen neuen
`uv`-Timer, ohne das vorherige Handle zu stoppen — jeder zweite
`setup()`-Aufruf (Bootstrap + Lazy-Manager-Config, oder ein Config-Reload)
ließ einen weiteren 30-Sekunden-Cleanup-Timer für den Rest der Session
mitlaufen, alle mit derselben redundanten Arbeit. Exakt derselbe Bugtyp wie
ein bereits bekannter Fund in `gopath.nvim` (`PERF-82`).

**Fix:** [`7c8e2b0`](https://github.com/StefanBartl/color_my_ascii.nvim/commit/7c8e2b0)
— `setup_auto_cleanup()` stoppt und schließt jetzt ein noch laufendes Timer-
Handle, bevor es ein neues erzeugt. Volle Test-Suite (`TESTS/run.lua`) danach
grün, `luacheck`/`stylua` clean.

## 5. Checklist aktualisiert

`WKDBooks/Development/wkdbook-Lua/Checklists/regeln/`:

- **`LUA_NVIM.md`** — neue Regel `LUA-06`: env-/FS-auflösende `require()`-
  Aufrufe gehören nie auf Modul-Ebene von `config/DEFAULTS.lua`, sondern in
  den Config-Accessor. Mit Beleg-Eintrag zu allen drei Fällen (pickers,
  casedesk, reposcope) plus einer Liste geprüfter, **nicht** betroffener
  Plugins (cmdlog, emojis, filetree, recommender, ui — Modul-Ebene-`require`
  vorhanden, aber nachweislich reine Daten ohne Seiteneffekt).
- **`PERFORMANCE.md`** — zweiter Beleg-Eintrag zu `PERF-82` (Idempotenter
  Timer-Start) für den color_my_ascii-Fund, neben dem bereits bestehenden
  gopath.nvim-Beleg.

Commit: [`9d6c907`](https://github.com/StefanBartl/WKDBooks/commit/9d6c907).

## 6. Zwei Architektur-Fragen, im Chat beantwortet (nicht umgesetzt)

**"Eager, aber statisch registrieren" (wie `hover`/`sandbox`/`media`/
`reposcope`) — auch für die Load-Guard-Plugins sinnvoll?**
Geprüft über die tatsächlichen lazy.nvim-Specs in
`lua/plugins/personal/init.lua`: jeder Eintrag hat entweder `lazy = false`
oder einen echten Trigger (`cmd`/`event`/`ft`/`keys`). lazy.nvim ruft in
beiden Fällen `config`/`opts` synchron auf, **bevor** der eigentliche
Tastendruck/Befehl durchgereicht wird — Befehle existieren in der Praxis also
schon vor dem ersten echten Gebrauch, unabhängig vom Registrierungsmuster.
Der Wert des eager-statischen Musters liegt eher darin, dass diese vier
Plugins öffentliche OSS-Repos sind und robust bleiben sollen gegen Nutzer
*ohne* lazy.nvim oder ohne aufgerufenes `setup()` — für diese Config selbst
bringt es nichts extra.

**Reiner Load-Guard (buffer-ctx, cascade, dap, debugging, diff, emojis,
fileops, gopath, images, insights, language, markdown, mdview, open,
pdfport, recommender, spotlight) — Nachteil? Umstellen?**
Kein Nachteil in dieser Config, aus demselben Grund. Einzige Bruchstelle
(dokumentiert als realer Fund in `LUA-93`, dort bei `blink.cmp`/
`nvim-ts-autotag`): wenn irgendein *anderes* Modul das Plugin per nacktem
`require(...)` zieht, ohne über dessen eigenen Trigger zu gehen — dann läuft
`setup()` nie, und ein Load-Guard-Plugin bietet dann gar nichts an. Ob das bei
einem der genannten Plugins in dieser Config vorkommt, wurde **nicht**
geprüft (aus dem Chat heraus nicht angefragt) — offener Punkt, falls
gewünscht.

---

## Kurzfassung

| Was | Repos | Status |
| --- | --- | --- |
| DEFAULTS.lua-Purity (`LUA-06`) | pickers, casedesk, reposcope | ✅ gefixt, getestet, gepusht |
| cmdlog.nvim geprüft | cmdlog | ✅ kein Fund |
| Timer-Leak (`PERF-82`) | color_my_ascii | ✅ gefixt, getestet, gepusht |
| Checklist-Regel + Belege | WKDBooks | ✅ ergänzt, gepusht |
| Eager-statisch vs. Load-Guard | — | Beantwortet, keine Umsetzung nötig |
| Cross-Plugin-`require`-Check (`LUA-93`-Risiko) | — | Offen, nicht angefragt |
