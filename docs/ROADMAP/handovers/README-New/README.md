Verstanden — nach filetree.nvim update ich die Handover-Notiz und stoppe dann mit einer Gesamt-Zusammenfassung (fertig vs. offen).

Handover-Notiz aktualisiert und gepusht. Wie gewünscht: **Stopp der Migration** an dieser Stelle. Zusammenfassung:

## Fertig (14 von 34)
cascade.nvim, fileops.nvim, mdview.nvim, sandbox.nvim, buffer-ctx.nvim, casedesk.nvim, cmdlog.nvim, color_my_ascii.nvim, dap.nvim, debugging.nvim, diff.nvim, documentation.nvim, emojis.nvim, filetree.nvim — alle README+docs auf Fassung 3 umgebaut, ASCII-Art per pyfiglet verifiziert, committed & gepusht.

## Noch offen (20 von 34)
github_stats.nvim, gopath.nvim, hover.nvim, images.nvim, insights.nvim, language.nvim, lib.nvim, lsp.nvim, markdown.nvim, media.nvim, open.nvim, pdfport.nvim, pickers.nvim, recommender.nvim, replacer.nvim, reposcope.nvim, runtime-analysis.nvim, sessions.nvim, spotlight.nvim, ui.nvim

`ui.nvim` bleibt der Sonderfall mit der Diary-Prosa, die noch bereinigt werden muss.

## Nebenbei aufgefallen (nicht Teil dieser Migration, evtl. eigener Task wert)
- **Wiederkehrendes Muster:** drei Plugins hatten README-Behauptungen über `:checkhealth`, die nicht zum tatsächlichen `health.lua`-Code passten (cmdlog, emojis, filetree) — Text wurde jeweils unverändert übernommen bzw. die schon korrekte Doku bevorzugt, nichts repariert. Könnte sich lohnen, das systematisch zu prüfen.
- Mehrere Repos (buffer-ctx, debugging) haben ein nicht committetes `lua/<name>/bindings/which_key.lua` liegen — sieht nach einem angefangenen, nie gepushten which-key-Feature aus.

Sag Bescheid, wenn's mit den restlichen 20 weitergehen soll (dann wieder 1 Agent nach dem anderen).
