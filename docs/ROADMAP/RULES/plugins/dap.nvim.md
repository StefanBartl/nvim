# dap.nvim

## Zweck
Konfigurationsschicht über nvim-dap: registriert Adapter und Launch-Configs für acht
Sprachen (Lua, JS/TS, C/C++, Go, Python, Rust, Zig, Assembly), erkennt/validiert
Adapter-Binaries (mit Mason-Fallback), verdrahtet ein austauschbares Panel-UI
(nvim-dap-view oder nvim-dap-ui), und liefert Keymaps/Commands/which-key-Gruppe. Quelle:
README.md, lua/wkddap/registry.lua, lua/wkddap/ui/provider.lua,
lua/wkddap/bindings/keymaps/init.lua.

## Nicht-standard Patterns / Algorithmen

1. `lua/wkddap/bindings/keymaps/init.lua:32-91` (`counted_step`) — `N<leader>ds` soll N
   Debugger-Steps ausführen, aber ein naives `for i=1,count do dap.step_over() end` ist laut
   DAP-Spec unzulässig, weil ein neuer Step-Request nicht gesendet werden darf, solange der
   Thread noch läuft. Lösung: der erste Step feuert sofort, weitere Steps werden erst über
   `dap.listeners.after.event_stopped` nachgefeuert, sobald der Adapter den vorherigen Stop
   bestätigt hat. Zusätzlich: `MAX_CHAINED_STEPS = 1000` als Obergrenze gegen einen
   Fat-Finger-Count oder eine Session, die endlos weiterläuft; `event_terminated`/
   `event_exited`-Listener räumen den Chain-Listener auf, falls die Session vor Abschluss des
   Chains endet (kein dangling Listener). Bei count<=1 (Normalfall) läuft der alte,
   listener-freie Pfad unverändert.

2. `lua/wkddap/ui/provider.lua:19-63` — Auflösung zwischen zwei sich gegenseitig
   ausschließenden Panel-UI-Plugins (nvim-dap-view vs. nvim-dap-ui) über `pcall(require, ...)`
   als Installations-Check, mit explizitem Fallback + Warnung, wenn die konfigurierte
   Präferenz nicht installiert ist, aber die Alternative schon. WARUM: verhindert einen
   harten Fehler beim Setup, wenn der Nutzer nur eines der beiden UI-Plugins installiert hat,
   ohne dass Keymaps/Commands wissen müssen, welches Backend aktiv ist (`dispatch()` routet
   generisch über eine `{[provider]=fn}`-Tabelle).

3. `lua/wkddap/ui/provider.lua:125-132` (`dap_view_call`) — ruft bevorzugt eine Lua-Methode
   auf dem `dap-view`-Modul auf, fällt aber auf den Vim-Befehl (`vim.cmd(command)`) zurück,
   wenn die installierte Version diese Methode (noch) nicht als Funktion exponiert. WARUM:
   defensiv gegen API-Drift zwischen nvim-dap-view-Versionen, ohne eine harte Versionsprüfung
   einzubauen.

4. `lua/wkddap/registry.lua:34-63` — Adapter-Registrierung ist idempotent (`if
   _registered[language] then return true, nil end`) und geht über einen Alias-Layer
   (`config.language_aliases`), bevor Validierung/Laden passiert, mit `pcall` um sowohl das
   `require` als auch den optionalen `adapter.setup()`-Aufruf. WARUM: verschiedene
   Filetype-Namen (z.B. "cpp" vs "c++") sollen auf denselben Adapter mappen, und ein
   fehlschlagendes Setup eines Sprachadapters darf die anderen nicht mitreißen.

5. `lua/wkddap/utils/executable.lua` — reiner Re-Export von `lib.nvim.cross.executable`, kein
   eigener Code mehr (Kommentar: "identical PATH/Mason-bin resolution logic" wurde upstream
   nach lib.nvim verschoben). Selbes Muster in `utils/safe_api`-Äquivalenten anderer Plugins
   hier (color_my_ascii). WARUM: Vermeidung von Codeduplikation über Plugins hinweg, klarer
   Owner der Logik in lib.nvim.

keine weiteren besonderen Patterns über die genannten hinaus in den gelesenen Dateien
gefunden (registry.lua, provider.lua, executable.lua, keymaps/init.lua, usercmds/init.lua).

## Abgeleitete Guidelines

1. Wenn ein Nutzer-Input (count, Argument) eine Sequenz von Aktionen gegen ein externes
   Protokoll/eine State Machine auslösen soll, das strikte Request/Response-Reihenfolge
   verlangt (wie DAP), niemals naiv looped feuern — über den Event/Listener des Protokolls
   verketten und einen Timeout/Terminierungs-Listener zum Aufräumen registrieren.
2. Bei count-gesteuerten Aktionen mit potenziell unbegrenzter Kette immer eine harte
   Obergrenze (`MAX_CHAINED_STEPS`-artig) einziehen.
