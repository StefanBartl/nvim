# README-Migration auf Fassung 3 — abgeschlossen (34/34)

Alle 34 Plugin-Repos sind auf Fassung 3 umgebaut: README auf Titel/Art/
Badges/Pitch/(Around-it)/Documentation-Links/License gekürzt, restlicher
Inhalt nach docs/ verschoben, ASCII-Art per pyfiglet verifiziert, committed
& gepusht.

cascade.nvim, fileops.nvim, mdview.nvim, sandbox.nvim, buffer-ctx.nvim,
casedesk.nvim, cmdlog.nvim, color_my_ascii.nvim, dap.nvim, debugging.nvim,
diff.nvim, documentation.nvim, emojis.nvim, filetree.nvim, github_stats.nvim,
gopath.nvim, hover.nvim, images.nvim, insights.nvim, language.nvim, lib.nvim,
lsp.nvim, markdown.nvim, media.nvim, open.nvim, pdfport.nvim, pickers.nvim,
recommender.nvim, replacer.nvim, reposcope.nvim, runtime-analysis.nvim,
sessions.nvim, spotlight.nvim, ui.nvim.

## Wiederkehrendes Muster (die meisten Repos)
Reife docs/-Struktur (FEATURES/-Kataloge) schon vorhanden — Migration war
Verschlankung plus 2-4 fehlende Standardseiten:
- `docs/quickstart.md` und `docs/what-you-get.md` fehlten oft, neu angelegt.
- `docs/requirements.md` nur als eigene Seite angelegt wo die
  Requirements-Sektion umfangreich war (2 Tabellen + deps-popup-Absatz);
  wo sie klein war, blieb sie als `## Requirements`-Abschnitt in
  `docs/installation.md` (Präzedenzfall: mdview.nvim).
- Die README-Tabelle "What it does"/"Area | Does" wanderte als Intro-Absatz
  in `docs/FEATURES/README.md` (bzw. `docs/modules.md` wo kein FEATURES/
  existiert) statt ersatzlos zu verschwinden.
- Eigene README-"Integrations"-Sektionen (lsp.nvim, markdown.nvim,
  spotlight.nvim) waren meist schon vollständiger in
  `docs/FEATURES/INTEGRATIONS.md` abgedeckt — gestrichen, nur noch verlinkt.

## Einmalige Sonderfälle
- **media.nvim:** kein FEATURES/ vorhanden — "What it does"/"What it does
  not do" → `docs/scope.md` (Präzedenzfall: images.nvim), "For plugin
  authors" (Lua-API) → `docs/api.md` (Präzedenzfall: hover.nvim,
  buffer-ctx.nvim). Echter Merge-Konflikt beim Push (paralleler Commit vom
  gleichen Account) — per rebase aufgelöst, Fassung-3-Version gewonnen.
- **replacer.nvim:** "Where this sits" (Vergleich zu nvim-spectre/
  grug-far.nvim) in `docs/FEATURES/README.md` gefaltet, kein Präzedenzfall
  existierte dafür.
- **runtime-analysis.nvim:** "The static × runtime join" (Ecosystem-Essay
  über documentation.nvim/docmap-desktop) ebenfalls in FEATURES/README.md
  gefaltet.
- **reposcope.nvim:** Demo-Video (GitHub user-attachments Link) aus eigener
  README-Sektion nach `docs/quickstart.md` verschoben, an den Anfang.
- **ui.nvim:** der eigentliche Sonderfall. Status-Blockquote war eine
  ~80-zeilige Schritt-für-Schritt-Chronik der NvChad-Entkopplung (Step 3-7,
  mehrere Audit-Runden) direkt im README — komplette Diary-Prosa. Chronik
  + Coupling-Tabelle → neues `docs/nvchad-migration.md` (Entscheidungs-
  protokoll + Credits an NvChad). "Scope"/"What it is not" → neues
  `docs/scope.md`. Neues `docs/requirements.md`. Pitch hatte einen
  Selbstwiderspruch, der genau dem Negativbeispiel aus der Fassung-3-
  Template-Datei entsprach ("which it does not do yet, because it is still
  standing on one") — behoben, da Step 7 (2026-09-13, selber Tag) den
  NvChad-Stand ohnehin überholt hatte. Neue "Around it"-Sektion ergänzt
  (casedesk.nvim, filetree.nvim, my.nvim, lib.nvim) — gab es vorher nicht.
  Während der Arbeit lief parallel echte Feature-Entwicklung am selben Repo
  (zwei fremde Commits reingepusht) — per rebase sauber aufgelöst, kein
  Datenverlust.
- **ui.nvim, nebenbei:** User meldete während der Migration einen Doku-Fund
  in `lua/ui/tabline/utils.lua` (style_buf()-Kommentar verwies auf eine
  Begründung in `M.flash`s Doc-Comment, die dort nicht stand) — behoben,
  echte Begründung ergänzt (Icon-Highlight-Gruppe hat keine Flash-Variante
  gebaut). Dazu eine Notiz in `docs/BINDINGS.md` zum asymmetrischen
  Flash-Verhalten (~120ms verzögerter `:confirm`-Dialog bei `<leader>bc`,
  bewusster Trade-off, kein Bug).

## Nebenbei aufgefallen (nicht Teil dieser Migration, evtl. eigener Task wert)
- **Wiederkehrendes Muster:** mehrere Plugins hatten README-Behauptungen über `:checkhealth`, die nicht zum tatsächlichen `health.lua`-Code passten (cmdlog, emojis, filetree, github_stats) — Text wurde jeweils unverändert übernommen bzw. die schon korrekte Doku bevorzugt, nichts repariert. Könnte sich lohnen, das systematisch zu prüfen.
- **gopath.nvim:** `health.lua` prüft intern auf Neovim 0.9+, während README/Badges/Requirements durchgängig 0.10+ verlangen — Diskrepanz, nicht angefasst.
- **github_stats.nvim:** alter README-Health-Abschnitt behauptete Dinge (last-fetch-Zeit, Storage-Größe), die tatsächlich `:GithubStats debug` liefert, nicht `:checkhealth` — die neue README verlinkt stattdessen auf die bereits korrekte `docs/FEATURES/DIAGNOSTICS.md`.
- **hover.nvim:** echte Namenskollision mit `lewis6991/hover.nvim` auf GitHub — "Around it" bewusst als Blockquote direkt nach dem Pitch behalten statt nur als Doku-Link, damit das sofort auffällt.
- Mehrere Repos (buffer-ctx, debugging) haben ein nicht committetes `lua/<name>/bindings/which_key.lua` liegen — sieht nach einem angefangenen, nie gepushten which-key-Feature aus.
- Einige Repos (gopath, hover, images, github_stats) hatten schon vor der Migration eine ungewöhnlich reife docs/-Struktur (FEATURES/-Kataloge, Developer-Notes/, WORKFLOW.md) — dort war die Migration hauptsächlich README-Verschlankung plus 2-4 fehlende Standardseiten, kein Neuaufbau.
