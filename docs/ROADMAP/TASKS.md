- [ ] **TUI-Spike: `ext_messages`-Logger neben noice und `ui2` in echter TUI testen** (Vorbedingung für das Message-Popup „letzte n Sekunden"). Kontext: Konzept `WKDBooks/Development/wkdbook-myplugins/lib.nvim/ROADMAP/messages-log-and-recent-popup.md` (Schritt 1), Befunde in `$NVIM_CONFIG_DIR/docs/ROADMAP/reports/noice-feature-abdeckung-2026-10-01.md`. Headless ist belegt, dass zwei `vim.ui_attach(…, { ext_messages = true })`-Listener beide jedes `msg_show` bekommen. Offen ist, was in einer echten TUI passiert. Nur testen, nichts bauen, keine Ersatzentscheidung.
  - Prüfen (Wegwerf-Skript, Ablage nach `TOOL-PLACEMENT.md`):
    1. Logger-only: nur `ext_messages` attachen, kein Renderer. Erwartung laut Nvim-Doku: die TUI zeichnet keine Meldungen mehr. Bestätigen und festhalten, wie sich das äußert (Meldungen weg? Prompts? `:messages`?).
    2. Logger neben noice (deine Config): Zeitstempel, Reihenfolge und `kind` der Events. Werden alle Meldungsarten gesehen (`echo`, `echomsg`, `emsg`, `wmsg`, `lua_error`, `rpc_error`, `:w`-Meldung, `showmode`, Suchzähler, `vim.notify`)? Verschluckt oder verändert der Logger etwas bei noice? Was passiert, wenn noice per `:Noice disable` oder `:Noice enable` umgeschaltet wird?
    3. `ui2` isoliert: `require("vim._core.ui2").enable({})` ohne noice, mit `msg.targets` pro `kind`. Was kommt gut, was fehlt gegenüber deinem Setup? Dazu `g<`, Pager und Cmdline-Highlighting prüfen.
    4. noice und `ui2` gleichzeitig: nur kurz testen, um den erwarteten Konflikt zu belegen.
    5. Kosten: Ringpuffer mit z. B. 1000 und 10000 Einträgen, `hrtime`-Overhead pro Event, Verhalten bei Meldungsfluten (`:echo` in Schleife, LSP-Logging).
    6. Verhalten bei `:redir`, `:silent`, `vim.cmd("silent …")` und `nvim_exec2(output = true)`: sieht der Logger diese Meldungen?
  - Ergebnis: Spike-Report nach `$NVIM_CONFIG_DIR/docs/ROADMAP/reports/`, mit einer klaren Antwort je Punkt (belegt, widerlegt oder offen) und einer Empfehlung zur Attach-Policy („nur attachen, wenn ein Renderer existiert"). Das Konzeptdokument in WKDBooks um die Ergebnisse ergänzen.
  - Danach entscheidet ein Mensch, ob `lib.nvim.messages` gebaut wird (Schritt 3 ff. im Konzept).

- [ ] **Übrige externe Plugins mit den eigenen Plugins abgleichen** (zweiter Teil des Roadmap-Punkts „Konkurrenzanalyse / noice & übrige externe Plugins": was ist durch eigene Plugins abgedeckt, was fehlt?). Nur dokumentieren, keine Ersatzentscheidung. Vorlage ist der Noice-Report `noice-feature-abdeckung-2026-10-01.md` (Feature-Matrix mit ✅ / 🟡 / ❌ / ➖).
  - Liste aus `lua/plugins/*.lua` (ohne `StefanBartl/…`): search.nvim, nui.nvim, neogit, neo-tree-tests-source, vim-matchup, mini.ai, snacks.nvim, tokyonight, which-key, nvim-cmp, fzf-lua, gitsigns, mason, vim-visual-multi, plenary, neo-tree (+ diagnostics-Source), neotest, telescope (+ file-browser, fzf-native, github), nvim-web-devicons, nvim-treesitter (+ textobjects), nvim-notify, blink.cmp, diffview, targets.vim, nvim-autopairs, nvim-ts-autotag. noice ist bereits erledigt.
  - Bereits abgelöst am 2026-09-19 (nicht erneut prüfen): nvim-window-picker → `ui.windowpicker`, nvim-bqf → pickers.nvim `quickfix`, zen-mode → `ui.zen`, minty/volt → `ui.colorpicker`.
  - Pro Plugin ermitteln: (1) wozu es bei dir dient und welche Features du tatsächlich nutzt (Config, Keymaps, `docs/NOTES/ExternPlugins/Bindings/*`); (2) welches eigene Plugin das Feld berührt (z. B. filetree.nvim ↔ neo-tree, pickers.nvim ↔ telescope/fzf-lua/snacks, gitsuite.nvim und diff.nvim ↔ gitsigns/neogit/diffview, lsp.nvim ↔ mason/cmp/blink); (3) Abdeckung je Feature (✅ / 🟡 / ❌ / ➖, mit Fundstelle im Quelltext); (4) ob das eigene Plugin das externe **ersetzt** oder **aufsetzt** (Abhängigkeit, Wrapper, Engine).
  - Mit Einschätzung der Reichweite des externen Plugins arbeiten, die Roadmap-Regel gilt: bei „mittlerer Ähnlichkeit" nur die reichweitenstärksten berücksichtigen.
  - Ergebnis: ein Report nach `$NVIM_CONFIG_DIR/docs/ROADMAP/reports/` mit Gesamtmatrix, einer Lückenliste und einer kurzen Liste „kein eigenes Pendant, auch keins geplant". Abhängigkeiten, die nach der Analyse übrig sind (z. B. `nvim-notify` und `nui.nvim` unter noice), sauber aufführen. Nichts entfernen oder ersetzen, ohne dass du es beschließt.