3. Für den Normalfall (count<=1 bzw. "kein Sonderfall") keinen Overhead einführen — der
   Listener-Pfad existiert nur, wenn er wirklich gebraucht wird.
4. Wenn zwei alternative Backend-Plugins dieselbe Funktion anbieten (hier: zwei Panel-UIs),
   über ein internes `provider.lua`-Dispatch-Modul abstrahieren statt if/else über die ganze
   Codebasis zu verteilen; Installation über `pcall(require, ...)` prüfen, nicht über eigene
   Versionslisten.
5. Bei Fallback zwischen Backends den Nutzer per `notify.warn` informieren, wenn nicht die
   präferierte, sondern die Alternative gewählt wurde — stiller Fallback verschleiert
   Fehlkonfiguration.
6. Adapter-/Modul-Registrierung idempotent gestalten (`if already then return true end`) und
   Setup-Fehler einzelner Komponenten per `pcall` isolieren, damit ein kaputter Adapter nicht
   die gesamte Registrierung blockiert.
7. Alias-Auflösung (unterschiedliche Namen für dieselbe Ressource) als eigener Layer vor
   Validierung/Laden, nicht verteilt über Call-Sites.
8. Rein delegierende Module (dünner Re-Export von lib.nvim) explizit als solche kommentieren
   ("Thin re-export of ..., upstreamed"), damit klar ist, wo die Quelle der Wahrheit liegt.
9. Jeder Keymap bekommt eine `desc`, damit which-key nur eine Gruppen-Bezeichnung braucht statt
   Einzel-Registrierung.
10. Ex-Commands und Keymaps sollten 1:1 dieselben Aktionen abdecken, aber unabhängig
    implementiert sein (Kommentar in usercmds/init.lua: "independent entry point"), damit
    keins vom anderen bricht, wenn eins geändert wird.

## Keybindings-Audit
Alle Keymaps unter konfigurierbarem Prefix (Default `<leader>d`), nur aktiv wenn
`keymaps.enable = true`. Aus `lua/wkddap/bindings/keymaps/init.lua`:

- `<leader>dc` Continue, `<leader>dt` Terminate, `<leader>dr` Restart, `<leader>db` Toggle
  Breakpoint, `<leader>dl` List Breakpoints, `<leader>du` Toggle UI, `<leader>dR` Open REPL:
  Ein-Schritt-Aktionen ohne Mengen-Semantik.
  - count: n.a. — Session-Control-Aktionen sind nicht wiederholbar sinnvoll.
  - Autocompletion: `:Dap <Tab>` über `lib.nvim.usercmd.composer` (Subcommand-Vervollständigung).
  - Fehlende Flags: keine ersichtlich für diese Gruppe.

- `<leader>ds`/`<leader>di`/`<leader>do` (Step Over/Into/Out):
  - count: JA, explizit und korrekt implementiert via `counted_step()` (siehe Pattern 1
    oben) — `3<leader>ds` führt drei Steps sequenziell aus, wartet zwischen jedem auf
    `event_stopped`. Vorbildliche Umsetzung.
  - Autocompletion: n.a. (kein Argument).
  - Fehlende Flags: keine.

- `<leader>dB` Conditional Breakpoint, `<leader>dL` Log Point: öffnen ein `lib.nvim.ui.kit`
  Input-Prompt.
  - count: n.a.
  - Autocompletion: Freitext-Prompt ohne Vorschläge (Condition-Ausdruck bzw. Log-Message)
    — nachvollziehbar, da beliebiger Lua/Sprachausdruck, keine feste Werteliste möglich.
    Das Ex-Command-Pendant (`:Dap conditional-breakpoint <cond>`) erlaubt zusätzlich
    Angabe direkt als Argument via `ctx.rest`, ohne Prompt — gute Doppelabdeckung
    (interaktiv vs. scriptbar).
  - Fehlende Flags: kein Weg, eine vorherige Condition wiederzuverwenden/zu editieren
    (immer leeres Prompt).

- `<leader>de` (n+v) Evaluate Expression/Selection:
  - count: n.a.
  - Autocompletion: n.a.
  - Fehlende Flags: keine ersichtlich.

## Ideen für andere Plugins
1. Ein generisches "count-verkettete asynchrone Aktion"-Hilfsmodul in lib.nvim
   (`lib.nvim.chained_action` o.ä.), das den in `counted_step()` gezeigten
   Event-basierten Verkettungsmechanismus samt Obergrenze und Cleanup-Listenern kapselt —
   wiederverwendbar für jedes Plugin, das count-Aktionen gegen einen asynchronen Prozess
   feuern will (z.B. github_stats' background fetching mit N aufeinanderfolgenden Fetches).
2. Ein generisches "Backend-Provider-Dispatch"-Modul in lib.nvim, das das in
   `ui/provider.lua` gezeigte Muster (Präferenz → Installationscheck → Fallback mit Warnung
   → generisches Dispatch über Aktionsnamen) formalisiert, für jedes Plugin mit
   austauschbaren UI-/Backend-Abhängigkeiten.
