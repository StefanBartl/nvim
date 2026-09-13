Handover-Notiz aktualisiert und gepusht. Wie gewünscht: **Stopp der Migration** an dieser Stelle. Zusammenfassung:

## Fertig (18 von 34)
cascade.nvim, fileops.nvim, mdview.nvim, sandbox.nvim, buffer-ctx.nvim, casedesk.nvim, cmdlog.nvim, color_my_ascii.nvim, dap.nvim, debugging.nvim, diff.nvim, documentation.nvim, emojis.nvim, filetree.nvim, github_stats.nvim, gopath.nvim, hover.nvim, images.nvim — alle README+docs auf Fassung 3 umgebaut, ASCII-Art per pyfiglet verifiziert, committed & gepusht.

## Noch offen (16 von 34)
insights.nvim, language.nvim, lib.nvim, lsp.nvim, markdown.nvim, media.nvim, open.nvim, pdfport.nvim, pickers.nvim, recommender.nvim, replacer.nvim, reposcope.nvim, runtime-analysis.nvim, sessions.nvim, spotlight.nvim, ui.nvim

`ui.nvim` bleibt der Sonderfall mit der Diary-Prosa, die noch bereinigt werden muss.

## Nebenbei aufgefallen (nicht Teil dieser Migration, evtl. eigener Task wert)
- **Wiederkehrendes Muster:** mehrere Plugins hatten README-Behauptungen über `:checkhealth`, die nicht zum tatsächlichen `health.lua`-Code passten (cmdlog, emojis, filetree, github_stats) — Text wurde jeweils unverändert übernommen bzw. die schon korrekte Doku bevorzugt, nichts repariert. Könnte sich lohnen, das systematisch zu prüfen.
- **gopath.nvim:** `health.lua` prüft intern auf Neovim 0.9+, während README/Badges/Requirements durchgängig 0.10+ verlangen — Diskrepanz, nicht angefasst.
- **github_stats.nvim:** alter README-Health-Abschnitt behauptete Dinge (last-fetch-Zeit, Storage-Größe), die tatsächlich `:GithubStats debug` liefert, nicht `:checkhealth` — die neue README verlinkt stattdessen auf die bereits korrekte `docs/FEATURES/DIAGNOSTICS.md`.
- **hover.nvim:** echte Namenskollision mit `lewis6991/hover.nvim` auf GitHub — "Around it" bewusst als Blockquote direkt nach dem Pitch behalten statt nur als Doku-Link, damit das sofort auffällt.
- Mehrere Repos (buffer-ctx, debugging) haben ein nicht committetes `lua/<name>/bindings/which_key.lua` liegen — sieht nach einem angefangenen, nie gepushten which-key-Feature aus.
- Einige der zuletzt migrierten Repos (gopath, hover, images, github_stats) hatten schon vor der Migration eine ungewöhnlich reife docs/-Struktur (FEATURES/-Kataloge, Developer-Notes/, WORKFLOW.md) — dort war die Migration hauptsächlich README-Verschlankung plus 2-4 fehlende Standardseiten, kein Neuaufbau.

Sag Bescheid, wenn's mit den restlichen 16 weitergehen soll (dann wieder 1 Agent nach dem anderen).
