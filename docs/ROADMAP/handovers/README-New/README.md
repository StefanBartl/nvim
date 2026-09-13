Migration läuft weiter, ein Repo nach dem anderen. Zusammenfassung:

## Fertig (26 von 34)
cascade.nvim, fileops.nvim, mdview.nvim, sandbox.nvim, buffer-ctx.nvim, casedesk.nvim, cmdlog.nvim, color_my_ascii.nvim, dap.nvim, debugging.nvim, diff.nvim, documentation.nvim, emojis.nvim, filetree.nvim, github_stats.nvim, gopath.nvim, hover.nvim, images.nvim, insights.nvim, language.nvim, lib.nvim, lsp.nvim, markdown.nvim, media.nvim, open.nvim, pdfport.nvim — alle README+docs auf Fassung 3 umgebaut, ASCII-Art per pyfiglet verifiziert, committed & gepusht.

## Noch offen (8 von 34)
pickers.nvim, recommender.nvim, replacer.nvim, reposcope.nvim, runtime-analysis.nvim, sessions.nvim, spotlight.nvim, ui.nvim

## media.nvim: Sonderfall dünnere docs/
media.nvim hatte (noch) kein FEATURES/ und keine der reifen Strukturen der
letzten Repos — README-"What it does"/"What it does not do" wurde zu
`docs/scope.md` (Präzedenzfall: images.nvim hat das schon so gelöst),
README-"For plugin authors" (Lua-API) zu `docs/api.md` (Präzedenzfall:
hover.nvim, buffer-ctx.nvim). Beim Push gab es dort einen echten Merge-Konflikt,
weil parallel woanders (gleicher Account) zwei kleine Commits reingingen —
per rebase aufgelöst, Fassung-3-Version hat gewonnen (die alten Commits waren
nur Detail-Trimming derselben Absätze, die ich sowieso komplett ersetzt habe).

`ui.nvim` bleibt der Sonderfall mit der Diary-Prosa, die noch bereinigt werden muss.

## Muster der letzten 5 (insights, language, lib, lsp, markdown)
Alle fünf hatten schon eine reife docs/-Struktur (FEATURES/-Kataloge etc.) —
Migration war überall Verschlankung plus 2-4 fehlende Standardseiten:
- `docs/quickstart.md` und `docs/what-you-get.md` fehlten in allen fünf, neu angelegt.
- `docs/requirements.md` nur angelegt wo die Requirements-Sektion umfangreich war
  (insights, language, lsp — je 2 Tabellen + deps-popup-Absatz); wo sie klein war,
  blieb sie als `## Requirements`-Abschnitt in `docs/installation.md` (lib, markdown) —
  Präzedenzfall dafür war bereits mdview.nvim.
- Die README-Tabelle "What it does"/"Area | Does" wanderte jeweils als Intro-Absatz
  in `docs/FEATURES/README.md` (bzw. `docs/modules.md` bei lib.nvim, da dort kein
  FEATURES/-Ordner existiert) statt ersatzlos zu verschwinden — war an keiner
  anderen Stelle in der gleichen Kompaktheit vorhanden.
- lsp.nvim und markdown.nvim hatten je eine eigene README-"Integrations"-Sektion,
  die in beiden Fällen bereits vollständiger in `docs/FEATURES/INTEGRATIONS.md`
  stand — komplett gestrichen, nur noch verlinkt.

## Nebenbei aufgefallen (nicht Teil dieser Migration, evtl. eigener Task wert)
- **Wiederkehrendes Muster:** mehrere Plugins hatten README-Behauptungen über `:checkhealth`, die nicht zum tatsächlichen `health.lua`-Code passten (cmdlog, emojis, filetree, github_stats) — Text wurde jeweils unverändert übernommen bzw. die schon korrekte Doku bevorzugt, nichts repariert. Könnte sich lohnen, das systematisch zu prüfen.
- **gopath.nvim:** `health.lua` prüft intern auf Neovim 0.9+, während README/Badges/Requirements durchgängig 0.10+ verlangen — Diskrepanz, nicht angefasst.
- **github_stats.nvim:** alter README-Health-Abschnitt behauptete Dinge (last-fetch-Zeit, Storage-Größe), die tatsächlich `:GithubStats debug` liefert, nicht `:checkhealth` — die neue README verlinkt stattdessen auf die bereits korrekte `docs/FEATURES/DIAGNOSTICS.md`.
- **hover.nvim:** echte Namenskollision mit `lewis6991/hover.nvim` auf GitHub — "Around it" bewusst als Blockquote direkt nach dem Pitch behalten statt nur als Doku-Link, damit das sofort auffällt.
- Mehrere Repos (buffer-ctx, debugging) haben ein nicht committetes `lua/<name>/bindings/which_key.lua` liegen — sieht nach einem angefangenen, nie gepushten which-key-Feature aus.
- Einige der zuletzt migrierten Repos (gopath, hover, images, github_stats) hatten schon vor der Migration eine ungewöhnlich reife docs/-Struktur (FEATURES/-Kataloge, Developer-Notes/, WORKFLOW.md) — dort war die Migration hauptsächlich README-Verschlankung plus 2-4 fehlende Standardseiten, kein Neuaufbau.

Sag Bescheid, wenn's mit den restlichen 16 weitergehen soll (dann wieder 1 Agent nach dem anderen).
