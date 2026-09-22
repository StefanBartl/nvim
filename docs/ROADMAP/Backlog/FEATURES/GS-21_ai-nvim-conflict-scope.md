# GS-21 — `ai.nvim`: `opts.conflict`-Scope

**Repos:** ai.nvim (Konsument von gitsuite) · **Nutzen** 3 · **Aufwand** 0,5 ·
**Risiko** niedrig · **Welle** 5 · erledigt 2026-09-22.

## Ausgangslage

`ai.context.assemble(opts)` baut den Prompt-Kontext aus unabhängigen Scopes
(`buffer`, `selection`, `diagnostics`, `cwd`, `structured_data`) zusammen.
Bei einem laufenden Merge-Konflikt bekam das Modell nur den rohen Puffer mit
`<<<<<<<`/`=======`/`>>>>>>>`-Markern — nicht als "hier stehen zwei
Alternativen" gekennzeichnet, sondern als undifferenzierter Text, den das
Modell selbst als Syntaxfehler hätte deuten können.

## Umsetzung

- **ai.nvim** (`10bdb26`): neues `context.conflict`-Flag (default `false`).
  `context/init.lua`s `add_conflict_scope()` pcallt
  `gitsuite.features.conflict` (optionale weiche Abhängigkeit), ruft
  `conflict.scan(bufnr)` und rendert für jede **nicht-ambiguë** Region beide
  Seiten gelabelt (`Merge conflict -- ours (<label>):`/`... theirs
  (<label>):`), inklusive des leeren-Sektion-Falls (`last < first`).
  Ambiguë Regionen werden übersprungen — es gibt keinen Split zum Zeigen.
  `lua/ai/config/DEFAULTS.lua`, `@types/init.lua`, `lua/ai/health.lua`
  (`:checkhealth ai` meldet jetzt auch, ob gitsuite.nvim gefunden wurde) und
  `docs/configuration.md`/`docs/requirements.md`/`doc/ai.txt` entsprechend
  ergänzt — `doc/ai.txt`s `ai.context.assemble()`-Referenz war dabei bereits
  vorher veraltet (fehlte `structured_data` aus einer früheren Änderung),
  im selben Zug mitkorrigiert.

## Nicht umgesetzt — bewusst geparkt

`choose("ai")` (ein Modell löst den Konflikt automatisch und schreibt das
Ergebnis zurück) ist **explizit nicht** Teil dieser Karte — das würde
Modelltext ungeprüft in Code eines Merges schreiben und braucht eine eigene
Vorschau/Bestätigung, bevor irgendetwas geschrieben wird.

## Tests

`TESTS/ai/context_spec.lua`: zwei Blöcke — ein "echtes gitsuite.nvim, falls
vorhanden"-Block (per `pcall(require, "gitsuite.features.conflict")`,
registriert 0 Tests wenn abwesend, wie beim bestehenden `data.nvim`-Muster)
und ein `package.loaded`-gestubbter Block als CI-garantierte Basisabdeckung
(Positivfall, leere Sektion, `scan()`-Fehler wird nicht durchgereicht,
gitsuite.nvim abwesend = stiller No-op). Bei der Untersuchung des ersten
Blocks fiel auf, dass `TESTS/minimal_init.lua`s `add_optional_dep()` einen
sibling-Checkout zwar auf `rtp`/`package.path` legt, `PlenaryBustedFile`
(ohne `{ minimal_init = ... }`) diesen Zustand aber nicht in den tatsächlich
ausführenden Kontext übernimmt — ein vorbestehendes Infrastruktur-Detail
(betrifft auch `data.nvim`s eigenen "echten"-Block), nicht Teil dieser
Karte, nicht angefasst. `stylua`/`luacheck` grün, volle Suite grün
(`LIB_NVIM_DIR`/`PLENARY_DIR` lokal).

## Ergebnis

CI grün auf allen Systemen (`gh run view` bestätigt `completed success`).

## Dokumentation mitgezogen

`docs/configuration.md`, `docs/requirements.md`, `doc/ai.txt` (siehe oben).
