# Regel-Audit — vollständige Befundliste je Plugin

> Anhang zu [`Regel-Audit-rules-nvim.md`](Regel-Audit-rules-nvim.md). Stand: 2026-09-18.
>
> 497 bestätigte Befunde aus 38 Plugin-Audits gegen die 76 kritischen, nicht
> automatisierbaren Regeln. Jeder Befund wurde von einem zweiten Agenten gegen den
> Quelltext gegengeprüft; 44 weitere Rohbefunde wurden dabei widerlegt und stehen
> hier nicht. **Nichts davon ist umgesetzt** — das ist die Befundlage, nicht der Fix.

`confidence` ist die Einschätzung des prüfenden Agenten: `high` = am Quelltext
eindeutig, `medium` = Regelanwendung ist Ermessenssache, `low` = Verdacht.

## Bearbeitungsstand

> Seit 2026-09-18 ist diese Datei die laufende **Handover-Akte** für die Umsetzung.
> Reihenfolge: `lib.nvim` zuerst (Wurzel-Fixes wirken fleet-weit), danach die
> Reihenfolge des Inhaltsverzeichnisses. Ein Plugin pro Runde, ein Agent, Fixes
> landen sofort auf `main` des jeweiligen Plugin-Repos.

Konvention je Befund — nach dem **Auswirkung**-Absatz steht eine Zeile:

- `**Status.** ✅ erledigt (\`<sha>\`) — <Anmerkung>` — gefixt und gepusht
- `**Status.** ☑️ schon behoben — <Nachweis>` — war beim Nachlesen bereits gefixt
- `**Status.** ⏭️ offen gelassen — <Grund>` — bewusst nicht umgesetzt (Begründung)

Befunde ohne Status-Zeile sind offen. Jeder Plugin-Header trägt zusätzlich
`Stand: n/m` (erledigt + schon behoben / gesamt).

| Plugin | Befunde | ✅/☑️ | ⏭️ | Stand |
|---|---:|---:|---:|---|
| lib.nvim | 17 | 17 | 0 | fertig (2026-09-18) |
| dap.nvim | 21 | 21 | 0 | fertig (2026-09-18) |
| mdview.nvim | 18 | 18 | 0 | fertig (2026-09-18) |
| replacer.nvim | 17 | 17 | 0 | fertig (2026-09-18) |
| buffer-ctx.nvim | 16 | – | – | offen |
| insights.nvim | 16 | – | – | offen |
| language.nvim | 16 | – | – | offen |
| debugging.nvim | 15 | – | – | offen |
| pdfport.nvim | 15 | – | – | offen |
| reposcope.nvim | 15 | – | – | offen |
| sandbox.nvim | 15 | – | – | offen |
| cascade.nvim | 14 | – | – | offen |
| casedesk.nvim | 14 | – | – | offen |
| cmdlog.nvim | 14 | – | – | offen |
| color_my_ascii.nvim | 14 | – | – | offen |
| media.nvim | 14 | – | – | offen |
| ai.nvim | 13 | – | – | offen |
| github_stats.nvim | 13 | – | – | offen |
| gopath.nvim | 13 | – | – | offen |
| lsp.nvim | 13 | – | – | offen |
| open.nvim | 13 | – | – | offen |
| sessions.nvim | 13 | – | – | offen |
| ui.nvim | 13 | – | – | offen |
| filetree.nvim | 12 | – | – | offen |
| images.nvim | 12 | – | – | offen |
| pickers.nvim | 12 | – | – | offen |
| runtime-analysis.nvim | 12 | – | – | offen |
| diff.nvim | 11 | – | – | offen |
| documentation.nvim | 11 | – | – | offen |
| emojis.nvim | 11 | – | – | offen |
| fileops.nvim | 11 | – | – | offen |
| hover.nvim | 11 | – | – | offen |
| markdown.nvim | 11 | – | – | offen |
| recommender.nvim | 10 | – | – | offen |
| rules.nvim | 10 | – | – | offen |
| spotlight.nvim | 9 | – | – | offen |
| my.nvim | 7 | – | – | offen |
| data.nvim | 5 | – | – | offen |

---

## Table of content

  - [dap.nvim](#dapnvim) — 21 Befunde
  - [mdview.nvim](#mdviewnvim) — 18 Befunde
  - [lib.nvim](#libnvim) — 17 Befunde
  - [replacer.nvim](#replacernvim) — 17 Befunde
  - [buffer-ctx.nvim](#buffer-ctxnvim) — 16 Befunde
  - [insights.nvim](#insightsnvim) — 16 Befunde
  - [language.nvim](#languagenvim) — 16 Befunde
  - [debugging.nvim](#debuggingnvim) — 15 Befunde
  - [pdfport.nvim](#pdfportnvim) — 15 Befunde
  - [reposcope.nvim](#reposcopenvim) — 15 Befunde
  - [sandbox.nvim](#sandboxnvim) — 15 Befunde
  - [cascade.nvim](#cascadenvim) — 14 Befunde
  - [casedesk.nvim](#casedesknvim) — 14 Befunde
  - [cmdlog.nvim](#cmdlognvim) — 14 Befunde
  - [color_my_ascii.nvim](#colormyasciinvim) — 14 Befunde
  - [media.nvim](#medianvim) — 14 Befunde
  - [ai.nvim](#ainvim) — 13 Befunde
  - [github_stats.nvim](#githubstatsnvim) — 13 Befunde
  - [gopath.nvim](#gopathnvim) — 13 Befunde
  - [lsp.nvim](#lspnvim) — 13 Befunde
  - [open.nvim](#opennvim) — 13 Befunde
  - [sessions.nvim](#sessionsnvim) — 13 Befunde
  - [ui.nvim](#uinvim) — 13 Befunde
  - [filetree.nvim](#filetreenvim) — 12 Befunde
  - [images.nvim](#imagesnvim) — 12 Befunde
  - [pickers.nvim](#pickersnvim) — 12 Befunde
  - [runtime-analysis.nvim](#runtime-analysisnvim) — 12 Befunde
  - [diff.nvim](#diffnvim) — 11 Befunde
  - [documentation.nvim](#documentationnvim) — 11 Befunde
  - [emojis.nvim](#emojisnvim) — 11 Befunde
  - [fileops.nvim](#fileopsnvim) — 11 Befunde
  - [hover.nvim](#hovernvim) — 11 Befunde
  - [markdown.nvim](#markdownnvim) — 11 Befunde
  - [recommender.nvim](#recommendernvim) — 10 Befunde
  - [rules.nvim](#rulesnvim) — 10 Befunde
  - [spotlight.nvim](#spotlightnvim) — 9 Befunde
  - [my.nvim](#mynvim) — 7 Befunde
  - [data.nvim](#datanvim) — 5 Befunde

---

## dap.nvim

**21 Befunde** (8 × high). Roh gemeldet: 24. — **Stand: 21/21** (⏭️ 0, 2026-09-18)

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/wkddap/ui/provider.lua:25` · `installed` · confidence **high**

**Befund.** installed(name) prüft nur `if name == "dap-view"` und probt für JEDEN anderen Wert `require("dapui")`. resolve() castet den Rest per ---@cast auf 'dap-view'|'dap-ui' und gibt bei Erfolg `preference` unverändert zurück; M.setup speichert diesen Rohwert in _active. Ein unbekannter provider-String wird weder validiert noch auf den Default degradiert.

**Regelbezug.** ERR-22 verlangt, dass ein ungültiger Config-Einzelwert auf seinen Default degradiert und über :checkhealth sichtbar wird. Weder config/init.lua noch health.lua prüfen ui.provider gegen die vier erlaubten Werte; health.lua:56 gibt den Rohwert nur aus, und der Fallback-Warn in Zeile 73 greift nicht, weil preference == active ist.

**Auswirkung.** Holds only when nvim-dap-ui is actually installed (otherwise installed("dapui") fails and the fallback at 61-66 rescues it). In that case `ui = { provider = "dapui" }` wires the dap-ui panel but sets _active = "dapui", so dispatch() (107-124) finds no entry in the actions tables and <leader>du / :Dap toggle-ui and the eval mapping answer "Toggle UI is not supported by 'dapui'" for the whole session even though the panel is set up. health.lua:56 prints the raw value as info and line 72 reports ok "active panel UI: dapui"; the mismatch warn at 73 cannot fire because preference == active. Same for any other typo'd string.

**Status.** ✅ erledigt (`e05e950`) — `resolve()` prüft den Wert gegen die vier erlaubten (`M.is_preference`), warnt und degradiert auf `dap-view`; health.lua warnt bei unbekanntem Wert und unterdrückt die falsche „fell back“-Meldung dafür.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/wkddap/bindings/init.lua:14` · `M.setup` · confidence **high**

**Befund.** M.setup(cfg) indiziert cfg.keymaps.enable (Z. 14), cfg.which_key.enable (Z. 21) und cfg.autocmds (Z. 27) ohne Typ-Guard. init.lua:83 ruft bindings.setup(cfg) als einzigen Setup-Schritt OHNE pcall auf. Zusätzlich steht cfg.which_key.enable als Argument-Ausdruck innerhalb des pcall-Aufrufs in Zeile 21 und wird damit vor dem pcall ausgewertet -- der pcall schützt sein eigenes Argument nicht.

**Regelbezug.** ERR-22: ein ungültiger Config-Einzelwert soll auf den Default degradieren, nicht die gesamte Plugin-Initialisierung abbrechen. vim.tbl_deep_extend ersetzt bei einem Nicht-Tabellen-Wert die ganze Untertabelle, es gibt keine Validierung davor (config/init.lua:20-27).

**Auswirkung.** require("wkddap").setup({ keymaps = false }) throws "attempt to index a boolean value" out of setup(). which_key = false throws too (it is the pcall's own argument, so the pcall on line 21 does not catch it), and autocmds = false throws at autocmds/init.lua:15. In every case usercmds were already registered on line 12 but keymaps/autocmds are not, M._initialized stays false and vim.g.loaded_wkddap is never set — so :checkhealth reports "plugin not yet initialized" and a second setup() call is not blocked. The user sees a raw Lua traceback that names no config key.

**Status.** ✅ erledigt (`ca7f3cf`) — Auf Config-Ebene gefixt: ein Nicht-Tabellen-Wert für `keymaps`/`ui`/`autocmds`/`which_key`/`menu`/`languages` wird vor dem Merge verworfen (Default bleibt), gemeldet und in `config.issues()` für `:checkhealth` festgehalten.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/wkddap/core/setup.lua:23` · `M.setup` · confidence **high**

**Befund.** Der Kommentar Z. 20-21 behauptet "nvim-dap has no set_log_level(); logging is controlled via the NVIM_DAP_LOG_LEVEL env var" und setzt vim.env.NVIM_DAP_LOG_LEVEL = tostring(opts.log_level). Beides ist falsch: nvim-dap hat `M.set_log_level(level)` (lua/dap.lua:1284 -> dap.log.set_level), und NVIM_DAP_LOG_LEVEL wird in nvim-dap nirgends gelesen (os.getenv kommt dort nur für LANG und USER vor).

**Regelbezug.** LLS-31: eine Funktion, die ihre Wirkung aus der geplanten statt der tatsächlichen Arbeit bildet, kann nicht auffallen -- "fail loudly, never silently no-op". Hier wird eine dokumentierte Option (docs/configuration.md:56, @types `log_level`) entgegengenommen, quittiert und nie wirksam.

**Auswirkung.** log_level is a complete no-op: it is documented in docs/configuration.md and typed in @types/init.lua (`log_level? integer`), accepted by setup(), and has zero effect on nvim-dap's log file, which stays at its own INFO default. Someone setting log_level = vim.log.levels.DEBUG to diagnose an adapter gets no extra log output and no indication why. Side effect: the variable is written into vim.env, so it is inherited by every adapter process spawned afterwards. The correct call is require("dap").set_log_level("DEBUG") — a level NAME, not the vim.log.levels integer, which dap.log.tolevel would pass through unvalidated as a number.

**Status.** ✅ erledigt (`beeaa34`) — `log_level` geht jetzt normalisiert (Integer oder Name) als Level-Name an `dap.set_log_level()`, `OFF` → `ERROR`, ungültige Werte werden gemeldet; das `NVIM_DAP_LOG_LEVEL`-Env-Schreiben ist weg.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/wkddap/adapters/init.lua:14` · `M.register_all` · confidence **high**

**Befund.** Der zweite Parameter heißt `_custom_adapters` und ist mit "reserved for future use" annotiert; er wird im Funktionskörper nirgends gelesen. init.lua:59 reicht cfg.adapters dorthin durch, docs/configuration.md:39 beschreibt die Option als "Custom adapter overrides, keyed by language (merged by each adapter module)", @types/init.lua:12 führt sie als Dap.Config-Feld.

**Regelbezug.** LLS-31: die Rückgabe/der Erfolg wird aus der geplanten statt der tatsächlichen Arbeit gebildet -- register_all gibt unbedingt `true` zurück, obwohl die übergebenen Overrides nie angewendet wurden. Ein stiller No-op mit dokumentiertem Feature-Namen.

**Auswirkung.** setup({ adapters = { go = {...} } }) is discarded without a word. The user keeps the built-in dap.adapters.* and gets no warning, no notify and no :checkhealth entry saying the documented option does nothing — the contrast is sharp against the sibling `configurations` option, which configurations/init.lua:49-63 actually applies.

**Status.** ✅ erledigt (`0f7c4ba`) — `adapters` wird jetzt angewendet: Schlüssel = nvim-dap-Adaptername (`codelldb`, `pwa-node`, …), Tabelle wird per `tbl_deep_extend` über die registrierte Definition gelegt, Funktion/unbekannter Name ersetzt bzw. ergänzt; Docs umgeschrieben (vorher „keyed by language“, nie implementiert). API-Entscheidung des Agenten — Sprach-Keys wären ein Follow-up.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/wkddap/health.lua:46` · `M.check` · confidence **high**

**Befund.** health.lua meldet ein fehlendes lib.nvim.bindings.keymap als vim.health.info mit dem Text "not found — using vim.keymap.set fallback". Einen solchen Fallback gibt es nicht: bindings/keymaps/init.lua:28 macht ein nacktes require("lib.nvim.bindings.keymap") (und Z. 29 dasselbe für lib.nvim.count), bindings/init.lua:22-24 fängt den Fehler nur ab und meldet "Skipped keymaps".

**Regelbezug.** LUA-01: "Eine harte Abhängigkeit darf in der Doku nie als optional dargestellt werden." Exakt der Gegenbeispiel-Fall, der in den Belegen für fileops.nvim (health.lua:71-75) schon einmal gefixt wurde -- warn/info statt error für eine harte Abhängigkeit.

**Auswirkung.** With a lib.nvim that lacks bindings.keymap, :checkhealth wkddap reports an informational line claiming a fallback is in effect while in fact not a single DAP keymap is installed. The auditor overstated "alles sei in Ordnung" slightly — setup() does emit one notify.warn("Skipped keymaps: …") at startup (bindings/init.lua:23) — but that warning scrolls past once, and the health check, which is where a user goes to diagnose exactly this, actively contradicts it.

**Status.** ✅ erledigt (`6e25d73`) — `lib.nvim.bindings.keymap` (und `lib.nvim.count`, ebenfalls nackt required) sind jetzt `check_require(..., "error")`, die erfundene Fallback-Info ist gestrichen.

### `LUA-92` — Ein Adapter lädt sein Plugin während `setup()` nicht

`lua/wkddap/core/capabilities.lua:15` · `M.detect` · confidence **high**

**Befund.** detect() ruft während setup() (core/setup.lua:26-29) unbedingt pcall(require, "dapui"), pcall(require, "dap-view") und pcall(require, "nvim-dap-virtual-text") auf, nur um _features zu füllen; der Modul-Header dokumentiert selbst, dass has() keinen Aufrufer hat und health.lua eigene Proben macht -- das Ergebnis wird berechnet und verworfen.

**Regelbezug.** LUA-92 verbietet genau das: `capabilities()` liest `package.loaded[...]`, nie `require` -- unter einem Lazy-Manager IST das require der Ladetrigger. Hier ist es zusätzlich reine Detektion ohne Konsumenten, also Kosten ohne jeden Nutzen.

**Auswirkung.** The marginal cost is nvim-dap-ui: with the default ui.provider = "dap-view", provider.resolve() returns after installed("dap-view") and never touches dapui (ui/provider.lua:57-59), so nothing else in a default setup() would load it — detect() pulls the whole nvim-dap-ui tree into every startup for a result nobody reads. dap-view and nvim-dap-virtual-text are separately required by ui/init.lua:24-35 anyway, so for those two detect() only moves the load earlier rather than causing it; the auditor overstated it by attributing all three to this line. With ui.enable = false and ui.virtual_text = false, however, detect() alone loads all three.

**Status.** ✅ erledigt (`cb638bd`) — `detect()` liest `package.loaded[...]` statt `pcall(require, ...)`; Spec prüft per `package.preload`, dass kein Load ausgelöst wird.

### `XP-04` — OS-Tatsachen brauchen kein Opt-out, Verhaltensunterschiede einen echten Fallback

`lua/wkddap/utils/validation.lua:48` · `M.pick_process` · confidence **high**

**Befund.** pick_process spawnt `vim.system({"ps","-eo","pid,comm"}, …)` ungeschützt. Der Kommentar in Zeile 38-40 hält selbst fest, dass `ps` Unix-only ist und die Auflistung unter Windows "nie funktioniert hat", lässt es aber ohne Fallback stehen.

**Regelbezug.** XP-04 verlangt bei einem Kommando, das auf einer Plattform gar nicht existiert, einen echten Fallback statt eines stillen Ausfalls. Verifiziert: `vim.system` WIRFT bei fehlendem Binary (`ENOENT: no such file or directory (cmd)`), es liefert kein res.code ~= 0. Damit wird die Fehlerbehandlung in den Zeilen 50-57 nie erreicht.

**Auswirkung.** On a Windows machine without a `ps` on PATH, choosing the JS/TS "Attach" configuration (javascript.lua:52-58) hangs nvim-dap's config-resolution coroutine permanently and silently: no error notification, no prompt, no session — the resume that would surface the error is discarded inside vim.schedule. This is worse than the zig case (ERR-01 finding), which at least reaches async.run's xpcall and notifies. Note the trigger is `ps` being absent, not Windows per se — a machine with Git-Bash/MSYS `ps.exe` on PATH will spawn something, so the hang is environment-dependent rather than guaranteed.

**Status.** ✅ erledigt (`5f3f359`) — Spawn ist `pcall`-geschützt (Fehler → Warnung + leerer Picker → `resume(co, nil)`, kein Hang mehr), unter Windows wird `tasklist /FO CSV /NH` benutzt und per `parse_process_list()` auf `pid name` umgeschrieben.

### `XP-05` — Ein fehlschlagendes `executable()`/`exepath()` ist unter Windows teuer und ungecacht

`lua/wkddap/languages/bash.lua:54` · `M.load` · confidence **high**

**Befund.** load() ruft vim.fn.exepath("bash") und vim.fn.exepath("bashdb") direkt auf, obwohl das Plugin mit wkddap.utils.executable.path (-> lib.nvim.cross.executable, memoisiert) genau dafür einen gecachten Weg hat -- config/init.lua:177-188 begründet diese Memoisierung ausführlich mit gemessenen ~50-65 ms pro Miss unter Windows. Zusatz: der Kommentar Z. 51-53 behauptet, pathBashdb bleibe leer, Z. 55 setzt es aber auf das exepath-Ergebnis.

**Regelbezug.** XP-05: ein FEHLSCHLAGENDES executable()/exepath() läuft jeden PATH-Eintrag gegen jede PATHEXT-Endung ab (~44 ms gemessen) und wird von vim.fn nicht gecacht. `bashdb` ist auf praktisch keiner Windows-Maschine installiert -- der Kommentar im selben File sagt das selbst -- also ist dieser Miss garantiert, nicht hypothetisch.

**Auswirkung.** Two uncached PATH probes on every require("wkddap").setup() under the default config. The bashdb probe is a guaranteed miss on practically any machine (the file's own comment says so), which is the ~44 ms PATH×PATHEXT walk XP-05 describes; the bash probe may hit cheaply if Git-Bash is on PATH. So realistically ~44 ms of avoidable startup on Windows, not ~88 ms. Functionally pathBashdb still ends up "" on a miss, so the contradicting comment is misleading rather than wrong in outcome.

**Status.** ✅ erledigt (`29d60d3`) — `pathBash`/`pathBashdb` laufen über `executable.path()` (memoisiert), Miss bleibt `""`; der widersprüchliche Kommentar ist korrigiert.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/wkddap/languages/zig.lua:93` · `M.load ("Launch (build first)".program)` · confidence **medium**

**Befund.** Die program()-Funktion der Konfiguration "Launch (build first)" spawnt `vim.system({ "zig", "build" }, …)` ohne pcall, vor dem coroutine.yield().

**Regelbezug.** ERR-01: externe Prozesse sind eine Systemgrenze und laufen über pcall. Verifiziert im lokalen Neovim: vim.system WIRFT bei nicht auffindbarem Kommando ("ENOENT: no such file or directory (cmd)"), es liefert nicht bloß res.code ~= 0 -- die vorhandene Fehlerbehandlung in Z. 98-103 deckt also nur den Fall ab, in dem der Spawn überhaupt gelingt.

**Auswirkung.** With zig not resolvable on Neovim's PATH (wrapper script, zvm/asdf shim, remote toolchain), selecting "Launch (build first)" throws out of nvim-dap's config resolution. Traced where it lands: the throw propagates through prepare_config into dap/async.lua's xpcall, so the user gets a vim.notify ERROR with a full Lua traceback instead of the executable prompt, and no session starts. Not a silent hang (unlike the pick_process case) — but a raw traceback where a "zig not found" message belongs. TESTS/wkddap/languages/program_prompt_spec.lua stubs vim.system, so the spec cannot catch it.

**Status.** ✅ erledigt (`b6812db`) — `vim.system({"zig","build"})` per `pcall`; bei ENOENT Warnung „zig build could not start“ und Prompt trotzdem (via `vim.schedule`), Spec mit werfendem `vim.system`-Stub.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/wkddap/languages/rust.lua:43` · `rustc_sysroot / initCommands` · confidence **medium**

**Befund.** rustc_sysroot() gibt "" zurück, wenn rustc fehlt (Z. 47-49), UND "" wenn `rustc --print sysroot` fehlschlägt bzw. leeren stdout liefert (Z. 51-52, `… .stdout or ""`). initCommands (Z. 114-129) prüft den Rückgabewert nicht auf "" und konkateniert ihn unbesehen zu einem Pfad.

**Regelbezug.** ERR-11: "leer, aber ok" muss von "leer, weil kaputt" unterscheidbar sein. Hier kollabieren beide Ursachen -- und zusätzlich der dritte Fall "gültiger, aber leerer Output" -- auf denselben Wert, den der Aufrufer dann als gültigen Sysroot behandelt.

**Auswirkung.** With rustc unresolvable, every Rust debug start sends LLDB `command script import "/lib/rustlib/etc/lldb_lookup.py"` (rooted at the filesystem root) plus an io.open on "/lib/rustlib/etc/lldb_commands" that silently yields no commands. codelldb answers with an import error at session start whose text never mentions the actual cause. Because the empty result is cached, a rustc that becomes available later in the same session does not repair it. Correct behaviour is to return no initCommands at all on an empty sysroot.

**Status.** ✅ erledigt (`34f9546`) — `rustc_sysroot()` liefert `nil` statt `""`, `initCommands` gibt dann `{}` zurück und warnt einmal; nur erfolgreiche Lookups werden gecacht.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/wkddap/config/init.lua:20` · `M.setup` · confidence **medium**

**Befund.** M.setup(user_opts) prüft nur type(user_opts) == "table" und macht danach unmittelbar vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), user_opts). Es gibt weder eine KNOWN_OPTS-Liste noch einen Unbekannte-Keys-Check -- weder vor noch nach dem Merge -- und health.lua validiert die Config ebenfalls nicht.

**Regelbezug.** ERR-50 verlangt die Validierung (unbekannte Keys, "meintest du …") VOR dem Merge, weil ein Tippfehler in einer verschachtelten Option sonst stillschweigend im Default verschwindet. Hier fehlt sie ganz, was die Regel in ihrer stärkeren Form verletzt.

**Auswirkung.** An unknown or misspelled key is merged into the active config and then never read, with no diagnostic anywhere. Concretely: keymaps = { enabled = false } still installs all default keymaps (bindings/init.lua:14 reads .enable, which stays true from DEFAULTS); ui = { providers = "dap-ui" } still wires dap-view; menu = { enabled = false } still emits menu entries. Nothing warns and :checkhealth wkddap has no configuration-validation section at all, so the user has no way to discover the typo short of reading DEFAULTS.lua.

**Status.** ✅ erledigt (`ca7f3cf`) — `sanitize()` prüft vor dem Merge gegen eine `KNOWN`-Liste (top-level + nested für `ui`/`which_key`/`autocmds`/`menu`), unbekannte Keys werden mit Levenshtein-„did you mean“ verworfen; `keymaps`/`adapters`/`configurations` bleiben offen (Action-Overrides bzw. Namens-Keys).

### `ERR-53` — In-place-Mutation statt Tabellen-Ersatz bei geteilten Referenzen

`lua/wkddap/languages/javascript.lua:44` · `M.load` · confidence **medium**

**Befund.** javascript.lua ersetzt dap.configurations[lang] durch eine neue Tabelle, browser.lua:88-90 hängt dagegen per vim.list_extend an dieselben Schlüssel an. Der CDX-Kommentar in browser.lua:84-87 hält den daraus folgenden Bug bereits fest, gefixt ist er nicht.

**Regelbezug.** ERR-53 (In-place-Mutation statt Tabellen-Ersatz bei geteilten Referenzen): dap.configurations["javascript"] ist eine von mehreren Sprachmodulen geteilte Tabelle. Wer sie ersetzt statt in-place zu erweitern, verwirft die Beiträge aller Module, die vorher angehängt haben.

**Auswirkung.** languages = { "browser", "javascript" } silently drops the two pwa-chrome entries from dap.configurations.javascript and .typescript — javascript.lua's assignment replaces the table browser.lua appended to. The browser entries survive for javascriptreact, typescriptreact and astro (javascript.lua touches only the first two filetypes), so the user sees "Attach to Chrome" in a .tsx buffer but not in a .ts one, with no message either way. The default order masks it entirely, which is why it has gone unnoticed.

**Status.** ✅ erledigt (`a46fd32`) — `load()` hängt jetzt per `vim.list_extend` an statt zuzuweisen; Spec lädt `browser` vor `javascript` und erwartet 2×pwa-node + 2×pwa-chrome; stale CDX-Kommentar in browser.lua entfernt.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/wkddap/config/init.lua:30` · `M.get` · confidence **medium**

**Befund.** M.get() gibt die lebende Tabelle _active per Referenz zurück (Z. 34), ohne Kopie und ohne dokumentierten "live reference, nicht mutieren"-Vertrag; dasselbe gilt für wkddap.init.M.get_config(), das M._config direkt herausgibt. Konsumenten sind u. a. integrations/menu.lua:29 und health.lua:51 -- beide öffentlich erreichbare Einstiegspunkte.

**Regelbezug.** ERR-54: ein öffentlicher Getter auf geteiltem Zustand kopiert entweder vorm Herausgeben oder dokumentiert explizit die Live-Referenz. Hier passiert weder das eine noch das andere; die @return-Annotation sagt nur Dap.Config.

**Auswirkung.** Latent, not currently triggered: I found no in-repo mutator of the returned table, so nothing breaks today — the auditor's own text concedes this. What is real is the missing contract. Any host composing menu entries, any statusline snippet, or a second plugin calling require("wkddap.config").get() or require("wkddap").get_config() receives the live active config and can mutate it for the rest of the session (including table.sort on a nested list, the github_stats failure mode), and neither the getter nor the annotation warns them off. Fix is one deepcopy or one documented "live reference — do not mutate".

**Status.** ✅ erledigt (`4042989`) — Beide Getter (`config.get()`, `wkddap.get_config()`) dokumentieren die Live-Referenz explizit („read, never mutate“); Kopie wäre falsch, weil `config/init_spec` die `get() == setup()`-Identität pinnt.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/wkddap/languages/python.lua:22` · `M.setup` · confidence **medium**

**Befund.** setup() setzt dap.adapters.python = { type = "executable", command = adapter_path, args = { "-m", "debugpy.adapter" } }. adapter_path stammt aus config.get_adapter_path("python") und ist das debugpy-WRAPPER-Skript, nicht ein Python-Interpreter. Nachgesehen in der lokalen Mason-Installation: mason/bin/debugpy.cmd -> mason/packages/debugpy/debugpy.cmd -> `venv/Scripts/python -m debugpy %*`.

**Regelbezug.** LLS-31: setup() gibt `true` zurück, sobald ein Binary gefunden wurde -- die Rückgabe bildet die geplante, nicht die tatsächlich funktionierende Verdrahtung ab. `-m debugpy.adapter` ist ein Python-Flag; an den debugpy-CLI-Wrapper gereicht wird daraus `python -m debugpy -m debugpy.adapter`, und die debugpy-CLI verlangt zwingend --listen oder --connect.

**Auswirkung.** With the Mason install documented in config/init.lua:48, the python adapter process exits immediately with a debugpy CLI usage error, so nvim-dap reports the adapter as crashed/exited on the first Python debug attempt. health.lua:106-108 reports "python: adapter available" because validate_adapter only checks that a binary path resolves. A pip-installed `debugpy` console script on PATH fails the same way. Correct wiring is command = <debugpy-adapter> with no args, or command = <python> with args {"-m","debugpy.adapter"}.

**Status.** ✅ erledigt (`cc38a8c`) — Adapter-Binary ist jetzt `debugpy-adapter` (Mason liefert `mason/bin/debugpy-adapter.cmd` = `python -m debugpy.adapter`), `args = {}`; installation.md nennt den nötigen Launcher. Nebenfund: reines `pip install debugpy` legt gar kein PATH-Binary an, hat also nie über `get_adapter_path` aufgelöst.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/wkddap/languages/javascript.lua:20` · `M.setup` · confidence **medium**

**Befund.** setup() nutzt config.get_adapter_path("javascript") nur als Gate und verwirft das Ergebnis danach; der tatsächlich verdrahtete Pfad wird fest als vim.fn.stdpath("data").."/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js" zusammengesetzt, ohne zu prüfen, ob diese Datei existiert.

**Regelbezug.** LLS-31 in seiner Umkehrung: die Erfolgsmeldung (`return true`) wird aus der geplanten Arbeit (irgendein js-debug-adapter ist auffindbar) gebildet statt aus der erledigten (der konkret verdrahtete Pfad ist gültig). get_adapter_path findet das Binary explizit AUCH auf $PATH (config/init.lua:189-192), nicht nur unter Mason.

**Auswirkung.** On a non-Mason install (distro package, npm -g, nix) the gate passes, setup() returns true, and dap.adapters["pwa-node"].executable.args points at a dapDebugServer.js under mason/ that does not exist. Every pwa-node session then fails at adapter start with node's "Cannot find module" while health.lua reports "javascript: adapter available". Note the wiring is broken for the same reason even on a Mason install if the package layout changes — nothing verifies the file.

**Status.** ✅ erledigt (`5f94631`) — `executable.command` ist der aufgelöste `js-debug-adapter`-Pfad mit `args = { "${port}" }`, kein hartkodierter Mason-Skriptpfad mehr; WORKFLOW.md-Absatz umgeschrieben.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/wkddap/languages/browser.lua:41` · `M.setup` · confidence **medium**

**Befund.** Identisch zu javascript.lua: config.get_adapter_path("browser") dient nur als Gate (Z. 37-39), verdrahtet wird danach der fest zusammengesetzte Mason-Pfad .../mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js, ungeprüft.

**Regelbezug.** Dieselbe LLS-31-Umkehrung wie in javascript.lua -- Erfolg aus dem Gate statt aus dem Ergebnis. Fix gehört an beide Stellen, sonst lebt der Bug in der Kopie weiter.

**Auswirkung.** Identical defect duplicated: without a Mason install of js-debug-adapter, dap.adapters["pwa-chrome"] references a non-existent dapDebugServer.js, so "Attach to Chrome (js-debug)" and "Launch Chrome (js-debug)" fail at adapter-server start while setup() and health.lua both report success. Fixing only javascript.lua leaves this copy broken.

**Status.** ✅ erledigt (`5f94631`) — Dieselbe Verdrahtung wie javascript.lua, Spec prüft für beide `command`/`args`.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/wkddap/health.lua:33` · `M.check` · confidence **medium**

**Befund.** Der Abschnitt "dap.nvim: lib.nvim" prüft lib.nvim.notify/cross/normalize als error, lässt aber ui.nvim vollständig aus -- obwohl docs/requirements.md ui.nvim unter "Required" führt und ui.kit in breakpoints.lua:79, validation.lua:22, assembly.lua:41, c.lua:56, csharp.lua:66, lua.lua:49+63, rust.lua:99, zig.lua:47+77 sowie ui.contextmenu in integrations/menu.lua:19 nackt requiret wird.

**Regelbezug.** LUA-01 verlangt, harte Abhängigkeiten konsistent zu behandeln. health.lua zählt die harten Abhängigkeiten explizit auf und begründet im Kommentar Z. 34-38, warum sie error und nicht warn sind -- genau diese Aufzählung übergeht die zweite harte Abhängigkeit.

**Auswirkung.** With ui.nvim absent, :checkhealth wkddap says nothing about it at all — the lib.nvim section passes and the user is sent looking elsewhere. Every interactive path then throws "module 'ui.kit' not found" at the moment of use: <leader>dB / <leader>dL breakpoint prompts, the executable/DLL prompts of C/C++, Rust, Zig, Assembly and C#, the Lua host/port prompts and the JS attach process picker. Because those prompts run inside nvim-dap's resolution coroutine, the error arrives via dap/async.lua's xpcall as a traceback notification. requiring wkddap.integrations.menu fails outright at module load (ui.contextmenu on line 19). Adding the same check_require(..., "error") lines for ui.kit/ui.contextmenu is the whole fix.

**Status.** ✅ erledigt (`6e25d73`) — Neuer Abschnitt „dap.nvim: ui.nvim“ mit `check_require("ui.kit")`/`("ui.contextmenu")` auf `error`.

### `LUA-90` — Ein globales `setup()` hat genau einen Besitzer

`lua/wkddap/ui/virtual_text.lua:16` · `M.setup` · confidence **medium**

**Befund.** M.setup() ruft vt.setup(config.virtual_text) mit der eigenen, in config/init.lua:127-137 hartcodierten Optionstabelle auf. Anders als bei den beiden Panel-Providern (opts.dap_view / opts.dap_ui, ui/dapview.lua:26 und ui/dapui.lua:30) gibt es für nvim-dap-virtual-text KEINE Durchreich-Option in Dap.UiOptions -- nur den An/Aus-Schalter ui.virtual_text.

**Regelbezug.** LUA-90: ein Fremd-Plugin mit genau einem globalen setup() gehört dem Spec, der es installiert; ein zweiter Aufruf "kippt die eigene Tabelle zur globalen Konfiguration". Die Asymmetrie zu dap_view/dap_ui zeigt, dass die Durchreichung hier schlicht fehlt, nicht bewusst weggelassen wurde.

**Auswirkung.** Because the pcall(require, …) is itself the lazy load trigger, the host's own spec config/opts runs first and wkddap's table is merged over it immediately after — so a user who sets virt_text_pos = "inline" or commented = false in their own nvim-dap-virtual-text spec has exactly those keys silently reverted to wkddap's values on every setup(). Keys wkddap does not name (display_callback, virt_text_win_col, …) survive. The only escape is ui.virtual_text = false, which disables the feature entirely. Correcting one sub-claim: the plugin builds a NEW table via tbl_deep_extend and config.virtual_text is flat, so the live module table is not retained by reference by the foreign plugin.

**Status.** ✅ erledigt (`d845deb`) — `ui.virtual_text` akzeptiert jetzt `true` (dap.nvim-Defaults), eine Tabelle (roh an `vt.setup()`, wie `dap_view`/`dap_ui`) oder `false` (dokumentiert: eigener Spec besitzt das Setup, das Plugin läuft weiter — „disables the feature entirely“ aus dem Befund stimmte nicht).

### `PERF-46` — Cache-Key vollständig

`lua/wkddap/languages/rust.lua:15` · `sysroot_cache` · confidence **medium**

**Befund.** sysroot_cache ist ein prozessweiter Ein-Wert-Cache ohne Schlüssel und ohne Invalidierung; der Kommentar Z. 12-13 begründet das mit "The value is a property of the toolchain, not of the session". `rustc --print sysroot` hängt aber vom Arbeitsverzeichnis ab -- ein rust-toolchain.toml bzw. ein `rustup override` im Projekt liefert einen anderen Sysroot.

**Regelbezug.** PERF-46: der Key muss jeden Parameter enthalten, der das Ergebnis beeinflusst. Hier beeinflusst das cwd das Ergebnis, der Cache hat aber gar keinen Key -- und PERF-42 (definierte Invalidierung/TTL) fehlt ebenfalls.

**Auswirkung.** Weaker than the auditor claims but real. prefetch_sysroot() is called from M.setup() (rust.lua:78), i.e. once at plugin setup, so the cached sysroot is normally the one for Neovim's STARTUP directory, not for the project being debugged — a :cd or :lcd into a second Rust project with a different toolchain (or a rust-toolchain.toml pinning nightly) keeps serving the first answer. The consequence is that LLDB imports lldb_lookup.py from the wrong toolchain; both toolchains ship that file, so the usual outcome is subtly mismatched pretty-printer output rather than a hard error. The per-session, no-invalidation design also means a `rustup update` mid-session is never picked up, and (see the ERR-11 finding) a failed lookup caches "" permanently.

**Status.** ✅ erledigt (`34f9546`) — Cache ist `table<cwd, sysroot>`, beide Spawns bekommen `cwd = paths.workspace_root()`; Spec zeigt: gleiche cwd → 1 Spawn, andere cwd → neuer Spawn, Fehlschlag wird nicht gemerkt.

### `PRIN-10` — Keine globalen States

`lua/wkddap/languages/csharp.lua:37` · `M.setup` · confidence **medium**

**Befund.** setup() setzt unter Windows global vim.opt.shellslash = false und stellt den vorherigen Wert nie wieder her. Der Kommentar Z. 11-13 dokumentiert, dass dieser Seiteneffekt schon einmal von der Modul-Ebene nach setup() verschoben wurde -- global ist er trotzdem geblieben.

**Regelbezug.** PRIN-10 (Zustand lebt modul-intern, Zugriff nur über Getter/Setter) sinngemäß auf globalen Editor-Zustand angewandt: ein Sprachmodul kippt hier eine sitzungsweite Option, die jedem anderen Plugin gehört. XP-04 rechtfertigt zwar den OS-Zweig ohne Config-Key, nicht aber den unbegrenzten Geltungsbereich -- nötig ist die Einstellung nur für das Argument, das an netcoredbg geht.

**Auswirkung.** Reachable only when netcoredbg actually resolves — setup() returns at line 28-30 otherwise. When it does (default languages = {} enables csharp, and auto_install/Mason make netcoredbg common), a bare require("wkddap").setup() on Windows turns shellslash off session-wide, overriding a user who deliberately set it in their own init.lua. Path completion, :! commands and any other plugin reading &shellslash see backslashes from then on, and the cause is invisible from the outside because it is attached to "C# happens to be in the default language list". Note PRIN-10 is applied here by analogy — the rule as written governs a module's own state, not editor options — but the defect itself (unbounded scope for a side effect needed only for one argument) is real.

**Status.** ✅ erledigt (`bfe537c`) — `vim.opt.shellslash = false` entfernt; `program` und `cwd` gehen durch das neue `paths.native()` (Backslashes nur unter Windows); LANGUAGES.md/CONTRIBUTING.md angepasst. Die Wirkungsbegründung im Befund war falsch: `vim.fs.normalize()` liefert ohnehin Forward-Slashes, das globale `shellslash` hat den DLL-Pfad nie beeinflusst — netcoredbg bekommt erst jetzt wirklich Backslashes (nicht live getestet).

### `ERR-02` — Type Guards & Literal Checks

`lua/wkddap/languages/c.lua:55` · `M.load (program)` · confidence **low**

**Befund.** local co = coroutine.running() ohne anschließenden nil-Check; co wird direkt an coroutine.resume() in den Callbacks weitergereicht. Dasselbe Muster in assembly.lua:40, csharp.lua:65, lua.lua:48 und lua.lua:62, rust.lua:98, zig.lua:74. utils/validation.lua:9-12 prüft an derselben Stelle korrekt auf nil -- die Inkonsistenz ist innerhalb des Repos sichtbar.

**Regelbezug.** ERR-02: Type Guards und nil-Checks vor der Verwendung, besonders vor API-Zugriffen. Unter LuaJIT gibt coroutine.running() im Haupt-Thread nil zurück; coroutine.resume(nil, …) wirft dann "bad argument #1 to 'resume'".

**Auswirkung.** Latent only — the auditor is right that nvim-dap's real path cannot reach it: dap/async.lua always runs config resolution inside a coroutine and dap.lua:592 asserts as much, so co is never nil in practice today. The concrete consequence if the path is ever reached (a spec calling program() directly, a third-party tool evaluating dap.configurations, a future nvim-dap resolution change) is that the throw surfaces from the submit/cancel callback rather than from program(), decoupling the error from its cause. Treat this as a consistency fix (mirror validation.lua's guard), not a live bug.

> **Abdeckung dieses Laufs.** Vollständig gelesen: alle 42 Lua-Dateien unter lua/ und plugin/ (3143 Zeilen), dazu README.md, docs/requirements.md, docs/configuration.md und die Specs TESTS/minimal_init.lua, contract_spec.lua, program_prompt_spec.lua, setup_spec.lua sowie gezielte Ausschnitte aus provider_spec.lua, config/init_spec.lua, mason_spec.lua, menu_spec.lua, validation_spec.lua und breakpoints_spec.lua (~500 Zeilen). .claude/, .git/, .deps/ und doc/tags wurden ausgelassen.

Extern verifiziert (nicht geraten): (a) nvim-dap unter nvim-data/lazy/nvim-dap hat `M.set_log_level` in lua/dap.lua:1284 und liest NVIM_DAP_LOG_LEVEL nirgends -- os.getenv kommt dort nur für LANG und USER vor; (b) mason/bin/debugpy.cmd delegiert auf mason/packages/debugpy/debugpy.cmd = `venv/Scripts/python -m debugpy %*`; (c) `vim.system` wirft bei fehlendem Kommando ("ENOENT: no such file or directory (cmd)"), getestet mit dem lokalen nvim --headless. Diese drei Punkte tragen die Findings zu core/setup.lua, python.lua, zig.lua und validation.lua.

Nicht abgedeckt / Einschränkungen:
- CMT-16: docs/map/ und docs/BINDINGS.md sind generierte Artefakte. Ich habe NICHT geprüft, ob sie gegenüber ihren Renderern gedriftet sind oder Handänderungen enthalten -- das braucht einen :DocMap-Lauf bzw. den Renderer aus lib.nvim, beides außerhalb eines reinen Lesevorgangs.
- SEC-46 (rust.lua) und PERF-46 (sysroot_cache): beide beruhen auf LLDB-Quoting-Semantik bzw. rustup-Toolchain-Overrides, die ich nicht ausführen konnte. Der Code-Befund ist gesichert, die Auswirkung ist begründet abgeleitet, nicht reproduziert.
- Die LLS-31-Findings zu javascript.lua/browser.lua/python.lua treffen eine Regel, deren Wortlaut ("Rückgabe aus der geplanten statt der tatsächlichen Arbeit") passt, deren Familie aber ursprünglich LuaLS-Diagnosen adressiert. Der Sachbefund ist eindeutig, die Regelzuordnung ist ein Urteil.
- PRIN-10 für csharp.lua:37 (globales shellslash) ist ebenfalls eine Zuordnung per Analogie: keine der 76 Regeln adressiert das Mutieren fremder Editor-Optionen direkt.
- Nicht geprüft werden konnte, ob nvim-dap-view/nvim-dap-ui die ihnen per Referenz übergebenen Tabellen (config.dapui_layout, config.virtual_text) tatsächlich mutieren; deshalb ist nur der virtual_text-Fall gemeldet (dort fehlt zusätzlich die Durchreich-Option) und nicht dapui.lua:30.
- Für ERR-30/ERR-31 gibt es in diesem Plugin keine Oberfläche: es schreibt keine einzige Datei (kein io.open("w"), kein vim.fn.writefile, kein uv.fs_open). Gelesen wird nur rust.lua:121 (io.open(..., "r")).

Explizit gegen die Belege gegengeprüft: LUA-03 nennt dap.nvim mit utils/executable.lua -- diese Datei ist heute ein reiner Re-Export von lib.nvim.cross.executable und sauber; kein Re-Report.

**Status.** ✅ erledigt (`beb1e0e`) — An allen 8 Stellen (c, assembly, csharp, lua×2, rust, zig×2) `local co = assert(coroutine.running(), ...)`; kein Spec, weil plenary jeden `it()`-Block selbst in einer Coroutine ausführt.

---

## mdview.nvim

**18 Befunde** (11 × high, 1 davon in Testcode). Roh gemeldet: 20. — **Stand: 18/18** (⏭️ 0, 2026-09-18)

### `ERR-02` — Type Guards & Literal Checks

`lua/mdview/helper/gen_token.lua:7` · `gen_token` · confidence **high**

**Befund.** `math.randomseed(vim.uv.hrtime())` runs at module level (and `vim.uv.hrtime()` again at line 14) with a bare `vim.uv` and no `vim.loop` fallback. `vim.uv` does not exist before Neovim 0.10.

**Regelbezug.** ERR-02 (nil-check before an API access) against a floor the plugin states three times: README.md:18 badge 'Neovim 0.9+', docs/installation.md:7, and health.lua:33-36 which actively reports 'Neovim >= 0.9' as OK. Every other module in this repo uses the documented `local uv = vim.uv or vim.loop` pattern and says why (ws_client.lua:12-14, runner.lua:7-9, detached.lua:235-237).

**Auswirkung.** On Neovim 0.9, requiring mdview.helper.gen_token raises "attempt to index field 'uv' (a nil value)" at load time, and because server_args.lua requires it at module level, the whole server_args module fails to load — so :MDView start cannot spawn the relay at all on the version the plugin advertises as its minimum. :checkhealth stays green throughout, since health.lua's own probe only asks has("nvim-0.9"). Scope note: this is the load-time break; log.lua carries the same 0.9 break behind a feature flag.

**Status.** ✅ erledigt (`c1af46f`) — gen_token.lua und adapter/log.lua nutzen jetzt `vim.uv or vim.loop` statt bare `vim.uv`, passend zum dokumentierten Neovim-0.9-Floor.

### `ERR-03` — Explizite Rückgaben

`lua/mdview/adapter/ws_client.lua:298` · `http_post_nonblocking` · confidence **high**

**Befund.** The no-curl fallback wraps `fn.system(cmd)` in a pcall and treats pcall success as command success: `if ok then ... cb(0, lines) end`. `vim.fn.system()` does not raise on a nonzero exit, so `ok` is true whenever the Lua call itself did not error, and the exit status in `vim.v.shell_error` is never read.

**Regelbezug.** ERR-03 requires a real success/failure return, not a silent one. Here a total failure (no sh, relay down, curl missing, nonzero exit) is reported to the caller as exit code 0.

**Auswirkung.** try_send_pending's callback (line 337) tests `if code == 0`, so a total failure of the fallback POST — no sh, curl missing, relay down, any nonzero exit — is reported as success: M._pending[path] is deleted at line 339 and "queued post success" is logged at line 343. The retry/backoff path at lines 346-360 becomes unreachable on this branch, so the buffer content is dropped with no retry and no message; the preview silently freezes at its last state. Reachable only when `fn.executable("curl") ~= 1`, i.e. exactly the machines this fallback exists to serve.

**Status.** ✅ erledigt (`b2773a5`) — Der No-curl-Shell-Fallback (Erfolg trotz Fehlschlag) ist entfernt; `http_post_nonblocking` meldet jetzt einen expliziten `curl not found`-Fehler statt stillschweigend zu scheitern.

### `ERR-03` — Explizite Rückgaben

`lua/mdview/adapter/ws_client.lua:109` · `http_get` · confidence **high**

**Befund.** The no-curl health-check fallback runs `fn.system("curl -sS " .. url)` inside a pcall and reports `cb(ok and 0 or 1)`. Since `fn.system` returns normally for a failed command, `ok` is true even when curl is absent (shell exit 127) or the relay is dead.

**Regelbezug.** Same silent-success inversion as above, on the readiness gate rather than the content path -- 'keine stillen Fehler' applied to the one check that decides whether the rest of the pipeline may proceed.

**Auswirkung.** wait_ready reports a dead relay as healthy on the first poll: M._ready is set true at line 140 and cb(true) fires. Because M._ready is session-cached and only cleared by reset_ready() (launcher.start / stop.lua:50), every later wait_ready in that session short-circuits at line 117 without any check at all. Downstream, launcher.M.start's readiness callback proceeds to open the browser tab against a port nothing is listening on, and live_push's per-keystroke wait_ready wrapper (live_push.lua:136-142) waves through every push to the same dead port. The user gets a browser error page and a preview that never renders, with no error from mdview. Same curl-less precondition as the POST case.

**Status.** ✅ erledigt (`b2773a5`) — Gleicher Fix für `http_get`: kein Shell-Fallback mehr, expliziter Fehlerkanal; neue Spec `ws_client_transport_spec.lua`.

### `ERR-03` — Explizite Rückgaben

`lua/mdview/diagnostics.lua:175` · `M.run` · confidence **high**

**Befund.** `local f = io.open(path, "w"); if f then ... end; return path` -- when the file cannot be opened (unwritable directory, bad user-supplied path) nothing is written, no error is returned or logged, and the path is returned exactly as on success. `M.run`'s signature offers no error channel at all.

**Regelbezug.** ERR-03: a relevant function must report success/failure instead of failing silently. The sibling exporters in this repo get it right (usrcmds/log.lua:259-266 and usrcmds/breadcrumbs.lua:149-156 both branch on the nil handle and notify an error), so this is the odd one out.

**Auswirkung.** When io.open fails — an unwritable directory, a path under a nonexistent parent, a read-only volume — :MDView diagnose <path> still prints "[mdview] diagnostics written to <path>" (usrcmds/diagnose.lua:13) and then runs `tabnew <path>` (line 16), which opens an empty, nonexistent-file buffer that looks like an empty report. The user believes they have a diagnostics file and hands over a path with nothing behind it — the one hand-off the module exists for. Note the default path branch (lines 170-174) is safe, so this only bites when the user passes an explicit path.

**Status.** ✅ erledigt (`3c8fc61`) — `M.run` meldet einen nicht schreibbaren Report-Pfad statt ihn unkommentiert zurückzugeben.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/mdview/bindings/usrcmds/start/init.lua:45` · `parse_start_args` · confidence **high**

**Befund.** The token loop matches `^cwd=(.+)$` and `^port=(%d+)$`; anything else falls into `elseif not file then file = token end`. A malformed value -- `port=808O` (letter O), `port=` with no value, `cwd=` with no value -- matches neither pattern and is therefore adopted as the *file path*.

**Regelbezug.** ERR-10 verbatim: 'no argument' and 'invalid argument' are collapsed, so a typo in one argument silently behaves as a different, valid argument instead of raising. The rule names this as a real, previously-observed bug class.

**Auswirkung.** "no argument" and "malformed argument" collapse into the same code path, and the malformed one is silently reinterpreted as a different, valid argument. `:MDView start port=808O` starts the relay on the default port with no parse error and no range warning, then treats the literal string "port=808O" as the document to preview: initial_push_async normalizes it, no buffer matches, readfile fails under pcall, and an empty document is pushed into a room named after the typo. The user's actual buffer is never previewed and nothing explains why. `:MDView start cwd=` behaves the same way, and additionally drops the cwd override the user meant to set.

**Status.** ✅ erledigt (`badfd5c`) — `parse_start_args` weist einen fehlerhaften `cwd=`/`port=`-Wert jetzt zurück statt ihn als Dateiname zu übernehmen.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/mdview/adapter/ws_client.lua:42` · `transport` · confidence **high**

**Befund.** transport() reads the config through `config.get()` / `config.options`, neither of which exists on `mdview.config` (the module exports only `defaults`, `validate`, `merge`), and the `type(config.get) == "function" and ... or config.options or {}` guard turns that into an empty table, so the function always returns its four hardcoded fallbacks.

**Regelbezug.** LLS-31's core case: a defensive wrapper around a call that can never succeed keeps the breakage invisible and the function silently does nothing (here: silently ignores the user). The rule's own framing -- 'fail loudly, never silently no-op' -- is exactly what is violated; every other module in this repo reads `require("mdview.config").defaults`.

**Auswirkung.** transport.health_poll_ms, transport.max_retries and transport.base_retry_ms are unreachable: the /health poll interval is permanently 200ms and a failed POST always retries 5 times from a 150ms base, whatever setup() says. transport.health_timeout_ms is dead twice over — both real callers pass an explicit timeout (live_push.lua:141 and launcher.lua:182 hand wait_ready ws_client.WAIT_READY_TIMEOUT = 15000), so `timeout_ms or tcfg.health_timeout_ms` never reaches the config value either. Correction to the auditor: a user on a slow box who raises health_timeout_ms per docs/configuration.md:44 does NOT see "relay did not respond within 10000ms" — they see ws_client.lua:159's "[mdview] server health-check timed out after 15000ms", unchanged by their setting. The user-facing defect is the same (a documented dial that does nothing, silently), the message and number in the finding are not.

**Status.** ✅ erledigt (`2b746c0`) — `transport()` liest jetzt über `config.defaults` statt über das nie existierende `config.get()`/`config.options`; `health_poll_ms`/`max_retries`/`base_retry_ms` sind damit erstmals erreichbar. Zweiter Fund am selben Ort: `health_timeout_ms` war zusätzlich durch einen zweiten hartkodierten `WAIT_READY_TIMEOUT`-Default an den echten Call-Sites unerreichbar — `WAIT_READY_TIMEOUT` ist jetzt selbst `transport()`s Default, Aufrufer übergeben keinen Override mehr.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/mdview/adapter/inbound_poll.lua:28` · `interval_ms` · confidence **high**

**Befund.** Same broken accessor: `local cfg = (type(config.get) == "function" and config.get() or config.options or {})`, so `(cfg.transport or {}).inbound_poll_ms` is always nil and the function always returns the literal 250.

**Regelbezug.** Identical to the ws_client case -- the guard makes a call against a nonexistent API look like a legitimate 'not configured' path. Note that the same file reads the config correctly three times (lines 50, 429, 446), so this is a drifted copy, not a house style.

**Auswirkung.** transport.inbound_poll_ms is unreachable; the browser→Neovim poll runs at a hardcoded 250ms for the session. Every enabled inbound feature is pinned to it — checkbox write-back, text-field sync, click-to-navigate and reverse scroll (the four endpoints tick() polls at lines 435-450). docs/configuration.md:46 sells this key as "the dial if reverse scroll or click-to-navigate feels laggy"; the dial is disconnected, and lowering it for snappier reverse scroll or raising it to cut curl spawns on battery both do nothing. Unlike the ws_client case there is no second override path, so this key is dead in every code path that reads it.

**Status.** ✅ erledigt (`2b746c0`) — Gleicher Fix für `interval_ms()` in inbound_poll.lua — `transport.inbound_poll_ms` (Checkbox-/Feld-Sync, Click-Navigate, Reverse-Scroll) ist jetzt erreichbar.

### `SEC-03` — Nutzereingabe nie shell-interpoliert

`lua/mdview/adapter/ws_client.lua:288` · `http_post_nonblocking` · confidence **high**

**Befund.** The no-curl fallback builds a shell command string with the full buffer content interpolated into it: `string.format("sh -c %q", "curl -sS -X POST " .. url .. " ... --data-binary @- <<'BODY'\n" .. body .. "\nBODY")`. `body` is the markdown buffer's entire text; `url` carries the percent-encoded document path.

**Regelbezug.** SEC-03 forbids putting user-controlled values into a command string at all. Lua's `%q` escapes for Lua, not for sh: inside the resulting double-quoted sh word, `$` and backticks are still expanded, and `%q`'s backslash-newline pairs are read by sh as line continuations, so the heredoc structure the code relies on does not survive either. Every other spawn in this repo correctly uses an argv list.

**Auswirkung.** On a POSIX machine with no curl on PATH, previewing a document containing `$(...)` or a backtick span executes that text as a shell command under the user's account on every push of that buffer — and README-style shell examples are exactly the content that contains it. A line consisting of `BODY` closes the heredoc early and feeds the rest of the document to sh as commands. Note the reachability ceiling the auditor left out: this branch also needs the outer 'shell' to be POSIX, so it is Linux/macOS/Git-Bash-on-Windows without curl, not Windows cmd.exe. It remains a SEC-03 violation regardless of reachability — the rule forbids building the command string at all.

**Status.** ✅ erledigt (`b2773a5`) — Teil desselben No-curl-Fixes wie #2/#3: keine Shell mehr, also auch kein Weg mehr für einen Backtick-Span im Dokumenttext in die Shell.

### `SEC-21` — Timeout **und** Byte-Limit

`lua/mdview/adapter/install.lua:249` · `M.ensure_client_bundle` · confidence **high**

**Befund.** `fn.mkdir(extracted_dir)` runs at line 242, `tar -xzf` at 247; when the extract fails the function returns an error at 249 but leaves the now-existing, partially-populated `extracted_dir` on disk. The next call short-circuits on `fn.isdirectory(extracted_dir) == 1` at line 233 and returns that directory as a good bundle.

**Regelbezug.** SEC-21's requirement to actively delete a failed/aborted download rather than leave a corrupt artifact in the cache -- the same rule `curl_download` already honours one function up (line 129 removes a truncated `dest` for exactly this reason). The unpack step was not given the same treatment.

**Auswirkung.** A failed extract leaves a directory that the next call accepts as a finished install. The most likely trigger is not a disk-full race but a missing `tar` — docs/installation.md:10 lists tar as a first-run requirement, and without it fn.system returns nonzero and extracted_dir is left EMPTY. From then on, ensure_client_bundle returns it at line 233 and server_args.lua:147/177 hands it to the relay as --web-root; the relay serves nothing, the tab renders blank. :checkhealth does catch this case (health.lua:83-97 reports the incomplete bundle) and tells the user to delete the cache dir, which is the only recovery — but nothing re-downloads on its own, and `:MDView start` itself reports no error at all.

**Status.** ✅ erledigt (`343c2be`) — Ein fehlgeschlagenes `tar -xzf` löscht jetzt das halb befüllte `extracted_dir` per `fn.delete(extracted_dir, "rf")`, statt es als „fertiges Bundle“ für den nächsten Aufruf stehen zu lassen — spiegelt `curl_download`s bestehende Aufräumlogik eine Funktion höher.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/mdview/adapter/detached.lua:101` · `M.resolve_target` · confidence **high**

**Befund.** `path = vim.fn.fnamemodify(vim.fn.expand(arg), ":p")` where `arg` is the raw `file` argument of `:MDView standalone <file>` (routed through usrcmds/init.lua:103 -> standalone.run -> detached.resolve_target).

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user text: a backtick span in the argument is a command substitution through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. The repo already has the sanctioned helper in use elsewhere -- runner.lua:14 imports `lib.nvim.cross.fs.expand_path` for exactly this job.

**Auswirkung.** `:MDView standalone` passes raw command-line text to Vim's filename expansion, which runs backtick spans through &shell — so a backtick span in the argument executes before anything is validated, and the subsequent "not a readable file" error is the only trace. The quieter failure is the likelier one: `%` resolves to the current buffer and `#` to the alternate file, so `:MDView standalone %` or a mistyped `#` silently previews a different document than the one named, with no message, since the expanded path is readable and the command succeeds. Note this needs the user to type the argument, so it is not remotely triggerable — but the same filename also reaches the Ex-string concatenation in scripts/mdview-bg.sh:81.

**Status.** ✅ erledigt (`13c8425`) — `detached.resolve_target` nutzt jetzt `lib.nvim.cross.fs.expand_path` statt `vim.fn.expand()` auf dem getippten `:MDView standalone <file>`-Argument — kein Backtick-Shell-Run, kein `%`/`#`-Missverständnis mehr.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/mdview/bindings/usrcmds/file_log.lua:44` · `absolute` · confidence **high**

**Befund.** `return vim.fn.fnamemodify(vim.fn.expand(path), ":p")`, called with the user's argument from `:MDView file-log on <path>` (line 52) and `:MDView file-log path <value>` (line 82).

**Regelbezug.** Same SEC-34 violation. The function's own comment says it exists to 'expand `~` and resolve relative paths' -- that is precisely the narrow job `lib.nvim.cross.fs.expand_path` does without a shell, without globbing and without Vim specials.

**Auswirkung.** A backtick span in the log-path argument runs through &shell at the moment the command is typed. The realistic damage is the specials, not the backticks: `:MDView file-log on %` expands to the current buffer's own path, and `#` to the alternate file's, so mdview then appends relay stdout to a real source file instead of creating a log — silently, because absolute() reports nothing and set_file_log_path accepts whatever it is handed. Both require the user to type the argument themselves; the value never comes from a buffer or a remote source.

**Status.** ✅ erledigt (`13c8425`) — Gleicher Tausch für `file_log.absolute()` (`:MDView file-log on/path <path>`).

### `ERR-02` — Type Guards & Literal Checks

`lua/mdview/adapter/log.lua:177` · `ensure_dir` · confidence **medium**

**Befund.** `vim.uv.fs_stat(dir)` at 177, and `vim.uv.fs_stat`/`vim.uv.fs_mkdir` again at 217, 220 and 224 -- bare `vim.uv`, no `vim.loop` fallback, in a module whose own comments (lines 63-65, 166-168) carefully justify using luv instead of vim.fn.

**Regelbezug.** Same ERR-02 / stated-0.9-floor break as gen_token.lua, in a second module. Unlike gen_token this one is inside a function rather than at module level, so it only fires when the feature is used.

**Auswirkung.** On Neovim 0.9 the first log line written after `:MDView file-log on` raises "attempt to index field 'uv' (a nil value)" from ensure_dir, called out of the relay's stdout handler. Unlike gen_token this is inside a function, so it costs only the feature, not plugin load: persistent file logging never works and the error surfaces from a libuv callback with no context tying it to the command the user just ran. Everything else in log.lua (the scratch-buffer mirror, the ring) is unaffected.

**Status.** ✅ erledigt (`c1af46f`) — Gleicher Fix wie #1, selbe Datei (adapter/log.lua) — beide Neovim-0.9-Floor-Brüche in einem Commit.

### `ERR-60` — `a and b or c` bricht, sobald `b` falsy sein kann

`lua/mdview/bindings/usrcmds/start/server/launcher.lua:183` · `M.start` · confidence **medium**

**Befund.** `local browser_autostart = (opts.browser_autostart == nil) and require(...).defaults.browser_autostart or opts.browser_autostart` -- the middle operand is a boolean config value that is legitimately `false`. The same construct appears, degenerate (both branches identical), at bindings/usrcmds/start/init.lua:198.

**Regelbezug.** ERR-60 is precisely this shape: once `b` can be falsy, `a and b or c` falls through to `c` regardless of `a`. With `opts.browser_autostart == nil` and a configured `browser_autostart = false`, the expression yields `nil` rather than the config's `false` -- it reaches the right truthiness by accident, not by evaluation.

**Auswirkung.** No user-visible misbehavior today, and the auditor says so honestly. The only consumer is line 257, `if browser_autostart and browser_adapter and browser_adapter.open then`, a truthiness test where nil and false are indistinguishable — so a user who sets browser_autostart = false still gets no browser, by accident rather than by evaluation. The defect is that the expression cannot be read correctly and breaks the moment the value is returned, logged, compared to `false`, or forwarded anywhere that separates "not set" from "explicitly off"; start/init.lua:198 shows the construct already being copied. Fix is a two-line explicit `if`, not a behavior change.

**Status.** ✅ erledigt (`b6a9521`) — `launcher.lua`s `(cond) and default or opts.browser_autostart`-Ternary ist durch ein explizites if/else ersetzt (falsy-Value-Bruch bei `browser_autostart = false`); der degenerierte Zwilling in `start/init.lua` (beide Zweige identisch) ist auf einen reinen Feld-Read vereinfacht.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/mdview/bindings/usrcmds/breadcrumbs.lua:24` · `show_in_scratch` · confidence **medium**

**Befund.** `pcall(vim.api.nvim_buf_set_name, buf, "mdview://breadcrumbs")` -- the pcall swallows the E95 'buffer with this name already exists' that a second invocation raises while the first window is still open, and the function carries on with an unnamed buffer.

**Regelbezug.** LLS-31: the pcall is what keeps the failure invisible, and the function then silently does less than it claims. The repo has already diagnosed and fixed this exact collision once -- usrcmds/log.lua:212-215 documents it ('nvim_buf_set_name throws E95 on a name collision, which happens whenever the previous log window is still open') and reuses the existing buffer instead -- but the sibling command still carries the bug.

**Auswirkung.** `:MDView breadcrumbs` with an earlier breadcrumbs split still open creates a second scratch split that silently ends up unnamed: the content is correct (set at line 18, before modifiable=false), but the buffer carries no mdview:// name, so nothing can find or reuse it and every further invocation adds another split. The pcall is what keeps this invisible — without it the E95 would surface the collision. Scope correction: show_in_scratch never reuses a buffer under any circumstances, so the split accumulation is present by construction; what the swallowed error costs specifically is the buffer's identity, which is also the thing that would let a fix reuse it the way usrcmds/log.lua does.

**Status.** ✅ erledigt (`adbc556`) — `show_in_scratch` in breadcrumbs.lua spiegelt jetzt usrcmds/log.lua's bestehenden Fix für dieselbe E95-Kollision: Buffer per Name suchen und wiederverwenden statt den Fehler in einem bare `pcall` zu verschlucken und unbenannt weiterzumachen. Neuer Test für die Wiederverwendung.

### `PERF-62` — Timer sauber stoppen

`lua/mdview/bindings/autocmds/live_push.lua:53` · `cancel_pending` · confidence **medium**

**Befund.** `pending_timer:close()` is called bare -- no `pcall`, and no `is_closing()` guard, unlike the same repo's inbound_poll.lua:462-467 which does `timer:stop(); if not timer:is_closing() then timer:close() end`. Separately, `cancel_pending()` is never called on teardown: bindings/autocmds/init.lua:112-123 resets selection_sync and stops inbound_poll but leaves live_push's trailing timer armed.

**Regelbezug.** PERF-62 spells out `timer:stop()` + `pcall(timer.close)` as the required shape, and the point of the rule is that a debounce timer must be deterministically torn down rather than left to chance.

**Auswirkung.** The trailing debounce timer is not torn down with the session, and the bare close() departs from the rule's required pcall shape. But the auditor's headline scenario is far narrower than stated and I could not make it routine: arming the trailing timer needs a second TextChanged inside the 150ms window (live_push.lua:155-163), and the timer then fires within that same ≤150ms — so the described cascade requires `:MDView stop` to be issued inside a sub-150ms window, which is not typeable by hand and needs a single-key mapping plus a fast repeat to hit at all. When it does hit, the consequences are as described: the callback calls push_now on the stopped session, stop.lua:50's reset_ready() forces a real /health poll, and wait_ready runs the full 15s at 200ms intervals, echoing "[mdview] waiting for server, attempt N..." every 10 attempts before the red "server health-check timed out after 15000ms". Treat this as a shape/teardown defect to fix, not a bug users are hitting.

**Status.** ✅ erledigt (`3e6ac77`) — `cancel_pending()` schließt den Timer jetzt per `timer:stop()` + `pcall(timer.close)` (statt bare `close()`) und wird jetzt auch aus `bindings/autocmds.teardown()` aufgerufen, sodass der nachlaufende Debounce-Timer die Session nicht überlebt.

### `SEC-35` — Nutzereingabe nie in einen `-c`-/`:execute`-String

`scripts/mdview-bg.sh:81` · `mdview-bg` · confidence **medium** · _Testcode_

**Befund.** `CMD="MDView standalone $FILE"` followed by `exec "$NVIM" --headless -u "$INIT" -c "$CMD" -c "qa!"` -- the user-supplied filename is concatenated into an Ex command string rather than passed as an argument. scripts/mdview-bg.ps1:66 does the same.

**Regelbezug.** SEC-35 verbatim: inside a `-c "..."` argument, `|` starts a new Ex command, so a path from the user's hand must never be pasted into one. `|` is a legal filename character on Linux/macOS, and the script's own readability check at line 61 confirms such a file exists before the command is built.

**Auswirkung.** A markdown file whose name contains `|` — legal on Linux and macOS — has everything after the pipe parsed as a separate Ex command by the launcher Neovim, executed under -u scripts/minimal_init.lua with the user's privileges. Realistic route: previewing a file from an untrusted archive or a download whose name the user did not inspect. The same value also reaches vim.fn.expand() in detached.lua:101 once the Ex command runs, so a backtick in the name reaches &shell on the same path. The .ps1 twin has the same defect via PowerShell string interpolation into -c.

**Status.** ✅ erledigt (`d3c7684`) — Beide Skripte (`mdview-bg.sh`, `mdview-bg.ps1`) bauen den `:MDView standalone`-Aufruf nicht mehr per String-Konkatenation in ein `-c`-Ex-Kommando; der Dateiname läuft jetzt über eine Umgebungsvariable, gelesen von einem festen Lua-Snippet über `vim.env` — Vims Ex-Kommando-Parser sieht den Nutzerwert nie.

### `SEC-46` — Beim String-Literal-Einbetten das Escape-Zeichen **zuerst** escapen

`lua/mdview/adapter/browser/init.lua:99` · `open_default` · confidence **medium**

**Befund.** The generated focus-restore script embeds the temp path into a PowerShell single-quoted literal with no escaping: `(";Remove-Item -LiteralPath '%s' -ErrorAction SilentlyContinue"):format(tmp)`, where `tmp = fn.tempname() .. ".ps1"` and therefore contains the user's profile directory.

**Regelbezug.** SEC-46 names PowerShell explicitly and states its escaping rule -- PowerShell doubles `'` inside a single-quoted string. Nothing here escapes anything, so a quote in the path closes the literal and the remainder is parsed as PowerShell source.

**Auswirkung.** For a Windows account whose name contains an apostrophe (legal in Windows account names, e.g. O'Brien), tempname() yields a %TEMP% path carrying that quote, the single-quoted literal closes early, and the whole .ps1 fails to parse. The user-visible effect: browser.focus = "nvim" silently never restores focus to Neovim — the pcall'd jobstart at 105 succeeds, powershell exits non-zero, and nothing reports it. The tab itself still opens (rundll32, line 117, is independent), so nothing looks broken. One correction: the leftover .ps1 files do NOT accumulate indefinitely — fn.tempname() returns a path inside Neovim's own per-process temp directory, which Neovim removes on exit, so the orphans are session-scoped, not permanent %TEMP% litter.

**Status.** ✅ erledigt (`cdfbb2e`) — Der Temp-Skript-Pfad wird vor dem Einbetten in das PowerShell-Single-Quote-Literal escaped (`'` → `''`), damit ein Apostroph im Windows-Profilpfad (z. B. Kontoname „O'Brien“) das Literal nicht vorzeitig schließt.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/mdview/health.lua:84` · `M.check` · confidence **medium**

**Befund.** `local wasm = vim.fn.glob(dir .. "/assets/*.wasm", true, true)` feeds a raw directory path (`stdpath('data')/mdview/bin/<version>/client`) straight into glob, whose argument is a pattern: `~`, `[`, `]`, `?`, `{}` in the path are interpreted, not matched literally.

**Regelbezug.** XP-01 exactly: 'für "liste die Dateien in diesem Verzeichnis" nie glob mit einem rohen Pfad füttern' -- the sanctioned replacement is `lib.nvim.fs.globbable`, which mdview already hard-depends on. The failure mode is an empty list with no error, so nothing downstream can tell it apart from a genuinely empty directory.

**Auswirkung.** Where the resolved data path contains a glob metacharacter, :checkhealth reports a false failure: has_index (line 83, filereadable — unaffected) is true, #wasm is 0, and lines 95-98 emit the error "client bundle at <dir> is incomplete (no .wasm in assets/)" with the advice "Delete the cache dir and re-run :MDView start to re-download" — telling the user to throw away an intact bundle. Correcting the auditor's trigger list: `[` and `]` cannot appear in a Windows account name (Windows rejects them), so the Windows-profile vector is not real. What remains is a Linux/macOS home or an XDG_DATA_HOME containing `[`, `]`, `{`, `}` or `?`, a short-path XDG_DATA_HOME with a `~1` component, or an install.version string carrying a metacharacter. Blast radius is checkhealth only — nothing else in lua/ reads this glob, so the bundle itself keeps working.

> **Abdeckung dieses Laufs.** Scope covered: all 81 Lua modules under lua/mdview/ (~9.5k LOC) read in full or near-full, plus plugin/mdview.lua, scripts/ (minimal_init.lua, mdview-bg.sh, mdview-bg.ps1), .busted, package.json and the CI workflow. Per instructions I skipped .claude/, .git/, .deps/ and doc/tags.

Not covered, and why: (1) the three non-Lua components -- the Go relay (native/server), the Rust/WASM renderer (native/wasm-render) and the TypeScript client (src/client) -- are outside a Lua rule audit, so the server-side half of SEC-40 (whitelist validation on the relay's HTTP surface), SEC-23 (the client's comrak+ammonia sanitization, already credited in the Belege) and the /toggle, /field and /nav endpoints' own input handling were not inspected; my inbound_poll findings only concern what the Lua side does with what the relay hands it. (2) The 24 TypeScript specs under TESTS/client/ were not read. (3) The Lua specs under TESTS/lua and TESTS/nvim were only skimmed (TESTS/nvim/harness.lua read in full) -- I looked for XP-06 module-path casing breaks and found none, but I did not audit the specs themselves, so the test-code side of this report is thin by choice rather than because it is clean. (4) CMT-16: I did not establish which files under docs/ are renderer-generated (docs/BINDINGS.md is a plausible candidate), so I neither confirmed nor cleared hand-edits into generated output.

Three things I saw but did not file as findings, because no rule in the 76 covers them cleanly: (a) helper/gen_token.lua builds the relay's session auth token from `math.random` seeded with hrtime -- Lua's PRNG is not a CSPRNG, and this token is the only thing keeping other local processes off /update and /ws; worth a look even though SEC-15 is about key storage, not generation. (b) core/breadcrumbs.lua's `M.entries` grows unbounded for the whole session with no count cap. (c) package.json's `test:lua` script ends in `|| true`, so a developer running it locally never sees a nonzero exit (CI runs busted directly and is unaffected).

Rules I checked and found genuinely satisfied rather than inapplicable, so they are absent from both lists: LUA-06 (config/DEFAULTS.lua is pure data, no module-level env/FS resolution), ERR-50/ERR-51/ERR-53 (already credited to this plugin in the Belege; the code in front of me still honours them), SEC-20 (install.lua verifies sha256 against checksums.txt and deletes on mismatch), PERF-80 (adapter/log.lua is meticulous about the fast-event context, and both timers use vim.schedule_wrap), LUA-16 (no raw vim.NIL reaches a buffer write), ERR-33/LUA-13 (buffer_switch.resync re-validates its handle; previewable.is is pcall-guarded throughout, which covers the deferred callers).

All line numbers were re-verified against the files after drafting.

**Status.** ✅ erledigt (`f179dbe`) — `vim.fn.glob` läuft jetzt über `lib.nvim.fs.globbable(dir)`, damit ein Metazeichen im aufgelösten Client-Verzeichnis (kurzer 8.3-Windows-Pfad, `install.version`-String) nicht mehr zu einer stillen Leerliste und einer falschen „Bundle unvollständig“-Meldung in `:checkhealth` führt.

---

## lib.nvim

**17 Befunde** (11 × high). Roh gemeldet: 18. — **Stand: 17/17** (⏭️ 0, 2026-09-18)

### `ERR-03` — Explizite Rückgaben

`lua/lib/nvim/cache/disk.lua:128` · `M.save` · confidence **high**

**Befund.** `M.save` opens the file, calls `file:write(encoded)` and `file:close()` and then unconditionally `return true, nil` — neither the write nor the close return value is inspected, and the write goes straight onto the live path (`io.open(path, "w")`, truncating) rather than through a tmp+rename like the sibling `fs/json.write` does.

**Regelbezug.** ERR-03/PRIN-20 require relevant functions to return true/false plus an error object rather than failing silently. `M.save`'s signature promises `(boolean ok, string|nil err)` but the only failure it can ever report is a failed `mkdir` or `io.open`; Lua buffers writes, so ENOSPC/EIO/EROFS surface on `file:close()`, which is the one call whose result is discarded.

**Auswirkung.** On ENOSPC/EIO/EROFS the buffered write surfaces on `file:close()`, whose return value is discarded, so `disk.save` reports `ok = true` over a truncated or empty file that `io.open(path, "w")` has already emptied. `store.project.save`, `frecency:flush` and `telemetry.store.save` all propagate that false success and never retry. The auditor's chain to ERR-11 is accurate but note the follow-on is bounded: the next `read_entry` backs the truncated bytes up to `.corrupt` before handing back an empty table (lines 78-91), so what is lost is the original content of THIS write, not silently the whole history.

**Status.** ✅ erledigt (`f816d88`) — `save()` prüft jetzt die Rückgaben von `file:write` und `file:close` und meldet `write failed: …`/`close failed: …` statt `true` über einer abgeschnittenen Datei.

### `ERR-03` — Explizite Rückgaben

`lua/lib/nvim/fs/write/to_file/init.lua:29` · confidence **high**

**Befund.** The library's primary synchronous write primitive does `f:write(content)` then `f:close()` and returns `true, nil` without checking either result. `lua/lib/nvim/fs/write/append/init.lua:30` is the identical shape.

**Regelbezug.** ERR-03 forbids silent failures in functions that declare a success/error contract. Both files are documented as `---@return boolean ok, string|nil err`, so a caller is entitled to treat `ok == true` as "the bytes are on disk" — which this code cannot establish, since the flush that would reveal the error happens inside the unchecked `f:close()`.

**Auswirkung.** Every caller of the library's primary synchronous write gets `ok = true` for a write whose flush error was discarded at `f:close()`. The `fs/json.write` case is the sharpest: line 54 accepts the unchecked `true`, line 59 renames the (possibly truncated or empty) `.tmp` over the real file, and `M.write` returns success — good data replaced by a partial blob with a success return. This is the same primitive `scan_roots`' disk cache and every `fs.path:write` consumer sits on.

**Status.** ✅ erledigt (`f816d88`) — Beide Schreibprimitiven (`to_file`, `append`) prüfen `write`/`close` und geben den Fehler zurück; damit renamed `fs/json.write` keine leere `.tmp` mehr über die echte Datei.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/lib/nvim/frecency/init.lua:114` · `entries` · confidence **high**

**Befund.** `entries()` does `local loaded = disk.load(namespace, disk_opts); cached = type(loaded) == "table" and loaded or {}` — and `cache.disk.load` returns plain `nil` for "no file yet", "io.open failed", and "JSON corrupt" alike, so all three collapse to an empty in-memory table that `flush()` (line 204-212) then writes back over the whole file via `disk.save`.

**Regelbezug.** ERR-11 requires a function whose result may legitimately be empty to make "empty, but ok" distinguishable from "empty, because broken". Here the store cannot tell a first run from a failed read, and the module's own header docs say these counts "accumulate over months of real use and cannot be regenerated" (which is why it lives under stdpath("data"), not cache). `cache/disk.lua`'s `read_entry` writes a `.corrupt` backup only on a *decode* failure with non-empty content — an `io.open` failure returns nil at line 76 with no backup at all.

**Auswirkung.** If `io.open(path, "r")` fails transiently (sharing violation from a sync client/AV/second Neovim, permission error), `entries()` yields `{}` with no error and no `.corrupt` backup; the next `record()` sets `dirty` and the `VimLeavePre` flush replaces months of accumulated visit counts with a one-entry file, silently. The JSON-corruption path is partly protected — `read_entry` does write a one-time `.corrupt` backup (lines 80-89) before returning nil — so there the bytes survive, but the user is still never told, and the live file is still overwritten. The auditor's framing is right; the concrete unprotected case is narrower than "all three": it is the io-error case that loses data outright, and the corrupt case that loses it visibly-only-if-you-know-to-look-for-a-.corrupt-file.

**Status.** ✅ erledigt (`bf49279`) — `cache.disk.load` liefert additiv einen zweiten Wert (`nil` bei fehlend/abgelaufen, `read failed: …`/`invalid json: …` sonst); `frecency` warnt einmal, `flush()` verweigert das Überschreiben bei Lesefehler (Visits bleiben pending), bei korrupter Datei wird geschrieben, weil ein `.corrupt`-Backup existiert. Nebenbefund: `read_entry` unterscheidet jetzt per `uv.fs_stat` „Datei fehlt“ von `io.open`-Fehler.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/lib/nvim/fs/collect_recursive/init.lua:75` · `walk / M.collect` · confidence **high**

**Befund.** `walk` opens the directory with `local handle = uv.fs_scandir(dir)` and, when that fails, `if not handle then return end` (lines 75-78) — the libuv error is discarded and the walk proceeds as though the directory were empty. `M.collect` (lines 108-115) is declared `---@return string[]` with no error channel at all, so "the root was empty" and "the root does not exist / is not readable" both come back as `{}`.

**Regelbezug.** ERR-11 requires a function whose result may legitimately be empty to make "empty, but ok" distinguishable from "empty, because broken". This is the walk underneath `fs.scan_cached`, `fs.scan_roots` and `harvest.scope`'s directory sources, so the ambiguity propagates to every consumer of those.

**Auswirkung.** A scan of a root that is momentarily unavailable — unmounted share, permission-denied directory, path typo — returns an empty list indistinguishable from an empty tree, and the caller has no way to ask which it was. Chained with `scan_roots`, line 79 then persists that empty list to `opts.cache_path` as a legitimate result; with `ttl_seconds` unset (the documented never-expires default) that "this project has no files" answer is returned across restarts until the JSON is deleted by hand. Note the failure is per-directory, not only per-root: a single unreadable subdirectory mid-walk is skipped just as silently, which the finding understates.

**Status.** ✅ erledigt (`db3c147`) — `collect`/`files`/`dirs` und die `_async`-Callbacks liefern `errors` (`<dir>: <reason>` pro unlesbarem Verzeichnis, Root inklusive); `scan_cached`/`scan_roots` reichen es durch und cachen fehlerhafte Läufe nicht, `harvest.scope` meldet es als `err`.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/lib/nvim/bindings/keymap/registry.lua:243` · `M.register` · confidence **high**

**Befund.** `M.register` stores its result array into the module-level registry with `registered[key] = bound` (line 243) and then hands that same table back to the caller at line 349 (`return bound`), documented only as `---@return Lib.Keymap.Registered[] bound # What was actually bound, in declaration order.` — no copy, no "live reference, do not mutate" caveat.

**Regelbezug.** ERR-54: a public accessor that returns internal shared state by reference must either copy before handing it out or explicitly document the live reference. Neither happened, and the registry is read back by `:checkhealth`, `M.conflicts()` and the generated bindings docs (stated in the module header and in `M.registered`'s docstring).

**Auswirkung.** This is the exact ERR-54 hazard from the rule's own Beleg. `table.sort(keymap.register(...))` or `table.remove(keymap.register(...), i)` by a consumer rendering its own keymap list permanently reorders or shortens the registry array for the session, and because `M.registered` shallow-copies from that same array the new order is what `:checkhealth`, `M.conflicts()` and the generated `docs/BINDINGS.md` see afterwards. No in-repo consumer does this today, so the defect is contractual rather than currently firing — but the return value carries no warning that would stop one.

**Status.** ✅ erledigt (`5a56b1b`) — `register()` gibt `vim.list_extend({}, bound)` zurück statt des Registry-Arrays; Einträge sind als geteilte Live-Records dokumentiert (read-only by contract).

### `LUA-48` — Nur kollektierbare Typen sind schwach schlüsselbar

`lua/lib/nvim/cache/memory.lua:46` · `caches` · confidence **high**

**Befund.** `local caches = setmetatable({}, { __mode = "k" })` keyed by the namespace *name*, a string (`caches[name]` at lines 60-72), with the comment above it claiming "keyed weakly so an abandoned namespace ... can still be garbage-collected along with its entries". The per-namespace backing store created at line 61 is `setmetatable({}, { __mode = "k" })` too, keyed by whatever `key` the caller passes to `ns.get`/`ns.set` — the module's own usage example and its in-repo consumer `fs/scan_cached` both pass strings (`root .. ":" .. kind`).

**Regelbezug.** LUA-48: `__mode` only affects collectible-with-identity types. Lua 5.1/LuaJIT explicitly does not remove strings from weak tables (they have no explicit construction), so both tables behave exactly like strong tables. The documented "entries are garbage-collected automatically" claim is false, which is the precise failure the rule describes. There is no compensating cleanup for `caches` itself: `setup_auto_invalidation` (line 177-204) only empties each namespace's *entries* and never removes a namespace, and `stats[name]` at line 49 is an ordinary strong table.

**Auswirkung.** Both weak metatables are no-ops for the documented string-key usage, so the comment a consumer reads before deciding they need no invalidation is false. A namespace created without `opts.ttl` and without the opt-in `setup_auto_invalidation()` sweep never drops an entry for the whole session — one retained value per distinct key ever seen. The `caches`/`stats` tables themselves also never shrink, so a caller that mints namespace names dynamically leaks a stats record per name. This is a monotonic memory leak, not a correctness bug.

**Status.** ✅ erledigt (`1b411e1`) — `caches` ist eine normale Tabelle, der falsche GC-Kommentar ist ersetzt; der Per-Namespace-Store behält `__mode="k"` mit präzisem Kommentar, README dokumentiert die echte Lebensdauer.

### `PERF-46` — Cache-Key vollständig

`lua/lib/nvim/fs/scan_cached/init.lua:39` · `M.scan / M.scan_async` · confidence **high**

**Befund.** The cache key is built as `local key = root .. ":" .. kind` (line 39, repeated at line 72 in `scan_async`), but the scan itself is run as `collect_recursive.collect(root, { kind = kind, ignore = opts.ignore })` — `opts.ignore`, a predicate that decides which paths are emitted, is not part of the key.

**Regelbezug.** PERF-46 requires the key to contain every parameter that influences the result, otherwise the cache silently returns results computed for a different configuration of the same input. `opts.ignore` demonstrably changes the returned list (it is the `ignore` callback `walk` consults per entry in `collect_recursive/init.lua:92,101`) and is entirely absent from the key.

**Auswirkung.** Within the TTL (default 5s, line 27), two callers scanning the same root with different `ignore` predicates share one cache entry: whichever ran first wins, and the second silently gets a list computed under the other's filter. A caller with no predicate can receive a pruned list (missing files it should see) or, in reverse, a caller with a prune predicate can receive the unfiltered list and walk into `node_modules`/`.git`. The auditor's line reference into collect_recursive (92,101) is off by two — the ignore calls are at 90 and 100 — but the substance holds.

**Status.** ✅ erledigt (`c0bb691`) — Key enthält jetzt `root:kind:<ignore-identity>`; der Cache-Eintrag hält die Predicate-Referenz (keine Adress-Wiederverwendung nach GC) und ein Hit prüft sie erneut.

### `PERF-46` — Cache-Key vollständig

`lua/lib/nvim/fs/scan_roots/init.lua:52` · `M.scan / M.scan_async` · confidence **high**

**Befund.** The on-disk cache is addressed solely by the caller-supplied `opts.cache_path`; the payload written at line 79 is `{ saved_at = os.time(), paths = merged }`. Neither `roots`, nor `kind` ("files"/"dirs"/"all"), nor `ignore_dirs` is stored or compared on read (lines 51-59) — the only freshness test is the timestamp.

**Regelbezug.** PERF-46: all three omitted values change `merged`. A single `cache_path` reused with different roots, a different `kind`, or a different ignore list returns the previous run's answer as if it were this run's.

**Auswirkung.** One `cache_path` reused with different roots, a different `kind`, or a different `ignore_dirs` returns the previous run's list as if it were this run's, and because the cache is a JSON file on disk the wrong answer survives Neovim restarts. The severity depends on callers actually reusing one `cache_path` across differing parameters — nothing in lib.nvim itself does, so this is a latent trap for consumers rather than an active bug in this repo.

**Status.** ✅ erledigt (`c0bb691`) — Cache-Payload speichert `roots`, `kind`, `ignore_dirs`; ein Read mit abweichenden Werten ist ein Miss (alte Dateien ohne diese Felder werden einmal neu geschrieben).

### `SEC-21` — Timeout **und** Byte-Limit

`lua/lib/nvim/net/curl/init.lua:171` · `build_argv / M.download` · confidence **high**

**Befund.** `build_argv` assembles the full curl argv starting at `local argv = { "curl", "-sS", "-X", opts.method or "GET" }` and never adds `--max-filesize` (or `--max-time`) anywhere in the function; there is no corresponding option in `Lib.Net.Curl.FetchOpts` either. The only bound is `opts.timeout_ms`, which is optional with no default — it is passed through verbatim at lines 394, 456, 501 and to `:wait(opts.timeout_ms)` in the blocking variants.

**Regelbezug.** SEC-21 requires a download to have a timeout *and* a byte limit, not one of the two. Here the byte limit does not exist at all, and the timeout defaults to none. `remove_partial` (line 300) correctly deletes an aborted download, which is the other half of the rule and is satisfied — but it only runs once curl has already finished writing.

**Auswirkung.** `M.download(url, dest, opts, cb)` called without an explicit `timeout_ms` streams an unbounded body to disk with no wall-clock limit; `remove_partial` only runs once curl has exited, so a hostile or misbehaving endpoint can fill the filesystem first. `fetch_raw_blocking`/`fetch_json_blocking` with no `timeout_ms` call `:wait(nil)` and block the Neovim UI until curl returns. SEC-21 wants both bounds plus a URL-hashed cache; here the byte limit is absent entirely, the timeout is opt-in with no default, and only the delete-on-abort half is satisfied.

**Status.** ✅ erledigt (`8e9a608`) — Neue Option `max_bytes` → `--max-filesize`; `download*` defaulten auf 512 MiB und `timeout_ms` auf 5 min (`false` hebt auf), Fetch-Tiers bleiben opt-in. Der von SEC-21 zusätzlich genannte URL-gehashte Re-Fetch-Cache ist bewusst nicht gebaut (eigene Schicht mit API-Entscheidungen, kein Audit-Fix).

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/lib/nvim/harvest/scope.lua:222` · `M.resolve (kind == "path")` · confidence **high**

**Befund.** The `path` scope does `local p = vim.fs.normalize(vim.fn.expand(raw))` where `raw = opts.path`. The public entry point feeding it, `M.resolve_token` (line 245-254), is documented as "treat a free-form token the way a user command would" and routes anything that is not `cwd`/`buffers`/`buffer`/`range`/`%` straight into `opts.path`.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on buffer/user text: a backtick span in the argument is a command substitution through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. The rule names `lib.nvim.cross.fs.expand_path` as the replacement — which this very repository ships at `lua/lib/nvim/cross/fs/expand_path/init.lua` and does not use here.

**Auswirkung.** Any user command routed through `harvest.scope.resolve_token` runs the contents of a backtick span in the argument as a shell command before any file is read, and resolves a `%` or `#` token to the current/alternate buffer name rather than a file of that literal name. The exposure is contingent on a consumer wiring a command argument into `resolve_token`/`resolve("path")` — which is exactly what the function is documented for — rather than being reachable today from a command shipped inside lib.nvim itself.

**Status.** ✅ erledigt (`db69872`) — `vim.fn.expand(raw)` → `lib.nvim.cross.fs.expand_path(raw)`; Spec prüft, dass `%` literal bleibt und ein Backtick-Span keine Marker-Datei erzeugt.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/lib/nvim/harvest/sink.lua:49` · `M.file` · confidence **high**

**Befund.** `M.file` does `return to_file(vim.fs.normalize(vim.fn.expand(path)), text)`. `path` reaches it from `harvest.emit(text, out, opts)` (`lua/lib/nvim/harvest/init.lua:60-68`), which parses `out:match("^(file):(.+)$")` — the module header calls this "mapping a user-supplied `out=` token to a sink" and cites `out=file:/tmp/x.md` as the intended usage.

**Regelbezug.** Same SEC-34 violation on the write side: the destination path is user-command text, and `vim.fn.expand` runs backtick spans through the shell before the path is ever used. `lib.nvim.cross.fs.expand_path` exists in-repo and handles `~`/`$VAR`/`%VAR%` with no shell, no globbing and no Vim specials.

**Auswirkung.** The destination path of an export is user-command text passed through Vim's filename expansion: a backtick span in the `out=file:` token runs as a shell command at export time, and `out=file:%.md` writes to the current buffer's name instead of a file called `%.md`. Same contingency as the scope finding — it needs a consumer command that forwards its `out=` token, which is the documented usage.

**Status.** ✅ erledigt (`db69872`) — Gleicher Tausch für den `out=file:`-Pfad; Spec schreibt eine Datei namens `%.md`.

### `ERR-02` — Type Guards & Literal Checks

`lua/lib/nvim/cross/run/init.lua:65` · `M.run / M.run_blocking` · confidence **medium**

**Befund.** Both `vim.system` paths build the argv by hardcoding exactly three positional slots: `{ sh.prog, sh.args[1], sh.args[2], sh.args[3], cmd }` (line 65, and again at line 110). `M.shell()` returns four args on Windows — `{ "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command" }` (lines 13-18) — so `sh.args[4]`, i.e. `-Command`, is silently dropped; and it returns one arg on POSIX (`{ "-lc" }`), so `sh.args[2]`/`sh.args[3]` are `nil` and the table is constructed with holes before `cmd`. The legacy `jobstart`/`systemlist` branches in the same functions do it correctly with `table.concat(sh.args, " ")` (lines 73, 118), so the two branches of each function disagree about what argv they build. `lua/lib/nvim/cross/copy_to_clipboard/init.lua:108` repeats the same three-slot spread.

**Regelbezug.** ERR-02 requires type/nil checks before API access rather than indexing blind. Here a variable-length list is consumed through fixed indices with no length check, and the result is handed straight to `vim.system`. That the POSIX case works at all depends on `vim.list_slice` compacting the nil holes away inside Neovim's `vim.system` — an implementation detail, not a property this code establishes.

**Auswirkung.** On native Windows every `cross.run.run`/`run_blocking` spawns `powershell -NoProfile -ExecutionPolicy Bypass <cmd>` with `-Command` missing. Correcting the auditor: `prog` is hardcoded `"powershell"` and never `pwsh`, so the pwsh/`-File` breakage they describe cannot occur here, and powershell.exe 5.1 binds a trailing bare string to `-Command` implicitly, so the common case still runs — the calls work by accident, not by construction. What actually breaks is a `cmd` whose first token powershell parses as a parameter (consumed as a switch instead of executed), and the POSIX branch depends on LuaJIT's `#` returning 5 for a table with nil holes so that `vim.list_slice` compacts them — an implementation detail this code never establishes. `copy_to_clipboard`'s `$input | Set-Clipboard` path carries the same construction.

**Status.** ✅ erledigt (`a2de47c`) — Neues `cross.run.argv(cmd)` hängt Shell, alle `shell().args` und `cmd` an; `run`, `run_blocking` und `copy_to_clipboard` nutzen es, `-Command` geht nicht mehr verloren. Wiederverwendbar für jeden Plugin-Code, der `sh.args[1..3]` spreadet.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/lib/config/init.lua:40` · `M.setup` · confidence **medium**

**Befund.** `M.setup` merges first — `M.options = vim.tbl_extend("force", M.options, opts or {})` (line 40) — and only afterwards checks the single field it knows about (`if not STRATEGY_MODULES[M.options.strategy]`, line 42). There is no known-keys table and no unknown-key report anywhere in the file; any key the user passes lands in `M.options` unexamined.

**Regelbezug.** ERR-50 requires config validation (unknown keys, "did you mean …") to run *before* the merge, precisely so a typo does not vanish into the defaults. Note the repository already has the machinery for this one layer down: `bindings/keymap/registry.lua` computes a Levenshtein `nearest()` suggestion for unknown keymap action names (lines 88-127). The config accessor does not use anything equivalent.

**Auswirkung.** `require("lib.config").setup({ startegy = "eager" })` is completely silent: the typo is stored as a real field on `M.options`, `strategy` stays `"metatable"`, and the user believes they switched aggregator strategies. `:checkhealth lib` reads the resolved strategy, not the keys that were ignored, so there is no diagnostic path. The blast radius is small — one option exists — but the failure mode is exactly the one ERR-50 names, and it is the config accessor of the library every other plugin depends on.

**Status.** ✅ erledigt (`adf5c5f`) — Unbekannte Keys werden vor dem Merge mit Levenshtein-Hint gemeldet (`startegy (did you mean strategy?)`) und nicht gespeichert; neue `TESTS/config_spec.lua`.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/lib/nvim/bindings/keymap/registry.lua:373` · `M.registered` · confidence **medium**

**Befund.** `M.registered` rebuilds the outer list(s) but copies entries by reference (`out[#out + 1] = e`, lines 378-381 and 387-396), while its docstring states outright: "Returns a **copy**, for that same reason -- mutating it does not reach either store."

**Regelbezug.** ERR-54 allows a live reference only when it is documented as one. This docstring documents the opposite of what the code does: the list is a copy, the `Lib.Keymap.Registered` entries inside it are the live registry objects shared with `registered[key]` and with `keymap.records.all()`.

**Auswirkung.** A consumer that normalizes entries in place — clearing `bound`, rewriting `desc`, setting `lhs` for display — mutates the registry that `:checkhealth`, `M.conflicts()` and the docs generator read afterwards, because only the containing list was copied. An unqualified "Returns a copy" invites exactly that reading. Nothing in this repo does it today, and every list-shaped mutation (sort, insert, remove) is genuinely safe, so this is a documentation-precision gap on a shallow copy, not the session-wide state corruption the auditor described.

**Status.** ✅ erledigt (`5a56b1b`) — Docstring/@types/README sagen jetzt exakt: Liste frisch, Einträge geteilte Live-Records — kein Deep-Copy eingeführt (Doku-Präzisierung, wie vom Befund selbst eingeordnet).

### `SEC-13` — Telemetrie erfasst Form, nie Inhalt

`lua/lib/nvim/telemetry/fingerprint.lua:36` · `M.value` · confidence **medium**

**Befund.** `if #v <= MAX_STRING then return ("%q"):format(v) end` with `MAX_STRING = 40` (line 21): any string argument of 40 characters or fewer is fingerprinted as its own verbatim value, not as a shape. Those fingerprints are accumulated per call site in `telemetry/registry.lua:92` and rendered into the report at `telemetry/report.lua:198`.

**Regelbezug.** SEC-13 requires telemetry to capture form rather than content — "Strings auf feste Länge kappen ... nie echte Werte serialisieren". The module header itself names the hazard ("file paths, buffer contents and possibly tokens") and is right about the >40 case, but the ≤40 branch stores the real value. The cap is doing double duty as both a size bound and a secrecy bound, and only works as the former.

**Auswirkung.** A string argument of 40 bytes or fewer is stored and rendered verbatim, and — contrary to the finding's own caveat — it is also written to disk under `stdpath("cache")`, which is precisely what the module header says a profiler must never do. A GitHub classic PAT (`ghp_` + 36 = exactly 40) sits on the boundary and is kept in full, in the `:Lib telemetry` report and in the cache file. Two limits on severity the auditor omits: argument profiling is opt-in per call site (`args = wrap_opts.profile_args or false`, `telemetry/init.lua:356`), and a secret passed inside an options table is fingerprinted as `<table:...>` by lines 40-47, so the leak needs a wrapped function that takes the secret as a direct string argument.

**Status.** ✅ erledigt (`af61d37`) — Strings jeder Länge werden als `<string:<len>:<fnv1a-8hex>>` gespeichert, nie als Text; pure-Lua-Digest (kein `vim.fn.sha256`, das in Fast-Event-Kontexten verboten wäre); `M.MAX_STRING` → `M.DIGEST_BYTES`. Kein anderes Repo nutzt `lib.nvim.telemetry.fingerprint` (runtime-analysis.nvim hat ein eigenes Modul), geprüft per grep.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/lib/nvim/bindings/autocmd/docs.lua:502` · `count_unregistered` · confidence **medium**

**Befund.** `local files = vim.fn.globpath(root .. "/lua", "**/*.lua", false, true) or {}` — a raw repository root is handed to `globpath` as a pattern. `root` comes from `repo_of(r.src)` in `write_all` (line 550) and is fed back at line 569 as `unregistered = count_unregistered(root)`, a number written into the generated autocmd documentation. The repository ships `lib.nvim.fs.globbable` for exactly this and does not use it here.

**Regelbezug.** XP-01: `globpath` reads its argument as a pattern, so a `~` in the path is a home-directory reference. Under Windows an 8.3 short root (`C:/Users/STEFAN~1/...` — what `%TEMP%` and `vim.fn.tempname()` expand to for any profile name over eight characters) makes glob try to resolve `~1` as a user, find none, and return an empty list with no error. `TESTS/autocmd_docs_spec.lua` builds its fake repo roots from exactly `vim.fn.tempname()` (lines 47, 80) and never asserts on `unregistered`, so nothing in the suite would catch it.

**Auswirkung.** `count_unregistered` returns 0 without error for a repo root that glob cannot read, and the generated autocmd document then states the repository creates no autocmds outside the module — the opposite of the truth, baked into a committed file. Correcting the auditor's scenario: their 8.3 example requires a Windows profile name over eight characters, which this machine's profile (`bartl`) is not, so `vim.fn.tempname()` here yields no `~` and the cited spec would not trip. The realistic triggers are a long Windows profile name, a repo path containing `[`, `]`, `?`, `*` or `{}`, or — specific to `globpath` and not mentioned by the auditor — a comma anywhere in the root, since `globpath` splits `{path}` on commas.

**Status.** ✅ erledigt (`07ca64d`) — `globpath` ersetzt durch `fs.collect_recursive.files(root .. "/lua")` mit `.lua`-Filter — kein Glob mehr, damit auch Kommata/Metazeichen unschädlich (nicht nur `~`).

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/lib/nvim/require/init.lua:72` · `require_dir` · confidence **medium**

**Befund.** `local files = vim.fn.glob(full_dir .. "/*.lua", true, true)` where `full_dir = vim.fn.stdpath("config") .. "/lua/" .. dir` (line 41) — both the stdpath prefix and the caller-supplied `dir` component go into the glob argument unprocessed, without `lib.nvim.fs.globbable`.

**Regelbezug.** XP-01: the argument is read as a pattern, so a `~` (8.3 short form) or any of `[`, `]`, `?`, `*`, `{}` in the resolved config path changes or empties the match. The code does check `#files == 0` and warn (lines 74-77), which is better than silence, but the warning says "No files found in <dir>" — it attributes the empty glob to a missing directory rather than to an unglobbable path spelling.

**Auswirkung.** Under a config path that glob reads as a pattern, `M.dir` loads nothing and every submodule under that directory silently never runs, while the warning blames a missing directory rather than an unglobbable path spelling. This is the weaker of the two XP-01 sites: `stdpath("config")` derives from `$LOCALAPPDATA`/`$XDG_CONFIG_HOME`, which Windows normally supplies in long form, so the 8.3 case needs both a long profile name and a short-form-resolved config root; a glob metacharacter in the config directory name is the more plausible trigger. It does warn rather than fail silently, which the rule's worst case does not.

> **Abdeckung dieses Laufs.** Scope: 481 Lua files / ~51,500 LOC under lua/, plus 62 spec files under TESTS/. I read roughly 6,800 lines closely; the rest was covered by pattern-directed grep only. .claude/, .git/, .deps/ and doc/tags were excluded as instructed.

Families I worked through with grep-then-read and found CLEAN (no finding, but verified by reading, not just by grep):
- PERF-62 (timer teardown): every debounce site does stop + pcall(close) + nil before starting a new timer — ui/kit/compare.lua:305-312, ui/kit/live_input.lua:59-70, ui/kit/picker.lua:85-91, debounce/init.lua:38-56. Exemplary.
- LUA-13 / ERR-33 (deferred handle revalidation): every vim.defer_fn body I traced revalidates — progress/styles/float.lua:50-54, progress/styles/kit.lua:46-50, ui/kit/surface.lua:80-85, ui/kit/chooser.lua:667-680 (which also checks a generation counter).
- PERF-92 (module-level geometry): all 29 vim.o.columns/lines reads are inside functions, computed per open. ui/statusline/init.lua:237 has the VimResized handler. The one gap I chose not to report: an already-open ui/kit float does not reflow on VimResized, but since geometry is recomputed per open and these are transient surfaces, that is a judgment call rather than the frozen-at-require case the rule targets.
- ERR-30: buffer/apply_edits.lua is a model implementation (bottom-up sort + `expect` re-verification against current text, skip on mismatch). `expect` being opt-in is a caller contract, not a defect in the primitive.
- SEC-30: vregex/init.lua correctly uses \V very-nomagic and escapes only backslash.
- SEC-10/11 (secrets in argv): net/curl routes Authorization/Cookie/private-token/bearer/auth and opt-in secret_headers through `-K -` on stdin, and documents the residual `opts.query` gap in-code and in TESTS/curl_spec.lua.
- ERR-11 done right: config/repo_file/init.lua returns distinct reason codes (read_failed / empty / invalid_json / not_object) — the pattern the two ERR-11 findings above are missing.
- PERF-07: no `local k = next(t); t[k] = nil` delete loops anywhere; cache/memory.lua:128-131 uses the correct `for k in pairs(t)` form and documents why it clears in place (PERF-47 satisfied).
- LUA-06: config/DEFAULTS.lua is a three-line pure-data table, no module-level env or FS resolution.
- LUA-17: no vim.g round-tripping of Lua objects; the vim.g uses are booleans and flat lists only.
- LUA-16: vim.NIL is handled centrally in nvim/json/init.lua:59.
- ERR-51: config/init.lua:35 uses vim.deepcopy(defaults).

Rules I could NOT cover and why:
- CMT-16: I did not compare docs/map, docs/BINDINGS.md or the autocmd/usercmd catalogs against their renderers. Establishing hand-edit drift needs a regeneration run, which is out of scope for a read-only audit.
- LLS-* beyond LLS-31: LuaLS diagnostics need an actual lua-language-server run, not reading.
- SEC-42, SEC-45, SEC-46, SEC-50, UI-01, UI-55, PRIN-01: I grepped for the surfaces (path sanitization, AppleScript/PowerShell string embedding, preview execution, bulk confirmations, nvim_buf_delete with visible windows) and found no call site that clearly engages the rule, but I did not read every candidate end to end. I would not call these verified clean.
- deps/ subtree (11 files: detect, install, pm, spec, status, view, first_run, health, require_tool) — read only far enough to confirm it shells out to package managers rather than downloading binaries itself. Its own config/validation surface is unaudited.
- bindings/usercmd/composer/ (13 files, the single largest subsystem here) and ui/kit/ (21 files) were audited only against the patterns the greps surfaced, not read module by module.
- No findings under TESTS/ or scripts/. TESTS/ was read only where it bore on a production finding (autocmd_docs_spec.lua, run_spec.lua, globbable_spec.lua, context_spec.lua) — the suite itself was not audited as code.

Two things I looked at and deliberately did NOT report:
- cache/disk.lua's read_entry collapsing missing/corrupt to nil: the Belege names lib.nvim (cache/disk.lua, read_entry) as already handled for ERR-11, and the `.corrupt` backup is in place as described. I report frecency separately because it is a distinct consumer whose own collapse is not covered by that backup on the io.open failure path.
- cross/fs/lock/init.lua's ensure_script() caching a .ps1 under stdpath("cache") and running it with `-ExecutionPolicy Bypass`: it check-then-creates (a weak ERR-31 shape) and never refreshes a stale script after a version upgrade. The content is a compile-time constant and the directory is the user's own, so I could not make either a concrete enough failure to report.

**Status.** ✅ erledigt (`07ca64d`) — `vim.fn.glob` ersetzt durch `vim.fs.dir` (Pfad, kein Pattern) + `isdirectory`-Check; die Warnung unterscheidet jetzt „No such directory“ von „No .lua files“.

---

## replacer.nvim

**17 Befunde** (8 × high). Roh gemeldet: 18. — **Stand: 17/17** (⏭️ 0, 2026-09-18)

### `ERR-02` — Type Guards & Literal Checks

`lua/replacer/export.lua:139` · `M.build_patch` · confidence **high**

**Befund.** `vim.text.diff(a, b, { result_type = "unified", ctxlen = 3 })` is called with no existence check and no fallback. `vim.text.diff` only exists from Neovim 0.11 (before that the function is `vim.diff`); `vim.text` itself is 0.10+. The plugin declares Neovim 0.9+ in README.md:17, docs/installation.md:7, doc/replacer.txt:41, and health.lua:53-70 actively certifies a 0.9 build as OK.

**Regelbezug.** ERR-02 requires a type/nil guard before an API access, especially against an API that is not present on every supported version. The single call site is unguarded, and it is not inside the pcall either -- init.lua:147 evaluates `export.build_patch(results)` as the argument to `show_diff_scratch`, outside that function's internal pcall.

**Auswirkung.** On Neovim 0.9-0.11 — every version `:checkhealth replacer` blesses — `:Replace old new --dry` throws at init.lua:147 ('attempt to index a nil value (field text)' on 0.9, 'attempt to call a nil value (field diff)' on 0.10/0.11), and `:Replace old new --export=out.patch` throws through the unguarded export.write_export at init.lua:137. Only .json exports survive. CI does exercise this (TESTS/feature_smoke.lua:1371 calls export.build_patch), so the failure is invisible only because `version: stable` in .github/workflows/ci.yml now resolves to 0.12 — the guard is missing, not the coverage.

**Status.** ✅ erledigt (`23ea472`) — `vim.text.diff` existiert erst ab Neovim 0.11; Fallback auf `vim.diff` (dieselbe Funktion unter altem Namen, vorhanden auf 0.9/0.10).

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/replacer/presets.lua:26` · `M.load / M.save` · confidence **high**

**Befund.** M.load() returns the same empty table `{}` for "presets.json does not exist yet" and "presets.json is present but failed to decode", and M.save() then does load -> mutate -> write-the-whole-file.

**Regelbezug.** ERR-11 requires "empty but ok" and "empty because broken" to be distinguishable; this is the exact load-modify-save collapse the rule's Belege calls the most common real bug class of the 32-repo sweep. The sibling file history.lua was fixed for this (it backs the raw bytes up to `.corrupt` before returning `{}` -- history.lua:50-55); presets.lua was never given the same treatment.

**Auswirkung.** If presets.json becomes undecodable (truncated write, hand-edit, partial disk write), the next `:ReplaceSavePreset name old new` calls M.load() -> `{}`, inserts the one new entry, and rewrites the whole file. Every other saved preset is gone permanently: no warning, no `.corrupt` backup (unlike history.json), no trace. `:ReplacePreset <old name>` afterwards reports only 'no such preset'. M.delete (79-86) has the same shape and would also flatten the file to one entry's removal against an empty base.

**Status.** ✅ erledigt (`9720bc1`) — Dekodier-Fehler sichert die Rohbytes jetzt nach `.corrupt`, statt beim nächsten Save/Delete alle Presets stillschweigend zu verlieren (Fix analog `history.lua`).

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/replacer/gitfiles.lua:132` · `M.list / step` · confidence **high**

**Befund.** `git_lines` is explicitly written to deliver `cb(lines, ok)` and returns `cb({}, false)` whenever git exits non-zero or the spawn fails (gitfiles.lua:26-41). The only caller binds a single parameter -- `function(lines) add_all(lines) step() end` -- and drops `ok` on the floor.

**Regelbezug.** ERR-11: the function's own signature distinguishes "no changed files" from "the git query failed", and the call site collapses both onto the same empty list. The error channel exists and is discarded.

**Auswirkung.** When `git diff --name-only` / `git diff --staged` / `git ls-files --others` fails (git not on PATH, locked or corrupt index, permission error on the repo), that kind contributes zero paths and nothing is reported. If all requested kinds fail, init.lua:424 prints '--changed: no changed files match the current scope' and returns — the user reads that as 'nothing changed', while the replace they asked for silently never ran. A partial failure (one of three kinds erroring) is worse: the run proceeds over an incomplete file list that looks authoritative.

**Status.** ✅ erledigt (`b417aad`) — `ok` aus `git_lines` wurde bisher verworfen; `M.list` meldet fehlgeschlagene Kinds jetzt über einen dritten `on_done`-Parameter, `--changed` warnt entsprechend.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/replacer/rg.lua:533` · `list_files / scan_file` · confidence **high**

**Befund.** `local ok, iter = pcall(vim.fs.dir, root, ...); if not ok or not iter then return end` -- an unreadable root directory returns silently with nothing appended. `scan_file` (rg.lua:561-564) does the same for an unreadable file. Neither `collect_vimgrep` nor `collect_vimgrep_async` has an error return: `M.collect` returns `items, err` with `err` hardcoded nil on the vimgrep path (rg.lua:844), and `collect_vimgrep_async` only ever reports an error for user cancellation.

**Regelbezug.** ERR-11: a result that can legitimately be empty must report "empty because nothing matched" differently from "empty because the scan failed". The native backend has no way to say the second thing.

**Auswirkung.** With the vimgrep backend (automatic whenever rg is not on PATH — health.lua:99 warns but permits it), any file the scanner cannot open is skipped with no record, and an unreadable root directory yields zero matches for that whole root. The mechanism is slightly different from the auditor's description: unreadable SUBdirectories are swallowed inside vim.fs.dir's own iteration and never reach this pcall at all, which makes the gap wider, not narrower. The user sees the ordinary 'no matches found' (init.lua:371) or a partial list that looks complete, and applies a project-wide rename believing it covered everything reachable.

**Status.** ✅ erledigt (`9ce4607`) — Unlesbare Root-Verzeichnisse/Dateien im vimgrep-Backend lösen jetzt `notify.warn` aus statt leise übersprungen zu werden. Bewusst über den bestehenden `notify`-Kanal statt über den überall fatalen `err`-Kanal — der wörtliche Befund-Vorschlag hätte einen guten Teilerfolg abgebrochen.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/replacer/fnames.lua:171` · `M.apply` · confidence **high**

**Befund.** `uv.fs_rename(m.old_path, m.new_path)` is called for every planned rename with no check that `m.new_path` is free. The plan was computed earlier from a single directory snapshot (M.collect, fnames.lua:80-114) and nothing re-verifies it against the current filesystem at write time.

**Regelbezug.** ERR-30 requires every edit computed during a scan to be re-verified against current state immediately before writing, and to be skipped on divergence rather than written blind. rename(2) (and MoveFileEx with REPLACE_EXISTING, which libuv uses on Windows) silently replaces an existing destination, so "blind" here means "destroys".

**Auswirkung.** `:ReplaceFNames foo bar` in a directory that already contains bar.lua destroys the existing bar.lua with no error: ok_rename is true, `renamed` increments, and the notification at fnames.lua:279-288 reports 'renamed N entries'. Nothing is written to `errors`, so nothing is shown. Confined to file-over-file (a dir-over-non-empty-dir rename fails with ENOTEMPTY). The same primitive is reused by `--also-rename-file` through rename_assist.lua:33 (`fnames.apply({ m })`), whose confirm prompt at rename_assist.lua:48-53 shows only 'Also rename foo.lua -> bar.lua?' and never mentions that bar.lua exists.

**Status.** ✅ erledigt (`e63e118`) — `M.apply` prüft das Rename-Ziel per `fs_stat` unmittelbar vor `fs_rename` und überspringt bei Kollision mit Fehlermeldung, statt blind zu überschreiben.

### `ERR-60` — `a and b or c` bricht, sobald `b` falsy sein kann

`lua/replacer/health.lua:226` · `check_config` · confidence **high**

**Befund.** `local picker_ok = (cfg.engine == "telescope") and pcall(require, "telescope") or pcall(require, "fzf-lua")` -- the middle operand `pcall(require, "telescope")` is itself `false` when telescope is not installed, so evaluation falls through to the `or` branch regardless of which engine was configured.

**Regelbezug.** ERR-60 verbatim: `a and b or c` yields `c` as soon as `b` is falsy, independent of `a`. Here `b` is a pcall result whose whole purpose is to be `false`.

**Auswirkung.** One concrete broken case: `engine = "telescope"`, telescope not installed, fzf-lua installed. picker_ok becomes true from the fzf-lua probe, the error at health.lua:229 never fires, and `:checkhealth replacer` prints 'Picker engine: telescope' as OK. That is the only check that would explain why every interactive `:Replace` dies with 'telescope.nvim not found' (pickers/telescope.lua:36). The engine="fzf" branch happens to produce the right answer by accident.

**Status.** ✅ erledigt (`da4037f`) — `a and b or c`-Kette (fiel bei fehlendem Telescope immer auf die fzf-lua-Probe zurück) durch explizites `if` ersetzt.

### `SEC-30` — Nutzereingabe literal escapen

`lua/replacer/checkpoint.lua:57` · `read_current` · confidence **high**

**Befund.** `vim.fn.bufnr(path)` is called with a raw absolute file path. `bufnr()` treats a String argument as a |file-pattern| (matched with 'magic' set), not as a literal path, so the path is handed to Vim's regex engine unescaped.

**Regelbezug.** SEC-30 requires a pattern built from user-controlled text to be literal-escaped before it reaches the regex engine, precisely to prevent false matches. A file path is user-controlled text here, and `[`, `*`, `?`, `.` in it are regex operators; substring matching also lets an unrelated buffer whose name merely contains the path win.

**Auswirkung.** During `:Replace! old new --checkpoint`, any target file that is NOT itself loaded but whose path is a prefix of (or a magic-pattern match for) some loaded buffer's name causes read_current() to snapshot that foreign buffer's contents under the target's name. `:ReplaceUndo` then hands that content to write_exact (checkpoint.lua:186), which writes it byte-exactly over the real file — the undo feature destroys the file it was created to protect. Requires a colliding loaded buffer, so it is conditional rather than universal; the `[`/`*`/`?` variant additionally misfires on any target path containing those characters. rg.lua:100 (is_buffer_modified) can likewise route a whole search into the wrong buffer's contents, and export.lua:27 builds the dry-run plan from the wrong file.

**Status.** ✅ erledigt (`e63e118`) — `vim.fn.bufnr(path)` (Regex-Pattern-Matching) durch literalen Abgleich über `nvim_list_bufs()`/`nvim_buf_get_name` ersetzt. Nebenfund: eine fünfte, vom Audit nicht benannte `vim.fn.bufnr(path)`-Stelle in `checkpoint.lua:188` (`M.undo`) gehört derselben Klasse an, wurde aber bewusst nicht mitgefixt (außerhalb der 17 gemeldeten Befunde) — lohnt ein Folge-Audit.

### `SEC-30` — Nutzereingabe literal escapen

`lua/replacer/fnames.lua:185` · `M.apply` · confidence **high**

**Befund.** After a successful file rename, `local bufnr = vim.fn.bufnr(m.old_path)` resolves the buffer to follow -- again handing a raw path to `bufnr()`, which matches it as a |file-pattern| rather than as a literal name.

**Regelbezug.** Same SEC-30 violation as checkpoint.lua:57, but the consequence is a write-side one: the resolved (possibly wrong) buffer is then renamed in place via `nvim_buf_set_name`.

**Auswirkung.** Renaming foo.lua -> bar.lua while foo.lua itself is not loaded but foo.lua.bak (or any buffer whose name the old path pattern-matches) is, re-points THAT buffer's name to bar.lua. The user is left with a buffer labelled bar.lua holding the .bak file's contents; the next `:w` overwrites the freshly renamed file with the wrong content. `:ReplaceFNames` reports 'renamed 1 entry' either way. When foo.lua IS loaded the full-match attempt wins, so this only fires on the near-miss case.

**Status.** ✅ erledigt (`e63e118`) — Gleicher Fix (`bufnr_exact`-Helper) wie #7, hier auf der Schreib-Seite (Buffer-Umbenennung nach Rename).

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/replacer/bindings/usrcmds.lua:52` · `M.setup` · confidence **medium**

**Befund.** `mod.register(entry.needs_run and run or nil)` is called outside any pcall -- only the preceding `require` is guarded. The module docstring (usrcmds.lua:41-43) claims "Each register() is pcall'd around its require ... one feature module failing to load must not cost the user :Replace itself". plugin/replacer.lua:12-14 likewise pcalls only the `require`, then calls `bindings.setup()` bare.

**Regelbezug.** ERR-01 requires a pcall at the system boundary, and `register()` is exactly that: every one of them calls into lib.nvim (`composer.verb`, `usercmd.create`) and into ui.nvim. The guard that was intended is one call short of where it needs to be.

**Auswirkung.** A throw from any register() — incompatible lib.nvim composer, verb-name collision, malformed route spec — aborts M.setup's loop at that entry. Every command later in M.REGISTRY is never created; for a failure in the third entry (replacer.regex) that means ReplaceRoot, ReplaceUndo, ReplaceHistory, ReplacePreset, ReplaceSavePreset, ReplaceBatch and ReplaceFNames all silently do not exist. The error propagates out of plugin/replacer.lua as a startup sourcing error, and because the flag is set after setup() returns, vim.g.__replacer_cmd_registered stays unset and the whole failure repeats on every reload.

**Status.** ✅ erledigt (`64440a3`) — `register()` selbst wird jetzt gepcallt, nicht nur das vorangehende `require`; ein fehlschlagendes Modul bricht die Registrierungs-Schleife nicht mehr für alle nachfolgenden Kommandos ab.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/replacer/export.lua:103` · `M.build_results` · confidence **medium**

**Befund.** `local old_lines = read_lines(path)` -- `read_lines` is documented to return `lines, ok` (export.lua:25) and returns `{}, false` when the file cannot be opened (export.lua:32-33), but the sole caller binds only the first value.

**Regelbezug.** ERR-11: the second return value exists precisely to separate "this file has no lines" from "this file could not be read", and the only consumer discards it.

**Auswirkung.** An unreadable file in the match set contributes all of its matches to `totals.skipped` and none to `totals.spots`. The dry-run summary at init.lua:127-135 folds it into the generic '(N skipped)' bucket alongside genuinely stale matches, and the file is absent from `results`, so it appears in neither the diff scratch buffer (init.lua:147) nor an exported .patch/.json. One correction to the auditor: the real apply reads through the same pcall(io.open) at apply.lua:186 and would fail on that file too, so the plan is not understating what the apply will touch — it is presenting an unreadable file as a stale-match no-op, hiding the actual cause (permissions, a vanished file) behind a count the user has no way to interpret.

**Status.** ✅ erledigt (`2b17f5b`) — Zweiter Rückgabewert von `read_lines` wird jetzt ausgewertet; neues `totals.unreadable`-Feld, im Dry-Run-Text sichtbar statt im „skipped“-Topf versteckt.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/replacer/health.lua:234` · `check_config` · confidence **medium**

**Befund.** The `else` branch that reports `"Unknown engine: %s"` can never execute: `cfg` comes from `cfg_mod.get()`, and `validate` has already coerced any unrecognised engine back to the default via `as_engine(cfg.engine) or out.engine` (config/init.lua:188). The same holds for `search_engine` and `progress_style`, which are only ever printed with `health.info`.

**Regelbezug.** ERR-22 has two halves: degrade an invalid single value to its default (satisfied) AND make that degradation visible through `:checkhealth` (not satisfied -- the config module keeps no record of what it rejected, so health has nothing to surface and its warning branch is dead code).

**Auswirkung.** `setup({ engine = "telescpoe" })` silently degrades to engine='auto'. `:checkhealth replacer` then reports 'Picker engine: auto (resolves to fzf-lua)' and looks entirely healthy (health.lua:216-223), so a user who believes they configured telescope and keeps getting the fzf-lua picker has no diagnostic surface pointing at the typo. The warn branch that was written for exactly this is dead code.

**Status.** ✅ erledigt (`da4037f`) — `config.issues()` macht degradierte Einzelwerte (engine/search_engine/progress_style) jetzt über `:checkhealth` sichtbar; der bisher tote `else`-Zweig bleibt als Fallback stehen.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/replacer/config/init.lua:259` · `M.setup / validate` · confidence **medium**

**Befund.** `M.setup(opts)` merges first (`vim.tbl_deep_extend("force", {}, state, tbl(opts))`) and only then validates; `validate` builds its result from a fresh `vim.deepcopy(Defaults)` and cherry-picks a fixed list of known keys (config/init.lua:186-246). There is no unknown-key check anywhere, before or after the merge, and no "did you mean" reporting.

**Regelbezug.** ERR-50 requires unknown-key validation to run before the merge exactly so a typo in an option cannot disappear into the defaults unnoticed. Here it disappears twice over: it survives the merge into an intermediate table and is then dropped without a word by the key-by-key rebuild.

**Auswirkung.** `setup({ smartcase = false })` (typo for smart_case, config/init.lua:198), `setup({ preserve_ws = true })`, `setup({ max_filesize = 1000 })` and every other near-miss survive the merge into the intermediate table and are then dropped without a word by validate's key-by-key rebuild. The option silently has no effect for the life of the session and there is no diagnostic path: check_config (health.lua:204-261) reads back only post-validation values, which are the defaults.

**Status.** ✅ erledigt (`da4037f`) — `sanitize_keys()` verwirft unbekannte Top-Level-Keys vor dem Merge, mit Levenshtein-„did you mean“-Hinweis (Muster aus dap.nvim/mdview.nvim übernommen).

### `PERF-72` — Auto-erkannte Scan-Roots konservativ

`lua/replacer/root.lua:77` · `M.detect_best` · confidence **medium**

**Befund.** `detect_best` walks every ancestor directory up to the filesystem root collecting marker hits, then deliberately prefers the OUTERMOST candidate that contains a `.git` (`for i = #candidates, 1, -1 do ... return candidates[i]`). This is what the `root` scope token resolves to in command.lua:504, with no prompt.

**Regelbezug.** PERF-72 requires auto-detected scan roots to stay conservative and never default to a whole home directory or drive. Preferring the outermost `.git` does the opposite -- it picks the largest enclosing repository rather than the nearest one.

**Auswirkung.** Conditional on the user having a .git directly in $HOME (a dotfiles repo, common but not universal): `:Replace old new root` from any buffer under $HOME resolves the scope to $HOME itself rather than to the project the file belongs to, so the scan — and with `!`/--all the rewrite — covers the entire home directory. Same shape for a monorepo superproject when the user meant the submodule they are editing. Without a $HOME-level .git, detect_best is bounded by the outermost enclosing repository, which is over-broad but not catastrophic. `:ReplaceRoot` is unaffected: M.pick (106-124) prompts via ui.kit.select whenever there is more than one candidate.

**Status.** ✅ erledigt (`d77b80c`) — `detect_best` überspringt das Home-Verzeichnis als „outermost .git“-Kandidat und fällt auf den nächstgelegenen Marker zurück.

### `PRIN-25` — Eingaben validieren

`lua/replacer/debug.lua:177` · `M.register_command` · confidence **medium**

**Befund.** The command argument is lowercased once into `cmd` (debug.lua:164) for subcommand dispatch, and the `analyze` branch then extracts BOTH the line number and the search pattern out of that lowercased copy: `local lnum, pattern = cmd:match("^analyze%s+(%d+)%s+(.+)$")`. The original `arg` is still in scope and unused here.

**Regelbezug.** PRIN-25: the argument is mangled before it is worked with. The case fold is correct for the verb and wrong for the payload; the payload is passed on to `M.analyze_line`, which does a literal `line:find(pattern, pos, true)`.

**Auswirkung.** `:ReplaceDebug analyze 42 FooBar` searches line 42 for the literal string 'foobar' and reports no occurrences. Every pattern containing an uppercase letter — most identifiers, which is what this tool exists to investigate — gets a fabricated negative. The printed 'Pattern: ...' line (debug.lua:118) shows the lowercased form, so the output is at least self-consistent and a careful reader could spot it; the line number capture (%d+) is unaffected by the fold.

**Status.** ✅ erledigt (`2aa33ed`) — Suchmuster für `analyze` wird jetzt aus dem Original-`arg` extrahiert statt aus dem kleingeschriebenen `cmd`.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/replacer/presets.lua:63` · `M.as_request` · confidence **medium**

**Befund.** `M.as_request` copies `p.old`, `p.new`, `p.scope`, `p.overrides` and `p.filters` straight out of the decoded presets.json into a runnable RP_Request with no type check, no length cap and no count cap. `M.load` only verifies that the decoded top level is a table.

**Regelbezug.** SEC-33: a persisted snapshot is untrusted on load and every field must be re-validated (type, length, count cap) before use. Nothing here is re-validated, and the resulting request goes straight into the replace pipeline.

**Auswirkung.** A presets.json corrupted or hand-edited into the wrong shapes turns `:ReplacePreset <name>` into an uncaught Lua error rather than a clean rejection: numeric `old` throws at init.lua:95, a non-string entry in filters.globs/exclude throws at rg.lua:186. Two of the auditor's sub-claims are overstated: a non-table `filters.file_types` only throws for number/boolean values (a string passes through extend as a silent no-op, since `#s` and `s[i]` are both legal), and `p.overrides` is NOT wholly untrusted — cfg_mod.resolve runs it through validate, which coerces every known key. The genuinely unvalidated override path is narrower: `overrides.changed_only` is read raw at init.lua:96 and handed to gitfiles.list, whose `for _, k in ipairs(kinds)` throws on a non-table. Net effect is a crash-on-load rather than a silent-wrong-result, but the rule's requirement — re-validate every field of a persisted snapshot before use — is unmet.

**Status.** ✅ erledigt (`9720bc1`) — `as_request` validiert Typ/Länge/Count-Cap jedes Feldes (inkl. `overrides.changed_only`) und liefert `(req, err)` statt unvalidierte Werte durchzureichen.

### `UI-01` — Bulk-/destruktive Aktionen

`lua/replacer/batch.lua:156` · `M.run` · confidence **medium**

**Befund.** Each `{old => new}` pair is dispatched as its own full `:Replace!` request with `req.all = true`. Every one of them independently reaches init.lua:292-307, where `cfg.confirm_all` (true by default) opens its own `ui.kit.confirm` float. There is no batch-level confirmation.

**Regelbezug.** UI-01: a bulk/destructive action is confirmed once, not once per item. `:ReplaceBatch` is the bulk action; each pair is an item.

**Auswirkung.** A 40-pair batch file produces up to 40 separate 'Apply ALL N spot(s) across M file(s)?' prompts (one per pair that matched anything). Because the dispatch loop at batch.lua:156 is synchronous while collection is asynchronous (rg.collect_async / collect_streaming, init.lua:393-395), the prompts arrive in collection-completion order rather than file order, so the user answers yes/no to floats with no indication which pair each belongs to. The 'batch: dispatched N pair(s)' notification (batch.lua:167) fires before any prompt has been answered. Whether the floats visually overlap depends on ui.kit.confirm's queueing, which lives in ui.nvim and I did not read; the per-item confirmation itself is unconditional.

**Status.** ✅ erledigt (`3106d56`) — Batch fragt jetzt einmal vorab (übersprungen bei `--dry` oder `confirm_all=false`); jede Einzel-Pair-Dispatch erzwingt `confirm_all=false`.

### `UI-53` — Race Conditions

`lua/replacer/perfile.lua:77` · `M.run / step` · confidence **medium**

**Befund.** In the `--confirm-per-file` loop, the "Only some" branch calls `on_pick_file(list)` and then falls through to `step(i + 1)` at perfile.lua:83, which immediately opens the NEXT file's `ui.kit.confirm` float while the picker for the current file is still opening.

**Regelbezug.** UI-53 (deferred/async handles and ordering, per LUA-13): the picker is opened asynchronously and the loop does not wait for it to settle, unlike the "All" branch which correctly advances only from inside `apply_func`'s completion callback (perfile.lua:70-74).

**Auswirkung.** Choosing 'Only some' opens the file's picker and then immediately stacks the next file's confirm float on top of it. Under the telescope engine that is the registry-corruption scenario the plugin's own code comments describe. Independently and unconditionally: whatever the user applies through that picker is never fed back into total_files/total_spots, because on_pick_file takes no result callback — so the closing summary from perfile's on_done (init.lua:269-277) under-reports the run by exactly the 'Only some' files.

> **Abdeckung dieses Laufs.** COVERAGE. I read all 8,009 lines of lua/ plus plugin/replacer.lua. TESTS/ (4,667 lines across 14 suites) was only grepped, not read line by line, so this report contains no test-code findings -- that is a gap, not a clean bill for TESTS/. I ignored .claude/, .git/, .deps/ and doc/tags as instructed.

VERIFIED EMPIRICALLY. The two SEC-30 findings rest on a real headless run, not on doc reading: with only `<dir>/foo.lua.bak` loaded, `vim.fn.bufnr("<dir>/foo.lua")` returns the .bak buffer, and `vim.fn.bufnr("<dir>/c[1].json")` returns the buffer for `c1.json`. Four call sites pass a raw path to `bufnr()`; I filed the two with write-side consequences (checkpoint.lua:57, fnames.lua:185) and named the other two in those impact statements (export.lua:27, rg.lua:100) rather than filing near-duplicates.

RULES I COULD NOT CHECK PROPERLY.
- CMT-16: docs/map/ and docs/BINDINGS.md are generator output, but proving a hand-edit needs a regeneration run and a diff, which is a write. Not attempted -- this was a read-only audit.
- LLS-31, LUA-02, PRIN-01/10: judgment rules I found nothing concrete against. apply.lua's async path does return a best-effort `0, 0` snapshot before the work finishes (apply.lua:444), which is LLS-31's inverse shape, but it is documented at the function's own docstring and every real caller uses `on_done`, so I did not file it.
- LUA-01/LUA-06: lib.nvim and ui.nvim are consistently hard (bare `require` at module top level, health.lua:86 reports missing lib.nvim as `error`, README.md:43-45 and docs/installation.md say so). `pcall(require, "lib.nvim.progress")` in rg.lua:29 / apply.lua:20 is version tolerance within a hard dependency, not a soft one -- and those exact lines already carry a LUA-05 Belege footnote. config/DEFAULTS.lua is pure data with no env or FS lookup, so LUA-06 is clean.
- SEC-03/34/35: clean. Zero `vim.fn.expand`, zero shell-string construction, zero user text in a `vim.cmd(...)` string -- every spawn is argv (`vim.system` / `lib.nvim.cross.run_argv`), and scope expansion goes through `lib.nvim.cross.fs.expand_path` (command.lua:455). The XP-04 rg smoke-test fix is present in health.lua:136-141.
- ERR-20/PRIN-27: satisfied. tscode.lua fails open by construction, and apply_code_only keeps a match whenever the file content is unreadable (rg.lua:797-799).
- PERF-80: satisfied. Every `vim.system` stdout/exit callback re-enters the loop with `vim.schedule` before touching a vim API (rg.lua:398, 406, 985, 994; gitfiles.lua:36).

OUT OF SCOPE BUT WORTH A LOOK. `make test` runs 4 of the 14 suites while CI runs at least 9 -- a local `make check` can be green on code CI would reject. No rule in the 76 covers it, so it is not filed above.

**Status.** ✅ erledigt (`520d69e`) — „Only some“ beendet die Pro-Datei-Schleife jetzt sofort (wie „Quit“), statt das nächste Confirm-Float über dem noch offenen Picker zu öffnen. Der wörtliche Befund-Vorschlag (auf Picker-Schließen warten) war nicht umsetzbar — kein Picker-Backend liefert ein solches Signal.

---

## buffer-ctx.nvim

**16 Befunde** (6 × high). Roh gemeldet: 16.

### `ERR-02` — Type Guards & Literal Checks

`lua/buffer_ctx/util/map.lua:10` · `has_lib` · confidence **high**

**Befund.** `local has_lib = ok_lib_map and type(lib_map) == "function"` — but `require("lib.nvim.bindings.keymap")` returns a table made callable through a `__call` metamethod (verified in lib.nvim `lua/lib/nvim/bindings/keymap/init.lua`, final `setmetatable(M, { __call = ... })`), and `type()` reports `"table"` regardless of `__call`.

**Regelbezug.** ERR-02 requires the type/literal checks guarding an API access to actually hold for the value being checked. This one can never be true, so the guard permanently disables the branch it is supposed to protect — the sibling check in util/notify.lua:13 compares against `"table"` and does find lib.nvim.

**Auswirkung.** `has_lib` is structurally always false, so M.set (line 30-33) always takes the plain `vim.keymap.set` branch and lib.nvim's keymap registry never records buffer-ctx's registrations — mark/init.lua:20 is the only consumer, so the `:Mark` toggle/yank keymaps (DEFAULTS.lua: `mark.keymaps.toggle = "<S-m>"`, `yank = "<C-p>"`) are invisible to `:LibKeymapConflicts` and to lib.nvim's option validation. M.using_lib() likewise always returns false, so `:checkhealth buffer_ctx` (health.lua:56-63) permanently prints the info line "lib.nvim not found — using plain vim.keymap.set" even though health.lua:40-47 has already reported lib.nvim as detected two sections above — a self-contradicting health report on every machine with lib.nvim installed. Functionally the keymaps still get set; the loss is registry/conflict visibility plus a misleading health line.

### `ERR-03` — Explizite Rückgaben

`lua/buffer_ctx/format/text_width.lua:155` · `M.reflow_buffer` · confidence **high**

**Befund.** `M.reflow_buffer` returns nothing at all and silently returns early on an invalid buffer (line 158) or a non-positive width (line 162). Its only caller, format/init.lua:114-115, then unconditionally reports `"Set textwidth=%d and reflowed buffer"`. `M.reflow_range` exists but is never wired to the `textwidth` route, which also declares `range = true`.

**Regelbezug.** ERR-03 requires relevant functions to return true/false plus an error object rather than failing silently; the companion warning in LLS-31 is that a success message built from the planned rather than the actual work can never reveal a no-op.

**Auswirkung.** The reachable defect is the ignored range, not the invalid-buffer/zero-width cases the finding names — those two branches cannot be triggered through `:Format textwidth`. Because build_routes gives every :Format route `range = true` (init.lua:318) and the textwidth handler takes only `(args)`, `:10,20Format textwidth 80` and `:'<,'>Format textwidth 80` reflow the ENTIRE buffer and then report "Set textwidth=80 and reflowed buffer", with M.reflow_range (line 174) sitting unused. Separately, M.reflow_buffer's contract is unsafe for any future or external caller: passing a wiped bufnr or a non-numeric width is a silent no-op that the caller cannot detect, which is what ERR-03 forbids.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/buffer_ctx/ops/boilerplate/init.lua:212` · `M.get` · confidence **high**

**Befund.** `return gen(), nil` returns the generator's result with a hard-coded `nil` error slot. For `guard-clause` the generator is `guard.guard_interactive()`, which returns plain `nil` when the user cancels the prompt (guard.lua:46-48), so `M.get("guard-clause")` returns `nil, nil`.

**Regelbezug.** ERR-11 requires a function whose result may legitimately be empty to make "empty but ok" distinguishable from "empty because it broke". `M.get` is annotated `@return string[]|nil lines, string|nil err`, but a deliberate user cancellation and a genuine template failure both arrive at the caller as `nil` with no error object.

**Auswirkung.** Cancelling the guard-clause form makes `:Insert boilerplate guard-clause` report `[buffer-ctx] boilerplate failed` — verified commands.lua:275-276 (`if not lines then notify.error(err or "boilerplate failed")`) and the same at lua/telescope/_extensions/buffer_ctx.lua:91-93. A deliberate Esc is reported to the user as a broken feature. Scope is narrower than the rule's usual case: guard-clause is the only `is_interactive` entry in REGISTRY, so today exactly one template is affected — but every future interactive template inherits the same collapse, since line 212 is the shared return path.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/buffer_ctx/health.lua:115` · `M.check` · confidence **high**

**Befund.** When the format subsystem is disabled, `M.check` prints one info line and does a bare `return` (line 115), which ends the whole health check — the `vim.health.start("buffer_ctx.mark")` section at line 148 and everything after it never runs.

**Regelbezug.** ERR-11 requires "nothing to report" to be distinguishable from "could not determine anything". A completely absent mark section reads as "nothing to say about marks", when in fact the mark checks were never executed because of an unrelated option.

**Auswirkung.** With `format = false` (or `format = { enable = false }`) in setup(), `:checkhealth buffer_ctx` stops after the format info line: the entire `buffer_ctx.mark` section is absent with no explanation, so a mark subsystem that failed to register, or a `buffer_ctx.mark` module that failed to load, is undetectable by the health check for every user who turned :Format off. An absent section reads as "nothing to report about marks" when the truth is "the mark checks never ran, for an unrelated reason" — the ERR-11 collapse. Note the two subsystems are independent: mark_enabled is computed from cfg.mark at lines 152-156 and does not depend on format at all, so this is purely an early-return bug, not a deliberate dependency.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/buffer_ctx/commands.lua:178` · `DISPATCH.snippet / DISPATCH.boilerplate` · confidence **high**

**Befund.** Bare `require("ui.kit")` (also line 256, `format/column_align.lua:225`, `ops/boilerplate/templates/guard.lua:31`) with no pcall and no fallback, while `docs/installation.md:10` lists ui.nvim as `*(optional)*` and `docs/commands.md:219` + `docs/FEATURES/TEMPLATES.md:15` claim the picker is `vim.ui.select`.

**Regelbezug.** LUA-01 requires a dependency to be either hard (bare require, no fallback) or soft (pcall + local fallback with an identical interface), held to consistently, and forbids presenting a hard dependency as optional in the documentation. Every other foreign dependency in this plugin (lib.nvim in util/notify, util/map, util/path, util/clip, ops/uuid, format/misc) is soft-required; ui.kit is hard-required in four places and documented as optional.

**Auswirkung.** Without ui.nvim installed, four features are dead. Three of them (`:Insert`/`:Copy snippet` with no name, `:Insert boilerplate` with no template, `:Insert boilerplate guard-clause`) surface a raw `Error executing Lua callback: ...module 'ui.kit' not found` — verified that commands.lua's build_routes (line 442-456) calls `M._dispatch(...)` from `run` with no pcall, and lib.nvim's composer does `return run(ctx)` at bindings/usercmd/composer/parse.lua:199 with nothing above it. The fourth case is NOT a raw error: format/init.lua:336 wraps every :Format handler in `pcall(def.handler, args, range_ctx)`, so `:Format column` with no args degrades to a clean `[column] ...module 'ui.kit' not found` notification. The doc-level harm is the same in all four: the user was told these paths fall back to vim.ui.select, and none does.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/buffer_ctx/format/table_fmt.lua:165` · `M.format_tables_in_scope` · confidence **high**

**Befund.** `vim.fn.expand(scope)` is applied to `scope`, which is the raw value of the `scope=<...>` token typed on the `:Format table` command line (parsed at table_fmt.lua:239-240, `opts.scope = val`).

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user/buffer text: a backtick span in the argument is a command substitution through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. This value comes straight from the user's command line, not from a static config literal, so it is exactly the case the rule names; the rule prescribes `lib.nvim.cross.fs.expand_path`, which this file already has hard access to.

**Auswirkung.** `:Format table scope=`<cmd>`` runs `<cmd>` through `&shell` at line 165, before the readability check on line 166 can reject anything — a command-substitution sink reachable from a plain command-line argument. `scope=%` and `scope=#` silently resolve to the current/alternate file name instead of being rejected as an unknown path, and `<cfile>`/`<cword>` are likewise substituted (`<cword>` on an empty line additionally throws E348, which format/init.lua:336's pcall turns into a `[table] ...` notification rather than a crash). A path containing a glob metacharacter is read as a pattern and, on no match, collapses to `""`, which then fails the filereadable check with the misleading message `File not readable: ""`.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/buffer_ctx/ops/annotation.lua:29` · `M.get / M._interactive_function` · confidence **medium**

**Befund.** Fifteen bare `fn.input(...)` calls (lines 29, 35, 36, 43, 44, 51, 55, 56, 65, 74, 80, 96, 100, 104, 108) with no pcall around any of them, reached from the `:Insert annotation` / `:Copy annotation` command handler.

**Regelbezug.** ERR-01 makes `pcall()` mandatory at system boundaries, explicitly including user input, and this is not a hotpath. `vim.fn.input()` raises `Vim:Interrupt` when the user presses CTRL-C at the prompt, and lib.nvim's composer invokes the route handler with a bare `return run(ctx)` (parse.lua:199), so nothing above catches it either.

**Auswirkung.** Pressing CTRL-C at any annotation prompt surfaces a raw `Error executing Lua callback: Vim:Interrupt` instead of a clean cancel — the :Insert/:Copy route chain has no pcall at any level, so Neovim's own user-command error handler is the first thing to catch it. In M._interactive_function the interrupt also aborts the whole dialog, discarding the description and every parameter already entered in that session; there is no partial result and no "cancelled" path. No corruption or data loss — the buffer is untouched — the harm is an error traceback where a cancel was intended, and lost typing in the multi-prompt case.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/buffer_ctx/format/misc.lua:183` · `register_subcommands / sort, unique, trim, case, indent, clear` · confidence **medium**

**Befund.** `build_routes` in format/init.lua:317 declares `range = true` for every `:Format` route and passes the resolved range to the handler as its second argument, but these six handlers take only `(args)` and rewrite `nvim_buf_set_lines(buf, 0, -1, ...)` over the whole buffer (misc.lua:154, 183, 206, 240, 268).

**Regelbezug.** ERR-10 is about an argument that is silently collapsed into "no argument" and therefore acts on *everything* instead of erroring. An explicitly-given range is accepted by the command grammar, then discarded, and the operation runs over the entire buffer with no message saying the range was ignored.

**Auswirkung.** A range accepted by the command grammar is silently discarded and the operation runs over the whole buffer. Concretely: select lines in Visual mode, press `:` (Neovim prefills `'<,'>`), type `Format sort` — the entire buffer is sorted, not the selection, and the message is the unqualified "Buffer sorted". Same for `unique`, `case`, `indent`, `trim` and `clear`; `:10,20Format clear` empties the whole buffer. This is recoverable with a single `u` (it is one nvim_buf_set_lines call, so one undo block), so the damage is a surprising whole-buffer rewrite plus a success message that hides it, not data loss.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/buffer_ctx/format/init.lua:252` · `setup_enum_lines / enum handler` · confidence **medium**

**Befund.** The `enum` route declares `range = true` (line 282) and the handler receives `range_ctx`, but the handler calls `core.enum_selection(opts)`, which reads the `'<`/`'>` marks (enum_lines.lua:170-176) and ignores the range entirely. `enum_lines.M.enum_range(bufnr, start_line, end_line, opts)` exists for exactly this and is never called from production code.

**Regelbezug.** ERR-10: an explicitly supplied range is collapsed to "no range" and the operation runs against a different, stale source of truth. lib.nvim's own composer documents that `'<`/`'>` persist from whichever visual selection was last active and are not proof the current invocation came from one (parse.lua:204-210).

**Auswirkung.** `:10,20Format enum` enumerates and overwrites whatever lines the last Visual selection in that buffer covered, not lines 10-20, and then reports "Enumerated N token(s)" for the region it actually touched (enum_lines.lua:187) — a success message about the wrong lines. When no Visual selection has ever been made in the session the marks are 0 and the user instead gets "No valid visual selection found" from a command they gave an explicit range to. Both cases are single-undo recoverable; the concrete harm is silently editing an unrelated region while claiming success.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/buffer_ctx/ops/filepath.lua:125` · `M.parse_args` · confidence **medium**

**Befund.** `M.parse_args` walks the argument list and matches each token against a fixed set of literals; any token that matches nothing falls off the end of the if/elseif chain and is discarded without a word. The returned opts then carry the defaults (`mode = "cwd", format = "unix"`).

**Regelbezug.** ERR-10 forbids collapsing "no argument" and "invalid argument" onto the same result — a typo in the argument then behaves exactly like no argument. `ops/git.lua:39-42` in this same plugin shows the intended shape (`unknown git mode: … (hash|short|branch|tag)`).

**Auswirkung.** `:Copy filepath absolut` (or `abso`, `rela`, `windows-1`) silently copies a cwd-relative unix path while the user believes they requested an absolute one, then pastes the wrong path wherever they were writing — a typo behaves exactly like giving no argument, which is the bug class ERR-10 names. The finding's three companion sites are real but weaker: ops/timestamp.lua:83 `FORMATS[fmt] or FORMATS.iso`, ops/uuid.lua:47 and ops/module.lua:47 each fall back to a default for an unknown value, so the same silent-typo behaviour applies to `:Copy timestamp`, `:Copy uuid` and `:Copy module`. No data loss in any of them; the harm is a wrong value in the clipboard or the buffer with no signal that the argument was not understood.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/buffer_ctx/ops/location.lua:82` · `M.get_range` · confidence **medium**

**Befund.** `if not line1 or not line2 or line1 == line2 then` replaces the caller-supplied range with the `'<`/`'>` marks whenever the supplied range is a single line — even though commands.lua:452-454 already passes `nil` when the user gave no range at all, so a non-nil `line1 == line2` can only mean the user explicitly asked for that one line.

**Regelbezug.** ERR-10: an explicitly given argument is treated identically to "no argument given" and the operation silently acts on a different, stale source (the last visual selection, which lib.nvim's composer documents as persisting across unrelated invocations).

**Auswirkung.** `:42Copy location range` copies the span of whatever was last visually selected anywhere in that buffer this session — e.g. `file.lua:L10-L20` — instead of `file.lua:42`, and the user pastes a wrong line reference into a review comment or issue with no indication anything was substituted. Only the explicit single-line range is affected: a multi-line `:10,20Copy location range` has line1 ~= line2 and is used as given, and a genuine one-line Visual selection is unaffected because the inner `vstart ~= vend` guard on line 84 rejects single-line marks. Clipboard-only, nothing is written to a buffer or disk.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/buffer_ctx/ops/snippet.lua:96` · `M.load` · confidence **medium**

**Befund.** `if vim.tbl_isempty(all) and #errors > 0 then return all, table.concat(errors, "; ") end; return all, nil` — the collected per-file errors are returned only when the combined result is completely empty. If any one source decoded successfully, every read/parse error from the other sources is dropped.

**Regelbezug.** ERR-11 requires "empty but ok" and "empty because something broke" to be distinguishable. Here the partial-failure case is worse than the rule's example: a non-empty result carrying a silently swallowed "invalid JSON in snippet file" looks exactly like a complete, healthy load.

**Auswirkung.** With two or more snippet files configured and one of them corrupt, unreadable or empty, `:Insert snippet <Tab>` and `:Insert snippet <name>` simply omit that file's snippets. M.get's caller path only ever sees the err when `vim.tbl_isempty(snippets)` (line 126-128), so with a healthy second source the user gets "unknown snippet: X" for a snippet they can see in their own JSON file. Verified there is no secondary channel: health.lua has no snippet section at all (grepped — zero hits for `snippet`), so `:checkhealth buffer_ctx` will not surface it either. The user has literally nothing to debug from.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/buffer_ctx/config/init.lua:21` · `M.setup` · confidence **medium**

**Befund.** `M.setup` validates only that `user_opts` is a table, then goes straight to `vim.tbl_deep_extend("force", DEFAULTS, user_opts or {})`. There is no known-keys set, no unknown-key check before or after the merge, and health.lua never reports unrecognised options either.

**Regelbezug.** ERR-50 requires config validation (unknown keys, "did you mean…") to run before the merge, precisely because a typo in a nested option otherwise disappears silently into the defaults and is never detected.

**Auswirkung.** Any misspelled option — `snipets = { paths = {...} }`, `mark = { keymap = { toggle = "<S-m>" } }`, `format = { enabled = true }` — is deep-merged in as an inert extra key. setup() succeeds, the intended setting never takes effect because every reader goes through config.get() and asks for the correctly-spelled path, and `:checkhealth buffer_ctx` reports nothing unusual. The user sees the plugin running on defaults with no error and no diagnostic pointing at their config. Severity is confined to silent misconfiguration — nothing crashes and no data is at risk — but ERR-50 exists precisely because this class of typo is otherwise undetectable.

### `LUA-16` — `vim.NIL` sanitizen

`lua/buffer_ctx/ops/snippet.lua:154` · `M.get` · confidence **medium**

**Befund.** `lines[#lines + 1] = strip_tabstops(tostring(line))` coerces every element of a decoded JSON `body` array with `tostring` and no `vim.NIL` / type check, then hands the result to `cursor.insert_lines` → `nvim_buf_set_lines`.

**Regelbezug.** LUA-16 requires every field coming from external JSON to be checked for `vim.NIL` before use (`if v == vim.NIL or type(v) ~= "string" then v = "" end`) — `vim.json.decode` maps JSON `null` to `vim.NIL`, which is userdata, not Lua `nil`, so it survives both the `type(body) == "table"` check on line 148 and the `ipairs` walk.

**Auswirkung.** Correcting the finding's mechanism: because tostring() coerces first, nothing throws and nvim_buf_set_lines does not crash — the failure is silent corruption, not a crash. A snippet file whose `body` array contains a JSON null inserts a line reading `vim.NIL` (or `userdata: 0x...`, depending on the build's __tostring) into the user's buffer; a nested object or array inserts `table: 0x...`; a JSON number inserts its stringified form, which is usually harmless. The user gets garbage text in their buffer instead of either the intended content or an error naming the bad snippet file. Single-undo recoverable; the exposure is limited to snippet files the user configured themselves via `snippets.paths`.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/buffer_ctx/ops/snippet.lua:27` · `M.set_sources` · confidence **medium**

**Befund.** `sources[#sources + 1] = fn.expand(p)` runs Vim's filename expansion over each configured snippet path; the doc comment on line 21 states the intent is only "may contain ~ or environment variables".

**Regelbezug.** SEC-34 names `.rc` values as one of the hazards and says that where only `~` and environment variables are wanted the call belongs in `lib.nvim.cross.fs.expand_path` — no shell, no globbing, no Vim specials. `vim.fn.expand` additionally reads its argument as a glob pattern and as a command substitution across backticks.

**Auswirkung.** A configured snippet path containing a glob metacharacter — `[`, `]`, `?`, `{`, `*`, all legal in POSIX filenames — is read as a pattern; when it matches nothing, expand() returns `""` and line 27 stores an empty string as a source. M.load then reports "snippet file not readable: " for it, and because of the ERR-11 defect at line 96 that message is swallowed whenever any other source loaded, so the file's snippets vanish with no diagnostic at all. A backtick span in a path likewise runs through `&shell` at setup() time. Practical exposure is lower than the table_fmt case (these values come from the user's own init.lua, not a command line), but the rule's point stands: the code asks for ~/env expansion and gets a shell and a globber.

### `UI-01` — Bulk-/destruktive Aktionen

`lua/buffer_ctx/format/table_fmt.lua:126` · `M.format_tables_in_scope (scope == "cwd")` · confidence **medium**

**Befund.** `:Format table scope=cwd` collects every `*.md` under the working directory via a recursive glob (collect_md_files, lines 57-67) and rewrites each one on disk through `lib_table.format_file` (line 139), with no confirmation prompt anywhere in the path.

**Regelbezug.** UI-01 requires a bulk/destructive action to be confirmed once before it runs. This is the most destructive operation the plugin has — it edits files on disk rather than buffers, so Neovim's undo does not cover it — and the only thing between the user and it is one tab-completable token (`scope=cwd` is offered by the completer at table_fmt.lua:203).

**Auswirkung.** A tab-completed or mistyped `scope=cwd` from a repository root rewrites every Markdown table in every `*.md` file under cwd, in place on disk, in one keystroke. Files not open in a buffer have no undo — recovery is version control or nothing. Two mitigations that limit but do not remove the exposure: format_file skips the write entirely when it found no tables (`if count == 0 then return true`), so only files that actually contain tables are touched, and the rewrite is idempotent-ish reformatting rather than deletion. The user is still shown no prompt before a recursive on-disk bulk edit, and gets only the after-the-fact "Formatted tables in N file(s)".

> **Abdeckung dieses Laufs.** COVERAGE. I read the full rules file first, then every file under lua/ and plugin/ (~5,400 LOC, including all of commands.lua, mark/init.lua, format/*, ops/*, bindings/*, util/*, health.lua, config/*, the telescope extension and the boilerplate templates), plus README.md, docs/installation.md, docs/commands.md, docs/configuration.md and TESTS/README.md. TESTS/*.lua I skimmed rather than read line by line — I found nothing there worth reporting, so there are no is_test_code findings. I also read the relevant parts of the real lib.nvim checkout at E:/repos/lib.nvim to verify two claims (the `__call`-table shape of `lib.nvim.bindings.keymap`, and that `composer`'s parse.lua:199 calls a route handler as a bare `return run(ctx)` with no pcall) — both findings that depend on those facts are marked high confidence because of it. I ignored .claude/, .git/, .deps/ and doc/tags as instructed.

ALREADY-HANDLED BELEGE I DID NOT RE-REPORT. buffer-ctx is named in the Belege for LUA-01 (`util/notify.lua`, `util/path.lua:8-11`) and XP-01. The XP-01 case is genuinely fixed: `format/table_fmt.lua:61` routes the glob root through `lib.nvim.fs.globbable` with a comment explaining the 8.3 short-name trap. The LUA-01 entry is a different matter — the soft-require convention it credits is still intact for lib.nvim, but a *new* hard dependency (ui.kit) has since appeared in four places and is documented as optional, so I report that as a live violation rather than a re-report.

RULES I COULD NOT COVER. CMT-16: `docs/BINDINGS.md` and `docs/map/` are generated artefacts, but I have no way from inside this repo to re-run `:DocMap`/the renderer and diff the output, so I cannot say whether either has been hand-edited or has drifted. LUA-02 (fixes upward): nothing here looked like a private copy of a lib.nvim fix — `format/table_fmt.lua` in fact documents the opposite (the parse/render engine was extracted *up* into `lib.nvim.markdown.table`) — but confirming there is no shadowed fix would need a cross-repo diff I did not do. LUA-93 (every plugin carries its own lazy trigger) is about the user's nvim-config specs, not this repo; docs/installation.md's own examples do carry `event`/`cmd` and use `opts` rather than `config`, which is what LUA-87 asks for.

CHECKED AND CLEAN. SEC-03/SEC-30: `ops/git.lua:48-51` builds an argv list for `systemlist`, never a shell string, and `format/filter_lines.lua:12,15` uses `string.find(..., 1, true)` so user patterns are matched literally. LUA-06: `config/DEFAULTS.lua` is a pure literal table — no `require`, no env lookup, no filesystem access at module level. ERR-51/ERR-53: `vim.tbl_deep_extend("force", DEFAULTS, user)` builds a fresh top-level table and no submodule holds a reference into DEFAULTS. ERR-62: zero occurrences of the `pcall(f(args))` shape. LUA-48: no `__mode` anywhere; `mark/init.lua`'s bufnr-keyed `marked` table is cleaned by a real `BufDelete`/`BufWipeout` autocmd (line 517), which is exactly what the rule prescribes. PERF/timer family: the plugin has no timers, no `vim.defer_fn`/`vim.schedule`, no libuv callbacks, no module-level geometry and no autocmds on hot events (bindings/autocmds.lua is a documented no-op). XP-05: `vim.fn.executable("git")` sits inside the `git` subcommand, not on any startup path. LLS-31's inverse: `mark.toggle_range`/`clear`/`yank` all count actual work, not planned work.

SMALLER THINGS I JUDGED BELOW THE REPORTING BAR (no confirmed breakage, listed so the triage can decide). `mark/init.lua:525` uses the `type(opts) == "table" and opts.keymaps or nil` idiom that `bindings/keymaps.lua:88` explicitly warns against — it cannot carry a `false`, but the following `if km and km ~= false` guard makes the outcome identical, so nothing breaks (ERR-60, zero impact). `config/init.lua:26` `return _active or DEFAULTS` hands out a live reference to shared state with neither a copy nor a "live reference, do not mutate" note (ERR-54) — no current consumer mutates it, so the risk is latent. `commands.lua:206` `table.remove(fargs, 1)` mutates the caller's table, which matters for the public `M.insert("annotation", my_args)` API. `format/init.lua:309-310` swallows a throwing completer into an empty candidate list. `ops/snippet.lua` re-reads and re-decodes every configured JSON file on every `<Tab>` (list_keys → load), with no caching. The TESTS/README itself documents two known-and-pinned bugs I confirmed are still present and did not re-report, since neither maps onto one of the 76 rules: `column_align`'s byte-vs-display-column off-by-one, and `mark.setup()`'s non-idempotent `BufDelete` autocmd group.

---

## insights.nvim

**16 Befunde** (8 × high). Roh gemeldet: 16.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/insights/bindings/autocmds.lua:33` · `norm_events` · confidence **high**

**Befund.** `if type(events) == "table" and #events > 0 then return events end; return default` — an explicitly empty list is treated exactly like "no value configured" and replaced by the built-in default event list.

**Regelbezug.** ERR-10/PRIN-26: "no value given" and "the value is the empty set" are collapsed onto the same branch. `config/DEFAULTS.lua:164` documents `events = { "VimEnter" }, -- when to scan; {} = only :Insights conflicts` and `docs/configuration.md:164` says `{} = never automatic, command only`; the code (and `TESTS/bindings_spec.lua:157-159`, which asserts "an empty list means the default") does the opposite.

**Auswirkung.** Confirmed. `conflicts.events = {}` — the opt-out both the defaults comment and docs/configuration.md tell the user to write — still registers the VimEnter autocmd, so every Neovim start runs `conflicts.run_async`. That is async (the comment at lines 46-48 shows the blocking version was deliberately replaced), so the impact is a background git scan plus a possible quickfix-list replacement and notification on startup, not the ~120ms main-loop block the old implementation had. `unimported.events = {}` likewise keeps the BufWritePost check on every write. Worth flagging that the spec test encodes the documented behavior's opposite, so any fix has to correct DEFAULTS.lua:164, docs/configuration.md:164 and bindings_spec.lua:157-159 together.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/insights/imports/init.lua:126` · `candidate_files` · confidence **high**

**Befund.** `local lines, code = rg.exec_sync(cmd)` followed by `if code <= 1 then return lines end`. `scan/rg.lua:88-90` returns `{}, -1` when the `vim.wait` timeout elapses or no result arrived, and `-1 <= 1` is true, so a timed-out scan returns an empty file list as a successful "no candidates".

**Regelbezug.** ERR-11: a function whose result may legitimately be empty must keep "empty and fine" distinguishable from "empty because it broke". Here rg exit 0 (files found), exit 1 (no matches) and the sentinel -1 (wedged/timed-out process, default 120 s) all collapse into the same silent empty list — and unlike exit code 2, -1 does not even fall through to the globpath fallback below.

**Auswirkung.** Confirmed. Three distinct outcomes — rg exit 0 (matches), exit 1 (no matches) and the `-1` timeout/wedged sentinel — collapse into one empty candidate list. On a tree where rg exceeds `symbols.indexing.timeout_ms`, `:Insights imports` reports 'no import/require calls found' rather than naming the scan failure, and the empty result is written to `imports.index` by both scan entry points, so `:Insights imports reverse <module>` and the hover.nvim contribution subsequently answer 'nobody imports this' from a scan that never completed. The one correction to the auditor: exit code 2 does fall through to the globpath fallback, so the gap is specific to the timeout sentinel.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/insights/ui/scratch.lua:8` · `module top level` · confidence **high**

**Befund.** `local kit = require("ui.kit")` is a bare, unguarded module-level require, used only by `show_help` (the `?` cheatsheet). `docs/installation.md:9` describes ui.nvim as required "for the default config" with the scope "`ui.kit.confirm` backs the dev-server-detected prompt … set `devserver.prompt = false` to opt out instead of installing it", and `health.lua:50` repeats that it is "required for the dev-server prompt".

**Regelbezug.** LUA-01: a dependency is either hard or soft and the documentation must not present a hard one as narrower/optional than it is. `insights.ui.scratch` is the display path for `:Insights metrics`, `:Insights smells`, `:Insights imports` (report, reverse, unused) and `:Insights symbols … scratch`, so ui.nvim is a hard dependency of the plugin's whole reporting surface, not of one prompt.

**Auswirkung.** A user who takes the documented opt-out — `devserver.prompt = false`, ui.nvim not installed — hits `module 'ui.kit' not found` on `:Insights metrics`, `:Insights smells`, every `:Insights imports` variant and `:Insights symbols … scratch`, because the failing require is at scratch.lua's top level and fires on the first `require("insights.ui.scratch")`, before any code path decides whether the help viewer is needed. `:checkhealth insights` compounds it by attributing the missing module solely to the dev-server prompt, so the health output actively points away from the real cause.

### `PERF-46` — Cache-Key vollständig

`lua/insights/scan/cache.lua:13` · `cache_path` · confidence **high**

**Befund.** The symbol cache file name is `<dir>/symbols_<sha256(cwd):16>.json` — the cwd is the only thing in the key. None of the parameters that change the result are in it: `symbols.languages` (which languages were scanned), `symbols.indexing.exclude_patterns`/`max_file_size_kb`/`follow_symlinks`, and above all the Lua split in `symbols/init.lua:103-111`, where `get_cwd_ts_lua` hands `rg_index.get` a config with `languages.lua = false` yet stores and loads through the same `"symbols"` namespace (rg_index.lua:154 and :176).

**Regelbezug.** PERF-46: the key must contain every parameter that influences the result, otherwise the cache silently answers a different configuration's question. Only source-file mtimes invalidate here (cache.lua:53-59) — flipping a config flag changes no file's mtime, so the stale entry stays valid for the full 3600 s TTL.

**Auswirkung.** Accurate as written and verified in both directions. With `symbols.use_treesitter_for_lua = true` against a cache warmed by an rg-only run, `:Insights symbols` returns the cached rg Lua entries *plus* the fresh Tree-sitter ones — every Lua function appears twice in the picker. After a TS-mode run persists the Lua-free index under the shared key, switching back to the rg backend shows zero Lua symbols until the TTL (default 3600s) lapses, a source file's mtime changes, or `:Insights cache clear` runs. The same applies to any `symbols.languages.<lang> = false` flip and to changes in `indexing.exclude_patterns` / `max_file_size_kb`, none of which are in the key.

### `SEC-03` — Nutzereingabe nie shell-interpoliert

`lua/insights/compress/init.lua:157` · `engines.powershell` · confidence **high**

**Befund.** The directory being compressed and the output path are concatenated straight into two single-quoted PowerShell strings (`Get-ChildItem -Recurse -Path '<path>'` on line 157, `Compress-Archive -Path '<path>' -DestinationPath '<out_path>' -Force` on lines 161-165) with no quote escaping; `lib.nvim.cross.run.shell()` runs that whole string through `powershell -NoProfile -ExecutionPolicy Bypass -Command`.

**Regelbezug.** SEC-03 forbids interpolating a user-supplied value (here the `:Insights compress [path] [outdir]` arguments, or the cwd) into a command string. PowerShell escapes a single quote by doubling it; the sibling module `lua/insights/tree/init.lua:74-76` has exactly that `q()` helper and uses it, so the correct escape exists in this repo and is simply not applied here.

**Auswirkung.** On Windows, any project directory or outdir containing an apostrophe terminates the PowerShell string literal early: `Get-ChildItem -Recurse -Path 'C:\Bob's Repo'` is a parse error, so `:Insights compress` fails with an opaque 'file listing failed' for an ordinary, legal Windows directory name — this is the realistic, routine failure. The injection case is real but narrower than stated: it requires an attacker-chosen directory name (e.g. a cloned repo checked out under `x'; iwr http://…|iex; '`) or an attacker-supplied `outdir` argument, and then arbitrary PowerShell runs under the user's account. Note `args[2]` is additionally never passed through `expand_path` — usrcmds.lua:285 splices it into the config table raw, so it reaches both `vim.fn.expand` (compress/init.lua:42) and this command string unsanitized.

### `SEC-30` — Nutzereingabe literal escapen

`lua/insights/tree/init.lua:66` · `build_tree_cmd` · confidence **high**

**Befund.** For the Unix branch, the cwd is escaped for a `sed` BRE with `cwd:gsub("([^%w_%./%-])", "%%%1")`, i.e. every character outside `[A-Za-z0-9_./-]` is prefixed with a literal `%` (Lua-pattern escape syntax), and the result is embedded in `s#^<escaped_cwd>/##` on line 69.

**Regelbezug.** SEC-30 requires user-derived input to be literal-escaped for the regex engine that will actually read it. `sed` BRE escapes with `\`, not `%`; `%` is an ordinary literal character there. This is the identical mistake the Windows branch of this same function documents as already fixed in its comment (lines 79-85: "The replacement below used to prepend a literal `%` to each one") — the sed branch was never corrected.

**Auswirkung.** Confirmed for Unix `:Insights tree` / `:Insights count`. A cwd containing a space, `+`, `&`, `(` etc. produces a pattern like `s#^/home/u/my% project/##` that can never match, so the output file lists absolute paths instead of project-relative ones — a silent, wrong-looking tree, not an error. A cwd containing the `#` delimiter itself (`s#^/a/b%#/##`) or an unbalanced `[` makes sed abort with a syntax error and `:Insights tree` reports 'tree write failed'. The auditor's `[`/`]` example is imprecise — a balanced `[test]` escapes to `%[test%]`, which sed parses as a valid bracket expression that simply does not match, rather than erroring; only an unbalanced bracket aborts. The false-prefix-match concern is real but minor.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/insights/bindings/usrcmds.lua:283` · `handle_compress` · confidence **high**

**Befund.** `args[1]`, the raw path token typed at `:Insights compress <path>`, is passed to `vim.fn.expand()` before `fnamemodify(..., ":p")`.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on buffer/user text: a backtick span in the argument is a command substitution over `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. The composer type `INSIGHTS_DIR_SOFT` (line 500-507) validates nothing — it returns `raw` unchanged. The safe helper is already imported in this very file (`expand_path`, line 28) and used on line 208 for `--file=`.

**Auswirkung.** A backtick span in the argument to `:Insights compress` is executed by `&shell` before anything is compressed, exactly as SEC-34 documents for `vim.fn.expand`. The Vim-specials half is narrower than the auditor implies: Vim only treats `%`/`#`/`<…>` as specials when they are the *first* character of the string, so it is an argument that literally begins with `%` or `#` (a directory named `%`) that silently resolves to the current/alternate file name and archives the wrong tree. Mid-string `%` is left alone.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/insights/metrics/init.lua:24` · `M.normalize_dir` · confidence **high**

**Befund.** `normalize_dir` calls `vim.fn.expand(path)` on its argument. It is reached with raw command-line text from two commands: `:Insights metrics <dir>` (usrcmds.lua:210 `opts.root = a` → metrics/init.lua:361) and `:Insights smells <dir>` (usrcmds.lua:263 `ctx.pos[1]` → smells/init.lua:233-235).

**Regelbezug.** SEC-34: the directory token comes from the user's command line, so a backtick span in it is executed by `&shell` inside `expand()`, and `%`/`#` are expanded as Vim specials rather than treated as path characters. `lib.nvim.cross.fs.expand_path` is the sanctioned no-shell, no-globbing replacement and is already used elsewhere in this plugin.

**Auswirkung.** A backtick span in the directory token of `:Insights metrics` or `:Insights smells` is run through `&shell` by `expand()` before the analysis starts. The specials case is limited to a token that *begins* with `%` or `#` (Vim only honours cmdline-special expansion at position 0), which then resolves to the current/alternate file name, so `vim.fn.isdirectory(root)` fails and the user gets 'not a directory: <some file>' rather than a silent wrong-tree scan — less silent than the auditor claims, but still a wrong resolution of a path the user named literally.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/insights/bindings/usrcmds.lua:147` · `handle_symbols` · confidence **medium**

**Befund.** The token loop recognises `cwd`/`buffer`, the three UIs, `rebuild` and the three symbol types; anything else falls off the end of the `if`-chain and is dropped, after which the hardcoded defaults (`scope = "cwd"`, `sym_type = "functions"`) are used.

**Regelbezug.** ERR-10: a mistyped argument behaves exactly like no argument instead of being reported. This is the rule's archetype — the typo silently widens the operation to everything rather than failing. The plugin knows how to do this correctly elsewhere: `handle_devserver` (line 405) and `handle_cache` (line 443) both warn on an unknown subcommand, and `symbols/open.lua:132-154` warns on an unknown configured scope/type.

**Auswirkung.** Confirmed — this is ERR-10's archetype, and the plugin's own `symbols/open.lua` already implements the correct behavior for the config-side equivalent. `:Insights symbols buffr` falls through to the `scope = "cwd"` default and runs a full ripgrep index of the working tree instead of scanning the one buffer, presenting the result as though it were what was asked for; on a large repo that is a multi-second scan the user did not request. `:Insights symbols rebiuld` leaves `rebuild = false`, so the requested rebuild silently does not happen and a stale cache is served. A mistyped symbol type (`tabels`) silently yields functions. In every case the widening is the failure mode the rule was written to catch.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/insights/bindings/usrcmds.lua:204` · `parse_metrics_args` · confidence **medium**

**Befund.** `opts.top_n = tonumber(a:sub(8))` for `--topn=` and `opts.col_width = tonumber(a:sub(12))` for `--colwidth=` (line 206). A non-numeric value yields `nil`, which `metrics.resolve`'s `pick()` (metrics/init.lua:139-148) cannot tell apart from "the flag was never passed", so the config default is used.

**Regelbezug.** ERR-10: an invalid argument value is collapsed onto "no argument", which is precisely the case the rule says must be returned separately. Nothing warns.

**Auswirkung.** Confirmed. `:Insights metrics --topn=2o` or `--colwidth=wide` silently discards the flag and renders the report with the configured defaults, byte-identical to a run where the flag was never typed — the user reads top-N lists and a column width they did not ask for with no signal that their argument was rejected. This is the narrowest of the three ERR-10 findings in this report: unlike `handle_symbols`, the operation is not widened and nothing expensive or destructive happens, so the cost is purely a misleading report the user has no way to distrust.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/insights/scan/cache.lua:113` · `M.stats` · confidence **medium**

**Befund.** `local decoded = require("lib.nvim.fs.json").read(path)` discards the second return value (the error), and `if not decoded then return nil end` returns the same `nil` whether the cache file is absent or present-but-unreadable/corrupt.

**Regelbezug.** ERR-11: "nothing to report" and "could not determine" must be distinguishable. `M.load` above does keep the two apart (it returns a reason string), so the information exists and is thrown away only here.

**Auswirkung.** Confirmed. A cache file that exists but cannot be parsed — the `invalid JSON` case that M.load already names correctly — is reported by `:Insights cache info` and by the Symbol cache section of `:checkhealth insights` as 'no cache for current CWD — run :Insights cache build'. The user is told to build a cache they already have, the corruption is never named, and `:checkhealth` — the one surface whose job is to reveal exactly this — reports the wrong condition. The fix is a one-line change since M.load next door already demonstrates the (result, reason) shape.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/insights/config/init.lua:25` · `expand_paths` · confidence **medium**

**Befund.** `expand_paths` indexes five nested config sub-tables unconditionally (`cfg.symbols.cache.dir`, `cfg.metrics.output_file`, `cfg.tree.outdir`, `cfg.imports.output_file`, `cfg.compress.outdir`) immediately after the merge in `M.setup` (line 44-45), with no type guard.

**Regelbezug.** ERR-22: an invalid single config value must degrade to its default instead of aborting plugin initialisation. `vim.tbl_deep_extend("force", …)` replaces a whole sub-table when the user passes a scalar, so a plausible mistake — writing `compress = false` by analogy with the top-level `hover = false`/`commands = false`/`deps_popup = false` switches this plugin does have — leaves `current.compress == false` and line 29 raises "attempt to index a boolean value". Every consumer elsewhere in the plugin guards for exactly this (`cfg.imports and cfg.imports.enable`, `cfg.conflicts or {}`); only the merge path does not.

**Auswirkung.** Confirmed. `require("insights").setup({ compress = false })` — or `symbols`, `tree`, `metrics`, `imports` given a scalar — throws out of `setup()` at config/init.lua:25-31 before `bindings` registers any command, keymap or autocmd, so a single mistyped option leaves the plugin entirely inert rather than degrading that one value to its default. Under lazy.nvim the error surfaces as a plugin-load failure in the lazy UI, which points at the plugin rather than at the offending line of the user's spec. ERR-22's second half is also unmet: nothing in `:checkhealth insights` surfaces a rejected value, because setup never returns.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/insights/config/init.lua:44` · `M.setup` · confidence **medium**

**Befund.** `current = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})` is the whole of config handling: there is no known-keys check, no "did you mean …" pass, and no validation of value types either before or after the merge. `health.lua:213-236` only prints a handful of resolved values back; it never compares the user's keys against the defaults.

**Regelbezug.** ERR-50 exists so a typo in a nested option cannot vanish silently into the default. With `"force"` deep-extend and no key validation, an unknown key is merged in and simply never read, and nothing in `:checkhealth insights` can surface it.

**Auswirkung.** Confirmed, and the consequence is precisely the silent-typo case the rule names. With `"force"` deep-extend, `setup({ symbols = { langauges = { lua = true } } })` merges the misspelled key into the resulting table where nothing ever reads it, and `setup({ imports = { engien = "ripgrep" } })` does the same. No error, no warning, and `:checkhealth insights` cannot surface it because it only prints resolved values. The user's only signal is that the plugin behaves as though they configured nothing — with no way to tell a typo from an option that does not do what they expected. The impact is a diagnosability gap rather than a crash, which matches the rule's medium-severity framing.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/insights/devserver/init.lua:27` · `M.tracked` · confidence **medium**

**Befund.** `M.tracked()` returns the module-local `tracked` table itself (declared line 20), and `lua/insights/init.lua:111-113` re-exports it as the public façade `insights.devservers()`. Neither copies, and neither documents the return value as a live reference that must not be mutated.

**Regelbezug.** ERR-54: a public getter that hands out internal shared state by reference makes every caller a potential mutator of that state. The table returned here is the same one `M.track` writes and `M.kill_all` iterates.

**Auswirkung.** I have to correct the auditor here: the concrete breakage they describe does not occur today. Nothing inside insights.nvim mutates the returned table — `handle_devserver` (usrcmds.lua:377) only reads it — so there is no live bug, and the statusline snippet in the impact text is invented. What is real is the exposure the rule is written against: `insights.devservers()` is a documented public API, so any external consumer that clears an entry or rewrites the table (the natural thing to do for a channel it considers dead) silently removes that server from the plugin's own tracking, and `kill_all` on VimLeavePre then skips a process the user answered 'yes' to killing. Severity is latent, not observed — the correct framing is 'undocumented live reference handed across a public API boundary', not a present-day defect.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/insights/scan/cache.lua:53` · `M.load` · confidence **medium**

**Befund.** After checking only `version` and `cwd`, `M.load` iterates `decoded.entries` and passes `ie.entry.filename` to `uv.fs_stat` (line 55) and then returns every `ie.entry` verbatim to the caller. No field's type, length or count is re-validated, and there is no cap on the entry count.

**Regelbezug.** SEC-33: a persisted snapshot is untrusted on load and every field must be re-validated on the way in. A JSON `null` decodes to `vim.NIL` (userdata, truthy), so `ie.entry and ie.entry.filename or ""` passes it straight to `uv.fs_stat`, which raises on a non-string; `entries` being a non-list, or `entry` a scalar, is equally unhandled.

**Auswirkung.** The violation is real but the auditor's mechanism and the 'truncated file' half are both wrong, so the impact needs restating. A truncated cache file is actually handled cleanly: `lib.nvim.fs.json.read` returns `nil, "invalid JSON: …"` and M.load's line 35-37 turns that into a proper `(nil, reason)` miss. And JSON null does not arrive as `vim.NIL` — `lib.nvim.json.decode` normalizes it to the `lib.lua.null.NULL` table sentinel (lib.nvim/lua/lib/nvim/json/init.lua:59-61). That sentinel is still truthy and still not a string, so the outcome the auditor predicted holds by a different route: a *syntactically valid* cache file with a null or wrong-typed `filename` (or a scalar `entry`, or a non-list `entries`) makes `uv.fs_stat` raise 'string expected, got table' out of an uncaught `cache.load`, and `:Insights symbols` errors instead of falling back to a rebuild. The uncapped entry count and the unvalidated `lnum` reaching `nvim_win_set_cursor` are both confirmed as stated.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/insights/compress/init.lua:42` · `resolve_outdir` · confidence **medium**

**Befund.** `vim.fn.expand(cfg_outdir)` is applied to `compress.outdir` from the merged config — a value `config/init.lua:29-31` has already run through the safe `lib.nvim.cross.fs.expand_path`. The same double expansion exists at `lua/insights/health.lua:257` (which then also creates the directory during `:checkhealth`) and at `lua/insights/metrics/init.lua:301` for `metrics.output_file`.

**Regelbezug.** SEC-34 names `.rc` values explicitly as text that must not reach `vim.fn.expand()`: a backtick span in a config string is a command substitution over `&shell`, and `%`/`#` are Vim specials. Since `expand_path` already resolved `~`/`$VAR`/`%VAR%` at merge time, this second call adds no capability at all — only the shell and the specials.

**Auswirkung.** Confirmed, and one point needs strengthening rather than softening. For the config-sourced value the auditor is right that the second expansion adds no capability beyond the shell and the specials, since expand_path already resolved `~`/`$VAR`/`%VAR%` at merge time — this is the redundant-risk case. But `:Insights compress <path> <outdir>` bypasses config entirely: usrcmds.lua:285 does `vim.tbl_extend("force", cfg.compress, { outdir = args[2] })` with the raw command-line token, so line 42 is the *first and only* expansion that token ever sees, and a backtick span there is straightforwardly a shell execution from a command argument. The `:checkhealth` exposure at health.lua:257 is real and worth calling out separately, because a user running `:checkhealth insights` does not expect it to execute anything from their config or to create a directory. The specials half applies only to a value beginning with `%` or `#`.

> **Abdeckung dieses Laufs.** Read in full: init.lua, plugin/insights.lua, config/{init,DEFAULTS}.lua, bindings/{usrcmds,autocmds,keymaps}.lua, compress, tree, conflicts, devserver, unimported, fileinfo, hover, health, scan/{rg,cache}.lua, symbols/{init,rg_index,open,parser(head),ts_lua}.lua, imports/{init,index,definition,graph,resolve,langs/util,langs/lua(is_external)}.lua, ui/{scratch,fzf,telescope}.lua, util/{notify,platform}.lua, metrics/{init,analyzer(head),misc(head)}.lua, smells/init.lua. Verified lib.nvim's shell selection (E:/repos/lib.nvim/lua/lib/nvim/cross/run/init.lua:11-19) to confirm the PowerShell finding, and docs/installation.md + docs/configuration.md to confirm the LUA-01 and ERR-10/events findings against their documentation.

Not read line by line (greps only, so a violation there could have been missed): metrics/report.lua (375 lines), symbols/patterns.lua (337), symbols/ts_lua_tables.lua (222), symbols/ts_lua_strings.lua (117), imports/ts_requires.lua beyond its first 80 lines, the five regex language scanners under imports/langs/ (~530 lines), config/@types/init.lua (annotations only). These are pure text/AST analysis with no I/O, shell or API surface in their greps.

TESTS/ was not audited as code: I read TESTS/run.lua and the autocmd block of TESTS/bindings_spec.lua only, to check XP-06 (no `require("TESTS…")`/case-sensitive module paths anywhere — the runner uses `dofile` with a path derived from `debug.getinfo`, so it is safe on a case-sensitive CI) and to see whether the `events = {}` behaviour was deliberate. It is asserted at TESTS/bindings_spec.lua:157-159, which is why that finding is phrased as code-vs-documentation rather than an accident. No findings are filed against test code.

CMT-16 not checked: docs/map/ and docs/BINDINGS.md are generated artefacts, but I did not diff them against their renderer (documentation.nvim lives outside this repo), so I cannot say whether either carries a hand edit.

Rules with a surface but no finding: LUA-11/12/13 and ERR-33 (handles are re-validated — hover.lua:120, unimported/init.lua:69, fileinfo/init.lua:50/62, ts_lua.lua:55); PERF-80 (conflicts/init.lua:181, graph.lua:151 and util/platform.lua:33 all `vim.schedule` before touching the API); SEC-35 (every `vim.cmd("edit …")` goes through `vim.fn.fnameescape`, which escapes `|`); SEC-30 elsewhere (`vim.pesc` is used in definition.lua:141 and imports/init.lua's `count_word`, and unimported's component names are constrained to `[A-Z][%w_]*`); ERR-51 (setup merges into `vim.deepcopy(defaults)`); XP-01 (every `glob`/`globpath` call goes through `lib.nvim.fs.globbable`).

One observation with no matching rule, so not filed as a finding: symbols/ts_lua.lua:195-196, ts_lua_tables.lua:210-211 and ts_lua_strings.lua:105-106 each do `vim.fn.bufadd(path)` + `vim.fn.bufload(path)` for every .lua file in the tree and never unload them, so `:Insights symbols tables cwd` (reachable with default config) leaves the whole project loaded as buffers for the rest of the session and fires every BufRead/FileType autocmd other plugins have registered.

---

## language.nvim

**16 Befunde** (14 × high). Roh gemeldet: 16.

### `ERR-03` — Explizite Rückgaben

`lua/language/translate/files.lua:116` · `deliver` · confidence **high**

**Befund.** `pcall(fn.writefile, result, abs)` on line 115 discards both the pcall status and `writefile`'s own return code, then line 116 unconditionally does `return abs, nil` — signalling "written to abs" whether or not anything was written. The `suffix` branch on lines 119-120 does the same.

**Regelbezug.** ERR-03 requires relevant functions to return success/failure rather than fail silently. `deliver`'s return is the only success signal the caller has: `M.process` uses the returned `written` path both to decide what to record in history (line 164) and, transitively, to let the run count as complete.

**Auswirkung.** A failed write (read-only file, permissions, full disk, path no longer valid) is completely silent: no notification, no log, and a history entry that names the path as if the translation had been written there. The `translated N file(s)` summary counts it too. In `--files=replace` mode the user's only remaining signal that nothing happened is opening the file. Note `vim.fn.writefile` can both throw (caught by the pcall) and return -1 (discarded) — both channels are dropped.

### `ERR-03` — Explizite Rückgaben

`lua/language/spell/ui/item_menu.lua:135` · `M._items (ignore_persistent)` · confidence **high**

**Befund.** `done_msg(ignore.add_persistent(issue.word), nil, msg)` — `ignore.add_persistent` returns `(ok, err)`, but because the call is not the last argument it is truncated to one value and a literal `nil` is passed as `done_msg`'s `err` parameter. `done_msg` then does `notify.error(tostring(err))`. The `add_dict` action at line 214 has the identical shape against `actions.add_to_dict`, which also returns `(ok, err)`.

**Regelbezug.** ERR-03 requires a real error object to travel with the failure rather than a silent or content-free one. Both producers do the right thing — `ignore.lua:76-79` returns `false, tostring(err)` from the `mkdir`/`readfile`/`writefile` pcall, `actions.lua:58-60` returns `false, tostring(err)` — and both call sites discard it at the last hop.

**Auswirkung.** When persisting an ignore or a dictionary word fails — state directory not writable, disk full, the ignore file owned by another user, a `:spellgood` rejection — the user's notification body is the literal string `nil`. The real cause existed one frame earlier and is discarded, so there is nothing to act on, and the word stays flagged on the next scan with no explanation. Non-destructive, but it converts a diagnosable failure into an undiagnosable one.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/language/bindings/usrcmds/init.lua:182` · `dispatch_translate` · confidence **high**

**Befund.** `scope.parse` returns every token it did not recognise in `rest`; `dispatch_translate` uses `rest[1]` as the target language and silently drops `rest[2]` and beyond. A misspelled scope word is therefore not an error — it is simply an extra token nobody looks at, and `scope.parse` falls through to its `{ kind = "buffer" }` default at scope/init.lua:179.

**Regelbezug.** ERR-10 verbatim: "ein Tippfehler im Argument verhielt sich wie ,kein Argument' und wirkte dadurch auf *alles* statt einen Fehler zu werfen". `composer.verb` declares `enum = TR_OUTPUT_MODES` / `TR_FILES_MODES` for the flags, but the module's own header documents that dispatch bypasses composer's parsed `ctx.args`/`ctx.flags` entirely and re-scans `ctx.raw`, so none of that declared validation is enforced.

**Auswirkung.** `:TranslateReplace DE selction` translates and overwrites the ENTIRE buffer with no warning, because the unrecognised token is discarded and `scope.parse` defaults to `buffer` while `dispatch_translate` forces `output = "replace"` (usrcmds/init.lua:254). That is the real and destructive consequence. The second example in the finding does NOT hold: `--output=raplace` is rejected before `run` is ever called — `composer.flags.split` routes the value through `argtypes.validate`, which checks `spec.enum` first (argtypes.lua:61-66) and returns `expected one of popup|replace|…`, and `parse.dispatch` (parse.lua:157-161) notifies that error and returns. So flag values ARE validated; it is only the positional scope word that silently degrades to 'everything'.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/language/translate/history.lua:44` · `ensure_loaded` · confidence **high**

**Befund.** `local decoded = json.read(h.file)` takes only the first return value of `lib.nvim.fs.json.read`, which returns `(decoded, err)`; a decode failure therefore looks exactly like the `filereadable == 1` guard above never having matched, and `ring` stays `{}`.

**Regelbezug.** This is the canonical ERR-11 load-modify-save collapse: "Datei fehlt" and "Datei korrupt" resolve to the same empty structure, and `save()` at line 61 then writes the WHOLE file back. The err value that would distinguish the two cases is available from the very call being made and is thrown away.

**Auswirkung.** Only reachable with the opt-in `translate.history.persist = true` (`config/DEFAULTS.lua:92` defaults it to `false`), so this is not a default-path bug. For a user who has opted in, a `translate_history.json` that exists but does not decode (interrupted write — `json.write` renames via `uv.fs_rename`, which lib.nvim's own header documents as best-effort on Windows — a hand edit, a partial sync) is indistinguishable from a missing file: `ring` stays `{}`, no error is surfaced anywhere, and the next `M.record` writes the whole file back with a single entry. The rest of the history is unrecoverable; nothing copies the bad file to `.corrupt` first, which is the remedy the rule's own Beleg block prescribes.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/language/spell/providers/native.lua:310` · `collect_file` · confidence **high**

**Befund.** `if fn.filereadable(path) ~= 1 then return end` — a path that does not exist, or is not readable, returns an empty issue list with no error channel. Same for the `pcall(fn.readfile, path)` failure two lines below. `M.scan_tree` (line 470) then hands that empty list straight to `cb`.

**Regelbezug.** ERR-11: a function whose result may legitimately be empty must make "empty but ok" distinguishable from "empty because it broke". Both outcomes here are an indistinguishable `{}`. `gather_tree_files` (line 379) has the same shape — the whole directory walk is wrapped in a bare `pcall`, so a failure mid-iteration silently yields a partial file list.

**Auswirkung.** `:Spellcheck en path=/does/not/exist` ends with `[language] 0 spelling issue(s)` from the progress handle and `No spelling errors found (path:/does/not/exist)` — a clean bill of health for a path that was never opened, with a mistyped path indistinguishable from a genuinely clean one. Reachable when the native provider is the one chosen for the cwd/path scope (collect.lua:220-238 picks the first available external CLI provider first). The `gather_tree_files` variant is the quieter one: an error mid-walk yields a silently truncated file list, so a large-tree scan reports a plausible subset as if it were the whole tree.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/language/spell/providers/cspell_server.lua:299` · `M.check` · confidence **high**

**Befund.** The 6-second guard timer fires, clears `state.pending[id]` and calls `cb({})`. The sidecar-failed path at line 257 (`if not ok or not (state.jid and …) then cb({}) end`) does the same, as does the job-exit drain at line 217 (`pcb({})`). None of the three carry any indication that the check did not run.

**Regelbezug.** ERR-11: the callback signature `fun(issues: LanguageSpellIssue[])` has no error channel at all, so "the sidecar timed out / never started / died" is delivered as the same value as "this buffer has no spelling issues". `collect.gather` (collect.lua:207-211) merges that empty list into the results and the panel renders `No spelling issues — nothing to review` (panel.lua:200).

**Auswirkung.** Overstated by the auditor: the buffer is NOT reported clean. `collect.raw_buffer` (collect.lua:142-149) runs `native_cached` unconditionally, so native and LSP issues still reach `cb(post(raw, cfg))` at collect.lua:213 — what silently vanishes is cspell's contribution on top of them. The accurate consequence is a partial result presented as a complete one: with `"cspell_server"` in `spell.providers.buffer`, a sidecar that fails to start, dies, or exceeds the hardcoded 6 s shows only the native subset with no indication that the configured checker did not run, and `state.failed` is never set on the timeout path so it recurs indefinitely. Separately, each timed-out check leaks one libuv timer handle for the session.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/language/spell/providers/custom.lua:52` · `M.scan_async` · confidence **high**

**Befund.** `local ok_cmd, argv = pcall(custom.cmd, scope, cfg)` — if the user's `cmd` function throws or returns something that is not a non-empty argv list, the branch calls `cb({})` and returns. The parse failure at line 66-69 (`if not ok_parse or type(parsed) ~= "table" then cb({}) end`) behaves identically, and line 95 delivers whatever survived shape-filtering with no count of what was dropped.

**Regelbezug.** ERR-11: a broken user-supplied provider is reported as "no spelling issues", identical to a clean scan. Note the sibling `translate/providers/custom.lua` gets this right — it has an `(ok, result)` callback and reports `"translate.custom.cmd did not return an argv list"` and `"translate.custom.parse failed"` as real errors. The spell side dropped that channel.

**Auswirkung.** A misconfigured `spell.providers.custom` is reported as a clean scan. `:Spellcheck cwd` finishes with `[language] 0 spelling issue(s)` and `No spelling errors found`, whether the adapter ran or the user's `cmd` threw, returned a non-list, or `parse` blew up. Since `custom` is the documented escape hatch for checkers the plugin ships no adapter for, first-time misconfiguration is the expected case, and it is the case with zero feedback — the user has no way to distinguish 'my tree is clean' from 'my adapter never ran'. The silent shape-filter drop at lines 73-94 hides a third case: a `parse` that returns the wrong field names yields 0 issues with no count of what was discarded.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/language/translate/files.lua:115` · `deliver` · confidence **high**

**Befund.** In `replace` mode the file is read at line 148, handed to the provider for a network round trip bounded only by `translate.timeout_ms` (8 s default), and then `pcall(fn.writefile, result, abs)` overwrites it — with no re-read or comparison against the content that was translated.

**Regelbezug.** ERR-30 requires every edit computed during a scan to be re-verified against the *current* text immediately before writing and skipped on mismatch. Nothing here re-stats or re-reads `abs`. The plugin's own `spell/core/actions.lua:40-47` does exactly this re-verification for a much shorter staleness window, so the rule is understood in the other domain and simply not applied here.

**Auswirkung.** Destructive and unrecoverable within the plugin: the file is overwritten with a translation of its pre-request content, so any edit saved to that file while its request was in flight is lost with no message. Files are processed strictly sequentially with one full network round trip each (`timeout_ms` default 8000), so a 20-file batch keeps every not-yet-processed file exposed for the whole run — tens of seconds. `fn.confirm` at line 223 asks once before the batch starts and is not a guard against mid-batch drift. Note the exposure is disk-level: a file open in a buffer is overwritten on disk underneath the buffer rather than in it.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/language/translate/init.lua:83` · `M.run_region` · confidence **high**

**Befund.** The byte region (`opts.sr, opts.sc, opts.er, opts.ec`) is read at line 67, sent over the network, and then written back with `pcall(api.nvim_buf_set_text, bufnr, opts.sr, opts.sc, opts.er, opts.ec, result)` in the provider callback — no re-read of that span, no `changedtick` comparison, and not even a fresh `nvim_buf_is_valid`.

**Regelbezug.** ERR-30: the edit must be re-verified against the current text right before writing. Additionally LLS-31 applies to the `pcall` wrapper: a range that has gone out of bounds throws, the pcall swallows it, and the function silently no-ops with no notification — the user sees nothing at all.

**Auswirkung.** The reachable replace paths are narrower than claimed: `:Translate DE cword` uses `opts.output or c.default_output or "popup"` (init.lua:80), and popup does not write. The genuinely affected callers are `:TranslateReplace` (usrcmds/init.lua:254 forces `"replace"`), the operator/motion mappings (`translate/motion.lua:100` passes `output = "replace"`), and the public `language.translate_replace()` (init.lua:91). On those paths the byte span computed before the request is written blind after it: if the user edits the line during the round trip (0.5-8 s, and longer on the motion path, where `choose_target` opens a language picker before the request even starts) the translation lands on whatever bytes now occupy those coordinates. If the coordinates have gone out of range instead, the pcall discards the error and the mapping silently does nothing.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/language/thesaurus/init.lua:146` · `M.replace_under_cursor/apply` · confidence **high**

**Befund.** `word, sr, sc, er, ec` are captured at line 136, then a Datamuse request (up to `thesaurus.timeout_ms`, 6 s) runs and a `ui.kit.select` menu waits for the user; `apply` finally does `pcall(api.nvim_buf_set_text, bufnr, sr, sc, er, ec, { item })` checking only `nvim_buf_is_valid`.

**Regelbezug.** ERR-30: the span is never re-verified to still hold `word`. `spell/core/actions.lua:40-47` performs precisely this check (`nvim_buf_get_text` then compare against `issue.word`) before its own `nvim_buf_set_text`, so the correct pattern exists two modules away and is not used here.

**Auswirkung.** The `ui.kit.select` menu has no timeout, so the window between capturing the span and writing it is bounded only by how long the user takes to pick. Any change to that line meanwhile (another window, format-on-save, undo) shifts the byte offsets and the chosen synonym is written over unrelated text on that line. The `pcall` with no failure branch means an out-of-range span produces no message either, so the keymap looks like it did nothing. Non-destructive relative to the file-overwrite findings (it is a buffer edit and undoable), but silent in both failure modes.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/language/translate/files.lua:140` · `M.process/step` · confidence **high**

**Befund.** `prog:finish(("translated %d file(s) → %s"):format(#picked, target))` reports `#picked` — the number of files the user selected — not the number actually translated and written.

**Regelbezug.** This is exactly the inverse LLS-31 names: "eine Funktion, die ihre Rückgabe aus der geplanten statt der tatsächlichen Arbeit bildet, kann nicht auffallen" (`return #geplant` statt `return #erledigt`). Two skip paths bypass all work and still count: the unreadable-file branch at lines 148-151 (`pcall(fn.readfile)` fails -> `vim.schedule(step)`, no counter) and the failed-translation branch at line 168 (notify.error, then `vim.schedule(step)`).

**Auswirkung.** The one line the user reads after a multi-file run asserts work that may not have happened. With a provider failure partway through a 20-file batch, the run ends with `translated 20 file(s) → DE` after N error notifications have already scrolled by in the same notification stream. In `--files=replace` mode there is no per-file success record either (see the ERR-03 finding on `deliver`), so nothing in the UI tells the user which files were actually rewritten.

### `PERF-46` — Cache-Key vollständig

`lua/language/spell/core/cache.lua:47` · `M.set` · confidence **high**

**Befund.** The whole-buffer native scan is cached as `store[bufnr] = { tick = changedtick, issues = issues }` — keyed on buffer and changedtick only. The result of `native.scan_scope` depends additionally on the active `spelllang` (via `vim.spell.check`), on `word_split.enable`/`min_length`, and on `regions.skip_urls`/`skip_emails`/`treesitter_spell`, none of which are part of the key.

**Regelbezug.** PERF-46: the key must contain every parameter that influences the result, otherwise the cache silently returns results computed for a different configuration of the same input. `collect.native_cached` (collect.lua:123-134) consults it for every `kind == "buffer"` scope.

**Auswirkung.** Reproducible exactly as described: `:Spellcheck en`, `:Spellcheck clear`, `:Spellcheck de` on an unedited buffer returns the cached English issue list — the German check never runs and the user is shown English results labelled as a German session. The same holds for a `spell.word_split` or `spell.regions` change via `setup()` (or a `spelllang` change made outside the plugin) while buffers are already cached: until the buffer is edited or deleted, the stale result is served. Wrong-but-plausible output, not a crash, and it persists for the life of the buffer.

### `SEC-10` — Nie als Prozessargument

`lua/language/translate/providers/deepl.lua:78` · `M.translate` · confidence **high**

**Befund.** The DeepL auth key is passed to curl as an argv element: `"-H", "Authorization: DeepL-Auth-Key " .. key`, where `key` comes from `translate.deepl.api_key` or `$DEEPL_API_KEY`.

**Regelbezug.** SEC-10: tokens must never be an argv element when the target CLI offers a stdin variant. curl does — `-K -` reads its configuration (headers included) from stdin. The rules' own SEC-21 Beleg names this exact remedy for this exact situation in github_stats.nvim's `health.lua`.

**Auswirkung.** For the duration of each translation request the paid DeepL key is a process argument, visible to any local process that can read the process table (`ps auxww`, `/proc/<pid>/cmdline`, `Get-CimInstance Win32_Process`) — a real exposure of a billable credential to anything running as the same or a higher-privileged user. The Windows escalation in the finding is wrong, though: `util/job/init.lua`'s `resolve_argv` (lines 20-40) explicitly returns the argv unchanged when `exepath` ends in `.exe`/`.com`, and `curl` resolves to `curl.exe` on Windows 10+, so there is no `cmd.exe /c` hop and no shell history involvement. Fixing this needs a stdin channel in `job.run`, which today takes only `{ timeout_ms, cwd, on_done }`.

### `SEC-35` — Nutzereingabe nie in einen `-c`-/`:execute`-String

`lua/language/spell/extra_dict.lua:48` · `M.ensure` · confidence **high**

**Befund.** `vim.cmd("silent spellgood! " .. w)` splices each word of the user's `spell.extra_wordlists` tables straight into an Ex command string, wrapped in a `pcall` that discards the result.

**Regelbezug.** SEC-35: a user-controlled token must go to the API as an argument, never into a built command string, because `|` starts a new Ex command there. The plugin already knows this — `spell/core/actions.lua:112-119` uses the table form `vim.cmd({ cmd = "spellgood", bang = …, args = { word } })` and its comment spells out why ("a flagged 'word' containing e.g. `|` must not be able to chain a second Ex command the way `cmd .. word` would have allowed"). That fix was never carried across to the two wordlist loaders. `programming_dict.lua:30` is the same line against `spell/data/programming.lua`, whose own header invites editing it ("Extend freely — it is just a list").

**Auswirkung.** Two consequences, and the mundane one is the likelier: any wordlist entry containing whitespace or another Ex-special makes `:spellgood!` fail, the bare `pcall` eats the error, and the word is silently never added — the user sees it flagged forever with no way to tell why. The injection case requires the user to load a wordlist they did not author (a shared team config, a copied snippet, a generated glossary), and then a `|` in an entry runs the trailing text as an Ex command at every `setup()`. Trust boundary is narrower than 'arbitrary attacker' — the words come from the user's own Lua config — so this is primarily a correctness bug with an injection tail, not a remote-code-execution hole.

### `ERR-02` — Type Guards & Literal Checks

`lua/language/translate/window.lua:128` · `on_change` · confidence **medium**

**Befund.** `if not state.timer then state.timer = vim.uv.new_timer() end` is followed directly by `state.timer:stop()` and `state.timer:start(...)` with no nil check on the `new_timer()` result.

**Regelbezug.** ERR-02/LUA-12: an API return must be type/nil-checked before use. This is the one place in the plugin that does not — `spell/live.lua:115-118` guards it (`if not fresh then return end`), `util/job/init.lua:90` and `:139` guard it (`if timer then`), and `spell/providers/cspell_server.lua:294` guards it. The inconsistency is the evidence that the omission is accidental rather than a considered exemption.

**Auswirkung.** Latent rather than observed: `vim.uv.new_timer()` returns nil only on libuv handle exhaustion, which in practice takes thousands of leaked handles. If it does happen, the consequence is milder than claimed — `autocmd.create` in lib.nvim wraps the callback in `pcall` unless `opts.raw` is set, and `window.lua:266-270` does not set it, so the indexing error becomes one error notification per `TextChanged`/`TextChangedI` keystroke rather than a raw crash. The live-translate refresh never fires again for that window. Worth fixing as a consistency gap with the plugin's own three guarded sites, not as an active defect.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/language/scope/init.lua:140` · `M.parse` · confidence **medium**

**Befund.** The `path=<p>` token from a `:Spellcheck` / `:Translate` / `:TranslateReplace` command line is run through `scope = { kind = "path", path = vim.fn.expand(path) }`.

**Regelbezug.** SEC-34: `vim.fn.expand()` is Vim's *filename* expansion — a backtick span in the argument is a command substitution through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are specials. The rule names the intended remedy for precisely this case ("Wo nur `~` und Umgebungsvariablen gewollt sind: `lib.nvim.cross.fs.expand_path` — kein Shell, kein Globbing, keine Specials"), and `~`-plus-env is all this call site wants.

**Auswirkung.** No cross-user privilege boundary is crossed — the value comes from the user's own command line, so shell execution via a backtick span is self-inflicted and requires the user to paste a hostile path. The consequence that bites in normal use is unintended expansion: `%`, `#`, `<cfile>` and `<cword>` are Vim specials, and a wildcard is glob-expanded (`expand()` returns multiple matches separated by NL characters, not the space-joined string the finding states, or an empty string when nothing matches). The resulting `scope.path` is then handed to a `--files=replace` batch that overwrites files in place, so the command can act on a different target than what was typed with no error and no echo of the resolved path.

> **Abdeckung dieses Laufs.** COVERAGE. I read the rules file end to end, then every Lua file under lua/ except lua/language/spell/data/programming.lua (203 lines of pure string data, sampled only) and the four @types/ meta files (read but annotation-only). That is ~7.6k of the 7.9k LOC in lua/. TESTS/ was inspected structurally (run.lua, spec list, config_spec's DEFAULTS assertions) but not audited line by line — no findings are marked is_test_code, and a dedicated test-code pass was not part of this sweep. node/cspell_server.js is JavaScript and outside the Lua rule set; I did not audit it, so the sidecar's own input handling is uncovered. .claude/, .git/, .deps/ and doc/tags were ignored as instructed; docs/map/ is generated output and was not read.

ALREADY-CREDITED BELEGE, VERIFIED STILL CLEAN. ERR-20 at spell/core/regions.lua — build() returns nil for every failure mode (no filetype, no parser, no highlights query, no @spell capture, parse error) and native.lua:266-278 turns that into "no predicate = all text spellable". Fail-open confirmed, not re-reported. SEC-03 at translate/providers/google.lua — the payload goes through `--data-urlencode` as an argv element; util/job/init.lua builds every command as argv and never a shell string. Confirmed, not re-reported.

WHAT I CHECKED AND FOUND CLEAN. PRIN-10 / LUA-17: zero uses of vim.g/vim.b/vim.w/vim.t or _G in lua/ — all state is module-local behind getters. SEC-30: actions.replace_all_in_buffer uses vim.pesc on the search term and escapes % in the replacement. SEC-15: the DeepL key is read lazily from cfg-or-env, never persisted, and health.lua:125-129 reports presence only. ERR-51/53: config/init.lua uses vim.tbl_deep_extend("force", defaults, …), which the rule explicitly blesses; nested sub-tables are shared with DEFAULTS, but I grepped for writes through cfg()/config.get() and found none, so the latent aliasing is not currently exploited. UI-01: files.lua:223 confirms the replace batch once, not per file. LUA-48: no __mode anywhere; the bufnr-keyed caches use explicit BufDelete cleanup (bindings/autocmds:21 -> spell.on_buf_delete -> cache.invalidate), which is the correct path. PERF-93: every hot-event handler (TextChanged, InsertLeave, WinScrolled, TextChangedI) goes through a debounce timer plus a cheap should_scan guard.

JUDGMENT CALLS I DELIBERATELY DID NOT REPORT. (1) LUA-06 on config/DEFAULTS.lua:54 and :93 — `vim.fn.stdpath("state") .. "/language/…"` is computed at module level. I calibrated against the fleet: casedesk.nvim's DEFAULTS.lua:193 does the same with vim.fs.joinpath(vim.fn.stdpath("data"), …) and survived the 2026-09-12 LUA-06 sweep untouched, so stdpath appears to be treated as naming rather than resolving. Flagging it here would contradict that precedent. (2) The two `cond and X or X` no-op expressions (cspell_server.lua:295 `cfg.scan_debounce_ms and 6000 or 6000`, window.lua:127 `cfg().timeout_ms and 300 or 300`) are real dead expressions that make two timeouts non-configurable, but they are already annotated in-tree with `--- CDX:` comments explaining exactly that (commit 3626c67, "tag no-op timeouts"), and neither breaks the way ERR-60 describes, since the middle operand is a literal and never falsy. Known and documented, so not re-raised as findings. (3) translate/window.lua leaks two scratch buffers per `:Translate!` — M.close closes the windows but never deletes the `nvim_create_buf(false, true)` buffers — a genuine resource leak that no rule in the 76 covers, so it has no home in this report. (4) SEC-11 on the persisted translation history: it stores full source and translated text, but that IS the feature (recall previous translations) and it is off by default, so it reads as the github_stats "convenience artifact" counter-case rather than a violation.

THEMES WORTH THE MAINTAINER'S ATTENTION, BEYOND THE INDIVIDUAL LINES. Two systematic gaps account for most of what I found. First, ERR-11: the spell provider contract `fun(issues: LanguageSpellIssue[])` has no error channel at all, so every provider collapses failure onto `cb({})` — I counted nine such call sites across typos.lua:65, cspell.lua:66, codespell.lua:69, custom.lua:47/53/67 and cspell_server.lua:217/257/299, plus the silent-skip paths in native.lua. The three I reported are the ones with the sharpest user-visible consequence; the fix is one signature change, not nine patches, and it belongs at the contract rather than in each adapter. Second, ERR-30: the spell domain re-verifies edits correctly (actions.lua:40-47, with a comment explaining why), and the translate and thesaurus domains do not — same plugin, same class of write, opposite conclusion. The asymmetry is what makes those three findings high-confidence rather than speculative.

---

## debugging.nvim

**15 Befunde** (8 × high, 1 davon in Testcode). Roh gemeldet: 16.

### `ERR-02` — Type Guards & Literal Checks

`lua/debugging/actions/neotree_safety.lua:29` · `need` · confidence **high**

**Befund.** `need()` returns any value of type `table` from `config.neotree.{quarantine,safety}` unvalidated, and the nine callers then index and call into it with no type guard and no pcall: `wq.is_quarantined()` (53), `wq.health_check()` (54), `safety.backup.show_backup_ui()` (95), `safety.backup.clean_old_backups(7)` (104), `safety.dry_run.toggle()` (114), `safety.queue.status()` (132), `safety.queue.clear()` (141).

**Regelbezug.** ERR-02/PRIN-25 require type guards before foreign-API access, and only the `require` is pcall-guarded here. The module header explicitly claims 'every access is pcall-guarded and degrades gracefully with a clear notification instead of erroring when the target is absent' — the code does not do that, so the documented contract hides the gap.

**Auswirkung.** Real, but narrower than stated: it needs `features.neotree = true` (DEFAULTS.lua:18 ships it `false`) plus a user-injected target of the wrong shape. Under those conditions `:Debug neotree backup-list` throws 'attempt to index a nil value (field \'backup\')' out of the user command as an uncaught error rather than the promised 'not present here' notification, and the module docstring's pcall-guarantee is false for every field access past the top-level table.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/debugging/tools/proc_trace.lua:126` · `M.watch` · confidence **high**

**Befund.** `local seconds = args and args[1] and tonumber(args[1]) or 120` collapses 'no duration given' and 'duration given but not a number' onto the same default of 120.

**Regelbezug.** ERR-10: a typo in the argument must not behave like an omitted argument. The sibling function in the same file, `parse_start_args` (lines 32-35), gets this right — it notifies 'ignoring non-numeric threshold_ms' — so the inconsistency is within one module.

**Auswirkung.** Accurate as filed. `:Debug proc watch 6O` or `30s` opens a 120-second watcher terminal with no message anywhere explaining that the typed value was discarded, so a user timing a freeze reproduction gets a window they did not choose.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/debugging/commands.lua:182` · `registry.indent.run.treesitter` · confidence **high**

**Befund.** `local enable = not (args[1] == "false" or args[1] == "0")` treats every value that is not exactly `false`/`0` — including a missing argument and any typo — as `true`.

**Regelbezug.** ERR-10 again, on the same dispatcher whose `parse_id` (lines 34-43) was already fixed for this exact class: 'no argument' and 'invalid argument' must return distinguishably. A misspelled negative reads as an omitted argument and therefore as the affirmative default.

**Auswirkung.** Accurate as filed. `:Debug indent treesitter flase` clears `cindent`/`smartindent` on the buffer -- the opposite of the intent -- and then prints 'treesitter-prefer mode for lua set to true', confirming an action the user did not request while their indentation behaviour changes.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/debugging/tools/startup.lua:115` · `M.startup` · confidence **high**

**Befund.** `local runs = tonumber(args and args[1]) or 1` maps both 'no run count' and 'run count that is not a number' to 1.

**Regelbezug.** ERR-10: the invalid-argument case is indistinguishable from the omitted-argument case, so a mistyped count is silently swallowed rather than reported.

**Auswirkung.** Accurate as filed. `:Debug performance startup 1O` runs a single cold measurement and prints 'Runs: 1'; nothing in the report or in `:messages` says the argument was discarded, so a user who asked for an averaged benchmark silently gets a one-sample one.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/debugging/views/capture/init.lua:263` · `try_execute` · confidence **high**

**Befund.** `try_execute` (and identically `try_exec2`, line 274) returns `false, nil, "vim.fn.execute returned empty"` both when the `pcall` threw and when `:messages` legitimately produced no output; the thrown error value is discarded. `capture_messages_raw` then reports `"all methods failed"` and `capture_messages` returns failure (lines 346-356).

**Regelbezug.** ERR-11 requires 'empty but ok' to be distinguishable from 'empty because broken'. Both causes are collapsed onto the same status and the same message string, and the author's own 'no messages to capture (empty content)' branch (line 368) is unreachable for these two sources because the empty case already failed upstream.

**Auswirkung.** Verified the user-facing path: `views/init.lua:91-98` does `notify.warn(detail)` on failure. So in a session with no messages yet, `:Debug messages capture` warns 'Failed to capture messages.' plus three troubleshooting suggestions -- a healthy, empty message history reported as a broken capture pipeline. Conversely a genuine `:messages` throw is reported with the text 'returned empty', naming the wrong cause and discarding the actual error. The unreachable branch at line 368 is dead code.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/debugging/autocmds/sources.lua:363` · `select_items` · confidence **high**

**Befund.** `get_scan()` (lines 336-338) hands back the cached `by_event`/`all` tables by reference — `lib.nvim.cache.memory`'s `get()` returns `entry.value` unchanged — and `select_items()` then sorts that very table in place with `tbl_sort` for `sort=event` and `sort=frequency`.

**Regelbezug.** ERR-54: a getter that returns shared internal state by reference turns every consumer into a mutator; here the consumer is a renderer that sorts for display, which is the exact counter-example the rule names. The cache neither copies on read nor documents a live-reference contract.

**Auswirkung.** Within the 5-second cache TTL, a `sort=frequency` or `sort=event` run permanently reorders the cached scan lists, so an immediately following default `:Debug autocmds sources` prints items in the previous run's order instead of file-walk order, and `qf=true` fills the quickfix list in that order. The auditor overstated it: the report carries no sort label (generate_output, lines 385-423, prints only Root/Parser/Total), so nothing is 'labelled as source order' -- the user just sees an unexplained ordering. Self-heals after 5 seconds or with `refresh=true`.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/debugging/terminals/keylogger.lua:75` · `resolve_logfile` · confidence **high**

**Befund.** The logfile path the user typed after `:Debug keylogger start` is passed straight to `vim.fn.expand()`, which is Vim's filename expansion, not a `~`/env expander.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user/buffer text: a backtick span in the argument is a command substitution through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. The module docstring and `usercmds.lua:53` both advertise this argument as a free-form path with PATH completion, so it is unambiguously user text.

**Auswirkung.** A backtick span in the argument is run through `&shell` before any file is touched: `:Debug keylogger start `date`.log` executes `date`. Wildcards (`*`, `?`, `[]`, `{}`, `**`) are also expanded, so a literal path containing them opens and chmods a different file than the user named, or expands to nothing. The auditor's `./#keys.log` example is WRONG -- `expand()` only applies the cmdline-specials `%`/`#`/`<cfile>`/`<cword>` when the string *starts* with them, so a mid-string `#` is left alone; only a bare `%` or `#` as the whole argument resolves to the alternate/current file name. Harm is bounded to the keylogger's own output path, but that path is where every keystroke of a terminal session -- including sudo/ssh/gpg prompts -- gets written.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/debugging/autocmds/sources.lua:319` · `parse_args` · confidence **high**

**Befund.** The `root=` value from the free-form `:Debug autocmds sources|all` argument string is run through `vim.fn.expand()`.

**Regelbezug.** Same SEC-34 violation on a second surface: `val` comes from `table.concat(fargs, " ")` in `commands.lua:107/110`, i.e. straight from the command line, and the `(%w+)=([^%s]+)` pattern happily accepts backticks and Vim specials since they contain no whitespace.

**Auswirkung.** `` :Debug autocmds sources root=`pwd` `` executes the backticked command through `&shell` during what the user believes is a read-only source scan. Note the shell payload cannot contain whitespace (the `[^%s]+` capture truncates at the first space), so this is limited to single-token commands. The auditor's second example is WRONG: `root=%` expands to the *current file name*, `get_scan` then hits `vim.fn.isdirectory(opts.root) ~= 1` (line 341) and notifies 'autocmd sources: root is not a directory: <name>' -- it fails loudly, it does not silently scan the wrong tree.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/debugging/markdown/inline_debug.lua:355` · `M.gather` · confidence **medium**

**Befund.** `vim.fn.mkdir(debugfolder, "p")` is called unguarded, in a function that otherwise reports every failure through its documented `(ok, err)` return and whose caller (`commands.lua:192-195`) only handles that return.

**Regelbezug.** ERR-01 requires `pcall` at filesystem boundaries. `mkdir()` raises E739 rather than returning 0 whenever the directory cannot be created (permission denied, a plain file already sitting at `stdpath('data')/debuglog`), and the surrounding comment shows the author already hit one raising variant of this call.

**Auswirkung.** When the directory cannot be created -- permission denied, or a plain file already occupying `stdpath('data')/debuglog` or `.../markdown_inline` -- `vim.fn.mkdir` surfaces the failure as a raised error rather than a 0 return, so `:Debug markdown inline` aborts with an uncaught E739 out of the user command instead of the 'markdown inline: ...' notification the dispatcher is written to show. The function's advertised `(ok, err)` contract is bypassed for this one boundary.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/debugging/autocmds/sources.lua:490` · `runtime_by_event` · confidence **medium**

**Befund.** When `pcall(vim.api.nvim_get_autocmds, {})` fails, the function returns the same empty table it returns when there genuinely are no registered autocmds; the error value is dropped and no caller can tell the two apart.

**Regelbezug.** ERR-11: 'nothing to report' and 'failed to determine' must be distinguishable. `M.all()` consumes the result at line 515 and has no way to know which case it got.

**Auswirkung.** Much weaker than filed. The structural collapse is real, but I found no reachable failure path: `nvim_get_autocmds({})` takes no options to reject and always returns Neovim's own core registrations, so neither the 'failed' branch nor the 'genuinely empty' branch is reachable in practice. This is a latent ERR-11 shape defect in a defensive branch, not a bug a user can hit today -- the auditor's scenario of `:Debug autocmds all` reporting 'Runtime registrations: 0' has no demonstrated trigger.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/debugging/config/init.lua:23` · `M.setup` · confidence **medium**

**Befund.** `vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), user_opts)` merges the user table with no key validation anywhere — neither before the merge nor after, and `health.lua` never reports unknown keys either.

**Regelbezug.** ERR-50 exists precisely because 'ein Tippfehler in einer verschachtelten Option verschwindet sonst stillschweigend im Default und wird nie erkannt'. With `tbl_deep_extend("force")` and no known-key check, every misspelled key is accepted and stored, and nothing ever surfaces it — the deep merge makes a nested typo completely invisible.

**Auswirkung.** Accurate as filed. `setup({ feature = { neotree = true } })` (singular) or `{ views = { timing = { attempts = 5 } } }` is merged in silently: the junk key is stored in the active config, the intended setting never takes effect, and `:checkhealth debugging` reports the plugin healthy. Because `features` is the gating surface the whole `:Debug` dispatcher reads (commands.lua `enabled(entry)`), a typo there leaves a category disabled with the user believing they enabled it -- and the deep merge makes the nested typo invisible.

### `ERR-62` — `pcall(f(args))` fängt nichts

`lua/debugging/terminals/keylogger.lua:167` · `M.start` · confidence **medium**

**Befund.** `pcall(vim.uv.fs_chmod, M.logfile, 384)` indexes `vim.uv` before `pcall` is entered, so the protection covers only the chmod call, not the lookup of the function.

**Regelbezug.** Same mechanism as ERR-62: the expression that can throw is evaluated outside the `pcall`. `vim.uv` only exists from Neovim 0.10, while README/`docs/installation.md`/`health.lua:39` all state 0.9+, and this repo's own `views/debug_helper.lua:233` uses the `(vim.uv or vim.loop)` form. The inline comment states the intent explicitly — 'must not stop logging' — which this construction does not deliver.

**Auswirkung.** On Neovim 0.9 (a version this plugin's README, installation doc and healthcheck all declare supported), `:Debug keylogger start <path>` throws 'attempt to index a nil value (field \'uv\')' out of the user command after the logfile has been opened and its session header written but before `M.logging = true`. The `io` handle in `_fh` is then leaked for the rest of the session because `M.stop()` bails on `M.logging == false`, and no keys are ever recorded. The inline comment's stated intent -- chmod is best-effort and 'must not stop logging' -- is exactly what this construction fails to deliver.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/debugging/views/init.lua:43` · `M.setup` · confidence **medium**

**Befund.** `_timings = vim.tbl_extend("force", _timings, opts.timings or {})` merges into the *current* timings table, while the two statements immediately below rebuild `_keymaps_cfg` (45) and `_autocmds_cfg` (50) from freshly written literal defaults.

**Regelbezug.** This is the `reposcope` counter-case named under LUA-87: `setup()` must merge into a defaults copy, not into the live options table, otherwise values accumulate and a later `setup({})` resets nothing. The asymmetry with the two sibling assignments in the same function shows the intended shape.

**Auswirkung.** Accurate as filed. A second `require("debugging.views").setup({})` -- the subsystem entry point per its own docstring, used by config-reload and test flows -- leaves `attempts`, `capture_timeout_ms` and the three delays at whatever the previous call set, while `_keymaps_cfg` and `_autocmds_cfg` in the same function do snap back to defaults. The resulting configuration is a mixture of two setups that matches neither, and there is no way to reset the timings short of reloading the module.

### `PRIN-20` — Keine stillen Fehler

`lua/debugging/views/utils.lua:173` · `M.focus_and_bottom` · confidence **medium**

**Befund.** `M.force_focus(win)` returns a boolean success flag that is discarded; execution continues unconditionally to `vim.cmd("normal! G")` at line 186, which acts on whatever window is current rather than on `win`.

**Regelbezug.** PRIN-20/ERR-03: the failure is reported by the callee and then dropped, so a failed focus becomes a silent no-op that still performs its follow-up action. Every other handle operation in this file is checked; this one return value is the exception.

**Auswirkung.** Real but narrower than filed. Line 185 already does `pcall(api.nvim_win_set_cursor, win, { last, 0 })`, so `win` itself is scrolled correctly even when focus failed -- the auditor's 'the debug view is never focused, no error is reported' holds, but the view is not left unscrolled. The concrete damage is line 186: `normal! G` fires in whatever window is still current, moving the cursor to the last line of the buffer the user is actually editing. Requires `nvim_set_current_win` or `make_focusable` to fail (textlock, cmdline-window, a window closed between the deferred callback and this line), which is uncommon.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`TESTS/capture_spec.lua:181` · `capture_spec` · confidence **medium** · _Testcode_

**Befund.** `vim.fn.glob(tmp_dir .. "/messages-*.log", false, true)` feeds a raw path built from `vim.fn.tempname()` into `glob`, then asserts the result has exactly one entry.

**Regelbezug.** XP-01: `glob` reads its argument as a pattern, not a path. Under Windows `$TEMP` is the 8.3 short form for any profile name over eight characters (`C:/Users/STEFAN~1/…`), glob tries to resolve `~1` as a home-directory reference, finds no such user and returns an empty list without raising. The rule's prescribed replacement is `lib.nvim.fs.globbable`.

**Auswirkung.** Latent, not currently firing -- the auditor's impact is conditional and does not reproduce on this machine. `$TEMP` only degrades to the 8.3 short form for profile names over eight characters, and this profile is `bartl` (five), so `tempname()` yields a path with no `~` and the assertion passes; CI is Linux-only, so it cannot surface there either. The real consequence is a portability trap: on a Windows profile with a long name the spec would fail at 'capture: save_file wrote exactly one timestamped logfile (expected 1, got 0)' and then error indexing `written[1]`, pointing the reader at `capture.capture_messages` rather than at the glob.

> **Abdeckung dieses Laufs.** Coverage: I read every Lua file under lua/ and plugin/ in full (4805 LOC), scripts/watch-nvim-procs.ps1 in full, README.md, docs/installation.md, .luacheckrc/.luarc.json, the CI workflow, TESTS/run.lua and TESTS/harness.lua in full, and the relevant sections of TESTS/capture_spec.lua and TESTS/tools_spec.lua. I did not read the remaining 14 spec files line by line — I grepped them for the rule-specific patterns (expand/glob/system/popen/vim.cmd/timers/__mode) and followed up only on hits, so test-code coverage is pattern-driven rather than exhaustive.

What I could not verify, and why:
- CMT-16 (never hand-edit a generated file): docs/map/{index.html,module_map.json,overview.md} and docs/BINDINGS.md are generator output, but the generator (:DocMap / gen_map) lives outside this repo and this is a report-only task, so I could not regenerate and diff to detect drift. Unchecked.
- SEC-35 (user input into a vim.cmd string): lua/debugging/markdown/inline_debug.lua:387 builds `echohl ModeMsg | echo '%s' | echohl None` by interpolation. I did NOT report it: the author escapes single quotes correctly via esc_squote (line 377-379), `|` inside a quoted Vimscript string is inert, and the only residual break needs a newline byte inside vim.g.colors_name or the filetype — editor state the user sets themselves. Worth a second opinion, but I could not construct a realistic break.
- LUA-92 (an adapter must not require its plugin): views/capture/init.lua:157 and views/debug_helper.lua:36 call `pcall(require, "noice")` outside :checkhealth, so under a lazy manager `:Debug messages capture` can itself load and activate noice.nvim in a session where it was never triggered. The rule is scoped to setup()/attach hooks, which this is not, so I left it out rather than stretch the rule; `package.loaded["noice"]` would be the conforming form.
- LUA-01 (hard vs soft dependency): the plugin is consistently hard (bare top-level `require("lib.nvim.*")` in 20 files, incl. the dispatcher) and docs/installation.md lists lib.nvim as required, so the rule is satisfied. Two nits I did not raise as findings: health.lua grades missing `lib.nvim.notify`/`lib.nvim.window` as "warn" although both are bare-required by commands.lua:18-19 (only the composer is "error"), and five hard requires are never checked at all by health — lib.nvim.ui.list, lib.nvim.cross.copy_to_clipboard, lib.nvim.bindings.autocmd, lib.nvim.bindings.keymap, lib.nvim.lua_ls.get_module_path.
- Neovim 0.9 support in general: README/health claim 0.9+, but lib.nvim (a hard dependency) uses bare `vim.uv` in 23 places, and `nvim_win_get_config` returns no width/height for split windows on 0.9 — which display.lua:103 and utils.lua:169 compare against 1 unguarded. I reported only the keylogger instance because its consequence is local and specific; the broader 0.9 claim looks untrue fleet-wide and is better settled as one decision than as per-file findings. CI runs stable Linux only, so nothing here is exercised.
- ERR-54 on config.get(): `config/init.lua:37-42` hands out the live `_active` table with neither a copy nor a documented live-reference contract. I did not report it because I traced every consumer and none mutates it today — it is a latent risk, not a present defect.

Rules I checked and found the plugin compliant with (not merely inapplicable): ERR-20/PRIN-27 (missing Tree-sitter Lua parser falls back to the text scanner, i.e. fail-open), ERR-33/LUA-13 (every vim.defer_fn callback re-validates its window handle), ERR-51 (setup merges into vim.deepcopy(DEFAULTS)), ERR-60 (I traced all 36 `and … or` sites; none has a falsy middle operand), LUA-06 (config/DEFAULTS.lua is pure data), LUA-02 (the clipboard command-injection fix was upstreamed to lib.nvim rather than patched locally), PERF-42 (the scan cache carries a 5s TTL), PERF-72 (default scan root is stdpath("config")/lua), PERF-92 (no module-level geometry), PERF-93 (no handler on a hot event), SEC-01/03 on the process side (proc watch and the startup benchmark both spawn via argv, never a shell string), SEC-30 (every user-supplied needle uses find(..., plain=true)), XP-06 (no mixed-case module paths).

---

## pdfport.nvim

**15 Befunde** (6 × high, 2 davon in Testcode). Roh gemeldet: 18.

### `ERR-03` — Explizite Rückgaben

`lua/pdfport/core/rasterize.lua:106` · `M.render_page` · confidence **high**

**Befund.** `uv.spawn("pdftoppm", {...}, cb)` is called with its return value discarded. I verified in this Neovim that a failing spawn returns `nil, "ENOENT: no such file or directory"` rather than raising, so on failure neither the exit callback nor `callback` ever runs, and the `stderr` pipe created at line 95 is never closed (its only `close()` is inside the exit callback at line 110).

**Regelbezug.** ERR-03 requires relevant functions to return an explicit success/failure and forbids silent failure. `M.render_page` takes a `callback(png_path, err)` contract and has an error path for every other failure (missing pdftoppm, pipe creation, non-zero exit) — this one alone settles never.

**Auswirkung.** Any spawn failure -- the binary disappearing or PATH changing after has_exec memoized its answer, EACCES, or fd exhaustion -- leaves the callback unsettled forever. The public `pdfport.render_page()` (init.lua:190-201) then never calls back, so its two documented consumers (hover.nvim's PDF preview, images.nvim's picker preview) wait on a promise that can never resolve, with no error anywhere. renderers/terminal.lua's page chain stops silently at that page (the `render_next` recursion only continues from inside the callback). One uv pipe handle leaks per attempt, since its only `close()` is in the exit callback.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/pdfport/integrations/telescope.lua:90` · `M.filetype_hook` · confidence **high** · _Testcode_

**Befund.** The extraction callback does `local text = result.text or ""` and writes that into the preview buffer, discarding `result.error` entirely. The other previewer in the same file (`define_preview`, line 63) does the opposite: `result.text or ("-- pdfport error: " .. (result.error or "unknown") .. " --")`.

**Regelbezug.** ERR-11: a result that can legitimately be empty must stay distinguishable from "empty because it broke". Here a failed extraction (no backend available, backend timed out, backend threw) and a genuinely empty PDF both render as a blank buffer with filetype `markdown` (line 94).

**Auswirkung.** Under the second documented usage (`preview = { filetype_hook = pdfport_tel.filetype_hook }`, telescope.lua:11-17) every PDF previews as an empty pane when extraction fails -- no backend installed, backend timed out, backend threw -- and the error text that `dispatcher.err_result` went to the trouble of composing is thrown away at the last step. The user reads it as "this PDF has no text" and has no route to the real cause except guessing to run `:checkhealth pdfport`. Single-picker users of `M.previewer` are unaffected; this is the global-hook path only.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`TESTS/run.lua:73` · `run.lua main loop` · confidence **high** · _Testcode_

**Befund.** `local run = dofile(dir .. name)` sits outside the `pcall` on the next line, so an error raised while *loading* a spec (syntax error, a missing file in the `specs` list, a top-level `require` that fails) aborts run.lua before `os.exit(1)` at line 84 is ever reached. The same applies to `dofile(dir .. "harness.lua")` at line 11.

**Regelbezug.** ERR-11: "nothing to report" must be distinguishable from "failed while determining". I verified empirically that `nvim --headless -u NONE -c "luafile <erroring file>" -c "qa!"` prints E5113 and exits **0** — so the CI gate cannot tell "every spec passed" from "the runner never ran".

**Auswirkung.** The CI test job cannot distinguish "all 20 specs passed" from "the runner aborted before asserting anything". A syntax error in any spec, a spec renamed without updating the `specs` list at :26-61, or a broken harness.lua produces a green check with zero assertions executed -- the failure prints E5113 into the log and the job still exits 0. The sentinel at :88 exists for precisely this and is unused, so the fix is one grep in the workflow plus moving `dofile` inside the pcall.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/pdfport/backends/docling.lua:104` · `M.extract` · confidence **high**

**Befund.** The generated Python script (lines 37-54) assigns `max_pages = %d` and then never reads it — `converter.convert(path)` / `export_to_markdown()` always process the whole document — yet the success result reports `pages_processed = max_pages > 0 and max_pages or nil`.

**Regelbezug.** LLS-31's stated inverse: a function that forms its return value from the *planned* rather than the *performed* work cannot be noticed (`return #geplant` instead of `return #erledigt`). The sibling backend `pdfplumber.lua:42` does apply the slice (`pdf.pages[:max_pages]`), and `docs/FEATURES/BACKENDS.md:155-158` states the project's own standard for claude/gemini: "`pages_processed` stays `nil` rather than claiming otherwise".

**Auswirkung.** `max_pages` is silently dropped: `extract({ max_pages = 5 })` against a 300-page PDF converts all 300 pages through docling, which is the expensive half of a run the caller explicitly asked to bound, and there is no timeout escape short of `timeout_ms` (default 120000). The returned `pages_processed = 5` is a fabricated number on the public `PdfPort.Result` contract and gets persisted under that lie by util/cache.lua:75, so it survives restarts. No in-tree consumer reads the field today (the buffer header at renderers/buffer.lua:91-98 does not), so the damage is the wasted work plus a public API field that reports planned rather than performed work to any embedder that trusts it.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/pdfport/util/page_range.lua:51` · `M.prompt` · confidence **high**

**Befund.** `M.prompt` calls a bare `require("ui.kit").input({...})` with no pcall and no fallback, while `util/picker.lua:138` treats the very same module as soft (`pcall(require, "ui.kit")` + `vim.ui.select` fallback) and `health.lua:407` reports a missing ui.kit as harmless info.

**Regelbezug.** LUA-01 requires a dependency to be hard OR soft consistently, and forbids presenting a hard dependency as optional in the docs. `docs/requirements.md:17` lists ui.nvim as optional and states the page-range prompt "falls back to `vim.ui.select`/`vim.ui.input` when absent" — that fallback does not exist in the code.

**Auswirkung.** With ui.nvim not installed, every path that prompts for a page range raises `module 'ui.kit' not found` instead of prompting: `:PdfPort float <path>` and `:PdfPort terminal <path>` without an explicit `pages=`, and choices 8 and 9 of the mode picker. The picker's own soft fallback at picker.lua:138-156 makes this worse, not better -- it succeeds via vim.ui.select and then hands the user straight into the hard require. The docs actively promise the opposite (requirements.md:17), and :checkhealth calls the missing module harmless. The suite stays green because the only ui.kit-absent test picks a choice that never reaches the prompt.

### `PERF-46` — Cache-Key vollständig

`lua/pdfport/integrations/fzf.lua:14` · `_cache` · confidence **high**

**Befund.** `local _cache = {}` is module-level and keyed by `filepath` alone (read at line 34, written at line 48), while the extraction it caches is parameterised by `opts.backend_id` and `opts.max_pages` (lines 43-44), which are per-`preview_fn` and not part of the key.

**Regelbezug.** PERF-46 requires the key to contain every parameter that influences the result ("Pfad + Backend + Variante"), otherwise the cache silently serves the wrong result for a different configuration of the same input. The plugin's own `util/cache.lua:22-24` gets this right with `path::backend::variant`.

**Auswirkung.** Two fzf-lua pickers configured with different `preview_fn` opts in one session share one table, so whichever previewed a given PDF first wins for the rest of the session: a `{ backend_id = "marker" }` picker shows the earlier `{ backend_id = "pdftotext", max_pages = 1 }` extraction, freshly rendered and indistinguishable from a real result. Two further consequences the finding did not name: line 48 caches failures too, so one transient backend error is pinned as that file's preview permanently, and line 35 forces filetype `markdown` on every hit even when the cached text is plain. Nothing checks mtime either, so editing the PDF does not invalidate it -- unlike util/cache.lua, which does.

### `ERR-31` — `O_CREAT|O_EXCL` statt Check-dann-Erzeugen

`lua/pdfport/core/composer.lua:90` · `resolve_conflict` · confidence **medium**

**Befund.** The `on_conflict = "suffix"` branch loops `if not uv.fs_stat(candidate) then return candidate end`, then hands that path to an external CLI (`create_opts.output`, line 250) that opens and writes it seconds to minutes later — the classic check-then-create sequence with no atomic claim on the name.

**Regelbezug.** ERR-31: "only create if it does not exist" must be expressed as `O_CREAT|O_EXCL` (treating `EEXIST` as success), not as a stat followed by a create. `"suffix"` exists precisely to express "do not clobber anything", and the implementation cannot honour that promise.

**Auswirkung.** The TOCTOU window is not microseconds -- it is the full producer run, bounded only by `create_opts.timeout_ms` (default 60000 per DEFAULTS.lua:46) and covering soffice's first start, a pandoc+LaTeX run or a headless Chromium print. Anything that creates `report-1.pdf` in that window -- a second `pdfport.create()`, another Neovim instance, an unrelated process -- has its file overwritten by the producer, under the one `on_conflict` setting the user picked to prevent exactly that, and with no error reported. Claiming the name with `O_CREAT|O_EXCL` before handing it over (treating EEXIST as "try the next suffix") closes it without changing the producer contract.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/pdfport/config/init.lua:16` · `M.setup` · confidence **medium**

**Befund.** `_cfg = vim.tbl_deep_extend("force", defaults(), opts or {})` is the entire setup path. There is no known-keys check, no "did you mean…", no arity/type validation — neither before the merge nor after it — and no `:checkhealth` section reports on the user's config at all (health.lua has ten sections, none of them config).

**Regelbezug.** ERR-50 requires config validation (unknown keys, "did you mean") to run before the merge, precisely so a typo in a nested option does not vanish into the default and stay undetected. `vim.tbl_deep_extend("force", …)` is the opposite: it happily adopts any key the user invents.

**Auswirkung.** Any user config key is adopted verbatim with no signal of any kind. A nested typo (`extract_opts.max_page`) is stored and never read, so the option appears to do nothing forever; a wrong-typed `fallback_chain = "pdftotext"` makes the resolver's chain loop a no-op and falls through to the registry-order chain, which looks like the plugin ignoring the setting; a misspelled `render_opts.split` silently degrades to the current window. Because :checkhealth has no config section at all, there is no surface anywhere in the plugin where the user could discover any of this -- the only diagnostic is `require("pdfport").config()`, which is undocumented.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/pdfport/backends/pdfplumber.lua:34` · `M.extract` · confidence **medium**

**Befund.** `opts.pages` (the explicit page list) is never read: only `opts.max_pages` reaches the Python script. Same in `backends/marker.lua:56` (only `--max_pages`) and `backends/docling.lua:35` (neither). Only `pdftotext.lua:37-41` and the two page-looping backends honour `opts.pages`.

**Regelbezug.** LLS-31 / "fail loudly, never silently no-op": the backend accepts the request, ignores the page selection, and returns `status = "ok"` for the whole document. The project documents this limitation for claude and gemini (`docs/FEATURES/BACKENDS.md:155-161`) and is careful there to leave `pages_processed` nil; for these three backends it is neither documented nor signalled.

**Auswirkung.** `:PdfPort float report.pdf pages=2-3` on a machine without pdftotext resolves down the default chain (DEFAULTS.lua:12-28) to pdfplumber, marker or docling, all of which return `status = "ok"` for the entire document -- the page selection is accepted and discarded with no warning and no degraded-result marker. The cache then compounds it: dispatcher.lua:205/271 stores that whole-document text under the variant key "2,3", so every later `pages=2-3` request against the unchanged file is served from a cache entry that looks correct and is not, across restarts. pdfplumber's own `pages_processed` is not itself a lie here (it stays nil when only `pages` was given); the lie is the `ok` status.

### `PERF-42` — Invalidierbar

`lua/pdfport/util/cache.lua:71` · `M.set` · confidence **medium**

**Befund.** The disk store is append-only: `M.set` only ever adds a key, and `M.get` returns nil early at line 40 when the source file no longer exists — without removing the entry. There is no size cap, no entry count cap, no TTL, and no age-based sweep. `M.clear()` (line 82) is the only removal path and is wired to no command, keymap or autocmd — `docs/configuration.md:138` tells the user to call it by hand.

**Regelbezug.** PERF-42 requires a defined point at which an entry becomes invalid. mtime invalidation makes a *stale* entry unreadable but never *removes* it, so entries for deleted, renamed or moved PDFs, and every superseded (path, backend, variant) combination, live forever.

**Auswirkung.** Invalidation by mtime is defined and works for live files, but there is no point at which an entry is ever *removed*: entries for deleted, renamed or moved PDFs, and every superseded (path, backend, variant) combination, stay in the store permanently and unreachable. Since lib.nvim's disk cache holds one JSON file per namespace with no memoization, every extraction and every cache probe -- including the hit that is meant to be the fast path -- parses the entire accumulated store and, on a miss, re-serialises all of it. Each entry holds a PDF's full extracted text, so the per-open cost grows monotonically with the number of PDFs ever opened and never shrinks, and the only remedy shipped is an undocumented-in-UI manual function call.

### `SEC-15` — API-Keys nie selbst verwalten

`lua/pdfport/init.lua:162` · `M.config` · confidence **medium**

**Befund.** `M.config()` returns `vim.deepcopy(config.get())`, i.e. the whole merged config table including `claude_api_key` and `gemini_api_key` in cleartext, as an undocumented-but-public function on the plugin's main module.

**Regelbezug.** SEC-15: a plugin holds no central key store and does not put the value anywhere it controls; `:checkhealth` reports at most present yes/no. Accepting the key into `_cfg` (`config/init.lua:16`) and then handing the whole table to any caller makes the plugin exactly the key store the rule forbids.

**Auswirkung.** For users who took the documented `setup({ claude_api_key = ... })` route rather than the env var, the key is held for the session in a table the plugin hands out whole, with no redaction path. `:lua vim.print(require("pdfport").config())` -- the ordinary way to inspect a plugin's settings, and exactly what one pastes into a bug report or has on screen while sharing -- prints both API keys in cleartext. Nothing is written to disk, so this is session-scoped exposure, not persistence; the fix is either to redact these two keys in `M.config()` or to drop the config-option route in favour of the env var that backends/claude.lua:53 already falls back to.

### `SEC-15` — API-Keys nie selbst verwalten

`lua/pdfport/health.lua:207` · `check_backends` · confidence **medium**

**Befund.** The key checks read only `vim.env.ANTHROPIC_API_KEY` (line 207) and `vim.env.GEMINI_API_KEY` (line 220). Neither consults `config.get().claude_api_key`/`.gemini_api_key`, although `backends/claude.lua:53` and `backends/gemini.lua:51` prefer exactly those over the environment.

**Regelbezug.** SEC-15 defines what :checkhealth owes the user for a key: present yes/no and which provider is active. A user who set the key through `setup()` — the route `docs/configuration.md:41,43` offers — gets "not set" and "backend unavailable", which is false.

**Auswirkung.** A user who set the key through `setup()` -- the route docs/configuration.md:41,43 offers as equal to the env var -- gets one `:checkhealth pdfport` run that contradicts itself: "ANTHROPIC_API_KEY not set - claude backend unavailable" (warn, with a remediation hint telling them to export it) in the extraction-backends section, and `claude  available` (ok) in the registered-backends section eleven sections later. The advice is actively wrong: there is nothing to fix, and following the hint writes the key into the environment for no reason. Same for gemini at :220.

### `SEC-21` — Timeout **und** Byte-Limit

`lua/pdfport/health.lua:180` · `check_backends` · confidence **medium**

**Befund.** `vim.fn.system({ "curl", "-s", "-w", "\n%{http_code}", "http://localhost:11434/api/tags" })` — a blocking, synchronous HTTP fetch with no `--max-time`, no `--connect-timeout` and no `--max-filesize`, whose whole response body is read into a Lua string just to regex out the trailing status code (line 181).

**Regelbezug.** SEC-21 requires a fetch to carry both a timeout and a byte limit, not one or the other. This has neither. The plugin already knows the pattern — `producers/*.lua` all pass `timeout_ms` to `spawn_capture`, and `docs/FEATURES/BACKENDS.md:145` notes ai.nvim passes curl its own `--max-time`.

**Auswirkung.** On a machine that has the ollama binary but where port 11434 is filtered rather than refused -- a firewall that drops instead of resetting, a VPN, a container network -- `:checkhealth pdfport` blocks the whole editor inside `vim.fn.system` for curl's default connect timeout, uninterruptibly and with no partial output, in the middle of a diagnostic command whose whole point is to be run when something is already wrong. If anything other than ollama answers on 11434, the entire response body is read into memory with no ceiling. Both are one flag each (`--max-time`, `--max-filesize`) on a call site that already builds its argv as a list.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/pdfport/util/cache.lua:48` · `M.get` · confidence **medium**

**Befund.** The persisted entry's fields are handed back untouched: `text = entry.text`, `format = entry.format`, `backend = entry.backend`, `pages_processed = entry.pages_processed`. The only check performed on a loaded entry is `entry.mtime ~= file_mtime` (line 46) — no type check, no length cap, no count cap on the store.

**Regelbezug.** SEC-33: persisted snapshots are untrusted and every field must be re-validated on load (type, length, count cap). The store is a JSON file under `stdpath("cache")`, written and read across sessions, and its contents flow straight into buffer APIs.

**Auswirkung.** The reachable trigger is narrower than claimed: it needs a store file that still decodes as valid JSON but carries a non-string `text` -- a hand-edited store, a third-party writer, or a JSON `null` decoding to `vim.NIL`. Truncation does not do it. When it happens, the value flows unvalidated through `M.get` into `vim.split(result.text or "", ...)` at renderers/buffer.lua:82 and raises. In `dispatcher.M.open` that is caught and mis-reported as "renderer 'buffer' failed", pointing at the renderer instead of the cache, and since the entry is never removed the PDF stays unopenable through the cache path until the user finds and deletes the store by hand. In the telescope and fzf previewer `__callback`s it raises uncaught inside the picker. A `type(entry.text) == "string"` guard at :46 costs one line.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/pdfport/bindings/usrcmds.lua:56` · `resolve_path` · confidence **low**

**Befund.** `if explicit and explicit ~= "" then return vim.fn.expand(explicit) end` runs Vim's filename expansion over the `path` argument of every `:PdfPort` route. The same at line 266 for `:PdfPort merge`'s output path. That argument is routinely filled by the plugin's own completion, which lists real directory entries via `vim.fn.glob(arg_lead .. "*", false, true)` (line 27).

**Regelbezug.** SEC-34: `vim.fn.expand()` treats a backtick span as a command substitution through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` as specials — so it must never be applied to text that is not a static, plugin-owned string. Where only `~` and environment variables are wanted, the rule names `lib.nvim.cross.fs.expand_path`.

**Auswirkung.** Narrow trigger, real mechanism. A PDF whose filename contains a backtick span -- plausible in a cloned repo, an extracted archive or a download directory, none of which the user controls the naming of -- is offered by `<Tab>` completion (usrcmds.lua:27 globs it in, :43 validates everything as fine), inserted verbatim into the command line, and then executed as a shell command by `expand()` the moment the user presses Enter. `%`, `#`, `<cfile>` and `<cword>` in a filename are mangled by the same call. The expansion buys nothing the rule's own helper would not: swapping in `lib.nvim.cross.fs.expand_path` at :56 and :266 keeps `~`/`$VAR` and removes the shell entirely.

> **Abdeckung dieses Laufs.** Coverage and caveats.

WHAT I READ IN FULL: every file under lua/ (51 modules, 6487 LOC incl. plugin/pdfport.lua), README.md, docs/requirements.md, docs/FEATURES/BACKENDS.md, the on_conflict/max_pages sections of docs/configuration.md and docs/FEATURES/CORE.md, TESTS/run.lua, .github/workflows/ci.yml, and the relevant parts of TESTS/picker_batch_spec.lua (to confirm the ui.kit gap is genuinely untested). Ignored as instructed: .claude/, .git/, doc/tags.

TWO BEHAVIOURS I VERIFIED EMPIRICALLY rather than reasoned about, both against the local Neovim: (1) `uv.spawn` on a missing binary returns `nil, "ENOENT: ..."` and does not raise — this is what makes the rasterize.lua finding a never-settling callback rather than a caught error; (2) `nvim --headless -u NONE -c "luafile <file that errors>" -c "qa!"` prints E5113 and exits **0** — this is what makes the TESTS/run.lua finding a silently-green CI gate.

RULES THAT GENUINELY HAVE NO SURFACE HERE (checked, not assumed): TS-04 (no `vim.treesitter` anywhere), LUA-48 (fleet grep for `__mode` returns zero hits in lua/ and TESTS/), PERF-07 (no `next(t)`-based delete loops), PERF-62 and PERF-82 (no debounce or background timers at all; the four `vim.defer_fn` calls in renderers/terminal.lua are one-shot PNG cleanups), PERF-72 (no directory scanning or auto-detected roots), PERF-92 (the only geometry, renderers/terminal.lua:46-47, is computed per display, not at module level — correct), PERF-93 (no autocmd on a hot event; the only two are a FileType dispatcher and an opt-in BufReadCmd), UI-55 (no buffer deletion anywhere), SEC-20 (no binary downloads), SEC-40 (no server-like surface), LUA-17 (`vim.g` is used only for a boolean load guard), ERR-30 (no in-place text edits), LUA-90/91/92/93 (no foreign-plugin `setup()` calls, no LSP adapter, no lazy specs in-repo).

RULES I CHECKED AND FOUND CLEAN: LUA-06 (config/DEFAULTS.lua is a pure-data factory function, no env or FS lookup at module level — this plugin is on the right side of the reposcope/pickers/casedesk sweep), ERR-51 (defaults() returns a fresh table per call, so the merge cannot mutate shared defaults), ERR-53 (`_set_config` hands the whole config table around; no submodule caches a subtable, and every consumer re-reads through `_config.X` at call time), ERR-54 (the public `M.config()` deepcopies; internal holders never mutate), SEC-03/SEC-35 (every external tool is invoked through argv — `spawn_capture`/`uv.spawn`/`vim.system` — with zero shell-string construction across all nine producers and all eight backends; the three `vim.cmd("split | terminal …")` calls in renderers/terminal.lua interpolate only a plugin-generated `tempname()` PNG, shellescaped, and `:terminal` does not treat `|` as a command separator), SEC-11/SEC-13 (nothing is logged or persisted beyond the extracted text the user asked for), PERF-80 (both fast-event callbacks — rasterize.lua:111 and ollama.lua:109,270 — wrap their API access in `vim.schedule`, with the reason written down).

WHAT I COULD NOT COVER. (a) CMT-16: docs/map/ is generated output and docs/BINDINGS.md may be too, but I did not run `:DocMap`/the renderer, so I cannot say whether either has drifted or been hand-edited — that needs a regeneration diff, not a read. (b) The LUA-16 finding depends on ai.nvim's contract for `Ai.Response.text`, which lives in a different repo I did not open; if ai.nvim guarantees a string, that finding collapses to a style note. (c) SEC-01/SEC-02 and the `lib.nvim` side of every delegated call (`spawn_capture`, `cache.disk`, `open_default`, `deps.detect`, `make_scratch`, `run.env`) are out of scope here — pdfport's ERR-11 correctness for the disk cache in particular rests entirely on lib.nvim's `read_entry()`, which the rules file records as already fixed at the root. (d) I read the test suite only where it bore on a specific finding; I did not audit all 6223 LOC under TESTS/ for its own defects.

---

## reposcope.nvim

**15 Befunde** (8 × high). Roh gemeldet: 15.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/reposcope/state/query_stats.lua:37` · `M.load` · confidence **high**

**Befund.** A corrupt/unparseable `query_stats.json` sets `_cache = {}` and returns it, exactly as a missing file does — no backup of the original bytes is taken.

**Regelbezug.** ERR-11 requires "empty but ok" (file missing) to be distinguishable from "empty because broken" (file corrupt). Both collapse to the same empty table here, and `_save()` unconditionally rewrites the WHOLE file from `_cache`.

**Auswirkung.** After one truncated/interrupted write to query_stats.json, the next `M.record` (prompt_input on_enter) rewrites the file with a single entry and the query-frequency history behind `:Reposcope queries` is gone. The user is warned (an ERROR-level notify fires on the corrupt load), but the original bytes are not preserved, so the loss is unrecoverable. Not "silent" as claimed — unrecoverable.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/reposcope/ui/prompt/prompt_config.lua:107` · `M.set_fields` · confidence **high**

**Befund.** An unrecognised prompt field is dropped with `notify(..., 2)` and no default substitution: if every configured field is invalid, `_fields` becomes `{}`.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default rather than break initialisation, and to be surfaced via `:checkhealth`. Neither happens. Level 2 is below the threshold in `utils/debug.lua:49` (`if M.is_dev_mode() or level >= 3`), so the "Ignored invalid field" message is invisible outside dev mode, and `health.lua` (read in full) never validates `prompt_fields`.

**Auswirkung.** `setup({ prompt_fields = { "keyword" } })` (missing 's') or `:Reposcope prompt keyword` leaves background, list and preview windows open with no prompt window and no way to type a query. The only feedback is "Layout empty or invalid" at ERROR level, which names neither the option nor the typo; the message that would ("Ignored invalid field: keyword") is suppressed at level 2 outside dev mode, and :checkhealth does not surface it either.

### `ERR-51` — Merges kopieren Defaults tief

`lua/reposcope/config/init.lua:25` · `M.options / module top level` · confidence **high**

**Befund.** `M.options = require("reposcope.config.DEFAULTS")` aliases the DEFAULTS module table instead of deep-copying it, and lines 32 and 38-40 then write env-resolved values (`clone.std_dir`, `github_token`, `gitlab_token`, `codeberg_token`) straight into it.

**Regelbezug.** ERR-51 requires merges to deep-copy the defaults (`vim.deepcopy` / `vim.tbl_deep_extend` into a fresh table) rather than mutate the shared defaults table. `require` caches DEFAULTS in `package.loaded`, so these four assignments permanently rewrite the canonical defaults for the whole Neovim session.

**Auswirkung.** `require("reposcope.config.DEFAULTS")` stops answering "what are the defaults" and answers "what did this machine's environment resolve to" for clone.std_dir and the three tokens. TESTS/config_spec.lua reads that table, which is why the generic scalar-DEFAULTS test had to hard-exclude the token fields. Before setup() runs, any write through `config.options.*` (ui/prompt/init.lua, state/session_state.lua, utils/metrics.lua) lands in the DEFAULTS module itself. No user-visible crash — this is a correctness/testability defect, not a runtime failure.

### `ERR-53` — In-place-Mutation statt Tabellen-Ersatz bei geteilten Referenzen

`lua/reposcope/ui/list/list_config.lua:38` · `M.highlight_color / M.normal_color` · confidence **high**

**Befund.** `M.highlight_color = ui_config.colortheme.accent_1` and `M.normal_color = ui_config.colortheme.text` are read once at module load. `ui/config.lua`'s `update_theme()` (lines 72-95) does not mutate `M.colortheme` in place — it assigns a brand-new table for "dark" and "light".

**Regelbezug.** ERR-53: when submodules hold values derived from a central table, the update must mutate in place, never replace the table, or those references silently decouple. The comment directly above line 38 claims the opposite — "sourced from the active colortheme (so a theme/colorscheme switch via `ui.config.update_theme()` is reflected here too, instead of these staying pinned to the original dark-theme hex values)" — which is exactly what does happen.

**Auswirkung.** After `require("reposcope.ui.config").update_theme("light")` the UI is half-converted: list_window and prompt_manager pick up the light palette at call time, while list_config.highlight_color/normal_color, background_config.color_bg and preview_config.layout.Normal.background/highlight_color/normal_color stay on the dark hex values. update_theme is public API with no internal caller, so it is latent until a user calls it. Fixing it by making update_theme mutate in place would NOT help.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/reposcope/utils/progress.lua:22` · `M.create` · confidence **high**

**Befund.** `lib.nvim` is loaded softly here — `local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")` with a nil-returning fallback at line 29 — and the module header states "`lib.nvim` is an optional dependency, matching the convention used elsewhere in the plugin".

**Regelbezug.** LUA-01 requires one consistent stance and forbids presenting a hard dependency as optional. The rest of the plugin is unambiguously hard: 50 bare, module-level `require("lib.nvim...")` calls with no fallback (`utils/protection.lua:24`, `bindings/usrcmds.lua:16`, `bindings/autocmds.lua:17`, `cache/readme_cache.lua:27-30`, `state/*.lua`, `network/request_tools/*.lua`, `config/init.lua:32`, ...). `docs/requirements.md` lists lib.nvim under **Required**, naming "the progress indicator" as one of the things it provides, and `.github/workflows/ci.yml` checks it out because "several modules require it at module load — so the suite cannot run without it".

**Auswirkung.** Nothing breaks at runtime: the soft path is unreachable, because a missing lib.nvim kills the plugin at the first bare require long before progress.create is called. The concrete cost is a header comment that asserts a project-wide convention that does not exist, so a maintainer copying it into a new module inherits a fallback that can never run and a false impression that lib.nvim is optional. This is a documentation/consistency defect, not a functional one — lower severity than the finding's framing.

### `LUA-13` — Deferred Calls absichern

`lua/reposcope/ui/list/list_manager.lua:79` · `M.update_list` · confidence **high**

**Befund.** `buf` is captured at line 72 with only a nil check, then used inside `vim.schedule(function() ... end)` at lines 80-82 (`vim.bo[buf].modifiable`, `nvim_buf_set_lines(buf, ...)`) with no `nvim_buf_is_valid` re-check at execution time.

**Regelbezug.** LUA-13/ERR-33 require handles to be re-validated inside deferred and async callbacks, because they can go invalid in between. Every other buffer writer in the plugin does this — `preview_manager.inject_content:67`, `status_view._set_buffer_lines:493`, `readme_viewer._prepare_readme_buffer:73` all guard.

**Auswirkung.** Close the Reposcope UI while a search is still in flight and the fetch's scheduled `update_list` callback runs against the deleted buffer id: `vim.bo[buf].modifiable = true` raises "Invalid buffer id: N" out of a scheduled callback after the UI is gone. Not a crash of Neovim — an unhandled error notification with no context, plus the list update is lost.

### `PERF-92` — Keine Layout-Geometrie auf Modulebene

`lua/reposcope/ui/list/list_manager.lua:28` · `preview_width / empty_tbl_msg` · confidence **high**

**Befund.** `local preview_width = require("reposcope.ui.preview.preview_config").width` is read at module load, and line 29 pre-renders the centred "No results..." message against it once, for the life of the session.

**Regelbezug.** PERF-92 says geometry is computed on every open, never once at `require`. The five `*_config` modules were given `recompute()` for exactly this reason (see the note in `ui/config.lua:14-21` and the calls in `init.open_ui`), but this consumer reads `preview_config.width` before any of those recomputes and never reads it again.

**Auswirkung.** Resize the terminal after plugin load, then run a search with no hits: the "No results..." line is padded for the preview width as of plugin-load time, so it sits off-centre (or wraps, if the terminal shrank) for the rest of the session. Cosmetic only — nothing errors, and it affects only the empty-result message.

### `PERF-93` — Heißes Event: billiger Guard **oder** Throttle, nie ungeschützt

`lua/reposcope/ui/prompt/prompt_autocmds.lua:65` · `M.setup_autocmds (cursor-lock autocmd)` · confidence **high**

**Befund.** `CursorMoved`, `CursorMovedI`, `InsertEnter` and `InsertLeave` are registered with `pattern = "*"` (verified global: `lib.nvim.bindings.autocmd.create` only sets `buffer` when `opts.buffer` is passed, otherwise it forwards `pattern`), and the handler has no buffer-scope guard at all. It runs `nvim_get_current_win`, `nvim_win_get_buf`, two validity checks, `nvim_buf_line_count` and `nvim_win_get_cursor` on every cursor move in every buffer, then forces the cursor to line 2.

**Regelbezug.** PERF-93 requires a hot event to leave the common case cheaply — the model being a first-line filetype/scope check. The sibling `TextChangedI` handler ten lines above does exactly that (`get_active_prompt_field()` -> `if not field then return end`); this one omits it, so it treats every buffer in the editor as a prompt buffer.

**Auswirkung.** While the Reposcope UI is open the cursor lock is editor-wide, not prompt-scoped. Any window with >= 2 lines that gets focus while the augroup lives has its cursor snapped back to line 2 on every CursorMoved/CursorMovedI/InsertEnter/InsertLeave — including help_view (`?`), which opens a kit.viewer and does not call cleanup_autocmds, so the cheatsheet cannot be scrolled. I verified the global registration, the missing guard and the readme_viewer workaround directly; the per-viewer breakage follows from those but I did not drive the UI to observe it.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/reposcope/utils/metrics.lua:309` · `M.check_rate_limit` · confidence **medium**

**Befund.** `local data = decode(response)` calls `vim.json.decode` directly on a network response body with no `pcall`, and line 311 then indexes `data.resources.core.limit` after checking only `data and data.resources`.

**Regelbezug.** ERR-01 makes `pcall` mandatory at system boundaries, and this is one — a process's stdout arriving through an async callback. Every other decode site in the plugin honours it: `github/.../readme_fetcher.lua:60`, `github/.../repository_fetcher.lua:54`, and the gitlab/codeberg equivalents all use `pcall(vim.json.decode, response)`. This one call was missed. The `data.resources.core` chain is also an unguarded nested index (ERR-02).

**Auswirkung.** Latent, not currently reachable from the UI. If any caller is added — or a test/API consumer invokes it — a non-JSON body (proxy error page, 502, truncated capture) makes vim.json.decode raise inside the spawn_capture completion callback instead of failing through the error path. A response where `resources` exists but `core` does not throws on the nested index at line 311 for the same reason. Today the practical impact is confined to TESTS/metrics_spec.lua and the public API surface.

### `ERR-02` — Type Guards & Literal Checks

`lua/reposcope/ui/prompt/prompt_manager.lua:53` · `_add_title_to_prompt_buffer` · confidence **medium**

**Befund.** `fg = require("reposcope.ui.config").colortheme.backg` — `colortheme` has no `backg` key. The table is defined at `ui/config.lua:45-51` (and rebuilt identically in `update_theme`) with `background`, `prompt`, `text`, `accent_1`, `accent_2`.

**Regelbezug.** ERR-02 requires nil checks before API access. The misspelled key evaluates to `nil` and is handed straight to `nvim_set_hl`, which accepts a table with `fg = nil` and simply defines the group without a foreground — no error, no warning, nothing that makes the typo visible.

**Auswirkung.** ReposcopePromptTitle is defined with only bg and bold, so each prompt field's centred title ("KEYWORDS", "OWNER", ...) renders with the inherited foreground over the accent_1 background instead of the intended one. Purely visual — nothing errors and nothing is unusable; on the default dark theme it happens to stay legible. The two halves of a single nvim_set_hl call disagreeing is the real signal, and it would get worse on a light palette.

### `ERR-03` — Explizite Rückgaben

`lua/reposcope/utils/checks.lua:37` · `M.resolve_request_tool` · confidence **medium**

**Befund.** After `local new_req_tool = M.first_available(requesters)`, the failure branch is `if not req_tool then notify("no request tool available") elseif new_req_tool then config.options.request_tool = new_req_tool end`. When nothing resolves, `new_req_tool` is nil and `req_tool` is non-nil, so neither branch runs; the function returns nil regardless.

**Regelbezug.** ERR-03/PRIN-20: a relevant function reports success/failure instead of failing silently. Here the only error path is gated on `not req_tool`, which cannot be true in practice — `DEFAULTS.lua:9` always supplies `request_tool = "gh"` and `setup()` only ever merges on top of it, so `config.options.request_tool` is never nil. The notification is unreachable and the caller gets no return value to check.

**Auswirkung.** On a machine with none of gh/curl/wget on PATH, setup() leaves request_tool = "gh" and says nothing. The first search then fails with "gh request failed (code ...)" from the gh.lua error path (around line 104, not 188), which names the wrong problem; the correct diagnosis exists only in :checkhealth. Secondary and confirmed: the notify branch cannot be entered in normal configurations, so the failure path is untestable, and the caller gets no return value to check.

### `LUA-16` — `vim.NIL` sanitizen

`lua/reposcope/providers/gitlab/repositories/repository_fetcher.lua:50` · `_normalize` · confidence **medium**

**Befund.** `default_branch = project.default_branch` (and `html_url` at 48, `stargazers_count` at 51) copy raw `vim.json.decode` output straight into the shared `Repository` shape with no `vim.NIL` check. `cache/repository_cache.lua`'s `_sanitize_repo` only runs `ensure_string` over `name`, `owner.login` and `description` — these three fields pass through untouched.

**Regelbezug.** LUA-16: JSON `null` decodes to `vim.NIL`, which is userdata and therefore **truthy**, so the usual `x or fallback` idiom does not catch it. `readme_manager.fetch_for_selected:187` does `local branch = repo.default_branch or "main"` and hands the result to `gitlab/readme/readme_urls.lua:24`, which concatenates it into a URL and passes it to `urlencode` at line 28.

**Auswirkung.** A GitLab project with null default_branch (GitLab returns null for a project with no commits, and such projects appear in /projects?search=) makes `branch` vim.NIL, and readme_urls.lua:24's concatenation raises "attempt to concatenate a userdata value" inside the README-fetch path — so arrow-key navigation over the result list throws. A null star_count breaks sort_prompt.lua:31 with "attempt to compare userdata with number"; a null http_url_to_repo/web_url breaks clone_command.lua:25 with "attempt to index a userdata value". Codeberg has the same three holes. I could not verify the GitLab API's null behaviour from this repo, so the trigger condition rests on the external API contract; the Lua-side breakage is certain once a null arrives.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/reposcope/config/init.lua:64` · `M.setup` · confidence **medium**

**Befund.** `M.options = vim.tbl_deep_extend("force", M.options, opts)` merges the user options into the *current* options table rather than into a fresh copy of DEFAULTS.

**Regelbezug.** LUA-87's merge contract is defaults (or file) as the base, `setup()` arguments layered on top — `vim.tbl_deep_extend("force", {}, defaults, user or {})`. Merging into the live table makes the operation accumulative instead of idempotent.

**Auswirkung.** setup() is accumulative rather than idempotent. A second setup() cannot clear anything the first set, and `setup({})` — the documented way to take the defaults — resets nothing. Two lazy.nvim specs for the same plugin, or re-sourcing the config in a session, keep the union of everything ever passed. No crash; the failure is a config that silently does not match what the user wrote.

### `SEC-10` — Nie als Prozessargument

`lua/reposcope/network/request_tools/gh.lua:137` · `M.request` · confidence **medium**

**Befund.** Caller-supplied headers are appended to argv verbatim: `args[#args + 1] = "--header"; args[#args + 1] = k .. ": " .. v`. A credential-bearing header therefore becomes a command-line argument of the spawned `gh` process. The neighbouring `redacted` table masks it for the log and the notify, but not for argv.

**Regelbezug.** SEC-10 forbids passing tokens as argv elements — a process command line is world-readable via `ps`/`Win32_Process` for the lifetime of the request. `curl.lua:43-51,65-69,78` implements precisely the opposite and says why: secret headers go into a curl config fed on stdin (`-K -`), never into argv. `gh.lua` itself already has the safe channel for this — lines 159-161 layer `GITHUB_TOKEN` into the child's environment — so the header is redundant as well as exposed.

**Auswirkung.** `utils/metrics.lua:301` builds `headers["Authorization"] = "Bearer " .. token` and passes it through `api_client.request` -> `http_client.request`; `_build_auth_header` returns `{}` for the gh tool but `tbl_extend("force", headers or {}, auth_headers)` at http_client.lua:98 preserves the caller's header, so the token reaches gh's argv. Any unprivileged local process enumerating the process list during that request reads the GitHub token in clear. Reachability is limited today — `check_rate_limit` has no production caller — but the argv path is live for any caller that passes an auth header, which is the documented shape of `api_client.request`'s `headers` parameter.

### `SEC-21` — Timeout **und** Byte-Limit

`lua/reposcope/network/request_tools/curl.lua:80` · `M.request` · confidence **medium**

**Befund.** `spawn_capture(argv, { env = env, stdin = stdin, timeout_ms = DEFAULT_TIMEOUT_MS }, ...)` sets a 20s timeout but no byte limit; the argv built at line 47 carries no `--max-filesize`. `wget.lua:45,62` is the same shape with no `--quota`/size cap.

**Regelbezug.** SEC-21 requires both, explicitly: "Downloads brauchen beides, nicht nur eines". The module comment at curl.lua:12-17 argues the timeout is enough because "this module isn't used for" a large download — but `readme_fetcher.fetch_raw` pulls `https://raw.githubusercontent.com/<owner>/<repo>/<branch>/README.md`, whose size is set entirely by a third party.

**Auswirkung.** A repository whose README.md is very large is buffered whole in spawn_capture's stdout accumulator, then cached to disk and split into the preview buffer — the 20s timeout bounds time, not memory. Real but bounded in practice: 20s caps how much a link can actually pull, and an oversized README is an unusual repo rather than an attacker-chosen payload. The sharper point is that curl.lua:12-17 documents a premise ("not used for a large download") that readme_fetcher.fetch_raw contradicts, so the reasoning that justified skipping the cap no longer holds.

> **Abdeckung dieses Laufs.** Scope actually read (not just grepped), roughly 7,100 of the 12,403 Lua lines: all of config/, state/, cache/, network/, utils/ (except stats.lua and repo_actions.lua), bindings/autocmds.lua and usrcmds.lua, ~200 lines of bindings/keymaps.lua, all controllers, all three providers' fetchers/normalizers/readme managers/clone builders, the whole prompt/ and preview/ subtrees, ui/config.lua plus the four derived *_config modules, list_manager/list_window, hover.lua, health.lua, preview_image.lua, help_view/readme_viewer/sort_prompt/filter_repos, and ~800 of status_view.lua's 1,387 lines. Ignored .claude/, .git/, .deps/, doc/tags as instructed.

Not covered, and why:
- status_view.lua lines 120-420 (M.render's column/width math and the highlight-group table) and 1100-1240 (`_attach_row_keymaps`, `_show_keymap_help`, WINBAR) were skimmed, not read line by line. Findings there are possible; I did not look hard enough to claim any.
- utils/stats.lua (157 lines), utils/repo_actions.lua, ui/actions/favorites_view.lua, ui/actions/readme_editor.lua, ui/actions/filter_prompt.lua, ui/background/background_window.lua and the @types/ tree were not read.
- TESTS/ was only surveyed structurally (run.lua, the spec list, grep for pcall/require shapes). I read no spec body end to end, so there are zero test-code findings here — that is a coverage gap, not a clean bill of health for TESTS/.
- CMT-16: docs/map/ and docs/BINDINGS.md are generated, but I did not run the generator or diff it against the tree, so I cannot say whether either has drifted or been hand-edited.
- UI-55: `init.close_ui` (init.lua:143-146) deletes every Reposcope buffer with `nvim_buf_delete(..., {force=true})` without first closing or redirecting the floats showing them; it never calls `list_window.close_window`/`preview_window.close_window`. Whether Neovim auto-closes a float whose buffer is wiped (rather than substituting a scratch buffer) is version-dependent and I could not verify it here, so I did not file it.
- SEC-33: `favorites_state.load` validates only `type(decoded) == \"table\"`; individual entries (owner/name/description/readme) are not re-validated on load, unlike `session_state.restore:77-99`, which type-checks every field. The file is user-local so I rated the risk too low to file.

Rules checked and found compliant (not merely inapplicable): SEC-03/SEC-01 (no shell-string construction anywhere — every external call is argv via `vim.system`, `spawn_capture` or `lib.nvim.cross.run_argv`; `protection.safe_execute_shell`'s string branch at protection.lua:213 is the only `vim.fn.system` call left and has no production caller), SEC-11 (the request log stores method/url/status/timestamp only, never headers or bodies), SEC-30 (`filter_repos.apply_filter:42` uses `find(query, 1, true)`), SEC-34 (`vim.fn.expand` survives only in `protection.is_valid_path:132`, which has no caller; everything else uses `lib.nvim.cross.fs.expand_path`), SEC-35 (no user text reaches a `vim.cmd` string), PERF-72 (scan roots default to `$REPOS_DIR`/`clone.std_dir`, never a drive or home), UI-01 (`_confirm_bulk` asks once per batch, not per item), ERR-62 (all seven `pcall(function() ... end)` sites wrap correctly), PERF-62 (debouncing is delegated to `lib.nvim.debounce`; no local timers).

Rules with no such surface in this plugin: ERR-30, ERR-31, LUA-02, LUA-48 (zero `__mode` occurrences), LUA-17 (only a read of `vim.g.statusline_winid`), LUA-90, LUA-91, LUA-92, LUA-93 (these govern nvim-config specs, not a plugin repo), PERF-07 (metrics.lua:139 is a single `next()`, not a delete loop), SEC-13, SEC-20, SEC-40, SEC-42, SEC-45, SEC-46, SEC-50, TS-04, XP-01 (zero `glob`/`globpath` calls), XP-02, XP-03, XP-06, XP-07.

One defect I could not map to any of the 76 rules, noted so it is not lost: `providers/github/repositories/repository_fetcher.lua:63` reads `notify(\"[reposcope] \" .. #parsed.items or 0 .. \" repositories received from GitHub.\", 2)`. `..` binds tighter than `or`, so this evaluates as `(\"[reposcope] \" .. #parsed.items) or (0 .. \" repositories...\")` — the left side is always a truthy string, so the message is permanently truncated to \"[reposcope] 25\". The gitlab and codeberg equivalents spell the same line correctly. Two more in the same category: `status_view.M.show:1364-1366` moves the *current* window's cursor to `_last_view.line` even for the `clipboard` and `path` output modes, where no Reposcope window was opened — `:Reposcope status --out=clipboard` yanks the cursor in whatever buffer the user was editing; and `github/clone/clone_manager.lua:70` calls `request_state.end_request(uuid)` synchronously right after `execute_clone`, which became asynchronous, so the UUID lifecycle no longer spans the clone and the duplicate-request guard the module header promises does not hold for its one real consumer.

---

## sandbox.nvim

**15 Befunde** (8 × high). Roh gemeldet: 18.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/sandbox/util/run_argv.lua:155` · `M.run_async_captured` · confidence **high**

**Befund.** The async spawn calls `vim.system(cmd, spawn_opts, cb)` bare, while its blocking twin twenty lines above (`run_blocking_captured`, line 27-29) wraps the identical call in `pcall`.

**Regelbezug.** ERR-01 makes `pcall` mandatory at system boundaries, and starting an external process is the system boundary of this whole plugin. `vim.system` does not return an error code when the binary cannot be spawned -- it `error()`s out of `uv.spawn` -- so the unguarded call throws instead of reporting.

**Auswirkung.** A throw out of `vim.system` (uv.spawn ENOENT when the engine binary is gone or a pinned `engine = "docker"` names one that is not installed) propagates raw to the user as an E5108 stack trace, skipping every friendly-error path this plugin has. The progress indicator started at line 148 is never finished and never cancelled, so it sits in the statusline for the rest of the session, and `on_done` never runs -- so callers that only report from the callback (image pull/push, all prunes, compose up/down/restart, devcontainer build) report nothing at all. Note the sibling failure mode is *silent*, not loud: the `vim.fn.jobstart` adapters return -1 without raising.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/sandbox/adapters/docker/containers/follow_logs.lua:41` · `M.follow_logs` · confidence **high**

**Befund.** `vim.system({"docker","logs","-f",container_id}, ...)` is called unguarded; identical code in nerdctl/containers/follow_logs.lua:41 and podman/containers/follow_logs.lua:41.

**Regelbezug.** ERR-01: an external-process start is a system boundary and must go through `pcall`. Neither this function nor its caller chain (`container_commands.logs_follow` -> `ui/log_follow_view`) has one.

**Auswirkung.** If the engine binary cannot be spawned, the throw lands between log_follow_view.lua:11 (scratch buffer already open, showing "-- following logs, press q to stop --") and line 38 (`bind_close`), so `q` is unbound and the BufWipeout kill-handler at line 43 is never registered. The user is left with a stuck, keyless buffer plus a raw Lua error, and must reach for `:bwipeout` by hand. Reopening the same container's log view hits the same unguarded call again.

### `ERR-02` — Type Guards & Literal Checks

`lua/sandbox/ui/list_view.lua:46` · `list_view` · confidence **high**

**Befund.** The container list view calls `vim.hl.range(...)` with no existence check, although `vim.hl` only exists from Neovim 0.11 (it is the 0.11 rename of `vim.highlight`), and README.md:18 plus docs/installation.md:5 both advertise Neovim 0.10+.

**Regelbezug.** ERR-02 requires a type/nil check before API access. The same file's sibling modules do guard version-dependent APIs -- `vim.fn.has("nvim-0.11") == 1` before `jobstart({term=true})` in five places -- and the fleet's own convention guards this exact call (`my.nvim/lua/my/hl_config/features/flash.lua:31`: `if vim.hl and type(vim.hl.range) == "function" ... elseif vim.highlight`).

**Auswirkung.** On the documented minimum (Neovim 0.10) `:Sandbox container list` indexes a nil `vim.hl` and throws inside the render loop at line 46 -- but only when the list is non-empty, since the loop body is what throws. The buffer is already open (line 36) and the throw aborts before `list_actions.set_keymaps` (line 55) and `setup_autorefresh` (line 251), so the user is left looking at a populated list buffer in which `q`, `?`, filter, engine-cycle and all sixteen row actions are unbound, plus a raw Lua error. Same for the filter re-render path (lines 195, 211).

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/sandbox/util/project_config.lua:18` · `M.read_engine_override` · confidence **high**

**Befund.** `read_engine_override` returns bare `nil` for three different situations: no `.sandboxrc` (line 13), a `.sandboxrc` with no `engine=` line, and a `.sandboxrc` whose `engine=` value is not one of the three known engines (the `and (value == ...)` filter on line 18 simply skips it).

**Regelbezug.** ERR-10/PRIN-26: "kein Argument" and "ungültiges Argument" must be distinguishable -- returning `nil, false` vs `nil, true`, or a structured error. Here a typo in a file the user wrote specifically to pin an engine is collapsed onto the same value as "the user never wrote one".

**Auswirkung.** `engine=dcoker` in a `.sandboxrc` is swallowed: init.lua:55-58 sees nil, falls through to the setup/detected engine, and the repo silently runs against an engine the file was written to override. The compounding claim checks out -- engine_commands.lua:70 asks the same nil-returning function (`elseif require("sandbox.util.project_config").read_engine_override() then source = ".sandboxrc"`), so `:Sandbox engine get` reports `(config)` and actively denies the file had anything to say. The same silence covers a valid `engine=` line typed as `engine = podman ` with a trailing token, since the pattern requires a single `%S+`.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/sandbox/ui/list_actions.lua:415` · `M.setup_autorefresh` · confidence **high**

**Befund.** `refresh_interval` is read straight from config and compared numerically (`if not interval or interval <= 0`) with no `type(...) == "number"` guard, unlike every sibling numeric option in this codebase (`status_cache_ttl_ms` statusline.lua:44, `completion_cache_ttl_ms` usrcmds/init.lua:50, `max_error_length` friendly_error.lua:22 all degrade to their default on a non-number).

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and be surfaced via `:checkhealth`. Here it degrades to nothing: the comparison throws, and health.lua validates only the engine name -- no config value is checked there at all.

**Auswirkung.** `setup({ refresh_interval = "2000" })` makes `setup_autorefresh` raise `attempt to compare string with number`. Because `setup_autorefresh` is the last statement of every list view (list_view.lua:251 and the image/volume/network equivalents), the buffer, highlights and keymaps are all already in place -- so the list looks and works fine, but every invocation of the command ends in a raw Lua error, with no hint that one config key is responsible and nothing in `:checkhealth` to point at it. Degrading to the DEFAULTS value (`refresh_interval = nil`) is what ERR-22 asks for.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/sandbox/config/init.lua:26` · `M.setup` · confidence **high**

**Befund.** `setup()` merges into the live `M.options` (line 25) rather than into a fresh DEFAULTS copy, then derives `M.engine_named = M.options.engine ~= nil` (line 26) -- but line 35 of the *previous* call already wrote the auto-detected engine into `M.options.engine`.

**Regelbezug.** LUA-87's counter-case (reposcope: "setup() merged in die aktuelle Optionstabelle statt in eine DEFAULTS-Kopie -- akkumuliert, ein zweites setup({}) setzt nichts zurück") is exactly this shape, and here the accumulation corrupts a flag whose whole purpose (documented at config/init.lua:12-18) is to tell a user *instruction* apart from a *guess*.

**Auswirkung.** A second `setup()` (lazy.nvim `opts` plus an explicit `require("sandbox").setup{}`, or `:Lazy reload`) turns a guess into an instruction: `engine_named` becomes true although the user never named an engine. `resolve_engine_name` then returns the first engine on PATH verbatim and skips the liveness probe -- the exact scenario engine_utils.lua:36-45 documents as the bug it was written to prevent (Podman on PATH with its VM stopped, Docker running and never asked; every command fails after ~370 ms). Nothing surfaces the flip: `:checkhealth sandbox` reports the resolved name, not how it was resolved.

### `PERF-46` — Cache-Key vollständig

`lua/sandbox/bindings/usrcmds/init.lua:63` · `cached_names` · confidence **high**

**Befund.** The completion cache is keyed by list kind alone (`list_cache["containers"]`, `"images"`, `"volumes"`, `"networks"`), while the values it stores come from `require("sandbox").get_engine()` -- which resolves through `vim.g.sandbox_engine`, the cwd's `.sandboxrc` and the config, none of which is part of the key.

**Regelbezug.** PERF-46: the key must contain every parameter that influences the result, otherwise the cache hands back the answer computed for a different configuration of the same input.

**Auswirkung.** After `:Sandbox engine set docker`, or a `:cd` into a repo whose `.sandboxrc` pins the other engine, `<Tab>` keeps offering the previous engine's object names until the entry ages out. With the shipped default that window is short -- `completion_cache_ttl_ms` falls back to 4000 ms (line 50) -- so the everyday impact is a few seconds of wrong candidates, not a lasting fault; a user who raises the TTL for a slow daemon extends it proportionally. Completing a name the active engine does not have produces a failed command, not silent damage. statusline.lua:47's single unkeyed `cache` slot has the same defect with a 3000 ms default (line 44).

### `PERF-82` — Idempotenter Timer-Start

`lua/sandbox/ui/list_actions.lua:434` · `M.setup_autorefresh` · confidence **high**

**Befund.** The idempotency guard `vim.b[bufnr].sandbox_autorefresh_active` is set at line 421 but never cleared when the timer stops itself: the scheduled callback closes the timer and returns (lines 434-440) as soon as the buffer has no window, and the BufWipeout handler (445) does not clear it either.

**Regelbezug.** PERF-82 demands an idempotent `start()` *with an explicit `stop()` counterpart*. The stop path here tears down the timer but leaves the flag that says "a timer is already running", so the start is no longer idempotent -- it is one-shot. The buffer survives the stop: lib.nvim's `open_named_scratch` sets `bufhidden = "hide"` and reuses the buffer by name, which this function's own docstring relies on.

**Auswirkung.** Closing the list *window* (`:q`, `<C-w>c`) rather than wiping the buffer stops the timer and leaves the "a timer is running" flag set on a buffer that survives. Every later `:Sandbox container list` (or image/volume/network list) reuses that bufnr, returns at line 418, and never arms a timer again -- auto-refresh is dead for that list kind for the rest of the session, silently. The flag is buffer-local, so the damage is per list kind, and only for users who set `refresh_interval`; BufWipeout is unaffected because the wipe destroys the flag with the buffer.

### `ERR-02` — Type Guards & Literal Checks

`lua/sandbox/bindings/usrcmds/container_commands.lua:96` · `M.exec / M.exec_once` · confidence **medium**

**Befund.** `local engine = require("sandbox").get_engine()` is followed by no `if not engine then return end`, unlike the other twelve functions in this file (list, logs, start, stop, kill, restart, pause, unpause, remove, prune, inspect, top). The identical omission is at line 118 in `M.exec_once`.

**Regelbezug.** ERR-02 requires a nil check before the value is used; `get_engine()` documents a `table|nil` return and returns nil after notifying "Invalid engine" (init.lua:70-73).

**Auswirkung.** With an unresolvable engine the usecase is invoked with `engine = nil` and dies at core/usecases/containers/exec_in_container.lua:8 (`engine.exec_in_container(...)`). The pcall at line 106 catches it, so the user gets two notifications for one cause -- "Invalid engine: nil" from init.lua:71, then "Failed to exec in container <id>: ...attempt to index a nil value" -- where every guarded neighbour stops after the first. Nothing is corrupted; the cost is a confusing second, internal-looking error. `M.inspect` at line 501 has the same exposure.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/sandbox/health.lua:101` · `M.check` · confidence **medium**

**Befund.** `:checkhealth sandbox` ends with a bare `require("lib.nvim.bindings.usercmd.composer").checkhealth("Sandbox")`, and no section of the healthcheck ever asks whether lib.nvim is installed -- while `notify.lua`, `logger.lua`, `run_argv.lua` and `friendly_error.lua` all carry `pcall(require, "lib.nvim...")` fallbacks whose own doc comments call lib.nvim "an optional dependency", contradicting docs/installation.md:4 ("**required**").

**Regelbezug.** LUA-01: a plugin picks hard or soft and holds it. The documented position is hard, so the healthcheck is the place that must *report* the missing dependency -- the same counter-case already fixed in fileops.nvim (`health.lua:71-75`), where a missing lib.nvim had to become an `error` line.

**Auswirkung.** Correcting the auditor: without lib.nvim, `:checkhealth sandbox` does not reach line 101. It throws at line 17, where `require("sandbox")` pulls in the three engine aggregators and thence `adapters/*/containers/follow_logs.lua:4`'s bare `require("lib.nvim.system.lines")` -- so the user sees the section header from line 12 and then `module 'lib.nvim.system.lines' not found`, with lib.nvim never named as the thing to install. (With `engine_named` set it instead survives to line 38 and dies in `engine_utils.is_executable` -> `require("lib.nvim.core")`, after one reassuring green line.) The auditor's secondary point stands: the pcall fallbacks in notify/logger/run_argv/friendly_error are unreachable in any install where the rest of the plugin loads at all.

### `LUA-16` — `vim.NIL` sanitizen

`lua/sandbox/ui/image_list_view_podman.lua:18` · `repo_tag` · confidence **medium**

**Befund.** `(img.Names or {})[1]` indexes a field taken straight from `podman images --format json`; the podman adapter returns the raw decoded table (adapters/podman/images/list_images.lua:22) with no sanitation, and `vim.fn.json_decode` turns JSON `null` into `vim.NIL` (userdata, truthy), so `or {}` does not catch it. Same expression in lua/sandbox/telescope/images.lua:31, same exposure for `img.Id` at line 25 (`(img.Id or ""):sub(1, 12)`).

**Regelbezug.** LUA-16 requires every field coming from external JSON to be checked for `vim.NIL` before use, precisely because `or`-defaulting does not see it and indexing/concatenating it throws.

**Auswirkung.** Any image entry whose `Names` or `Id` decodes to JSON `null` makes the render loop throw `attempt to index a userdata value`, taking down the entire `:Sandbox image list` view (and the Telescope picker) rather than degrading that one row to `<none>:<none>`. The concrete trigger the finding names -- podman marshalling a dangling image's empty `Names` slice as `null` -- is plausible (Go's encoding/json emits `null` for a nil slice) but I could not verify podman's field tags from this repo, so treat the crash as conditional on the engine's JSON rather than guaranteed. What is unconditional from the code: two external fields are consumed with a defence that cannot work, and the adapter offers none upstream. `img.Size` is safe by luck (`tonumber(vim.NIL) or 0`).

### `LUA-92` — Ein Adapter lädt sein Plugin während `setup()` nicht

`lua/sandbox/hover.lua:209` · `M.setup` · confidence **medium**

**Befund.** `sandbox.setup()` calls `hover.setup()` unconditionally (init.lua:29-31), which does `pcall(require, "hover.registry")` and then a behavioural probe that calls `registry.register` and `registry.position_at` (lines 263-282).

**Regelbezug.** LUA-92: an adapter must not load the foreign plugin during `setup()` -- under a lazy manager the `require` *is* the load trigger. The rule allows `require` only where it is read by `:checkhealth` alone, which health.lua:88 does correctly; this site does not.

**Auswirkung.** Under a lazy manager the `require` is the load trigger, so `sandbox.setup()` loads hover.nvim -- and runs a position probe through it -- for every user with the integration left on, defeating whatever `keys`/`cmd` trigger hover.nvim's own spec carries. With docs/installation.md:48 recommending `event = "VimEnter"` for sandbox itself, that lands in startup. Reading `package.loaded["hover.registry"]` and deferring registration to hover.nvim's own load keeps both the feature and the laziness; the behavioural probe would move with it.

### `PRIN-20` — Keine stillen Fehler

`lua/sandbox/adapters/docker/containers/run_container.lua:31` · `M.run_container` · confidence **medium**

**Befund.** `vim.fn.jobstart(cmd, {...})` is called for its side effects only -- the return value is discarded -- and the only path that ever calls `on_done` is the `on_exit` handler. Same in the nerdctl and podman copies of run_container.lua.

**Regelbezug.** PRIN-20/ERR-03: a relevant function must report success or failure and must not fail silently. When `jobstart` cannot start the process it returns `-1` (or raises from `vim.fn`), `on_exit` never fires, and this function returns as if work were under way.

**Auswirkung.** The reachable case is `:Sandbox container run`: container_commands.lua:436-443 passes a callback that prints either "Container started: ..." or "Failed to run container: ...", and a failed spawn prints neither -- the command returns having done and said nothing, which is indistinguishable from a slow start. The finding's devcontainer framing is weaker than claimed: build.lua only reaches `run()` after a successful `run_async_captured` build (line 57) or `pull_image` (line 68), so the engine binary has already proven spawnable by then. Returning jobstart's id and reporting `<= 0` through `on_done` would close it.

### `PRIN-25` — Eingaben validieren

`lua/sandbox/core/usecases/devcontainer/build.lua:31` · `devcontainer build use case` · confidence **medium**

**Befund.** Fields parsed out of the project's devcontainer.json are used without any type check: `config.workspaceFolder` goes straight into a concatenation (line 31, then line 48), `config.dockerComposeFile` likewise (line 27), and `config.build.dockerfile`/`config.build.context` are concatenated into a path (lines 55-56). `devcontainer_file.parse` validates only that the top-level decode produced a table (util/devcontainer_file.lua:94).

**Regelbezug.** PRIN-25/ERR-02: arguments must be validated before they are worked with, especially before a foreign API call -- and a JSONC file from a checked-out repository is external input, with `vim.NIL` in play for any `null` field (LUA-16).

**Auswirkung.** A malformed or null-bearing devcontainer.json in a checked-out repo makes `:Sandbox devcontainer build` die with `attempt to concatenate a table/userdata value` inside the use case. devcontainer_commands.lua:61-63 calls it with no pcall, so the trace reaches the user raw, immediately after the `notify.info("Building devcontainer...")` at line 60 -- with nothing naming the offending key. The file is repo-controlled input, so this is reachable by checking out someone else's project, not only by the user's own typo.

### `UI-55` — Buffer löschen, dessen Fenster sichtbar sind

`lua/sandbox/ui/list_actions.lua:187` · `M.set_keymaps (shared.close)` · confidence **medium**

**Befund.** The `q` action calls `vim.api.nvim_buf_delete(bufnr, { force = true })` -- which is `:bwipeout`, not `:bdelete` -- without first redirecting the windows that show this buffer.

**Regelbezug.** UI-55 requires visible windows to be pointed at an alternative buffer before the delete, because Neovim otherwise repoints them itself (to the alternate buffer, or to a fresh empty scratch when there is none). `M.bind_close` (line 312) has the same shape.

**Auswirkung.** Pressing `q` deletes the buffer but leaves the split standing, repointed by Neovim to the alternate buffer -- normally a second view of the file the user was in, or an empty [No Name] when there is no alternate. Because the list buffer is gone, the next `:Sandbox container list` finds no window showing it and opens another split, so one extra window is left behind per open/close cycle. Applies to every surface using this helper: the four list views, inspect_view and log_follow_view (via `bind_close`).

> **Abdeckung dieses Laufs.** Coverage: I read all of lua/sandbox's non-adapter code (init, config/*, util/*, ui/*, bindings/usrcmds/* except ~350 repetitive route-table lines in init.lua, statusline, hover, health, logger, notify, engine_utils, integrations/menu, telescope/*), plus the port contracts, a representative slice of the use cases, and the docker adapter family end to end. The 160 adapter files are near-verbatim triplicates (docker/nerdctl/podman), so I read the docker copy of each operation and spot-checked the podman/nerdctl divergences (podman's JSON shape, inspect_containers naming, list_containers parse); a defect unique to one nerdctl or podman file outside those spots could have escaped me. I did not audit TESTS/ (10k lines) or scripts, so there are no is_test_code findings -- not because the specs are clean but because the plugin's own code was the budget. I also did not run the suite or Neovim; every finding is from reading.

Not covered for lack of surface rather than lack of looking: CMT-16 (docs/GENERATED_COMMANDS.md carries its "Do not edit by hand" header and its route set matches the live table as far as a textual comparison shows; proving a hand edit would need the git history of that file, which I did not walk).

Deliberately not reported, so you know they were checked: SEC-01/03/10 hold up -- there is no shell-string construction anywhere in the 270 files, every CLI call goes through argv, and `docker/podman login` still pipes the password via `--password-stdin` (adapters/*/registry/login.lua:17-22). SEC-30 is satisfied (the list filter uses `find(q, 1, true)`, plain). XP-06 is fixed: the specs require `TESTS.sandbox.helpers...`, matching the directory's actual case. PERF-80 is honoured at every `vim.system`/`jobstart` completion callback (all of them `vim.schedule` before touching the API). ERR-60 is explicitly reasoned about in the adapters (see the comment at adapters/*/images/prune_images.lua:17-19) and I found no falsy-middle `and/or` anywhere. ERR-62 has no instances -- both `pcall`s in the tree pass a closure. LUA-48, PERF-07, PERF-72, PERF-92, TS-04, SEC-13, SEC-20/21/23, SEC-34/35, SEC-40/46/50, XP-01/03/07 have no corresponding surface in this plugin at all (no weak tables, no delete loops, no module-level geometry, no treesitter, no telemetry, no downloads, no `vim.fn.expand`, no `vim.cmd` string built from input, no server, no preview execution, no glob, no PowerShell redirection, no clipboard).

Two findings share a root and could be fixed as one: PERF-46 (completion cache) and the unkeyed statusline cache at statusline.lua:47 -- I reported the completion one because its stale values become command arguments, and folded the statusline into its impact. The two ERR-01 findings are likewise one fix in two places (run_argv's async spawn, and the three follow_logs adapters that spawn directly instead of going through run_argv).

---

## cascade.nvim

**14 Befunde** (10 × high, 1 davon in Testcode). Roh gemeldet: 15.

### `ERR-02` — Type Guards & Literal Checks

`lua/cascade/cycle/date.lua:76` · `M.step` · confidence **high**

**Befund.** `local norm = os.date("*t", os.time(t))` passes `os.time`'s return value straight into `os.date` with no nil check. `os.time` returns nil for a date it cannot represent, and `os.date("*t", nil)` is defined as "now".

**Regelbezug.** ERR-02 requires an explicit nil/type check before an API call, especially on a value coming back from one. Here the missing check does not produce an error — it produces a plausible-looking wrong value, which is the worse failure mode.

**Auswirkung.** On Windows/BSD (where os.time cannot represent pre-epoch dates), one `<C-a>`/`<C-x>`/`+`/`-` on any ISO date before 1970 — or on 1970-01-01 with a year decrement — silently replaces the whole date with today's date. No error, no notification; the user only notices if they reread the line. CI runs on ubuntu-latest, where glibc accepts the pre-1970 range, so the suite can never catch it.

### `ERR-02` — Type Guards & Literal Checks

`lua/cascade/init.lua:60` · `feed` · confidence **high**

**Befund.** `vim.api.nvim_feedkeys(vim.keycode(lhs), "n", false)` calls `vim.keycode`, which Neovim's own news-0.10.txt:276 lists as new in 0.10, with no existence check — while README.md's badge, docs/installation.md:8 ("**Neovim 0.9+**") and health.lua:23 (`vim.fn.has("nvim-0.9")` → `ok(...)`) all declare 0.9 supported. Same unguarded call at dispatch/init.lua:25 and util/lib.lua:132.

**Regelbezug.** ERR-02 requires a type/nil check before an API access. On the lowest version the plugin advertises, `vim.keycode` is nil and the call throws; the plugin states the requirement three times and gets it wrong in all three.

**Auswirkung.** On Neovim 0.9 — the floor the plugin advertises in its badge, its docs and its health check — every native-fallback path throws "attempt to call field 'keycode' (a nil value)": `<CR>`/`o`/`O` off a list line, `+`/`-`/`<C-y>`/`<C-x>` off a cyclable token, and the visual reselect helpers. `:checkhealth cascade` reports "ok Neovim 0.9.x" while those paths are broken. The honest fix is either a `vim.keycode or vim.api.nvim_replace_termcodes` shim or raising the declared floor to 0.10 in all three places; the practical exposure is small since 0.9 is long superseded.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/cascade/init.lua:932` · `M.run_indent_command` · confidence **high**

**Befund.** `local count = tonumber(cmd.args) or 1` — but `cmd` is `ctx.raw`, the untouched nvim user-command args table, whose `.args` field is the whole tail after the verb (`"indent 3"`), not the composer-parsed `levels` value. `tonumber("indent 3")` is nil, so a supplied argument is indistinguishable from no argument.

**Regelbezug.** ERR-10: "no argument" and "invalid/unread argument" must not collapse onto the same nil. The composer already parsed and type-checked the value into `ctx.args.levels` (usrcmds.lua:254, `type = "INT"`), but the run handler reads the raw string instead and falls back to the no-argument default, so the argument is neither used nor rejected.

**Auswirkung.** `:Cascade indent N` and `:Cascade dedent N` silently ignore their documented argument for every N and always shift by one level. The argument is neither used nor rejected — a typo'd argument and no argument produce identical behaviour. No error, no traceback; the only symptom is that the documented feature does nothing.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/cascade/cycle/packs/init.lua:54` · `M.resolve` · confidence **high**

**Befund.** `local ok, groups = pcall(require, "cascade.cycle.packs." .. name)` is followed by `if ok and type(groups) == "table" then ... end` with no else branch. The warning at lines 60-65 fires only for names that are not in `M.KNOWN` — a *known* pack whose module fails to load is dropped in complete silence.

**Regelbezug.** ERR-11: a function whose result can legitimately be empty must let the caller tell "empty but fine" from "empty because something broke". Here "this pack contributed nothing because it failed to load" and "this pack is simply not requested" produce byte-identical output, and the module's own docstring claims a typo "degrades to 'that pack is missing'" — which only holds for the unknown-name branch.

**Auswirkung.** A known pack whose module fails to load (corrupt file, partial checkout, a syntax error introduced while editing a pack) contributes zero groups with no signal anywhere: `resolve` returns the same shape as "that pack was not requested", and `:checkhealth cascade` shows a smaller "+N from packs" number still marked ok. The user sees the pack's words simply not cycling. I did not reproduce the stubbed-load run the auditor reports, but the missing else branch is unambiguous in the source.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`TESTS/run.lua:40` · `run.lua main loop` · confidence **high** · _Testcode_

**Befund.** `local run = dofile(dir .. name)` sits outside the `pcall(run, H)` on line 41. A spec that fails to *load* (syntax error, renamed file, a top-level `require` of a moved module) throws out of the whole chunk, so the loop aborts, the failure counter is never incremented, and `os.exit(1)` on line 52 is never reached.

**Regelbezug.** ERR-11: the runner's exit code must distinguish "nothing to report — everything passed" from "could not determine — the runner itself broke". With the documented invocation those two are the same exit code.

**Auswirkung.** A spec that fails to load rather than to assert — syntax error, renamed or moved file, a top-level require of a relocated module — aborts the runner before any counting, and CI still goes green with zero specs having run, because nvim honours the trailing `-c qa!` and exits 0 and nothing greps for the `CASCADE_TESTS_OK` marker. Test-only code, so no user-facing breakage, but it is a blind spot in the gate that guards everything else.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/cascade/lists/marker.lua:71` · `parse_custom` · confidence **high**

**Befund.** `rest:match(extra[i])` feeds each `lists.per_filetype_patterns` entry straight into `string.match` with no validation of the value's type, of the pattern's syntax, or of the documented "exactly two captures" contract; `split_checkbox(after, opts)` on the next line then indexes the second capture unconditionally.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and be surfaced via `:checkhealth`. `config/init.lua`'s `normalize()` (lines 53-74) normalizes only `sequence` and `lists.renumber`; `per_filetype_patterns` is never validated, and health.lua never mentions it. Instead the bad value throws from the hot path.

**Auswirkung.** With a malformed or single-capture `lists.per_filetype_patterns` entry, every `<CR>`, `o`, `O` and indent keypress in a buffer of that filetype throws an unhandled traceback, and nothing in `:checkhealth cascade` names the option. One correction to the auditor: a non-string entry does NOT throw — `rest:match(42)` works because Lua coerces numbers in the string library — so only the pattern-syntax and capture-count halves of the claim are real; the "no type validation" half is inert.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/cascade/health.lua:64` · `M.check` · confidence **high**

**Befund.** `table.concat(lists.filetypes, ", ")` assumes `lists.filetypes` is a table. Nothing validates it: `config/init.lua`'s `normalize()` (lines 53-74) covers only `sequence` and `lists.renumber`, and `lib_config.deep_merge` replaces the default list wholesale with whatever the user passed.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and be made visible through `:checkhealth`. Here it does neither: the bad value is kept, the feature it gates silently dies, and the health check that should report it is the thing that crashes.

**Auswirkung.** A singular-string typo for `lists.filetypes` (or `cycle.filetypes`) is accepted verbatim instead of degrading to the default: the whole list domain goes silently dead — no continuation, no checkbox, no indent, no renumber, not one list keymap bound — and the one tool meant to explain it, `:checkhealth cascade`, aborts with a `table.concat` type error instead of naming the option.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/cascade/lists/format.lua:81` · `M.apply` · confidence **high**

**Befund.** `if opts.continue.hanging_indent == false then` indexes `lists.continue` without checking it is a table. The same unchecked indexing of a config sub-table appears at transform.lua:229 (`opts.checkbox.states`), marker.lua:267, continue.lua:60 and health.lua:65.

**Regelbezug.** ERR-22: an invalid config value must degrade to its default and surface in `:checkhealth`, not throw. `normalize()` validates neither `lists.continue` nor `lists.checkbox`, and `deep_merge` happily stores a non-table there.

**Auswirkung.** `setup({ lists = { continue = false } })` — an easy confusion with the documented `lists.features.continue = false` — makes every markdown/text/tex/gitcommit buffer fire an "Autocmd failed (FileType)" error notification for the whole session, and hanging indent never applies. The parallel `lists.checkbox = false` kills `:checkhealth cascade` at health.lua:65 and crashes transform.rotate at :229 once an actual rotatable block is reached (my empty-buffer probe exited early, so that one is code-read, not reproduced). In every case the invalid value is kept rather than degraded, and health cannot report it.

### `ERR-51` — Merges kopieren Defaults tief

`lua/cascade/init.lua:603` · `M.cycle_group_add` · confidence **high**

**Befund.** `opts.groups[#opts.groups + 1] = values` appends to the table returned by `config.get("cycle")`. Because `lib.lua.config.deep_merge` only shallow-copies the top level of `base`, any key the user did not override keeps the shipped table by reference: after `config.setup({})`, `config.options.cycle == DEFAULTS.cycle` and `config.options.cycle.groups == DEFAULTS.cycle.groups`. `M.cycle_group_remove` (init.lua:620) does the same with `table.remove`. `config/init.lua:21` (`M.options = DEFAULTS`) has the same aliasing before setup runs.

**Regelbezug.** ERR-51 requires a merge to deep-copy the defaults rather than mutate the shared defaults table; config/DEFAULTS.lua's own header says "Never mutate it at runtime". ERR-54 applies too: `config.get` hands out the live internal table and a consumer mutates it. The root fix belongs in lib.lua.config.deep_merge (LUA-02), but the consumer-side violation is here.

**Auswirkung.** `:Cascade cycle add`/`remove` permanently edit the shipped DEFAULTS table for the rest of the Neovim session: an added group survives every re-`setup()` despite the docstring promising it is "deliberately not persisted", and a removed default group cannot be restored by any `setup()` call. Session-scoped only (nothing is written to disk), but it also means specs mutate live DEFAULTS mid-suite. The root cause is lib.lua.config.deep_merge's shallow base copy, so a fix belongs there (LUA-02), not only at this call site.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/cascade/cycle/word_cycle.lua:163` · `M.pick` · confidence **high**

**Befund.** `M.pick` calls `require("ui.kit").select({...})` as a naked, unguarded require, while docs/installation.md:23 states "ui.nvim is optional too: it backs cycle.pick's themed chooser (ui.kit.select, falling back to any vim.ui.select override)" and health.lua never probes ui.nvim at all.

**Regelbezug.** LUA-01 requires a dependency to be either hard (naked require, no fallback) or soft (pcall + local fallback with an identical interface), held consistently — and forbids a hard dependency being presented as optional in the docs. `ui.kit` is hard here (no pcall, no vim.ui.select fallback of cascade's own; `respect_override = true` is a setting *inside* ui.kit, not a substitute for it) yet documented as optional. It also violates ERR-01: a plugin-API call at a system boundary with no pcall.

**Auswirkung.** A user who installs what installation.md calls required (Neovim + lib.nvim) and enables the shipped preset gets an unhandled Lua traceback on the default `<leader>cp` keymap, and `:checkhealth cascade` reports a clean bill of health because it never probes ui.nvim. Scope is limited to that one action — every other cascade surface works — but the failure is a raw traceback, not a notification, and the docs plus health actively point away from the cause.

### `ERR-33` — Fenster-/Buffer-Handles bei Ausführung erneut validieren

`lua/cascade/cycle/word_cycle.lua:172` · `M.pick` · confidence **medium**

**Befund.** The `on_select` callback writes `vim.api.nvim_buf_set_text(ctx.bufnr, ctx.row0, s, ctx.row0, e, { repl })` using the bufnr, row and byte columns captured before the picker opened, with no `nvim_buf_is_valid` re-check at execution time and no pcall. The function's own docstring acknowledges "the actual buffer edit happens in the picker's callback, which may be asynchronous depending on the UI backend".

**Regelbezug.** ERR-33/LUA-13 require a deferred callback to re-validate its buffer and window handles at execution time rather than at capture time. Every other cascade action gates on `Context.writable()` (which does check `nvim_buf_is_valid`) at the start of the action — this one skips that check on the only path where time actually passes.

**Auswirkung.** Under a third-party `vim.ui.select` (telescope-ui-select, dressing, snacks), where the user can switch or close the buffer or an LSP/formatter autocmd can rewrite the line between opening the picker and choosing, the callback raises an unhandled traceback from inside the picker — "Invalid buffer id" for a wiped buffer, "Invalid 'start_col': out of range" for a shortened line. Both reproduced. The third case the auditor names — a line that changed but stayed long enough, overwriting the wrong span with no error — follows from the same captured columns and is the reason ERR-30 wants a re-verify, not just a validity check. Every other cascade action gates on Context.writable() first; this is the one path where time actually passes and it does not.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/cascade/config/init.lua:85` · `M.setup` · confidence **medium**

**Befund.** `M.setup` deep-merges the user table and then calls `normalize(M.options)`, which only coerces `sequence` and `lists.renumber` into shape. There is no unknown-key validation anywhere — not before the merge, not after it, and not in health.lua, which checks values but never keys.

**Regelbezug.** ERR-50 requires config validation (unknown keys, "did you mean …") to run before the merge, precisely so a typo in a nested option cannot vanish into the defaults unnoticed. cascade has no such pass at any point, which is the exact outcome the rule exists to prevent. The fleet convention (a `KNOWN_OPTS` table checked at setup) is absent here.

**Auswirkung.** A typo in any nested option key is merged in and read by nobody: the real option keeps its default, and neither `setup()` nor `:checkhealth cascade` ever mentions it. The user sees a feature "not working" against a config file that looks correct, with no diagnostic path — `debug = true` only instruments dispatch.try and lists_active. This is a missing-safety-net finding rather than a crash: nothing breaks that was working, but a whole class of user error is made undiagnosable.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/cascade/util/lib.lua:99` · `M.map` · confidence **medium**

**Befund.** util/lib.lua maintains a full soft layer (`try_require` + native fallback) for `lib.nvim.notify`, `lib.nvim.bindings.keymap` and `lib.nvim.bindings.autocmd.augroup`, and health.lua:36/38 tells the user "lib.map/lib.notify remain soft (util/lib.lua falls back to native APIs)". But the plugin hard-requires lib.nvim in five places — config/init.lua:15, init.lua:11, bindings/keymaps.lua:20, bindings/autocmds.lua:42, bindings/usrcmds.lua:168, plus util/lib.lua:565/578 — so none of those fallback branches is reachable. `M.map` additionally has no production caller at all; the only call site in the repo is TESTS/lib_util_spec.lua:48.

**Regelbezug.** LUA-01 requires the hard/soft choice to be made once and held, and forbids a hard dependency being presented as optional in the documentation. cascade is hard-dependent on lib.nvim in fact, soft-dependent in code shape, and describes itself as half-and-half in both installation.md and its own health output.

**Auswirkung.** Real but narrower than claimed, and I have to correct the auditor on three points. (1) health.lua:36 is a *source comment*, not user output — the user-facing string at :38 says only "lib.map/lib.notify available", which is accurate. (2) installation.md does NOT present lib.nvim as optional; lines 8-10 call it "a *required* dependency, not a soft one", so LUA-01's documentation prong is not breached. What IS misleading is installation.md:16-18's promise that ":checkhealth cascade tells you which of the two situations you are in" — that second situation is unreachable, and health's own "lib.nvim not found" branch at line 40 can never fire either, because the `pcall(require, "cascade.config")` guard at lines 28-33 fails first and returns. (3) "~120 lines of unreachable fallback code" is wrong: the fallbacks guard against lib.nvim *submodule* drift (a renamed lib.lua.numeral, lib.nvim.dotrepeat), not lib.nvim absence, so they are reachable. What survives is the genuine LUA-01 breach — one dependency treated as hard in five modules and soft in a sixth — plus one concrete piece of dead code (M.map, tested only by a spec that tests itself) and one false promise in the docs.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/cascade/bindings/autocmds.lua:124` · `M.setup` · confidence **medium**

**Befund.** `setup_list_keymaps(cfg)` is called only when `cfg.keymaps.preset` is truthy, and `lib.augroup("cascade_list_keymaps")` — the clear-on-create call the module relies on for idempotency — lives *inside* that function. `setup_hanging_indent` has the same shape (its `lib.augroup` call is behind an early return on `lists.enable`). The module docstring claims "Three autocmds, all idempotent (their augroups are cleared on every setup)".

**Regelbezug.** LUA-87's merge contract is that `setup()` composes a fresh state from defaults plus user options — the counter-example cited in its Belege is exactly "a second `setup({})` resets nothing". Here the config side does reset correctly, but the binding side accumulates: turning a switch off in a re-run leaves the previous run's wiring in place, so the effective state depends on call history rather than on the final config.

**Auswirkung.** Turning the keymap preset (or `lists.enable`) off in a re-run leaves the previous run's wiring fully in place: 19 FileType autocmds survive, the global cycle keymaps stay bound, and the effective state depends on call history rather than the final config — contradicting the module's own idempotency docstring. Reachable via `:Lazy reload cascade.nvim`, re-sourcing the config, or any host calling setup() twice. Only a restart clears it, and nothing surfaces why.

> **Abdeckung dieses Laufs.** Coverage: I read every one of the 48 production Lua files under lua/ in full (6,968 LOC incl. plugin/ and scripts/), plus TESTS/run.lua and TESTS/harness.lua; the 17 spec files (5,986 LOC) I covered by targeted grep and by running the suite, not line by line. .claude/, .git/, .deps/ and doc/tags were skipped as instructed. I ran the real suite (green, "CASCADE_TESTS_OK") before auditing, so every finding is against working code, and I verified 8 of the 14 findings by executing them under headless nvim 0.12 rather than by reading alone (ui.kit, per_filetype_patterns, DEFAULTS mutation, os.time/pre-1970 dates, :Cascade indent N, lists.filetypes/checkbox/continue, failing pack, re-setup autocmds, nvim exit code).

What I could NOT cover:
- CMT-16 (never hand-edit a generated file): docs/map/ is DocMap-generated, but I cannot tell from a working-tree snapshot whether anything in it was hand-edited — that needs the generator re-run and a diff. docs/BINDINGS.md is explicitly hand-maintained here ("Kept in sync with lua/cascade/bindings/"), so it is not a CMT-16 surface; I did not audit it for drift against the actual keymap table.
- The whole SEC family is genuinely inert in this plugin: no shell-out, no process spawn, no download, no file I/O, no env/token handling, no vim.fn.expand, no vim.cmd string built from user text (the only vim.cmd calls interpolate computed integers). Nothing to report there.
- PERF is almost as inert: no timers, no vim.uv, no defer_fn/schedule anywhere (marker.lua:55 states this as an invariant and it holds), no floats or layout geometry, and the only autocmds are FileType and BufWritePre — neither is a hot event. PERF-42/46/47 apply only to cascade.cycle.packs' resolution cache, which has a complete key (the pack-name list) and an explicit invalidate() wired into config.setup(); core/patterns.lua's cache has no invalidation but is bounded by the number of distinct unordered_markers configs (in practice one), so I did not count it.
- LUA-02 (push fixes up to lib.nvim): the ERR-51 finding's root cause is lib.lua.config.deep_merge's shallow top-level copy, which lives in lib.nvim and is out of scope for this plugin's report. I report the consumer-side effect only.
- ERR-30 (re-verify a match before writing): every write path here is fully synchronous — read lines, build, nvim_buf_set_lines in the same tick — so there is no window for staleness. The one exception is the cycle_pick callback, reported as ERR-33.
- PRIN-01: lua/cascade/init.lua is 1,192 lines and carries the action surface of all four domains plus gating, count stashing and the :command runners. docs/architecture.md:39 declares this deliberately as "the action facade every keymap binds to", so I treated it as an architectural choice rather than an SRP violation and did not file it.
- The CI workflow always checks out ui.nvim as a sibling (ci.yml), so the "ui.nvim absent" path behind finding 1 can never be exercised by the existing suite; the gap is structural, not a missing assertion.

---

## casedesk.nvim

**14 Befunde** (10 × high). Roh gemeldet: 15.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/casedesk/ui/cases.lua:249` · `M.stale` · confidence **high**

**Befund.** `local days = tonumber(days_arg)` — nil is then used at `query.stale(days)` (`query.lua:189-193`) to mean "no flat cutoff, use each case's own priority threshold". The route declares the argument as `type = "STRING"` (`bindings/usrcmds.lua:537`), so nothing validates it upstream.

**Regelbezug.** ERR-10: "no argument" and "invalid argument" are collapsed onto the same `nil`. A typo'd number is indistinguishable from an omitted one — the rule's named real bug type.

**Auswirkung.** `:Cases stale 3O` (letter O) or `:Cases stale 7days` does not report the typo; it switches the command into per-priority threshold mode, which is a materially different query. The header confirms the wrong mode in a way that reads deliberate — `("Stale (%d, priority-based threshold)"):format(#rows)` at line 261 — and the empty-result notify says 'no open case is stale for its priority' rather than naming a bad argument. The user believes they filtered on a day count that was never applied. Low severity, trivially fixed by distinguishing `days_arg == nil` from `tonumber(days_arg) == nil` (or by declaring the arg as a numeric argtype).

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/casedesk/ui/cases.lua:218` · `M.recent` · confidence **high**

**Befund.** `local n = tonumber(n_arg) or 10`, with the route declaring `n` as `type = "STRING"` (`bindings/usrcmds.lua:511`).

**Regelbezug.** ERR-10: a mistyped count degrades to the default exactly as if no argument had been passed, with no way for the caller to tell the two apart.

**Auswirkung.** `:Cases recent 2O` silently lists 10 entries rather than rejecting the argument. Same class as the `stale` case and equally cheap to fix, but milder in consequence: the picker header reads `("Recent (%d)"):format(#rows)` with the true row count, so the number on screen is at least honest about how many were returned — the user just does not learn that their requested count was discarded.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/casedesk/sla/notify.lua:93` · `M.setup` · confidence **high**

**Befund.** `local interval_ms = config.sla_notify_interval_seconds * 1000`, reached unconditionally on every startup because `sla_notifications_enabled` defaults to `true` (`config/DEFAULTS.lua:419`). `bindings/usrcmds.lua:242` calls `require("casedesk.sla.notify").setup()` *before* it builds the route table, and neither that call nor `casedesk/init.lua:18-22` wraps it in `pcall`.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and be surfaced via `:checkhealth`, instead of aborting the whole plugin initialization. Here a non-numeric value raises out of `setup()` at the earliest point of `usrcmds.setup()`, and `health.lua` checks no option types at all.

**Auswirkung.** `opts = { sla_notify_interval_seconds = "15m" }` (or any non-numeric-coercible value) makes `casedesk.setup()` raise 'attempt to perform arithmetic on a string value' from sla/notify.lua:93. Because this runs before the route table is registered, and before `keymaps.setup()`/`autocmds.setup()` in init.lua, the entire plugin surface is gone: `:Case`, `:Cases` and `:Tricentis` do not exist, and the plugin's keymaps and autocmds are never installed. The traceback names sla/notify.lua, not the option the user mistyped, and `:checkhealth casedesk` — which validates no option types — offers no path to the answer. ERR-22 asks for exactly the opposite: degrade that one value to its default and surface it in checkhealth.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/casedesk/apply.lua:30` · `M.run (kind == "write")` · confidence **high**

**Befund.** `plan.build` decides "file exists -> skip" at scan time (`plan.lua:46`, `uv.fs_stat`), the resulting action list is rendered into a viewer and the user is then asked to confirm (`ui/sync.lua:44-49`, `ui/case_new.lua:145-155`); only after the answer does `apply.run` call `write_to_file(a.path, ...)` with no re-check.

**Regelbezug.** ERR-30 requires every edit computed during a scan to be re-verified against the current state immediately before writing. Here the only guard against clobbering is a stat taken before an unbounded human-time confirmation gap, and `lib.nvim.fs.write.to_file` opens with `io.open(path, "wb")`, which truncates unconditionally.

**Auswirkung.** Between the `uv.fs_stat` in `plan.build` and the truncating `io.open(path, "wb")` in `apply.run` there is an unbounded, event-loop-live confirmation window during which nothing re-checks the target. If a blueprint file materializes in that window, confirming `:Case sync` silently truncates it and writes the blank template (H1 + empty body) over it, with `apply.errors` reporting success. The practical exposure is narrower than the auditor implies: for `:Case new` the directory is brand new, so essentially only `:Case sync` on an existing case is at risk, and it needs the file to appear in the seconds the dialog is up. What is unambiguously broken regardless of timing is the written policy — plan.lua:3-5 and apply.lua:2-4 both claim 'never overwrite an existing file' / 'safe to run against a case that already has some of its blueprint in place', and that guarantee holds only at scan time, not at write time.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/casedesk/normalize.lua:98` · `M.run` · confidence **high**

**Befund.** Rename targets are validated inside `doctor.check()` (`doctor.lua:270`, `doctor.lua:479`: `to = exists(to) and nil or to`), the plan is shown in a viewer and confirmed (`ui/cases.lua:717-728`), and only then does `M.run` call `mutate.rename_file(s.from, s.to)` — without re-checking that `s.to` is still absent.

**Regelbezug.** ERR-30: the match computed during the scan is applied blind. `lib.nvim.cross.fs.mutate.rename_file` delegates to `uv().fs_rename(src, dst)` (`cross/fs/mutate/init.lua:129-131`), and libuv's rename replaces an existing destination silently on both POSIX and Windows (MOVEFILE_REPLACE_EXISTING).

**Auswirkung.** The 'target already exists -> ambiguous, leave it to a human' policy that doctor.lua and normalize.lua are jointly built around never fires at all, at any time. Because `exists(to) and nil or to` always evaluates to `to`, every such finding reaches `normalize.plan` as a candidate with a non-nil `to`, is listed as a normal rename in the viewer, and `:Cases normalize` then renames over the existing file via `uv.fs_rename` — destroying it without a word. This does not require the confirmation-window race the finding describes; it happens on the very first run against any case where e.g. both `CaseNote.md` and `Summary.md` already exist. The ERR-30 defect (no re-verification before the write) is the second layer: even once the `and/or` bug is fixed, a target created during the confirmation pause is still clobbered.

### `ERR-33` — Fenster-/Buffer-Handles bei Ausführung erneut validieren

`lua/casedesk/ui/reply_check.lua:109` · `M.reply_check` · confidence **high**

**Befund.** `bufnr` is captured at line 22, then an async network link check runs (`replygate.check` -> `linkcheck.run`, HEAD requests with a 5 s timeout each). The report's buffer-local keymaps close over that `bufnr` and fire arbitrarily later: `c` calls `replygate.clear_emojis(bufnr)` (line 109), which goes straight into `vim.api.nvim_buf_get_lines(bufnr, ...)` (`replygate.lua:25`), and `s` calls `vim.api.nvim_set_current_buf(bufnr)` (line 124). Neither revalidates with `nvim_buf_is_valid`.

**Regelbezug.** ERR-33/LUA-13: a handle captured before a deferred/async hop must be revalidated at execution time, not only at capture time. Everything between capture and use is asynchronous — network round-trips, a `vim.schedule`, and then an open-ended wait for a keypress.

**Auswirkung.** Close or wipe the reply draft while the async link check is in flight (each HEAD request carries its own timeout, so this is a multi-second window), then press `c` or `s` on the report that appears afterwards: the keymap callback raises a raw 'Invalid buffer id: N' instead of doing the action or saying anything useful. One correction to the auditor: the report does NOT stay open indefinitely — `kit.viewer` wires `close_on_focus_lost` (ui.nvim `kit/viewer.lua:63-65`), so the float dismisses itself on WinLeave/BufLeave and the user cannot leave it, close the draft, and come back. The reachable window is the async link check itself, not 'any time afterwards'.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/casedesk/config/init.lua:142` · `M.setup` · confidence **high**

**Befund.** `setup(opts)` iterates `pairs(opts)` and merges every key straight into `M` with no key-set check, no type check and no "did you mean" — neither before nor after the merge. Grepping the whole plugin finds no `KNOWN_OPTS`, no `vim.validate`, and `health.lua` never reports unknown options either.

**Regelbezug.** ERR-50 requires config validation (unknown keys, "did you mean …") to run before the merge precisely so a typo cannot disappear silently into the default. Here nothing validates at all, so an unrecognized key is stored on the config table forever and read by nobody.

**Auswirkung.** Any misspelled option is accepted in total silence and stored on the config table where nothing reads it. Concretely, `opts = { case_root = "D:/work" }` (the real key is `cases_root`) leaves `cases_root` at the derived default `<$REPOS_DIR or C:/repos>/WKDBook-Tricentis/Cases/SAP_Support/Cases` (config/init.lua:127-130), so `:Cases list` scans the author's path and comes back empty. `:checkhealth casedesk` then reports on that default path — ok if it happens to exist, `error: repo_root does not exist` otherwise — and never mentions that an option was supplied and ignored, which is precisely the 'typo disappears into the default and is never noticed' failure ERR-50 names.

### `ERR-51` — Merges kopieren Defaults tief

`lua/casedesk/config/init.lua:13` · `M (= DEFAULTS)` · confidence **high**

**Befund.** `local M = DEFAULTS` — the config module IS the DEFAULTS table, and `M.setup` mutates it in place (`M[k] = v` / `M[k] = vim.tbl_deep_extend("force", M[k], v)` at lines 150-156, plus `rebuild_derived`/`reconcile_areas`). There is no `vim.deepcopy(DEFAULTS)` anywhere.

**Regelbezug.** ERR-51 requires merges to copy the defaults deeply rather than mutate the shared defaults table. The module's own rationale (lines 5-8) only justifies "a module table rather than a get() accessor" — a deep copy would give exactly the same ergonomics. This is also the reposcope counter-case cited under LUA-87: merging into the current options table instead of a DEFAULTS copy accumulates.

**Auswirkung.** Two real consequences, both as stated. (1) There is no pristine copy of the defaults anywhere after `setup()` — `require("casedesk.config.DEFAULTS")` hands back the mutated table, so any future consumer wanting a default value (doc generation, a health check that wants to say 'this differs from the default', a reset path) silently gets the user's value instead; the test suite already has to work around this by clearing two `package.loaded` entries. (2) `setup()` is not idempotent-with-respect-to-reset: a second `setup({})`, as a config reload or a `:Lazy reload` would issue, cannot restore any default, because `explicit` is empty and every derived path is recomputed from the already-overridden base. The module doc's stated rationale (lines 5-8) only argues for a module table over a `get()` accessor, which a `vim.deepcopy(DEFAULTS)` would satisfy equally well — the aliasing buys nothing.

### `PERF-46` — Cache-Key vollständig

`lua/casedesk/statusline.lua:146` · `M.status` · confidence **high**

**Befund.** The cache key is `bufname` (read from the caller's `buf` argument at line 144) plus a 60 s time bucket, but the value is computed from `resolve.sync(nil)` at line 159, which resolves `vim.api.nvim_buf_get_name(0)` — the *current* buffer (`resolve.lua:44`). The `buf` parameter is a documented public argument (`---@param buf integer|nil # defaults to the current buffer`) and influences nothing except the key.

**Regelbezug.** PERF-46: the key must contain every parameter that influences the result. Here it contains one that does not, while the input that actually determines the result (which buffer is current) is absent from it — the exact shape the rule warns about, a cache silently answering for a different input than the one it was keyed under.

**Auswirkung.** Correcting the auditor on reachability: no caller in this ecosystem currently passes an explicit buffer. ui.nvim's casedesk segment (`lua/ui/statusline/modules/casedesk/init.lua:30`) calls `statusline.status()` with no argument, and `M.lualine_component()` does the same, so on the nil path the key and the computed value agree and today's output is correct. The defect is latent, not live: `M.status(buf)` is documented public API, and the moment any consumer uses it as documented — a heirline/lualine component rendering an inactive window's statusline — it gets the ACTIVE buffer's case label back, and that wrong label is then cached under the inactive buffer's name for up to `SLA_REFRESH_SECONDS` (60s), so repeat redraws keep returning it. Fix is one line: pass `buf` through to the resolve call instead of `nil` (or drop the parameter from the signature).

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/casedesk/ui/copy.lua:27` · `M.copy / with_src` · confidence **high**

**Befund.** `source = vim.fn.expand(source)` is applied to a path that comes either from the `:Case copy <src>` argument or, on the interactive path, verbatim from `kit.input({ prompt = "Source file" })` at line 62.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on buffer/user text: a backtick span in the argument is a command substitution through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. The rule names `lib.nvim.cross.fs.expand_path` as the safe replacement — which the composer's PATH argtype (lib.nvim `composer/argtypes.lua:145`) already applied to `ctx.args.src`, so this second expansion is both redundant on that path and the dangerous one.

**Auswirkung.** A source path containing a backtick span — typed at the `Source file` prompt, or passed to `:Case copy` — is executed as a shell command by `vim.fn.expand` before `uv.fs_stat` is ever reached, and the command's stdout becomes the path that is then read and copied. `%` and `#` in a path are likewise silently replaced by the current/alternate filename. Reachability is limited (the string has to come from the user's own keystrokes or a pasted path), so this is a latent injection sink rather than a remote-triggered one, but it is the exact pattern SEC-34 exists to forbid, and the fix is a one-line swap to `lib.nvim.cross.fs.expand_path` — on the `:Case copy` path, simply deleting line 27 is already correct.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/casedesk/ui/similar.lua:31` · `M.similar` · confidence **medium**

**Befund.** `similar.rank(entry.short, tonumber(n_arg) or 5)`; the argument reaches this untyped from the route.

**Regelbezug.** ERR-10: same collapse of "no count given" and "count given but unparseable" onto the default.

**Auswirkung.** `:Case similar 049885 1O` ranks 5 hits instead of 10 without saying the argument was rejected. Milder than the auditor states: the picker title is `("Similar to %s (%d)"):format(entry.short, #hits)` and `#hits` is the real returned count, so the displayed number is accurate — what is lost is only the signal that the requested count was discarded. Lowest-severity of the three ERR-10 instances.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/casedesk/templates.lua:97` · `M.render` · confidence **medium**

**Befund.** `M.render(tag, tokens)` returns a bare `string[]`. An unknown tag returns `{}` (line 99), an unreadable/missing template file returns `{}` (line 101), and a genuinely empty template also returns `{}` — the three are indistinguishable to the caller, `plan.lua:56` (`vim.list_extend(lines, templates.render(node.template, tokens))`).

**Regelbezug.** ERR-11: a function whose result may legitimately be empty has to make "empty and fine" distinguishable from "empty because broken". There is no second return value and no error channel, so `plan.lua` cannot tell a broken install from an empty template and emits the same `write` action either way.

**Auswirkung.** Three causally distinct outcomes — unknown tag, unreadable/missing template file, legitimately empty template — are indistinguishable to the caller, so `:Case new` and `:Case sync` cannot tell a broken install from an empty template and report success either way. The realized consequence is a scaffolded case whose documents contain nothing but their H1, with no error and no health warning. The chosen mitigation is a spec assertion (`TESTS/templates_spec.lua` checks every registered tag resolves to a readable file), which catches a shipped-path regression in CI but covers nothing that happens at the user's install: a `M.register(tag, path)` typo, a case-sensitive filesystem, or a packaging change that drops `templates/` all reproduce the silent outcome the doc comment already describes. ERR-11's fix is a second return value (`{}, nil` vs `{}, err`) that plan.lua can surface.

### `LUA-11` — Gültigkeit prüfen

`lua/casedesk/ui/cases.lua:174` · `M.list_all` · confidence **medium**

**Befund.** `toggle_line(vim.api.nvim_win_get_cursor(surf.winid)[1])` inside the buffer-local `m` keymap. `surf.winid` is the window handle captured when `kit.viewer` created the surface at line 158; the mapping is scoped to `surf.bufnr`, not to that window, and no `nvim_win_is_valid` check guards the call.

**Regelbezug.** LUA-11 requires `nvim_win_is_valid` before every window API call, and the handle here is a stale capture used from a callback that runs arbitrarily later. Correctly this should read the *current* window (`0`), which is by definition the one showing the buffer the mapping fired in.

**Auswirkung.** Press `<C-w>s` in the `:Cases list` viewer: ui.nvim's `close_on_focus_lost` (kit/viewer.lua:63-65, lib.nvim `window/close_on_focus_lost.lua:39-45`) closes the float on WinLeave, but the scratch buffer survives in the new split because it is displayed there (`bufhidden=wipe` only wipes on hide), and its buffer-local `m`/`c` maps stay live. Pressing `m` there raises a raw 'Invalid window id: N' out of the keymap. Two corrections to the auditor: the user does not need to close the original window — the float closes itself — and the 'worse than an error, reads the other window's cursor' claim does not hold, because the two windows never coexist for longer than one scheduled tick. The fix is the one the auditor names: read window `0`, which is by definition the window the buffer-local mapping fired in.

### `PERF-82` — Idempotenter Timer-Start

`lua/casedesk/sla/notify.lua:86` · `M.setup` · confidence **medium**

**Befund.** `M.setup()` is correctly idempotent (`if timer then return end`, line 88) and stores the handle in the module-local `timer`, but the module exposes no `stop()`: grepping the plugin finds no `timer:stop`, no `timer:close` and no `M.stop` anywhere.

**Regelbezug.** PERF-82 asks for the idempotent `start()` to come with an explicit `stop()` counterpart. Without one the handle is unreachable from outside the module and the timer cannot be released for the life of the session.

**Auswirkung.** The concrete consequence is on reload, and it is a real handle leak rather than just a missing API. A `:Lazy reload casedesk.nvim` (or any `package.loaded` clear) discards the module-local `timer` reference, but the libuv timer itself is still armed and its `vim.schedule_wrap` closure still holds the old module table — so the old 15-minute wakeup keeps firing forever while the reloaded module's `M.setup()` happily creates a second one. N reloads leave N timers. Tempering the auditor's other claim: flipping `sla_notifications_enabled = false` at runtime does stop the user-visible notifications (`M.check` early-returns at line 60), so the residual cost there is only a cheap no-op wakeup every 15 minutes, not spurious alerts. There is also no way to change the interval without restarting Neovim. A three-line `M.stop()` doing `timer:stop()` + `pcall(timer.close, timer)` + `timer = nil` closes all of it.

> **Abdeckung dieses Laufs.** COVERAGE. I read the full rules file first, then ~5,200 of the plugin's 13,822 Lua lines end-to-end: init.lua, config/init.lua, meta.lua, apply.lua, plan.lua, registry.lua, usage.lua, query.lua, detect.lua, resolve.lua, statusline.lua, linkcheck.lua, replygate.lua, redaction.lua, templates.lua, normalize.lua, marks.lua, anonymize.lua, attachments.lua, health.lua, bindings/{autocmds,keymaps}.lua, sla/notify.lua, most of export.lua/ocr.lua/stream_format.lua/sla/clock.lua, and ui/{copy,common,add,activity,sync,case_new,reply_check,commands,similar}.lua plus the decisive halves of ui/cases.lua, ui/lifecycle.lua, ui/ki.lua and bindings/usrcmds.lua. Every finding above was confirmed by reading the code and, where the consequence depended on a lib.nvim primitive, by reading that primitive too (`fs/write/to_file` truncates via `io.open(...,"wb")`; `cross/fs/mutate.rename_file` delegates to `uv.fs_rename`; `composer/argtypes.lua`'s PATH type expands via the safe `expand_path`).

WHAT I COULD NOT COVER BY READING. Roughly 8,600 lines were reached only through targeted greps per rule family, not read whole: extract/{stream,supportinfo,facts,doclinks}.lua, solution.lua, similar.lua, sla/{init,stream}.lua, migrate.lua, doctor.lua (most of 556), blocks.lua, links.lua, terminology.lua, timeline.lua, blueprint.lua, render.lua, ki.lua, commands.lua, and about fifteen ui/* modules. For those I grepped and followed every hit for the pattern-detectable rules (all `vim.api.nvim_*` calls, `vim.fn.expand`, glob/globpath, io.popen/os.execute/vim.fn.system/vim.system, vim.cmd, `__mode`, `next(t)` delete loops, `vim.g`/`vim.b`/`vim.w`, treesitter, uv timers/spawn, os.getenv, json, every file write, every `table.sort`, every `tonumber`, every autocmd registration, module-level geometry) — so grep-visible violations there should be covered. The judgment-only rules (PRIN-01 SRP, CMT-16, SEC-11/13, SEC-45, XP-03/04/05/07, LLS-31's "returns the planned count instead of the done count") were NOT systematically checked in those files; I spot-checked LLS-31 at the three success-message sites I did read (`ui/cases.lua:732`, `ui/lifecycle.lua:527/540`, `replygate.clear_emojis`) and all report actual work, not planned work.

NOT CHECKED AT ALL. TESTS/ (44 spec files) and scripts/ were only spot-read — no test-code findings are reported, so `is_test_code: true` does not appear above; that is an absence of coverage, not a clean bill. CMT-16 (hand-edits in generated files) would need a `scripts/gen_docs.sh` run against `docs/commands.md`/`docs/BINDINGS.md` to verify, which is a write and out of scope for a report-only pass. XP-06 (module-path casing on a case-sensitive CI filesystem) I checked only for `require` paths inside lua/, not for doc links.

DELIBERATELY NOT REPORTED. Three things look like hits but are not. (1) `usage.lua:77` collapses "journal missing" and "journal corrupt" onto `{}` and then rewrites the whole file — textbook ERR-11 load-modify-save, but the module doc (lines 20-22) declares the journal explicitly loss-tolerant and reconstructible, which is the documented exemption the ERR-11 Belege grants github_stats' telemetry store. (2) `attachments.lua:18` doubles `'` for a PowerShell single-quoted literal — that is complete and correct for that context (backslash is literal there), so SEC-46 is satisfied, not violated. (3) `registry.list()` hands out the live cache table by reference and `ui/insert.lua:305` passes it straight into `kit.select` — the ERR-54 shape, but I read ui.nvim's `kit/select.lua`, `chooser.lua` and `picker.lua` and none of them mutates the caller's `selection`, so there is no current defect; it stays a latent one if that picker ever starts sorting in place. I also left out the check-then-create in `ui/add.lua:76` (ERR-31): it is the named anti-pattern, but the "exists" branch opens the file rather than claiming exclusivity, and a TOCTOU race needs two concurrent `:Case add` calls in one single-user editor.

PRIORITISATION. If only three are fixed: the two ERR-30 write-after-confirm gaps (they destroy user data silently) and SEC-34 in ui/copy.lua (it executes a shell).

---

## cmdlog.nvim

**14 Befunde** (7 × high). Roh gemeldet: 14.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/cmdlog/core/store.lua:29` · `M.load_json` · confidence **high**

**Befund.** `load_json` returns the caller's `default` for three different situations — file missing, file empty, and `json_decode` failing on a corrupt file — with no second return value distinguishing them.

**Regelbezug.** ERR-11 requires "empty but ok" to be distinguishable from "empty because broken". Every consumer here is a load-modify-save cycle (`errors.record`, `stats.record`, `project_history.record`, `tags.save`) that calls `load()`, mutates the result, and then hands the WHOLE table to `save_json`, which rewrites the entire file. This is verbatim the bug class the ERR-11 Belege calls the most common real finding of the 32-repo sweep; cmdlog is not among the four repos named there as fixed, and there is no `.corrupt` backup path anywhere in this module.

**Auswirkung.** A `project_history.json` that is present and non-empty but not valid JSON makes load() return the caller's `{}`. The very next `:` command reaches tracker.lua's scheduled callback (l.58-65), project_history.record inserts one entry into that `{}` and save_json rewrites the whole file — the recorded history for every Git root is lost with no notification and no backup. Identical for stats.json, errors.json and favorite_tags.json. Note the distinction only matters for a corrupt-but-present file; a missing file legitimately yields `{}`, which is exactly why the two cases need to be distinguishable.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/cmdlog/core/favorites.lua:81` · `M.load` · confidence **high**

**Befund.** `M.load` collapses "file not readable" (line 70), "file empty" (line 76) and "JSON decode failed / decoded to a non-table" (line 81) onto the same `favorites_cache[target] = {}` and returns it, caching the empty list for the rest of the session.

**Regelbezug.** Same ERR-11 collapse as `core/store.lua`, but on the one file in this plugin that holds hand-curated, non-reconstructible user data. `M.save` (line 94) unconditionally writes the full list, so the corrupt-file case is indistinguishable from the first-run case at the only place where the difference matters.

**Auswirkung.** A corrupt-but-present favorites.json is indistinguishable from first run. `:Cmdlog favorites` reports "No favorites found", and the first `<Tab>` in any other picker calls M.toggle, which writes a one-element array over the file — the hand-curated list is destroyed with no backup. undo_last_toggle cannot recover it because its snapshot is the same empty list. This is the one cmdlog store whose contents cannot be reconstructed from anything else.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/cmdlog/ui/picker_utils.lua:167` · `M.open_picker` · confidence **high**

**Befund.** `if config.options.picker == "fzf" then` routes to fzf-lua; anything else falls through to the Telescope branch (lines 190-231). `health.lua:53` accepts `picker == "fzf" or picker == "fzf-lua"` as valid and reports ok, `health.lua:67` tells the user to "Set picker to 'telescope', 'fzf' or 'fzf-lua'", and `@types/init.lua:40` declares the union with `'"fzf-lua"'` in it.

**Regelbezug.** ERR-22: an invalid config value must degrade to its default and be made visible via `:checkhealth`. Here the inverse happens — `:checkhealth` actively blesses a value the runtime does not honour, and there is no degradation path at all. The code already carries a `CDX` comment at lines 164-166 acknowledging that the three sites disagree, so this is confirmed, not inferred.

**Auswirkung.** `picker = "fzf-lua"` — a spelling health.lua itself recommends and @types declares valid — silently falls through to the Telescope branch. With only fzf-lua installed, `:checkhealth cmdlog` prints "picker = 'fzf-lua' and fzf-lua found" while every `:Cmdlog` subcommand throws `module 'telescope.pickers' not found`. ERR-22's requirement is not just degradation but visibility via :checkhealth; here checkhealth actively certifies the broken configuration, which is worse than staying silent.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/cmdlog/core/shell.lua:380` · `M.delete_entry` · confidence **high**

**Befund.** `vim.fn.readfile(path)` at line 380 produces `lines`; `kept` is computed from it at lines 389-395; the write at line 403 (`vim.fn.writefile(kept, path)`) happens inside `do_write`, which is called from `kit.confirm`'s `on_answer` callback (line 427) — an asynchronous float dialog. Nothing re-reads or re-verifies the file between the scan and the write.

**Regelbezug.** ERR-30: every match/edit computed during a scan must be re-verified against the *current* text immediately before writing. Here an unbounded amount of wall-clock time (the user answering a modal) sits between the read and a full-file overwrite of a file that a live interactive shell appends to continuously.

**Auswirkung.** Single-entry `<C-x>` on a shell-history entry: the confirmation float opens, and any command the user's shell appends while the dialog is up (zsh with INC_APPEND_HISTORY, or any shell exiting in that window) is silently erased when they answer yes, because writefile replaces the file with the pre-dialog snapshot. The auditor's batch claim is WRONG and I refute that half: for `#targets > 1`, mappings.lua l.186-191 confirms once and then calls run(true), and with `skip_confirm = true` shell.lua l.411-414 calls do_write() synchronously inside delete_entry — so the loop at l.168-178 is strictly sequential and each iteration's readfile already sees the previous iteration's write. There is no last-writer-wins and no N-1 lost deletions; the batch path is in fact the safer one, since all its reads happen after the single confirmation.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/cmdlog/core/shell.lua:22` · `module top level` · confidence **high**

**Befund.** `local kit = require("ui.kit")` is a bare, unguarded require at module scope, making ui.nvim a hard load-time dependency of `cmdlog.core.shell`, while `docs/installation.md:15-18` lists ui.nvim as "**optional**. […] required only the first time `:Cmdlog shell` or `:Cmdlog shell-full` actually deletes an entry."

**Regelbezug.** LUA-01: a plugin declares a dependency hard (bare require) or soft (`pcall(require, …)` + fallback) and holds that line — "Eine harte Abhängigkeit darf in der Doku nie als optional dargestellt werden." The plugin's own `TESTS/smoke_spec.lua:32-34` already states the fact the docs contradict ("cmdlog.core.shell requires ui.kit at module load"). Introduced by commit 6da5140 (`refactor(ui): migrate from lib.nvim.ui.kit to ui.nvim`) without the docs/health follow-up.

**Auswirkung.** Installing exactly what installation.md calls required (lib.nvim + one picker) leaves four of the ten `:Cmdlog` subcommands — bare `:Cmdlog`, `full`, `shell`, `shell-full` — throwing `module 'ui.kit' not found` at require time, not at delete time as the docs promise. `:checkhealth cmdlog` then aborts at health.lua:71 on the same machine, after the picker section but before the shell-detection and composer sections, and never names ui.nvim as the missing piece.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/cmdlog/core/favorites.lua:205` · `M.import / M.export` · confidence **high**

**Befund.** `M.import(path)` does `vim.fn.expand(path)` on the argument that `bindings/usrcmds.lua:142` passes straight from `ctx.args.path` of `:Cmdlog import <path>`. `M.export` does the same at line 185. lib.nvim's composer `PATH` argtype (`composer/argtypes.lua:145`) has already run the value through `lib.nvim.cross.fs.expand_path`, which handles only `~`, `$VAR`, `${VAR}` and `%VAR%` and leaves backticks, `%`, `#` and glob characters untouched.

**Regelbezug.** SEC-34: `vim.fn.expand()` must never be applied to user text. A backtick span in its argument is a command substitution through `&shell`, and `%`/`#`/`<cfile>`/`<cword>` are Vim specials. The value here is literally what the user typed on the `:Cmdlog` command line, and the safe expansion the rule prescribes (`lib.nvim.cross.fs.expand_path`) has already been applied upstream — this second `expand()` adds nothing but the attack surface.

**Auswirkung.** A backtick span in the path argument of `:Cmdlog import`/`:Cmdlog export` is run through `&shell` by vim.fn.expand() before any file is touched — command execution from a path argument. I correct one sub-claim: `:Cmdlog export ~/notes/cmdlog%.json` does NOT misfire, because expand() only treats `%`/`#`/`<...>` as cmdline-specials when the string *starts* with them. The leading-special case is real though: `:Cmdlog import #.json` expands `#` to the alternate buffer's name, so the import reads a file the user did not name, and the same shape applied to export can overwrite an open source file. Removing the redundant expand() call costs nothing, since the composer already resolved `~`/`$VAR`.

### `SEC-50` — Ein Preview liest, es führt nicht aus und wertet nicht aus

`lua/cmdlog/ui/picker_utils.lua:183` · `M.open_picker (fzf branch default action)` · confidence **high**

**Befund.** Under `picker = "fzf"` the default `<CR>` action is `if selected[1] then vim.cmd(selected[1]) end` — it executes the selected history entry as an Ex command. No picker module passes `opts.actions`, so this default is always what fzf users get. The Telescope branch's equivalent (`ui/mappings.lua:38`) only does `vim.fn.feedkeys(":" .. value, "n")`.

**Regelbezug.** SEC-50's own rationale names this exact situation: "Die Einträge sind nicht mal zwingend die eigenen — `extra_files`, Shell-History u. ä. falten fremden Text als Quelle ein". `ui/preview_policy.lua:7-16` states the plugin's rule ("a preview reads, it does not run") and gates execution behind `preview_execute = false` plus a `risky_patterns` refusal — the fzf `<CR>` path bypasses both gates, applies no `risky_patterns` check and asks for no confirmation. README.md:24 promises the opposite: "Commands are inserted into the command-line, never executed for you — this is recall, not automation."

**Auswirkung.** Under `picker = "fzf"`, `<CR>` executes the highlighted line as an Ex command with no prompt, no risky-pattern refusal and no execution gate. The reachable-from-foreign-text part is real: all_picker/all_unique_picker fold `extra_files` content and shell history into the same list, so an arbitrary text file's line becomes an Ex command. Concretely dangerous entries are nvim-history lines like `!rm -rf build` or `qa!`, and shell-history lines that also parse as Ex commands (`source ~/.bashrc`, `set -x`). The auditor's `:!rm -rf build` example holds for nvim-history/extra_files entries; a plain shell line such as `rm -rf build` fails harmlessly with E492, so not every folded-in line is executable — but enough are, and the README states flatly that none are.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/cmdlog/ui/telescope-previewer.lua:126` · `command_previewer -> shell branch` · confidence **medium**

**Befund.** `stream(bufnr, { command = plan.arg })` passes an entire shell command line as `opts.command`. `lib.nvim.system.job.start` builds argv as `local cmd = { opts.command }` plus `opts.args` (`system/job.lua:33`), so `:!git status --short` becomes `vim.system({ "git status --short" })` — one argv element that is not an executable. `stream()` (lines 39-53) wraps neither `job.start` nor `vim.system` in a `pcall`.

**Regelbezug.** ERR-01 requires `pcall` at system boundaries — spawning an external process is one, and this is not a hot path. `vim.system` raises for a non-resolvable executable rather than routing the failure to `on_stderr`, so the error escapes `define_preview` into Telescope's render loop. The `:terminal` branch two lines above (line 121) shows the correct shape for the same problem (`command = vim.o.shell, args = { vim.o.shellcmdflag, plan.arg }`); the shell branch was not given it.

**Auswirkung.** With `preview_execute = true` (non-default, which is why this is medium), moving the cursor onto any multi-word `:!<cmd> <args>` entry raises ENOENT out of define_preview instead of showing output — telescope does not pcall the previewer, so the error surfaces and the preview window stays empty for exactly the entry class the option was enabled for. Only single-word `:!ls`-style entries work. The fix is the one-line shape already used by the terminal branch directly above; the missing pcall is the secondary defect.

### `ERR-02` — Type Guards & Literal Checks

`lua/cmdlog/core/tracker.lua:25` · `is_redacted` · confidence **medium**

**Befund.** `is_redacted` guards only `if not patterns or patterns == false then return false end` (line 23) and then calls `ipairs(patterns)` at line 25. There is no `type(patterns) == "table"` check. `core/risky.lua:24` — the sibling function doing the identical job for `risky_patterns` — has exactly that guard (`if type(patterns) ~= "table" then return matches end`).

**Regelbezug.** ERR-02 requires a `type(...)` check before working with a value, and ERR-22 requires an invalid single config value to degrade to its default rather than break the feature. `@types/init.lua:48` declares `redact_patterns string[]|false`, so a bare string is invalid input — and `ipairs` on a non-table raises in LuaJIT.

**Auswirkung.** `setup({ redact_patterns = "token" })` — a plausible single-pattern shorthand — makes is_redacted raise on every `:` command. The error is caught by lib.nvim's autocmd wrapper, so Neovim keeps working but the user gets an "Autocmd failed (CmdlineLeave)" notification after every single Ex command. Because is_redacted is called at l.47, before the `vim.schedule` block at l.58, project history, stats and error tracking record nothing at all for the whole session. risky.lua having the guard and tracker.lua not having it makes this a plain omission rather than a design choice.

### `ERR-33` — Fenster-/Buffer-Handles bei Ausführung erneut validieren

`lua/cmdlog/ui/mappings.lua:148` · `delete mapping -> finish()` · confidence **medium**

**Befund.** `actions.close(prompt_bufnr)` is called from `finish()`, which runs only after every `delete_fn` callback has returned. For shell/combined pickers that path goes through `core/shell.lua`'s `kit.confirm` — an asynchronous ui.nvim float dialog. `prompt_bufnr` is the value captured when the mapping was attached and is never re-validated. The same pattern sits at line 99, inside the `vim.ui.input` callback of the tag mapping.

**Regelbezug.** ERR-33/LUA-13: a callback deferred past the capture point must re-validate its window/buffer handles at execution time (`nvim_buf_is_valid` or the picker's own liveness check). `ui/telescope-previewer.lua:22,31` does exactly that for its preview buffer; these two sites do not.

**Auswirkung.** Deleting a shell-history entry with the confirmation dialog: answering yes writes the file successfully, then finish() raises `attempt to index a nil value (local 'picker')` out of telescope's actions.close. The user sees a Lua error for a delete that actually succeeded, and because the error aborts finish() before `vim.schedule(refresh_fn)` at l.149, the picker list is never refreshed — though in practice the picker window is already gone, so the visible symptom is the traceback rather than a stale list. The `<C-t>` tag mapping at l.99 has the same exposure under any async vim.ui.input provider (dressing.nvim, snacks.input, noice).

### `ERR-50` — Config-Validierung vor dem Merge

`lua/cmdlog/config/init.lua:19` · `M.setup` · confidence **medium**

**Befund.** `M.options = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), opts)` merges the user table with no key validation at any point — neither before nor after. There is no `KNOWN_OPTS` list, no "did you mean" pass, and `health.lua` validates only `picker`. The one place unknown names *are* checked is `bindings/keymaps.lua:74`, which warns about an unknown `:Cmdlog` subcommand inside `keymaps`.

**Regelbezug.** ERR-50 states the ordering requirement and gives the failure it exists to prevent verbatim: "ein Tippfehler in einer verschachtelten Option verschwindet sonst stillschweigend im Default und wird nie erkannt". With no validation at all, that failure is unconditional rather than merely mis-ordered. Reported as a judgment call because the rule is phrased about ordering and presupposes a validation step exists.

**Auswirkung.** Any misspelled top-level or nested option (`preview_executes`, `redact_pattern`, `higlight_risky`) is deep-merged into M.options as an inert extra key. The plugin keeps its default, :checkhealth reports everything ok, and the user has no way to learn the option never took effect. I correct the auditor's overstatement on the security case: a `redact_pattern` typo does not leave the user unredacted — DEFAULTS.lua l.29-34 still supplies password/secret/token/Bearer/api[-_]?key — it silently drops only the site-specific patterns the user added, which is a narrower but still real gap.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/cmdlog/core/favorites.lua:68` · `M.load` · confidence **medium**

**Befund.** `M.load` returns `favorites_cache[target]` — the live module-level cache table — by reference on every path (lines 68, 72, 78, 84, 88). The docstring says only "@return string[] favorites or empty table"; there is no copy and no "live reference, do not mutate" contract. `favorites_picker.lua:25` passes the returned table to `open_picker` as *both* `entries` and `favs`.

**Regelbezug.** ERR-54: a public getter handing out shared internal state by reference must either copy before returning or explicitly document "live reference, nicht mutieren", with every consumer holding to it. Neither is done. `M.move` (line 151) defends itself with `vim.deepcopy(M.load())` and `history_picker.lua:30` / `shell_picker.lua:31` use `vim.deepcopy(favs)` — which shows the authors already knew the return value is not safe to own, without the getter ever saying so.

**Auswirkung.** Latent, and I hold the auditor to their own wording: nothing is broken today. cmdlog satisfies the half of ERR-54 that says every consumer must hold to the no-mutate contract — they all do — but not the half that says the contract must be written down. So this is a documentation/API-hygiene gap, not a live bug: the fix is either `return vim.deepcopy(...)` or one line of docstring saying "live reference, do not mutate". Its value is preventive — the three existing deepcopy call sites show the authors already knew the return value is unsafe to own, and the next consumer that sorts or appends in place would silently reorder or corrupt favorites.json for the rest of the session via M.save. It should be ranked well below the other findings.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/cmdlog/core/stats.lua:16` · `load / by_frequency / describe` · confidence **medium**

**Befund.** `load()` validates only `type(cache) ~= "table"` on the whole decoded document; individual fields are never checked. `by_frequency` then does `data[a].count > data[b].count` (lines 51-52) and `describe` does `entry.count` / `os.date(..., entry.last_used)` (line 63) on whatever was in the file. `core/tags.lua:32` (`load()[cmd] or {}` fed straight to `table.concat` at `favorites_picker.lua:32`) and `core/project_history.lua:86` (`data[root] or {}` fed to `process_list`) have the same shape.

**Regelbezug.** SEC-33: persisted snapshots are untrusted and every field must be re-validated on load (type, length, count cap). Valid JSON of the wrong shape passes `store.load_json` cleanly, so ERR-11's corrupt-file path does not cover this — it is a second, distinct gap on the same files.

**Auswirkung.** A stats.json entry whose value is a JSON number or null (interleaved write from a second Neovim instance — there is no locking, and each instance holds an independent module-level cache) decodes fine and then crashes `:Cmdlog stats` inside table.sort's comparator with "attempt to index a number value" / "attempt to index a userdata value" (JSON null decodes to vim.NIL, not Lua nil). The error names neither the file nor the key, and the crash repeats on every invocation until the user finds and deletes stats.json by hand. The same malformed entry also breaks stats.record at l.27-28 inside tracker.lua's scheduled callback. A string value under a command key in favorite_tags.json breaks `:Cmdlog favorites` the same way via table.concat.

### `SEC-45` — Redaktion rundet auf Übervorsicht

`lua/cmdlog/core/tracker.lua:26` · `is_redacted` · confidence **medium**

**Befund.** `local ok, matched = pcall(string.find, cmd, pattern); if ok and matched then return true end` — when a `redact_patterns` entry is malformed (unfinished capture, bad character class), `pcall` fails, the pattern is skipped, and the loop falls through to `return false`, meaning "not redacted". Nothing warns that a configured pattern never fires.

**Regelbezug.** SEC-45: redaction rounds toward over-caution — "lieber zu viel als zu wenig schwärzen — Über-Redaction ist der sichere Fehlermodus". Here a broken pattern fails in the unsafe direction. The identical `pcall`-and-skip shape in `core/risky.lua:30` is correct, because there the consequence is a missing highlight; here the consequence is a secret written to disk, and `DEFAULTS.lua:23-28` states plainly that this list exists so that `:!curl -H "Authorization: Bearer …"` does not "persist the token there forever".

**Auswirkung.** A single malformed entry in a user's redact_patterns list (e.g. a trailing `%`, an unfinished capture, a bad character class) silently drops that pattern from the redaction set. Command lines that only that pattern would have caught are then written verbatim into plaintext stats.json, project_history.json and errors.json under stdpath('data'), and persist there. The built-in defaults (password/secret/token/Bearer/api[-_]?key) still fire, so the loss is scoped to the user's own additions — which are precisely the site-specific secrets they added the list for. Nothing warns, and :checkhealth does not validate the list.

> **Abdeckung dieses Laufs.** Coverage: I read all 3529 lines of lua/ (every one of the 40 modules, end to end) plus the header and bootstrap of TESTS/smoke_spec.lua (2737 lines), README.md, docs/installation.md and the docs/ file listing. I also read the relevant lib.nvim dependencies to verify claims rather than guess: lib/nvim/system/job.lua (argv construction, for the ERR-01 finding), lib/nvim/bindings/usercmd/composer/argtypes.lua and lib/nvim/cross/fs/expand_path/init.lua (to establish that the SEC-34 double-expansion is real and that backticks/% survive the composer), and lib/nvim/bindings/autocmd/init.lua (to establish that the ERR-02 failure is a per-command notification rather than a hard crash). I confirmed ui.kit lives in ui.nvim, not lib.nvim.

No findings under TESTS/ or scripts/ — there is no scripts/ directory, and TESTS/smoke_spec.lua's bootstrap is correct (it already accounts for the ui.nvim hard dependency that the user-facing docs deny, which is what let me confirm finding 3). is_test_code is false for everything reported.

What I could NOT cover:
- CMT-16 (no hand-edits in generated files). docs/map/{index.html,module_map.json,overview.md} and docs/BINDINGS.md are generator output, but the generator (:DocMap / gen_map) lives outside this repo and I had no way to re-render and diff. I did not inspect their contents for drift; this needs a regeneration run, not a read.
- XP-06 (case-sensitive module paths) beyond a spot check. lua/cmdlog/@types/ matches require("cmdlog.@types"), and TESTS/ is referenced by file path rather than module path, so the sandbox.nvim failure mode does not apply — but I did not audit every docs/ link target against the on-disk directory spelling.
- I did not run the plugin or its test suite; every finding is from reading code. The two lowest-certainty items are marked accordingly: ERR-33 (finding 8) depends on Telescope tearing down its picker when an async float takes focus, which I reasoned about from telescope's actions.close/get_current_picker path but did not reproduce, and ERR-50 (finding 12), where the rule is phrased about validation ordering while cmdlog has no validation step at all.

Genuinely clean areas worth recording: no timers anywhere (PERF-62/82 have no surface), no __mode weak tables (LUA-48), no vim.g/b/w round-tripping (LUA-17), no vim.fn.glob (XP-01), no module-level layout geometry (PERF-92), no treesitter (TS-04), no pcall(f(args)) mistakes (ERR-62), and no a-and-b-or-c hazards — I checked all 15 such expressions individually and every falsy-b case is unreachable (ERR-60 is clean). config/init.lua is ERR-51/ERR-53-correct (fresh vim.deepcopy(DEFAULTS) per setup, and every consumer dereferences config.options.X at call time rather than capturing a subtable). ui/preview_policy.lua is a well-built SEC-35 fix and matches the Belege footnote naming cmdlog for that rule; I did not re-report it. LUA-06 is likewise already cleared for cmdlog in its Belege and the DEFAULTS.lua stdpath calls are the standard idiom, so I left it alone.

---

## color_my_ascii.nvim

**14 Befunde** (7 × high). Roh gemeldet: 16.

### `ERR-03` — Explizite Rückgaben

`lua/color_my_ascii/init.lua:46` · `M.setup` · confidence **high**

**Befund.** `local ok, err = pcall(config.setup, opts)` is followed by `if not ok and cfg.debug_enabled then ... return false, tostring(err) end`. With `debug_enabled` false — the default — a thrown `config.setup` is swallowed entirely: execution falls through to the rest of setup and the function returns `true, nil`.

**Regelbezug.** ERR-03 requires relevant functions to return success/failure with an error object and forbids silent failures; the function's own annotation promises `@return boolean success`. Reporting success for a failed initialisation is precisely the silent error the rule exists to prevent, and gating the report on a debug flag makes the default configuration the blind one.

**Auswirkung.** A bad colour anywhere in `overrides`, `languages` or a scheme raises inside `build_char_lookup`/`build_keyword_lookup` — which run at config/init.lua:419-421, i.e. *after* `current_config` was already replaced at line 404. So the session is left with the new config applied but `M.char_lookup`/`M.keyword_lookup`/`M.unique_keyword_lookup` still holding their previous (on a first setup: empty) values, `M.setup` reports success to lazy.nvim, and highlighting is silently wrong for the rest of the session with nothing in `:messages` and nothing in `:checkhealth`.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/color_my_ascii/parser.lua:304` · `M.get_byte_offset` · confidence **high**

**Befund.** `for _, char in vim.str_utf_pos(line) do` drives `vim.str_utf_pos` as a generic-for iterator, but that function returns a *table* (a list of byte positions), not an iterator function. The generic-for then attempts to call that table.

**Regelbezug.** LLS-31 covers a call made with the wrong signature that throws at runtime and therefore never does the work it claims to; the rule marks this class critical rather than mere diagnostics hygiene. `get_byte_offset` is a public, annotated function on `color_my_ascii.parser`, a module four other modules require.

**Auswirkung.** Correcting the auditor on reach: a grep over `lua/` finds no caller at all — only the definition here and TESTS/byte_offsets_spec.lua:155-156, which already pins it (`'BUG: get_byte_offset raises for every column > 0'`). So nothing in the plugin is currently broken by it. What is true is that a documented public entry point of a module four others require is dead on arrival: any external caller, or the first internal caller added later, gets a raised error instead of a byte offset for every `col > 0`.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/color_my_ascii/init.lua:215` · `M.highlight_buffer` · confidence **high**

**Befund.** `return false, string.format(('Failed to clear buffer (cache hit): %s'):format(), err)` — the inner `(...):format()` is `string.format('…%s')` with no argument, which raises `bad argument #2 to 'format' (no value)`. The identical mistake sits at line 278: `notify.warn(string.format(('Inline code highlighting error: %s'):format(), err))`.

**Regelbezug.** LLS-31: a call whose signature is wrong throws where the code intends to report, so the reporting path can never do its job and the breakage stays invisible. Both sites are error handlers, which is exactly why nothing has surfaced them — the only code that would exercise them is code nobody looks at.

**Auswirkung.** Both are cold: each needs an already-failing API call to be reached, and line 278 is additionally gated on `debug_enabled` (false by default). When reached, `M.highlight_buffer` raises instead of returning `false, msg`. Line 215's throw escapes the unprotected call sites at init.lua:125 (hot-reload loop in setup), init.lua:322 (`toggle_buffer`), init.lua:336 (`toggle`) and commands/schemes.lua:94 — the two loops abort entirely rather than skipping one buffer. Line 278 replaces the debug warning that was meant to name the real cause with an opaque format error. The auditor's line references (126/333) are off by one or two; the defects themselves are exactly where claimed.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/color_my_ascii/integrations/menu.lua:20` · `module top level` · confidence **high**

**Befund.** `local contextmenu = require('ui.contextmenu')` is a bare, unprotected require at module load, while the module's own header says "color_my_ascii.nvim does not depend on a menu plugin", `config/DEFAULTS.lua:209` calls it a "soft dependency", and `docs/requirements.md` lists ui.nvim under "Optional, each detected at runtime and degrading to nothing when absent" — explicitly naming the context-menu entries.

**Regelbezug.** LUA-01 requires a plugin to declare a dependency either hard (bare require, no fallback) or soft (pcall + fallback with an identical interface) and to hold that line, and says a hard dependency may never be presented as optional in the documentation. The same repo does the soft form correctly for the *same* plugin elsewhere (`commands/hover.lua:175`, `commands/fence/export.lua:76,93` all use `pcall(require, 'ui.kit')` with real fallbacks), so the treatment is inconsistent as well as mis-documented.

**Auswirkung.** On a machine without ui.nvim the failure is at `require` time of the integration module itself, not inside `items()`: the snippet docs/integrations.md tells users to paste into their own <RightMouse> dispatcher raises "module 'ui.contextmenu' not found" and takes the whole dispatcher down, not just this plugin's entries. The `cfg.menu.enable` opt-out at line 34 cannot help, because it sits behind the top-level require. `:checkhealth` offers no explanation, since health.lua probes only lib.nvim.

### `PERF-46` — Cache-Key vollständig

`lua/color_my_ascii/api/fences.lua:99` · `scan_cached` · confidence **high**

**Befund.** The public fence-API block cache is keyed on `(bufnr, changedtick)` only. The cached `ColorMyAscii.FenceBlock` records carry `is_ascii`, which `parser.is_ascii_fence` derives from `cfg.fence_language_map` and `cfg.treat_empty_fence_as_ascii`; the backend that produced the records also depends on `cfg.treesitter.{enabled,block_detection}`. None of that is in the key, and nothing calls `M.invalidate` when the config changes (verified by grep across `lua/`).

**Regelbezug.** PERF-46 requires the cache key to contain every parameter that influences the result, otherwise the cache silently serves results computed for a different configuration. `init.lua`'s hot-reload path shows the author's own intent — it calls `cache_manager.clear_all()` on re-setup — but the fence-API cache is a second, separate cache that is never flushed there.

**Auswirkung.** Correct in mechanism; the auditor overstated the visible half. `fence_hl.apply` does consume the stale flag (`b.is_ascii` at fence_hl.lua:369-370), but `apply_to` defaults to `'all'` for both sub-features (DEFAULTS.lua:168 and the fence_line_highlight block), so the mis-painting only shows for a user who set `apply_to = "ascii"`. The unconditional damage is the public API: after `:ColorMyAscii schemes switch matrix` (or back), every buffer that is not edited afterwards keeps its old `is_ascii` classification for the rest of the session, and `require('color_my_ascii').fences.list_blocks()` hands consumers (mdview.nvim, markdown.nvim) those stale flags with no way to force a rescan short of calling the undocumented `M.invalidate` themselves.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/color_my_ascii/commands/fence/export.lua:165` · `write_and_finish` · confidence **high**

**Befund.** `path = vim.fn.expand(path)` is applied to the export path, which comes either from `:Fence export <path>` argv (tokenised in `commands/fence/init.lua:18`) or from the `vim.ui.input`/`kit.input` prompt in `prompt_path` — both raw user text.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on buffer/user text: a backtick span in the argument is a command substitution through `&shell` (`vim.fn.expand("`cmd`")` runs the shell), and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. The rule names `lib.nvim.cross.fs.expand_path` as the replacement for the `~`/env-var expansion actually wanted here; lib.nvim is a hard dependency of this plugin and that module exists.

**Auswirkung.** A backtick span anywhere in the export path — typed after `:Fence export` or pasted into the export prompt — is executed through 'shell' before anything is written, and the exit is silent (expand returns the command's stdout as the path). `%`/`#`/`<cfile>` are Vim specials: typing `%` at the prompt resolves to the current file's name, so the overwrite-confirm dialog at line 173 offers to overwrite the markdown document the block came from. This is a self-inflicted hazard (the user types or pastes the string), not a remotely reachable RCE, but a path copied out of a README or repo is a realistic carrier.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/color_my_ascii/commands/fence/import.lua:17` · `M.run` · confidence **high**

**Befund.** `path = vim.fn.expand(path)` where `path = argv[1]`, i.e. the literal token the user typed after `:Fence import`.

**Regelbezug.** Same SEC-34 violation as the export path: `vim.fn.expand` is Vim's *filename* expansion and runs backtick spans through `&shell`, so a user-supplied string must never reach it. `lib.nvim.cross.fs.expand_path` is the sanctioned alternative and is available here.

**Auswirkung.** `:Fence import` with a backtick span in the argument runs that command through 'shell' before the readability check at line 18; the substituted stdout then becomes the path, so the user sees a 'file not readable' message rather than any sign that a command ran. `%`, `#`, `<cfile>` also resolve as Vim specials, so `:Fence import %` reads the current file instead of erroring.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/color_my_ascii/fence_hl.lua:169` · `M.setup_hl` · confidence **medium**

**Befund.** `pcall(api.nvim_set_hl, 0, CONTENT_GROUP, resolve_content_spec(cfg))` — the argument expression `resolve_content_spec(cfg)` is evaluated *before* the pcall, in the unprotected caller frame. Inside it, `color.shade(bg, fch.amount or 6, direction)` reaches `math.max(0, math.min(100, percent or 0))` (`utils/color.lua:46`) with no type check on `amount`. `M.setup_hl` is itself called unprotected from `init.lua:79`, which is called unprotected from `plugin/color_my_ascii.lua:44`.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default rather than abort plugin initialisation, and to be surfaced through `:checkhealth`. The neighbouring `right_pad` is handled correctly (`tonumber` + clamp at `fence_hl.lua:346-347`); `amount` is not. The mechanism is ERR-62's: the `pcall` that appears to guard the line protects only `nvim_set_hl`, never the argument that computes its value.

**Auswirkung.** Overstated by the auditor, and the correction matters. `plugin/color_my_ascii.lua:44` calls `setup()` with **no** opts, so the bad value can never be present there, and lazy.nvim sources `plugin/` before running `config`/`opts` — lines 47 and 50 (the `:ColorMyAscii` command tree and the FileType autocmds) have already run. What actually happens is that the user's own `setup({ fence_content_highlight = { amount = '6%' } })` throws at init.lua:80, so everything registered after it never exists: the two ColorScheme re-resolve autocmds (lines 81-96) and the WinResized/VimResized right_pad recompute (lines 100-115), plus the hot-reload re-highlight. Fence highlighting therefore goes stale on the next `:colorscheme` with no explanation, lazy.nvim surfaces an opaque stack trace ending in utils/color.lua:46, and `:checkhealth` says nothing about the offending value instead of degrading it to its default of 6.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/color_my_ascii/commands/fence/format.lua:84` · `M.run` · confidence **medium**

**Befund.** The async `vim.system` callback writes the formatter's stdout back with `api.nvim_buf_set_lines(buf, sp[1], ep[1], false, out)`. Two extmarks anchor the *positions* (lines 63-64, 71-72) and the buffer's validity is rechecked, but nothing re-reads the interior text or compares a captured `changedtick` against the text that was sent to the formatter on stdin.

**Regelbezug.** ERR-30 requires an edit computed during a scan to be re-verified against the *current* text immediately before writing, and treated as stale (skipped) on any divergence. Position anchoring handles lines shifting above the block; it does not detect that the block's own content changed. The code comment ("Anchor the interior so a slow formatter can't corrupt a shifted region") shows only the shift half of the problem was considered.

**Auswirkung.** Any edit inside the fenced block between the spawn and the callback is silently replaced by output computed from the pre-edit text — the extmarks even follow inserted lines, so the replace range grows to cover the new content and swallows it whole. No warning is emitted; the only recovery is undo. The window is the formatter's runtime: short for `gofmt`, but a cold `prettier` or `rustfmt` start is comfortably long enough to type into, and `:Fence format` is exactly the command a user fires and keeps typing after.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/color_my_ascii/config/init.lua:404` · `M.setup` · confidence **medium**

**Befund.** `current_config = vim.tbl_deep_extend('force', defaults, config_to_merge)` merges the user's table straight into the defaults. There is no known-keys set and no validation pass anywhere in the module (grep confirms no `KNOWN_OPTS`/`validate` in `lua/`); only `merge_user_languages` checks structure, and only for `languages` entries, and only *after* the merge (line 409).

**Regelbezug.** ERR-50 requires config validation (unknown keys, "did you mean …") to run before the merge, precisely so a typo in a nested option cannot vanish into the default. Here nothing runs at all, before or after, and `health.lua` does not report unknown keys either.

**Auswirkung.** Accurate as filed. `setup({ fence_line_higlight = { enable = false } })` or `setup({ comment_ascii = { enabled = true } })` is accepted without a word: the misspelled key lands in `current_config` as dead data, the real option keeps its default, and the user gets a feature that appears not to work with no diagnostic anywhere — not in `:messages`, not in `:ColorMyAscii show-config` (bindings/usrcmds.lua:56, which prints only known fields), not in `:checkhealth`.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/color_my_ascii/commands/schemes.lua:89` · `M.switch_scheme` · confidence **medium**

**Befund.** `require('color_my_ascii').setup(scheme)` passes the bare scheme module table. `config.setup` then does `current_config = vim.tbl_deep_extend('force', defaults, config_to_merge)` (`config/init.lua:404`) with `defaults` being the pristine DEFAULTS copy — and the scheme tables carry no key outside the colour/feature set (verified: none of `schemes/*.lua` even defines `scheme`).

**Regelbezug.** LUA-87 governs config precedence: what the plugin applies later must not silently overrule what the user passed to `setup()`. The rule's own counter-case (reposcope) is the mirror image of this — merging into the wrong base table. Here a runtime command rebuilds the config from DEFAULTS + scheme, discarding the user's `setup()` arguments entirely.

**Auswirkung.** `:ColorMyAscii schemes switch <name>` resets every option the user passed to `setup()` that the chosen scheme does not mention — back to the DEFAULTS value, not to `false`: `fence_line_highlight`, `fence_content_highlight`, `comment_ascii`, custom `languages`, `treesitter`, `fence_export/run/format`, `cache`, `debounce`, `menu`, `keymaps`. `comment_ascii.enable` defaults to `false` (DEFAULTS.lua:41), and init.lua:76 then re-runs `bindings.autocmds.enable()`, which clears and rebuilds the `ColorMyAscii` augroup from the reset config, so comment-block highlighting stops until the user re-runs their own setup() or restarts. The Telescope picker is worse than the auditor says: `preview_scheme` applies each scheme for real, and closing with `<Esc>` runs no restore, so the last previewed scheme stays applied even when the user cancelled.

### `PERF-93` — Heißes Event: billiger Guard **oder** Throttle, nie ungeschützt

`lua/color_my_ascii/commands/schemes.lua:154` · `preview_scheme` · confidence **medium**

**Befund.** `preview_scheme` is wired to `CursorMoved` (line 170) and, on every fire, calls the plugin's full `require('color_my_ascii').setup(selection.scheme)` followed by `M.highlight_buffer` for every managed buffer. It has no guard at all — not even "is this the same scheme as last time".

**Regelbezug.** PERF-93 states the question on a hot event is whether the handler leaves the common case cheaply, and that an unguarded handler on a hot event is never acceptable. Buffer-scoping it to the picker prompt narrows *when* it is hot, but inside the picker every j/k is a fire, and the handler's body is the most expensive operation the plugin has.

**Auswirkung.** Every j/k in the scheme picker runs the plugin's most expensive operation end to end: full config merge, all three lookup tables rebuilt, four augroups torn down and recreated, the libuv cache-cleanup timer closed and replaced, the parse cache flushed and every managed markdown buffer re-parsed and re-extmarked. Holding `j` across ten schemes does that ten times. One correction to the auditor: `bundled_defs()` is memoised (config/init.lua:147-163), so the 31 language files are not re-globbed or re-required — only the lookups built from the already-loaded tables. Scope is also narrower than 'a hot event' in general, since the autocmd is buffer-local to the picker prompt (line 172).

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/color_my_ascii/config/init.lua:50` · `load_languages` · confidence **medium**

**Befund.** `pcall(fn.globpath, lang_path, '*.lua', false, true)` feeds a raw directory path to `globpath`, which reads it as a *pattern*. The same construction is at line 110 (`load_groups`) and in `health.lua:28` (`count_files`). `lang_path` is derived from `debug.getinfo(1,'S').source`, i.e. whatever spelling the runtimepath entry has.

**Regelbezug.** XP-01 forbids feeding a raw path to `glob`/`globpath` for "list the files in this directory" and names `lib.nvim.fs.globbable` as the replacement — it globs a real tree and compares the hit count instead of trusting the return value. lib.nvim is a hard dependency here and that module exists. `~`, `[`, `?`, `*`, `{}` in the path are interpreted, and on Windows an 8.3-shortened rtp entry makes glob try to resolve `~1` as a home directory and return an empty list with no error.

**Auswirkung.** Conditional but verified: if the install path contains a glob metacharacter (`[ ] { } ? *`) — or a comma, since globpath splits its {path} argument on commas — both loaders return early with zero entries. `defaults.keywords` and `defaults.groups` are then empty, so `build_char_lookup`/`build_keyword_lookup` produce nothing and character and keyword highlighting do nothing at all, while the only signal is the generic 'WARNING - No language files found in: …' at line 57 that does not name path syntax as the cause; health.lua:28 reports a file count of 0 for the same reason. I could not reproduce the 8.3-short-path half of the auditor's claim on this machine, so treat that part as unverified; the metacharacter/comma half is demonstrated.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/color_my_ascii/config/init.lua:435` · `M.get` · confidence **low**

**Befund.** `function M.get() return current_config end` hands out the module's live configuration table by reference. The doc comment is only "Get the current configuration"; it neither copies nor warns that the result must not be mutated.

**Regelbezug.** ERR-54 requires a public getter over shared internal state to do one of two things: copy before handing out, or explicitly document "live reference, do not mutate" so every consumer knows. This one does neither. Copying is not the right fix here (`M.get()` runs once per character in the highlight hot path), which makes the documented-live-reference option the applicable half of the rule.

**Auswirkung.** Nothing breaks today — a grep over `lua/` finds assignment into the returned table only inside config/init.lua itself, so the auditor's own scoping is right. The exposure is that ~30 call sites hold the live config, and the nested language/group values are the `require`d module tables, so the first consumer that sorts or appends to e.g. `cfg.keywords.lua.words` for display corrupts the plugin's bundled data for the rest of the session — and `package.loaded` caching means a re-`require` will not undo it. The rule's applicable half here is the documented-live-reference one, not copying: `M.get()` runs once per character in the highlight path, so the fix is one doc line plus a convention, not a `deepcopy`.

> **Abdeckung dieses Laufs.** COVERAGE. I read every file under lua/ and plugin/ (11,549 LOC) except that the pure data tables — lua/color_my_ascii/languages/*.lua (31 files), schemes/*.lua (10) and groups/*.lua (5) — were sampled (operators.lua, symbols.lua head, catppuccin/default/dracula/gruvbox/matrix scheme headers, theme_presets in full) rather than read word by word; they are keyword/character lists with no control flow. TESTS/ was read selectively (run.lua, harness.lua head, TESTS/README.md in full, grep for package.loaded stubbing); I found no rule violations in test code and report none, so is_test_code is false throughout. lib.nvim itself was consulted only to confirm that lib.nvim.cross.fs.expand_path, lib.nvim.fs.globbable and lib.nvim.bindings.autocmd.group actually exist (they do) — it was not audited. .claude/, .git/, .deps/ and doc/tags were ignored as instructed.

ALREADY-KNOWN DEFECTS. TESTS/README.md ("Pinned bugs and findings") documents four open defects pinned by specs. One of them maps cleanly onto a critical rule and is reported above (parser.get_byte_offset / LLS-31). The other three do not map onto any of the 76 rules and are therefore not reported: comment_ascii extmarks land `#prefix + 1` bytes too far left; `enable_bracket_highlighting = false` cannot actually switch brackets off because groups/operators.lua already claims all six; twelve keywords duplicated inside their own language file. They are real and unfixed — they simply are not rule findings.

BELEGE ALREADY NAMING THIS PLUGIN. LUA-48 cites color_my_ascii (cache_manager.lua) as documentation-only, already corrected — I verified cache_manager.lua:6-9 now states plainly why a bufnr key can never be weakly collected, and the max_size eviction plus periodic is_valid_buffer sweep are both present, so nothing to re-report. XP-06 cites `docs/features/` lowercase — `ls -d docs/*/` now shows `docs/FEATURES/`, fixed.

THINGS I CHECKED AND FOUND CLEAN. PERF-07 (no `next(t)` delete loops); PERF-62/80/82 (cache_manager.setup_auto_cleanup stops+closes before replacing and wraps the tick in vim.schedule_wrap; the debounce timer is delegated to lib.nvim.debounce); PERF-92 (all fence geometry is computed per apply, with a WinResized/VimResized handler at init.lua:100); LUA-17 (vim.g holds only the boolean load flag); LUA-06 (config/DEFAULTS.lua is pure data — no env or filesystem lookup at module level); LUA-02 (utils/safe_api.lua is a pure re-export of lib.nvim.safe_api, not a private copy); SEC-01/03 (`:Fence run`/`format` both use argv-form vim.system with an explicit per-buffer cwd — no shell string anywhere in the repo); SEC-35 (every vim.cmd string is a fixed verb plus vim.fn.fnameescape, which escapes `|`); ERR-20/PRIN-27 (parser.find_ascii_blocks fails open to the heuristic scanner when treesitter is unavailable or errors); ERR-51/53 (the merge uses vim.tbl_deep_extend("force", …) against a defaults copy; no submodule holds a reference into a defaults subtable); box_align.lua is arithmetically sound end to end.

THINGS I DELIBERATELY DID NOT REPORT AS FINDINGS, because the rule's failure mode does not materialise today: (a) api/fences.lua:200 `cache = {}` replaces the table reference rather than emptying it in place, which is the pattern PERF-47 forbids — but `cache` is a module-private upvalue shared through closures, so no second holder can freeze on stale data until someone adds one; (b) `vim.fn.writefile` return values are ignored at commands/fence/run.lua:89 and commands/fence/open.lua:125, so an unwritable temp dir surfaces as a confusing interpreter error rather than "could not write temp file"; (c) plugin/ carries two independent helptag generators (color_my_ascii.lua:35 and color_my_ascii_autodoc.lua:20), the first unconditional, so doc/tags is rewritten on every startup.

NOT COVERED. CMT-16: docs/map/ is a generated tree and docs/BINDINGS.md is renderer-produced, but I could not tell from the working tree alone whether either carries a hand edit — that needs a `:DocMap`/gen_map run plus a diff, which is out of scope for a read-only audit. I also did not attempt to run the headless suite, so every claim above rests on reading, not execution; the two places where that matters most are the E348 behaviour of `expand('<cword>')` on a whitespace-only line (hover.lua:146, asserted as fact by the rules file's own spotlight.nvim Beleg) and the exact reachability of the two `('…%s'):format()` sites in init.lua, which I have flagged as cold paths in the finding itself.

---

## media.nvim

**14 Befunde** (7 × high). Roh gemeldet: 14.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/media/core/cache.lua:218` · `pump` · confidence **high**

**Befund.** `pump()` increments `running` and then calls `entry.render(...)` with no `pcall`, although every renderer passed in (`frame`, `frames`, `sheet`, `waveform`, `normalize`) spawns a process with a bare `vim.system(...)`.

**Regelbezug.** ERR-01 requires `pcall` at the process boundary. `vim.system` raises rather than returning an error when the spawn fails — verified in nvim 0.12.2: `pcall(vim.system, {"C:/nope/ffmpeg.exe"}, {}, f)` returns `false, "ENOENT: no such file or directory (cmd)"`. `core/bin.lua:80-86` deliberately hands back a configured path *without* checking it exists ("honoured as given, including when it does not exist"), so a wrong `bin.ffmpeg` routes straight into this unguarded spawn. `health.lua:46` already wraps its own `vim.system` in `pcall`, so the boundary is understood elsewhere.

**Auswirkung.** With `bin.ffmpeg`/`bin.ffprobe` pointed at a nonexistent path, each render attempt raises out of `pump()` with `running` already incremented and `inflight[out]` still populated. After `render_concurrency` (default 4) such failures, `running >= limit()` permanently and the `while running < limit()` loop at line 203 never starts anything again: every later `media.frame`/`frames`/`sheet`/`waveform` sits in the queue with a callback that never fires -- no error surfaced to the caller, no timeout. Re-requesting the same output joins the stuck `inflight` entry (line 255), and `cancel()` refuses to clear it because `started` is true. Correct as described; one scoping note -- `transcribe` reaches this only through its normalize/frame steps, not directly.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/media/core/probe.lua:258` · `M.probe` · confidence **high**

**Befund.** `vim.system(argv, …)` is called without `pcall` in the body of `M.probe`, after `inflight[path]` has already been populated at line 218.

**Regelbezug.** ERR-01: the spawn is a system boundary and `vim.system` raises on spawn failure (verified, see above). The module's own contract two lines up says the callback "runs exactly once, always on the main loop", and `media.init`'s header promises consumers the same.

**Auswirkung.** With `bin.ffprobe` set to a nonexistent path, `media.probe(path, cb)` raises out of the public API instead of calling back with an error, breaking the module's own "callback runs exactly once" contract, and the raise propagates into the synchronous callers (frame.lua:157 and the equivalents in frames/sheet/waveform/normalize). `inflight[path]` stays populated for the rest of the session, so every subsequent probe of that same path is appended to a waiter list nobody will ever drain -- the first attempt errors loudly, every one after it goes permanently silent. Scope correction: this needs a misconfigured `bin.ffprobe`; a simply-absent ffprobe is caught cleanly at line 233.

### `ERR-60` — `a and b or c` bricht, sobald `b` falsy sein kann

`lua/media/core/player.lua:173` · `M.start` · confidence **high**

**Befund.** `ontop = opts.ontop ~= nil and opts.ontop or window.ontop` — the middle term of the `a and b or c` chain is the boolean the caller passed, which can legitimately be `false`.

**Regelbezug.** ERR-60 exactly: as soon as `b` is falsy the expression yields `c` regardless of `a`. `Media.PlayerOpts.ontop` is documented at `@types/init.lua:334` as "override `config.window.ontop` for this one window", and `DEFAULTS.lua:306` sets `window.ontop = true`.

**Auswirkung.** `media.play_window(path, { ontop = false })` still passes `--ontop` to mpv, so the documented per-call override is inoperative in the one direction anybody would use it -- there is no way to get a non-floating player window except the global `window.ontop = false`. A consumer such as hover.nvim that asks for a window that must not float over everything gets one that does. One correction to the auditor: the `autofit` line above is NOT latent for the same reason -- `spec.autofit` is typed `string`, and every Lua string including `""` is truthy, so that chain cannot fall through. Only `ontop` is affected.

### `PRIN-20` — Keine stillen Fehler

`lua/media/hub/actions.lua:266` · `M.run_batch` · confidence **high**

**Befund.** `cancel()` calls `current.cancel` on the transcription handle in flight, but the batch's `on_done` is only ever reached from `step()`, which is only ever re-entered from that same handle's callback.

**Regelbezug.** Cancelling the dispatcher handle (`core/dispatcher.lua:192-213`) removes this batch's waiter from `job.waiters`; when it was the last one the job is cancelled and `fan_out` — the only thing that calls `w.done` — never runs. So the callback that would schedule the next `step()` is suppressed, and the `if cancelled then on_done(...)` branch at line 223-226 is unreachable. The docstring claims the opposite ("the handle stops the run after the item currently in flight").

**Auswirkung.** Cancelling a marked-set batch while an audio/video item is transcribing leaves `on_done` uncalled forever: the dashboard's summary never runs, so the sidecars/SRT files already written for earlier items are never reported, the accumulated per-file failure list is dropped, and `progress.finish` is never called on the lib.nvim handle (leaving the indicator up). Note the leak is not limited to the last-waiter case -- if another consumer has joined the same transcription key, `job.cancel` is correctly skipped, but this batch's waiter has still been removed from the list, so its callback is suppressed either way. OCR and PDF items are unaffected: `hub.run` returns nil for those, so cancel only sets the flag and the in-flight callback still drives `step()` to the cancelled branch.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/media/bindings/usrcmds.lua:53` · `M.resolve_path` · confidence **high**

**Befund.** The path argument a user types on the `:Media` command line is passed straight through `vim.fn.expand()` before anything else touches it.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user/buffer text: it is Vim's *filename* expansion, so a backtick span is a command substitution over `&shell` and `%`/`#`/`<cfile>` are specials. Only `~`/env expansion is wanted here, which is `lib.nvim.cross.fs.expand_path`.

**Auswirkung.** Every `:Media <verb> <path>` runs the typed argument through Vim's filename expansion. Two real consequences. (1) Buffer specials silently retarget: `:Media frame "#1 Intro.mp4"` renders buffer 1's file, `%`-prefixed arguments render the current buffer -- the wrong file, reported as success. (2) A backtick span executes through `&shell`; I confirmed the side effect (file created). One correction to the auditor: on Windows the substituted output cannot be read back, so `expand` then raises `E282: Cannot read from ...` -- the command still runs, but the user sees a raw Vim error rather than a silent success, which makes the injection noisier than described, not absent. The fix is `lib.nvim.cross.fs.expand_path`, which does `~`/env only.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/media/bindings/keymaps.lua:32` · `M.target` · confidence **high**

**Befund.** `vim.fn.expand("<cfile>")` is called unguarded and its result assumed to be a string; the function is documented `---@return string|nil`.

**Regelbezug.** SEC-34 names this exact failure mode: the cursor specials do not return `""` when there is nothing under the cursor, they throw. The rule's own Beleg (spotlight.nvim `cursor.token()`) is the same crash one plugin over.

**Auswirkung.** On an empty or whitespace-only line, `<leader>Mp`/`Mf`/`Ms`/`Mo` and any bare `:Media <verb>` with no path argument abort with a raw `E446: No file name under cursor` instead of the intended warning at usrcmds.lua:414 ("no file given, and none under the cursor"). `M.register_fallback` (usrcmds.lua:671) resolves the path before dispatching, so under the no-lib.nvim fallback even `:Media health` and `:Media cache clear` -- which need no path -- throw on such a line. Scope correction: `:Media cache clear` and `:Media health` are only affected on the fallback path, not under the lib.nvim composer, where each verb calls `require_path` itself.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/media/hub/scan.lua:97` · `M.root` · confidence **high**

**Befund.** The `path=<dir>` argument of `:Media dashboard` is run through `vim.fn.expand(arg)` before `fnamemodify(..., ":p")`.

**Regelbezug.** Same rule as above — a user-supplied directory string reaches Vim's filename expansion, where a backtick span is a shell command substitution and `%`/`#` are buffer specials.

**Auswirkung.** `:Media dashboard path=<arg>` runs the argument through Vim's filename expansion twice per open. A backtick span executes through `&shell`. A `#`/`#N` argument with no alternate buffer raises a raw `E194` out of the command. The auditor's headline claim -- that `path=#1` silently scans buffer 1's directory -- does NOT happen: the `isdirectory` check on line 98 rejects it with a clean "not a directory: #1". So the exposure here is command substitution plus uncaught Vim errors, not a silent wrong-directory scan.

### `ERR-03` — Explizite Rückgaben

`lua/media/output/init.lua:72` · `write` · confidence **medium**

**Befund.** `fd:write(content)` and `fd:close()` are called and their return values discarded; the function then unconditionally `return true, nil`.

**Regelbezug.** ERR-03/PRIN-20: the function's contract is `---@return boolean ok, string|nil err`, but the success value is formed from the work that was *attempted*, not from the work that succeeded. Lua's buffered `io` reports a full disk or a failing flush from `write`/`close`, which are exactly the two results thrown away here.

**Auswirkung.** Any write failure after a successful open -- full volume, quota, a disconnected network share, a flush error at close -- is reported as success. `:Media transcribe out=srt` (and out=vtt, out=sidecar, and the OCR/PDF `.ocr.md`/`.text.md` routes) tells the user `wrote <name>.srt` while the file on disk is empty or truncated, after a run that took minutes. The auditor's confidence rating of medium is right: the discard is certain from the code, but triggering it needs a genuinely failing volume, so this is a correctness/contract defect rather than an everyday break.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/media/hub/scan.lua:133` · `M.walk` · confidence **medium**

**Befund.** `uv.fs_scandir(dir)` returning nil is handled by `if handle then` — the directory is skipped and nothing records that it could not be read. `M.walk` has no error channel at all, and `M.scan` only ever returns an error for an unresolvable root.

**Regelbezug.** ERR-11: a function whose result can legitimately be empty must let "empty, but fine" be told apart from "empty because something broke". Here an unreadable directory and an empty one produce the identical `string[]`.

**Auswirkung.** A scan root that resolves but cannot be read -- a permission-denied share, a dropped NAS mount, a Windows junction that `isdirectory` accepts but `fs_scandir` refuses -- yields zero entries, and the dashboard states "no images, PDFs, audio or video under <root>" about a directory it never actually opened. A partially unreadable tree silently shows a short list with no indication anything was skipped. Note the `path` scope is partly protected by the `isdirectory` check at line 98 (a plainly nonexistent path errors cleanly); the gap is the readable-looking-but-unopenable directory, and the `cwd`/`cfile` scopes, which have no such check.

### `ERR-31` — `O_CREAT|O_EXCL` statt Check-dann-Erzeugen

`lua/media/core/cache.lua:247` · `M.ensure` · confidence **medium**

**Befund.** Existence is checked with `uv.fs_stat(out)` and, when absent, ffmpeg is told to write that exact path with `-y`. The join/queue that serialises writers is per-process state (`inflight`, `running`), while the cache directory is `stdpath("cache")/media.nvim` — shared by every Neovim of that user.

**Regelbezug.** ERR-31: naive check-then-create instead of an exclusive create (or the equivalent here, render to a unique temp path and rename into place). The module header asserts "Two `ffmpeg` processes writing the same file is a corrupt PNG, so the second caller waits on the first instead" — true within one Neovim, not across two.

**Auswirkung.** Two Neovim instances that request the same still concurrently both see no file and both run ffmpeg with `-y` on the same path. Because `settle` only tests existence, the interleaved result is accepted as a success and handed to callers. Since the cache key is content-derived (kind + path + mtime + args) and documented as safe to keep forever, that entry is never re-rendered, so one race can leave a permanently broken still for both instances and all future sessions until `:Media cache clear`. A reader in a second instance can also be served a half-written PNG through the line-247 fast path. Correctly rated medium: the mechanism is certain, but it needs two concurrent instances hitting the same key in the same window.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/media/health.lua:114` · `M.check` · confidence **medium**

**Befund.** `:checkhealth media` reports lib.nvim under the heading "media.nvim: optional integrations" via `check_optional`, which emits `h_info` (not even a warning) when it is missing — while `docs/installation.md:8` lists lib.nvim as **required** and `README.md` calls it "the one real dependency".

**Regelbezug.** LUA-01: the plugin must declare lib.nvim as hard (bare `require`, no fallback) or soft (`pcall` + local fallback) and hold that line, and a hard dependency must never be presented as optional. The code is unambiguously soft — `pcall(require, …)` with a working fallback at usrcmds.lua:432, keymaps.lua:77, ui.lua:125, cache.lua:52, bin.lua:88, play.lua:50, dashboard.lua:775 — so it is the documentation and the two statements that disagree, which is the same inconsistency the rule's fileops.nvim Beleg (`health.lua:71-75`) was raised for.

**Auswirkung.** The plugin gives two contradictory answers about its own dependency. `:checkhealth media` reports lib.nvim as an optional integration and stays green without it, while the README and installation docs call it required. Someone trusting checkhealth and removing lib.nvim gets a green report and a quietly degraded plugin (no `:Media` tab completion, no float dashboard -- a long `vim.notify` instead per dashboard.lua:776-780, no progress indicator, no cancel key for a minutes-long transcription); someone trusting the docs installs a dependency the code demonstrably does not need. Note the direction is the reverse of the rule's second sentence -- this is a soft dependency documented as hard, not a hard one documented as optional -- so the correct resolution is to align the docs with the soft implementation (or vice versa), not necessarily to raise the health level.

### `PRIN-20` — Keine stillen Fehler

`lua/media/core/dispatcher.lua:277` · `fan_out` · confidence **medium**

**Befund.** `local waiters = job.waiters` aliases the live list and then iterates it with `ipairs`, under a comment that says "Snapshot first" — while `fan_phase` fifteen lines above does make a real copy for exactly this reason.

**Regelbezug.** PRIN-20: a waiter's `done` callback can reach `join`'s `cancel`, which does `table.remove(job.waiters, i)` on the very list being iterated. Removing an element during `ipairs` shifts the tail left and the loop skips the next entry silently.

**Auswirkung.** When two callers have joined one transcription -- the documented case of `:Media transcribe` alongside a background hover.nvim request for the same file/engine/lang/task -- and the first caller's `done` callback cancels a handle, the second caller's `done` is silently skipped. That caller waits forever on a run that has already completed, with no error anywhere. Note `inflight[key]` is already cleared at line 273, so a later request for the same key does start a fresh run; the permanent hang is confined to the skipped waiter, not to the key. Fix is one line: copy the list as `fan_phase` already does.

### `PERF-46` — Cache-Key vollständig

`lua/media/core/bin.lua:76` · `M.find` · confidence **low**

**Befund.** The per-session lookup cache `resolved` is keyed by binary name only, although the answer also depends on `config.get().bin[name]`, which is read inside the same function; nothing in `media.config.setup()` or `media.setup()` calls `M.reset()`.

**Regelbezug.** PERF-46: the key has to carry every input that changes the result. Here the configured override is an input to the result and is absent from the key.

**Auswirkung.** Any `find()` that runs before or between `setup()` calls freezes the answer for the session. A consumer calling `media.available()` before media's own `setup()`, or a second `setup({ bin = { ffmpeg = "D:/tools/ffmpeg.exe" } })` after a reload, leaves the plugin on the previously resolved binary -- and the `false` sentinel is the worse case: a pre-setup lookup that found nothing makes `find` return nil forever, so a user who then configures an explicit `bin.ffmpeg` path still gets "ffmpeg not found". `M.reset()` would fix it but is only reachable via `VimResume`. Correctly rated low confidence on likelihood -- it needs a specific call ordering -- but the stale-key mechanism itself is certain from the code.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/media/core/dispatcher.lua:119` · `read_cached` · confidence **low**

**Befund.** A transcript read back from the on-disk JSON cache is accepted on `type(doc) == "table"` alone and handed to every waiter as a `Media.Transcript`; no field (`segments`, `text`, `engine`, per-segment `s`/`e`/`text`) is re-validated.

**Regelbezug.** SEC-33: a persisted snapshot is untrusted on load and every field has to be re-checked for type and shape. This entry survives across sessions and plugin versions, and the consumers assume the full shape.

**Auswirkung.** A cached transcript file that decodes to a table lacking a `segments` array reaches `to_text(nil)` and raises `bad argument #1 to 'ipairs'` out of a user command, on the buffer and sidecar output routes only (srt/vtt are guarded). Tempering the auditor: these files are written solely by the plugin itself (`write_file_async` at line 342) under a sha256-derived name, so the realistic trigger is a field-layout change between plugin versions or a file placed in the cache directory by something else -- not an everyday failure, and the low confidence rating is appropriate. The rule violation (no per-field re-validation of a snapshot that survives across sessions and versions) is nevertheless real, and the fix is cheap: validate `segments` is a table before returning.

> **Abdeckung dieses Laufs.** Coverage: I read essentially all of lua/ (39 files, 8058 lines) — every core/, hub/, output/, engines/, bindings/, config/ and integrations/ module in full; @types/init.lua only as far as needed to check the option contracts named in the findings. TESTS/ was surveyed (run.lua, harness.lua, targeted greps, hub_actions_spec) rather than read line by line, so the test suite is under-covered and produced no findings — none of the specs touch the filesystem outside `vim.fn.tempname()`, and the `/tmp/...` strings in the arg specs are opaque inputs to pure functions, not paths that get created.

Three behaviours were verified empirically against the installed Neovim 0.12.2 rather than argued from the code: (a) `vim.fn.expand(\"<cfile>\")` raises `E446` on an empty/whitespace line — checked by calling the plugin's own `media.bindings.keymaps.target()` and `usrcmds.resolve_path(nil)`; (b) `expand()` on a user string performs backtick command substitution and `#`/`%` buffer-special substitution (`expand(\"#1.mp4\")` → buffer 1's name, extension dropped); (c) `vim.system` raises `ENOENT` rather than returning an error when the command cannot be spawned. Nothing in the plugin was modified, staged or run beyond loading modules read-only in a headless `-u NONE` session.

Rules I could not properly check: **CMT-16** — `docs/map/` is generated by `:DocMap` and its `module_map.json` is stale (it reports 31 lua files / 4828 lines against the current 39 / 8058), but I have no way to tell from inside this repo whether `docs/BINDINGS.md` is generated or hand-written, or whether any generated file was hand-edited, so I report nothing there. **LUA-02** (fixes upward into lib.nvim) and **LUA-06**-adjacent cross-repo questions need lib.nvim itself, which is outside this plugin. **ERR-50** — there is no config validation of unknown keys at all (`config/init.lua:27` is a bare `vim.tbl_deep_extend` with no `KNOWN_OPTS` gate), which is an absence rather than a wrong ordering, so I did not force it into an ERR-50 finding; ERR-51/ERR-53/LUA-87 are all satisfied (the merge starts from `vim.deepcopy(DEFAULTS)`, nothing holds a module-level reference into the config tree, and no self-written config file exists). **PERF-93/PERF-92** have no surface: the plugin registers exactly one autocommand (`VimResume`) and computes no geometry at module level. **LUA-48** is clean — the one `__mode = \"k\"` (core/player.lua:59) is keyed by handle *tables*, which are collectible.

Additional context for two findings: the unguarded `vim.system` behind ERR-01 also appears at core/audio.lua:218, core/player.lua:190 and core/play.lua:72 with the same root cause (play.lua is the mildest — it verifies the binary with `executable.exists` first). Both audio.lua's and player.lua's module headers explicitly promise \"never raises\", which a misconfigured `bin.mpv` breaks. I folded these into the two anchor findings rather than filing five near-identical rows.

---

## ai.nvim

**13 Befunde** (5 × high). Roh gemeldet: 13.

### `ERR-03` — Explizite Rückgaben

`lua/ai/providers/claude.lua:267` · `M.stream / on_done` · confidence **high**

**Befund.** A mid-stream `decoded.type == "error"` event (line 255-265) calls `handlers.on_error` but records nothing; curl then exits 0, so this `on_done` runs its normal path and calls `handlers.on_done` with the text accumulated so far. The `recover_error_body` fallback cannot catch it either -- the error already arrived as a `data:` line, so `non_data_lines` holds only `event: error`, which is not valid JSON.

**Regelbezug.** ERR-03 requires a relevant function to signal success or failure, not both for one request. gemini.lua:274 carries exactly the `failed` flag this file lacks, with the comment "Set once an error is reported mid-stream so `on_done` below doesn't also fire with an empty-but-'successful' response afterwards" -- the invariant is stated in the repo and unmet here.

**Auswirkung.** on_error and on_done both fire for one request. Correcting the auditor on the panel claim: they are wrong that the panel finishes as a success. actions.lua's on_error calls `panel.finish(panel, "error")` first, and lib.nvim's progress handle guards on `done` (progress/init.lua:137-141), so the later finish from on_done is a no-op and the panel label stays "error". The real, confirmed damage is at the library contract, which is what ERR-03 is about: `Ai.StreamHandlers` (@types/init.lua:94) documents on_done as carrying the response, and any consumer implementing only on_done -- or treating it as "the answer is complete" -- silently records a truncated or empty answer as a finished one after an Anthropic overloaded_error/rate-limit event. The auditor's pdfport.nvim example is also wrong: providers/init.lua:137-139 says pdfport goes through ask(), not stream().

### `ERR-03` — Explizite Rückgaben

`lua/ai/providers/openai.lua:241` · `M.stream / on_done` · confidence **high**

**Befund.** Same shape as claude.lua: the `decoded.error` branch in `on_chunk` (lines 217-228) reports via `handlers.on_error` and returns, but sets no failure flag, so this `on_done` still calls `handlers.on_done` with the partial `text_parts` once curl exits 0.

**Regelbezug.** ERR-03: one request must not be reported as both failed and successful. gemini.lua:274/340 shows the intended guard; openai.lua has none.

**Auswirkung.** An OpenAI error object delivered as an SSE data event (quota exceeded, content filter) fires on_error and is then immediately followed by on_done carrying whatever text arrived first. Same correction as claude.lua: the panel keeps its "error" label because lib.nvim's progress `done` guard no-ops the second finish. The concrete consequence is the library API: a caller that only implements on_done (the handler @types/init.lua:94 documents as the response) accepts a half-answer as complete with no signal that anything failed.

### `ERR-03` — Explizite Rückgaben

`lua/ai/providers/ollama.lua:182` · `M.stream / on_done` · confidence **high**

**Befund.** The NDJSON `type(decoded.error) == "string"` branch (lines 163-170) fires `handlers.on_error` and returns without recording the failure; `on_done` then reports success with `table.concat(text_parts)`.

**Regelbezug.** ERR-03: the request's outcome must be one of success or failure. Ollama emits `{"error":"model 'x' not found"}` as a normal stream line and then closes the connection with exit 0, so both callbacks fire for the same request.

**Auswirkung.** Streaming against a model that is not pulled fires on_error and then on_done with an empty-but-successful response. The auditor's panel wording is wrong -- `ai.bindings.actions.stream_prompt`'s on_error finishes the panel as "error" first and lib.nvim's progress `done` guard makes the trailing finish a no-op, so the panel is not relabelled as a success. The real violation is that one request reports both outcomes across the public `Ai.StreamHandlers` contract: a library consumer keyed on on_done stores an empty string as the answer to a request that failed.

### `ERR-03` — Explizite Rückgaben

`lua/ai/providers/loomai.lua:166` · `M.stream / on_done` · confidence **high**

**Befund.** The `decoded.error ~= nil` branch (lines 149-157) reports the error and returns; nothing marks the stream as failed, so `on_done` still calls `handlers.on_done({ text = ... })` when curl exits 0.

**Regelbezug.** ERR-03, same as the three sibling backends: gemini.lua is the only one of the five that guards `on_done` behind a `failed` flag.

**Auswirkung.** A loomAI `data: {"error":{...}}` event produces an error callback followed by a success callback with empty text. Panel-level the auditor overstates it (progress's `done` guard keeps the "error" label). The accurate consequence: the documented stream contract is violated -- a caller that implements only on_done records the failed request as an empty answer, and every caller that implements both receives contradictory outcomes for one request with no ordering guarantee stated anywhere.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/ai/config/DEFAULTS.lua:64` · `DEFAULTS.completion.provider / .model` · confidence **high**

**Befund.** `provider = nil` and `model = nil` inside the `completion` table store no key at all in Lua, so `DEFAULTS.completion` has no `provider`/`model` key; `config/init.lua`'s pre-merge `warn_unknown_keys` tests exactly `defaults[key] == nil` and therefore reports both as unknown keys.

**Regelbezug.** ERR-50's whole point is that the pre-merge key check catches a typo in a nested option. Here the check fires on two options that are documented (`docs/configuration.md:52,75`), declared in the type (`lua/ai/@types/init.lua:47-48`), read at runtime (`lua/ai/completion/init.lua:84-85`) and actively recommended by the plugin's own health advice (`lua/ai/health.lua:134`) -- the validator calls the plugin's own documented configuration a typo.

**Auswirkung.** A user who follows docs/configuration.md:75 or :checkhealth's own advice and sets `completion = { provider = "ollama", model = "..." }` gets exactly ONE spurious warning on every startup: `unknown config key "completion.provider" -- check for a typo`. The value still merges and works. The second-order damage is the same either way: the pre-merge typo check cries wolf on the plugin's own documented option, training the user to ignore the one mechanism ERR-50 exists for. Note the mirror-image hole the auditor missed: because OPEN_SHAPE_KEYS matches by name and not by path, a real typo in any nested option named `model` can never be caught.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/ai/context/init.lua:98` · `add_scope / M.assemble` · confidence **medium**

**Befund.** `add_scope` swallows a failed `pcall(scope.resolve, ...)` exactly like a scope that legitimately resolved to nothing, and `M.assemble` returns `""` for both "nothing was requested/selected" and "every requested scope failed".

**Regelbezug.** ERR-11: a function whose result may legitimately be empty must let the caller tell "empty and fine" from "empty because something broke". The empty string carries no such distinction, and the only caller that branches on it guesses the benign cause.

**Auswirkung.** Confirmed, though narrower than stated and with the caller's line numbers wrong -- explain_badge's fallback is actions.lua:210-213, not 223-225. When lib.nvim's harvest.scope.resolve throws (API drift, a malformed range), explain_badge reports "Nothing to explain in the current context", pointing the user at their selection instead of the real fault; for ask/stream the context block silently vanishes from the prompt and the model answers without the buffer it was meant to see. Severity depends on resolve actually throwing, which is not demonstrated here -- the violation is the lost distinction, not an observed crash.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/ai/config/init.lua:66` · `M.setup` · confidence **medium**

**Befund.** `setup()` validates key *names* only. No option's value is ever type- or range-checked, and there is no degrade-to-default path: `vim.tbl_deep_extend` stores whatever the user wrote (`provider_order = "claude"`, `timeout_ms = "60s"`, `completion.trigger = "atuo"`).

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and to be made visible through `:checkhealth`. Here a wrong-typed value survives the merge intact and is first touched deep inside a request or inside health itself.

**Auswirkung.** `provider_order = "claude"` (a plausible single-provider typo) raises at health.lua:114. Neovim's health runner pcalls each plugin's check and reports the exception, so :checkhealth itself survives, but the ai.nvim report stops there -- the completion, optional-integrations and composer-preflight sections never render, i.e. the one surface ERR-22 designates for making the mistake visible is the surface it breaks. The same value raises inside providers.resolve on every :Ai ask/stream. `completion.trigger = "atuo"` is the quieter half: it survives the merge intact, silently means "never auto-trigger" (completion/init.lua:181), and health.lua:120 prints it back as an info line without flagging it as invalid.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/ai/completion/init.lua:131` · `M.accept` · confidence **medium**

**Befund.** `accept()` writes with `nvim_buf_set_text(bufnr, suggestion.row, suggestion.col, ...)` using coordinates captured when the suggestion was *rendered*. It checks `nvim_buf_is_valid` but never re-verifies the buffer's changedtick or that the line is still long enough, and the write itself is not guarded (the cursor move on line 142 is pcall'd, the write is not).

**Regelbezug.** ERR-30 requires an edit computed earlier to be re-verified against the current text immediately before writing, and skipped when it no longer matches. The changedtick captured in `trigger()` (line 75) is never carried into the shown suggestion, so `accept()` has nothing to compare against.

**Auswirkung.** In the normal insert-mode flow the dismiss autocmds keep the stale window very small, so this is not a routinely reachable bug on its own -- it needs a ghost that survived into Normal mode (the InsertLeave/generation hole above). Once that happens, Normal-mode edits (dd, u, :%d) leave the ghost in place and the next insert-mode <Tab> writes the suggestion at the stale (row, col): text inserted at the wrong position, or -- when the row/col no longer exists -- an unguarded 'out of range' API error surfacing as E5108 out of an expr mapping, which also swallows the <Tab> the user actually pressed.

### `ERR-33` — Fenster-/Buffer-Handles bei Ausführung erneut validieren

`lua/ai/completion/init.lua:100` · `M.trigger callback` · confidence **medium**

**Befund.** The stale-response guard revalidates `bufnr` and its changedtick, but reads the cursor with `vim.api.nvim_win_get_cursor(0)` -- the window that is current when the response lands, not the window the request was fired from (no window handle is captured at all). It also never checks that `bufnr` is still the current buffer, and `reset()` (the InsertLeave handler, lines 53-56) does not bump `generation`, so an in-flight request survives leaving insert mode.

**Regelbezug.** ERR-33/LUA-13 require a deferred callback to revalidate its window *and* buffer handles at execution time. Here the window is not revalidated but re-resolved, so the guard compares a position in one window against a position captured in another.

**Auswirkung.** Two paths, unequal in reachability. The InsertLeave one is the real one: trigger a completion with the cursor at column 0, type nothing, press Esc (column 0 is the one column Esc does not move away from) -- generation unchanged, buffer valid, changedtick unchanged, cursor unchanged, so the guard passes and ghost.show renders inline virtual text while the user is in Normal mode, where no autocmd clears it again (Normal-mode motion fires CursorMoved, not CursorMovedI). The cross-window path the auditor leads with is far narrower: it additionally requires the new window's cursor to sit at the exact same (row, col), and ghost.show's set_extmark is pcall'd (ghost.lua:55), so it degrades to an invisible extmark in a background buffer rather than a crash.

### `ERR-60` — `a and b or c` bricht, sobald `b` falsy sein kann

`lua/ai/providers/loomai.lua:102` · `M.ask / M.stream error message` · confidence **medium**

**Befund.** `local msg = type(data.error) == "table" and data.error.message or data.error` (and the identical line 151 in `M.stream`): the middle term `data.error.message` is falsy whenever the error object carries no `message` field, or carries JSON `null` there -- which `util.denil` has just converted to Lua `nil`.

**Regelbezug.** ERR-60 names exactly this: `a and b or c` falls through to `c` as soon as `b` is falsy, independent of `a`. Here the fall-through hands the whole error *table* to `tostring()`.

**Auswirkung.** A loomAI error body like `{"error":{"code":500}}` or `{"error":{"message":null}}` surfaces to the user as `loomai error: table: 0x...` -- the failure is reported but the message carries no information about what went wrong, in both the buffered ask() path and the streaming path. Non-fatal (the error kind and err.data are still correct), but the one string the user actually sees is useless.

### `LUA-93` — Jedes Plugin trägt seinen eigenen Lazy-Trigger

`docs/installation.md:10` · `lazy.nvim spec / keys` · confidence **medium**

**Befund.** The documented lazy spec's trigger is `keys = { "<leader>a" }`. A bare string entry in lazy.nvim's `keys` list defaults to mode `"n"`, so no Visual-mode key loads the plugin -- while five of the six default keymaps (`rewrite`, `append`, `prepend`, `quick`, `explain`, `ask`) register a Visual-mode bind in lua/ai/bindings/keymaps.lua.

**Regelbezug.** LUA-93 requires a plugin that should be lazy to carry a trigger that actually covers how it is used. This one covers half of its own keymap surface.

**Auswirkung.** A user installing from this snippet who selects a block and presses <leader>ar before ever running :Ai or a Normal-mode <leader>a* gets nothing at all -- the plugin is unloaded, so the Visual mapping does not exist and the key falls through to whatever <leader> normally does. Because any later Normal-mode use loads the plugin and makes the Visual binds appear, the feature looks intermittent rather than broken. Fix is a one-line doc change (`keys = { { "<leader>a", mode = { "n", "v" } } }`); the plugin code itself is fine.

### `PRIN-20` — Keine stillen Fehler

`lua/ai/bindings/keymaps.lua:59` · `M.setup / actions.ask (mode "v")` · confidence **medium**

**Befund.** The Visual-mode `ask` bind calls `actions.ask_prompt("")`, which calls `require("ai").ask({ prompt = text })` with no `context` field at all (lua/ai/bindings/actions.lua:33). `ai.context.assemble(nil)` returns "", so no selection is ever attached -- while the bind's own `desc` (line 61) and docs/BINDINGS.md:11 both say "about the selection".

**Regelbezug.** PRIN-20 forbids silent failure of a relevant function: the action advertises that it sends the selection, sends nothing, and reports neither an error nor a warning. The sibling Visual binds do it correctly (`quick`/`explain` pass `vim.tbl_extend("force", cfg.context, { selection = true })`, lines 80 and 161), which makes this an omission rather than a deliberate boundary.

**Auswirkung.** Selecting a function and pressing <leader>aa in Visual mode sends only the typed question -- the model answers about nothing, with no error, warning or any other signal that the selection was dropped, while which-key and BINDINGS.md both promise the selection was included. The failure is invisible precisely because the model still returns a confident-sounding answer.

### `ERR-03` — Explizite Rückgaben

`lua/ai/providers/transport.lua:81` · `write_body_file` · confidence **low**

**Befund.** `local written, write_err = uv.fs_write(fd, json, 0)` is checked with `if not written` only. `fs_write` returns the number of bytes written; a short write returns a positive number smaller than `#json` and passes this check.

**Regelbezug.** ERR-03: the function returns `path, nil` (success) for a write it has not verified completed. The file this path exists for is the multi-megabyte one (attachments, large cwd sweeps) -- the case where a partial write is least impossible.

**Auswirkung.** Genuine unchecked return value, but keep the auditor's own hedge: no short write was reproduced, and on a regular local file a partial uv.fs_write essentially requires ENOSPC or signal interruption. If one occurs, curl POSTs truncated JSON via --data-binary @file and the provider answers with a parse error naming neither the file nor the truncation, so the user sees what looks like an API fault on exactly the largest (attachment-carrying) requests. Low severity, cheap fix (`if not written or written < #json then`).

> **Abdeckung dieses Laufs.** COVERAGE: I read all 28 modules under lua/ (4333 LOC) in full, plus plugin/ai.lua and scripts/gen_map.lua. TESTS/ (3701 LOC) was NOT read in full -- only TESTS/minimal_init.lua, the harness half of TESTS/ai/panel_spec.lua, and targeted greps (pcall misuse, package.loaded handling). No test-code findings are reported; that is a coverage gap, not a clean bill for TESTS/. Nothing was executed against a real Neovim: the only thing I ran was an isolated Lua reproduction of warn_unknown_keys against the DEFAULTS shape, which confirmed finding #1.

WHAT I COULD NOT VERIFY FROM THIS REPO: several rules hinge on lib.nvim/ui.nvim internals rather than on ai.nvim's own code. I read the relevant parts there and found ai.nvim's reliance sound, so no finding is filed: PERF-80 (lib.nvim/net/curl/init.lua wraps its callbacks in vim.schedule centrally -- ai.nvim's own code contains no vim.schedule and does not need one); LUA-11/12 (ui.kit's Surface:set_lines guards nvim_buf_is_valid, so a chunk arriving after the panel closed is a no-op); ERR-02 for :Ai routes (composer's build_ctx always materializes ctx.range, and enum args are validated, not merely completed -- so usrcmds.lua's ctx.range.line1 and config.set_provider's trust in the enum are both justified); PERF-62/82 (completion's auto-trigger delegates its timer lifecycle to lib.nvim.debounce). If any of these upstream guarantees changes, the corresponding ai.nvim call sites become findings -- and per LUA-02 the fix would belong upstream anyway.

DELIBERATELY NOT REPORTED: (a) `executable_cache` in providers/util.lua never invalidates (PERF-42) -- documented as an intentional session-lifetime memo and exactly what XP-05 asks for; (b) `config.get()` returning the live table by reference (ERR-54) -- explicitly documented as a live reference, and no consumer mutates it (every caller copies via vim.tbl_extend); (c) gemini.lua's plain-JSON error recovery being documented as never live-verified -- a stated gap, not a rule violation; (d) killing a stream from the panel surfaces as `[error] curl exited …` in the panel, i.e. a user-initiated cancel reads as a failure -- a UX wart with no matching rule in the 76; (e) `attachments.from_file` not checking `uv.fs_read`'s returned byte count -- same class as finding #13 but on a path already capped at 32 MB, too speculative to file twice.

ONE STALE COMMENT worth a look while fixing: TESTS/minimal_init.lua:24-29 states that "none of the specs under TESTS/ai touch ai.ui.panel/ai.ui.badge/ai.bindings.actions", which is why ui.nvim is left off the rtp. TESTS/ai/panel_spec.lua does require ai.ui.panel (it stubs ui.kit via package.loaded, so the run still passes) -- the reasoning in the comment no longer matches the suite. No rule in the 76 covers it, hence no finding.

---

## github_stats.nvim

**13 Befunde** (7 × high). Roh gemeldet: 13.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/github_stats/bindings/usrcmds/show.lua:32` · `M.execute` · confidence **high**

**Befund.** `start_date`/`end_date` are taken verbatim from `parts[3]`/`parts[4]` and handed to `analytics.query_metric` (lines 41-46) with no validation. In analytics.aggregate_daily, `start_ts = start_date and parse_date(start_date)` yields nil for anything that is not `YYYY-MM-DD`, and the filter at lines 135-140 is guarded by `if start_ts and ...`, so a nil start_ts means no filtering at all. Meanwhile M.complete (line 156) and the route's `GH_DATE_OR_PRESET` type (usrcmds/init.lua:82-92) actively tab-complete preset names such as `this_month`, which parse_date cannot parse.

**Regelbezug.** ERR-10: "no argument" and "invalid argument" must not collapse onto the same nil. Here a typo (`2026-o1-01`) and a completion-suggested preset (`this_month`) both take the identical path as "user gave no date", so the argument acts on everything instead of raising an error -- the rule's literal description of the bug type.

**Auswirkung.** `:GithubStats show owner/repo clones this_month` -- and every other preset name the command's own <Tab> completion offers, including today and yesterday -- silently reports the full stored history instead of the requested window, because a value the completion suggested collapses onto the same nil as "no date given". The floating window's "Period:" line (show.lua:75) prints stats.period_start/period_end, which analytics.lua:335-339 derives from the dates that actually survived, i.e. the full span -- so the output is self-consistent and gives no hint that the filter was dropped. Identical behaviour for any mistyped ISO date.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/github_stats/retention.lua:55` · `load_archive` · confidence **high**

**Befund.** `load_archive` calls `require("lib.nvim.fs.json").read(path)` and discards the error half of its (data, err) return; both "_archive.json does not exist" and "_archive.json exists but does not decode" fall through to the same fresh empty skeleton returned at lines 59-62. `compact_metric` then rebuilds `archived_dates` from that empty table and, at line 115, writes the whole archive back over the file.

**Regelbezug.** ERR-11 requires "empty but fine" and "empty because broken" to be distinguishable; this is exactly the load-modify-save collapse the rule's Belege footnote calls the most common real bug class of the 32-repo sweep. Unlike this plugin's telemetry/report files, the archive is not a convenience artifact: it is the only remaining copy of every day older than `cutoff_days`, because compact_metric deletes the raw fetch files that produced it (line 136).

**Auswirkung.** One unreadable or wrong-shaped `_archive.json` (failed rename on Windows, full disk, a hand edit) is read as "no archive yet". compact_metric rebuilds the archive from only the days still present in raw fetch files and overwrites the damaged file at line 115, destroying the last chance of recovering it by hand -- and the rule's own prescribed mitigation (rename to .corrupt before the next save) is absent. compact_metric then returns err = nil at line 145, so `:GithubStats compact` and the fetcher's retention notification both report a clean success.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/github_stats/storage.lua:159` · `read_metric_history` · confidence **high**

**Befund.** `local parsed = json.read(filepath)` drops the error return, and line 160 silently skips any file whose decode failed. The function then returns `results, nil` at line 173 -- "here is the history, no error" -- whether it read every file or none of them.

**Regelbezug.** ERR-11: a function whose result can legitimately be empty must distinguish "empty, ok" from "empty, because something was unreadable". Every caller (analytics.query_metric line 313-316, retention.compact_metric, the dashboard render, statusline) branches on that nil error and therefore treats a partially-read directory as complete data.

**Auswirkung.** Every unreadable fetch file is dropped from the aggregation with no signal anywhere, so clone/view totals, daily breakdowns, sparklines, trend arrows, exports and diffs come out silently lower than the truth. Combined with retention: compact_metric archives from this short aggregation and then deletes every raw file with date <= cutoff (retention.lua:130-143) purely from the directory listing, without regard to whether it parsed. Note the statusline is not affected -- statusline.lua:96 wraps query_metric in pcall and degrades to an empty component.

### `LUA-01` — Hart oder weich, aber konsistent

`README.md:42` · `"Around it" section` · confidence **high**

**Befund.** README.md:38-44 lists ui.nvim among plugins that are "all soft: without them everything else works unchanged" and names only lib.nvim and curl as "the real dependencies", while lua/github_stats/dashboard/init.lua:12 does a bare `require("ui.contextmenu")` and lua/github_stats/init.lua:56 does `M.dashboard = require("github_stats.dashboard")` at module top level.

**Regelbezug.** LUA-01 requires a dependency to be hard or soft and held to consistently, and explicitly forbids presenting a hard dependency as optional in the docs. There is no pcall and no fallback anywhere on the ui.nvim path; docs/installation.md:8 and health.lua:274 both already state the opposite of what the README says ("also required, not optional -- require('github_stats') will fail to load").

**Auswirkung.** A user who installs on the strength of the README front page, without StefanBartl/ui.nvim, gets an uncaught error from the first `require("github_stats")` -- which is what setup() itself is -- because init.lua:56 pulls dashboard/init.lua and its bare `require("ui.contextmenu")` at module load. No user command, autocmd or background fetch is ever registered. The failure lands during plugin load, i.e. before :checkhealth github_stats can be run to deliver the error message health.lua:274 already has ready for exactly this case.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/github_stats/health.lua:46` · `check_config` · confidence **high**

**Befund.** `check_config()` (the first thing `M.check()` runs) calls `config.init()` with no arguments. config/init.lua re-resolves PATHS from `resolve_config_dir(nil)` (line 111-113), reloads config.json over DEFAULTS (line 125), and only re-applies setup options when `next(opts) ~= nil` (line 139) -- which is false here.

**Regelbezug.** LUA-87 fixes the order as "file or defaults as the base, setup() arguments win over it". config.init() honours that order only when it is handed the opts; a second, argument-less entry point re-runs the same initialisation and drops them, so the self-written config.json silently overrules setup() again -- the exact failure the rule's own Beleg records as fixed for this plugin.

**Auswirkung.** Running `:checkhealth github_stats` discards every setup() option for the rest of the session, reverting the module-level config to config.json-over-DEFAULTS. With `setup({ config_dir = ... })` or `{ data_dir = ... }` it is worse than a value reset: PATHS is re-pointed at stdpath('config')/lua/plugins/github-stats (creating a config.json there if none exists), so after the healthcheck the dashboard reads an empty store, fetches write to the default directory, and retention archives and os.removes there -- and the rest of the healthcheck reports on that wrong directory as though it were the configured one.

### `PERF-62` — Timer sauber stoppen

`lua/github_stats/dashboard/init.lua:43` · `M.schedule_render / cleanup_dashboard` · confidence **high**

**Befund.** `M.schedule_render` stops the existing debounce timer and nils the handle (lines 42-45) without ever calling `close()`, then allocates a brand-new `vim.uv.new_timer()` at line 57. The timer's own callback repeats the same stop-and-nil at lines 63-66, and `cleanup_dashboard()` does it once more at line 241.

**Regelbezug.** PERF-62 requires `timer:stop()` **plus** `pcall(timer.close)` before starting a new debounce timer, and explicitly forbids just dropping the handle. The plugin's two other timers do it correctly (background.lua:101-103 and dashboard/state.lua:56-57 both stop and close), so this is the one place that diverges.

**Auswirkung.** Each debounce cycle drops a stopped-but-open libuv timer handle on the event loop: the callback at 63-66 abandons its own handle every time a debounced render fires, and 41-45 abandons any still-live handle before 57 allocates a replacement. They accumulate for the session; cleanup_dashboard() leaks the last one too, so closing the dashboard does not release it. Only luv's GC finalizer eventually closes them, at a moment nothing in this code controls. The per-keypress count is lower than "dozens per scroll" -- 41-45 only leaks when a timer is still pending -- but the accumulation over a session is real and unbounded, and this is the one timer in the plugin that diverges from its two correct siblings.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/github_stats/export.lua:64` · `write_lines` · confidence **high**

**Befund.** `write_lines` runs `expand(filepath)` (`vim.fn.expand`, aliased line 13) on the output path, and `M.create_pdf` does the same at line 107. The path is raw user text: bindings/usrcmds/export.lua:64 takes it as `parts[3]` of the typed command line, and integrations/menu.lua:74-86 feeds it straight from a `vim.fn.input` prompt into the same execute(). bindings/usrcmds/export.lua:90 expands it a third time for the success message.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user/buffer text precisely because a backtick span in the argument is a command substitution through &shell, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. Only `~`/env expansion is wanted here, which is what `lib.nvim.cross.fs.expand_path` does -- and which the composer's own PATH argtype already applied, so this second, unsafe expansion adds nothing but the hazard.

**Auswirkung.** vim.fn.expand() runs a backtick span in the path through &shell before anything is written, and resolves Vim specials. One correction to the auditor's proof-of-concept: execute() splits args on `%s+`, so a backtick span containing spaces is torn apart -- the shell-execution case needs a whitespace-free span (e.g. `:GithubStats export owner/repo clones \`id\`.csv`), and the same constraint applies to the right-click "Export selected..." prompt, whose text is reassembled into the same string at menu.lua:85. Unaffected by that constraint: `:GithubStats export r clones %.csv` silently resolves `%` to the current buffer's name and can overwrite the file being edited, and a path containing `[`, `{` or `*` resolves to something other than what was typed.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/github_stats/bindings/usrcmds/chart.lua:38` · `M.execute` · confidence **medium**

**Befund.** `if arg3:match("last") or arg3:match("%d+d")` decides whether the third argument is a time range or a start date. Anything else -- including the preset names `this_week`/`this_month`/`this_quarter`/`this_year` that the route's `GH_DATE_OR_PRESET` completion offers -- falls into the `start_date` branch at line 42 and is then dropped by analytics.parse_date, which only accepts `YYYY-MM-DD`.

**Regelbezug.** Same ERR-10 collapse as in show.lua, with an extra inconsistency: `last_quarter` happens to match `"last"` and is routed through parse_time_range (which resolves presets correctly), while `this_quarter` does not and silently becomes "no filter". A user cannot tell which of two adjacent completion entries actually works.

**Auswirkung.** `:GithubStats chart owner/repo clones this_month` draws the sparkline over the entire stored history, and the "Period:" line from visualization reports that full span, so the chart looks internally consistent while answering a different question than the one asked. Because last_* presets happen to match the "last" substring and this_*/today/yesterday do not, two adjacent entries in the same completion list behave differently with nothing to tell them apart.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/github_stats/analytics.lua:572` · `get_top_referrers / get_top_paths` · confidence **medium**

**Befund.** `get_top_referrers` takes `latest.data` (line 569) and `table.sort`s it in place at line 572; `get_top_paths` does the same at lines 603-608. `latest` is a record handed out by `storage.read_metric_history`, whose own docstring (storage.lua:134-137) states that the list is copied but "the records themselves are shared ... Treat the records as read-only".

**Regelbezug.** ERR-54 allows a getter to hand out a live reference only when it documents that and every consumer honours it. storage.lua documents exactly that contract and these two consumers break it: they reorder the array inside the module-level `history_cache` entry, so the mutation outlives the call and is visible to every later reader of that repo/metric.

**Auswirkung.** Much smaller than claimed, and one part of the claim is simply wrong. `table.sort` sorts the entire array regardless of `limit` (the limit is applied afterwards, at 578-580 / 612-614), so a limit=3 call cannot change what a later limit=10 call sees -- that specific scenario does not occur. I grepped every consumer: the only callers of get_top_referrers/get_top_paths are bindings/usrcmds/referrers.lua:29 and paths.lua:30, and both go through these same two functions, which apply the identical count-descending sort. Nothing today depends on the GitHub API's original array order, so the observable damage is currently nil. What is real is a latent one: the cached record's array is permanently reordered for the session, so any future consumer added against the documented read-only contract (an export of raw referrers, a differently-sorted view) would silently get mutated state. This is a contract violation to fix on principle, not a user-visible bug.

### `PERF-92` — Keine Layout-Geometrie auf Modulebene

`lua/github_stats/dashboard/init.lua:136` · `create_dashboard_window` · confidence **medium**

**Befund.** The dashboard float's geometry is computed from `vim.o.columns`/`vim.o.lines` at open time (lines 136-141), which is correct, but nothing recomputes it afterwards: there is no `recompute()` and no `VimResized` autocmd anywhere in lua/ (the only occurrences of the string are the comment in bindings/autocmds.lua:7 and a hidden note in docs/BINDINGS.md:129-133 recording that the previous handler was deleted with dashboard/layout.lua and never replaced).

**Regelbezug.** PERF-92 requires not only that geometry be computed per open, but that every such surface carry a `recompute()` and a `VimResized` handler. The plugin's own documentation states the gap outright: "the dashboard currently does NOT re-render on terminal/window resize."

**Auswirkung.** With the dashboard open, a terminal or tmux-pane resize leaves the float at the width, height and centre offsets computed at open time: nothing recomputes them and nothing triggers a re-render. The float is no longer centred after any resize. Content is laid out against the config values dashboard.header_width (render.lua:46) and dashboard.sparkline_width (render.lua:367-372) rather than the live window width, so after a shrink it is clipped by the stale window instead of re-flowing. One correction: render_dashboard does read nvim_win_get_height(win) at render.lua:524, so scroll limits do catch up -- but only on the next render, which a resize never causes. Closing and reopening the dashboard is the only fix.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/github_stats/analytics.lua:71` · `deduplicate_by_date` · confidence **medium**

**Befund.** Records come from storage.read_metric_history, which validates only `type(parsed) == "table"` (storage.lua:160) before inserting a decoded file into the history. deduplicate_by_date then indexes `record.data` unguarded at line 71/74, calls `extract_date(item.timestamp)` at line 77 (a `:match` on whatever the file held), and compares `record.timestamp > by_date[date].timestamp` at line 80.

**Regelbezug.** SEC-33 treats persisted snapshots as untrusted and requires every field to be re-validated on load (type, length, count cap). Nothing between the JSON decoder and these accesses checks that `data` is a table, that `timestamp` is a string, or that the item array is bounded -- and lib.nvim's decoder turns JSON `null` into a sentinel value rather than Lua nil, so a null field survives the `if items then` guard and reaches the `:match`.

**Auswirkung.** A .json file in a metric directory that decodes to a table but lacks a conforming data/timestamp shape raises an uncaught Lua error. The first crash is usually earlier than the auditor's line: storage.lua:167's `table.sort(results, function(a, b) return a.timestamp < b.timestamp end)` fails with "attempt to compare nil with string" before analytics is reached. Either way, the dashboard render, :GithubStats show, summary, chart and export all fail for that repository until the file is found and deleted by hand. One correction: the statusline is NOT affected -- statusline.lua:91-99 wraps both the require and query_metric in pcall and returns nil, so the component just goes empty. The missing count cap is also real: no limit on the stored array, so an oversized one is aggregated in full on every render.

### `SEC-42` — Pfad-/Dateiname-Komponenten sanitizen

`lua/github_stats/storage.lua:22` · `sanitize_repo_name` · confidence **medium**

**Befund.** The only sanitisation applied to a repository identifier before it becomes a directory name is `repo:gsub("/", "_")`; the result is joined into the storage root at line 41 and used for every read, write and delete, including retention's `os.remove` path at storage.lua:224.

**Regelbezug.** SEC-42 requires user-controlled path components to be stripped of escape/control sequences and then whitelisted, and states that a blacklist alone is not enough. This is a one-character blacklist: backslashes, `..` segments, control characters, leading `~` and drive-letter prefixes all pass through untouched. The identifiers are user-controlled (`repos` in config.json / setup()) and partly remote-controlled (`full_name` from the GitHub API via `watch_users`), and health.lua's `^[^/]+/[^/]+$` check only runs during :checkhealth, never on the write path.

**Auswirkung.** Weaker than framed as an attack, but real as a robustness hole: the "attacker" here is whoever writes the repos list, i.e. the user, and GitHub's own full_name is in practice constrained to a safe charset, so the remote vector is theoretical. What does bite is Windows path semantics -- a repos entry containing a backslash (`owner\repo` as a typo, or `owner\..\..\x`) is not sanitized, so vim.fs.joinpath produces a nested or escaping path, fetches write outside the configured data directory, and retention's os.remove operates there too (limited to files matching list_metric_files' `^YYYY-MM-DDT....json$` pattern inside whatever directory was computed). The benign case is the likelier one: the same entry resolves to a different storage location on Windows than on Linux, so history silently splits across two directories.

### `ERR-03` — Explizite Rückgaben

`lua/github_stats/fetcher.lua:114` · `M.fetch_all` · confidence **low**

**Befund.** `M.fetch_all(force, callback, opts)` documents an optional completion callback but returns without invoking it on two exit paths: `#repos == 0` (line 114) and the interval-not-elapsed gate (line 125). Its two callers that do pass a callback -- dashboard/init.lua:350 and dashboard/actions.lua:164, the latter reached from the right-click menu's force_refresh wrapper -- are left waiting forever.

**Regelbezug.** ERR-03/PRIN-20: a relevant function must report success or failure rather than ending silently. A completion callback that is simply dropped is the callback-shaped version of a silent failure -- the caller cannot distinguish "still running" from "decided not to run".

**Auswirkung.** Narrower than stated. Both named callers pass force = true, so the interval gate at line 120 (`if not force and not should_fetch()`) is unreachable from them -- only the `#repos == 0` path at 114 strands them. When it does: dashboard/actions.refresh_all's on_done never fires, so the right-click menu's force_refresh wrapper (integrations/menu.lua:57-64) leaves its "Refreshing..." notification standing with no re-render and no warning, and the same for dashboard/init.lua's open(force_refresh = true) path. Reaching it needs the repo list to empty out after the dashboard was opened, since M.open guards the list at open time -- so this is a correctness/contract fix, not a bug users are hitting today.

> **Abdeckung dieses Laufs.** COVERAGE: I read all of lua/github_stats/ except roughly 250 lines of export.lua's markdown/CSV line builders and ~160 lines of diff.lua's formatting half, plus the tail completion functions of referrers.lua/paths.lua/compact.lua/dashboard.lua -- those I skimmed for the grep patterns only. TESTS/ (24 spec files) was surveyed by targeted grep (tempname/env/timer/pcall/require-path patterns), not read line by line, so there are no test-code findings here; that is a coverage gap, not a clean bill. .claude/, .git/, .deps/ and doc/tags were excluded as instructed; docs/map/index.html is a generated DocMap artifact and was excluded from greps after it swamped one search.

RULES I COULD NOT MEANINGFULLY CHECK: ERR-33/LUA-13 (deferred-handle revalidation) came out clean rather than unchecked -- every scheduled callback I found either re-reads state through ui_state.get_buf_win(), which validates both handles (ui_state.lua:78-84), or re-queries dashboard_state. ERR-50 (validation before merge) has no surface: the plugin does no unknown-key/did-you-mean validation at all, before or after the merge, which is arguably its own gap but not the ordering violation ERR-50 describes. ERR-51/ERR-53: config/init.lua:100 merges with `vim.tbl_deep_extend("force", DEFAULT_CONFIG, parsed)` rather than into a fresh `{}`, so untouched sub-tables of the loaded config are the same objects as DEFAULT_CONFIG's; the rule text names `tbl_deep_extend("force", ...)` as acceptable and I found no consumer that mutates one, so I did not report it -- but it is one in-place sort away from being a real bug. SEC-11/SEC-15 are clean: the token is read from the environment, never persisted, and health.lua reports only its length and source; api.lua passes it via lib.nvim.net.curl's stdin `-K -` path, never argv. ERR-31: ensure_config_exists (config/init.lua:67-90) is a check-then-create rather than O_CREAT|O_EXCL, but both racers would write byte-identical defaults through an atomic rename, so the impact does not clear the bar for a finding.

TWO REAL DEFECTS I FOUND THAT NO RULE IN THE 76 COVERS, noted so they are not lost: (1) bindings/keymaps.lua:205-213 calls `actions.refresh_all()` and `actions.force_refresh_selected()` without the `on_done` argument both functions exist to take, so pressing `R` or `f` notifies "Refreshing..." and then never re-renders when the fetch lands -- while integrations/menu.lua:57-64 passes on_done correctly, contradicting that file's own claim that right-click "never offers anything the keyboard doesn't already provide". (2) dashboard/render.lua:242-247 hardcodes a 72-column box border while lines 244-246 fill the interior to `header_content_width()`, so any `dashboard.header_width` other than the default 72 produces a header box whose borders no longer line up with its content.

BELEGE ALREADY CLOSED FOR THIS PLUGIN, re-verified as still fixed and therefore not re-reported: ERR-54 on config.get_repos() (now returns vim.list_slice, config/init.lua:188), LUA-87's original form (setup() now wins over config.json, config/init.lua:139-141), SEC-21 (api_timeout_ms + --max-filesize wired through api.lua:57-64), XP-04 (health.lua:137 now uses argv `vim.fn.system({...})`), SEC-01/03/10 in health.lua (check_api_sync goes through lib.nvim.net.curl with bearer_token via stdin), PERF-81/82 (background.lua's idempotent start with deferred first cycle).

---

## gopath.nvim

**13 Befunde** (5 × high, 1 davon in Testcode). Roh gemeldet: 13.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/gopath/resolvers/lua/local_to_module.lua:15` · `M.enhance_lsp_result` · confidence **high**

**Befund.** `vim.fn.readfile(lsp_result.path)` ohne pcall auf einem Pfad, der direkt aus der LSP-Antwort stammt (`providers/lsp.lua:49` `vim.uri_to_fname(uri)` → `symbol_locator.lua:32` → hier). Die Folgezeile `if not lines or #lines == 0` zeigt, dass ein Rückgabewert erwartet wurde -- `readfile` wirft stattdessen E484.

**Regelbezug.** ERR-01 verlangt pcall an Systemgrenzen (Dateisystem, Fremd-API). Beides trifft hier zu, und zwei Schwesterstellen im selben Plugin machen es richtig (`go/import_path.lua:30`, `javascript/import_path.lua:79`), drei weitere nicht (`symbol_locator.lua:230`, `table_locator.lua:702`, `value_origin.lua:49`).

**Auswirkung.** When the definition URI does not name a readable file (unsaved buffer, a non-file URI scheme, a file deleted since the server indexed it), readfile throws E484 out of enhance_lsp_result, up through symbol_locator, and is caught by resolve.lua's safe.call at line 114. The already-correct `base_result` built at symbol_locator.lua:29-37 is discarded with it, so the LSP phase returns nothing even though the server had answered, and resolution silently drops to the weaker treesitter/builtin phases.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/gopath/config/init.lua:63` · `M.setup` · confidence **high**

**Befund.** `M.setup` mergt `opts` ohne jede Typ- oder Wertprüfung in den State; `deep_merge_into` (Zeile 41-56) schreibt für jeden Nicht-Tabellen-Wert bedingungslos `dst[k] = v`. Ein ungültiger Einzelwert degradiert nirgends auf seinen Default, und `health.lua`s `check_config` (Zeilen 241-280 des Files) druckt den Wert nur per `vim.inspect` aus, ohne ihn zu bewerten.

**Regelbezug.** ERR-22 verlangt, dass ein ungültiger Config-Einzelwert auf seinen Default zurückfällt und das über `:checkhealth` sichtbar wird. Hier passiert weder das eine noch das andere -- der falsche Wert wandert roh bis an die Verwendungsstelle.

**Auswirkung.** `setup({ order = "lsp" })` makes every gP/g|/g\/g} throw "bad argument #1 to 'ipairs' (table expected, got string)" at resolve.lua:113 — the error escapes resolve_at_cursor, and commands.resolve_and_open (commands.lua:68) calls it without a pcall, so it reaches the keymap. `setup({ languages = false })` throws "attempt to index a boolean value" at resolve.lua:92 the same way. Neither value degrades to its default, and `:checkhealth gopath` reports both as ordinary info lines, so the report actively suggests the config is fine.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/gopath/resolvers/common/tailsearch.lua:422` · `M.probe / finish` · confidence **high**

**Befund.** Der Multi-Match-Picker ruft `require("ui.kit").select({...})` nackt auf, ohne pcall und ohne den überall sonst vorhandenen `vim.ui.select`-Fallback.

**Regelbezug.** ui.nvim ist in docs/installation.md:30 ausdrücklich als optional deklariert ('falling back to vim.ui.select when absent'), im Modulkopf derselben Datei (Zeile 10 und 369) und in commands.lua:245 ebenfalls. Die drei Schwester-Aufrufstellen halten sich daran (alternate/ui.lua:52, external/pdf.lua:97, create.lua:147 -- alle `pcall(require, "ui.kit")` + `vim.ui.select`-Fallback). Hier ist die weiche Abhängigkeit real hart: LUA-01 verbietet genau das ('Eine harte Abhängigkeit darf in der Doku nie als optional dargestellt werden').

**Auswirkung.** Without ui.nvim, any probe that yields more than one match raises "module 'ui.kit' not found". Two distinct paths: from the cache fast path `finish(cached, 0.85)` the error propagates synchronously out of M.probe into the :Gopath probe / <leader>pp command (uncaught — commands.probe_selection does not pcall), and from the live branch it is thrown inside finder.find_async's callback, where nothing catches it and on_done never fires, so the command dies silently apart from the Lua error. Either way the documented vim.ui.select dialog never appears.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/gopath/create.lua:65` · `touch` · confidence **high**

**Befund.** Der Zweig, der laut Warnung in Zeile 36-39 der 'built-in mkdir+open fallback for file creation' für ein fehlendes lib.nvim ist, ruft selbst `require("lib.nvim.fs.write.to_file")` auf.

**Regelbezug.** Der Fallback für 'lib.nvim fehlt' benutzt lib.nvim. Es gibt also gar keinen eingebauten Pfad -- die Abhängigkeit ist hart, wird dem Nutzer aber als 'optional dependency' mit funktionierendem Ersatz gemeldet. Genau die von LUA-01 verbotene Mischform.

**Auswirkung.** The auditor's scenario is overstated: if lib.nvim is genuinely absent, `require("gopath").setup()` already dies at bindings/keymaps.lua:15, so nobody ever reaches the create dialog. The branch is actually reachable on a lib.nvim old enough to lack `fs.create_entry` but still carrying `fs.write.to_file`, where it works fine — and on one lacking both, where `touch()` throws "module 'lib.nvim.fs.write.to_file' not found" out of the ui.select callback, so "Create file" aborts with a raw Lua error. The concrete, always-true defect is the user-visible warning itself: it tells the user lib.nvim is optional and that a built-in fallback is in use, when neither is true.

### `PERF-46` — Cache-Key vollständig

`lua/gopath/truncated/cache.lua:63` · `config.cache_file / M.load_from_disk` · confidence **high**

**Befund.** Der persistierte Dateiindex liegt unter genau einem Pfad (`stdpath('cache')/gopath_fs_cache.json`) für alle Projekte, obwohl `config.scan_roots` `vim.fn.getcwd()` und den Git-Root enthält (Zeilen 127-133). `_save_to_disk` schreibt `scan_roots` und `version` mit (Zeilen 295-300), `load_from_disk` (309-337) validiert nur `paths` und `last_built` und ignoriert beide Felder.

**Regelbezug.** Der Cache-Key muss jeden Parameter enthalten, der das Ergebnis beeinflusst -- hier sind das die Scan-Roots (cwd/Git-Root). Ein Index, der in Projekt A gebaut wurde, wird in Projekt B unverändert übernommen, weil nichts vergleicht, wofür er gebaut wurde.

**Auswirkung.** The stale-index window is narrower than claimed but real. At startup in project B, load_from_disk installs project A's path list and `needs_refresh(max_cache_age)` (3600 s) returns false, so no rebuild is scheduled; the periodic timer (cache_refresh_interval, default 600 s) only fires after one full interval, so A's file list is live for up to ~10 minutes, and for the full hour if `truncated.use_cache = false`. During that window `tailsearch.resolve_cached` can return an A-project path; because filetoken consults it only after &path and rtp searches miss (filetoken.lua:165-178), the damage is on tokens that do not resolve inside B — instead of a create-on-missing offer, gP opens the same-named file in the other project, with `pick_best` (tailsearch.lua:166-174) picking the shortest path among them. Independently of the window, the single unkeyed file means every project's build overwrites every other's on disk. The unread `version = 1` is dead: a future format change cannot be detected on read.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/gopath/env_shorten.lua:141` · `M.shorten_current_line` · confidence **medium**

**Befund.** `vim.api.nvim_buf_set_lines(0, row - 1, row, false, { result })` ohne pcall und ohne Prüfung auf `vim.bo.modifiable`.

**Regelbezug.** Ein Schreibzugriff auf einen Buffer ist eine Systemgrenze im Sinne von ERR-01; der Aufruf wirft bei `nomodifiable`/`readonly`, und hier ist kein Hotpath-Argument dagegen (die Funktion läuft genau einmal pro Kommando).

**Auswirkung.** Running :GopathToReposDir / :Gopath to-repos-dir in a non-modifiable buffer — a help window, a `view`-opened file, quickfix — aborts with the raw API error ("E21: Cannot make changes, 'modifiable' is off" surfaced as a Lua error from the command callback) instead of the LOG.warn the neighbouring failure path uses. Nothing is corrupted; the cost is an unhandled error message where a one-line warning belongs. The auditor's "E5108 … Buffer is not modifiable" is the wrong error text.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/gopath/config/init.lua:64` · `M.setup / deep_merge_into` · confidence **medium**

**Befund.** Es gibt keine Validierung unbekannter Keys -- weder vor noch nach dem Merge. `deep_merge_into` legt jeden unbekannten Schlüssel stillschweigend im State an.

**Regelbezug.** ERR-50 verlangt die Prüfung auf unbekannte Keys ('meintest du …') VOR dem Merge, damit ein Tippfehler in einer verschachtelten Option nicht im Default verschwindet. gopath hat weder ein KNOWN_OPTS-Äquivalent noch eine Warnung.

**Auswirkung.** A typo is accepted in silence at every nesting level: `setup({ truncted = { enable = false } })` creates a `truncted` branch nobody reads while `truncated` keeps its defaults, and `setup({ mappings = { open_vspit = "gv" } })` registers no keymap for the intended action. Nothing warns at setup time, and `:checkhealth gopath`'s check_config only prints named fields it knows about, so the misspelling appears nowhere — the user sees a plugin that ignores their configuration with no diagnosable cause.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/gopath/truncated/cache.lua:492` · `M.add_root` · confidence **medium**

**Befund.** `table.insert(config.scan_roots, dir)` mutiert eine Tabelle, die in `M.setup` Zeile 104 per Referenz übernommen wurde (`config.scan_roots = opts.roots`) -- und `opts.roots` ist `config.get().truncated.cache_roots`, durchgereicht von `init.lua:31`.

**Regelbezug.** `config.get()` dokumentiert sich in `config/init.lua:67` als 'read-only reference'. ERR-54 erlaubt die Live-Referenz nur, wenn jeder Konsument sich daran hält. Hier hält sich einer nicht daran und schreibt in die zentrale Optionstabelle.

**Auswirkung.** With `truncated.cache_roots` set, `:Gopath cache add-root <dir>` permanently appends to the user's own options table for the rest of the session: every later reader of `config.get().truncated.cache_roots` — including `:checkhealth gopath`'s truncated section — sees a value the user never wrote, with nothing recording that the plugin mutated it. With cache_roots left at its default the getter is not aliased and there is no leak. The secondary point holds independently: bindings/usrcmds.lua:88 documents cache_add_root as "Add a directory to the filesystem cache roots and persist it", but nothing persists the roots — _save_to_disk writes scan_roots and load_from_disk ignores the field, so the added root is gone on restart.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/gopath/resolve.lua:119` · `M.resolve_at_cursor` · confidence **medium**

**Befund.** `local ok, result = safe.call(...)` in Zeile 114, ausgewertet in Zeile 119 als `if ok and result then`. Im Fehlerfall wird `result` (der Traceback) ersatzlos verworfen -- kein LOG.error, nicht einmal LOG.debug.

**Regelbezug.** `util/safe.lua:5-11` beschreibt den einzigen Zweck des Moduls als 'Wraps xpcall with debug.traceback so that errors arriving from deep resolver chains include a full stack trace … prefer safe.call over a bare pcall when the error message matters'. Der einzige Aufrufer wirft genau diesen Traceback weg. Damit ist die Absicherung das, was den Bruch unsichtbar hält -- der Kern von LLS-31 ('die Funktion tut still nichts').

**Auswirkung.** Any throw inside a language resolver — the unguarded readfile above, a vim.NIL field, a changed third-party signature — is indistinguishable from "no match": resolve_at_cursor moves to the next provider and eventually returns the filetoken fallback or the raw <cfile>. No log line is written at any level, so `dev_mode = true` does not help either, and the only symptom is that gP lands on a weaker guess. A resolver can stay broken indefinitely without anyone having a signal that it ever ran.

### `LUA-02` — Fixes nach oben, nicht in die Kopie

`lua/gopath/resolvers/common/tailsearch.lua:64` · `git_root` · confidence **medium**

**Befund.** `git_root` spawnt `git -C <dir> rev-parse --show-toplevel` über `vim.system(...):wait()` -- synchron, auf dem Main Loop, ohne Timeout. `M.guess_roots` (Zeile 106) ruft es bis zu zweimal pro Aufruf, und `M.probe` (Zeile 387) ruft `guess_roots` bei jedem Probe.

**Regelbezug.** Genau dieser Aufruf wurde in `truncated/cache.lua:111-124` bereits durch `lib.nvim.fs.find_root`s Marker-Walk ersetzt, mit ausgeschriebener Begründung im Kommentar ('synchronous subprocess spawn on the main loop … expensive on Windows (AV scan on every spawn)'). Der Fix liegt in lib.nvim, diese zweite Kopie zieht ihn nicht nach -- LUA-02s 'sonst lebt der Bug in allen anderen Kopien weiter'.

**Auswirkung.** Every <leader>pp / :Gopath probe with default config blocks the UI for the duration of up to two synchronous git spawns before the search even starts — process-spawn cost, noticeably worse on Windows, though I cannot verify the auditor's 20-100 ms figure from the code. The verifiable hazard is the missing timeout: `proc:wait()` with no argument and no `opts.timeout` waits indefinitely, so a git that stalls (network drive, lock contention) freezes Neovim with no way out, where the lib.nvim replacement used one file over is a pure directory walk with no subprocess at all.

### `LUA-16` — `vim.NIL` sanitizen

`lua/gopath/providers/lsp.lua:48` · `M.definition_at_cursor` · confidence **medium**

**Befund.** `if uri and rng then` als einzige Prüfung auf zwei Feldern, die direkt aus der dekodierten LSP-JSON-Antwort kommen (Zeilen 45-46).

**Regelbezug.** JSON-`null` dekodiert in Neovim zu `vim.NIL` (Userdata) -- und `vim.NIL` ist in Lua truthy. Der Guard lässt genau den Fall durch, gegen den er schützen soll. LUA-16 verlangt `if v == vim.NIL or type(v) ~= "..." then`.

**Auswirkung.** Narrower than the auditor implies, because Location.uri and Location.range are non-nullable in the LSP spec — this needs a server that violates it. When one does, the guard admits vim.NIL and the next line throws (bad argument to uri_to_fname, or an index on userdata) from inside the `for` loop, so the whole definition_at_cursor call dies rather than skipping the bad location; resolve.lua:119 swallows it, and the good locations later in the same response are lost with it. The fix the rule asks for (`if v == vim.NIL or type(v) ~= "..."`) would degrade to skipping just that entry.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/gopath/config/init.lua:58` · `state / M.setup` · confidence **medium**

**Befund.** `local state = vim.deepcopy(defaults)` wird einmal beim Laden gebildet; `M.setup` mergt jedes Mal in genau diese, bereits akkumulierte Tabelle statt in eine frische DEFAULTS-Kopie (Kommentar Zeile 61: 'Calling setup() more than once re-merges on top of the previous state').

**Regelbezug.** Das ist der in LUA-87 namentlich geführte Gegenfall (reposcope: 'setup() merged in die aktuelle Optionstabelle statt in eine DEFAULTS-Kopie -- akkumuliert, ein zweites setup({}) setzt nichts zurück'). Der Standard-Merge-Mechanismus der Regel lautet `vim.tbl_deep_extend("force", {}, defaults, user or {})`, also Defaults als Basis bei jedem Aufruf.

**Auswirkung.** Two of the auditor's three triggers do not survive checking: `:Lazy reload` clears package.loaded, so gopath.config is re-required and line 58 rebuilds state from DEFAULTS — the accumulation is reset. What remains is real but narrow: two setup() calls within one module lifetime (two specs for the same plugin, or a manual re-setup) never reset, so `setup({ truncated = { enable = false } })` followed by `setup({})` leaves truncated disabled. Worth noting for whoever fixes it: a naive switch to `vim.tbl_deep_extend("force", {}, defaults, user)` would replace the state table and decouple every consumer already holding a sub-table reference (cache.setup takes `tcfg.cache_roots` by reference) — ERR-53 requires the reset to happen in-place.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`scripts/ci/unit_tests.lua:38` · `spec discovery` · confidence **medium** · _Testcode_

**Befund.** `vim.fn.globpath(spec_dir, "*.lua", false, true)` mit `spec_dir = vim.fn.getcwd() .. "/scripts/ci/specs"` -- ein roher Pfad als Glob-Pattern. Identisch in `scripts/ci/headless_tests.lua:41` für `TESTS/`.

**Regelbezug.** XP-01: `globpath` interpretiert `~`, `[`, `?`, `*`, `{}` im Verzeichnisargument. Unter Windows trifft das insbesondere die 8.3-Kurzform (`C:/Users/STEFAN~1/…`), die glob als Home-Referenz aufzulösen versucht und dann eine leere Liste ohne Fehler liefert. Für 'liste die Dateien in diesem Verzeichnis' ist `lib.nvim.fs.globbable` bzw. `vim.fs.dir` der Griff.

**Auswirkung.** CI tooling only — no runtime user impact, and no failure on the current checkout path (E:/repos/gopath.nvim contains no metacharacters). The latent failure is a silent empty list when the checkout sits under a path containing ~, [, ?, *, {} — or a comma, which globpath reads as a directory separator and which would make it search two nonexistent directories. Discovery then reports "[FAIL] no specs found under scripts/ci/specs/" (unit_tests.lua:41-45) or "no fixtures found under TESTS/" (headless_tests.lua:44-47), blaming the suite for what is a path-quoting problem.

> **Abdeckung dieses Laufs.** Gelesen wurden rund 7.200 der 10.493 Lua-Zeilen unter lua/ (77 Dateien) plus die CI-Runner. Vollständig gelesen: init, config/*, commands, resolve, registry (Kopf), open/*, create, truncated/*, resolvers/common/* (help, filetoken, linepath, env_path, tailsearch, extractor-Kopf), env_shorten, util/* (path, log, safe, safe_notify, cross), providers/*, external/*, alternate/*, bindings/*, health, alias_index, binding_index, ts_lua_ast.

Nur teilweise oder gar nicht gelesen -- dort kann ich keine Aussage treffen: die neun Sprach-Resolver (resolvers/c|csharp|go|java|javascript|python|rust|zig/*), resolvers/lua/{chain, identifier_locator, require_path, symbol_locator, table_locator, value_origin} über die readfile-Stellen und die via_lsp-Kette hinaus (table_locator allein ist >700 Zeilen), resolvers/common/url.lua ab Zeile 100, resolvers/common/{lang_helper, extractor/terminators, extractor/common_extensions}, external/helpers/detector.lua, util/location.lua, bindings/keymaps.lua Zeilen 1-79 und bindings/usrcmds.lua ab Zeile 140, health.lua ab Zeile 420. Die Test-Specs unter scripts/ci/specs/ (18 Dateien) habe ich nur stichprobenartig angesehen (config_spec, tailsearch_spec, harness, die beiden Runner).

Geprüft und sauber -- ausdrücklich keine Funde: LUA-48 (die beiden `__mode`-Stellen sind laut Beleg gefixt, der Code bestätigt es: `cache = {}` plus BufDelete/BufWipeout-Autocmd in alias_index.lua und binding_index.lua), ERR-52/`deep_merge_into` (der `order = {\"treesitter\"}`-Fund aus dem Beleg ist mit is_list-Sonderbehandlung und ausgeschriebener Begründung behoben), PERF-72 (Scan-Roots sind cwd/stdpath/Git-Root, kein Laufwerk, kein Home), PERF-07 (kein `next(t)`-Löschloop), PERF-80 (alle libuv-Callbacks hoppen vor dem ersten vim.api-Zugriff per vim.schedule; cache.lua:277 und finder.lua:197 dokumentieren es), PERF-82 (`start_periodic_refresh` stoppt+schließt den alten Timer, erster Lauf um ein volles Intervall verzögert), PERF-92 (kein Float, keine Layout-Geometrie irgendwo), SEC-01/03 (jeder Subprozess wird als argv-Liste an `vim.system` übergeben, nirgends ein Shell-String; opener.lua begründet die explorer.exe-Wahl sogar gegen `cmd /c start`), SEC-34 (`vim.fn.expand` wird ausschließlich auf statischen Specials `<cfile>`/`<cword>`/`%:p:h` aufgerufen, nie auf Buffer-Text; env_path.lua umgeht expand bewusst), SEC-35 (die beiden zusammengebauten `vim.cmd`-Strings in open/help.lua:16,62 bekommen ihr Subject ausschließlich aus resolvers/common/help.lua, das über `^vim%.api%.([%w_]+)$`-Muster auf `[%w_]+` einschränkt -- kein `|` erreichbar), XP-06 (Specs werden per dofile über absolute Pfade geladen, kein case-sensitiver require).

Nicht bewertbar mangels Zugriff: ob `lib.nvim.fs.json.read` beim Lesen zwischen 'Datei fehlt' und 'Datei kaputt' unterscheidet (relevant für ERR-11 an `truncated/cache.lua:309-318`, wo `load_from_disk` für beide Fälle `false` zurückgibt). Ich habe es nicht als Fund aufgenommen: der Dateiindex ist ein reines Wegwerf-Artefakt, und der Beleg zu ERR-11 nimmt bewusst verlusttolerante Convenience-Artefakte ausdrücklich aus. Erwähnenswert bleibt, dass eine korrupte Datei nie nach `.corrupt` gesichert oder gelöscht wird und `health.lua` sie als 'Cache is empty' meldet.

Zwei Beobachtungen ohne passende Regel im 76er-Katalog, deshalb nicht als Fund geführt: (1) `truncated/finder.lua`s synchroner Zweig `M.find`/`search_root`/`detect_tool` (Zeilen 14-113) ist toter Code -- nichts im Plugin ruft ihn, nur `find_async` läuft; `health.lua:60-81` warnt trotzdem, ohne fd/rg seien 'suffix search and live-search fallback unavailable', was für den libuv-Walk nicht stimmt. (2) `alias_index.lua:34` und `binding_index.lua:39` holen jede Zeile mit einem eigenen `nvim_buf_get_lines(buf, i-1, i, false)` statt in einem Aufruf -- bei einer 10k-Zeilen-Datei 10.000 API-Calls pro Rebuild (changedtick-gecacht, also einmal pro Edit).

---

## lsp.nvim

**13 Befunde** (8 × high). Roh gemeldet: 13.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/lsp/completion/usage.lua:56` · `load / M.bump` · confidence **high**

**Befund.** `load()` does `local decoded = json.read(STATE_FILE); local fresh = type(decoded) == "table" and decoded or {}` and `M.bump()` repeats the same collapse at line 98 — the second return value of `lib.nvim.fs.json.read`, which distinguishes "read failed" from "invalid JSON", is discarded at both call sites. `M.bump` then writes the whole table back with `json.write(STATE_FILE, current)` at line 104.

**Regelbezug.** ERR-11 requires "empty but fine" (file absent) to be distinguishable from "empty because broken" (file corrupt). Here both produce the same `{}`, and because this is a load-modify-save cycle whose save rewrites the entire file, the indistinguishable state is immediately overwritten — the exact load-modify-save collapse ERR-11's Belege names as the most common real bug class of the 32-repo sweep. The information is available: `lib/nvim/fs/json/init.lua:30-37` returns `(nil, "read failed: …")` for a missing file and the decoder's own error for malformed JSON.

**Auswirkung.** A truncated or hand-edited `lsp_completion_usage.json` under `stdpath("state")` decodes to nil, is silently treated as an empty history, and is then overwritten with the whole in-memory table — either by the legacy migration inside `load()` (line 66) or by the first `M.bump` (line 104). No `.corrupt` backup is taken and nothing is reported, so the file's remaining content is destroyed before the user has any chance to notice the history was not merely empty. Within the session `M.count` keeps working off the rebuilt table; the loss shows up only as completion ranking having quietly reset.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/lsp/tools/ts_type_lookup/cmds.lua:265` · `M.find_in_node_modules` · confidence **high**

**Befund.** After `fn.systemlist(cmd)`, the code branches `if vim.v.shell_error ~= 0 or vim.tbl_isempty(result) then notify.info("No results for '" .. symbol .. "' in node_modules") end` — a non-zero ripgrep exit and an empty-but-successful search produce the identical message.

**Regelbezug.** ERR-11 requires "nothing to report" and "failed while determining" to be distinguishable. ripgrep exits 1 for "no matches" but 2 for an actual failure (regex parse error, unreadable directory, argument error), and this collapses all three onto the same informational notice.

**Auswirkung.** A ripgrep run that fails outright — for example a regex parse error from a `<cword>` containing `[` or `(`, or a missing/broken rg invocation — is reported to the user as "No results for '<symbol>' in node_modules", indistinguishable from a successful search that found nothing. The user concludes the symbol is not vendored and stops, rather than fixing the query. The auditor's permissions example is weaker than stated: rg normally warns on unreadable paths and still exits 0 or 1, so the realistic exit-2 cases are malformed patterns and argument/IO errors.

### `ERR-31` — `O_CREAT|O_EXCL` statt Check-dann-Erzeugen

`lua/lsp/languages/webdev/astro/usercmds.lua:31` · `scaffold` · confidence **high**

**Befund.** `scaffold(path, template)` calls `vim.fn.writefile(template, path)` with no existence check of any kind. It backs both `:AstroNewComponent` (line 105) and `:AstroNewPage` (line 142), whose paths are built as `"src/components/" .. name .. ".astro"` / `"src/pages/" .. name` from the command argument or the `ui.kit` prompt.

**Regelbezug.** ERR-31 governs file creation with "only create when not present" semantics: it must use exclusive creation and treat EEXIST as success, rather than clobber. A command named `New…` has exactly those semantics, and this one does not even perform the naive check the rule already considers insufficient — it truncates unconditionally.

**Auswirkung.** Running `:AstroNewComponent Button` a second time replaces an existing `src/components/Button.astro` with the nine-line stub, and `:AstroNewPage about` does the same under `src/pages/`. No prompt, no backup, no warning — the `pcall` only catches a write that fails outright, and a successful clobber is indistinguishable from a successful create. Line 36 then `:edit`s the path, so the user is shown the stub as if it were the new file. Recovery requires VCS.

### `ERR-31` — `O_CREAT|O_EXCL` statt Check-dann-Erzeugen

`lua/lsp/languages/webdev/astro/keymaps.lua:161` · `astro <leader>ax extract-to-component` · confidence **high**

**Befund.** The visual-mode "Extract to component" mapping builds `component_path = "src/components/" .. name .. ".astro"` from the prompt answer and calls `pcall(vim.fn.writefile, content, component_path)` with no existence check, then replaces the selection with `<Name />` and reports "Created component:".

**Regelbezug.** Same rule as the `scaffold` finding: a create-new operation that unconditionally truncates whatever is already at the target path. The surrounding comments show the site was audited for other problems (empty selections, mkdir, range shifting) but never for the pre-existing-file case.

**Auswirkung.** Extracting a visual selection under a component name that already exists truncates that component's file and writes the extracted snippet over it, then replaces the selection in the source buffer with `<Name />` and reports "Created component: src/components/X.astro". The clobbered file's content is gone from disk with no backup while the message claims a creation; recovery requires VCS. The source buffer is left referencing a component whose body is now the wrong code.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/lsp/servers/lua_ls/reload.lua:163` · `:LuaLsSetProfile` · confidence **high**

**Befund.** `:LuaLsSetProfile` sets `vim.env.LUA_LS_PROFILE = profile`, calls `M.reload_library()` and reports `"Switched to profile: %s - Reloading..."`. But `M.reload_library()` rebuilds through `lsp.servers.lua_ls.build_library`, whose entry point takes only `root` and hardcodes `max_results = 200, max_depth = 15, include_files = true` (build_library.lua:33-37). The only reader of `LUA_LS_PROFILE` is `library_profiles.get_active_profile()`, reachable only from `library_profiles.build_library`, which `lsp/servers/lua_ls/init.lua:191-195` documents as dead code. The argument is also never validated against the completion list, and `get_active_profile()` silently falls back to "normal" for an unknown name.

**Regelbezug.** LLS-31 covers the case where a function forms its report out of the work it intended rather than the work it performed — "ein echter, still bleibender Laufzeit-Bug", not diagnostics hygiene. The command reports a profile switch that provably cannot happen, and the plugin's own `servers/lua_ls/README.md:464` and `init.lua:71` already state that `LUA_LS_PROFILE` has no effect.

**Auswirkung.** `:LuaLsSetProfile minimal` sets an environment variable that nothing on the reload path reads, runs the same unprofiled 200-result/depth-15 `find_type_dirs` walk as before, and then tells the user "Switched to profile: minimal - Reloading...". On a large tree the scan the command exists to narrow is unchanged, and the confirmation message is the reason the user stops investigating. A typo such as `:LuaLsSetProfile ful` is accepted without validation and echoed back verbatim, so even the inert env var does not hold a value any reader would recognise.

### `LUA-16` — `vim.NIL` sanitizen

`lua/lsp/core/filter.lua:57` · `M.dedup` · confidence **high**

**Befund.** dedup() builds its dedup key from a raw `textDocument/publishDiagnostics` payload using `(d.severity or 0)`, `(d.source or "")` and `(d.message or ""):gsub(...)`, then `table.concat`s the five values — but a JSON `null` in any of those optional fields decodes to `vim.NIL`, which is userdata and therefore truthy, so the `or`-fallback never fires.

**Regelbezug.** LUA-16 requires every field coming from external JSON/LSP/RPC data to be checked against `vim.NIL` before use, because `vim.NIL` is userdata, not Lua nil — exactly the `or`-idiom this function relies on is the one that fails. The module docstring (lines 39-44) states it is given raw publishDiagnostics payloads, so this is the external-data path, not an internal one.

**Auswirkung.** Any language server that sends `"severity": null`, `"source": null` or `"message": null` in a publishDiagnostics item makes `dedup` throw on every push. It is not an uncaught crash: nvim dispatches notifications through `rpc.lua`'s `Client:try_call(NOTIFICATION_HANDLER_ERROR, ...)` (rpc.lua:481-487), so the error is pcall'd and surfaced as an LSP client error. The consequence is still that the whole push is dropped before `orig()` ever runs, so that server's diagnostics never render and the buffer keeps whatever stale set it had, with a recurring NOTIFICATION_HANDLER_ERROR as the only clue. `severity` and `source` are optional fields in the LSP spec, so a null there is a legal-ish payload, not only a broken server.

### `SEC-30` — Nutzereingabe literal escapen

`lua/lsp/tools/ts_type_lookup/cmds.lua:263` · `M.find_in_node_modules` · confidence **high**

**Befund.** `local cmd = { "rg", "--no-ignore", "-n", "--hidden", "-S", symbol, node_dir }` passes `symbol` to ripgrep as a regular expression with no literal escaping and no `-F`/`--fixed-strings`. `symbol` is user input: either `:TypeDefFindInNodeModules <arg>` (line 353) or `fn.expand("<cword>")`.

**Regelbezug.** SEC-30 requires a pattern built from user input to be literal-escaped before reaching the regex engine, precisely to prevent false matches and pathological backtracking. Nothing here escapes; the argv form protects against shell injection (SEC-03) but not against regex interpretation.

**Auswirkung.** A cursor word or argument containing regex metacharacters is reinterpreted as a pattern rather than matched literally: `Foo.Bar` also matches `FooXBar`, so the first hit rg returns — which is the one this function opens in a vsplit — can be a different symbol's file presented as the type's home. A pattern rg refuses to compile (`a[`, an unbalanced group) exits 2 and is reported as "No results" because of the collapse on line 265. The backtracking concern is real but secondary: rg's default engine is finite-automaton based and only falls back to PCRE2 on `-P`, which is not passed here — the practical cost of a pathological pattern is the synchronous `fn.systemlist` blocking the UI for the whole node_modules walk.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/lsp/languages/documentation/markdown_words/init.lua:347` · `M.set_root` · confidence **high**

**Befund.** `M.set_root(path)` passes its argument straight through `vim.fn.expand(root)`. The argument reaches it from `:MdSetRoot <args>` (line 494-496: `local path = cmd_opts.args ~= "" and cmd_opts.args or nil; M.set_root(path)`), and again from `M.rebuild()` (line 372), which re-expands the already-expanded stored root.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user/buffer text: a backtick span in the argument is a command substitution over `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. The rule names `lib.nvim.cross.fs.expand_path` as the replacement when only `~` and environment variables are wanted, which is all this call needs.

**Auswirkung.** `:MdSetRoot` runs its argument through Vim's filename expansion, so a backtick span is a command substitution over `&shell` (confirmed: the shell branch is taken on this machine, failing with E282 only because &shell is PowerShell and the temp-file redirect does not match). `usercmd.create` pcall-wraps the callback, so the user sees a notification rather than a crash — but the shell has already run. The non-malicious breakage is narrower than claimed: only a root whose string BEGINS with `%`, `#` or `<` is rewritten (`#tmp` expands to the empty string, after which the `gsub` leaves `""` and the scan walks the wrong tree), and glob metacharacters `*`, `?`, `[`, `{}` are expanded anywhere in the path. A `#` or `%` in the middle of a directory name is NOT affected.

### `ERR-03` — Explizite Rückgaben

`lua/lsp/completion/usage.lua:104` · `M.bump` · confidence **medium**

**Befund.** `json.write(STATE_FILE, current)` is called for its side effect only; `lib.nvim.fs.json.write` returns `(ok, err)` — "encode failed", "write failed" or "rename failed" — and both call sites here (lines 66 and 104) discard both values. `M.bump` is annotated `@return nil` and reports nothing to the caller either.

**Regelbezug.** ERR-03 requires relevant functions to return success/failure rather than fail silently, and the information is right there at the boundary. This is not a best-effort path by design: the module docstring promises "a write per pick is free — and it means a crash never costs the history" and claims the behaviour was measured landing on disk.

**Auswirkung.** When the state directory is read-only or full, or the `.tmp`→target rename loses a race with another Neovim instance holding the file, every pick is dropped with no return value, no notification and no health signal. The auditor's "the counter reads 0 forever" is wrong for the running session: line 103 assigns `counts = current` before the write, so in-session ranking keeps working and the user sees normal behaviour. The failure only becomes visible after a restart, when the history is back to whatever last landed on disk — which is exactly the symptom hardest to trace back to a broken write weeks earlier.

### `LUA-11` — Gültigkeit prüfen

`lua/lsp/tools/lsp_signature/open_floating_preview.lua:67` · `open_floating_preview` · confidence **medium**

**Befund.** `local bufnr = api.nvim_create_buf(false, true)` is used without checking the result, and lines 70-90 immediately call `nvim_buf_set_name`, `nvim_buf_set_lines`, `nvim_set_option_value("modifiable", false)`, `nvim_set_option_value("bufhidden", "wipe")` and `nvim_buf_clear_namespace` on it, followed by `nvim_open_win(bufnr, …)` at line 114.

**Regelbezug.** LUA-11/LUA-12 require a validity check before every `nvim_buf_*` call. `nvim_create_buf` signals failure by returning 0, and 0 is not an invalid handle in the Neovim API — it is the alias for the *current* buffer, so an unchecked failure silently retargets every following call. The plugin's own `lspdoctor/probe.lua:161-163` guards the identical call with `if probe_buf == 0 then return nil, "could not create a buffer" end`, so this is an inconsistency inside one codebase rather than a missing convention.

**Auswirkung.** A defensive-rule breach whose failure mode needs `nvim_create_buf` to actually return 0 (allocation/handle exhaustion), which is rare — the auditor's own 'medium' confidence is right. Should it happen, nothing downgrades the popup to a no-op: `bufnr = 0` retargets the whole sequence at the buffer the user is editing, so its lines are replaced with the signature text, `modifiable` is set to false and `bufhidden` to `wipe`, its extmark namespaces are cleared, and it is opened in a floating window — armed to be wiped on hide. The concrete, present-tense defect is the unguarded handle and the inconsistency with probe.lua, not a bug users are hitting today.

### `LUA-16` — `vim.NIL` sanitizen

`lua/lsp/tools/lsp_signature/format_signature_help.lua:81` · `format_signature_help` · confidence **medium**

**Befund.** `if sig.parameters and active_param then local param = sig.parameters[active_param + 1]` treats `sig.parameters` as a truthiness test. `parameters` is an optional field of `SignatureInformation`, so a server may send it as JSON `null`, which decodes to `vim.NIL` — truthy userdata — and the next line indexes it.

**Regelbezug.** LUA-16 requires each field from external LSP data to be checked for `vim.NIL` before use rather than relying on a nil test; the rest of this file uses `type(...) == "number"`/`"string"` guards for exactly the sibling fields (`activeParameter`, `documentation`), so this one line is the gap.

**Auswirkung.** A server answering signatureHelp with `"parameters": null` plus a numeric `activeParameter` makes the formatter raise "attempt to index a userdata value". It is caught, not fatal: nvim invokes the response callback through `Client:try_call(SERVER_RESULT_CALLBACK_ERROR, ...)` (rpc.lua:468-475), so the error is logged and surfaced as an LSP client error. The user-visible effect is that the signature popup silently never appears for that server — and because the error names only the Lua line, nothing points at the server payload as the cause. Note the same file has the identical exposure one step earlier at line 37 (`#sigs` on a `vim.NIL` `result.signatures`), so a fix should cover both.

### `LUA-93` — Jedes Plugin trägt seinen eigenen Lazy-Trigger

`lua/lsp/pack/core.lua:27` · `conform.nvim pack spec` · confidence **medium**

**Befund.** The `stevearc/conform.nvim` spec carries only `enabled = pack.enabled(...)` — no `ft`/`cmd`/`event`/`keys`, and no explicit `lazy = false` with a reason. Its actual load trigger is `require("conform")` from `lsp.formatter.conform.setup()` (conform.lua:135) and `lsp.formatter.build()` (formatter/init.lua:33), both of which `lsp.init`'s bootstrap runs during `require("lsp").setup()`. Every neighbouring spec in the pack does declare one (`lazydev` → `ft = "lua"`, `workspace-diagnostics` → `event = "LspAttach"`, `trouble` → `cmd`, `lspsaga`/`lensline` → `event`, `inc-rename` → `cmd`, `blink` → `event`).

**Regelbezug.** LUA-93 states the trigger belongs in every spec that should be lazy, and that being `require`d by another module is an accident rather than a trigger — naming `lsp.integrations.blink` pulling blink into every startup as the case. The spec's module docstring explains at length why there is no `config` block but is silent on why there is no trigger, so neither a reader nor the plugin manager can tell whether the eagerness is intended.

**Auswirkung.** The spec states no loading intent, so what happens depends on the host's lazy.nvim `defaults.lazy`: with the stock default (false) conform is loaded at startup by lazy.nvim itself regardless of the require; under a host that sets `defaults.lazy = true`, `lsp.setup()`'s two `require("conform")` calls become the accidental trigger and pull it into every startup anyway — the `lsp.integrations.blink` case the rule names. Either way conform is fully `setup()`-ed in sessions that never format. The concrete trap is the one the auditor identified: adding conform's documented `event = "BufWritePre", cmd = "ConformInfo"` would make the spec read lazy while the bootstrap require keeps loading it eagerly, and nothing in the file would contradict the reader.

### `PRIN-10` — Keine globalen States

`lua/lsp/init.lua:331` · `vim.g._formatter_api` · confidence **medium**

**Befund.** `vim.g._formatter_api = formatter` publishes the table of five closures returned by `lsp.formatter.build()` (formatter/init.lua:234-240) into the global Vim namespace, and `lsp.bindings.actions.formatter()` (actions.lua:39-53) reads it back, accepting anything for which `type(...) == "table"` holds and calling `.toggle()`/`.format()`/`.is_enabled()` on it. The key is not namespaced under `vim.g.lsp_nvim`, which the plugin does use for `config/pack.lua`.

**Regelbezug.** PRIN-10 requires state to live inside its module and be reached through a getter/setter; LUA-17 adds that `vim.g` is not a transport for Lua objects between a plugin's own modules — the module should be `require`d directly. The code acknowledges it ("A global because the keymaps are registered by the host today; it goes away with roadmap phase 3") without that changing what it is today.

**Auswirkung.** The formatter's live API is published under an unprefixed, undocumented global that any config or plugin in the session can read or overwrite. A collision — someone else writing `vim.g._formatter_api` — passes `actions.lua`'s `type(...) == "table"` guard and then makes `M.format_toggle`/`M.format_buffer` raise "attempt to call a nil value" from inside a keymap callback with nothing pointing back at the collision. That is a latent risk rather than a bug users hit today. The present, verifiable consequence is structural: the module has no getter, `vim.g` hands back a fresh converted copy on every read, and metatables do not survive the round-trip (verified on 0.12.2), so `build()` can never grow a metatable-backed or non-serialisable member without breaking at the first call site.

> **Abdeckung dieses Laufs.** Scope: read ~6,200 of the 24,821 lua/ lines plus spot checks in TESTS/ and scripts/. .claude/, .git/, .deps/ and doc/tags were excluded as instructed; docs/map/ was also excluded once `git check-ignore` confirmed it is generated and gitignored (so CMT-16 has no committed generated artefact to hand-edit — and .github/workflows/ci.yml does run `gen_bindings.lua --check` as a drift gate).

This plugin has clearly been through several earlier sweeps. config/init.lua, config/project.lua, config/DEFAULTS.lua, core/handlers.lua, core/lightbulb.lua, core/diagnostics.lua, core/workspace_diagnostics.lua, core/supervisor.lua, usercmds/stop.lua, usercmds/start.lua and integrations/blink.lua are conspicuously clean against the rules they touch — I checked each against its family and found nothing. Where a rule family had already been swept, the remaining violations clustered in the older, less-worked corners: tools/lsp_signature, tools/ts_type_lookup, languages/webdev/astro and servers/lua_ls.

Confirmed clean rather than untested, with the evidence I used:
- LUA-06: DEFAULTS.lua contains no `require`, no env lookup, no filesystem access — pure data.
- ERR-51/ERR-53: every merge in config/init.lua goes through `vim.deepcopy(DEFAULTS)`; core/diagnostics.lua `apply()` deep-copies `user_opts` before stripping keys, so the live config is never mutated.
- PERF-80: verified the one library boundary that matters — `lib.nvim.cross.uv.spawn_capture` wraps `on_done` in `vim.schedule`, and supervisor's `on_exit`, handlers' timer and stop.lua's poll all schedule before touching the API.
- PERF-93: the only `CursorMoved` handlers (core/lightbulb.lua:501, integrations/lspsaga.lua:185) both go through a debounce.
- PERF-46: `core/workspace_diagnostics.lua`'s cache key is root + sorted extension set, NUL-separated.
- PERF-07: no `next(t); t[k] = nil` delete loop anywhere. LUA-48: no `__mode` anywhere. XP-01: no `glob`/`globpath` anywhere.
- ERR-62: every `pcall` in lua/ uses either `pcall(f, args)` or `pcall(function() ... end)`; no `pcall(f(args))`.
- SEC-03/SEC-35: all subprocess calls use argv form (`vim.system`, `spawn_capture`, `fn.systemlist` with a list); every `vim.cmd(...)` string is either a literal or built from the plugin's own keymap catalogue, and the one path-carrying case escapes with `fn.fnameescape`.
- LUA-92: integrations/blink.lua reads `package.loaded["blink.cmp"]` and mirrors the capability constant, with a drift spec.

Could not cover / caveats:
- I did not read health.lua (~700 lines), lspdoctor/ beyond probe.lua, diagnostics/, bindings/keymaps.lua, bindings/which_key.lua, core/workspace_folders.lua, core/root_scope*.lua, or most of servers/ end to end — only the parts a grep for a named rule pattern led me into. ERR-30 (re-verify a match before writing) and ERR-20/PRIN-27 (fail-open on an optional signal) in particular have no confirmed surface I located, but I cannot claim I looked everywhere for them.
- TESTS/ (15,446 lines) got only targeted checks: XP-06 require-path casing (clean — minimal_init.lua resolves deps through env vars and normalizes them) and the `pcall(f(args))` shape (clean). No test-code findings; that is a statement about what I checked, not a full audit of the suite.
- Two things I looked at and decided against reporting, so they are not silent omissions: (a) `lua/lsp/tools/lsp_signature/show_hover.lua:122` `M.clear_cache()` replaces the LRU reference instead of clearing in place, which is the letter of PERF-47 — but the cache is a module-local upvalue that nothing outside holds, so I could not name anything that actually breaks; (b) `core/workspace_diagnostics.lua`'s `files_cache` has no invalidation, which brushes PERF-42 — but the module explicitly documents session lifetime as the intended contract, so it is a design choice, not a missing definition.
- I verified three claims empirically against nvim 0.12.2 rather than reasoning about them: the `vim.NIL` / `or`-fallback behaviour (confirms the filter.lua finding), `vim.fn.expand` backtick command substitution (confirms the markdown_words finding), and the `vim.g` function round-trip (which *disconfirmed* a LUA-17 reading of `vim.g._formatter_api`, so that finding is filed under PRIN-10 at reduced severity). One claim I could not reproduce: the E348 behaviour of `vim.fn.expand(\"<cword>\")` on blank lines that bindings/actions.lua:318-323 documents as measured — on this 0.12.2 it returned `\"\"` in both a scratch and a real file buffer. I therefore did not file findings against the four unguarded `expand(\"<cword>\")` sites (astro/usercmds.lua:178, ts_type_lookup/cmds.lua:152 and :253, ts_type_lookup/symbol_picker.lua:52, plus the two keymap RHS strings in noice_integration.lua:41,48), even though they are inconsistent with the two sites that do guard it. Worth a second look on a machine where that measurement reproduces.

---

## open.nvim

**13 Befunde** (8 × high). Roh gemeldet: 13.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/open/init.lua:84` · `M.setup` · confidence **high**

**Befund.** `for _, key in ipairs(cfg.handlers)` iterates a config value with no type check. The same holds for `cfg.custom_handlers` (init.lua:99), `office_open.extensions` (office_open.lua:29) and `cfg.command` (passed straight to `composer.verb`). There is no config validation anywhere in the plugin.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default rather than abort the whole initialisation, and to be visible in `:checkhealth`. Here one wrong-typed value takes down all of `setup()`.

**Auswirkung.** One wrong-typed config value aborts the whole of `setup()` with a raw Lua traceback and the plugin's `:Open` is never registered — verified for all four values. One correction that makes this worse, not better: `:Open` does not simply vanish. Neovim's own netrw ships a built-in `:Open`, so after a failed setup `:Open <file>` silently runs netrw's `vim.ui.open` shim instead of the plugin's command, with different semantics and no error. `:checkhealth open` cannot explain it: there is no validation to report and `check_handlers()` only says the registry is empty. Abort points differ — `handlers`/`custom_handlers` abort before anything is registered, `office_open` and `command` abort after handlers (and, for `command`, after the office autocmd) are already in place, leaving a genuinely partial state.

### `ERR-51` — Merges kopieren Defaults tief

`lua/open/config/init.lua:39` · `M.setup` · confidence **high**

**Befund.** `current = vim.tbl_deep_extend("force", defaults, opts_rest)` — `defaults` is the module-level table returned by `require("open.config.DEFAULTS")`, and `tbl_deep_extend` copies a sub-table by reference whenever the later argument has no counterpart for that key. Line 10 does use `vim.deepcopy`, but line 39 overwrites that copy on every `setup()`.

**Regelbezug.** ERR-51 requires the merge to deep-copy the defaults rather than share them. Verified in nvim: after `setup({})`, `config.get().viewer == DEFAULTS.viewer`, `config.get().office_open == DEFAULTS.office_open` and `config.get().filemanager == DEFAULTS.filemanager` are all `true`.

**Auswirkung.** Any write through `config.get()` permanently rewrites the plugin's module-level DEFAULTS table for the rest of the session, and a later bare `setup({})` — which is supposed to restore defaults — returns the mutated value. Verified end to end for `viewer.sort`. Correction to the auditor: the suggested fix is wrong. `vim.tbl_deep_extend("force", {}, defaults, opts_rest)` still shares the sub-tables — verified — because `tbl_deep_extend` only recurses where both sides have a table, and assigns by reference otherwise. The working fix is to base the merge on a copy, e.g. `vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts_rest)`.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/open/picker.lua:22` · `M.select` · confidence **high**

**Befund.** `require("ui.kit").select({...})` is a bare require on ui.nvim (a separate repo: `/e/repos/ui.nvim/lua/ui/kit/`), with no pcall and no fallback. `integrations/menu.lua:22` does the same at module level with `require("ui.contextmenu")`.

**Regelbezug.** LUA-01 requires a dependency to be hard or soft consistently, and forbids presenting a hard one as optional in the docs. `docs/installation.md:17-24` lists ui.nvim under "Optional, each degrading to nothing when absent", and `integrations/menu.lua`'s own header says "open.nvim does not depend on a menu plugin". The CI workflow contradicts both — it checks out ui.nvim because "the picker test drives open.picker's require(\"ui.kit\").select() for real".

**Auswirkung.** ui.nvim is a hard dependency of two surfaces while the docs present it as optional and degrading. Verified: with ui.nvim absent, `setup({ picker = { enabled = true } })` turns a documented option into a hard failure — every subsequent `:Open` that reaches the picker throws `module 'ui.kit' not found` instead of falling back to `vim.ui.select`, which the picker's own docstring says it wants to honour anyway. `require("open.integrations.menu")` throws at load. `:checkhealth open` cannot diagnose either, because it has no ui.nvim probe. The default path (`picker.enabled = false`, menu never required) is unaffected, so this bites only users who follow the docs and enable the option.

### `LUA-16` — `vim.NIL` sanitizen

`lua/open/keywords.lua:158` · `resolve_pip_conf` · confidence **high**

**Befund.** `local appdata = vim.fn.getenv("APPDATA") or ""` followed by `return appdata .. "\\pip\\pip.ini"` on line 159. `vim.fn.getenv()` returns `vim.NIL` (userdata), not Lua `nil`, when the variable is unset, so the `or ""` guard never fires.

**Regelbezug.** LUA-16 is exactly this: `vim.NIL` is userdata, not `nil`, and string concatenation with it throws. The field must be checked as `v == vim.NIL` (or read via `vim.env.APPDATA`, which does return `nil`).

**Auswirkung.** `:Open <handler> pip_conf` (and `require('open').open(..., 'pip_conf')`) raises a Lua error instead of degrading, and because of the confirmed ERR-01 defect at context.lua:341 the throw is not contained — `context.with_cache` re-raises at line 52, so the whole invocation aborts with a traceback rather than reporting "Nothing to open". Trigger is narrower than the auditor implies: Windows only, and only when APPDATA is unset or empty, which is unusual outside stripped service/CI environments. The defect is still real — the written guard does nothing.

### `LUA-92` — Ein Adapter lädt sein Plugin während `setup()` nicht

`lua/open/integrations/urlview.lua:74` · `M.setup` · confidence **high**

**Befund.** `if opts.default_picker == nil and pcall(require, "telescope") then` and, on line 77, `and pcall(require, "fzf-lua") then` — `require` is used purely as an availability probe inside this adapter's `setup()`.

**Regelbezug.** LUA-92 states it outright: an adapter reads `package.loaded["<plugin>"]` and never `require`s, because under a lazy manager the `require` IS the load trigger; `require` is only allowed where `:checkhealth` alone reads it. LUA-91 adds that "installed" is not the question — whether the plugin is set up is.

**Auswirkung.** Calling `require("open.integrations.urlview").setup()` from urlview.nvim's config block — the module's own documented usage — fully loads telescope.nvim, and if telescope is absent then fully loads fzf-lua, defeating whatever `cmd`/`keys`/`ft` trigger that engine's spec declares and pulling it into that startup. It also selects a picker that is merely installed rather than set up (LUA-91). Scope is narrower than a core defect: this module is opt-in, is not loaded by `open.setup()`, and the probes are skipped entirely when the caller passes an explicit `default_picker`.

### `SEC-30` — Nutzereingabe literal escapen

`lua/open/viewer/init.lua:342` · `M.open` · confidence **high**

**Befund.** `pcall(vim.fn.search, "\\c^#\\+\\s*.*" .. slug, "w")` where `slug = frag:sub(2):gsub("%-", "[- ]")` and `frag` is the `#anchor` tail of a link target scraped out of a buffer or a file on disk by `open.viewer.scan`.

**Regelbezug.** SEC-30 requires a pattern built from user/foreign input to be literal-escaped before it reaches the regex engine. Only `-` is touched here (and deliberately turned INTO a character class); every other Vim-regex metacharacter in the anchor — `.`, `*`, `[`, `~`, `\\`, `\\(`, `\\{n,m}` — is passed through raw.

**Auswirkung.** Following a markdown link whose anchor contains a Vim-regex metacharacter (`.`, `*`, `[`, `~`, `\`) jumps the cursor to the wrong heading, silently — verified: an anchor naming a literal heading `a.*b` landed on an earlier unrelated heading instead. The `pcall` hides a malformed pattern but does nothing for a pattern that is merely wrong, so the user sees a successful jump to the wrong place. Two parts of the auditor's impact I am trimming: the "unbounded time backtracking" claim is speculative — a probe with `a\{1,99}[` returned immediately without error — and the `:Open viewer cwd` scope remark describes `scan`, not this search, which only runs once per link the user actually follows. Fix is a very-nomagic (`\V`) prefix or literal-escaping the slug.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/open/context.lua:92` · `resolve_existing_path` · confidence **high**

**Befund.** `resolve_existing_path()` runs `vim.fn.expand(candidate)` on raw buffer/user text: it is fed `signals.cfile` (line 238) and, from `M.resolve` line 371, the final resolved `text` — which is the visual selection, `<cWORD>`, or the literal scope argument the user typed.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on buffer/user text: a backtick span in the argument is a command substitution through `&shell`, and `%`/`#`/`<cfile>` are Vim specials. The plugin already knows the safe primitive — `lib.nvim.cross.fs.expand_path` is used two lines up at context.lua:329 and 343 — but not here.

**Auswirkung.** Silent shell execution via `&shell` with no gesture beyond invoking `:Open`. Verified on Windows with the default `cmd.exe` shell (and with `powershell.exe`): the embedded command runs, its output is discarded, and `expand()` returns the string unchanged, so nothing in the UI indicates anything ran. Because the call sits in the unconditional `is_path` probe at line 371, it fires before any handler is chosen and regardless of which handler was asked for, and again per entry scrolled in the telescope previewer. The trigger is a backtick span occupying the whole resolved text — a visually selected line, the `<cWORD>` under the cursor, or a literal `:Open <handler> <text>` argument. Unix `&shell` accepts a wider set of spans than the Windows whole-string case.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/open/handlers/filemanager.lua:35` · `resolve_path` · confidence **high**

**Befund.** Every path-taking handler re-expands the context text through Vim's filename expansion: `filemanager.lua:35` (`vim.fn.expand(text)`), `nvim_internal.lua:19`, `terminal.lua:21` and `browser.lua:26` (`"file://" .. vim.fn.expand(text)`). `ctx.text` is the visual selection, `<cWORD>`, or the verbatim scope argument.

**Regelbezug.** Same rule as the context.lua case, but these are four independent call sites that each need their own fix — swapping only the central one in context.lua leaves all four live. None of them restricts the input to a path it produced itself.

**Auswirkung.** Four independent execution sites: fixing only `context.lua` leaves each one live. Verified that the filemanager handler alone executes the embedded command when handed a context built elsewhere, so the viewer's own dispatches (viewer/init.lua:318/328/337) and any programmatic caller reach it without `context.resolve`. On the normal `:Open filemanager <backtick span>` path the command runs twice — once in the `is_path` probe, once in `resolve_path`. Note browser.lua:26 is gated on `ctx.is_path`, so in practice it only re-expands text that already stat'd as an existing path; the other three are reached with arbitrary text.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/open/context.lua:341` · `M.resolve` · confidence **medium**

**Befund.** `text = kw()` invokes a scope-keyword resolver with no `pcall`. The resolvers come from `cfg.keywords`, which mixes the plugin's built-ins (`open.keywords.builtin()`) with arbitrary user-supplied functions accepted by `setup({ keywords = { ... } })`.

**Regelbezug.** ERR-01 makes `pcall` mandatory at system boundaries, and a config-supplied callback that may shell out (`capture()` runs `vim.system():wait()`), touch the filesystem, or read the environment is one. This is not a hot path — it runs once per `:Open`.

**Auswirkung.** A throwing scope-keyword resolver aborts the entire `:Open` invocation with a Lua traceback instead of degrading to the "Nothing to open" path that already exists eight lines below at line 353. Verified with a user-supplied keyword and, independently, with the plugin's own `pip_conf` built-in. The resolvers are exactly the kind of boundary ERR-01 names — `capture()` shells out via `vim.system():wait()`, others read the filesystem and the environment — and `with_cache`'s deliberate re-raise means the error surfaces raw to the user.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/open/init.lua:119` · `M.setup` · confidence **medium**

**Befund.** `local ok_deps, deps = pcall(require, "lib.nvim.deps")` / `if ok_deps then deps.show_once("open.nvim") end` — only the `require` is guarded; the call into the foreign module is not. The comment on lines 112-119 states the intent as "pcall'd because an older lib.nvim without lib.nvim.deps must not break setup() over an informational popup".

**Regelbezug.** ERR-01 covers the call into a plugin API, not just its require. The guard as written only defends against the module being absent, not against `show_once` itself failing — an API-signature change, a malformed `docs/install.json`, or a failure inside the popup.

**Auswirkung.** An error inside `show_once` — an API-signature change, a malformed docs/install.json, a failure while drawing the popup — makes `setup()` raise, which is precisely the outcome the comment above it set out to prevent. Correction to the auditor: nothing is left half-initialised. Line 119 is the final statement, so the command, keymaps and the office_open autocmd are all already registered and the plugin works; what the user gets is a raw traceback out of their lazy.nvim config block over an informational popup, and any caller that checks `pcall(setup, ...)` concludes setup failed when it did not. Fix is `pcall(deps.show_once, "open.nvim")`.

### `ERR-03` — Explizite Rückgaben

`lua/open/registry.lua:112` · `M.dispatch` · confidence **medium**

**Befund.** `local ok, err = pcall(handler.run, ctx)` — `ok` is the pcall status and `err` is the handler's FIRST RETURN VALUE when the call succeeded, i.e. the handler's own `true`/`false`. The `if not ok` branch on line 113 therefore never sees a handler that returned `false`. `M.dispatch` itself declares no `@return` and returns nothing, and so do `open.M.open` (init.lua:43-69) and `usrcmds.run_open`.

**Regelbezug.** ERR-03 requires relevant functions to return true/false plus an error object. Every handler in this plugin carefully computes and returns a boolean (`browser.lua:109`, `filemanager.lua:67`, `nvim_internal.lua:47`, `terminal.lua:55`, `image.lua:37`, `default.lua:28`) and the dispatch layer throws all of it away.

**Auswirkung.** The success/failure boolean every handler carefully computes is discarded at the dispatch layer and never reaches a caller — verified, `registry.dispatch` and `require('open').open` both return 0 values. A programmatic caller (integrations/menu.lua, integrations/urlview.lua:44, viewer/init.lua:318/328/337, or a user keymap) cannot distinguish a successful open from a failed one and therefore cannot fall back to another handler. Not fully silent to the human: every handler notifies on its own failure, so the user does see something — this is a broken return contract, not an invisible failure. `err` at line 112 is also misnamed: on success it holds the handler's return value, not an error.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/open/config/init.lua:47` · `M.get` · confidence **medium**

**Befund.** `M.get()` returns the internal `current` table by reference. Its docstring says only "Return the active config" — it neither copies before handing out nor documents a "live reference, do not mutate" contract, and it is a documented public API (docs/api.md, and every module in the plugin calls it).

**Regelbezug.** ERR-54 requires one of the two: copy on the way out, or an explicit live-reference contract every consumer honours. Neither is present, and because of the ERR-51 defect above the shared state reaches all the way back into the module-level DEFAULTS.

**Auswirkung.** Latent, not yet triggered: no module inside open.nvim currently mutates the table `config.get()` hands out, so nothing breaks today. What the missing contract buys is that any consumer — a user's config, another plugin, a future renderer that sorts a config list for display — can rewrite the plugin's DEFAULTS for the session without any signal, because ERR-51 above makes the handed-out sub-tables the DEFAULTS sub-tables. Fixing ERR-51 alone reduces the blast radius to the session's config; the getter still needs either a copy or an explicit documented contract.

### `PRIN-20` — Keine stillen Fehler

`lua/open/init.lua:89` · `M.setup` · confidence **medium**

**Befund.** `local ok, mod = pcall(require, mod_path)` / `if ok and type(mod) == "table" and type(mod.register_all) == "function" then pcall(mod.register_all, registry.register) end`. Neither pcall's failure is reported: a handler module that fails to load has no `else` branch, and a `register_all` that throws part-way has its error discarded. The only warning in the loop (line 92) covers an unknown handler KEY, not a failed load.

**Regelbezug.** PRIN-20 / ERR-03 forbid silent failure, and LLS-31 names this precise shape — the pcall is what keeps the breakage invisible, and the function goes on to report success by doing nothing. `setup()` completes normally either way.

**Auswirkung.** A handler module that fails to load, or a `register_all` that throws part-way, is swallowed entirely: `setup()` returns normally and says nothing. Verified — setup reported success while the browser handler was silently missing from the registry. The user's first symptom is `:Open browser` answering "Unknown target: 'browser' (available: ...)" with no pointer to the failed module, and `:checkhealth open`'s `check_handlers()` can only list what did register. A `register_all` that throws half-way leaves a partially registered module in the same silence. Same shape as the ERR-22 finding but from the opposite direction: there a bad value is too loud, here a real failure is inaudible.

> **Abdeckung dieses Laufs.** SCOPE: read all 26 Lua files under lua/ plus plugin/open.lua (3819 LOC) line by line, plus README.md, docs/installation.md, docs/api.md, docs/BINDINGS.md and .github/workflows/ci.yml. Nothing in the plugin was edited — `git status` in E:/repos/open.nvim is clean. .claude/, .git/, .deps/ and doc/tags were not touched.

VERIFICATION: eight of the thirteen findings were reproduced in a headless nvim with open.nvim + lib.nvim on the runtimepath, writing only into the session scratchpad (SEC-34 x2 proof directories, ERR-51 defaults poisoning, LUA-16 pip_conf throw, ERR-22 four aborted setups, LUA-01 picker/menu failures with ui.nvim absent, ERR-03 zero-return dispatch). All proof artifacts were deleted afterwards.

WHAT I COULD NOT COVER:
- TESTS/ (3030 LOC, 16 spec files) was surveyed for structure and coverage gaps but NOT audited rule by rule — no test-code findings are reported, and their absence should not be read as a clean bill.
- Unix/macOS/WSL behaviour. All runtime verification ran on Windows 11. That matters most for SEC-34: on Windows only a whole-string backtick span executes (`x=`whoami`` did not fire), so `viewer/scan.lua:108` — `vim.fn.expand(path)` on a markdown link target — is NOT reportable here because `is_absolute()` gates it to strings that cannot be a bare backtick span. On a shell where a prefixed span expands (the markdown.nvim Beleg used `./`...``), scan.lua:108 becomes a live SEC-34 site reached merely by listing links, and it should be fixed together with the others. `viewer/scan.lua:126` is safe either way: its token pattern excludes backticks.
- lib.nvim's own code (harvest.scope/sink/emit, cross.run, cross.reveal_in_fm, usercmd.composer) — treated as a trusted dependency boundary, not audited.

JUDGMENT CALLS I DELIBERATELY DID NOT REPORT:
- UI-55 at office_open.lua:53: I tested the mechanic — Neovim falls back to the ALTERNATE buffer, not an empty scratch, so the rule's harm only appears when no other listed buffer exists, which is the `nvim report.docx` case the code's own comment calls out as desired. Not a finding.
- PERF-42 at keywords.lua:31 (`capture_cache`): no TTL, but the lifetime IS defined (session) and documented in a 10-line comment. The only real staleness is editing `git config --global core.excludesFile` mid-session. Below the bar.
- XP-05 at keywords.lua:83: `resolve_pwsh_profile` does not cache a NEGATIVE `executable()` probe, so on a machine with neither pwsh nor powershell every `:Open pwsh_profile` re-pays two failing PATH x PATHEXT walks. Lazy, not on the startup path the rule targets.
- LUA-90 at integrations/urlview.lua:81 (`urlview.setup(opts)`): calling a foreign plugin's global setup, but the module is opt-in and its header tells the user to call it FROM urlview's own config block, which makes the caller the single owner. Defensible as written.
- ERR-50: there is no config validation at all, so the rule's ordering requirement (validate before merge) has nothing to order. Reported as ERR-22 instead, which is the concrete failure.
- context.lua:340-344 inconsistency: a STRING keyword gets `expand_path`, a FUNCTION keyword's return does not. It currently works only because the SEC-34-violating `vim.fn.expand` downstream happens to expand the `~`. Whoever fixes SEC-34 must route function-keyword results through `expand_path` too, or `:Open gitignore_global` breaks when git config returns a literal `~/...`.

TEST-COVERAGE GAPS relevant to these findings: no spec exercises a backtick/shell-metacharacter target, a wrong-typed config value, `vim.fn.getenv` returning `vim.NIL`, or mutation-through-`config.get()`. `TESTS/config_spec.lua:111` asserts that a bare `setup({})` restores `command` to its default — that assertion passes only because `command` is a scalar; the same claim is false for every nested table, which is the ERR-51 finding.

---

## sessions.nvim

**13 Befunde** (9 × high). Roh gemeldet: 13.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/sessions/layout.lua:158` · `M.restore` · confidence **high**

**Befund.** `build(tree, api.nvim_get_current_win(), out)` is called unguarded; `build` recurses into `split_children` (line 75-83), which calls `api.nvim_set_current_win(winid)` and `vim.cmd("rightbelow vsplit"/"rightbelow split")` with no pcall -- even though every other editor call in this same function is wrapped (line 153 `only!`, lines 170/175 the win sizing), and core.lua wraps all of its `vim.cmd` calls.

**Regelbezug.** ERR-01 makes pcall mandatory at system/plugin-API boundaries. A split raises `E36: Not enough room` when the remaining window is too small, and `M.restore` documents the contract `@return boolean ok, string path_or_err` -- an error thrown from inside it bypasses that contract entirely. lib.nvim's composer does not catch it either: `parse.lua:199` ends with a bare `return run(ctx)`, no pcall.

**Auswirkung.** Restoring a layout with more windows than the current terminal can fit throws E36 as a raw Lua traceback out of `:Session load-layout`, so the `n().error("layout restore failed: ...")` branch at bindings/usercmds/init.lua:281 is unreachable for this failure and M.restore's documented `@return boolean ok, string path_or_err` contract is bypassed. The aggravating detail is verified: line 153 has already run `silent! only!` by that point, so the user's previous window arrangement is gone and the replacement is half-built when the error lands.

### `ERR-02` — Type Guards & Literal Checks

`lua/sessions/git.lua:30` · `M.current_branch` · confidence **high**

**Befund.** `local stat = vim.uv.fs_stat(dotgit)` indexes `vim.uv` with no nil check, while every other site in the plugin writes `vim.uv or vim.loop` (core.lua:7, config/init.lua:31, health.lua:29, health.lua:130).

**Regelbezug.** ERR-02 requires a `type`/`nil` check before API access. `vim.uv` was introduced in Neovim 0.10; on 0.9 it is nil. The plugin explicitly claims 0.9 support (README badge "Neovim 0.9+", health.lua:15-19 passes on `nvim-0.9`, health.lua:29-33 deliberately probes `vim.uv or vim.loop`), so this is the one place that breaks the contract the rest of the file honours.

**Auswirkung.** Narrower than stated. I read E:/repos/lib.nvim/lua/lib/nvim/git/init.lua: it requires lib.nvim.cross.run_argv lazily inside git_system, not at module level, so `pcall(require, "lib.nvim.git")` at git.lua:11 succeeds on any install that has lib.nvim at all -- and lib.nvim is a hard dependency (bare module-level require at bindings/usercmds/init.lua:6). The fallback branch containing line 30 therefore only executes on a partial or version-skewed lib.nvim checkout that is missing the git submodule. On such a checkout running Neovim 0.9, M.current_branch() raises `attempt to index a nil value (field 'uv')` on the resolve path shared by :Session save, :Session load, the VimLeavePre autosave and the VimEnter autoload, instead of degrading to default_name as the rest of the function is written to do. The one-line `vim.uv or vim.loop` the other four sites use is the whole fix; the code-level inconsistency is unambiguous even where the impact is not reachable.

### `ERR-03` — Explizite Rückgaben

`lua/sessions/portable.lua:124` · `M.make_relative` · confidence **high**

**Befund.** `write_all(session_path, content)` discards the `(ok, err)` pair that `lib.nvim.fs.write.to_file` returns (see the wrapper at line 26-28), and `M.make_relative` itself returns nothing at all. `read_all` (line 19-21) likewise flattens a read failure and an empty file into `""`, and line 117-119 then returns early and silently. `core.lua:242-244` calls it without checking anything and goes on to report success at line 268.

**Regelbezug.** ERR-03 requires relevant functions to return true/false plus an error object rather than failing silently. This function performs the entire `relative_paths` feature -- the one thing that makes a session file portable -- and has no channel through which failure can reach the caller, while the caller advertises the save as successful.

**Auswirkung.** Accurate as written. With relative_paths = true, a failed post-processing read or write (file held by a sync client or antivirus, read-only volume) leaves the session file host-absolute while :Session save reports success -- bindings/usercmds/init.lua's save route sees ok = true and prints "saved: <path>". The failure is discovered only on the second machine, where the session sources paths that do not exist there, which is the one scenario the feature exists for. Note M.prepare_for_load (portable.lua:137-171) has the mirror-image gap: portable.lua:169 discards the write result for the temp copy, so a failed temp write hands core.load a path it will then try to source. Giving make_relative a `(boolean, string|nil)` return and checking it at core.lua:243 and :300 is the whole fix.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/sessions/picker.lua:80` · `do_delete` · confidence **high**

**Befund.** `do_delete` loops `core.delete(name)` discarding both return values, then reports `n.info("deleted: " .. table.concat(names, ", "))` -- the list it *intended* to delete, not the list it actually deleted. `core.delete` returns `false, "session not found: ..."` or `false, "failed to delete: ..."` (core.lua:447-453).

**Regelbezug.** LLS-31's inversion clause: "eine Funktion, die ihre Rückgabe aus der geplanten statt der tatsächlichen Arbeit bildet, kann nicht auffallen (`return #geplant` statt `return #erledigt`)". Same failure as PRIN-20/ERR-03: a relevant function swallows failure and reports success. The `:Session delete` route (bindings/usercmds/init.lua:160-165) handles the same call correctly, so the picker path is the outlier.

**Auswirkung.** A session file that is read-only, held open by another process, or on a read-only volume is reported as "deleted: alpha, beta" while still on disk. The Snacks branch makes it worse in a verifiable way: picker.lua:129-136 filters the names out of picker.opts.items and calls picker:refresh() unconditionally, so the entry disappears from the open picker regardless of what happened on disk and reappears on the next :SessionLoad with no explanation. do_delete's notifier only ever exposes `info` (picker.lua:70-76 builds a fallback table containing info alone), so there is currently no channel through which a per-name failure could even be reported without also extending that table.

### `LUA-06` — `config/DEFAULTS.lua` bleibt reine Daten

`lua/sessions/config/DEFAULTS.lua:17` · `default_blacklist_paths` · confidence **high**

**Befund.** The returned defaults table calls `default_blacklist_paths()` at line 57, i.e. at module-load time, and that function runs `vim.fn.has("win32")` and `vim.fn.expand("$TEMP")`. Line 26 likewise resolves `vim.fn.stdpath("data")` on the module level.

**Regelbezug.** LUA-06 states that a `require` of `config/DEFAULTS.lua` must only *name* values, never *compute* them -- an env lookup or filesystem resolution on the module level is exactly the named violation, because `require("<plugin>.config.DEFAULTS")` has to stay side-effect-free for docgen, tests and any early accessor-less reference. The work is also pure duplication: `config/init.lua:29-59` re-resolves `$TEMP` (in all four spellings, plus `fs_realpath`) at `setup()` time anyway, so the module-level result is overwritten in practice.

**Auswirkung.** The auditor's stated impact overstates the runtime consequence and I am correcting it: because config/init.lua:48-59 appends the runtime %TEMP% spellings additively (deduping first) rather than replacing them, the module-level value is not actually 'overwritten' and does not produce wrong behaviour on any machine today. The accurate consequence is the one the rule exists for: `require("sessions.config.DEFAULTS")` is not side-effect-free -- it performs an environment lookup and a stdpath resolution -- which breaks the contract that docgen, TESTS/config_spec.lua:7 and any future early accessor-less reference rely on, and freezes both values at first-require time instead of at config-build time. This is a conformance fix with no user-visible behaviour change, matching how pickers.nvim, casedesk.nvim and reposcope.nvim were migrated.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/sessions/meta.lua:32` · `M.read` · confidence **high**

**Befund.** `M.read` returns whatever `lib.nvim.fs.json.read` decoded, unvalidated and with the `err` half of the pair discarded, and both consumers use the fields directly: `bindings/usercmds/init.lua:198-199` concatenates `meta.saved_at`/`meta.branch`, and `picker.lua:44-56` concatenates `saved_at`/`branch`/`cwd` and runs `ipairs(meta.buffers or {})`.

**Regelbezug.** SEC-33 requires every field of a persisted snapshot to be re-validated on load (type, length, count cap). The `.{name}.json` sidecar is exactly such a snapshot: it lives next to the session file in a directory the plugin itself encourages to be git-tracked and synced across machines (`:Session toggle-track`, docs/git-integration.md). The plugin's own `layout.lua:118-138` (`is_valid_node`) does this validation properly, with a comment describing a crash caused by precisely this omission -- meta.lua never got the same treatment. Dropping the `err` also collapses "no sidecar" and "corrupt sidecar" into one `nil` (ERR-11); `layout.lua:148-150` keeps the `err`, meta.lua does not.

**Auswirkung.** A sidecar whose `saved_at` or `branch` decodes to a table (e.g. `"branch": {}`) makes `:Session list` raise `attempt to concatenate a table value` at bindings/usercmds/init.lua:198-199, and because that concatenation sits inside the `for _, p in ipairs(list)` loop, one bad sidecar takes out the listing of every session, not just its own. `"buffers": "x"` makes picker.lua:55 raise `bad argument #1 to 'ipairs'` in the preview. Neither is caught: lib.nvim's composer ends with a bare `return run(ctx)` at bindings/usercmd/composer/parse.lua:199, so the error surfaces as a raw traceback. The ERR-11 half is also real -- a corrupt sidecar and a missing one both arrive as nil, so picker.lua:59-60 tells the user "(no metadata recorded -- enable `metadata = true` ...)" about an option that is already on by default (DEFAULTS.lua:43).

### `UI-55` — Buffer löschen, dessen Fenster sichtbar sind

`lua/sessions/core.lua:176` · `wipe_blacklisted` · confidence **high**

**Befund.** Before every `:mksession`, `wipe_blacklisted()` force-deletes every loaded buffer whose buftype/filetype/path matches `cfg.blacklist`, without first checking whether that buffer is displayed in a window and without redirecting such windows to an alternative buffer.

**Regelbezug.** UI-55 requires visible windows to be redirected to an alternative buffer *before* the delete, precisely because Neovim otherwise auto-creates an empty scratch buffer in that window. The default blacklist contains `buftype = "nofile"`, which is what nvim-tree/neo-tree/Trouble/aerial sidebars and most dashboard buffers use, so the visible-window case is the common case, not an edge case.

**Auswirkung.** `:Session save` (and `:Session save-tab`) with a sidebar or dashboard open force-deletes that buffer while its window is still showing it. Neovim then reassigns the window -- to the alternate buffer when one exists, to a newly created empty buffer when none does -- so the user's visible layout changes as a side effect of saving, and :mksession records the substituted window instead of the sidebar. The auditor's "empty [No Name] scratch buffer" is the worst case, not the only one; the load-bearing consequence is that the saved layout no longer matches what was on screen. Separately real: `{ force = true }` discards unsaved changes without a prompt in any buffer whose name starts with a blacklisted path prefix (the $TEMP / /tmp / %TEMP% entries added by DEFAULTS.lua:12-22 and config/init.lua:29-59).

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/sessions/core.lua:424` · `M.list` · confidence **high**

**Befund.** `M.list()` passes the raw `cfg.root` straight to `fn.globpath(cfg.root, "*.vim", false, true)`; `M.list_tabs()` does the same with `cfg.root .. "/.tabs"` at line 436.

**Regelbezug.** XP-01 states that `glob`/`globpath` read their first argument as a *pattern*, not a path, and names `lib.nvim.fs.globbable` as the mandatory wrapper for "list the files in this directory". `cfg.root` is user-supplied and only passes through `lib.nvim.cross.fs.expand_path`, which expands a *leading* `~` and `$VAR`/`%VAR%` but leaves an 8.3 `~1` component untouched -- so `root = "%TEMP%/nvim-sessions"` resolves to `C:/Users/STEFAN~1/Temp/nvim-sessions` and glob tries to resolve `~1` as a user. lib.nvim is already a hard dependency here (20+ bare requires), so the prescribed helper is available at zero cost.

**Auswirkung.** Only reachable with a non-default root: the default `vim.fn.stdpath("data") .. "/sessions"` is long-form and safe. With a root under an 8.3 short path (e.g. `root = "%TEMP%/nvim-sessions"` on a profile name over eight characters) or a root containing `[`, `]`, `?` or `*`, globpath returns {} silently while core.save keeps writing files there by concatenation. Verified consumers of that empty list: `:Session list` prints "No sessions saved." (bindings/usercmds/init.lua:187-189), `:SessionLoad` prints "no sessions saved yet" (picker.lua:233-234), and <Tab> completion for `:Session load`/`delete`/`rename` offers nothing (the SESSION type at bindings/usercmds/init.lua:65-72 is built on core.list()). :checkhealth also reports "0 session(s) stored" for a full directory (health.lua:134-135). The sessions stay on disk and are unreachable through the plugin's own UI.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/sessions/layout.lua:189` · `M.list` · confidence **high**

**Befund.** `fn.globpath(layouts_dir(cfg), "*.json", false, true)` feeds the raw `cfg.root .. "/layouts"` path to globpath as a pattern.

**Regelbezug.** Same rule and same mechanism as the `core.lua` sites, in a second module: the directory argument is derived from user-supplied `cfg.root` and is never run through `lib.nvim.fs.globbable`.

**Auswirkung.** Same precondition as the core.lua finding (a session root with an 8.3 component or a glob metacharacter, not the default root). Under it, `:Session load-layout <Tab>` offers no candidates even though layout.save wrote the file successfully via lib.nvim.fs.json.write (which never globs), so a saved layout can only be restored by typing a name the plugin will no longer show. Note the restore itself still works if the name is typed exactly -- layout_path() concatenates rather than globbing -- so this is a discoverability failure, not data loss.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/sessions/config/init.lua:18` · `M.setup` · confidence **medium**

**Befund.** `M.cfg = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), opts or {})` is the entire setup path. There is no known-keys table, no per-value type check, and no "did you mean" pass -- neither before the merge nor after it. `health.lua:110-146` prints the merged values but never flags an unknown or off-type key.

**Regelbezug.** ERR-50 requires validation (unknown keys, "meintest du ...") to run *before* the merge, precisely so that a typo in a nested option does not vanish into the default. With no validation at any point, the failure the rule exists to prevent is fully present; ERR-22's "sichtbar gemacht über `:checkhealth`" is likewise unmet. TESTS/config_spec.lua tests only the merge itself and DEFAULTS immutability, never an unknown key.

**Auswirkung.** Worth stating precisely: the finding is really 'no validation exists at all' rather than 'validation runs on the wrong side of the merge', but the harm ERR-50 is written to prevent is fully present, so the site is in scope. Concretely, setup({ autosave_names = "proj" }) is accepted in silence, autosave keeps its default of resolving a project/branch name, and nothing -- not setup(), not :checkhealth sessions -- ever mentions the unknown key; setup({ blacklist = { filetype = {...} } }) likewise leaves the real filetypes list at its default so the buffers the user meant to exclude keep landing in the session file. The user sees the symptom (wrong autosave naming, temp buffers in sessions) with no path back to the typo. Lowest-cost fix is a KNOWN_OPTS table checked against opts before line 18, surfaced via vim.health.warn in health.lua.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/sessions/health.lua:74` · `M.check` · confidence **medium**

**Befund.** `:checkhealth` reports `lib.nvim.bindings.keymap` as optional ("not found -- using vim.keymap.set fallback", line 74) and `lib.nvim.notify` as optional ("using vim.notify fallback", line 67). No such fallback exists: bindings/keymaps/init.lua:91 does a bare `require("lib.nvim.notify").create(...)`, line 126 a bare `require("lib.nvim.bindings.keymap").register(...)`, line 134 a bare `require("lib.nvim.bindings.keymap.which_key")`. Grepping the whole plugin finds `vim.keymap.set` only in the autoload confirm float (autocmds/init.lua:80,85), never as a keymap fallback.

**Regelbezug.** LUA-01: a plugin picks hard or soft and holds it, and -- explicitly -- "eine harte Abhängigkeit darf in der Doku nie als optional dargestellt werden". lib.nvim is unambiguously hard here (20+ bare requires across config, state, meta, portable, buforder, layout, usercmds). The health report is the user-facing doc, and it advertises two fallbacks that were never written. bindings/autocmds/init.lua:12-14 compounds it by claiming in a comment that the fallback convention is "used in bindings/keymaps and bindings/usercmds", which is false for both.

**Auswirkung.** Two corrections to the auditor. First, the companion claim about health.lua:67 is wrong and I am dropping it: the vim.notify fallback genuinely exists in three of the four modules (bindings/usercmds/init.lua:19-35, picker.lua:70-76, bindings/autocmds/init.lua:18-24); only bindings/keymaps/init.lua:91 lacks it, so line 67 is broadly honest and the autocmds comment is half-right rather than wholly false. Second, the failure is narrower: a completely absent lib.nvim already throws at sessions/init.lua:27 (usercmds.enable) before keymaps are reached, and cfg.keymaps defaults to false (DEFAULTS.lua:66), so attach() is skipped entirely for default users. What survives is real: on a partial or version-skewed lib.nvim that has the composer but not bindings.keymap, :checkhealth reports "info: using vim.keymap.set fallback", and a user who then calls setup({ keymaps = {...} }) gets a throw out of attach at sessions/init.lua:34 -- after :Session/:LastSession/:SessionLoad and the autocmds were already registered and before `vim.g.loaded_sessions_nvim = 1` at line 40, with _setup_done already true (init.lua:23) so a retry is a silent no-op. Fix is one line: report it as an error, or keep the wording honest about there being no fallback.

### `LUA-16` — `vim.NIL` sanitizen

`lua/sessions/bindings/usercmds/init.lua:198` · `M.enable (list route)` · confidence **medium**

**Befund.** `local ts = (meta and meta.saved_at) and ("  " .. meta.saved_at) or ""` (and line 199 for `meta.branch`) guards only against `nil`, never against the JSON-null sentinel or a non-string type. `picker.lua:44-52` has the same shape for `saved_at`/`branch`/`cwd`.

**Regelbezug.** LUA-16 requires every field coming from external JSON to be checked with `if v == vim.NIL or type(v) ~= "string" then v = "" end` before use. `lib.nvim.json.decode` normalizes `vim.NIL` into `lib.lua.null`'s `M.NULL`, which is a table carrying only `__tostring` -- no `__concat` -- and is therefore *truthy*, so it sails past the `meta.saved_at and ...` guard and then blows up on the concatenation.

**Auswirkung.** A sidecar containing `"saved_at": null` or `"branch": null` makes `:Session list` fail with `attempt to concatenate a table value` (tostring would have printed "null") instead of listing anything, and makes the picker preview fail for that entry at picker.lua:45-51. Same blast radius as the SEC-33 finding -- one bad sidecar breaks the listing of all sessions -- and the two findings are two views of one defect: SEC-33 names the missing validation at the meta.lua load boundary, LUA-16 names the missing type guard at these two use sites. Fixing it at meta.lua:32 closes both.

### `UI-01` — Bulk-/destruktive Aktionen

`lua/sessions/picker.lua:118` · `pick_snacks / sessions_delete action` · confidence **medium**

**Befund.** `<C-d>` in the picker runs `do_delete(names)` on the whole multi-selection immediately, with no confirmation step of any kind (telescope backend: same, line 213). `core.delete` `os.remove`s the `.vim` file plus its `.json` and `.bufs.json` sidecars irreversibly.

**Regelbezug.** UI-01 requires a bulk/destructive action to be confirmed once. Here there is no confirmation at all -- which is strictly worse than the per-item confirmation the rule is written against. The plugin already ships a confirmation primitive it could reuse (`float_confirm`/`hand_rolled_confirm` in bindings/autocmds/init.lua:47-100) and uses it for the far less destructive `autoload = "ask"` prompt.

**Auswirkung.** This is the weakest of the set and I am confirming it on the rule text alone: UI-01 requires a bulk destructive action to be confirmed once, and there is no confirmation at any point. Concretely, one <C-d> -- including in insert mode while typing a filter into the Snacks input -- permanently removes every selected session file plus its .json and .bufs.json sidecars, with no undo and no prompt. I dropped the auditor's claim about <C-d> being adjacent to <C-u>/<C-f> scroll bindings: that depends on the host picker's own defaults, which are not in this repo and which I did not verify. The behaviour is clearly deliberate (the spec asserts it), so this is a policy conflict to decide rather than a latent bug, and the fix is one reuse of the float_confirm the plugin already ships.

> **Abdeckung dieses Laufs.** COVERAGE: read all 17 modules under lua/ in full (~2870 LOC), plus TESTS/run.lua, TESTS/harness.lua, config_spec, state_spec, meta_spec and the relevant blocks of core_spec and picker_spec (~530 LOC). Also read lib.nvim's fs/json, fs/globbable, cross/fs/expand_path, lua/null and the composer's parse.lua dispatch, because several rule verdicts depend on those contracts (whether the err half exists, whether nulls become vim.NIL or a sentinel, whether the composer pcalls route handlers). Ignored .git/, doc/, docs/map/ per instructions.

CHECKED AND CLEAN (leads that did not survive reading the code): ERR-11 in sessions/state.lua -- TESTS/state_spec.lua:38-44 documents the corrupt-file collapse as a deliberate loss-tolerant decision ("the session it points at is a convenience, not data the user typed"), which is the same exemption the ERR-11 Belege grants github_stats' telemetry store; no finding. ERR-51/ERR-52: config/init.lua:18 deep-copies DEFAULTS before merging and config_spec.lua:22 asserts it. ERR-62: every pcall in the tree uses the `pcall(f, args)` form. LUA-48: statusline.lua:26's `__mode = "k"` cache is keyed by the caller's opts *table*, which is collectable -- this is the correct positive example the Belege already cites. SEC-03/SEC-35: every process call is argv (`vim.system({...})`, `run_argv`), and every `vim.cmd` that takes user data uses the API/args form. SEC-30/SEC-42: portable.lua uses plain `find(..., true)` and escapes the placeholder; git.sanitize strips ANSI before whitelisting `[%w%-_]`. PERF-07, PERF-62, PERF-80, PERF-92, PERF-93, XP-05, XP-06, LUA-17: no matching surface or correctly handled (the only vim.system callback schedules before notifying; vim.g carries one number).

NOT REPORTED, JUDGMENT CALLS I chose to leave out rather than pad the list: (a) ERR-53 at bindings/autocmds/init.lua:107 -- `M.enable()` captures `cfg` once and the VimLeavePre callback reads `cfg.autosave_name` from that captured table, while config/init.lua:18 *replaces* `M.cfg` rather than mutating it in place, and all nine call sites in core.lua re-read the live table. The decoupling is real but I could not name anything that actually breaks: `sessions.setup()` is idempotent and `sessions.config` is not documented as public API, so the only trigger is an undocumented direct `require("sessions.config").setup(...)` at runtime. (b) ERR-31 at core.lua:471-478 -- `M.rename` is a textbook check-then-create (`filereadable` then `os.rename`, which silently overwrites on POSIX); the race needs two Neovim instances sharing one session root, which `:Session toggle-track`'s sync story makes plausible but not demonstrable. (c) LUA-11 at picker.lua:181 -- `nvim_buf_set_lines(self.state.bufnr, ...)` on a telescope-owned handle with no `nvim_buf_is_valid` check; strictly a violation, but telescope drives `define_preview` synchronously and I could not construct the failure. (d) PERF-46 at statusline.lua:35 -- the memo key is the opts table's identity, not its contents, so a consumer that mutates its own opts table in place gets a permanently stale merge; docs/statusline.md:65-70 documents the identity-keyed scheme, so it is a deliberate trade.

COULD NOT VERIFY: whether `vim.cmd.source(path)` escapes a path containing spaces (core.lua:340, 391). `nvim_cmd` is documented to escape file arguments for XFILE commands, and I had no way to run Neovim here to confirm, so I left it out; if it does not escape, a session root under a directory with a space in its name would break `:Session load` outright. I also could not execute the test suite (no Neovim in this environment), so every finding rests on reading, not on a reproduction.

---

## ui.nvim

**13 Befunde** (1 × high, 1 davon in Testcode). Roh gemeldet: 15.

### `ERR-60` — `a and b or c` bricht, sobald `b` falsy sein kann

`lua/ui/statusline/modules/lsp/helpers/paths.lua:275` · `M.display_path` · confidence **high**

**Befund.** `local home_tilde_override = type(cfg) == "table" and cfg.path_home_tilde or nil` — when the caller passes `path_home_tilde = false`, the `and` yields `false`, `false or nil` yields `nil`, and the explicit override is erased.

**Regelbezug.** ERR-60: `a and b or c` breaks as soon as `b` can itself be falsy. Here `b` is a boolean option whose whole point is that it can be `false`. `home_tilde(s, override)` distinguishes `override ~= nil` correctly, so it falls back to the module's live config instead of honouring the call.

**Auswirkung.** A caller passing `M.display_path({ path_home_tilde = false }, buf)` silently loses the override: `home_tilde` falls back to the module's live config, whose shipped default is `path_home_tilde = true` (config/init.lua:27), so the path still renders `~/project/file.lua` instead of the absolute home path the call asked for. That breaks the promise in the function's own doc comment (lines 261-267) that `cfg` "overrides the module's live config for THIS call only". Scope correction: `M.display_path_for_buf` (line 307) is unaffected in practice, because when the live config's value IS false the fallback resolves to false anyway -- the defect only bites a caller who wants a different value than the live config. The auditor's secondary PERF-46 claim is half right: an explicit `false` cannot reach the line 231 cache key VIA `display_path`, but `M.path_relative` is public and can be called with `false` directly, so the cache key itself is not broken.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/ui/contextmenu/init.lua:350` · `M.bind_buffer` · confidence **medium**

**Befund.** Inside the `<RightMouse>` keymap callback, `local items = get_items()` calls a provider function supplied by a *different* plugin with no pcall. The surrounding `vim.keymap.set(modes, keymap, ..., { buffer = bufnr })` also does not check `nvim_buf_is_valid(bufnr)` first.

**Regelbezug.** ERR-01: every call that touches a foreign plugin API must run through `pcall`. `get_items` is precisely such a boundary — the module's own doc comment says it is "safe to call unconditionally from a plugin's setup path" and that "the renderer is resolved when the trigger fires", and `M.open` on the very next line does pcall its own `require`.

**Auswirkung.** A contributing plugin whose items builder raises (a renamed upstream field, a nil buffer variable) turns every right-click in that buffer into a raw Lua traceback out of a keymap callback, rather than the degradation the module's own doc comment at lines 336-339 promises ("safe to call unconditionally from a plugin's setup path; the renderer is resolved when the trigger fires"). Scope correction: the second half of the auditor's claim -- that `vim.keymap.set` is called without `nvim_buf_is_valid(bufnr)` first -- is factually true of lines 348-359, but it belongs to LUA-11/LUA-12 ("Gueltigkeit pruefen"), not ERR-01, and should be reported separately rather than ride along in this finding's impact.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/ui/kit/form.lua:69` · `M.open / step` · confidence **medium**

**Befund.** `step(i)` returns whatever `input.open(...)` returns and `M.open` returns `step(1)`. `input.open` returns `nil` when `surface.open` fails (input.lua:104-106) without invoking `on_cancel`. `M.open` also returns `nil` for an empty `fields` list. The two are indistinguishable to the caller, and a failure at field *i > 1* is invisible entirely.

**Regelbezug.** ERR-11: a function whose result can legitimately be empty must make "empty but ok" distinguishable from "empty because it broke". Here "no fields to ask" and "the float could not be opened" both surface as a bare `nil`, and a mid-chain failure surfaces as nothing at all.

**Auswirkung.** Correcting the auditor on the empty-fields case: it is NOT indistinguishable in the way claimed. With an empty `fields` list, `step(1)` finds no field and calls `opts.on_submit(values)` with an empty table (form.lua:38-41) before returning nil, so the caller's callback contract does fire and "empty but ok" is observable. The genuine defect is the failure case only: if `surface.open` fails at any field, neither `on_submit` nor `on_cancel` ever runs and the caller's flow stops with no error and no dialog. Through `ui.kit.sync` that becomes a `vim.wait` (sync.lua:64) that can only end on `DEFAULT_TIMEOUT_MS`, which is `10 * 60 * 1000` (sync.lua:21), reporting `timed_out` instead of the real cause. Reference correction: the auditor cites kit/sync.lua:136, but that file is 74 lines long; the wait is at line 64. Likelihood note: `surface.open` failing is itself an edge case, so this is a robustness gap in a kit twenty sibling plugins build on, not a routinely-hit bug.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/ui/screenkey/init.lua:198` · `M.setup` · confidence **medium**

**Befund.** Every option is assigned straight through with only a truthiness check: `if opts.width then cfg.width = opts.width end`, likewise `height`, `margin`, `max_entries`, `fade_ms`. No type check, no range check, no degrade-to-default, and no `:checkhealth` surface (`ui.health` has no screenkey section at all).

**Regelbezug.** ERR-22: an invalid single config value must degrade to its default and be made visible through `:checkhealth`, rather than being accepted as-is. PRIN-25 says the same for arguments before they are worked with.

**Auswirkung.** The `max_entries` half of the auditor's impact is backwards and I am correcting it: with a negative or zero `max_entries`, the guard at line 183 (`if #entries > cfg.max_entries then table.remove(entries, 1) end`) is always TRUE, so it removes the oldest entry on every keystroke and the list is pinned at length 1 -- it does not grow unbounded, it collapses to a single visible key. The verified consequence is the arithmetic one: a non-numeric `width` (e.g. `true`) is accepted silently and first fails inside `build_text`'s `math.max(1, cfg.width - 2)` at line 102, reached from `render()` inside the `vim.schedule` body of `on_key` (lines 156-190), which is not wrapped in pcall. That produces a repeating "attempt to perform arithmetic" error on every keystroke once the HUD is enabled, with the traceback pointing at build_text rather than at the config value that caused it. The same applies to `height`/`margin` via `corner_geometry` at line 122.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/ui/bindings/usrcmds/themes/init.lua:28` · `active_theme_cfg` · confidence **medium**

**Befund.** `return (cfg and cfg.theme) or require("ui.config.DEFAULTS").theme` hands back either the live `_last_config.theme` sub-table (via `ui.config.last()`, itself a by-reference getter at config/init.lua:219) or, before the first `setup()`, the `require()`-cached `ui.config.theme` module table itself. `M.get_info()` (line 130) then publishes `toggle_themes = active_theme_cfg().theme_toggle` — the live array — to any caller.

**Regelbezug.** ERR-54: a public getter that returns internal shared state by reference must either copy before handing it out or explicitly document "live reference, do not mutate". Neither is done here; the doc comment only describes *which* config is returned, not that it is live.

**Auswirkung.** Correcting two overstatements. First, `active_theme_cfg` itself is a file-local function, not a public getter; the exposed surface is `M.get_info()`. Second, the "permanently rewrites the shipped defaults" claim holds only on the pre-`setup()` branch: after `ui.config.setup()` has run, `_last_config.theme` is a `vim.deepcopy` of `ui.config.theme` (config/init.lua:145), so a consumer mutating the returned array corrupts the assembled session config for the rest of the session but leaves `require("ui.config.theme")` intact -- the next `setup()` still deep-copies a clean table. Only a mutation performed before the first `setup()` reaches the module singleton and survives across later `setup()` calls. The `or {}` in `get_info` also means a nil `theme_toggle` yields a fresh, safely-mutable table, so only the populated case is live. As the auditor concedes, no in-repo consumer mutates it -- `:UI status` only `table.concat`s it (usrcmds/init.lua:198) -- so this is a latent trap on the published API, not an active bug.

### `PERF-42` — Invalidierbar

`lua/ui/statusline/modules/file_icons/devicons.lua:105` · `devicon_for_path` · confidence **medium**

**Befund.** When `soft_require.try("nvim-web-devicons")` returns nil, the generic fallback icon `󰈙` is written into the per-path LRU (`icon_cache:put(cache_key, result)`) as if it were a real answer. The only invalidation the cache has is the `ColorScheme`/`OptionSet background` reset at the bottom of the file (line 232) — nothing invalidates on "devicons is now loaded". The identical pattern is at `lua/ui/tabline/utils.lua:306`.

**Regelbezug.** PERF-42: it must be defined when an entry becomes invalid. The condition that produced this entry (devicons not loaded yet) is transient and has no corresponding invalidation trigger; the entry outlives the condition.

**Auswirkung.** Every path (statusline) or filename tail (tabline) rendered before nvim-web-devicons loads keeps the generic fallback glyph in a 256-entry LRU. It corrects itself only when the entry is evicted by LRU pressure or the user changes colorscheme/background -- in a session with fewer than 256 distinct files, neither happens. ui.nvim installs `lazy = false` (README:82) and paints on the first redraw, so the window is real whenever devicons is pulled in later by another plugin's lazy trigger. Severity correction: this is a cosmetic wrong-icon persistence, not a functional break -- `soft_require.try` stays correct, and any file first seen after devicons loads gets the right icon.

### `PERF-93` — Heißes Event: billiger Guard **oder** Throttle, nie ungeschützt

`lua/ui/statusline/modules/lsp/init.lua:113` · `M.render_breadcrumbs_lspfirst / render_breadcrumbs_inherit_lspfirst` · confidence **medium**

**Befund.** Both renderers call `M.symbol_context_smart()` unconditionally on every statusline evaluation. Without my.nvim installed that lands in `ui.statusline.modules.lsp.symbols.treesitter.symbol_context_ts()` (treesitter.lua:140), which walks every ancestor of the node under the cursor and, for each matching one, runs `ts_identifier_of` — a recursive child search plus `vim.treesitter.get_node_text` calls. There is no cache, no changedtick guard and no throttle. The module's own config declares `debounce_ms = 250` and `update_events` (lua/ui/statusline/modules/lsp/config/init.lua:11-19), but a repo-wide grep shows nothing outside the type annotations ever reads either key.

**Regelbezug.** PERF-93: on a hot path the handler must either leave the common case cheaply or be throttled, never unguarded. `'statusline'` is re-evaluated on essentially every cursor move and keystroke; a full Tree-sitter ancestor walk plus text extraction is the opposite of a cheap exit, and the debounce that was evidently designed for it is dead code.

**Auswirkung.** Hosts on the shipped `lsp` or `blocks` preset pay a full Tree-sitter ancestor walk plus node-text extraction on every statusline redraw, in every buffer that has a parser and where my.nvim is absent -- the common standalone case. Redraws on cursor movement and text change make this the hottest path in the plugin. Two `vim.deepcopy` calls of the config table ride along per render (helpers/paths.lua:309 and modules/formatters/init.lua:249 -- note the auditor's path for the latter omits that it lives under `modules/`, not `modules/lsp/`). Correction to the auditor's framing: PERF-93 names autocmd handlers on hot events, and this is a `'statusline'` expression rather than a handler, so the rule applies by analogy -- but the analogy runs in the strict direction, since a `%!` expression is evaluated at least as often as `CursorMoved` fires. The visible symptom (input lag on large files) is a reasonable expectation but was not measured here; what is verified is the absence of any guard and the deadness of the declared 250 ms debounce, which misleads both a reader and `:checkhealth`.

### `PRIN-10` — Keine globalen States

`lua/ui/statusline/cursor_ctl/init.lua:7` · `cursor_ctl.mode / set_mode` · confidence **medium**

**Befund.** The module's only state is a public field on the returned table: `local cursor_ctl = { mode = "row_progress" }`. `set_mode` (line 12) validates against the five legal names, but `cursor_ctl.mode = anything` from outside bypasses it entirely. `set_mode` itself is documented as "no-op on invalid input" and returns nothing.

**Regelbezug.** PRIN-10: state lives module-internally, reached only through getter/setter. Here the setter exists but the field is public beside it, so the validation is advisory. ERR-03 compounds it: `set_mode(nil)` and `set_mode("row_progres")` are both silent no-ops with no return value to tell them apart.

**Auswirkung.** Latent, and milder than stated. Every in-repo consumer goes through the getter -- config/statusline/lsp.lua:78, default.lua:70 and blocks.lua:136 all call `get_mode()` -- so nothing in the plugin writes the field directly. An unknown mode also does not error downstream: the cursor segment falls through every `elseif` and renders `renderer.cursor_classic()` alone, i.e. the classic display with no progress token, rather than breaking. The concrete harm is confined to a host following the published type and assigning `cursor_ctl.mode` directly: the write bypasses `set_mode`'s five-name whitelist entirely, the segment silently degrades to classic, and the next `toggle_mode()` jumps to "row_progress" instead of continuing the cycle. The ERR-03 half (both `set_mode(nil)` and a typo'd name are silent no-ops with no return value) is accurate but is the documented behaviour ("no-op on invalid input", line 9).

### `PRIN-20` — Keine stillen Fehler

`lua/ui/bindings/usrcmds/init.lua:230` · `switch_variant` · confidence **medium**

**Befund.** `require("ui.statusline.render").enable(assembled.ui.statusline)` then `return true`. `ui.config.setup` builds `config.ui` as `vim.tbl_deep_extend("force", { tabline = tabline_config }, statusline_config.ui or {})`, so `assembled.ui.statusline` is `nil` for any variant table that does not carry a `ui.statusline` key. `render.enable(nil)` sets its module-level `current = nil` (render.lua:226), after which `M.render()` returns `""` — and `switch_variant` still reports success.

**Regelbezug.** PRIN-20 / LLS-31's inversion: the return value is formed from the work that was *planned* (the call was made) rather than the work actually done. `M.enable`'s signature is `---@param cfg Ui.Statusline.Config` — non-optional — so passing nil is a contract break that produces no error and no warning.

**Auswirkung.** A host registering a variant with a slightly wrong shape (`{ statusline = {...} }` instead of `{ ui = { statusline = {...} } }`) gets `:UI variant <name>` printing the success notification at usrcmds/init.lua:261 ("Statusline variant changed to: <name>") while the statusline renders as an empty string, with no warning anywhere pointing at the cause. The state is also sticky: `current` stays nil until another `enable()` runs, so the statusline remains blank for the rest of the session, and `:UI status` reports the variant as active. Scope note: this is reachable only through a host-registered variant -- every shipped preset carries `ui.statusline`, so the default install cannot hit it.

### `PRIN-25` — Eingaben validieren

`lua/ui/bindings/keymaps/tabufline/state.lua:373` · `M.move_buf` · confidence **medium**

**Befund.** `bufs[i], bufs[i + n] = bufs[i + n], bufs[i]` with no range check on `n`. The only guards are the two single-step wrap cases (`n < 0 and i == 1`, `n > 0 and i == #bufs`). For `|n| > 1` near either end, `i + n` is outside the list: Lua evaluates the right-hand side first, so `bufs[i]` is set to `nil` (a hole in the array) and the buffer number is written past the end.

**Regelbezug.** PRIN-25: arguments must be validated before being worked with. The documented contract is `---@param n integer # positive moves right, negative moves left` — nothing restricts it to ±1, and `M.move_buf` is a public function on a public module.

**Auswirkung.** `vim.t.bufs = bufs` at line 379 then persists a table that is no longer a proper sequence -- a nil hole at `i` plus an entry past the end. Latency correction: this is unreachable through the shipped surface, since the only in-repo callers pass literal ±1 (bindings/keymaps/init.lua:114 and :125), so it is a latent contract hole rather than an active bug. Accuracy correction: I confirmed the corrupt table is built and assigned, but I did not verify the auditor's downstream story -- Neovim's Lua-to-vimscript conversion may reject a holed table on the `vim.t` assignment rather than store it, in which case the symptom is an error at the call rather than a tabline that silently drops chips. Either way the input is unvalidated and the outcome is not the documented one.

### `SEC-50` — Ein Preview liest, es führt nicht aus und wertet nicht aus

`lua/ui/kit/preview.lua:80` · `eval_config / M.open` · confidence **medium**

**Befund.** `eval_config` reads the whole config buffer, `loadstring`s it and `pcall(chunk)`s it. `M.open` wires that to `TextChanged`/`TextChangedI` on the config buffer (line 246), so the buffer's contents execute as Lua on every single edit. There is no gate of any kind — no `preview_execute` flag, no risky-pattern list, no confirmation — and `lua/ui/kit/init.lua:213` (`pcall(preview.ensure_command)`) registers `:KitPreview` unconditionally the moment any of the ~20 sibling plugins does `require("ui.kit")`.

**Regelbezug.** SEC-50: a preview reads, it does not execute and does not evaluate; anything executing needs an explicit `preview_execute = true` (default `false`) and is refused even then for a risky entry. Here evaluation is the mechanism, it is always on, and it fires automatically rather than on a deliberate user action.

**Auswirkung.** The auditor's impact overstates the exposure and I am correcting it. There is no drive-by path: the buffer is created empty by `M.open` and seeded from `initial_lines()`, a plugin-authored template; no file, picker entry, `extra_files` list or shell history is ever folded in, so content can only arrive through the user's own editing of a scratch buffer they explicitly opened with `:KitPreview`. The real, residual defect is narrower: because evaluation is bound to `TextChanged`/`TextChangedI` rather than to a deliberate action, a pasted snippet or a completion-inserted fragment executes with full Lua and vim API rights the instant it lands, before the user can read it -- which is a measurable step down from `:edit` + `:source`, where reviewing first is possible. The doc gap the auditor raises is separately true but is not a SEC-50 matter: docs/BINDINGS.md:7 claims "Nothing here is registered until require('ui').setup({ all = true }) runs", and `:KitPreview` contradicts that, appearing in no BINDINGS.md entry.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`TESTS/kit_drift_spec.lua:144` · `kit_files` · confidence **medium** · _Testcode_

**Befund.** `for _, p in ipairs(vim.fn.glob(root .. "/**/*.lua", false, true)) do` — the raw directory path (`vim.fn.getcwd() .. "/lua/ui/kit"`, or the lib.nvim side resolved from `$LIB_NVIM_DIR` / `.deps/lib.nvim` in `lib_root`, lines 38-53) is concatenated straight into a glob pattern.

**Regelbezug.** XP-01: `vim.fn.glob` interprets `~`, `[`, `?`, `*` and `{}` in its argument, and on Windows a path carrying an 8.3 component (`C:/Users/STEFAN~1/...`, which any profile name over eight characters produces for an env-var-supplied path) makes it try to resolve `~1` as a home directory and return an **empty list with no error**. The rule says never to feed `glob` a raw path for "list the files in this directory" — use `lib.nvim`'s `fs.globbable`, which compares hit counts rather than trusting the return value.

**Auswirkung.** Both failure modes are reachable, and the second is the serious one. If only the lib side globs empty, the first `it` (line 151) fails with a misleading "file sets differ" that points nowhere near the real cause. If both sides glob empty, the first `it` compares two empty lists and passes, and the second `it` (line 155) iterates nothing, so `drifted` stays `{}` and the drift guard reports success while having compared zero files -- and this spec is the only thing keeping lua/ui/kit and lib.nvim's frozen copy in sync. The spec's own header (lines 31-36) records that it already went inert in CI once for a structurally identical reason, which makes a second silent-pass mode in the same file materially worse than it looks. Realistic trigger: `ui_dir` comes from `vim.fn.getcwd()`, normally the long form, so the practical risk is the `$LIB_NVIM_DIR` path on Windows and any checkout directory containing `[`, `?`, `{}` or a literal `~`.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/ui/statusline/modules/git_clickable/init.lua:21` · `list_branches` · confidence **low**

**Befund.** `if vim.v.shell_error ~= 0 then return {}, nil end` — "this directory is not a git repository", "git is not on $PATH" and "git errored" all collapse into the same empty list with no second channel. The caller `switch_branch` (line 47) can only guess, and prints the combined message "No git branches found (not a git repo, or git not on $PATH)".

**Regelbezug.** ERR-11: a function whose result can legitimately be empty must return "empty but ok" distinguishably from "empty because broken". The module's own doc comment acknowledges the collapse ("`vim.v.shell_error` is the only signal `systemlist` gives") rather than resolving it — `systemlist` also returns the error text, which is discarded here.

**Auswirkung.** Three distinct situations produce one message. Beyond the two the auditor names, a genuine repository with no commits yet exits 0 with empty output and lands in the same warning via `#branches == 0`, so the message is wrong there too. `open_context_menu` (line 74) makes the same call and silently drops the "Copy branch name" entry in all three cases. Severity is as the auditor states -- a misleading warning on a mouse click, no data loss and no broken state -- and the fix is cheap because `systemlist` already returns the explanatory text that is being thrown away.

> **Abdeckung dieses Laufs.** COVERAGE. Read line-by-line: lua/ui/init.lua, config/{init,DEFAULTS,variants,theme}.lua, health.lua, winbar/init.lua, util/soft_require.lua, contextmenu/init.lua, bindings/** (keymaps, tabufline/{init,state}, usrcmds/{init,themes/init,themes/picker}), statusline/{render, utils/{primitives,clickable,idle,get_separators}, modules/lsp/**, modules/file_icons/devicons, modules/filetree_cwd_mode, modules/diagnostics_sparkline, modules/highlighting, and all 13 small segment modules}, tabline/{render,modules,utils,styles}, theme/{palette,transparency}, highlights/diagnostics.lua, screenkey/init.lua, kit/{init,surface,input,form,sync,note,toast,preview,picker,live_input,compare-timer-section,menu-action-section}, scripts/{test.sh,minimal_init.lua}, TESTS/kit_drift_spec.lua. Roughly 8,600 of the 14,349 Lua lines.

NOT READ LINE-BY-LINE, only pattern-scanned (greps for unguarded `nvim_*` API calls, `__mode`, timer lifecycle, `a and b or c` ternaries, module-level geometry, `next(t)` delete loops, shell/glob/expand usage — all came back clean): kit/chooser.lua (853), kit/menu.lua (820), kit/compare.lua (583 outside the debounce block), kit/confirm.lua (275), kit/theme.lua (230), kit/layout.lua (225), kit/select.lua, kit/viewer.lua, kit/prompt.lua; statusline/catalog.lua, statusline/highlights.lua, statusline/themes/default.lua, config/statusline/{default,minimal,lsp,blocks}.lua, tabline/highlights.lua, all @types files. kit/menu.lua and kit/layout.lua make zero direct `vim.api` calls (everything routes through kit/surface, which validates), so LUA-11/12/13 exposure there is genuinely low. The 7,319 lines under TESTS/ were pattern-scanned only; kit_drift_spec.lua is the single spec read in full.

NOT VERIFIABLE HERE: nothing was executed (no nvim run, no spec run) — every finding is from reading. lib.nvim is not in this checkout, so every `lib.nvim.*` call (notify, bindings.autocmd/keymap/usercmd, ui.hl.persist, debounce, memo.lru, window.make_scratch, cross.fs.expand_path, progress) was taken at its documented contract; LUA-01 (hard-vs-soft dependency consistency) and LUA-02 (fixes belong upstream) could therefore only be judged from this side. LUA-01 looks correct: lib.nvim is a bare `require` everywhere, health.lua:59-65 reports its absence as `error`, and README/docs/requirements.md call it "the one real dependency".

RULES CHECKED WITH NO HIT (not listed as N/A, they have surface here): PERF-07 (zero `next(t)` delete loops), PERF-62 (all three debounce timers — kit/compare.lua:308, live_input.lua:62, picker.lua:88 — do `timer:stop()` + `pcall(timer.close, timer)` before replacing the handle, textbook-correct), PERF-82 (every `ensure_autocmds`/`setup` is guarded by a `registered` flag), PERF-92 (no layout geometry at module level anywhere; every float computes its geometry at open time), PERF-80 (screenkey's `vim.on_key` hook defers all API work into `vim.schedule`), ERR-33/LUA-13 (winbar/init.lua:30, theme picker, chooser flash and tabline flash all re-validate handles inside the deferred callback), ERR-50 (`KNOWN_SETUP_KEYS` validation runs before the merge in config/init.lua:135), ERR-51 (three explicit `vim.deepcopy` calls with recorded reasons), LUA-06 (config/DEFAULTS.lua is pure data — the two module-level `require`s resolve to static tables; matches the existing Belege note listing ui.nvim as checked-and-clean), LUA-93 (README's `lazy = false` carries its reason inline), CMT-16 (docs/map/ is generated and gitignored; docs/BINDINGS.md is hand-maintained by design and says so).

RULES WITH NO SURFACE IN THIS PLUGIN: see rules_not_applicable.

TWO OBSERVATIONS THAT ARE NOT RULE VIOLATIONS BUT WORTH PASSING ON:
1. `ui.health.check_segments` (health.lua:315-330) probes ten foreign plugins with `has()` = `pcall(require, mod)`, which under a lazy manager *loads* each one. This plugin's own `util/soft_require.lua:70-84` exists specifically to avoid that ("a health check that loads ten lazy plugins... has changed the session it was asked to describe... and then reporting them all as 'present' because it just made them so") and `check_soft_dependencies` uses the non-loading `available()`. LUA-92 explicitly exempts `:checkhealth` from its require ban, so this is not a violation of the letter — but the two health sections contradict each other, and the `has()` one always reports "present" for anything installed.
2. `lua/ui/statusline/modules/variant/init.lua:29` builds an Ex command by concatenation: `vim.cmd("UI variant " .. choice)`. `choice` comes from `variants.list()`, i.e. names a host registered itself, so this is not SEC-35 in the untrusted-input sense — but a registered name containing `|` would start a second Ex command. `:UI` has no `-nargs` restriction that would catch it.
3. `:KitPreview` and `:Theme` are registered but absent from docs/BINDINGS.md, which states it lists every command the plugin registers.

---

## filetree.nvim

**12 Befunde** (3 × high). Roh gemeldet: 13.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/filetree/features/org/session/init.lua:61` · `load_store` · confidence **high**

**Befund.** load_store() returns with `_sessions` left at `{}` for four different reasons -- file missing, readfile failed, json_decode failed, decoded value not a table -- and reports none of them; save_store() (line 69) then unconditionally serialises the whole `_sessions` table back over the same file.

**Regelbezug.** This is the exact ERR-11 load-modify-save collapse the rule calls the most common real bug class of the 32-repo sweep: "file missing" (empty, but ok) and "file corrupt" (empty, because broken) are indistinguishable, and the next save writes the ENTIRE store. `_store_path` is `vim.fn.stdpath("data") .. "/filetree/sessions.json"` (line 221) -- one single file for every project, keyed by project_key(). Nothing in the module documents the store as deliberately loss-tolerant (the github_stats/runtime-analysis exemption in the rule's Belege does not apply). The repo already has the fixed primitive for this: features/nav/cwd_mode/init.lua:303 persists through lib.nvim.store.project, whose read_entry() was hardened at the root exactly for this case; session/init.lua hand-rolls its own JSON store instead.

**Auswirkung.** Accurate as written, and the default-on status makes it worse than the finding states. Any event that leaves sessions.json unparseable -- a truncated writefile at line 82, a hand edit, a crash mid-write -- silently resets the in-memory store to {}. The next VimLeavePre or BufHidden auto-save (wired at lines 228-240) then writes a file containing only the current project's entry, discarding every other project's saved adapter, tree root, cursor line, topline and expanded-dir list. No notification is emitted at load time or save time, so the user's only signal is that every other project reopens at its default root.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/filetree/refs/init.lua:32` · `filetree.refs` · confidence **high**

**Befund.** `refs/init.lua:32` bare-requires `filetree.refs.ui`, which bare-requires `ui.kit` at module level (refs/ui.lua:16); `filetree/init.lua:94` calls `require("filetree.refs").setup(cfg.refs)` without a pcall. Ten modules bare-require `ui.kit` (util/confirm.lua:19, util/confirm_choice.lua:13, features/fileops/move:44, trash/undo:13, org/marks:11, search/filter:22, search/live_search:27, ui/cheatsheet:25, ui/node_info:7, refs/ui:16), while create_from_template/init.lua:75 soft-requires the same module with a fallback.

**Regelbezug.** LUA-01 requires one regime, held consistently, and forbids presenting a hard dependency as optional in the docs. docs/installation.md:9 says ui.nvim "degrades to a single notify, not an error, if missing". It does not: the require chain from setup() is bare all the way down, so the failure is an error thrown out of setup(), not a degraded context menu. The single soft-require in create_from_template is the inconsistency the rule names.

**Auswirkung.** With ui.nvim absent or older than ui.kit, `require("filetree").setup({})` throws "module 'ui.kit' not found" out of init.lua:94 -- before tree_attach.install (139), before bufevents.install (145), before commands.setup (147). The plugin is not partially degraded, it is entirely absent: no :Filetree/:Ft, no keymaps, no features, and the error surfaces as a lazy.nvim config-function traceback rather than anything filetree-branded. A user following installation.md:9 expects to lose only the right-click context menu.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/filetree/refs/pathutil.lua:100` · `M.resolve_candidates` · confidence **high**

**Befund.** A link target read verbatim out of a scanned file is passed to vim.fn.expand() whenever it starts with `~` or a Windows drive letter (`out[#out + 1] = M.abs(vim.fn.expand(t))`).

**Regelbezug.** SEC-34 forbids vim.fn.expand() on buffer/user text: a backtick span inside the argument is a shell command substitution via &shell, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. `t` here is not a static config string -- it is `target` handed down from the markdown provider (refs/providers/markdown.lua:230, via pathutil.match:134) and the plaintext provider (refs/providers/plaintext.lua:297), both of which extract it from the text of a file on disk, after url_decode() has already turned `%60` back into a backtick. refs/scan.lua:283-297 (run_plan) feeds EVERY line of every candidate file through plan.extract, so it is not limited to the line that matched the needle. The correct primitive (lib.nvim.cross.fs.expand_path) is already known to this repo -- util/path.lua:30 uses it.

**Auswirkung.** Platform-split, and the auditor overstated it as universal. On Linux/macOS this is code execution: Neovim routes any pattern containing a matched backtick pair through the shell (SPECIAL_WILDCHAR -> os_expand_wildcards -> `echo <pattern>`, backticks left unescaped), which is the same primitive the rule's own Beleg records as confirmed in markdown.nvim (`![x](./`mkdir -p /tmp/pwned; echo a.png#`)` really created the directory). Cloning a repo containing `[x](~%60cmd%60/y.md)` and then renaming any file runs `cmd` during the pre-mutation scan, with no prompt in between. On Windows this does NOT execute: I ran `vim.fn.expand("~`echo PWNED > <probe>`/y.md")` under nvim 0.12.2 headless and the probe file was not created -- expand returned "", so the Windows consequence is only a silently mis-resolved link candidate. Fix is the same either way (lib.nvim.cross.fs.expand_path), but severity is RCE on Unix/macOS and a correctness bug on Windows.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/filetree/init.lua:69` · `M.setup` · confidence **medium**

**Befund.** `config_mod.validate()` failing makes setup() notify and `return` (lines 68-72), abandoning the whole initialisation: no features, no tree_attach, no bufevents, no :Filetree/:Ft commands. The same all-or-nothing return follows for an unresolvable adapter at lines 78-81.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default rather than abort the entire plugin initialisation, with the problem surfaced through :checkhealth. Here the two things validate() actually checks (config/init.lua:240-241: `adapter` must be a string, `features` must be a table) are single values with obvious defaults -- "auto" and `{}` -- yet either one being the wrong type takes the whole plugin down.

**Auswirkung.** Confirmed as described. `setup({ adapter = 0 })` or `setup({ features = "all" })` produces one `[filetree]` notification and a completely inert plugin -- :Filetree and :Ft are never registered, no keymaps are bound, no feature runs. The only remaining in-editor diagnostic is :checkhealth filetree, which re-runs validate() at health.lua:58 and prints the same message. Degrading the offending field to its default would have cost one line and left the rest of the plugin working.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/filetree/config/init.lua:238` · `M.validate` · confidence **medium**

**Befund.** `M.setup(user)` deep-merges the user table into a deepcopy of DEFAULTS (lines 220-226) with no validation of any kind beforehand; `M.validate()` runs afterwards, on the already-merged table, and only type-checks `cfg.adapter` and `cfg.features`. There is no known-key set anywhere in the plugin -- `deep_merge` (lines 25-34) copies every key it is given, and health.lua only reports validate()'s result.

**Regelbezug.** ERR-50 requires the unknown-key / "did you mean" validation to run BEFORE the merge, precisely so a typo in a nested option cannot vanish into the defaults. Here nothing detects unknown keys at any point, before or after; util/bind.lua:20-23 explicitly documents that the keymap registry's typo reporting was deliberately left out too.

**Auswirkung.** Confirmed. `setup({ adaptor = "neotree" })`, `setup({ features = { auto_reaveal = { enabled = false } } })` or any misspelled nested field is merged into the active config, never read by anything, and produces no warning at setup time or in :checkhealth -- which affirmatively reports "Config validated". The feature silently keeps running on its default. Because M.setup also re-deepcopies DEFAULTS each call, there is not even an accumulating-garbage symptom that might tip the user off.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/filetree/util/path.lua:30` · `filetree.util.path` · confidence **medium**

**Befund.** lib.nvim is soft-required with local fallbacks in roughly twenty places (util/path.lua:15/23/30, util/notify.lua, util/autocmd.lua:11, bindings/autocmds.lua:34,67, bindings/init.lua:39, nav/cwd_sync:291, paths/path_copy:182,320, nav/auto_reveal:158, infra/ignore_list:65,78 ...) while it is bare-required in roughly thirty others, including commands.lua:19, which filetree/init.lua loads at module top level.

**Regelbezug.** LUA-01 requires one regime held consistently. Because commands.lua:19 bare-requires lib.nvim.bindings.usercmd.composer and init.lua:9 requires commands.lua at load time, `require("filetree")` cannot succeed without lib.nvim at all -- so every soft fallback is unreachable for the case it was written for. docs/installation.md:8 reinforces the wrong mental model by saying only the commands fail to register. Two of the fallbacks also diverge behaviourally from the lib path (util/path.lua:42's vim.fn.expand, reported separately), and cwd_sync:291/path_copy:320 pcall-require lib.nvim.fs.find_root while nav/cwd_mode/init.lua:49 bare-requires the identical module.

**Auswirkung.** Maintenance and correctness-of-documentation risk, not a user-visible failure -- and one part of the finding's reasoning needs correcting. docs/installation.md:8 does NOT present lib.nvim as optional: it says "required", and only narrows what breaks. So LUA-01's documentation clause is not violated here (it IS violated for ui.nvim -- see the refs/init.lua:32 finding); what is violated is the consistency clause. The concrete cost is 26 fallback paths that no test can exercise and no user can reach, two of which diverge behaviourally from the lib path (util/path.lua:42's vim.fn.expand, reported separately), plus the fact that no single file tells a maintainer which regime is in force -- someone "cleaning up the lib.nvim optionality" in either direction has no local signal about which way is correct.

### `PERF-42` — Invalidierbar

`lua/filetree/features/ui/size_info/init.lua:103` · `get_file_size` · confidence **medium**

**Befund.** `_cache[path]` is consulted before every fs_stat and written once per path (lines 103-108, and 92 for the async directory branch); it is only ever emptied by the explicit `M.refresh()` command (line 154) or teardown (line 202). There is no TTL, no BufWritePost invalidation, and no per-entry expiry.

**Regelbezug.** PERF-42 requires a defined point at which a cache entry becomes invalid. The module's own header (lines 6-7) claims "Sizes are cached and refreshed lazily" and lists BufEnter and CursorHold as refresh triggers, but both only call M._render(), which reads the same cache back -- the refresh triggers re-render stale values rather than re-measuring. The repo's other caches do satisfy the rule (util/buffer.lua has TTL + a BufDelete invalidation; project_root documents why its key is session-stable and exposes clear_cache).

**Auswirkung.** A file's size is measured once per Neovim session and then frozen for that path. Writing the file, a build growing it, or a directory gaining entries leaves the tree's eol extmark showing the first value indefinitely; the BufEnter and CursorHold triggers the header advertises as refreshes re-render the stale number rather than re-measuring it. Only :Filetree size refresh (M.refresh) or a plugin re-setup corrects it. The feature is on by default (init.lua:114-121 forces enabled=true; size_info is not in DEFAULT_DISABLED), so this is the default behaviour, not an opt-in edge case.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/filetree/features/org/session/init.lua:190` · `M.restore` · confidence **medium**

**Befund.** `entry.topline`, loaded from sessions.json, is concatenated straight into `vim.cmd("normal! " .. (entry.topline or 1) .. "zt")` with no type check; `entry.cursor` is handed to nvim_win_set_cursor the same way (line 189). load_store (line 61) validates only `type(data) == "table"` for the whole store.

**Regelbezug.** SEC-33 requires every field of a persisted snapshot to be re-validated on load (type, length, count cap). This module does validate `entry.root` properly (normkey + is_subpath, lines 176-181, with a comment naming hand-edited stores as the threat) and `entry.adapter`, which shows the intent -- but topline and cursor are exempted from the same discipline, and topline is the one that is concatenated into an executable string rather than passed as an argument.

**Auswirkung.** Two distinct silent failures on every restore from a corrupt or hand-edited sessions.json, both swallowed by the pcall at 187-192 and never reported. (a) A string topline makes `:normal!` replay it as literal keystrokes in the tree window. (b) A table/boolean topline makes the concatenation at line 190 throw -- and it throws AFTER nvim_win_set_current_win(winid) at 189 but BEFORE the restore at 191, so the pcall leaves the user's cursor parked in the sidebar window at every startup, with no message explaining it. The auditor missed (b), which is the more likely of the two to actually bite. The count cap the rule asks for (a plausible line number, bounded entry.expanded) is absent throughout.

### `UI-55` — Buffer löschen, dessen Fenster sichtbar sind

`lua/filetree/adapter/netrw.lua:257` · `M.close` · confidence **medium**

**Befund.** `M.close()` locates the netrw buffer and deletes it with `vim.cmd("bdelete " .. buf)` without first pointing the window that displays it at another buffer.

**Regelbezug.** UI-55 requires visible windows to be redirected to an alternative buffer before the delete, because Neovim otherwise substitutes an automatically created empty scratch buffer. The netrw buffer is by definition displayed (find_netrw_buf/buf_to_win are used by the sibling M.refresh at lines 252-254 for exactly that reason), so the window is always visible at this point.

**Auswirkung.** `:bdelete` never closes a window; Neovim loads the alternate buffer into it, or creates a fresh empty one when there is no alternate. M.close() is reached from features/fileops/open_replace/init.lua:183 (`pcall(adapter.close)` -- the "open this file and close the tree" flow), so under the netrw adapter that operation leaves the sidebar window open holding either a stray file buffer or an empty [No Name], instead of closing it. Scope is narrower than the finding implies: adapter = "auto" resolves to neo-tree/nvim-tree, so only users who explicitly select the netrw adapter are affected.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/filetree/features/infra/project_root/init.lua:92` · `find_from` · confidence **medium**

**Befund.** For glob-shaped markers the walk builds `current .. "/" .. marker` and hands the whole string to `vim.fn.glob` -- the raw directory path `current` is interpolated into what glob reads as a pattern.

**Regelbezug.** XP-01 states glob/globpath interpret `~`, `[`, `?`, `*`, `{}` in their argument and that a raw path must never be fed to them; the plugin already knows this (features/search/find_files/init.lua:24 uses lib.nvim.fs.globbable after the earlier XP-01 fix), but this site was not converted. Only the `marker` half is meant to be a pattern; `current` is a filesystem path that walks up from the buffer's directory.

**Auswirkung.** Narrower than the finding claims, but real. "*.rockspec" is the only glob-shaped entry in the default marker list (lines 16-36) and it is tried after .git, .hg, .svn, package.json, Cargo.toml, go.mod, Makefile, CMakeLists.txt and others, so the root is only lost for a project whose sole marker is a rockspec, located under a path containing a glob metacharacter or a Windows 8.3 component. In that case find_from returns nil, M.find (126-134) falls back to fallback="parent" (the file's own directory), and line 113-115 caches that wrong answer under every visited ancestor for the rest of the session -- so find_files, grep_in_dir, git_status, breadcrumbs and the refs scan scope all inherit it until :Filetree root clear. Not a silent-wrong-root for the average user; a permanent one for the affected project.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/filetree/util/path.lua:42` · `M.to_absolute` · confidence **low**

**Befund.** When lib.nvim.cross.fs.expand_path is unavailable, M.to_absolute falls back to `p = vim.fn.expand(p)` on whatever path it was handed.

**Regelbezug.** SEC-34 names lib.nvim.cross.fs.expand_path as the correct primitive precisely because vim.fn.expand runs backtick spans through &shell and honours `%`/`#`/`<cfile>` specials. M.to_absolute is the plugin's general path normaliser and is reached with user-typed paths (features/infra/safety/backup.lua:19 passes `config.backup_dir`, and the module header at lines 66-72 describes raw paths typed by the user flowing through this module).

**Auswirkung.** Latent, not live -- the auditor was right to rate it low and I would rate it lower still. The branch only runs when lib.nvim.cross.fs.expand_path is absent, and that module is present in the installed lib.nvim (E:/repos/lib.nvim/lua/lib/nvim/cross/fs/expand_path exists), so on any current install line 42 is dead and nothing is exploitable today. It would only wake up for someone pinned to an older lib.nvim tag, and even then, on Windows it cannot execute anything (verified: expand() returns "" for a backtick span rather than running the shell), so the exposure is Unix/macOS-only. Worth fixing as a one-line consistency change (route the fallback through the same primitive, or drop the fallback in line with the LUA-01 finding), not worth prioritising as a vulnerability.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/filetree/features/infra/safety/backup.lua:80` · `M.prune` · confidence **low**

**Befund.** `pcall(vim.fn.glob, _dir .. "/*", false, true)` interpolates the raw backup directory into a glob pattern; M.list() at line 97 does the same.

**Regelbezug.** Same XP-01 mechanism as project_root above: `_dir` is a filesystem path (line 19: `config.backup_dir` run through path.to_absolute, else stdpath("data")), not a pattern, and glob will interpret any `~`, `[`, `?`, `{}` inside it. The pcall catches a thrown error but not the silent empty-list return, which is the failure mode the rule describes.

**Auswirkung.** Correct mechanism, but the scope needs stating: the safety feature is in init.lua's DEFAULT_DISABLED (line 50), so it is opt-in, and the stdpath("data") default path contains no glob metacharacter. The bug therefore only reaches a user who enabled safety AND set a backup_dir containing [ ? * { } or resolving to a Windows 8.3 short path. For that user, M.prune() believes the directory is empty so max_backups is never enforced and backups accumulate without bound, while :Filetree safety list reports no backups at all even though the files are on disk -- and M.backup() still reports success, so nothing signals the inconsistency.

> **Abdeckung dieses Laufs.** COVERAGE. 129 Lua modules / ~29,200 LOC under lua/. I read roughly 35 modules in depth (~4,200 lines) and covered the remaining ones by pattern greps across all of lua/ for every concrete construct the rules name (pcall shapes, vim.fn.expand, glob/globpath, os.execute/io.popen/vim.fn.system, vim.cmd string building, __mode, vim.g/b/w, next()-delete loops, vim.NIL, timers/defer_fn, vim.uv callbacks, hot autocmd events, module-level geometry, json/readfile/writefile, buf_delete, os.getenv). Every reported finding was confirmed by reading the surrounding code; no finding rests on a grep hit alone.

WHAT I COULD NOT COVER.
- TESTS/ (~9,900 lines: units.lua 5088, gaps.lua 2574, refs/run.lua 1728, plus cwd_mode/adapter_lines/smoke/menu/sidebar_guard) and scripts/gen_vimdoc_reference.lua were surveyed structurally only. I did not audit the specs themselves against the rule set, so is_test_code is false on every finding. If test-code triage matters for this sweep, that is the gap.
- I did not read features/nav/cwd_mode/init.lua (880 lines), features/fileops/copy_move, rename_batch, create_from_template, refs/providers/{lua,python,ts_js}.lua, or the five adapters end to end -- only the sections the greps pointed at. A rule violation that needs whole-file context in those files could have been missed.
- Report-only: nothing was executed. The behavioural claims in three findings (E348 on `<cword>`, bdelete substituting a scratch buffer, glob returning an empty list on an 8.3 path) rest on documented Vim/Neovim semantics and on the rule text's own measurements, not on a run in this repo.

ALREADY-HANDLED BELEGE, RE-CHECKED AND STILL CLEAN. LUA-48 (util/buffer.lua:55-58 -- the weak table is gone, the comment explains why, the BufDelete invalidation is in place), LUA-06 (config/DEFAULTS.lua, refs/DEFAULTS.lua, nav/cwd_mode/DEFAULTS.lua are pure data; every env lookup in the plugin sits inside a function), XP-01 find_files (now lib.nvim.fs.globbable), XP-04 (size_info uses `du -sk` x1024 with the reasoning in a comment), PERF-93 (breadcrumbs, git_status, preview, size_info all leave the frequent case on a cheap filetype/validity guard), PERF-85/87-91 (refs/apply.lua, refs/scan.lua).

RULES I CHECKED AND FOUND COMPLIANT, worth recording because they are the ones that usually break. ERR-30: refs/apply.lua:161-195 re-reads the line and re-runs rewrite_line against the current text before writing, in both the buffer and the readfile branch. ERR-51: config/init.lua:220 rebuilds from vim.deepcopy(_defaults) on every setup(), so a second setup({}) resets rather than accumulates (the reposcope counter-case). SEC-46: trash/platform.lua:76-79 escapes the backslash before the quote for AppleScript with the reasoning written out, and the PowerShell sites double `'` correctly. SEC-03/SEC-01: every shell-out in the plugin is argv (vim.system / lib.nvim.cross.run_argv); I found no shell string construction. PERF-80: the uv fs_event callback in file_watcher goes through lib.nvim.debounce, and size_info wraps its vim.system callback in vim.schedule_wrap. UI-01: trash confirms the whole batch once and offers per-item confirmation as an explicit choice. SEC-30: the filter fallback uses find(pattern, 1, true) (plain), not a raw regex. SEC-33: cwd_mode's persist_restore (lines 330-350) validates version, mode against MODES, and the pinned directory's existence -- the model the session store does not follow.

ERR-31 note: I found no check-then-create race in a security-relevant place, but features/infra/safety/backup.lua:29 builds its destination from os.date("%Y%m%d_%H%M%S") plus the basename, so two backups of the same filename within one second resolve to the same path and the second overwrites the first with no error. That is a collision, not the TOCTOU race ERR-31 names, so I did not file it as a finding.

---

## images.nvim

**12 Befunde** (4 × high, 1 davon in Testcode). Roh gemeldet: 14.

### `ERR-03` — Explizite Rückgaben

`lua/images/init.lua:597` · `M.orphans.delete_if_confirmed` · confidence **high**

**Befund.** `local ok = pcall(vim.uv.fs_unlink, choice.path)` is used as the success signal for the deletion; `ok` is then branched on to report "deleted:" or "could not delete:".

**Regelbezug.** luv's synchronous `fs_unlink` does not raise on failure — it returns `nil, err, name`. `pcall` therefore returns `true` whether the file was removed or the call failed with EACCES/EBUSY/ENOENT, so the error branch is unreachable and the failure is silent. ERR-03/PRIN-20 require a real success/failure signal, not one that cannot be false. calibration.lua:72-73 shows the author checking a real return value elsewhere, so the pattern is inconsistent within the plugin.

**Auswirkung.** `:Image orphans` reports "deleted: <rel>" unconditionally after a confirmed delete, whether or not the file was removed — a read-only permission, a Windows lock held by an image viewer, or a path already gone all produce the success message. The luv error string that would name the cause is captured into a discarded return slot and never shown. The user reruns `:Image orphans`, finds the same entry still listed, and has nothing pointing at why.

### `ERR-33` — Fenster-/Buffer-Handles bei Ausführung erneut validieren

`lua/images/paste.lua:267` · `insert_link` · confidence **high**

**Befund.** `insert_link` re-validates the captured `buf` handle (nvim_buf_is_valid, modifiable) but then reads the insertion position from window `0` — the window that is current *now* — and applies it to `buf` with `nvim_buf_set_text`.

**Regelbezug.** ERR-33 requires a deferred callback to revalidate its window *and* buffer handles at execution time. Only the buffer is revalidated; the window is not captured at all, so the cursor position used belongs to whatever window happens to be focused when the async capture finally returns. The function's own docstring (lines 240-247) states it reruns "after the clipboard write ... and therefore rechecks the buffer's state" — the window half of that check is missing.

**Auswirkung.** The link's insertion point is read from whatever window is current when the async callback fires, then written into a buffer that window may not be showing. The concrete reachable case is the `ask_alt_text = true` path with ui.nvim installed: `k.input`'s `on_submit` fires from the input float's own context, so `nvim_win_get_cursor(0)` can return the popup's cursor rather than the document window's. If that row is within `buf` the markdown link lands at an unrelated line/column; if it is out of range `nvim_buf_set_text` throws, the `pcall` on line 268 swallows it, and the user is told "could not insert the link" for an image that was saved correctly. The `:Image screenshot` variant the auditor leads with is the weaker case — during the snip Neovim is not focused, so the window usually has not changed.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/images/calibration.lua:102` · `M.as_config` · confidence **high**

**Befund.** `M.load` accepts any JSON object whose top level is a table (line 58, `type(decoded) == "table"`) and `as_config` hands the whole decoded table back as `{ display = values }`, which `config/init.lua:31` deep-merges into the live configuration above the defaults. No field is typed, bounded or whitelisted against the two keys calibration actually writes (`terminal_padding`, `cell_aspect`).

**Regelbezug.** SEC-33 requires every field of a persisted snapshot to be revalidated on load (type, length, count cap). Here a file under `stdpath("data")/images.nvim/calibration.json` becomes an unrestricted overlay on `config.display`.

**Auswirkung.** Every key under `display` is writable from `stdpath("data")/images.nvim/calibration.json` with no type check, no key whitelist and no count cap, overriding the defaults for any option the user did not spell out in `setup()`. The realistic trigger is corruption or hand-editing rather than an attacker — the file is machine-local and only the user writes it — but the consequences are concrete: `display.remote.enabled = true` in that file silently turns hover on a remote link into an outbound network request, undoing the consent default the plugin documents at DEFAULTS.lua:62-68; a `clear_events` that is not a list reaches `nvim_create_autocmd` through `arm_clear`; and a JSON `null` decodes to `vim.NIL` in a field the display path reads as a number.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/images/bindings/usrcmds.lua:28` · `IMAGE_TARGET.validate` · confidence **high**

**Befund.** The `IMAGE_TARGET` argument validator runs `vim.fn.expand(raw)` on the raw, unvalidated `:Image show <target>` argument before any readability check.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user text: a backtick span in the argument is a command substitution through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. This plugin already knows this — `resolve.to_path` (resolve.lua:101-108) carries a long comment explaining exactly why `expand` was removed there and replaced by `lib.nvim.cross.fs.expand_path`, and the rule's own Belege records that fix. The same call was left standing at this second site, which sits *in front of* the `filereadable` gate rather than behind it.

**Auswirkung.** `:Image show` runs its argument's backtick span through `&shell` at validation time, before the plugin has decided the argument is a file at all — the same command substitution the author already removed from `resolve.to_path`. Two non-malicious breakages, both verified: an argument that *begins* with `%` or `#` expands to the current/alternate file and the rest of the string is discarded outright (`expand("#foo.png")` -> `"C:/tmp/current.md"`), so `:Image show #draft.png` silently shows the previous buffer's file; and an argument containing a wildcard that matches nothing expands to `""` (`expand("img*.png")` -> `""`), which then fails `filereadable` and is reported as "'img*.png' is not a readable file or URL". Mid-string `#`/`%` are NOT affected — the auditor's `notes#2.png` example does not reproduce.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/images/browse.lua:76` · `walk` · confidence **medium**

**Befund.** The per-entry loop calls `max_entries()` on every single scanned directory entry; `max_entries` (lines 40-45) does a `pcall(require, "images.config")`, a `config.get()` and two nested table lookups each time.

**Regelbezug.** ERR-01 explicitly places this boundary: `pcall` belongs at the outer edge of a hot loop, not per iteration. The bound this reads is a constant for the whole walk — the configuration cannot change while the loop runs — so hoisting it above the `while` costs nothing and removes up to 20 000 `pcall`+`require`+`get` round trips.

**Auswirkung.** Every scanned entry — up to the 20 000 cap at DEFAULTS.lua:59 — re-derives a bound that cannot change mid-walk, costing a function call, a `pcall`, a `package.loaded` lookup, a `config.get()` and two table indexes each time, on the synchronous path that blocks the editor before the picker opens. The auditor overstates this as "the full config lookup": `config.get()` returns the memoized `current` table (config/init.lua:51-54) and re-merges nothing, so the real cost is tens of milliseconds on a full-cap scan, not a hang. The structural complaint stands — the overhead scales with tree size rather than with images found, which inverts what the cap exists to bound.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`TESTS/run.lua:160` · `run.lua spec loop` · confidence **medium** · _Testcode_

**Befund.** The runner wraps the *execution* of each spec in `pcall(run, H)` but loads it with a bare `dofile(dir .. name)`.

**Regelbezug.** ERR-01 puts `pcall` at filesystem boundaries, and `dofile` is one — it reads and compiles a file. The loop is already written to collect failures and print a per-spec verdict, so the load half is the only place that can abort the whole thing.

**Auswirkung.** A syntax error, a missing spec file, or an error raised at a spec's top level aborts the runner at that spec: every remaining spec in `specs` is skipped, the "N spec(s) failed" summary and the `IMAGES_TESTS_OK` marker never print, and CI sees a raw Lua traceback instead of a line naming the offending spec and the count of others skipped behind it. Test infrastructure only — no runtime impact on the plugin — but it degrades exactly the diagnostic the loop was built to produce.

### `ERR-03` — Explizite Rückgaben

`lua/images/screenshot.lua:183` · `capture_windows` · confidence **medium**

**Befund.** The repeating 600 ms timer calls `read_clipboard_image_async` on every tick with no guard for an outstanding read, and the completion handler calls `stop()` + `callback(...)` from inside whichever read returns — reads that were already in flight when `stop()` ran still complete and take the same branch.

**Regelbezug.** `M.capture`'s contract is documented at lines 228-230 as "`callback(ok, err)` runs once the user is done", and paste.lua's `paste_with_name` is written against exactly that single-shot contract. A PowerShell `-STA` start costs several hundred milliseconds, routinely longer than the 600 ms interval, so two or more reads overlap; when the snip finally lands, every in-flight read sees `current ~= baseline`, and each one re-enters the success path. `stop()` is idempotent, the callback is not.

**Auswirkung.** On Windows, `:Image screenshot` can run `paste_with_name`'s continuation twice. The auditor's primary scenario is wrong about which way it fails: the second handler re-opens and rewrites `out` (lines 186-192) *before* calling `callback(true)`, so the temp file exists again and `move_file` succeeds — the actual outcome is a duplicate markdown link inserted at the cursor plus a second "image saved" notification, not the "could not move the file" error. The secondary observation stands unchanged: a 60 s timeout at a 600 ms interval starts up to 100 PowerShell processes for one screenshot, since nothing throttles a tick against the previous tick's still-running read.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/images/calibration.lua:57` · `M.load` · confidence **medium**

**Befund.** A missing file (line 52), an empty file (line 55) and a file whose JSON fails to decode (line 57-58) all return the same empty `cached` table with no error channel; `M.save` then rebuilds the file from `vim.tbl_deep_extend("force", M.load(true), values)` (line 70) and writes the whole thing back.

**Regelbezug.** ERR-11 requires "empty but ok" to be distinguishable from "empty because broken", and names the load-modify-save collapse as the most frequent real bug class of the fleet sweep: `save()` always writes the *whole* file, so a corrupt read silently becomes a destructive write. The docstring (lines 42-43) declares a missing or unreadable file "not an error case", but that framing only covers the read — it does not make the overwrite non-destructive, and unlike the documented loss-tolerant cases in the rule's Belege there is no statement that the stored measurement is a disposable convenience artifact.

**Auswirkung.** A `calibration.json` truncated by a crash or a full disk is indistinguishable from "never calibrated": `terminal_padding` and `cell_aspect` revert to defaults, images land a cell off, and no message anywhere — not `:Image calibrate`, not `:checkhealth images` — says the file is corrupt rather than absent. The next `:Image calibrate` that saves only one of the two values merges into `{}` and rewrites the file with just that key. The auditor overstates this last step as "destroying the other measurement": the other measurement was already unreadable, so what is actually lost is the chance to notice the corruption and the `.corrupt` backup the rule's own fix pattern prescribes before overwriting.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/images/config/init.lua:31` · `M.setup` · confidence **medium**

**Befund.** `M.setup` merges `defaults`, the stored calibration and the user's `opts` straight into `current` with `vim.tbl_deep_extend("force", …)`. There is no known-key set and no validation pass anywhere in the module — not before the merge, not after.

**Regelbezug.** ERR-50 requires unknown-key validation to run *before* the merge so a typo in a nested option cannot vanish into the default. With no validation at all, every misspelling is swallowed. The plugin has a large nested option surface (`display` alone carries fifteen keys plus four sub-tables) and `config.user_opts()` already exists to keep the unmerged spec around, so the input the check needs is on hand.

**Auswirkung.** A misspelled nested option is accepted silently and has no effect: `display = { max_col = 80 }` or `paste = { ask_altext = true }` merges in as a new key nobody reads, the plugin keeps its default behaviour, and neither `setup()` nor `:checkhealth images` says a word. The user concludes the option is broken rather than misspelled. This is also the missing backstop for the unvalidated calibration snapshot at calibration.lua:102 — a known-key pass over the merged `display` table would have caught foreign keys arriving from that file as well.

### `PERF-42` — Invalidierbar

`lua/images/pixels.lua:41` · `cache` · confidence **medium**

**Befund.** A module-level `cache` table keyed by `path:mtime:size` grows for the life of the session. There is no TTL, no entry cap, no eviction and no `clear()`; the same shape exists in `images.info` (info.lua:31) and neither is reachable from `images.recheck()` or any command.

**Regelbezug.** PERF-42 requires it to be defined when an entry becomes invalid. A changed file does get a new key, but the superseded entry is never removed, and an entry for a file that is deleted or never looked at again is never removed either — so the only defined end of an entry's life is the end of the session.

**Auswirkung.** Both caches grow monotonically for the session with no TTL, entry cap, eviction or `clear()`. `pixels.read` is called from `anchor.draw` (anchor.lua:282) and is documented at pixels.lua:203 as "cheap enough to call on every draw", so a `:Image pickers` run over a large tree, or a picker preview swept across a long file list, adds one permanent entry per distinct file version to each cache. Entries for files that were deleted, or never looked at again, are never reclaimed. This is a slow session-lifetime memory leak rather than a correctness bug — each entry is a small string key plus a two-field table — but nothing short of restarting Neovim reclaims it.

### `PRIN-10` — Keine globalen States

`lua/images/debug.lua:93` · `arm` · confidence **medium**

**Befund.** `arm()` stashes `images.terminal.draw` on the foreign module as `term.__debug_draw` and replaces `term.draw` with a logging wrapper. The comment on line 91 says the original is "put back by `disarm`" — no `disarm` function exists anywhere in `lua/` (grep confirms only the three `__debug_draw` sites), and nothing else restores `term.draw`.

**Regelbezug.** PRIN-10 requires state to live module-internally with access through getters/setters; this reaches into another module's public table, mutates it permanently, and leaves the reader a restore path that was never written. The accompanying `log` table (line 39) is appended to on every draw and is only ever reset inside `arm()` (line 158), never after printing.

**Auswirkung.** One `:Image debug report` permanently rewires `images.terminal.draw` for the rest of the session — every hover, gallery tile, picker preview and zen draw then pays a full `nvim_list_wins` + per-window `nvim_win_get_config` scan plus a config read, and appends an unbounded entry to `log`. The restore path the comment on line 91 promises does not exist, `M.report`'s second invocation only prints, and `armed` is never cleared, so the only way back is restarting Neovim. Severity is bounded by the fact that a user has to run a debug command to reach it.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/images/browse.lua:116` · `M.roots` · confidence **medium**

**Befund.** The `path` scope resolves its argument with `vim.fn.fnamemodify(vim.fn.expand(arg), ":p")`. `M.roots` is reached both from `:Image pickers path <dir>`/`:Image compare path <dir>` and from the public Lua API `require("images").browse(scope, arg)` / `.compare(scope, arg)`, which applies no validation of its own.

**Regelbezug.** Same rule as the usrcmds finding: `vim.fn.expand` on caller-supplied text runs backtick spans through `&shell` and honours `%`/`#`/`<cfile>` as specials. Only the command path could plausibly have been filtered by the composer's `DIR` type; the Lua entry points documented in init.lua:631-638 and 690-696 reach this line with whatever string the caller passes.

**Auswirkung.** A host plugin or user mapping that forwards a value into `images.browse("path", value)` or `images.compare("path", value)` hands that value to Vim's filename expansion, where a backtick span executes as a shell command. The auditor's `#`/`%` claim does not apply here: I verified mid-string `#` and `%` are not expanded, and a directory argument beginning with `%` or `#` (the only form that does expand) would then fail the `isdirectory` check on line 117 rather than silently scanning elsewhere. The realistic consequence is therefore the command substitution alone, not a wrong-tree scan.

> **Abdeckung dieses Laufs.** Coverage: I read every one of the 38 modules under lua/ in full (8955 LOC), plugin/images.lua, and TESTS/run.lua. .claude/, .git/, .deps/ and doc/tags were ignored as instructed.

What I could NOT verify, and why:
- lib.nvim internals are outside this plugin and were not read: `lib.nvim.bindings.usercmd.composer` (what its FILE/DIR/STRING validators do with an argument before the route's `run` sees it), `lib.nvim.cross.fs.expand_path`, `lib.nvim.cross.executable`, `lib.nvim.window.make_scratch`, `lib.nvim.notify`, `lib.nvim.bindings.autocmd`/`keymap`, `lib.nvim.fs.read`/`mkdirp`. This directly bounds two findings: the browse.lua:116 SEC-34 site is rated medium rather than high precisely because I could not confirm whether the composer's DIR validator already neutralises the command path (the Lua-API path is unaffected either way), and the same uncertainty applies to debug.lua:215/291, which expand a FILE-typed argument — I left those out of the findings for that reason.
- Nothing was executed. No Neovim, no test suite, no `magick`/`tesseract`/`curl`. Every finding is from reading; runtime-only claims (does a given terminal actually scroll, does PowerShell actually exceed 600 ms on the reporter's machine) are reasoned from the code and the plugin's own measured comments, not observed.
- TESTS/*_spec.lua: I listed all 33 specs and checked their `require` paths against the real directory casing for XP-06 (all match, including `images.config.DEFAULTS`), but I did not read the specs line by line. Test-side findings beyond run.lua:160 may exist.
- CMT-16: docs/map/ is generated by documentation.nvim and doc/ holds generated vimdoc plus tags. I did not diff generated output against its renderer, so I cannot say whether any hand edit has drifted into a generated file — that check needs the generator, not a read.
- Rules I checked and found clean, so they produced no finding rather than being skipped: ERR-60 (I enumerated all 39 `and … or` sites; every `b` is a non-falsy literal, a string, or a number where 0 is truthy in Lua — none can fall through), ERR-62 (all six `pcall` sites pass a function or an anonymous wrapper, never `pcall(f(args))`), SEC-01/03 (every subprocess in the plugin is an argv array through `vim.system`; there is no shell string construction and no `io.popen`/`os.execute` anywhere), SEC-46 (paste.lua:73 embeds the output path in a PowerShell *single-quoted* literal and doubles `'`, which is the complete escape for that quoting form — backslash is not an escape character there), SEC-35 (all four `vim.cmd` calls take static strings), LUA-48 (no `__mode` in the repo), LUA-17 (`vim.g` holds only the boolean load guard), PERF-92 (all geometry is computed inside functions; zen re-derives on WinResized/VimResized), PERF-93 (the only hot-event handler is the `clear_events` autocmd, armed with `once = true` per draw), PERF-80 (every `vim.system` callback is wrapped in `vim.schedule` before touching the API, and the screenshot timer uses `vim.schedule_wrap`), LUA-87 (the calibration file is correctly outranked by `setup()` opts), PERF-62/82 (the one timer stops and closes, guarded by `is_closing`), ERR-20/PRIN-27 (the capability check fails open — it warns and draws anyway), UI-01 (`:Image orphans` confirms before the single delete it performs).
- One thing I judged too speculative to file: `images.convert.to_format` (convert.lua:494) builds its output path as `fnamemodify(path, \":r\") .. \".\" .. format` without validating `format` against `M.target_formats()`. The `:Image convert` route constrains it with an `enum` (usrcmds.lua:203), but the public `require(\"images\").convert(format, path)` does not, so a caller passing a `format` containing path separators would write outside the source directory. The code fact is confirmed; whether any caller can supply hostile input there is not, so it is noted here rather than reported as a SEC-42 finding.

---

## pickers.nvim

**12 Befunde** (4 × high). Roh gemeldet: 13.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/pickers/smart/search.lua:113` · `M.collect` · confidence **high**

**Befund.** Both spawn results are consumed as `if ok and res and res.stdout then` (lines 113 and 134). `res.code` is never inspected, and `M.collect` returns `files, greps` with no error channel — a failed, timed-out or partially-killed `fd`/`rg` run is indistinguishable from "this query matched nothing".

**Regelbezug.** ERR-11 requires a function whose result can legitimately be empty to make "empty but ok" distinguishable from "empty because something broke". `vim.system(...):wait(timeout)` returns on timeout with a non-zero code and whatever stdout had accumulated, so the 3000 ms default (config/DEFAULTS.lua:193) silently yields a truncated result set that is then ranked and capped as if it were the complete one. `pickers.smart.query` and every engine adapter above it have no way to tell the difference.

**Auswirkung.** On a large root, a bad glob from `find.exclude`, a permission error, a killed-at-timeout run, or simply a machine without `fd`/`rg` installed, `pickers.smart` ranks and caps a partial result set as if it were complete and shows a short or empty list. The user reads that as "there are no more matches". No notify, no prompt-title marker, and `:checkhealth pickers` does report whether the CLI tools exist but says nothing about a run that was cut off. Callers above (`pickers.smart.query` and every engine adapter) have no return value to branch on.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/pickers/bindings/collections.lua:16` · `M.register` · confidence **high**

**Befund.** `util.to_pascal(coll.name)` turns a user-supplied collection name into a command name and hands it straight to `util.usercmd` -> `lib.nvim.bindings.usercmd.create` -> `vim.api.nvim_create_user_command`, with no check that the result is a legal Ex-command name. `config/init.lua`'s `normalise_collection` (line 31-46) only validates that `name` is a non-empty string.

**Regelbezug.** ERR-22 says a single invalid config value must degrade to its default rather than abort the whole plugin initialisation. lib.nvim's `usercmd.create` calls `nvim_create_user_command` raw (no pcall — verified in lib.nvim/lua/lib/nvim/bindings/usercmd/init.lua), so an illegal name throws. `to_pascal` only uppercases and strips `_`, so `"my-notes"` -> `"My-notes"` and `"notes v2"` -> `"Notes v2"`, both of which Neovim rejects (command names must be alphanumeric and start with an uppercase letter).

**Auswirkung.** `setup({ collections = { { name = "my-notes", dir = … } } })` throws `Invalid command name: 'My-notesFiles'` out of `bindings.collections.register`, out of `bindings.setup`, out of `pickers.setup()`. Because the collections loop (bindings/init.lua:24-26) sits before `pickers.mappings.apply(cfg)` (line 30) and `pickers.keys.patch(cfg)` (line 37), the declarative `mappings` surface and every in-picker key are never registered, and lazy.nvim reports a plugin-load failure instead of naming the one bad collection name. Any collection already registered earlier in the loop stays half-installed. Note the blast radius is narrower than the auditor implied: only names with characters nvim actually rejects (e.g. `-`, `.`, leading lowercase is auto-fixed by `to_pascal`) trigger it — a space does not.

### `ERR-33` — Fenster-/Buffer-Handles bei Ausführung erneut validieren

`lua/pickers/integrations/images/adapters/snacks.lua:91` · `M.preview_fn / on_done -> fallback` · confidence **high**

**Befund.** The `on_done` callback passed to `images.preview()` captures the snacks preview context `ctx` and, when the draw failed, calls `fallback()` which does `require("snacks.picker.preview").file(ctx)` — writing into `ctx.preview` / `ctx.win` without re-validating either handle at execution time.

**Regelbezug.** ERR-33 requires every deferred callback to re-validate its window and buffer handles when it runs, not only when it captured them. For a PDF entry images.nvim rasterizes asynchronously (`images/integrations/picker.lua:261` -> `images.pdf.page_png(..., cb)`), so this callback fires hundreds of ms later. The only guard pickers has is the `generation` ticket in `integrations/images/init.lua:188` (`while_current`), and that ticket is only bumped by `M.preview` or `M.clear`. The telescope adapter closes this hole because its previewer `teardown` calls `images.clear()` (adapters/telescope.lua:118-120); the snacks adapter has no close hook at all, so a closed picker leaves the ticket current and the callback un-silenced.

**Auswirkung.** Snacks picker + images.nvim + a PDF page not yet rasterized (needs pdfport.nvim/pdftoppm), picker closed mid-render: images.nvim fires `on_done(false, …)`, pickers' ticket still matches, and `fallback()` runs `snacks.picker.preview.file(ctx)` against the destroyed preview. `ctx.buf` is a live metatable proxy for `self.win.buf` (core/preview.lua:193-200) and snacks' `Win:close()` sets `self.win = nil` / `self.buf = nil` and `nvim_buf_delete`s the scratch buffer (win.lua:542-577), so `vim.bo[ctx.buf].buftype = ""` raises `Invalid 'name': Expected Lua string` (verified in nvim 0.12.2; `Invalid buffer id: N` when the buffer number survives). The error escapes into images.nvim's rasterizer callback as a stray unhandled error with no connection to anything the user did. Trigger window is narrow (first, uncached page only — afterwards the page is on disk and the draw is synchronous), but the missing re-validation is exactly what ERR-33 requires and what the telescope adapter already does via `pcall` at lines 101/105 plus its teardown.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/pickers/bindings/util.lua:21` · `M.usercmd / M.map` · confidence **high**

**Befund.** lib.nvim is declared as a hard dependency in most of the tree (bare module-level `require` in config/init.lua:5-6, command/composer.lua:15, bindings/usrcmds.lua:38, bindings/keymaps.lua:19, engines/*.lua, sources/*.lua) but as a soft one here and in bindings/autocmds.lua:26 and engines/when_loaded.lua:66, each with a `pcall(require, ...)` plus a raw-API fallback and a comment claiming it exists "so pickers still works standalone".

**Regelbezug.** LUA-01 requires a plugin to pick hard or soft and hold it. `plugin/pickers.lua:14` requires `pickers.command.composer`, which bare-requires `lib.nvim.bindings.usercmd.composer` at module level, so the plugin cannot even load without lib.nvim. Every `pcall`-plus-fallback branch is therefore unreachable, and health.lua contradicts itself about it: line 9 calls lib.nvim "a hard dependency here", line 31 claims the bindings/util.lua aliases "still degrade gracefully without lib.nvim".

**Auswirkung.** Documentation and dead-code drift, not a runtime fault: nothing misbehaves today, because lib.nvim is in fact always present. The concrete cost is that bindings/util.lua:35, bindings/autocmds.lua:35 and engines/when_loaded.lua:75 are unreachable branches a maintainer keeps paying for, and health.lua:29-31 actively tells a reader a standalone mode exists. Anyone who removes lib.nvim gets a module-not-found abort from plugin/pickers.lua:14 (and from `require("pickers.config")`), not the degraded mode the comments promise. The auditor's impact statement is accurate; I would only downgrade the severity from a behavioural bug to a maintenance/documentation defect.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/pickers/history/init.lua:31` · `M.dir` · confidence **medium**

**Befund.** `M.dir` calls `vim.fn.mkdir(dir, "p")` with no pcall, and is called from `telescope_opts`, `fzf_path` and `fzf_opts` — i.e. on every picker open while `history.enabled` is true (engines/fzf.lua:128, engines/telescope.lua:84).

**Regelbezug.** ERR-01 makes pcall mandatory at system boundaries, and directory creation on a user-supplied path (`history.dir`, accepted verbatim by config/init.lua:73 after `expand_path`) is one. `vim.fn.mkdir` raises E739 on failure, and there is no hot-path exemption here: this runs once per picker, not per iteration.

**Auswirkung.** With `history = { enabled = true, dir = <unwritable> }` — a read-only mount, a path whose parent is a file, a Windows path or drive the user has no rights to — every picker open throws E739 before the picker appears, on both the telescope and fzf-lua paths. The error names `vim.fn.mkdir` and a path fragment rather than the `history.dir` option that caused it, and `:checkhealth pickers` never probes the directory, so there is nothing that points at the real cause.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/pickers/sources/collection.lua:27` · `list_subdirs` · confidence **medium**

**Befund.** `list_subdirs` returns a bare `{}` for three different situations: the directory does not exist or is not a directory (line 25), `vim.uv.fs_scandir` failed (line 28), and the directory is genuinely empty of matching subdirs. The error from `fs_scandir` is discarded entirely — only its handle is bound.

**Regelbezug.** ERR-11 requires a function whose result can legitimately be empty to return "empty but ok" distinguishably from "empty because broken". `M.list_subdirs` is deliberately exported (lines 55-63) "for callers that need the raw path list without going through the engine sub-picker (e.g. command-line completion)", and those callers — sources/repos.lua:34 and sources/plugins_book.lua:36 — get no way to tell the cases apart.

**Auswirkung.** A collection directory that exists but cannot be scanned (permissions, a broken mount or network share, an I/O error) reaches `M.get`'s `#subdirs == 0` branch and reports "[name] no subdirs with prefix 'x' found in: <dir>" (collection.lua:106-112) — a message that diagnoses the wrong problem and sends the user looking at their `prefix`/`only_git`/`exclude` settings. Through `M.complete` in repos.lua and plugins_book.lua the failure is even quieter: `:RepoFiles <Tab>` simply offers nothing, with no message at all, indistinguishable from "you have no repos".

### `ERR-50` — Config-Validierung vor dem Merge

`lua/pickers/config/init.lua:120` · `M.apply` · confidence **medium**

**Befund.** `M.apply` reads a fixed list of known fields one by one and silently ignores everything else. There is no unknown-key detection anywhere — no KNOWN_OPTS set, no "did you mean" pass, and nothing reported to `:checkhealth`. The only exception is the two removed keys `selected_index`/`experimental`, which get a dedicated warning at lines 172-178.

**Regelbezug.** ERR-50 requires config validation to run before the merge precisely so a typo in a nested option cannot disappear into the default unnoticed. Here `setup({ engien = "fzf" })` is dropped without a word; so is `display = { path_shortern = true }` (only `path_shorten` is read, line 196) and `images = { enabeld = false }` (line 202). Worse, the deep-merged sub-tables absorb typos into the live config: `smart = { limmit = 500 }` lands in `cfg.smart` via `vim.tbl_deep_extend` at line 192, is never read, and the real `limit` keeps its default.

**Auswirkung.** Any mistyped option — top-level (`engien`), nested-and-dropped (`display.path_shortern`, `images.enabeld`), or nested-and-absorbed (`smart.limmit`, `find.hiden`) — produces default behaviour with zero feedback: no notify at setup, nothing in `:checkhealth pickers`. The absorbed variety is the nastier half, because the wrong key sits in the live config table and would even survive a `vim.inspect(cfg)` inspection while doing nothing. The author already treats this class as worth reporting (the `selected_index` warning), so the general case is an acknowledged gap rather than a design choice.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/pickers/config/init.lua:121` · `M.apply` · confidence **medium**

**Befund.** `M.apply` starts with `local cfg = M.get()` — the module-level `_cfg` singleton — and mutates it in place. It never rebuilds the options from a fresh DEFAULTS copy, so each `setup()` call accumulates on top of whatever the previous one left behind.

**Regelbezug.** LUA-87's standard merge mechanism is `M.options = vim.tbl_deep_extend("force", {}, defaults, user or {})` — options formed anew from the defaults plus this call's user table. The rule names exactly this counter-case for reposcope.nvim ("setup() merges into the current options table instead of a DEFAULTS copy — accumulates, a second setup({}) resets nothing"); pickers.nvim has the identical shape, and the Belege footnote does not list pickers for it.

**Auswirkung.** Two `setup()` calls in one Lua state compose instead of the second one winning cleanly: `setup({ engine = "fzf", find = { no_ignore = true } })` followed by `setup({})` leaves `engine = "fzf"` and `no_ignore = true` in place. Reachable when configuration is split across two lazy specs, when a spec's `config` block and a manual `require("pickers").setup()` both run, or on a config re-source that does not clear `package.loaded`. I would soften the auditor's hot-reload framing: a reload that re-requires the module resets `_cfg` along with it, so the realistic trigger is two setup() calls within one Lua state, where the result is order-dependent with no way to reset to defaults short of restarting Neovim.

### `LUA-90` — Ein globales `setup()` hat genau einen Besitzer

`lua/pickers/keys/adapters/telescope.lua:90` · `M.patch` · confidence **medium**

**Befund.** `require("telescope").setup({ defaults = { mappings = ... } })` is called from pickers.nvim. The same pattern appears at keys/adapters/fzf.lua:87 (`fzf.setup({ keymap = { builtin = ... } }, true)`) and history/init.lua:88 and :95. `keys.enable` defaults to true and `bindings/init.lua:37` calls `keys.patch` unconditionally, so this runs on every install by default, including via the VimEnter fallback when the user never called `setup()`.

**Regelbezug.** LUA-90 says a foreign plugin with one global `setup()` belongs to the spec that installs it, and no second module calls it too. pickers.nvim explicitly does not own telescope or fzf-lua in the default model — plugin_spec.lua:192-194 and docs/installation.md:110-113 both state that pickers.nvim "never calls Snacks.setup()/telescope.setup()/fzf-lua.setup() for you, so your own engine config ... is never fought over by a second competing setup() call". Three of the four call sites make that statement untrue.

**Auswirkung.** Because pickers' `telescope.setup()` call is always the second one, `first_non_null` hands telescope pickers' own `{ i = {...}, n = {...} }` table and it REPLACES `config.values.mappings` wholesale — the user's entire `defaults.mappings` block from their own telescope.setup() is discarded, in every telescope picker, including ones pickers.nvim never opens. Telescope's built-in `default_mappings` survive (separate table, mappings.lua:130), so the symptom is "my custom telescope keybinds silently stopped working" rather than a broken picker. On the fzf-lua side `fzf.setup({ keymap = { builtin = … } }, true)` deep-merges, so only the two keys pickers binds by default — `<PageDown>`/`<PageUp>` (keys/init.lua:95-96) — overwrite the user's own entries. Either way the plugin does exactly what its installation docs promise it never does.

### `LUA-93` — Jedes Plugin trägt seinen eigenen Lazy-Trigger

`lua/pickers/plugin_spec.lua:78` · `M.plugin_spec` · confidence **medium**

**Befund.** Both generated specs (the no-engine one at lines 76-83 and the pair at lines 104-119) carry `dependencies` and `config` but neither `lazy = false` nor any of `cmd`/`ft`/`event`/`keys`.

**Regelbezug.** LUA-93 requires every spec that should be lazy to carry its own trigger, and a `lazy = false` with a real reason to carry that reason in the spec. This plugin's own documentation treats the flag as mandatory: `lua/pickers/init.lua:11` writes `lazy = false, -- required: load at startup`, and docs/installation.md:43 and :62-66 repeat it ("Without a load trigger lazy.nvim never executes `config`, so nothing gets registered"). `plugin_spec()` is advertised as the ready-made spec list and omits exactly that.

**Auswirkung.** Only under `lazy.setup({ defaults = { lazy = true } })`: the spec returned by `plugin_spec()` resolves to lazy with no trigger, lazy.nvim never loads it, `config` never runs, and the user gets no `:Pickers`, no keymaps, no compat commands and no error explaining why. Under lazy.nvim's own default (`defaults.lazy = false`) the generated spec loads at startup and works, so this is conditional rather than universal — but it means the hand-written spec in the docs is correct and the generated one silently is not, and with `own_engine = true` the engine spec at lines 104-110 has the same gap.

### `PERF-42` — Invalidierbar

`lua/pickers/sources/drives.lua:55` · `_cache` · confidence **medium**

**Befund.** `_cache` holds the discovered mount points / drive letters for the whole session. `get_roots` returns it whenever it is set (lines 154-157), and nothing in the module ever clears or re-reads it — there is no TTL, no invalidation event and no `clear()`.

**Regelbezug.** PERF-42 requires it to be defined when a cache entry becomes invalid. The comment at line 54 ("drives don't change during a session") states the assumption but is not a mechanism, and the assumption is false on the platform this module goes to the most trouble for: removable drives and network shares appear and disappear while Neovim is running.

**Auswirkung.** After the first `:Pickers drives` (or any `:Pickers system` with no path token, which routes through `drives.roots`), a USB drive plugged in or a share mounted later stays invisible for the rest of the session, so a systemwide search silently skips it with no indication that its root list is stale. The reverse also holds: an unmounted drive stays in the list and its picker opens on a path that no longer exists. Restarting Neovim is the only remedy, and because nothing resets `_cache`, spec suites carry the same value across tests.

### `PRIN-25` — Eingaben validieren

`lua/pickers/engines/fzf.lua:339` · `M.pick_item` · confidence **medium**

**Befund.** In the no-preview branch (`has_preview` false, i.e. no item carries `file`), `opts.items` is handed to `fzf.fzf_exec` unchanged even when the entries are `Pickers.Item` tables, and the selection handler at line 350 returns `selected[1]` — fzf's raw output line, a string — to `opts.on_select`. The preview branch two blocks below does it correctly, mapping back through `by_line` at line 384.

**Regelbezug.** PRIN-25 requires arguments to be checked before being worked with, especially before a foreign-API call. Here nothing narrows `opts.items` to the string form fzf-lua's contents table expects, and nothing maps the selected line back to the original entry. That also breaks the contract the public type states verbatim (`lua/pickers/engines/@types/init.lua:47-49`): "`on_select` is always called with the EXACT entry that was in `items` (string in, string out; table in, that same table out), never a re-parsed copy". `file` is optional on `Pickers.Item` (line 52), so a table-only, file-less list is a legal call.

**Auswirkung.** An external consumer that passes table items with no `file` — the case the public type explicitly sanctions, and the type doc names filetree.nvim's template picker — does not get a re-parsed string back: on current fzf-lua the call raises `assertion failed!` out of `fzf-lua/core.lua:101` and propagates out of `M.pick_item` (the only pcall there guards the `require`), so no picker opens at all. On any fzf-lua build whose contents path tolerates the tables, the second defect takes over: `on_select` receives fzf's raw line instead of the caller's table, breaking the identity contract the type states verbatim. Both stem from the same missing narrowing of `opts.items` before the foreign call, and both are invisible until someone switches engines, since telescope and snacks handle the identical call correctly.

> **Abdeckung dieses Laufs.** Coverage: I read every file under lua/ (74 modules, ~8088 lines) plus plugin/pickers.lua, README.md and docs/installation.md. I did NOT read TESTS/pickers_spec.lua in full (3919 lines) — I read its bootstrap/harness header and grepped it for ERR-62 (`pcall(f(args))`), assertion-swallowing pcalls and module-path casing (XP-06). Nothing surfaced worth reporting, but a line-by-line pass on the spec was out of budget, hence zero test-code findings rather than a clean bill. .claude/, .git/, .deps/ and doc/tags were ignored as instructed.

Rules I checked but found clean, so they are neither findings nor listed as inapplicable: ERR-62 (all nine pcalls use the `pcall(fn, ...)` or anonymous-wrapper form), ERR-51 (config.get deep-copies DEFAULTS), ERR-53/ERR-54 (config.get returns the live `_cfg` by reference, but I grepped every consumer — nobody mutates or in-place-sorts a config sub-table, so the ERR-54 github_stats failure mode is absent here), ERR-60 (all eight `a and b or c` sites were read; each `b` is provably truthy at that point), LUA-06 (already fixed — `repos_dir` resolves in config/init.lua:22, DEFAULTS.lua is pure data, matching the LUA-06 Belege), LUA-92 (engines/when_loaded.lua reads `package.loaded[module]` and only falls back to a lazy-load autocmd — textbook compliant), PERF-80 (both fast-event callbacks, snacks.lua:266 and drives.lua:48, are vim.schedule-wrapped), PERF-93 (no handler on a hot event anywhere), SEC-03/SEC-30/SEC-34/SEC-35 (all shell-bound values go through argv or `vim.fn.shellescape`; the one `vim.cmd` string is `fnameescape`d; `vim.fn.expand` is used only on the literal `"~"`; user paths go through `lib.nvim.cross.fs.expand_path`), XP-01 (no `glob`/`globpath` at all), XP-06 (every `require` path matches its lowercase directory).

Two judgment calls I decided against reporting: (1) `integrations/images/init.lua:211` calls `images.clear()` without the shape guard the same module applies to `is_previewable` and `is_pdf` — real inconsistency, but it only fires against an images.nvim old enough to lack `clear`, which I could not confirm ever shipped. (2) `pickers.refine` (252 lines plus its @types module) has zero callers anywhere in lua/, plugin/ or TESTS/ — it is a documented public API (docs/FEATURES/REFINE.md), so no rule in this set covers it, but it is worth a maintainer's attention.

PERF-84 (`smart/search.lua`'s blocking `vim.system():wait()`) and LUA-06 are both already named for pickers.nvim in the Belege footnotes and the code still matches what those footnotes describe as the fixed state, so I did not re-report them.

---

## runtime-analysis.nvim

**12 Befunde** (5 × high). Roh gemeldet: 13.

### `ERR-03` — Explizite Rückgaben

`lua/runtime-analysis/graphql.lua:136` · `M.resolve` · confidence **high**

**Befund.** On an unparseable variables block `M.resolve` returns `request, "GraphQL variables block is not valid JSON"` — a truthy request plus an error — but both call sites (`bindings/usrcmds.lua:315-319` via `resolve_request_shape`, and `bindings/usrcmds.lua:698-703` in `do_export`) test `if not resolved then ... return end`.

**Regelbezug.** ERR-03 requires a relevant function to report failure so the caller can act on it; here the error object is structurally unreachable because the first return value is never nil on the failure path. The function's own `@return` annotation (line 124) declares the request as non-optional, so the callers are written against a `nil, err` contract the function does not have.

**Auswirkung.** A typo in a GraphQL request's variables JSON is completely silent: the written error message never reaches the user, the `{"query":…,"variables":…}` envelope is never built, and the raw query text plus the still-attached `X-Request-Type: GraphQL` header is sent to the server as an ordinary body. The user sees an opaque server 400 with nothing pointing at the variables block. `:RA export` yanks the same wrong curl command.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/runtime-analysis/env.lua:64` · `read_env_file` · confidence **high**

**Befund.** `read_env_file` returns `{}` both when the file is absent (checked at line 61) and when `json.read(path)` fails to decode it. `lib.nvim.fs.json.read` returns `nil, err` on a decode failure (lib.nvim/lua/lib/nvim/fs/json/init.lua:30-37); the second return value is discarded here by `return decoded or {}`.

**Regelbezug.** ERR-11 requires 'empty but fine' to be distinguishable from 'empty because broken': file missing → empty table, no error; file corrupt → empty table *with* an error message. Both collapse to the same value here.

**Auswirkung.** A JSON syntax error in `http-client.env.json` or `http-client.private.env.json` is indistinguishable from the file not existing. Every environment disappears: `:RA send` on a request using `{{baseUrl}}` reports "no environment is selected ... (available: none defined)", `:RA env` completion offers nothing, and `:checkhealth` tells the user to create a file that already exists. No message anywhere mentions the decode failure, so the user is pointed away from the actual cause.

### `ERR-33` — Fenster-/Buffer-Handles bei Ausführung erneut validieren

`lua/runtime-analysis/bindings/usrcmds.lua:279` · `check_assertion` · confidence **high**

**Befund.** `check_assertion` builds a quickfix item with `bufnr = source_bufnr`, a handle captured in `send_current_buffer` at line 364 and used later from inside `runner.run_async`'s `vim.schedule`d callback (call sites at lines 490 and 502). The handle is never revalidated with `nvim_buf_is_valid` at execution time.

**Regelbezug.** ERR-33/LUA-13 require every `vim.schedule`/`vim.defer_fn`-deferred callback to revalidate its buffer and window handles when it runs, not only when it captures them. An HTTP round trip is exactly the window in which the request buffer can be wiped.

**Auswirkung.** Send a request block carrying `@expect status N`, then WIPE the request buffer (`:bw!`, or any buffer with `bufhidden=wipe`) before the response arrives -- `:bd!` alone does not reproduce this. On a status mismatch the response is rendered first, then `list.qf` -> `vim.fn.setqflist` raises an uncaught `Vim:E92: Buffer N not found` out of the scheduled callback; the `notify.error("✗ expect status ...")` on line 284 never runs, so the assertion verdict is replaced by a raw E92 with no connection to the assertion.

### `PERF-93` — Heißes Event: billiger Guard **oder** Throttle, nie ungeschützt

`lua/runtime-analysis/statusline.lua:148` · `M.status` · confidence **high**

**Befund.** `M.status()` / `M.lualine_component()` — documented in docs/statusline.md for lualine, heirline and the native `set statusline+=%{...}` — calls `telemetry.known_namespaces()` on every invocation, which runs `store.namespaces()` (`uv.fs_scandir` of the telemetry cache dir, one `fs_scandir_next` per file, plus `table.sort`, telemetry/store.lua:162-185). For each namespace with a live instance, `entries_for` (line 125) then calls `inst.report({since="1d"})`, which does `vim.deepcopy(base)` + `store.merge` (telemetry/init.lua:902-905) and a full `report.build` that re-sorts every fingerprint bucket and every entry.

**Regelbezug.** PERF-93 requires a handler on a hot path to either leave the common case cheap or be throttled; a statusline component is re-evaluated on nearly every redraw. The module recognises the problem for the disk *read* (5-second TTL cache, lines 43-46, 86-89) but the directory scan and the live-instance report path have neither a cache nor a throttle nor a cheap early-out.

**Auswirkung.** With telemetry running and the component wired in, every statusline redraw performs a synchronous directory scan of the telemetry cache dir plus, per live instance, a full `vim.deepcopy` + re-merge + re-sort of the entire accumulated dataset (every wrapped-function key, every day bucket, every argument/error/caller fingerprint) -- all to produce one of three emoji. Cost grows with how long telemetry has been collecting and with how many plugins are instrumented. The module's own 5s cache proves the author saw the problem for the disk read but left the scandir and the live-instance report path unguarded.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/runtime-analysis/telemetry/command.lua:1084` · `:RATelemetry flamegraph` · confidence **high**

**Befund.** The output path a user types as the second argument of `:RATelemetry flamegraph <path>` (`rest = args.fargs[2]`, set at line 846) is passed straight to `vim.fn.expand(rest)` before `fnamemodify(..., ":p")`.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user/buffer text: a backtick span in the argument is a command substitution through `&shell`, and `%`/`#`/`<cfile>` are Vim specials. Nothing else in the plugin uses `expand()` on caller text, and `lib.nvim.cross.fs.expand_path` (the sanctioned `~`/env-only expansion) is not used anywhere in this repo.

**Auswirkung.** Two real effects, one narrower than claimed. (1) Shell execution is reachable only when the whole argument is a backtick span -- `:RATelemetry flamegraph `whoami`` runs the shell, then fails with `UserCommand 'RATelemetry' failed: Vim:E282` and writes no flamegraph; `` `whoami`.svg `` does NOT (verified). (2) The everyday effect is silent path rewriting: an output path containing `%`, `#` or an unmatched `*` expands to the empty string, `fnamemodify("", ":p")` turns that into the cwd, and the SVG is written to a path the user never named while `notify.info("wrote " .. path)` reports that other path as success.

### `ERR-02` — Type Guards & Literal Checks

`lua/runtime-analysis/init.lua:64` · `M.open_request` · confidence **medium**

**Befund.** `M.open_request(lines)` — documented at lines 17-26 as "this plugin's one public integration surface for another plugin to build on" — applies `lines = lines or {…}` and then indexes `#lines[1]` for the cursor position without checking that `lines` is a table, that it is non-empty, or that its entries are strings.

**Regelbezug.** ERR-02 requires `type(...)`/`nil` checks before API access, especially on a boundary; PRIN-25 requires arguments to be validated before being worked with. `lines or {…}` only substitutes for nil — an explicitly passed `{}` is truthy and passes straight through.

**Auswirkung.** A consumer passing an empty table -- a documentation.nvim Endpoints route with nothing resolvable to pre-fill, or any caller that built its lines in a loop that produced no rows -- gets `:enew` run, buftype/filetype set, and then a raw `attempt to get length of a nil value` from inside runtime-analysis. The user is left standing in a stray scratch `acwrite` buffer with an error that names neither the calling plugin nor the empty argument. A non-string element fails one line earlier, at 60, with the same outcome.

### `ERR-03` — Explizite Rückgaben

`lua/runtime-analysis/multipart.lua:168` · `M.resolve` · confidence **medium**

**Befund.** After a successful `io.open(path, "rb")`, `local content = f:read("*a")` is appended with `out[#out + 1] = content` without checking for nil. `f:read("*a")` returns nil on a read failure (notably when `path` is a directory, which `io.open` accepts on POSIX), and appending nil to a table is a no-op.

**Regelbezug.** ERR-03 forbids silent failures in a function that otherwise reports errors explicitly: the open failure one line up returns `nil, err`, but the read failure produces no error and no trace.

**Auswirkung.** On POSIX, a `< ./path` reference pointing at a directory (io.open succeeds, read returns nil), or any genuine mid-read IO error on either platform, makes that part's content vanish from the reassembled body while the surrounding boundary lines stay. `M.resolve` reports success with a nil error, so `:RA send` ships a structurally broken multipart body and the resulting server-side rejection looks like a server problem. The narrow trigger makes this lower-severity than the finding implies, but the silent-success return is a genuine ERR-03 break in a function that reports its other failure explicitly.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/runtime-analysis/view.lua:84` · `M.show` · confidence **medium**

**Befund.** `vim.cmd(opts.split or "vsplit")` executes the `split` config value as a raw Ex command. `config/validate.lua` only checks that the *keys* of `opts` are known (init.lua:70-75); no value validation exists for `split` anywhere, and `health.lua` never inspects the configured value.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and to be surfaced through `:checkhealth`. Here it degrades to nothing: the value is handed to `vim.cmd` unchecked, and the health check reports on curl, lib.nvim, telemetry, history, env files, usage and optional tools but never on the option values themselves.

**Auswirkung.** `setup({ split = "vsplt" })` is accepted silently. The first `:RA send` of the session reaches `view.show` for the "→ sending ..." placeholder, `find_window` finds no response window, and `vim.cmd("vsplt")` fails with `E492: Not an editor command: vsplt`, surfaced as `UserCommand 'RASend' failed: Vim:E492: ...`. The request is never dispatched, and because the response window is never created, every subsequent send fails the same way. Nothing degrades to `"vsplit"` and `:checkhealth` stays green.

### `PERF-42` — Invalidierbar

`lua/runtime-analysis/telemetry/init.lua:808` · `inst.stop` · confidence **medium**

**Befund.** `inst.stop()` detaches the wrappers, stops the timer and flushes, but never removes the instance from the module-level `instances` registry it was appended to at line 1053. There is no removal path anywhere; `M.get(namespace)` (line 1152) returns the *first* match.

**Regelbezug.** PERF-42 requires a defined point at which a registry/cache entry becomes invalid. A stopped instance is invalid as an answer to "which instance owns this namespace", yet it stays in the list forever and shadows every later one.

**Auswirkung.** After `:RA usage stop` + `:RA usage start`, the namespace has two entries in `instances` and every `M.get`-based path binds to the dead one. Concretely: the traffic light freezes at the pre-stop counts because `statusline.entries_for` reports the stopped instance's own `base`; `:checkhealth` lists the namespace twice; `:RATelemetry reset <ns>` resets the dead instance and leaves the live one's data intact (so the user's reset appears to do nothing); and `:RATelemetry stop <ns>` / `start <ns>` act on the dead instance. The spurious "namespace already has a live instance; both will write the same cache file" warning fires on every restart.

### `SEC-23` — Remote-Content clientseitig sanitizen

`lua/runtime-analysis/telemetry/renderers/html.lua:301` · `M.render` · confidence **medium**

**Befund.** The guard that stops report data from terminating the `<script>` block it is embedded in is `rows_json:gsub("</script", "<\\/script")` — a case-sensitive literal. HTML's script-data end-tag matching is ASCII case-insensitive, so `</SCRIPT` or `</Script` passes through untouched.

**Regelbezug.** SEC-23 requires unchecked external content never to reach the DOM directly. The row payload carries `key`, `namespace` and argument/error/caller fingerprints, and a fingerprint is built from a real call argument's own value (fingerprint.lua:66-70 stores strings up to 40 bytes verbatim) — i.e. attacker-influenceable text from whatever the instrumented plugin was called with.

**Auswirkung.** Narrower than 'the row payload' but real. The fields that carry unescaped text into the embedded JSON are `namespace`, `key`, `top_arg`, `top_caller` and `hint`. Any of those containing `</SCRIPT` (or `</Script`) terminates the script element in the HTML parser; everything after it is parsed as markup. The `key`/`namespace` route needs a wrapped function or namespace named that way; the argument route additionally needs `profile_args` on (opt-in) and a string argument of at most 40 bytes -- `</SCRIPT><img src=x onerror=...>` fits at 37. `:RATelemetry export report.html` or the float's `gO` then opens the file in the system browser and the injected element executes with `file://` origin. The lowercase-only guard leaves open exactly the case the comment on lines 295-300 was written to close.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/runtime-analysis/loaded.lua:246` · `M.load_snapshot` · confidence **medium**

**Befund.** `M.load_snapshot` returns the raw decoded JSON (`return raw`) after only checking that it is not nil, and annotates it as `{ version: integer, prefix: string, captured_at: integer, modules: table<string, table<string,true>> }`. The sibling persistence layer does validate: `telemetry/store.lua`'s `normalize` (lines 69-84) checks the version and re-types every field before handing data back.

**Regelbezug.** SEC-33 requires every field of a persisted snapshot to be revalidated on load (type, length, count cap). Nothing here checks `version`, `modules` or any nested value, yet the return type promises a specific shape.

**Auswirkung.** The exposure is a syntactically VALID snapshot with the wrong shape -- hand-edited, written by an older/newer schema, or produced by a future format change. Such a file is handed back typed as if it were well-formed: `raw.modules` may be nil, a string or a number, and `raw.version` is never compared against anything, so a schema change reads back as the current version. A consumer iterating `snap.modules` raises `bad argument to pairs` or `attempt to index a nil value` inside itself, with nothing naming the snapshot as the cause. I could not confirm from this repo that documentation.nvim's Loaded panel is a live consumer, so the concrete blast radius is 'whatever reads the documented return type', not that specific panel.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/runtime-analysis/telemetry/lazy.lua:358` · `M.configured` · confidence **low**

**Befund.** `M.setup` stores the caller's table by reference (`configured = opts`, line 279) and `M.configured()` hands that same table back to any caller. The doc-comment describes the value ("the `opts` the most recent `M.setup()` call received, unchanged") but carries no 'live reference, do not mutate' warning, and no copy is made on either side.

**Regelbezug.** ERR-54 requires a public getter over shared internal state either to copy before handing out or to document the live reference explicitly. This does neither — and the shared state here is not even internal: it is the user's own `opts.telemetry` sub-table from their plugin spec, passed through `runtime-analysis.init.setup` at init.lua:88.

**Auswirkung.** Latent, not an active bug -- correcting the finding's severity rather than its substance. No production code in this repo calls `configured()` at all (the single caller is a spec, read-only), so nothing misbehaves today. The violation is that the contract permits it: any future or external consumer that sorts, normalises or adds a key to the returned table would mutate the user's live lazy.nvim spec sub-table for the rest of the session, changing what every later `M.setup()` / `candidates()` read sees, with no warning in the getter telling them not to.

> **Abdeckung dieses Laufs.** COVERAGE. I read the rules file end to end first, then read these files completely: init.lua, config/{DEFAULTS,init,validate}.lua, runner.lua, history.lua, env.lua, parse.lua, curl.lua, multipart.lua, graphql.lua, assertions.lua, view.lua, ui/float.lua, usage.lua, statusline.lua, health.lua, loaded.lua, bench.lua, bindings/usrcmds.lua (all 1146 lines), startup/init.lua, telemetry/{store,toggle,reminder,fingerprint,registry,report_file,config,setup_all}.lua, telemetry/renderers/{html,mdview,preview_tab}.lua, and TESTS/run.lua. I read large but partial slices of telemetry/init.lua (~250 of 1616: new/report/flush/timers/lifecycle/module-level), telemetry/command.lua (~350 of 1330: the dispatcher, backup prompt, do_reset_all, flamegraph/export/open branches), startup/profile.lua (~250 of 541: parse/aggregate/argv/run), and telemetry/lazy.lua (~130 of 456). I also read the relevant lib.nvim implementations the findings depend on (fs/json, lua/json/encode, ui/list, strings/encoding) rather than assuming their contracts, and verified two behaviours in headless Neovim: setqflist with an invalid bufnr raises E92, and vim.fn.expand on a backtick span performs shell substitution and then raises E282.

NOT FULLY COVERED, and why. telemetry/report.lua (1201 lines) — I read only build() and the fingerprint helpers, so the markdown/compare/lines renderers are unaudited; telemetry/command.lua's snapshot/compare/retention/setup-all subcommands (roughly lines 1129-1250) I only skimmed via the dispatcher; telemetry/cost_vs_use.lua, telemetry/startup.lua, ui/columns.lua and renderers/flamegraph.lua I checked only by targeted grep (escaping, autocmds, timers, and/or chains), not by full read. Everything under TESTS/ and scripts/ I looked at only for XP-06 (module-path casing) and the spec-list-vs-file drift in TESTS/run.lua — both clean, 28 spec files and 28 entries — so those directories are effectively unaudited for the rest of the rules; nothing I report is test code.

CMT-16 I could not settle. docs/map/ is generated by scripts/gen_map.lua and docs/BINDINGS.md is explicitly hand-maintained (its own header says so, and gen_map.lua lines 16-20 confirm it is not rendered), so a hand-edit in the generated map is the only live surface — and detecting drift there means running the generator, which this report-only task forbids. Separately, docs/BINDINGS.md claims "All nine are registered unconditionally" while health.lua:255 says "All four checked here"; I did not count the registrations to resolve that, and a stale hand-maintained doc is not a CMT-16 case anyway.

RULES CHECKED AND CLEAN (so their absence from the findings is a result, not a gap). ERR-60: I enumerated every `and … or` site in lua/ and confirmed each `b` is a table, a non-empty string, a number or a literal — 0 and "" are truthy in Lua, so the only real exposure is reminder.lua, reported at low confidence. ERR-62: every pcall in the plugin is `pcall(f, args)` or `pcall(function() … end)`; none evaluates its callee first. SEC-30: every match against caller-supplied text uses `find(…, 1, true)`. SEC-03/SEC-35: no shell-string construction anywhere; startup/profile.lua uses argv through `vim.system`, and renderers/mdview.lua:48 goes through `fnameescape`. PERF-62/PERF-82: both timers (startup/init.lua:243, telemetry/init.lua:750) stop and close before a restart. PERF-80: both fast-event callbacks (startup/profile.lua:361, telemetry/init.lua:757) wrap in vim.schedule, and the stall timer touches no vim.api at all. PERF-92: ui/float.lua computes geometry per open, not at require. LUA-48: registry.lua:35's `__mode = "k"` is keyed by container *tables*, which is the correct use — matching the Belege entry that already names this file as a positive example. LUA-06: config/DEFAULTS.lua is pure data with no env or filesystem access at module level. LUA-87/LUA-93: docs/installation.md uses `opts` (not a `config` block) and gives `lazy = false` an explicit stated reason. ERR-50/51: validation runs before the merge, and the merge deep-copies DEFAULTS. SEC-11/SEC-13: history.lua stores exactly method/url/status/timestamp and fingerprint.lua caps strings — both already cited as positive Belege for this plugin. telemetry/store.lua's load-modify-save collapse is the case the ERR-11 Belege footnote explicitly clears for this repo as deliberately loss-tolerant, so I did not re-report it.

TWO THINGS I SAW AND DELIBERATELY DID NOT REPORT. curl.lua:329 interpolates `request.method` into the exported curl command without the `shq` quoting every other field gets — but parse.lua:81 constrains the method to `%u+`, so there is no reachable impact today; it is an inconsistency, not a defect. And multipart.lua:160-174 resolves `< path` references with a naive per-line regex over the whole body, while the export side (`part_content`, line 129-138) only honours a reference that is a part's entire content — the two directions disagree about what counts as a file reference, and neither constrains the path to the request buffer's own tree. I could not tie that cleanly to one of the 76 rules, so I am flagging it here rather than inventing a rule id for it; it is worth a look if a checked-in `.http` file from an untrusted repo is ever a scenario you care about.

---

## diff.nvim

**11 Befunde** (7 × high). Roh gemeldet: 18.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/diff/core/directory.lua:136` · `diff_trees` · confidence **high**

**Befund.** Four bare `fn.readfile(...)` calls (lines 136, 137, 144, 147) read every listed file with no `pcall`, at a filesystem boundary between a tree walk and the read.

**Regelbezug.** ERR-01 requires `pcall` at filesystem boundaries; this is not a hotpath (it is one read per changed file, and the outer loop would be the right place to guard anyway). `vim.fn.readfile` raises: verified here, `pcall(vim.fn.readfile, "<missing>")` → `Vim:E484: Can't open file`. The same module already guards its `fn.writefile` with `pcall` twelve lines further down.

**Auswirkung.** Any listed file that becomes unreadable between `list_files` and `diff_trees` (permission change, lock, branch switch, another process deleting it) raises `E484: Can't open file` out of `diff_trees`, past `directory.run`'s own `(nil, err)` + `notify.error` contract, and out of `core.execute` — which never reaches either `done(dir_result)` or `fail(dir_err)`. The user sees a raw Vim error instead of the plugin's message, and an API caller's `on_done` never fires at all, so it waits forever. Confirmed by the repo's own pinned test.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/diff/core/directory.lua:138` · `diff_trees` · confidence **high**

**Befund.** `local stats = render.compute_stats(a_lines, b_lines, algorithm, ctxlen)` captures only the first return value and drops the `err`; the following `if stats and (...)` silently skips the file when `stats` is nil.

**Regelbezug.** ERR-11: a result that can legitimately be empty must distinguish "empty, but fine" from "empty, because it broke". Here a file whose diff could not be *computed* is recorded identically to a file that is genuinely unchanged — no entry, no error, no notification. `compute_unified` correctly returns `(nil, err)`; the caller throws the err away.

**Auswirkung.** A file whose diff could not be computed is recorded identically to an unchanged file — no entry, no error, no notification. With a typo'd `diff.algorithm`, `compute_stats` returns nil for every file present in both trees, so `:Diff` on two directories whose filenames match but whose contents all differ reports "No differences found" as a success. Narrower than the auditor stated: files present in only one tree still produce A/D entries via the bare `#fn.readfile` on lines 144/147, which never calls `compute_stats` — so trees that also differ in their file sets do report something, just with every modified file missing. The non-directory paths surface the same error correctly as "diff failed: …".

### `LUA-93` — Jedes Plugin trägt seinen eigenen Lazy-Trigger

`docs/installation.md:30` · `lazy.nvim spec` · confidence **high**

**Befund.** All three package-manager snippets (lines 30, 40, 55) declare `cmd = { "Diff", "DiffClear", "DiffBuffers", "DiffOrig", "DiffExit" }`. `DiffProfile` — registered by `bindings/usrcmds.lua:123` under the default-on `features.diffopt_profile` — appears nowhere in the file.

**Regelbezug.** LUA-93: every command/keymap a lazy-loaded plugin owns needs a trigger in its own spec; being reached some other way is an accident, not a trigger. Here the documented spec is `cmd`-only, so nothing in it loads the plugin for `:DiffProfile`, for the default-on `gh` keymap (`features/gitsigns_peek.lua:45`), for the global-scope `exit.key`, or for any configured `cfg.keymaps` shortcut — all four are registered inside `setup()`, which a `cmd`-only trigger defers until one of the five listed commands is typed.

**Auswirkung.** With the documented spec, `:DiffProfile` gives `E492: Not an editor command` until one of the five listed commands has been run once, and the default-on `gh` hunk-peek keymap is simply absent at startup, appearing only after an unrelated `:Diff*` command loads the plugin — which reads as "the feature does not work", with nothing pointing at load order. Two of the auditor's four sub-claims do not hold: `exit.key` defaults to `scope = "buffer"` (DEFAULTS.lua:81), so it only ever binds to diff buffers that cannot exist before the plugin loads, and `keymaps` defaults to `{}` (DEFAULTS.lua:78), so that part affects only users who configure entries — real for them, but not a default-path breakage.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/diff/core/resolve.lua:127` · `M.resolve_lines` · confidence **high**

**Befund.** The file-path branch runs the raw user specifier through `vim.fn.expand(tostring(spec))` before `filereadable`/`readfile`.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on user/buffer text: a backtick span in the argument is a command substitution over `&shell`, and `%`/`#`/`<cfile>` are Vim specials. `spec` here is whatever the user typed after `target=`/`source=` in `:Diff`, or whatever an integrating plugin passed to `require('diff').run(...)` — the rule's `lib.nvim.cross.fs.expand_path` (no shell, no globbing, no specials) is the intended tool.

**Auswirkung.** `:Diff target=`<cmd>`` — the whole value being a backtick span, no suffix — runs `<cmd>` through `&shell` and uses its stdout as the file path. `%`, `#`, `<cfile>` are likewise substituted when they are the whole token. Nothing throws: `expand` returns normally, so there is no crash, no leaked scratch buffer and `on_done` still fires. The concrete harm is silent command execution from a `:Diff` argument (or from whatever an integrating plugin passes to `require('diff').run(...)`), plus resolving to a path the user never wrote.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/diff/core/directory.lua:38` · `M.is_directory_spec` · confidence **high**

**Befund.** `fn.isdirectory(fn.expand(spec))` expands the raw user specifier.

**Regelbezug.** Same SEC-34 violation, but this is the *earliest and broadest* exposure: `core.execute` calls `directory.is_directory_spec(opts.target)` on every single `:Diff` invocation whose target is not `current`/`clipboard`/a bufnr/`git:`/`http(s)://` — i.e. on every file-path diff — before anything else touches the specifier.

**Auswirkung.** Every `:Diff` whose target or source is a plain path runs `vim.fn.expand` on it before anything else touches it, so a specifier that is entirely a backtick span (`:Diff target=`id``) executes through `&shell` here first. The E282/uncaught-error part of the claim does not hold — `expand` returns normally on nvim 0.12.2, so `:Diff` does not die; the specifier is simply resolved from command output instead of from what the user typed.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/diff/core/init.lua:274` · `stat_list_target` · confidence **high**

**Befund.** `local path = vim.fn.expand(spec)` on the raw target specifier, when resolving a quickfix/location-list entry for `output=stat`.

**Regelbezug.** Fourth call site of the same SEC-34 defect, on the `output=stat` + `stat_list="qf"/"loc"` path.

**Auswirkung.** On the `output=stat` + `stat_list="qf"/"loc"` path the specifier is shell-expanded a second time (resolve.lua:127 already did it once), so a backtick-span specifier runs its command twice per `:Diff`. The auditor's alternative claim that it raises E282 and discards the completed diff is wrong — `expand` returns normally, so the diff is not discarded; the quickfix entry just points at whatever the command printed.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/diff/features/image_compare.lua:59` · `M.is_image_file_spec` · confidence **high**

**Befund.** `local path = vim.fn.expand(spec)` on the raw specifier, and the expanded value is then handed to `images.gallery({path_a, path_b}, 2)`.

**Regelbezug.** Fifth call site of the same SEC-34 defect. This one also forwards the expanded string into a third-party plugin, so whatever `expand` produced (including the stdout of a backtick command) becomes a path another plugin acts on.

**Auswirkung.** A third unconditional shell-expansion of the same user specifier on every plain-path `:Diff`, running before the image-extension check so it is not limited to image workflows. When the expansion does produce command output and that output happens to end in an image extension and be readable, it is handed to images.nvim as a file path. No error escapes; the damage is the command execution itself plus a path the user never supplied crossing a plugin boundary.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/diff/core/resolve.lua:25` · `M.parse_args` · confidence **medium**

**Befund.** `for key, value in raw:gmatch("(%a+)=([^%s]+)")` keeps every key it matches and never reports the ones it does not recognise; `bindings/usrcmds.lua` declares a kv schema for completion but deliberately bypasses composer's parsed `ctx.kv` and hands `core.run` the raw string, so composer's own key checking never applies either.

**Regelbezug.** ERR-10: "kein Argument" must not collapse onto "ungültiges Argument" — the rule's named bug type is a typo in an argument behaving like an absent argument. `:Diff veiw=inline` parses cleanly into `kv.veiw`, `kv.view` stays nil, and `resolve_view_output` silently substitutes `cfg.default_view`. The plugin does reject a *known* key with a *bad value* loudly (`Unknown view=%q (valid: …)`), which makes the silence on a misspelled key the inconsistency.

**Auswirkung.** A misspelled option name is applied as though it had never been typed, with no message: `:Diff veiw=inline target=x` opens the default vsplit, `:Diff ouput=stat target=x` opens a buffer diff, `:Diff sorce=clipboard` silently diffs the current buffer. Because the plugin is loud about a bad value under a correct key, the user reasonably concludes the feature itself is broken rather than that the key is misspelled.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/diff/config/init.lua:25` · `M.setup` · confidence **medium**

**Befund.** `_active = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), user_opts)` is the whole of setup: no per-value validation anywhere, and `health.lua` never inspects a single configured value. The module's own docstring on line 15 claims "Validates only the cheap, high-value fields" — nothing is validated.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and to be made visible through `:checkhealth`. Neither happens: an out-of-range value propagates unchanged into every consumer. (`default_orig_view` is the one field that does degrade — `origin.lua:58` falls back to `vsplit` for any non-`"split"` value, and says so in a comment — which shows the intended pattern is understood but applied in exactly one place.)

**Auswirkung.** An invalid single config value neither degrades to its default nor becomes visible in `:checkhealth`; it propagates unchanged into every consumer. A typo'd `diff.algorithm` makes `vim.diff` fail on every invocation, so text outputs report "diff failed: not a valid algorithm" on every `:Diff` with no hint the config is the cause, directory diffs report "No differences found" instead (per the ERR-11 finding, for files present in both trees), and `:checkhealth diff` reports every section green. The same absence of validation applies to `ctxlen` and `directory_max_files`.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/diff/config/init.lua:25` · `M.setup` · confidence **medium**

**Befund.** User options are deep-merged with no unknown-key check at any point — the module documents this as "unknown keys are preserved".

**Regelbezug.** ERR-50 requires unknown-key/"did you mean" validation to run *before* the merge, precisely so "ein Tippfehler in einer verschachtelten Option verschwindet nicht stillschweigend im Default". Running it nowhere produces exactly the harm the rule names. The plugin already has the counterpart machinery one layer up — `bindings/keymaps.lua:196` warns on an unknown `keymaps.*` name with the full accepted list — so the pattern exists but is not applied to the config table itself.

**Auswirkung.** A misspelled option key is accepted in complete silence: `setup({ features = { diff_orgin = false } })` or `setup({ diff = { word_diffs = false } })` merges the typo'd key into the active config, the real option keeps its default, and neither `setup()` nor `:checkhealth diff` ever mentions it. Because `M.setup` returns early on a second call (`_setup_done` in init.lua:27-30), there is also no later opportunity for the mistake to surface. The user concludes the option does not work.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/diff/core/scratch.lua:49` · `M.track` · confidence **medium**

**Befund.** `M.track` appends to `_bufs` without checking whether the handle is already registered; `M.active_count` then counts registry entries rather than distinct live buffers, and `require("diff").status()` prints that count.

**Regelbezug.** LLS-31's inversion clause — a function forming its return from the bookkeeping rather than from the actual work. `active_count` reports how many entries were parked, not how many diffs exist, so the public statusline number cannot be trusted and the discrepancy can never surface as an error.

**Auswirkung.** `M.track` is a documented public entry point ("for buffers it did not itself create"), so an integrating plugin that adopts a buffer twice — or adopts one `M.create` already registered — makes `diff.status()` print an inflated count such as `diff:3` for a single diff, and the statusline keeps reporting it for the rest of the session. Impact is latent rather than active: nothing inside diff.nvim calls `track()` today, so it requires an external caller to trigger. `cleanup_all`/`wipe_on_exit` are unaffected — they re-validate per entry, so duplicates are skipped and the buffer is still wiped exactly once.

> **Abdeckung dieses Laufs.** COVERAGE. Read every file under lua/ and plugin/ in full (4,290 LOC, 28 files), plus README.md and all 15 files under docs/. TESTS/ was read selectively (run.lua, harness.lua, and the spec sections that turned up in targeted greps) rather than in full, so test-side findings are not exhaustive — I report none, and none of the 18 findings above is test code.

VERIFIED, NOT ASSUMED. Four behaviors that findings hang on were reproduced in a headless Neovim rather than taken on faith: (1) vim.fn.expand("`echo PWNED`") does invoke &shell and raises E282 when the run cannot be read back; (2) pcall(vim.fn.readfile, "<missing>") → Vim:E484; (3) pcall(vim.cmd, "silent! split | …") → false, Vim(split):E36 — confirming the module's own claim that `silent!` suppresses the message, not the error; (4) pcall(vim.diff, …, {algorithm="bogus"}) → "not a valid algorithm".

DELIBERATELY DROPPED AFTER CHECKING. I started three LLS-31 findings claiming that render.three_way/render.inline/directory.run hand a caller the user's own window in `result.windows` (against the contract in docs/api.md), then verified the E36 path raises before the `return` is reached — so that scenario is unreachable and I removed them. The surviving defect at those sites is the missing pcall (ERR-01), which is what I report. Similarly, I checked every `a and b or c` the grep turned up (18 sites) against ERR-60 and found no violation: in each one the middle term is a table, a non-empty string, or a number that can be 0 (truthy in Lua). ERR-51 is already handled at config/init.lua:25 (deepcopy) and is named in the rules file's own Belege for diff.nvim, so it is not re-reported; likewise SEC-01 (core/git.lua, core/url.lua use argv, never a shell string) and ERR-11's positive citation of core/resolve.lua.

ALREADY PINNED BY THE REPO. Two of the findings (ERR-01 at directory.lua:136, LLS-31 at scratch.lua:49) already have characterization tests in TESTS/ that assert the broken behavior and label it "BUG:". They are unfixed in the code in front of me, so they are reported; the existing tests make them cheap to confirm and cheap to flip once fixed.

NOT REPORTED FOR LACK OF A MATCHING RULE ID. Three real drift hazards found no clean home among the 76: (a) VALID_VIEWS/VALID_OUTPUTS are declared twice — core/init.lua:21-24 and bindings/usrcmds.lua:25-26 — with core/init.lua:943's M.valid_lists() carrying a CDX comment saying it has zero callers; adding a view to one copy silently breaks the other. (b) docs/BINDINGS.md claims to list "Every keymap, user command, and autocommand" but omits both :DiffProfile and the default-on `gh` keymap. (c) features/gitsigns_peek.lua:45 binds a global `gh` by default, which contradicts bindings/keymaps.lua's own header ("diff.nvim still imposes no mappings… the exit key is the only thing bound without being asked for"). CMT-16 does not apply — docs/BINDINGS.md is hand-maintained, not renderer-generated, and docs/map/ shows no hand-edit.

AREAS I COULD NOT FULLY CLOSE. ERR-11 on directory.lua's list_files: if vim.fs.dir cannot open a directory that isdirectory() just confirmed (permission on the dir itself), the iterator may yield nothing and list_files would return an empty list with no error — the same collapse as the reported finding one function down. I could not confirm vim.fs.dir's exact failure mode for this Neovim version without constructing an unreadable directory on Windows, so I left it out rather than guess. ERR-54 (config.get() returns the live _active table by reference, neither copied nor documented as "live reference, do not mutate") is technically unmet, but I traced every consumer and none mutates it, so there is no impact to state and I did not report it. SEC-23 I judged satisfied: URL content is normalized through split_lines into a nomodifiable, buftype=nofile scratch buffer with no filetype set, so no FileType autocmd chain fires on fetched content.

---

## documentation.nvim

**11 Befunde** (4 × high, 1 davon in Testcode). Roh gemeldet: 13.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/documentation/editor/health.lua:394` · `check (resolved configuration section)` · confidence **high**

**Befund.** `:checkhealth documentation` resolves the configuration with `require("documentation.config").build(vim.fn.getcwd())` — the two-argument form, with no `notify` instance.

**Regelbezug.** ERR-22 requires that a config value which degrades to its default be made visible through `:checkhealth`. `config.build` emits all three of its degradation warnings (unrecognised option key, malformed `.docmap.json`, typo'd `checks` code) only through the optional `notify` argument — the block at `config/init.lua:344-362` is wrapped in `if notify then`. Passing none makes the one surface the rule names silent about exactly the cases it exists to report. Both sibling hosts added a `notify` for this reason and say so in their comments (`scripts/action_run.lua:112-124`, `standalone/docmap.lua:272-290`).

**Auswirkung.** A repository whose `.docmap.json` is malformed JSON, names a host-only key, or misspells a `checks` code is mapped with the defaults, and the `:checkhealth documentation` section literally headed "resolved configuration" prints those defaults as if they were what the user asked for. The one surface ERR-22 names as the place degradation must be visible reports nothing -- the fix is a `notify`-shaped adapter funnelling into the section's own `h_warn`.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/documentation/bindings/usrcmds/annotate.lua:147` · `apply_all/apply_one` · confidence **high**

**Befund.** `:DocMap annotate --write` builds every plan first (`annotate.plan` reads and snapshots each file's lines) and only then applies them all; `annotate.apply` writes `plan.lines` back wholesale, never re-reading the file or re-verifying the anchor against the current text. With more than `CHUNK = 10` candidates both phases are spread over separate event-loop ticks via `vim.schedule` (lines 174 and 230).

**Regelbezug.** ERR-30 requires an edit computed during a scan to be re-verified against the current text immediately before writing. The code itself states the requirement and then breaks it: `Documentation.AnnotatePlan.lines` is documented as "stale the moment the file changes on disk" and `M.plan`'s header says "always call it right before `apply`, never cache the result across edits" (`lua/documentation/core/annotate.lua:163-166`). The only caller caches every plan across many ticks.

**Auswirkung.** On the wide path only (more than `CHUNK` = 10 candidates), any write to one of those files between its plan and its apply -- a buffer save, a formatter, a `git checkout` -- is silently discarded: `apply` rewrites the file from the earlier snapshot plus the generated header, returns ok, and the path is listed in the quickfix as "annotated". No error, no skip, no diff. Scope correction to the finding: at 10 or fewer candidates both phases run in one synchronous pass with no event-loop yield, so the window is zero there; the defect is confined to the chunked path.

### `LUA-16` — `vim.NIL` sanitizen

`lua/documentation/config/file.lua:188` · `M.load` · confidence **high**

**Befund.** `.docmap.json` is decoded with `pcall(vim.json.decode, text)` and no `{ luanil = { object = true, array = true } }`, then every allowlisted key is copied verbatim into the options table (`out[key] = value`) with no type check.

**Regelbezug.** LUA-16 requires every field arriving from external JSON to be sanitised before use, because a JSON `null` decodes to `vim.NIL` — truthy userdata, not Lua `nil`. Every other decode site in this repo passes `luanil` and says why (`core/artifact.lua:71-77`, `bindings/usrcmds/diff.lua:30-35`, `editor/browse/README.md:74`); this one, the only decode of a file written by hand, does not.

**Auswirkung.** `"source": null` yields `opts.source = vim.NIL`; `core/scan.lua:327` then calls `chomp(slash(entry))` and `slash` (line 79-81) does `p:gsub("\\", "/")` on userdata, so `:DocMap` dies with "attempt to index a userdata value" rather than reporting a bad config line -- the crash is real, but the message is an index error, not the "attempt to concatenate a userdata value" the finding names (that would only be reached at scan.lua:407 if slash were bypassed). `"title": null` / `"repo_url": null` instead survive as truthy userdata into the merged opts and are carried into `module_map.json` and the rendered page. The missing type check is real and independent: `"out_dir": 7` or `"branch": {}` are accepted verbatim by the same loop.

### `SEC-03` — Nutzereingabe nie shell-interpoliert

`standalone/docmap.lua:381` · `popen_git` · confidence **high**

**Befund.** The standalone build's only git runner concatenates its arguments into a single shell string handed to `io.popen`, and one of those arguments is `opts.out_dir`, which `config/file.lua` lets the scanned repository set from its own `.docmap.json` (`REPO_KEYS.out_dir = true`).

**Regelbezug.** SEC-03 forbids putting a value that comes from outside the program into a command string. `shell_quote` wraps the value in double quotes, which on a POSIX shell does not neutralise `$(...)`, backticks or `$VAR` — so the quoting the comment calls "the second lock on that door" is in fact the only lock, and it does not hold. The comment's premise ("`opts.root`/`opts.out_dir` (config, not request input)") is wrong: `out_dir` is repository input, and `config/file.lua`'s own header states the threat model — the file is read "out of a repository that CI just cloned, or that a person added to a desktop app by pointing at a directory".

**Auswirkung.** On Linux/macOS, a cloned repository shipping `.docmap.json` with `"out_dir": "docs/map$(cmd)"` gets `cmd` executed with the privileges of whoever runs the standalone binary, as soon as the binary answers `--api=commit/<sha>` for that tree. Precondition is only a sha that exists in the clone (the preceding `git show -s` must succeed) -- no map, no checklist, no other setup. Since `docmap-desktop` runs this binary per project, adding an untrusted project to the app is arbitrary code execution. Scope correction: on Windows the shell is cmd.exe, which does not expand `$(...)`/backticks, so the RCE as described is POSIX-only; only the `commit/<sha>` route is confirmed to pass `out_dir` into a git argument.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/documentation/core/artifact.lua:80` · `M.decode / M.load` · confidence **medium**

**Befund.** `M.decode` returns `nil` for an empty string, for undecodable JSON and for JSON that decodes but has no `nodes` table; `M.load` feeds it `read(path) or ""`, collapsing "there is no artifact" into the same `nil` as "the artifact on disk is corrupt".

**Regelbezug.** ERR-11 requires an empty result to distinguish "empty and fine" from "empty because broken". The module header only justifies the first ("Absence is a normal outcome… a project that has never been generated simply has none") and says nothing about the second. The repo shows it knows the difference elsewhere: `core/consumers.lua:100` returns a separate `unreadable` count, documented as "Maps found but not decodable — reported, never treated as 'this project uses nothing'".

**Auswirkung.** `core/api.lua:33-35`'s `current_ir` is the only reader, and lines 124-127 collapse the `nil` into `{ available = false, namespace = ..., reason = "no map generated yet" }`. So a truncated or half-written `docs/map/module_map.json` makes every server-backed panel and every standalone `--api` route tell the user to generate a map they already have, naming the wrong cause; the next `:DocMap` regenerates over the corrupt file and it is never reported. Impact is a misleading diagnosis, not data loss -- the file is going to be rewritten anyway -- but the user is sent looking in the wrong place.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`scripts/gen_map.lua:67` · `top-level opts build` · confidence **medium** · _Testcode_

**Befund.** `require("documentation.config").build(root, { … })` is called with two arguments — no `notify` — so this entry point suppresses the unrecognised-key, malformed-`.docmap.json` and bad-`checks`-code warnings.

**Regelbezug.** Same ERR-22 gap as `editor/health.lua`, in the host where it is least recoverable. Both other non-editor hosts fixed it deliberately: `scripts/action_run.lua:112-124` ("a host that hands it none turns every one of those into silence. In a CI log silence is the worst of the three places it can happen — nobody is watching, and the run goes green") and `standalone/docmap.lua:272-290`.

**Auswirkung.** A malformed `.docmap.json`, a host-only key or a typo'd `checks` code is dropped without a word in the host the pre-commit hook and the `map` CI gate run. Under `--check` the run then compares a defaults-built map against the committed one and prints "Module map is stale" with byte offsets, with nothing naming the config file as the cause. The finding's `is_test_code: true` is mislabelled -- this is a build/CI entry point, not a test, which is what makes it matter. The claim that every repository copying it per `docs/reuse.md` inherits the silence is plausible but not something I verified against those repos.

### `ERR-60` — `a and b or c` bricht, sobald `b` falsy sein kann

`lua/documentation/core/lang/kotlin.lua:489` · `scan (interface member visibility)` · confidence **medium**

**Befund.** `local inherited = what == "interface" and false or nil` — the middle operand is `false`, so the expression always evaluates to `nil`, and `record_function`'s `if inherited ~= nil and not child_of(node, "modifiers")` branch (line 413) is unreachable.

**Regelbezug.** ERR-60 forbids `a and b or c` where `b` can be falsy and requires an explicit `if`. This repository has already paid for exactly this shape and written the lesson down two files over: `core/lang/swift.lua:508-521` names it ("a Lua trap this session has now hit twice", "`nil` and `false` are both unusable as the middle operand") and uses an `if`, as does `core/lang/scala.lua:454-456`. Kotlin and PHP were not brought along.

**Auswirkung.** No wrong output today: `is_internal` (kotlin.lua:278-287) already returns `false` when a declaration has no `modifiers` node, so an interface member with no modifier is reported public either way and the dead branch's value coincides with the live one. The concrete defect is that the branch is silently unreachable while the comment above it claims the behaviour is implemented, so nothing -- no test, no diagnostic -- would notice if the `is_internal` default changed or a future `inherited = true` case were added. Lower severity than the finding implies: this is dead code and a false comment, not a current visibility bug.

### `ERR-60` — `a and b or c` bricht, sobald `b` falsy sein kann

`lua/documentation/core/lang/php.lua:503` · `scan (interface member visibility)` · confidence **medium**

**Befund.** `local inherited = kind == "interface_declaration" and false or nil` — always `nil`, so `is_internal(node, src, inherited)` (line 468) never takes its `if inherited ~= nil then return inherited end` path at `php.lua:322-325`.

**Regelbezug.** Same ERR-60 trap as the Kotlin site: a falsy middle operand makes the condition irrelevant. The `if` form is already used for the identical decision in `core/lang/swift.lua:518-521` and `core/lang/scala.lua:454-456`.

**Auswirkung.** `is_internal`'s third parameter is threaded through the call chain and is always `nil`, so the interface-member rule is dead code. Invisible today because the `if not vis` fallthrough returns `false` anyway, which is the same answer. As with the Kotlin site, the real cost is an unreachable branch plus documentation asserting behaviour the code does not have -- it would become a wrong-visibility bug only if that fallback changed.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/documentation/editor/callhierarchy.lua:206` · `telemetry_ttl_ms` · confidence **medium**

**Befund.** The hover telemetry cache's TTL is read with `pcall(require, "documentation.config.DEFAULTS")` and `defaults.telemetry_ttl_ms` — the raw defaults table, not the resolved config — and the function takes no `cfg` parameter at all.

**Regelbezug.** LUA-87's merge rule requires option access to go through the resolved config (`config.options.X`), never a direct read of a module's own field, precisely so a user override is not discarded. The two sibling helpers for the other tunable in this plugin do it correctly — `bindings/usrcmds/churn.lua:27-34` and `bindings/usrcmds/checklist.lua:28-35` both take `cfg` and prefer `cfg.git_log_timeout_ms` — and the caller here already threads a resolved value (`namespace`, per the `@param` note at line 273), so the resolved config is reachable.

**Auswirkung.** `setup({ telemetry_ttl_ms = 500 })` passes `KNOWN_OPTS_KEYS` validation without a warning and is then discarded -- the hover telemetry cache always uses the 2000 ms default. The option is documented in three places as configurable and is, in fact, inert. Scope: this affects only the hover/CursorHold telemetry read in `callhierarchy.lua`, so the user-visible effect is that the number cannot be made to refresh faster or slower; nothing crashes.

### `SEC-42` — Pfad-/Dateiname-Komponenten sanitizen

`lua/documentation/init.lua:533` · `M.write_artifacts` · confidence **medium**

**Befund.** `out_dir` is taken straight from the resolved options and pasted onto the root (`write(root .. "/" .. out_dir .. "/" .. name, content)`), with `mkdirp` creating whatever directories that names. `config/file.lua` lets the scanned repository set `out_dir` from its own `.docmap.json`, and nothing between the two normalises the value or checks that it stays inside the repository.

**Regelbezug.** SEC-42 requires a user-controlled string that becomes part of a path to be sanitised and whitelisted before use. `core/docs.lua:451` strips leading slashes off the same value for its own exclusion check, so the need for normalisation is already recognised — but the write path does none, and `..` segments are never removed anywhere.

**Auswirkung.** Opening an untrusted checkout and running `:DocMap` with `"out_dir": "../../../../.config/nvim/lua"` in its `.docmap.json` makes `mkdirp` create that directory tree and writes `module_map.json`, `index.html` and `overview.md` into it (plus `coverage.svg` when `badge` is set), outside the repository, overwriting any existing files of those names. It is an overwrite limited to docmap's own three or four artifact filenames, not arbitrary-name file creation -- but `~/.config/nvim/lua/index.html` landing on disk from opening a cloned repo is real. The same unnormalised value also moves `editor/serve.lua`'s static route out of the repository.

### `SEC-46` — Beim String-Literal-Einbetten das Escape-Zeichen **zuerst** escapen

`standalone/docmap.lua:344` · `shell_quote` · confidence **medium**

**Befund.** `return '"' .. tostring(s):gsub('"', '\\"') .. '"'` — the value is wrapped in double quotes and only the double quote itself is escaped; the escape character `\` is not escaped first.

**Regelbezug.** SEC-46 is explicit that embedding into another language's string literal escapes the escape character before the quote. A POSIX shell treats `\` as an escape inside double quotes, so a value ending in a backslash produces `"…\"` — the trailing backslash escapes the closing quote and the string runs on into the rest of the command line. (The same omission leaves `$` and backticks live, which is the SEC-03 finding above.)

**Auswirkung.** Confirmed for values that reach `popen_git` unnormalised -- chiefly `out_dir`, which `.docmap.json` sets verbatim and `core/api.lua:381` embeds as `:(exclude)<out_dir>`: a trailing backslash consumes the closing quote and the remainder of the composed command (` 2>&1` and any following arguments) is absorbed into the string or reparsed by sh. Two corrections to the finding: `opts.root` is not a live vector, because `config.normalise_root` (config/init.lua:308-320) runs the value through `lib.nvim.fs.normkey`, which converts backslashes to forward slashes and strips trailing separators, so a root ending in `\` never reaches `popen_git`; and the Windows half is the inverse of what is claimed -- cmd.exe does not honour `\"` as an escaped quote at all, so there a value merely *containing* a `"` breaks out of quoting. Severity is below the SEC-03 finding, which already gives full execution on the same line through `$(...)`.

> **Abdeckung dieses Laufs.** Scope: read `lua/` (139 files, ~54 kLOC), `standalone/`, `scripts/`; ignored `.claude/`, `.git/`, `.deps/`, `doc/tags`, and `docs/map/` (generated artifact, not source). Roughly 5 600 LOC read in full or in the relevant region; the rest covered by pattern greps whose hits I then opened.

What I could NOT cover properly:
- `lua/documentation/core/render/html.lua` (10 185 lines, most of it embedded JavaScript in a Lua long string). I verified the escaping contract only at the places a grep pointed at: server-side `esc` = `lib.lua.strings.encoding.html_escape` at line 25, client-side `esc` at 1276, and the one unescaped `href` interpolation at line 4643 — that one is safe because `inlineMd` runs `esc(s)` over the whole string first, so a quote can never survive into the attribute. I did not audit the remaining ~9 900 lines of generated markup for SEC-23.
- `lua/documentation/core/check.lua` (~2 000 lines) and `core/scan.lua` (~830) were only spot-read around their file I/O and `pcall` sites; the individual drift checks were not reviewed.
- The 23 language backends under `core/lang/` were reviewed only for the patterns the rules name (`and false or nil`, `pcall(f(args))`, `fs_scandir` error handling). Their parsing logic was not audited.
- `TESTS/` (105 spec files) was not reviewed at all — no findings from there, and that is an absence of coverage, not a clean bill.
- `standalone/vim_shim.lua` (~790 lines) was read only around `vim.NIL` and `vim.json`; its `vim.*` emulation was not compared against Neovim semantics beyond that.

Rules I checked and found clean rather than inapplicable, so they are deliberately absent from both lists: PERF-07 (no `next`-based delete loops), PERF-62 / PERF-82 (the one debounce is created once behind an `entry.augroup` guard and cancelled in `uninstall`), PERF-80 (every `vim.system` completion callback wraps its editor work in `vim.schedule`, with the reason written at each site), PERF-93 (the only autocmds are `BufWritePost`/`BufReadPost`/`VimLeavePre` — no hot event), PERF-72 (root falls back to `vim.fs.root(markers)` then cwd), SEC-30 (`browse/filter.lua:108` matches with `find(…, 1, true)`), SEC-34/SEC-35 (no `vim.fn.expand` on buffer text; every `vim.cmd` takes a literal), ERR-51 (`DEFAULTS` is flat scalars, so the shallow `vim.tbl_extend("force", {}, DEFAULTS, …)` copies it fully), ERR-50 (unknown keys are checked before the merge), LUA-06 (`config/DEFAULTS.lua` is pure data — no env or filesystem lookup at module level), LUA-01/LUA-93 (`lib.nvim` is a bare hard `require` throughout and documented as required in `docs/requirements.md`; every install snippet carries `cmd = { "DocMap", "DocBrowse" }`), PRIN-10 (no globals, no `vim.g` writes), and ERR-11 at `editor/browse/trail_store.lua:215-231`, which already backs the original bytes up to `.corrupt` before falling through to an empty store — the fix the rules file records for this plugin is still in place.

One thing I could not confirm either way: `core/api.lua:136`/`204` pass a percent-decoded `snapshot` name straight into `runtime-analysis.telemetry.load_snapshot` / `loaded.load_snapshot` with no shape check. Whether a `../`-bearing name can escape that plugin's own snapshot directory depends on runtime-analysis.nvim, which is outside this repository and which I did not read. If it resolves the name as a path component, that is a SEC-42 finding at `lua/documentation/core/api.lua:94` (`M.decode_param`), reachable from the 127.0.0.1 server's `?snapshot=` query.

Three of the four `config.build` hosts (`scripts/action_run.lua`, `standalone/docmap.lua`) pass a `notify`; the three that do not (`editor/health.lua`, `bindings/usrcmds/init.lua`'s per-invocation path, `scripts/gen_map.lua`) are reported separately because they fail for different reasons and would be fixed in different places, but they share one root cause — `notify` being an optional argument on the function that owns every config-degradation warning.

---

## emojis.nvim

**11 Befunde** (5 × high, 2 davon in Testcode). Roh gemeldet: 12.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/emojis/search.lua:79` · `M.apply_across_files` · confidence **high**

**Befund.** The bulk-apply loop calls `fn.readfile(path)` (line 79), `fn.writefile(new_lines, path)` (line 95) and `vim.cmd("silent write")` inside `nvim_buf_call` (line 92) with no `pcall` anywhere, for every file rg reported.

**Regelbezug.** ERR-01 makes `pcall` mandatory at system boundaries (filesystem, external input). This is not a hotpath — it is a once-per-invocation loop over a handful of files, and every other failure mode in this module is reported through `notify`. A raising `readfile`/`writefile` escapes the loop entirely.

**Auswirkung.** Any file rg reported that is deleted, renamed, or made unreadable between the async scan and the user's confirmation -- or any read-only file on the write side, or a bogus path produced by the greedy parse at line 41 -- raises out of `M.apply_across_files` mid-loop. The files already processed stay rewritten and saved (buffers are written to disk at line 92), the remaining files are silently never touched, the summary notify at line 112 never runs, and the user sees a raw `Vim:E484` with no indication of how far the bulk operation got or which files changed. Partial, unreported mutation across the project, which is worse than either completing or refusing.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/emojis/actions.lua:132` · `M.edit / apply` · confidence **high**

**Befund.** With `preview.enable = true`, `M.edit` reads the buffer lines at line 94, hands the mutation to a `vim.defer_fn` callback that fires `preview.duration_ms` later (default 150 ms), and that callback writes the pre-computed `new_lines` back over `t.l1..t.l2+1` after re-checking only `nvim_buf_is_valid(t.buf)` — never the text it was computed from.

**Regelbezug.** ERR-30 requires every edit computed during a scan to be re-verified against the *current* text immediately before writing, and skipped on divergence. Handle validity is re-checked (ERR-33/LUA-13 are satisfied); buffer content is not. The module's own doc advertises the preview as non-blocking so Neovim 'stays responsive' — which is exactly the window in which the user keeps typing into the range being overwritten.

**Auswirkung.** Only with `preview.enable = true` (DEFAULTS.lua:177 ships it false, so the inline path is unaffected): any edit landing in `t.l1..t.l2+1` during the preview_duration_ms window -- the user typing, an LSP formatter, another autocmd -- is silently reverted by the deferred write. Because `strict_indexing` is false, `nvim_buf_set_lines` clamps rather than erroring, so there is no error and no warning; the user sees the success notify `[emojis] Removed N emoji`. Verified headless exactly as described. The loss is bounded to the action's own range and is undoable with `u`, so it is data reversion within one buffer, not unrecoverable corruption.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/emojis/config/init.lua:42` · `M.setup` · confidence **high**

**Befund.** `M.setup` merges immediately (`vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), user_opts)`) and only afterwards value-checks three fields (`overlay.mode`, `overlay.columns`, `default_scope`). There is no unknown-key validation anywhere in the plugin — a grep for `KNOWN`, 'unknown key' or a 'did you mean' suggestion over `lua/` returns nothing.

**Regelbezug.** ERR-50 requires config validation (unknown keys, 'did you mean …') to run *before* the merge, precisely because `tbl_deep_extend` silently absorbs a typo'd nested key into the result where it can never be detected afterwards. Here validation both runs after the merge and never covers unknown keys at all.

**Auswirkung.** Verified headless: `setup({ overlay = { colums = 3 }, preview = { enabled = true }, checkbox = { set = {...} } })` returns a config in which `overlay.colums = 3` sits next to `overlay.columns = 5`, `preview.enabled = true` next to `preview.enable = false`, and `checkbox.set` next to `checkbox.sets` -- with exactly zero notifications emitted. `:checkhealth emojis` only probes dependencies (health.lua:10-80, no config validation at all), so nothing surfaces there either. The typo'd option is inert, the real option silently keeps its default, and the user has no way to notice short of reading the plugin source.

### `PRIN-25` — Eingaben validieren

`lua/emojis/core/ops.lua:207` · `M.unreplace` · confidence **high**

**Befund.** The `:U+XXXX:` fallback token is parsed out of raw buffer text (`token:match("^U%+(%x+)$")`) and fed straight into `patterns.encode(tonumber(hex, 16))` with no range check; `encode` then does `string.char(0xF0 + math.floor(cp / 0x40000))`, which is out of byte range for any codepoint >= 0x400000.

**Regelbezug.** PRIN-25 requires arguments to be validated before they are worked with — here a value taken verbatim from an untrusted buffer reaches arithmetic that can only produce a valid byte for a bounded input. A codepoint above U+10FFFF is not a codepoint at all and must be rejected (left untouched, like any other unrecognised `:...:` token, which is what the function's own docstring promises).

**Auswirkung.** Two distinct consequences, both verified headless. (1) Raise: `:Emojis unreplace` on any scope whose text contains `:U+400000:` or a longer hex run raises out of `actions.edit` -- I confirmed `pcall(actions.edit, "unreplace", target)` returns false with `ops.lua:207: bad argument #1 to 'encode' (invalid value)`. `unreplace` takes the inline `apply()` path (actions.lua:140) with no pcall anywhere, so the user gets a raw Lua error instead of the module's notify contract and nothing on the line is restored. (2) Silent corruption, which the auditor missed: codepoints in 0x110000..0x3FFFFF do NOT raise -- `:U+110000:` produces the byte sequence F4 90 80 80, which is above U+10FFFF and therefore not valid UTF-8, and `unreplace` writes it into the buffer and counts it as a successful restore.

### `PRIN-25` — Eingaben validieren

`lua/emojis/search.lua:41` · `files_of / finish` · confidence **high**

**Befund.** ripgrep's `file:line:text` output is split with the greedy pattern `^(.+):%d+:` (same pattern again at line 180 for the quickfix entries). Greedy `.+` matches up to the *last* `:<digits>:` on the line, not the first, so any matched text that itself contains a colon-digits-colon sequence is folded into the file name.

**Regelbezug.** PRIN-25: the parsed path is used unvalidated as a real file path (`fn.bufnr`, `fn.readfile`, `fn.writefile`, quickfix `filename`). The correct split is the first `:%d+:` after the path, not the last.

**Auswirkung.** Triggered whenever a matched line contains both an emoji and a `:<digits>:` construct after the path -- a timestamp (`10:30:`), a ratio, or an embedded `file.lua:12:` reference. `:Emojis list cwd` then puts a quickfix entry with a non-existent filename and the wrong line number into the list (jumping to it opens an empty new buffer at that name). `:Emojis clear cwd` / `replace cwd` feed the same bogus path to `fn.bufnr` (returns -1, so `loaded` is false) and then to `fn.readfile` at line 79, which raises `Vim:E484: Can't open file` -- aborting the bulk run part-way through, after earlier files have already been rewritten and saved. Note this bug is the most likely real-world trigger of the unguarded-readfile finding at line 79.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/emojis/core/insert.lua:41` · `M.at_cursor` · confidence **medium**

**Befund.** `api.nvim_buf_set_lines` is called unguarded after checking only `nvim_buf_is_valid` — the buffer's `modifiable`/`readonly` state is never considered. The same pattern is in actions.lua at lines 130, 132 and 197, where `buf_ok()` likewise checks validity only.

**Regelbezug.** ERR-01: a write through a plugin API that can throw sits on a system boundary and needs a `pcall` (or a `modifiable` pre-check). The neighbouring cursor call on line 42 *is* pcall-wrapped, so the omission is inconsistent within the same function, and this module's contract is to return `false` on failure, not to raise.

**Auswirkung.** Verified headless with the real modules: `insert.at_cursor(glyph)` with a `nomodifiable` current buffer raises `insert.lua:41: Buffer is not 'modifiable'` instead of returning `false`, and `actions.checkbox("add", target)` on the same buffer raises `actions.lua:197: Buffer is not 'modifiable'` instead of notifying. Reachable whenever the current buffer is not writable when the glyph lands -- a help buffer, quickfix, a plugin scratch window, a `:set nomodifiable`/`readonly` file. The error escapes out of the picker/overlay callback as a raw Lua error rather than the module's documented false-return and notify contract. It is a broken-contract/ugly-failure bug, not data loss: nothing is written and the buffer is untouched.

### `ERR-03` — Explizite Rückgaben

`lua/emojis/init.lua:118` · `M.checkbox_add / M.checkbox_remove` · confidence **medium**

**Befund.** `local target = checkbox_target()` discards the second return value (the error string) and the `if target then` guard then returns without a word. `M.toggle` (line 106), which calls the identical helper, captures `target, err` and reports `scope error: …` through notify.

**Regelbezug.** ERR-03/PRIN-20: a relevant function must signal success/failure rather than fail silently. `checkbox_target()` is explicitly built as an `(target, err)` pair — the error is produced and then dropped at two of its three call sites.

**Auswirkung.** Latent, not currently observable -- the auditor overstated this. `checkbox_target()` returns nil only when `nvim_get_current_win()` or `nvim_get_current_buf()` hands back an invalid handle (init.lua:76/94, scope.lua:19/35), which does not happen in normal Neovim: the current window and buffer are valid by construction. Both non-visual branches call `scope_m.resolve("line", ...)`, which never reaches scope.lua's genuinely reachable failure paths ('cursor line is empty', 'cursor is not on a word' -- those belong to the `word` scope). So today `checkbox_add`/`checkbox_remove` never silently no-op. What is real is the inconsistency between three call sites of the same `(target, err)` helper: two of them structurally cannot report a failure, so the moment that branch becomes reachable (a new scope, a future failure mode in scope.resolve) the two API entry points and any keymap bound to them would do nothing at all while `toggle` reports it. Cheap to fix, no user-visible defect right now.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/emojis/config/init.lua:80` · `M.setup` · confidence **medium**

**Befund.** Value validation stops after three fields. `overlay.limit` and `preview.duration_ms` (plus `wrap.prefix`/`suffix`, `preview.hl_group`, `search.extra_args`) are stored unchecked and reach `math.min(overlay.limit or #sorted, #sorted)` (overlay/init.lua:105) and `vim.defer_fn(..., cfg.duration_ms)` (actions.lua:57) as-is.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and be surfaced via `:checkhealth`, rather than taking a code path down with it. `overlay.mode`/`columns`/`default_scope` do exactly that (warn + fall back); the remaining scalars have no such treatment, and `health.lua` reports no config validation at all.

**Auswirkung.** Verified headless against the real modules, not just the primitives. `setup({ overlay = { limit = "all" } })` then `overlay.open("grid")` raises `overlay/init.lua:105: bad argument #1 to 'min' (number expected, got string)` -- every `:Emojis overlay` throws instead of opening with the default of 20. `setup({ preview = { enable = true, duration_ms = "150ms" } })` then `actions.edit("clear", target)` raises `bad argument #1 to 'start' (number expected, got string)` from the `vim.defer_fn` at actions.lua:57 -- every `:Emojis clear`/`replace` throws. In both cases `setup()` itself completes silently and the failure only surfaces at use time as a raw Lua error, so the plugin reads as broken rather than misconfigured, and `:checkhealth emojis` gives no hint. Note a numeric string still works (`math.min("10", 5)` coerces), so only genuinely non-numeric values bite.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`.github/workflows/ci.yml:70` · `tests job` · confidence **medium** · _Testcode_

**Befund.** The test job runs `nvim --headless -u NONE -c "set rtp+=…" -c "luafile TESTS/run.lua" -c "qa!"`. The job's pass/fail therefore depends solely on `os.exit(1)` being reached inside run.lua — but `TESTS/run.lua:54` calls `dofile(dir .. name)` *outside* the per-spec `pcall` (only the returned function is pcall'd at line 55), and `run.lua:13`/`:18` run before any protection at all.

**Regelbezug.** LLS-31's core principle is 'fail loudly, never silently no-op' — a result formed from the planned rather than the actually performed work cannot be noticed. Here the green checkmark reports 'nvim exited', not 'the specs ran'. Related, same file family: `TESTS/run.lua:21` carries a hardcoded 22-entry spec list while its own header claims it 'loads every *_spec.lua in this directory', so a newly added spec silently never runs (the list happens to be in sync today).

**Auswirkung.** Verified: `nvim --headless -u NONE -c "luafile boom.lua" -c "qa!"` on a file whose first line is `error("boom")` prints `E5113: Lua chunk: boom.lua:1: boom` and exits with code 0. So a syntax or load-time error in any spec, a spec listed in run.lua but missing from disk, or a failure in harness.lua / frecency.set_path makes the CI 'Run TESTS suite' step pass green with zero checks executed -- the one gate meant to catch exactly that. Because `dofile` at line 54 sits outside the per-spec pcall, a load-time error in one spec also kills the whole run rather than being reported as one failing spec. One correction to the auditor's secondary point: the hardcoded list at run.lua:21 holds 22 entries and `TESTS/` contains exactly 22 `*_spec.lua` files, so nothing is being skipped today; the risk is prospective -- a newly added spec is silently never run, contradicting run.lua's own header claim at line 8 that it 'Loads every *_spec.lua in this directory'.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/emojis/util/lib.lua:120` · `M.map` · confidence **medium** · _Testcode_

**Befund.** `M.map` probes `lib.nvim.bindings.keymap` with `pcall(require, …)` and falls back to `vim.keymap.set`, while `lua/emojis/bindings/keymaps.lua:16` requires the very same module bare at module top level, and `commands.lua:17` / `actions.lua:15` require `lib.nvim.bindings.usercmd.composer` and `lib.nvim.ui.list` bare as well.

**Regelbezug.** LUA-01 requires the plugin to pick one policy for lib.nvim — hard (bare require) or soft (pcall + equivalent fallback) — and hold it. Here the same module is hard in one file and soft in another. The docs are honest (README and docs/requirements.md both call lib.nvim required, and health.lua reports a missing composer as `error`, not `warn`), so the doc half of the rule is satisfied; what remains is the inconsistency itself.

**Auswirkung.** No runtime defect; this is a maintainability and documentation-accuracy issue. The `vim.keymap.set` fallback at util/lib.lua:132 is unreachable on every supported path: `M.map`'s only caller is overlay/init.lua:265, and reaching the overlay through the documented route requires `setup()`, which bare-requires the same `lib.nvim.bindings.keymap` at bindings/keymaps.lua:16 and the composer at commands.lua:17. It can only fire via the raw Lua API on a machine that has ui.nvim but not lib.nvim and never ran `setup()`. The concrete wrongness is the doc claim: util/lib.lua's header and docs/requirements.md:6 both describe `lib.nvim.bindings.keymap` as soft/optional, which bindings/keymaps.lua:16 contradicts -- a reader trusting either will mis-model the dependency.

### `PRIN-25` — Eingaben validieren

`lua/emojis/nav.lua:92` · `M.next` · confidence **medium**

**Befund.** `for i = 1, math.max(count or 1, 1)` iterates the caller-supplied count with no upper bound; each iteration runs `scan()`, which walks buffer lines from the cursor to the end (plus a wrap pass from the top). `count` comes straight from `:Emojis next <n>`, which composer validates as an integer but does not bound.

**Regelbezug.** PRIN-25: an argument taken from user input must be checked before it is worked with. The loop's only exit is 'the cursor did not move', which never triggers while the buffer holds two or more emoji — the walk wraps and keeps moving.

**Auswirkung.** Measured headless on a 50-line buffer with two emoji: 20000 iterations took 1.117 s, i.e. ~56 us per step, so `:Emojis next 100000000` would spin roughly 93 minutes on the main loop with no progress indication and no interrupt check inside the Lua loop. Correcting the auditor's framing: the cost is linear and ordinary counts are perfectly fine -- this is not a hang at small n -- but there is no upper bound and no rejection of a nonsensical count, so one fat-fingered zero freezes the editor. The secondary point holds and is minor: `math.max(count or 1, 1)` at line 92 silently clamps `:Emojis next 0` and `:Emojis next -3` to a single forward step rather than rejecting them.

> **Abdeckung dieses Laufs.** COVERAGE. Read line by line and in full: every file under lua/ (23 files, incl. @types.lua) and plugin/ (2 files) — roughly 3,735 LOC — plus TESTS/run.lua and TESTS/harness.lua and .github/workflows/ci.yml. The 22 spec files themselves were only grepped (requires, filesystem writes, temp-path handling), not read line by line, so test-code findings are deliberately under-sampled. .claude/, .git/, .deps/ and doc/tags were ignored as instructed. No file in the plugin was modified.

VERIFICATION. Five findings were reproduced with headless nvim 0.12.2 rather than argued from reading: the stale preview overwrite (ERR-30), the `:U+400000:` crash (ops.lua:207), the greedy rg path split (search.lua:41), the config-type raises behind ERR-22, and the CI exit-code-0 hole. `nvim_buf_set_lines` was also checked to *clamp* rather than raise on an out-of-range end index, which is why the ERR-30 data loss is silent instead of erroring. The suite was run green beforehand (22 specs, 775 checks, with ../lib.nvim and ../ui.nvim on the rtp), so none of these findings is covered by an existing spec.

ALREADY TRACKED IN-CODE — NOT RE-REPORTED. Two CDX markers already name real silent-behaviour gaps, so reporting them back adds nothing: (1) config/DEFAULTS.lua:193 — `checkbox.default_set` is documented in DEFAULTS, in @types.lua:88/157 and in docs/configuration.md:67 ("or e.g. \"status\""), but a grep over lua/ confirms no code path ever reads it, so a user setting it silently gets 'search every set'; (2) search.lua:25 — RG_PATTERN covers three of the four core.patterns RANGES, so `cwd`-scoped list/count/clear/replace silently skips U+2300-23FF glyphs that every buffer scope matches.

DOC DRIFT WITH NO MATCHING RULE ID. @types.lua:30 describes the `cwd` scope as "ripgrep-based, async; list/count only", while commands.lua and search.lua SUPPORTED both route `clear` and `replace` through it — i.e. the most destructive operation in the plugin (rewrite + save every matched file across the project) is annotated as not existing. health.lua:56/58 and docs are correct; only the type alias is stale.

RULES I COULD NOT SETTLE. CMT-16: docs/map/ and docs/BINDINGS.md look generated (plugin/emojis_autodoc.lua regenerates helptags), but I did not run the generator, so I cannot say whether either file has been hand-edited or has drifted — unverified, not clean. ERR-53/ERR-54: `config.checkbox_sets()` hands out live references into the active config's set tables (out[#out+1] = set, and `return { set }`) rather than copies, and its docstring does not say 'live reference, do not mutate'; I traced every consumer (core.checkbox.toggle/add/remove, actions.checkbox) and none mutates today, and `init.cascade_groups` deepcopies before handing the sets outside the plugin, so there is no current defect to report — only a latent one. LUA-02: whether any fix here belongs upstream in lib.nvim needs cross-repo context I did not gather. PERF-46/47: the frecency store's `_store`/`_path` caches have no TTL and `reset()` replaces the table instead of clearing in place, but no consumer holds a reference across a reset, so neither rule bites. LUA-06 is clean — DEFAULTS.lua's only module-level require is core.patterns, which is pure byte arithmetic (matching the rule's own Belege note for this plugin).

---

## fileops.nvim

**11 Befunde** (5 × high). Roh gemeldet: 12.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/fileops/ops/cycle.lua:151` · `list_files` · confidence **high**

**Befund.** `local ok, err_or_iter = pcall(vim.fs.dir, dir)` is meant to catch "dir does not exist or is not readable" (the comment on line 153 says so) and return an empty list — but `vim.fs.dir` never raises for a missing directory, so the guard never fires and the empty list is returned without any error either way.

**Regelbezug.** ERR-11 requires "empty but fine" to be distinguishable from "empty because broken". Both collapse onto the same empty table here, and `navigate`/`jump_edge` then turn both into the single message "no files in directory".

**Auswirkung.** When the current buffer's directory has been renamed, deleted, or lives on a dropped network share, `:File next/prev/first/last`, the default `<leader>nf`/`<leader>pf` keys and `fileops.next()/prev()/first()/last()` all report "no files in directory" — byte-identical to a directory that genuinely holds no matching files. The user is pointed at the directory's contents rather than at its absence. `ops/bulk.lua:36` shows the wording the codebase itself considers correct ("cannot read directory"), which this module structurally cannot produce.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/fileops/bindings/keymaps.lua:120` · `bulk_rename` · confidence **high**

**Befund.** `local plan = bulk.plan(dir, pattern, replacement or "", {})` discards `plan`'s second return value, the error string, so an invalid Lua pattern is reported as a successful run over zero files.

**Regelbezug.** ERR-11: `bulk.plan` deliberately returns `({}, err)` to separate "nothing matched" from "the pattern is broken"; dropping `err` collapses them again. The `:File bulk rename` path does it correctly at `bindings/usrcmds.lua:364-368`, so the same plugin answers the same question two different ways.

**Auswirkung.** A user who mistypes the Lua pattern in the two-step `bulk_rename` prompt is told "bulk rename: 0 file(s) renamed" — indistinguishable from a valid pattern that matched nothing — and never learns the pattern was rejected, while `:File bulk rename` with the identical pattern names the error. Narrower than the finding implies: `bulk_rename` has no default lhs (DEFAULTS.lua:89 leaves it commented out), so only users who explicitly bind it are affected.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/fileops/ops/file.lua:657` · `delete_path_from_disk` · confidence **high**

**Befund.** `local trash = opts.mode == "trash"` treats every value that is not exactly the string `"trash"` as "permanent", and nothing validates `delete.mode` on the way in from `setup()`.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its *default* and to be made visible via `:checkhealth`. Here an invalid value degrades to the opposite of the default (`DEFAULTS.lua:31` is `mode = "trash"`), and `health.lua` never looks at `delete.mode` at all.

**Auswirkung.** A capitalisation or spelling typo in `delete.mode` ("Trash", "trash ", "recycle") silently selects permanent `fs_unlink` instead of the OS trash — the opposite of the documented default — for `:File delete`, the default-bound `<leader>dcf` key (DEFAULTS.lua:57,70), `fileops.delete_current()`, and the asset cascade in `delete_path`. The file is gone with no undo, the success message still reads "deleted <name>", and neither `:checkhealth fileops` nor anything else surfaces that the configured value was not understood.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/fileops/ops/cycle.lua:238` · `M.open_path` · confidence **high**

**Befund.** `require("ui.kit")` is a bare, unguarded require with no fallback, and the same is true at `bindings/usrcmds.lua:280` and `:384`, `bindings/keymaps.lua:67` and `:98`, `integrations/filetree_assets.lua:118`, and `integrations/menu.lua:24` (module level) — while `docs/installation.md:23` lists ui.nvim under "Optional", in a table whose header promises each entry is "detected at runtime and degrading to nothing when absent".

**Regelbezug.** LUA-01 allows a hard dependency (bare require) or a soft one (pcall + fallback) but requires consistency, and states outright that a hard dependency may never be presented as optional in the documentation. `util/notify.lua` is the soft form; these six sites are the hard form for a plugin the docs call optional.

**Auswirkung.** Without ui.nvim installed, the default path throws "module 'ui.kit' not found": `:File next/prev` (and the default `<leader>nf`/`<leader>pf` keys) on a modified buffer, any `:File rename/move/duplicate/copy/touch/new` issued without an argument — each documented to prompt — and `:File bulk rename`. `:checkhealth fileops` reports nothing about it and instead vouches for `vim.ui.select`, which nothing in the plugin calls. The docs promise the opposite ("degrading to nothing when absent"), and the test harness stubs the module, so neither CI nor the health check can surface the mismatch. The two opt-in keymap sites (keymaps.lua:67, :98) and the filetree asset confirm are unbound/inactive by default, so the blast radius is the three default-reachable paths above.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/fileops/ops/file.lua:65` · `resolve_path` · confidence **high**

**Befund.** Every user-supplied destination path is run through `vim.fn.expand(raw)` before use, so a backtick span in the argument is executed as a shell command substitution via `&shell`.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on buffer/user text precisely because a backtick span is a shell command substitution and `%`/`#`/`<cfile>` are Vim specials; it names `lib.nvim.cross.fs.expand_path` as the `~`+env-only replacement. This repo already uses that function at `bindings/usrcmds.lua:148`, but `resolve_path` re-expands afterwards anyway, so no entry point is protected.

**Auswirkung.** Any destination path a user pastes or types that contains a backtick span is executed as a shell command via `&shell` before it is ever treated as a filename — reachable from `:File new/write/saveas/writeto/touch/rename/move/duplicate/copy`, from every `ui.kit` destination prompt (usrcmds.lua:279-290), and from the public `fileops.new_file()/touch()/rename()/move()/copy()/duplicate()` Lua API. `%`, `#`, `<cfile>` are likewise expanded (the `%` case is deliberate — usrcmds.lua:139-141 offers it as a completion candidate — the shell case is not). Secondary: because `fn.expand` is unguarded, a backtick span whose command writes nothing raises a raw E282 out of an op documented to return `(false, msg)`.

### `ERR-03` — Explizite Rückgaben

`lua/fileops/init.lua:10` · `M.setup` · confidence **medium**

**Befund.** `if _setup_done then return end` makes every `setup()` call after the first a silent no-op that discards its entire argument; the function returns nothing and notifies nothing.

**Regelbezug.** ERR-03/PRIN-20: a function that cannot do what it was asked must say so rather than fail silently. This is the same shape as the github_stats `LUA-87` finding — `setup()` quietly throwing away every option the caller passed.

**Auswirkung.** Every `setup()` after the first is a silent no-op that throws away its whole argument. Two lazy.nvim spec fragments for the same plugin, an `opts` table combined with a `config = function() ... setup() end` block, or `:source $MYVIMRC` to re-apply a changed config, all leave the user with settings visible in their config file that never reach the plugin and no message explaining why. Note this also masks the ERR-53 finding above: because the guard fires first, the config sub-table divergence is not reachable through this entry point.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/fileops/ops/bulk.lua:34` · `M.plan` · confidence **medium**

**Befund.** `local ok, iter = pcall(vim.fs.dir, dir)` guards a failure `vim.fs.dir` does not produce, so the documented `"cannot read directory: " .. dir` return is unreachable and a missing/unreadable directory produces `({}, nil)` — the same answer as a directory with no matching files.

**Regelbezug.** ERR-11: the function's own contract (`@return string|nil err`) promises to tell "empty but fine" from "empty because broken", and cannot keep it.

**Auswirkung.** `:File bulk rename` in a directory that has been removed or on a dropped share hits `bindings/usrcmds.lua:369-372` and reports "bulk rename: no files in %s matched %q", so the user retypes the pattern instead of checking the directory. The documented `"cannot read directory: "` return is dead code. Mildly less harmful than the cycle case because the message at least names the directory — and the same call path via `bindings/keymaps.lua:120` drops the err entirely anyway.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/fileops/features/on_hold.lua:423` · `M.setup.run` · confidence **medium**

**Befund.** `api.nvim_buf_set_extmark(buf, NS, lnum - 1, 0, …)` is called unguarded with an `lnum` captured at line 413, before two async git subprocess round-trips (`git blame` → `git show`); `still_valid()` re-checks the buffer and window handles but never re-checks that the buffer still has that many lines or that the cursor is still there.

**Regelbezug.** ERR-30 requires an edit computed during a scan to be re-verified against the *current* text immediately before it is written. The line index is the computed part here, and it is written blind. LUA-12 also applies: this is the one `vim.api` call in the file with neither a pcall nor a precondition check.

**Auswirkung.** For users who opt into `on_hold` (DEFAULTS.lua:99 has `enable = false`, so this is opt-in): if the buffer shrinks below the captured line while the two git subprocesses run — `:e!`, an external reload, a formatter, undo of a large paste — the CursorHold handler raises an uncaught `Invalid 'line': out of range` at the user. The reliably-reached case is milder but certain: since `CursorMoved` does not bump the generation, moving the cursor during the git round-trip still passes `still_valid()`, so the previous line's committed content is parked as virtual text on a line the cursor has already left, until the next move clears it. Not a data-loss bug — the mis-severity in the original finding is calling the crash the primary consequence.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/fileops/config/init.lua:14` · `M.setup` · confidence **medium**

**Befund.** `M.setup` deep-merges user options straight into a copy of DEFAULTS with no validation step anywhere — no unknown-key check, no enum check, no "did you mean" — and `health.lua` inspects nothing from the merged config either.

**Regelbezug.** ERR-50 requires config validation to run *before* the merge, because a typo in a nested option otherwise disappears silently into the defaults and is never detected. With no validation at all, that is exactly what happens; the `@types/init.lua` annotations are LuaLS-only and do not run.

**Auswirkung.** `setup({ delete = { mode2 = "trash" } })`, `setup({ cycle = { open_taget = "split" } })` or `setup({ keymaps = { lsh = {...} } })` are accepted without a word: `tbl_deep_extend` writes the unknown key into the active config next to the correct one, nothing ever reads it, and the user gets default behaviour with no diagnostic anywhere. This is also the missing gate that lets the `delete.mode` case above turn a typo into permanent deletion. Lower severity on its own than the auditor implies — it is the absence of a guard rather than a wrong action — but it is the enabling condition for the ERR-22 finding.

### `ERR-53` — In-place-Mutation statt Tabellen-Ersatz bei geteilten Referenzen

`lua/fileops/config/init.lua:16` · `M.setup` · confidence **medium**

**Befund.** `_active = vim.tbl_deep_extend(...)` replaces the whole config table rather than deep-mutating it in place, while `bindings/init.lua:21-23` hands the sub-tables `cfg.auto_mkdir`, `cfg.on_hold` and `cfg.conflict_marks` to modules that keep those references alive in their autocmd closures for the rest of the session.

**Regelbezug.** ERR-53: when sub-modules hold a direct reference to a sub-table of the central config, the merge must mutate in place; replacing the table silently decouples those references from the new values.

**Auswirkung.** A second `require('fileops.config').setup(...)` leaves the already-registered auto_mkdir autocmd and the on_hold / conflict_marks feature closures reading the *previous* values, while `config.get()` returns the new ones — two disagreeing views of one config with nothing to indicate it. Narrower than the finding states in two ways: the auditor's own reproduction uses `delete.mode`, which is not a held reference at all (both `bindings/usrcmds.lua:504-508` and `bindings/keymaps.lua:162-166` re-read `config.get().delete` per invocation and are unaffected); and `fileops.setup()` short-circuits on its second call (init.lua:10-13), so the divergence is only reachable by calling `fileops.config.setup()` directly, not through the documented entry point.

### `XP-01` — `glob`/`globpath` lesen ihr Argument als Pattern, nicht als Pfad

`lua/fileops/bindings/usrcmds.lua:130` · `complete_from_bufdir` · confidence **medium**

**Befund.** `vim.fn.getcompletion(bufdir .. "/" .. arg_lead, "file")` feeds a raw directory path — taken from `vim.fn.expand("%:p:h")` on line 125 — to a call that reads its argument as a file *pattern*, not as a path.

**Regelbezug.** XP-01's subject is exactly this: `glob`-family calls interpret `~`, `[`, `?`, `*`, `{}` in the argument and answer an unmatched pattern with an empty list and no error, so "list the files in this directory" must never be spelled by handing them a raw path.

**Auswirkung.** Any buffer whose directory path contains a glob metacharacter (`[`, `]`, `?`, `*`, `{`, `}`) gets a silently empty `<Tab>` for `:File rename/move/copy/duplicate/new/touch`, which reads as "there is nothing here" rather than "the path could not be resolved as a pattern". Completion-only: the user can still type the path, so nothing is lost or corrupted. I could not reproduce the 8.3 `STEFAN~1` variant the finding also claims — this profile is `C:\Users\bartl` (5 characters), my temp path came back in long form, and completion against it worked, so that half of the impact does not apply here.

> **Abdeckung dieses Laufs.** COVERAGE. Read all 18 production modules under lua/fileops/ plus plugin/fileops.lua in full (4261 lines), README.md, docs/installation.md, docs/README.md, and TESTS/run.lua + harness.lua + the relevant sections of on_hold_preview_spec.lua and file_paths_spec.lua. Ignored .claude/, .git/, .deps/, doc/tags as instructed. Ran the plugin's own suite (20 specs, 831 checks, green) and then five purpose-written headless probes against the real modules; every "confirmed" claim above is backed by observed output, not by reading alone.

NO TEST-CODE FINDINGS. Nothing under TESTS/ violates one of the 76 rules on its own. The suite's one structural weakness is reported as part of the LUA-01 finding instead: TESTS/harness.lua stubs `ui.kit`/`ui.contextmenu` into `package.loaded`, which is why an unguarded hard dependency on ui.nvim can sit in six production call sites and still show a green suite.

FALSE LEAD I CHECKED AND CLEARED (do not re-file). `features/on_hold.lua:233` calls `fn.fnamemodify(file, ":t")` inside a `vim.system` on_exit callback, i.e. in a fast-event context, which looks like a PERF-80 violation and which the plugin's own `util/git.lua:81-83` comment says is forbidden. It is not a live bug on the installed Neovim: I measured `vim.in_fast_event() == true` there while `vim.fn.fnamemodify` succeeded (only `nvim_call_function` and `nvim_create_buf` raise E5560 on nvim 0.12.2), and `on_hold_preview_spec.lua` drives that exact two-subprocess chain end to end and passes. I could not test Neovim 0.9/0.10, which the README still claims support for, so a residual risk remains there.

THINGS I SAW THAT NO RULE IN THE 76 COVERS, listed so they are not lost: (1) `features/on_hold.lua:326` sets `vim.o.updatetime = 100` globally and unconditionally when the feature is opted in, with no config key and no restore — it changes CursorHold timing, swap writing and gitsigns for the whole session. (2) `util/git.lua`'s three `_async` twins have no production caller (its own header says so) while `features/on_hold.lua:143-185` keeps near-identical private copies — a fix to one will not reach the other. (3) `ops/bulk.lua:88` calls `fsops.rename_file` without the `retry_opts(...)` every other mutation in the plugin passes, so a bulk rename gets none of the Windows sharing-violation retry budget. (4) `config/init.lua:6` exposes `M.DEFAULTS` as a live reference to the shared defaults table; `M.get()` at least documents itself as a "read-only view", which I judged sufficient for ERR-54, but `M.DEFAULTS` carries no such note and a consumer mutating it would poison every later `setup()`. (5) `ops/file.lua` is 984 lines covering create/rename/delete/info/path/cd/lock-diagnosis — coherent but the weakest PRIN-01 story in the repo; I did not file it because the split is defensible.

WHAT I COULD NOT CHECK. lib.nvim itself is a hard dependency and out of scope, so anything that happens inside `lib.nvim.cross.fs.mutate`, `lib.nvim.fs.trash`, `lib.nvim.bindings.usercmd.composer` or `lib.nvim.buffer.open_background` (retry semantics, argv handling, timeouts) is unverified from here — several of my confidence calls assume those behave as documented. Everything was exercised on Windows 11 / nvim 0.12.2 only; the Linux and macOS branches (notably `ops/cycle.lua`'s symlink handling and the `retry.attempts = 1` POSIX default) were read but not run. docs/map/ is generated output (index.html, module_map.json, overview.md, all timestamped together) and I found no sign of a hand edit, but I did not re-run its renderer to diff it, so a CMT-16 drift would not have shown up; note the map was generated 2026-09-14 while docs/ changed on 2026-09-17, so it may simply be stale.

---

## hover.nvim

**11 Befunde** (6 × high). Roh gemeldet: 11.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/hover/preview/office.lua:244` · `M.preview` · confidence **high**

**Befund.** `_running[key] = true` is set at line 242, then `pdfport.create{...}` is called with no `pcall`. `_running[key]` is cleared only inside pdfport's `__callback`. The surrounding `build_async` (`lua/hover/init.lua:398`) calls the previewer bare -- `local provisional = run(...)` -- so a raise here propagates out through `build` -> `M.show` -> `M.trigger` -> the CursorHold autocmd.

**Regelbezug.** ERR-01 -- a call into a foreign plugin's API is a system boundary and belongs in a `pcall`. The two pdfport calls immediately above it (`require` at 231, `can_create` at 236) are both guarded; this one, the only one that mutates module state first, is not.

**Auswirkung.** Two consequences, and the second is the durable one. (1) The raise is not swallowed: M.trigger debounces through lib.nvim.debounce, whose timer callback calls `fn` bare inside vim.schedule (debounce/init.lua:68-72), so the error escapes as an unprotected `Error executing vim.schedule lua callback` trace on each cursor stop over the document -- lib.nvim's autocmd pcall wrapper (bindings/autocmd/init.lua:251-259) does not cover it, because show() runs from the debounce timer and not from the autocmd body. (2) `_running[key]` stays true for the rest of the session, so office.lua:227-229 answers every later hover on that document with the `converting to PDF…` pending badge while nothing is converting; only an explicit `office.reset()` (line 283) clears it.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/hover/preview/text.lua:41` · `head` · confidence **high**

**Befund.** `head()` returns `{}, false, 0` when `io.open(path, "r")` fails -- byte-identical to the return for a file that genuinely has no lines. `M.file` then takes the `#lines == 0` branch and renders `(empty file, <size>)` (line 122).

**Regelbezug.** ERR-11 -- a function whose result can legitimately be empty must make "empty, but ok" distinguishable from "empty, because it could not be read". `M.directory` in the very same file does draw that line (`(cannot read directory)` at line 168); the file path does not.

**Auswirkung.** classify.lua:120 already stat'd the path and classify.lua:132 routed directories elsewhere, so this branch is reached for a regular file that exists but cannot be opened: no read permission, a FIFO, or a file another process holds exclusively (routine on Windows). The float then reads `(empty file, 1.2 MB)` -- self-contradicting, since target.size comes from the same stat -- and the reader is told the file has no content rather than that hover could not open it. No error is raised and nothing else reports the failure; the wrong answer is also cached under cache.key, so it persists until the mtime changes.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/hover/init.lua:1252` · `M.open` · confidence **high**

**Befund.** `if ok_player and argv and pcall(media.play, what) then M.hide(); return true end` -- the branch tests `pcall`'s own success flag as if it were `media.play`'s answer, discarding the value `media.play` actually returned.

**Regelbezug.** LLS-31 -- a function that forms its return from the planned rather than the actual work cannot fail visibly. `lua/hover/preview/external.lua:198-203` makes the identical call and spells the correct form out in a comment ("`pcall`'s own success flag is not that second answer -- `pcall(f)` reports `true` for any `f` that returns without erroring, including one that returns `false, \"reason\"` on purpose"). The two call sites in one plugin disagree.

**Auswirkung.** When media.play declines without raising -- a configured player binary that is missing, an unreachable handler -- init.lua:1253-1254 still calls M.hide() and returns true. Pressing <CR> on a media hover makes the float disappear, nothing opens, and the `nothing here can open …` warning at init.lua:1305 is not reached. Narrower than the auditor implies: the branch is entered only when the `media` plugin is installed, media.is_media(what) is true, and media.core.play.player() returns an argv (lines 1247-1251), so a machine with no player configured at all takes the open.nvim/vim.ui.open path instead.

### `PERF-46` — Cache-Key vollständig

`lua/hover/cache.lua:63` · `M.key` · confidence **high**

**Befund.** The preview cache key is `type|raw|path|anchor|mtime`. The line number a target named lives in `found.line`/`found.line_end` and is threaded separately into `preview_opts.line`/`line_end` (`lua/hover/init.lua:847-848`), where `preview.text.file` uses it to pick the window of lines *and* to build the float's title (`lua/hover/preview/text.lua:102-107,132-139`). Neither value is in the key.

**Regelbezug.** PERF-46 -- the key must contain every parameter that influences the result. `bare_path.split_location` deliberately strips the `:42` suffix off `target.raw` before `classify` sees it, so two targets that differ only in line number are byte-identical to `M.key`.

**Auswirkung.** Hovering `init.lua:42` and then `init.lua:100` in the same buffer (a log, a diff, a stack trace -- the population bare_path's `:line` handling was written for) serves the second from the LRU: the float shows lines 39-58 under the title `init.lua:42`. Because text.lua:132-140 derives the title from opts.line, the cached title asserts the first target's line, so the wrong content carries a confident, wrong label rather than looking stale. Entries survive until cache.reset() or the 64-entry LRU evicts them; an mtime change also breaks the collision, so editing the file masks it.

### `PERF-62` — Timer sauber stoppen

`lua/hover/preview/shot.lua:285` · `cancel` · confidence **high**

**Befund.** `cancel()` calls `_pending.timer:stop()` on the `vim.defer_fn` handle from line 475 and then drops the reference (`_pending = nil`); it never calls `timer:close()`.

**Regelbezug.** PERF-62 requires `timer:stop()` **and** `pcall(timer.close)` before a debounce timer is replaced -- stopping alone leaves the libuv handle registered on the loop. `lua/hover/preview/playback.lua:139-142` and `lua/hover/status_view.lua:721-726` both do it correctly in this same repository, so this is the outlier rather than the house style.

**Auswirkung.** Narrower than the auditor states. cancel() runs at shot.lua:459 on every M.preview call, but it only leaks when `_pending` is non-nil -- that is, when a previous render was still inside its shot_delay_ms window (default 1000 ms) and had not fired. A timer that fires clears `_pending` itself at line 476 and vim.defer_fn closes it. So the leak is one un-closed uv_timer_t per *cancelled pending* render: scrolling through a document of links faster than the render delay accumulates one handle per link passed, held on the event loop until the process exits. Not one per link in the general case.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/hover/classify.lua:52` · `resolve_path` · confidence **high**

**Befund.** `resolve_path` hands the raw link target -- the string a registered scanner (markdown.nvim) read out of the buffer between `[text](` and `)` -- straight to `vim.fn.expand()` before resolving it against the document's directory.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on buffer/user text: a backtick span in the argument is a *command substitution* run through `&shell`, and `%`, `#`, `<cfile>`, `<cword>` are Vim specials. Nothing between the scanner and this line escapes or rejects either. The identical defect was found and fixed in markdown.nvim and images.nvim; hover.nvim reaches `expand()` on the same class of text through its own resolver.

**Auswirkung.** A link target containing a backtick span reaches Vim's file-name expansion, where backticks are a command substitution through &shell -- so `[pic](`cmd`.png)` in an attached buffer runs `cmd` on the automatic CursorHold trigger, with no keypress. This route needs a registered link scanner (markdown.nvim's), because hover's own bare_path source filters its token through 'isfname', which excludes the backtick by default. Two corrections to the auditor's impact: the `#` claim is wrong -- a leading `#` is returned as an anchor at line 94 and a mid-string `#` is split off at line 113, so `#` never reaches line 52; and `%` is only a Vim special when it is the *first* character of the argument (`:help expand()`), so `[cfg](%APPDATA%/nvim/init.lua)` resolves to the current file's name plus the remainder, while a `%` anywhere else is harmless.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/hover/preview/media.lua:823` · `M.pdf.render` · confidence **medium**

**Befund.** `pdfport.render_page(target.path, page, {...}, callback)` is called with no `pcall`, although the `require` above it (line 769) and the capability probes (lines 705-708) are both guarded. `build_async` calls the previewer bare, so a raise reaches the CursorHold autocmd.

**Regelbezug.** ERR-01 -- calls into a foreign plugin API run through `pcall`. This is the busiest such call in the plugin: it fires for every local `.pdf`, every page turn, every zoom step and, via `preview.webpdf`/`preview.office`, for every downloaded or converted document.

**Auswirkung.** A raise from pdfport -- a changed signature, a rejected crop rect, a bad option table -- escapes as an unprotected `Error executing vim.schedule lua callback` trace, because M.trigger debounces through lib.nvim.debounce whose timer callback invokes fn bare inside vim.schedule (debounce/init.lua:68-72), outside lib.nvim's autocmd pcall wrapper. The float shows nothing and the trace repeats on each cursor stop over the PDF, instead of degrading to the `PDF · <size>` metadata line M.pdf already returns for every other failure path (lines 761-767, 771, 780, 852). Unlike office.lua:244 no module state is left stuck -- media.lua's page cache is only written in the success branch at 829-832.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/hover/init.lua:1298` · `M.open` · confidence **medium**

**Befund.** `local ok_ui = pcall(vim.ui.open, what)` -- `vim.ui.open` reports failure by *returning* `nil, errmsg` rather than raising, and both return values are discarded; `ok_ui` is then used as the "it opened" test.

**Regelbezug.** LLS-31, same inversion as line 1252: the return is formed from the attempt rather than the result. This is the last fallback in `M.open`, so it is what decides whether the reader is told nothing could open the target.

**Auswirkung.** On a machine with no registered handler for the target's type, vim.ui.open returns nil plus an error string without raising, pcall reports true, and M.open closes the float and returns true. <CR> on the hover makes the preview vanish, nothing opens, and the warning at init.lua:1305 is unreachable -- the reader gets a blank screen and no message, at the exact point written to catch that case. Worth noting the neighbouring open.nvim call at init.lua:1290 has the same shape, but there the comment at 1277-1281 shows the author knew and chose it deliberately; here there is no such note.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/hover/init.lua:215` · `M.enable` · confidence **medium**

**Befund.** `M.enable` merges the installation spec's `opts` first (line 209) and only then calls `persist.load()`, which feeds the previous session's `hover/status.json` through `config.setup(saved)` (`lua/hover/persist.lua:161-164`) -- so the file wins over `setup()`. `persist.snapshot()` writes `mode`, `auto_hover` and all twelve switch flags on every `VimLeavePre` unconditionally, with no record of whether the reader ever toggled any of them.

**Regelbezug.** LUA-87 -- the order must be file (or default) as the base, `setup()` arguments winning above it; the other way round, `setup({...})` silently discards options as soon as the file exists. Because the snapshot carries no `explicit` set, a value that only ever came from the spec is written back and then re-applied over that same spec, so "the reader chose this" and "this was the spec's value at exit" are collapsed (the ERR-10/PRIN-26 shape underneath it).

**Auswirkung.** After any session in which enable() ran, editing `mode`, `auto_hover`, or any of `links.enabled/web/fetch`, `links.pdf.enabled`, `links.shot.enabled/eager`, `paths.enabled/missing/code`, `positions`, `inline_images` or `office.convert` in the installation spec has no effect: M.setup applies the new value and persist.load() overwrites it six lines later with last session's copy of the old one. Because the snapshot has no explicit-set, a value that only ever came from the spec is written back and then re-applied over that same spec, so "the reader toggled this" and "this was the spec's value at exit" are indistinguishable. Correcting the auditor on one point: this is not undocumented -- docs/configuration.md:347-370 states the DEFAULTS -> spec -> last session order outright, names the JSON file under stdpath("cache"), and offers `persist = false` as the opt-out, and `:Hover dashboard` reports the live state. The defect is the unconditional snapshot, not a hidden file.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/hover/persist.lua:161` · `M.load` · confidence **medium**

**Befund.** The snapshot read back from `stdpath("cache")/lib.nvim/cache/hover/status.json` is passed to `config.setup(saved)` after a single `type(saved) == "table"` check. No field is validated for type, and no key is restricted to the set `M.snapshot()` writes; `config.setup` itself re-checks only `mode` (`lua/hover/config/init.lua:252-254`).

**Regelbezug.** SEC-33 -- a persisted snapshot is untrusted on load and every field has to be re-validated (type, length, count cap). The write side is disciplined (booleans and one enum); the read side accepts whatever the file happens to contain and merges it into the live configuration.

**Auswirkung.** Real but narrower than "a truncated file": a truncated JSON fails to decode and disk.load returns nil, so the exposure is a file that parses but carries keys or types the write side never produces -- hand-editing, a partial write, or a future format change. Such a file merges straight into the live configuration and is then read unvalidated: `max_lines = {}` survives config/init.lua:559 (`c.max_lines or DEFAULTS.max_lines` -- a table is truthy) and reaches preview/text.lua:49 `#out >= limit`, raising "attempt to compare number with table" from the debounced CursorHold path; `links.timeout_ms = "soon"` survives config/init.lua:563 and is handed downstream as a timeout. Either fails as an error trace rather than as a rejected option, and survives restarts because nothing rewrites the file until VimLeavePre.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/hover/bare_path.lua:314` · `via_cfile` · confidence **medium**

**Befund.** `via_cfile` takes the `<cfile>` token, strips surrounding delimiters and a `:line` suffix, and passes the remainder to `vim.fn.expand()` to resolve it against the buffer's directory. `trim_delimiters` (line 187) removes backticks only at the *ends* of the token.

**Regelbezug.** SEC-34 -- `vim.fn.expand()` on buffer text. Rated below the `classify.lua` case because `'isfname'` excludes the backtick in Neovim's stock Unix and Windows defaults, so the shell path needs a reader who widened `isfname` (which `TESTS/bare_path_spec.lua:117` shows is a setting this plugin's behaviour is sensitive to). The Vim specials need no such precondition: `%` is in the default `isfname` on Unix, and `#` is never stripped here the way `classify` strips it.

**Auswirkung.** Two concrete effects, both narrower than the auditor's wording. (1) Shell: a backtick span in the token is a command substitution through &shell, but 'isfname' excludes the backtick in Neovim's stock Unix and Windows defaults, so this needs a reader who widened 'isfname' -- a real but opt-in precondition. (2) Vim specials: `:help expand()` applies cmdline-special expansion only when the argument *starts* with `%`, `#` or `<`. So the auditor's `60% / 27%` example is harmless -- those tokens end with `%`. The real case is a token that begins with one, e.g. `%APPDATA%\nvim\init.lua` pasted into prose or a config snippet: 'isfname' includes `%` and `\` on Windows, trim_delimiters does not strip `%`, looks_like_path accepts it on the separator, and line 314 expands it to the current buffer's name plus the remainder -- so the uv.fs_stat at 318/333 tests a path that is not the text under the cursor, and any hit is previewed as if it were.

> **Abdeckung dieses Laufs.** Read-only audit; nothing in E:/repos/hover.nvim was modified. .claude/, .git/, .deps/ and doc/tags were skipped as instructed.

Method and coverage. I read the full rules file first, then read completely: README.md, config/DEFAULTS.lua (skimmed, plus every `video.*` type annotation), config/init.lua, cache.lua, classify.lua, registry.lua, persist.lua, scope.lua (decision half), bindings/autocmds.lua, preview/external.lua, preview/webpdf.lua, preview/text.lua (read half), preview/office.lua (conversion half), float.lua (open/close/contains), plugin/hover.lua, scripts/minimal_init.lua and scripts/test.sh. init.lua (2225 lines), media.lua (958), status_view.lua (914), playback.lua (828), url.lua (783), shot.lua (485), health.lua (509), video.lua (582) and align_win.lua (460) were covered by targeted reads around every grep hit rather than end to end.

What I could not check, and why.
- I did not start Neovim or run the spec suite, so no finding is confirmed by execution. The SEC-34 shell behaviour rests on the rule's own measurement plus the markdown.nvim/images.nvim precedent, not on a run here.
- CMT-16: docs/map/overview.md and docs/map/index.html are generated by `:DocMap`/scripts/gen_map.lua and carry the "Do not edit by hand" banner. I could not regenerate them to test for drift (that needs documentation.nvim on the rtp), and I found no hand-edit evidence in the files themselves, so no finding either way. The header's "3 modules · 33 helper files" against 40 Lua files is worth one regeneration run by someone who has the generator.
- The whole LLS family except LLS-31 is out of scope without a LuaLS run; .luarc.json exists but I did not execute lua-language-server.
- The embedded PowerShell, AppleScript and bash scripts in preview/align_win.lua were reviewed only for how values reach them (integers via `param()` / baked-in numbers -- no user strings, so SEC-46 and SEC-35 do not bite) and not audited as programs in their own right.
- status_view.lua (914 lines, the ui.nvim board) and health.lua (509 lines) were checked for timers, geometry, `vim.g` and secret handling only. Their rendering logic is unreviewed.
- preview/playback.lua's frame-pump arithmetic and preview/url.lua's ~40-pass HTML flattening were read for structure and sanitization ordering but not line by line.

Judgment calls I decided *not* to report, so they are visible rather than missed.
- LUA-01 (hard vs soft `lib.nvim`): the README and scripts/minimal_init.lua both call lib.nvim a hard dependency, and bindings/autocmds.lua, float.lua and webpdf.lua use bare `require`. But cache.lua, persist.lua, url.lua and monitor.lua reach it through `pcall(require, ...)` with fallbacks. Each of those documents itself as tolerating an *older* lib.nvim rather than an absent one, and the fallbacks keep the same interface, so I read this as version-tolerance rather than the mixed hard/soft style LUA-01 forbids. A stricter reader could call it a finding.
- ERR-54 (`config.get()` returns `_options` by reference, config/init.lua:276): no consumer I found mutates it, `M.raw()` exists precisely as the mutation door, and `M.raw()`'s own doc states "everything that only reads should use `M.get()`". Documented, if in the neighbouring function.
- ERR-02 at preview/monitor.lua:116 (`return ok and fn() or false` calls the required module without a `type(fn) == "function"` check) and LUA-12 at float.lua:506/513/514 (`nvim_win_get_config`/`_height`/`_width` unguarded two lines after a sibling call that *is* `pcall`ed) are both real inconsistencies with negligible reachable impact; I left them out to keep the list to things that break something.
- preview/url.lua's `LI_OPEN`/`LI_CLOSE` sentinels (`"\1"`/`"\2"`) are documented as "two characters no HTML document contains", but `unescape` runs before the split and decodes `&#1;`/`&#2;` into exactly those bytes. The worst outcome is a spurious bullet on one line, so it is not worth a SEC-23 entry.
- scripts/test.sh interpolates `$1` into a `-c "lua require('plenary.busted').run(...'$target'...)"` string (SEC-35 shape), but the input is the developer's own argv to their own test runner. Noted, not reported.

Clean areas worth recording. No shell-string construction anywhere (every external process is argv through `vim.system`); no `vim.fn.glob`/`globpath`; no `__mode` weak tables; no `next(t)`-delete loops; no module-level geometry; no `executable()` probe on the startup path; no secrets, telemetry or history persistence; `vim.g` carries only booleans; `float.close` closes the window before deleting the buffer (UI-55); `preview.webpdf` has timeout, byte cap, URL-hashed cache and active deletion of incomplete downloads (SEC-21); `preview.shot` runs the browser with `--user-data-dir` and deliberately without `--no-sandbox`; `hover.scope` fails open in every branch (ERR-20/PRIN-27); the `CursorMoved` trigger is debounced through `lib.nvim.debounce` (PERF-93); and config/DEFAULTS.lua is genuinely side-effect-free data (LUA-06).

---

## markdown.nvim

**11 Befunde** (8 × high). Roh gemeldet: 11.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/markdown/commands/links.lua:65` · `collect/links_from_file` · confidence **high**

**Befund.** `local lines = vim.fn.readfile(path)` with no pcall, called once per file for every `*.md` under cwd (synchronously below CHUNK files, from a `vim.schedule(step)` chain above it, lines 91-111).

**Regelbezug.** ERR-01 makes pcall mandatory at filesystem boundaries. `vim.fn.readfile` raises on failure (verified: `pcall(vim.fn.readfile, "<missing>")` returns false, "Vim:E484: Can't open file"). The sibling scanner `core/file_refs.lua:122` wraps the identical call in `pcall(vim.fn.readfile, file)`, so this is an inconsistency inside the plugin, not a house style.

**Auswirkung.** One unreadable file under cwd (permission denied, broken symlink, a file removed between the globpath and the read) aborts `:Markdown links show cwd`. Above 20 files the throw happens inside a vim.schedule callback, so the step chain dies: on_done never fires, no picker opens, and the progress handle created at line 89 is never finished or cancelled -- lib.nvim.progress has no expiry, so the indicator stays for the rest of the session. The user gets a scheduler error with no indication of which file or how far the scan got. Below 20 files the error surfaces through the :Markdown command instead, which is noisier but not stuck.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/markdown/core/link_sanitize.lua:97` · `M.file` · confidence **high**

**Befund.** `vim.fn.readfile(path)` (line 97) and `vim.fn.writefile(new_lines, path)` (line 99) run with no pcall; the only guard is a `filereadable` check on line 96, which says nothing about writability and is a TOCTOU window for the read.

**Regelbezug.** ERR-01 requires pcall at filesystem boundaries. Both functions raise on failure (verified: writefile to an unwritable path returns false, "Vim:E482: Can't open file ... for writing"). `M.file` is reached from `M.path` → `sanitize_one` in `commands/links.lua:312-318`, which runs inside the same `vim.schedule(step)` chunk loop.

**Auswirkung.** `:Markdown links sanitize cwd` over a tree containing one read-only *.md file (or one that vanishes between globpath and the write) throws mid-run. Files already processed stay rewritten on disk, the rest are never touched, the done() summary at lines 302-310 never runs, and above 20 files the throw is inside the scheduled step so the loop dies and the progress handle is left hanging for the session. The user is left not knowing how much of the tree was modified. Note the write itself is not partial -- vim.fn.writefile either replaces the file or fails -- so no file is left half-written; the loss is knowledge of scope, not data.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/markdown/tableview/renderer.lua:835` · `M.write_back` · confidence **high**

**Befund.** In the on-disk branch of `write_back`, the read is guarded (`pcall(vim.fn.readfile, mt.source)`, line 824) but the write two lines later is not: `vim.fn.writefile(new_content, mt.source)`.

**Regelbezug.** ERR-01 requires the filesystem boundary to be pcall'd, and `vim.fn.writefile` raises on failure. The read on line 824 in the same branch is already wrapped, so the omission is asymmetric within one function.

**Auswirkung.** `:w` in a TableView opened over a %/cwd/path scope raises E482 on the first read-only or vanished file. The loop over state.tables aborts, so every remaining table is silently not written; `vim.bo[state.buf].modified = false` on line 844 never runs, so the float keeps claiming unsaved changes; and the summary notification on lines 846-858 never appears. The finding overstates one detail: the user does not see a raw stack trace -- lib.nvim's autocmd wrapper catches it and emits a single notify.error("Autocmd failed (BufWriteCmd): ..."). That outer catch does not satisfy ERR-01, because it cannot resume the loop or report how many of n files were written.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/markdown/tableview/renderer.lua:822` · `M.write_back` · confidence **high**

**Befund.** `:w` in the TableView float (BufWriteCmd, line 458) calls `M.write_back`, which replaces `mt.start_line - 1 .. mt.end_line` in `mt.bufnr` with freshly rendered lines. The only check is `api.nvim_buf_is_valid(mt.bufnr)`; the line range and the source text captured when `parser.get_tables` ran are never re-verified against the buffer's current content (no changedtick, no line comparison).

**Regelbezug.** ERR-30 requires every edit computed during a scan to be re-verified against the current text immediately before writing, and skipped when it has drifted. The float is a normal window the user can leave and return to, so an arbitrary amount of editing can happen between the parse and the `:w`. `core/link_delete.lua:209-224` does exactly this re-verification twice (before the dialog and before the delete) for the same reason, so the pattern is established in this repo.

**Auswirkung.** Leave the float, edit the source buffer above the table so it shifts, return to the float and press :w -- the stale range is overwritten blind. Whatever now occupies mt.start_line..mt.end_line is replaced by the table's rendered lines and the table's real, moved location is left untouched, producing content loss plus a duplicate, reported as the success message "TableView: wrote back to 1 buffer(s)" (line 852-857). The damage is undoable in the source buffer (it is a normal nvim_buf_set_lines edit, so `u` works), but nothing warns and nothing is skipped. The file-on-disk branch below has the same defect against mt.source.

### `LLS-31` — Ein `pcall` um einen bemängelten Aufruf ist nie kosmetisch

`lua/markdown/handler/init.lua:72` · `search_and_jump_to_fragment` · confidence **high**

**Befund.** `local fence_pattern = "^%s*([`~]{3,})%S*%s*$"` — `{3,}` is not a Lua-pattern quantifier, so this matches one backtick/tilde followed by the four literal characters `{3,}`. The `in_fence` toggle on line 77 therefore never fires.

**Regelbezug.** LLS-31 is the "fail loudly, never silently no-op" rule: a guard that cannot possibly do its work stays invisible because nothing errors. Every other fence scanner in this repo carries an explicit comment about this exact trap and spells the quantifier out — core/toc.lua:30-31, core/heading_gaps.lua:10-11, core/heading_scan.lua:14, core/headings.lua:240-241, anchor/jump.lua:80-82 (`"^%s*[`~][`~][`~]+%S*%s*$"`), and TESTS/headings_spec.lua:39-41 names it as a fixed regression. handler/init.lua is the one call site the sweep missed.

**Auswirkung.** The fence guard is dead code: search_and_jump_to_fragment scans fenced code blocks as ordinary prose. Following a `#anchor` (or a `file.md#fragment`) jumps the cursor to the first matching `## Heading`, `{#id}` or `id="..."` even when that line is only an example inside a ``` block, and reports success (returns true), so no fallback and no message. Scope is narrower than a crash: it only misfires on documents that contain a fenced block whose content mimics the anchor being followed -- common in this plugin's own docs, rare elsewhere. It is exactly the silent no-op LLS-31 names, and this is the one fence scanner in the repo that the fix sweep missed.

### `LUA-01` — Hart oder weich, aber konsistent

`lua/markdown/bindings/autocmds.lua:84` · `M.setup` · confidence **high**

**Befund.** With the default config, setup() unconditionally runs `require("markdown.hover").configure(cfg.hover)` (line 83) and `require("hover").enable()` (line 84); `markdown.hover.lib()` is a bare `require("hover")` with no pcall, and `hover` lives only in the separate hover.nvim repo (lua/hover), not in lib.nvim.

**Regelbezug.** LUA-01 requires a dependency to be consistently hard or soft, and forbids presenting a hard dependency as optional in the docs. docs/installation.md lists hover.nvim under "every one of them is optional" and its Requirements table names only Neovim, lib.nvim and rg; README.md says "All of the above are soft: without them everything else works unchanged. lib.nvim is the one real dependency". TESTS/run.lua:65-70 and .github/workflows/ci.yml treat hover.nvim as fatal-required, exactly like lib.nvim — the code and the tests agree it is hard, only the docs say soft. The documented vim-plug spec (docs/installation.md:66-68) does not install hover.nvim at all.

**Auswirkung.** Confirmed by running it. With lib.nvim present and hover.nvim absent, require("markdown").setup() raises "module 'hover' not found" at markdown/hover/init.lua:140. The throw is on line 83 (configure -> lib().setup), one line before the line 84 the finding anchors, so line 84 is never even reached. Measured after the failure: exists(":Markdown") = 0, exists(":TableView") = 0, augroups MarkdownNvimKeymaps, MarkdownNvimUserCommands and MarkdownNvimLinksSanitize do not exist; only MarkdownNvimTableView survives (4 autocmds), because it is created above the throw. So the plugin is not merely missing its hover float -- no keymaps, no user commands, no fold options, no link sanitize-on-save. :checkhealth markdown does not mention hover.nvim, so nothing tells the user why. A user who follows README.md or the vim-plug section of docs/installation.md gets exactly this.

### `PERF-62` — Timer sauber stoppen

`lua/markdown/bindings/autocmds.lua:159` · `M.setup (table-wrap resize hook)` · confidence **high**

**Befund.** The `VimResized`/`WinResized` debounce does `if timer then pcall(function() timer:stop() end) end` and then overwrites `timer` with a new `vim.defer_fn(...)` handle. `timer:close()` is never called.

**Regelbezug.** PERF-62 requires `timer:stop()` **and** `pcall(timer.close)` before starting a new debounce timer, never just dropping the handle. `vim.defer_fn`'s timer closes itself only from inside its own callback, so a timer that is stopped before it fires is never closed. `core/refs.lua:271-275, 289-292, 311-315` gets this right (stop + `pcall(close)` on all three paths), so the correct shape is already in the repo.

**Auswirkung.** With table.wrap.auto_resize = true, every resize event that arrives while a debounce is already pending stops the pending libuv timer and drops the handle without closing it; the handle stays open for the rest of the session. Confirmed at runtime that a stopped vim.defer_fn timer is never closed. The finding's "hundreds of never-closed uv handles per resize gesture" is overstated -- the leak is one handle per resize event that lands inside the 300 ms window, so a drag of a split leaks on the order of tens, not hundreds, and each handle is small. It is a genuine unbounded-growth leak over a long session with frequent resizing, not something that breaks a feature.

### `SEC-34` — `vim.fn.expand()` nie auf Buffer-/Nutzertext

`lua/markdown/commands/create.lua:16` · `resolve` · confidence **high**

**Befund.** `:Markdown create fs` scans the buffer with `link_scan.from_line` (line 68), and passes each raw markdown link target into `resolve()`, whose first statement is `target = vim.fn.expand(target)`.

**Regelbezug.** SEC-34 forbids `vim.fn.expand()` on buffer/user text: a backtick span in the argument is a command substitution through `&shell`, and `%`/`#`/`<cfile>` are Vim specials. This is the exact call site class that `lua/markdown/util/path.lua:38-62` was rewritten for — its docstring documents the same attack against link targets ("![x](`mkdir /tmp/pwned; echo a.png#`) was arbitrary command execution ... confirmed, the directory appeared") and provides `expand_path`/`M.resolve` as the safe replacement. create.lua reimplements path resolution instead of calling it, so the fix never reached it.

**Auswirkung.** Opening an untrusted .md file and running `:Markdown create fs` executes the shell on every backtick span inside a markdown link target. Confirmed by side effect on this machine: vim.fn.expand with a backtick argument created a directory via cmd.exe. Severity is bounded by the fact that :Markdown create fs is an explicit, deliberate command over the buffer (or a visual range), not something an autocmd or hover triggers -- this is not a drive-by from merely opening a file. Second, smaller defect confirmed: when the shell invocation fails, expand raises E282 and that error propagates out of do_fs with no pcall, so a single backtick anywhere in any link target aborts the whole command. The plugin already has the fix in-tree (util/path.lua expand_path / M.resolve); create.lua reimplements resolution and misses it.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/markdown/core/link_sanitize.lua:96` · `M.file` · confidence **medium**

**Befund.** `if vim.fn.filereadable(path) ~= 1 then return 0 end` — the "could not read this file" outcome returns the same `0` the success path returns when a readable file simply had no link target worth normalizing.

**Regelbezug.** ERR-11 requires "empty but fine" and "empty because broken" to be distinguishable in the return. Here the single integer return collapses both, and the caller has no second channel to consult.

**Auswirkung.** Confirmed but narrower than stated. In the single-file path the caller first does uv.fs_stat (commands/links.lua:352-355), so a *missing* file is caught there with "scope not found". The collapse bites for a file that exists but is not readable (permissions) or for a directory passed as the scope: both pass fs_stat, fail filereadable, and are reported as "links sanitize: nothing to normalize" -- the user is told the file was clean when it was never opened. Over cwd the case is broader: unreadable files are silently excluded from both counters, so "normalized N link target(s) across M file(s)" understates the scope with nothing saying files were skipped. No data is lost; the defect is a false clean bill of health.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/markdown/config/init.lua:117` · `M.setup` · confidence **medium**

**Befund.** `M.setup` is `_cfg = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), opts or {})` followed by `resolve_features(_cfg)`. There is no known-keys table and no unknown-key check anywhere — `resolve_features` only validates the *values* inside `features.disable`/`enable`/`just_enable`, and it runs after the merge.

**Regelbezug.** ERR-50 requires config validation (unknown keys, "did you mean …") to run before the merge, precisely so a typo in a nested option cannot vanish into the defaults unnoticed. `config/DEFAULTS.lua` is 393 lines with roughly 25 nested option tables (`hover.url`, `hover.office`, `table.wrap`, `toc`, `refs`, `links.diagnostics`, `fenced_scope.operations`, …), and `vim.tbl_deep_extend("force", …)` happily accepts any key at any depth.

**Auswirkung.** A typo in any option key other than a features.* name is accepted in total silence: the bogus key is merged into the resolved config and the intended option keeps its default. Concrete cases against the real defaults: setup({ table = { wrap = { maximum = 40 } } }) leaves the actual key `max` (DEFAULTS.lua:122) at nil, so wrapping stays unlimited; setup({ tabel = {...} }) drops the whole block. :checkhealth markdown reports nothing, because it only validates links.picker. The user's only symptom is an option that appears to do nothing. The finding's own hover.enable/enabled example is weak -- hover.enabled already defaults to true, so that particular typo is invisible for a different reason -- but the underlying gap is real.

### `XP-05` — Ein fehlschlagendes `executable()`/`exepath()` ist unter Windows teuer und ungecacht

`lua/markdown/core/file_refs.lua:161` · `M.find_references / M.find_references_async` · confidence **low**

**Befund.** `vim.fn.executable("rg")` is called afresh on every reference search — line 161 in the sync path and line 193 in the async one. The result is never cached.

**Regelbezug.** XP-05 states that a *failing* `vim.fn.executable()` walks every PATH entry against every PATHEXT extension (~44 ms measured on Windows) and that `vim.fn` does not cache the result, so the fix is to cache it or defer it. Nothing here memoizes; the same negative probe is paid on every call.

**Auswirkung.** Confirmed, and stronger than the finding claims -- the auditor's own "low" confidence was unwarranted. Measured here: 64 ms per call with rg absent, and 18 ms per call even with rg installed, both uncached and both paid on every DD keypress on a link line and on every call to the public M.find_references / M.find_references_async. The finding is right that this is not a startup cost (markdown.nvim is FileType-lazy and neither function runs at setup), so it does not slow Neovim's start; it is per-operation latency on an interactive keypress, and on a rename/delete flow that calls the public API once per file it multiplies linearly. A module-level memo (with an explicit invalidation story, since caching a negative means a mid-session rg install goes unnoticed) removes it.

> **Abdeckung dieses Laufs.** Scope: read `lua/` (15079 LOC) — roughly 9500 lines line-by-line (config, bindings, handler, core/link_*, core/refs, core/file_refs, core/table_fmt, scope, hover, tableview/renderer + views, util/*, health, commands/*), the rest (core/toc, core/wrap*, core/table_wrap, core/table_mode, core/heading_*, core/html_links, anchor/*, hl_options, fenced_fix, tableview/parser, bindings/keymaps+actions) covered by targeted greps for each rule's concrete pattern plus reading every hit's surroundings. TESTS/ (6203 LOC) was read only where it evidenced a rule (run.lua's dependency bootstrap, headings_spec's fence regression note) — no findings there; the four unguarded `vim.fn.expand`/`vim.cmd` uses inside specs are test fixtures on paths the spec itself created.

Verified at runtime rather than by reading: the hover.nvim crash (headless `setup()` with lib.nvim but no hover.nvim → `SETUPOK=false`, `:Markdown` not registered), the dead fence pattern (`(\"```lua\"):match(\"^%s*([`~]{3,})%S*%s*$\")` → nil), and that `vim.fn.readfile`/`vim.fn.writefile` raise rather than return a code (E484/E482), which is what makes the three ERR-01 findings aborts rather than silent miscounts.

Could not confirm / deliberately not reported:
- ERR-54: `config.get()` (config/init.lua:122) hands out the live `_cfg` by reference with no \"live reference, do not mutate\" note, and `core/table_fmt.lua:46` passes the live `table.col_overrides` sub-table straight into `lib.nvim.markdown.table`. I read `lib.nvim`'s `resolve_overrides` (lua/lib/nvim/markdown/table/init.lua:254-284) and it does not mutate its argument, and I found no mutator inside markdown.nvim either, so there is no demonstrable bug today — only a missing guard rail.
- ERR-31: `commands/create.lua:28-45` is a literal check-then-create (`uv.fs_stat` then `io.open(path, \"a\")`). It is not `O_CREAT|O_EXCL`, but `\"a\"` does not truncate, so a file appearing in the race window is not clobbered — only mis-reported as \"created\". Not worth a finding.
- ERR-22: several config values are never validated or degraded (`table.header_align`/`entry_align`, `toc.min_level`/`max_level`, `toc.anchor_separator`, `progress_style`, `heading_format.capitalize`); `:checkhealth markdown` validates only `links.picker`. This is diffuse rather than one place, and it overlaps ERR-50 above, so I folded it into that finding instead of listing each key. Note `core/slug.lua:35` uses `anchor_separator` as a gsub *replacement* string, so a `%` in it would raise — contrived enough that I left it out.
- UI-01: `:Markdown links sanitize cwd` and `:Markdown table format scope=cwd` rewrite every `*.md` file under the cwd with no confirmation at all. UI-01 as written targets per-item confirmation (\"once, not once per item\"), and the user names the scope explicitly, so I did not file it — but a one-off \"rewrite N files?\" prompt is the obvious gap.
- PERF (not in the 76): `core/file_refs.lua:44` rebuilds the whole ignore set (including a `pcall(require, …)`) once per scanned file inside `is_ignored`; `hover/section.lua:40-45` reads an entire linked file into memory with no line or byte cap before taking the first 20 lines.
- Not a listed rule, but almost certainly a live bug: `core/headings.lua:303` is `vim.cmd(\"normal! \\\\<Esc>\")`, i.e. a literal backslash-`<Esc>` typed as normal-mode input rather than an escape — `vim.cmd(\"normal! \" .. vim.api.nvim_replace_termcodes(...))` or `<Esc>` via `nvim_feedkeys` is what was meant.

---

## recommender.nvim

**10 Befunde** (5 × high). Roh gemeldet: 11.

### `ERR-10` — „Kein Argument" ≠ „ungültiges Argument"

`lua/recommender/bindings/usrcmds.lua:140` · `classify_pos_args` · confidence **high**

**Befund.** The classification chain ends in `elseif not threshold then threshold = tonumber(tok) end`, so a token that is neither a scope name nor an analyzer name nor a number is assigned `nil` and dropped without a trace; the caller (line 196-200) then cannot tell 'no analyzer given' from 'an analyzer was given and it was garbage'.

**Regelbezug.** ERR-10 is exactly this: a typo in an argument must not behave like 'no argument'. The composer route declares `type = "STRING", values = COMPLETION_VALUES` (lines 461-463), and in lib.nvim `values` is completion-only -- `composer/argtypes.lua:96-104` registers STRING's `validate` as `return true, raw` and uses `spec.values` only in `complete`. Only `spec.enum` validates (`argtypes.lua:59-68`), and this route does not use it, so the typo reaches `classify_pos_args` unchallenged.

**Auswirkung.** `:Recommender javascrpt`, `:Recommender treesiter` or `:Recommender cdw` run as a bare `:Recommender` — the configured default analyzer over the current buffer — with no message at all. The user sees a plausible result list for the wrong analyzer, or a one-buffer scan where they asked for the whole project, and nothing points at the typo. One correction to the auditor's wording: the bad token is not consumed (`not threshold` stays true), so a real number later on the same line is still picked up; the defect is purely the missing 'unknown argument' report. Declaring `enum = COMPLETION_VALUES` on the three slots would close it at the composer layer.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/recommender/bindings/usrcmds.lua:240` · `execute / state.refresh / get_analyzer` · confidence **high**

**Befund.** `analyzer_name` falls back to `cfg.analyzer` unvalidated, and `get_analyzer()` raises `error(...)` (line 117) for a name it cannot `require`. The call sits at the top of `state.refresh`, *before* the local `guarded()` pcall wrapper defined at line 282 and used from line 290 on.

**Regelbezug.** ERR-22 requires an invalid single config value to degrade to its default and be surfaced via `:checkhealth`, not to break the plugin. Nothing validates `cfg.analyzer`: `config/init.lua:18` only deep-merges, and `health.lua` reports `float_layout`, `progress_style`, `cwd_max_files` and `cwd_ignore` but never reads `cfg.analyzer`. Positional analyzer tokens are checked against `ANALYZER_NAMES`; the config value is not.

**Auswirkung.** Correcting the auditor's framing: setup() does not abort — it returns green, and so does :checkhealth recommender. The bad value is deferred to command time, where every :Recommender run and every in-float <BS>/U refresh raises an unhandled 'Error executing vim.schedule lua callback: [recommender] Unknown analyzer "treesiter"' and shows no float. That is the worse failure mode for diagnosis: two surfaces the user would check both say OK while the command is dead. statusline.lua:61-64 degrades correctly on the same typo, which is the shape ERR-22 asks for; usrcmds does not.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/recommender/float/keymaps.lua:109` · `M.make_on_select` · confidence **high**

**Befund.** `register_replace_finish(target_win, snapshot, item.alias)` arms a one-shot WinClosed insert *before* the code decides whether `:Replace` will actually run (lines 111-118). On the else-branch the alias is inserted immediately via `nvim_put`, but the armed autocmd is never disarmed -- `float/autocmds.lua:38` only deletes the augroup from inside the handler, which requires a TelescopePrompt window to close.

**Regelbezug.** ERR-30 requires an edit computed earlier to be re-verified against the current text immediately before writing, and to be dropped when it no longer matches. Here the staleness test is inverted: `float/autocmds.lua:50-64` inserts the alias precisely *because* the buffer now differs from the stale snapshot -- which it always does, since the alias was already inserted on the fallback path.

**Auswirkung.** Narrower than stated but real: on the fallback path the alias is inserted once and a one-shot WinClosed autocmd stays armed against a snapshot that can no longer match. It is inert until a TelescopePrompt window closes, so the practical case is a user who has replacer.nvim (hence telescope) installed and hits the `var_name = nil` branch — perf analyzer in replace mode: the next unrelated Telescope picker close re-inserts that alias line into target_win at whatever cursor position it then has. With no telescope in the session the augroup just lingers with no effect, and a later replace-mode selection clears it via `autocmd.group(..., true)`. Fix: arm it only on the branch that actually dispatches :Replace.

### `LUA-01` — Hart oder weich, aber konsistent

`README.md:46` · `README "Around it" section` · confidence **high**

**Befund.** README lists ui.nvim in the 'Around it' section and then states 'All of the above are soft: without them everything else works unchanged. lib.nvim is the one real dependency', while `ui.kit` is a hard, fallback-free dependency: `float/rendering.lua:9` and `float/keymaps.lua:19` `require("ui.kit")` at module level, and `bindings/usrcmds.lua:28-29` requires both at module level, which `bindings/init.lua:15` pulls in from `setup()`.

**Regelbezug.** LUA-01 says a hard dependency must never be presented as optional in the documentation. The plugin's own `docs/installation.md:9` marks ui.nvim '**required** ... `require("recommender").setup()` fails without it, no fallback', and `health.lua:30-37` emits `vim.health.error` for a missing ui.kit -- so the README contradicts both the code and the rest of the docs.

**Auswirkung.** Documentation-only defect, but it breaks installs. A reader who takes the README's summary line at its word and installs only lib.nvim gets an uncaught `module 'ui.kit' not found` out of `require("recommender").setup()`: :Recommender is never registered and anything after that call in the same config block does not run. Secondary inaccuracy worth fixing in the same pass: the ui.nvim bullet describes it as only the statusline badge, when ui.kit is the suggestion picker itself.

### `SEC-35` — Nutzereingabe nie in einen `-c`-/`:execute`-String

`lua/recommender/float/keymaps.lua:114` · `M.make_on_select` · confidence **high**

**Befund.** Builds an Ex command line by string-formatting `item.chain` -- text taken verbatim from the user's buffer -- into `vim.cmd(("Replace %s %s %%"):format(item.chain, var_name))` instead of passing it as an argument.

**Regelbezug.** SEC-35 forbids putting user-controlled text into a `vim.cmd(...)`/`-c` string; a chain is not a sanitized token. The treesitter analyzer returns the raw source text of a `dot_index_expression` node, which I confirmed can contain arbitrary characters and newlines: running `collect_chains` over a buffer yields chains like `vim.fn.expand("| echo pwned").field` and `"vim.tbl_map(function(v)\n  return v\nend, t).foo"`. Neither the regex-family analyzers' character class nor the blacklist constrains the treesitter path.

**Auswirkung.** In replace mode (`-r`) with replacer.nvim's `:Replace` present, <CR> on a suggestion whose chain spans lines runs every line after the first as its own Ex command in the user's session. Ordinary multi-line Lua (a `vim.tbl_map(function() ... end, t).foo`) only yields a truncated `:Replace` plus E492 noise; a crafted or pasted file executes attacker-chosen Ex commands — verified live, a register was written. Preconditions: analyzer = treesitter, replace mode, replacer.nvim installed, and the multi-line chain meeting the threshold (`:Recommender -r treesitter 1`). Fix is the list form / passing the chain as an argument rather than formatting it into the command string.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/recommender/project.lua:278` · `M.read_lines / M.read_lines_async` · confidence **medium**

**Befund.** Both readers do `local ok, file_lines = pcall(vim.fn.readfile, p)` and simply skip the file when `ok` is false (lines 278-284 and 329-335), returning only a flat `lines` array with no count of failures and no error channel; `on_done(lines)` carries the same shape whether zero or all files failed.

**Regelbezug.** ERR-11 requires 'empty but fine' to be distinguishable from 'empty because something broke'. The module header even states the skip as the intended behaviour, but intent does not replace the signal: `usrcmds.lua:255-258` turns an empty result into `notify.info("No suggestions (threshold: %d)")`, identical to a clean scan, and the progress handle's closing text at line 386 reports `("scanned %d files"):format(#paths)` -- the number of files *found*, not the number actually read.

**Auswirkung.** A cwd/path scan over a tree the user cannot read (permission-restricted checkout, files deleted mid-scan, a dropped network share) finishes with 'scanned 412 files' and 'No suggestions (threshold: 3)' — byte-identical to a clean scan of a project with genuinely no repeated chains, so the user concludes the code is clean when nothing was read. Returning a skipped-file count alongside `lines` and folding it into the finish text (and into the empty-result notify) is the missing piece; the per-file skip itself should stay.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/recommender/health.lua:57` · `M.check` · confidence **medium**

**Befund.** The health check branches on `if vim.g.loaded_recommender then ok("plugin loaded") else info("plugin guard not set (call require('recommender').setup())") end`, but `plugin/recommender.lua:6` sets `vim.g.loaded_recommender = true` when Neovim sources the plugin directory, long before and independently of `setup()` (which sets it again, to `1`, at `init.lua:26`).

**Regelbezug.** The check collapses two different states -- 'the plugin file was sourced' and 'setup() actually ran' -- onto one signal, so the only diagnostic that could report the second one can never fire. ERR-11's shape: the negative branch is unreachable, and the green result is reported for a condition it does not actually observe.

**Auswirkung.** An installed-but-never-setup() plugin yields a fully green :checkhealth recommender, including an affirmative claim that the <leader>lr keymaps are bound when none are — so the page troubleshooting points at first actively steers away from the real cause. The fix is one line: test something setup() actually does (`vim.g.loaded_recommender == 1`, or `vim.fn.exists(':Recommender') == 2`) instead of the plugin-load guard. Caveat on classification: ERR-11 is written about a function's empty return, so the rule fit is by analogy — but the defect (two states collapsed onto one signal, negative branch unreachable, green reported for a condition never observed) is real and sits on a diagnostic surface.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/recommender/config/init.lua:18` · `M.setup` · confidence **medium**

**Befund.** `M.setup` is a bare `vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), opts or {})` -- there is no known-key check, no 'did you mean' and no type check, neither before nor after the merge, and no other module validates the merged table either.

**Regelbezug.** ERR-50 requires config validation (unknown keys, near-misses) to run before the merge, precisely so a typo in an option name cannot vanish into the merged table. `force` merges an unknown key straight in, and since nothing ever reads it, the mistake is unobservable.

**Auswirkung.** `setup({ threshhold = 5 })`, `setup({ blacklists = {…} })` or `setup({ float_keymap = false })` is accepted in complete silence: the orphan key lands in the merged table, nothing ever reads it, and every default stays in force. :checkhealth prints the still-default values without flagging the stray key, so the option reads as applied. Worth noting the merge is otherwise clean — it deepcopies DEFAULTS rather than mutating them (ERR-51 satisfied); the single gap is the missing pre-merge known-key/near-miss check.

### `ERR-53` — In-place-Mutation statt Tabellen-Ersatz bei geteilten Referenzen

`lua/recommender/config/init.lua:18` · `M.setup` · confidence **medium**

**Befund.** `M.setup` replaces `_active` with a brand-new table, while `bindings/init.lua:15` hands the *old* table to `bindings/usrcmds.lua`'s `M.setup(cfg)`, which captures it in the command's `run` closure (line 471) for the rest of the session.

**Regelbezug.** ERR-53 requires an in-place deep mutation rather than a table swap exactly when submodules hold a direct reference to the config table -- otherwise those references decouple silently from the new values. The reference is held here, and the swap does decouple it.

**Auswirkung.** Structurally real, but reachable today only by calling `require("recommender.config").setup({…})` directly — a path the docs never suggest, and one that init.lua's `_setup_done` guard blocks for the documented `require("recommender").setup()` entry point; TESTS/config_spec.lua is the only current caller. When it is reached, :Recommender keeps running on the pre-swap analyzer/threshold/blacklist/cwd_max_files while :checkhealth and the statusline component report the new values, with nothing indicating which is in force. Correct classification is a latent structural violation to fix together with the LUA-87 finding (fixing that one is what would make this reachable), not a bug users hit now.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/recommender/init.lua:16` · `M.setup` · confidence **medium**

**Befund.** `if _setup_done then return end` makes every `setup()` after the first a complete no-op: the new `opts` are never merged, `config.setup()` is never reached, and nothing is returned or notified to say so.

**Regelbezug.** LUA-87's belege class is 'setup() silently discarded every option' -- the ordering rule exists so that explicit `setup()` arguments always win over whatever was already in place. Here the earlier state wins over the explicit call, and silently. PRIN-20 ('keine stillen Fehler') points the same way: a call that does nothing must say so.

**Auswirkung.** `:lua require("recommender").setup({ threshold = 5, analyzer = "python" })` in a live session does nothing and says nothing: the previous config keeps running, so the option reads as broken rather than ignored. Same outcome when a config that calls setup() is re-sourced without restarting Neovim, since package.loaded keeps `_setup_done` true. A normal single-spec plugin-manager install calls setup() exactly once, so a fresh start is unaffected — the cost falls on the tune-and-reload loop. Either notify on the repeat call, or keep the registration one-shot while still re-merging the new opts into config.

> **Abdeckung dieses Laufs.** Coverage: I read all 24 files under lua/ (2633 LOC), both files in plugin/ (29 LOC), README.md, docs/installation.md and the generated-doc headers, plus TESTS/run.lua, harness.lua, config_spec.lua, float_autocmds_spec.lua and usrcmds_spec.lua in full (~460 of the 1733 TESTS LOC); the remaining analyzer/rendering specs I only skimmed via grep for stubbing patterns, so test-code findings are under-covered -- I report none, which reflects effort as much as cleanliness. Two findings were verified empirically against nvim 0.12.2 rather than by reading alone: (a) `vim.cmd` splits an embedded newline into separate Ex commands and a chain carrying one really does execute the second line (SEC-35), and the treesitter analyzer really does emit node text containing newlines and `|`; (b) `vim.fn.expand("<cfile>")` at usrcmds.lua:235 does NOT throw E348 on an empty/whitespace line and does not further expand env vars, so I dropped the SEC-34 lead I was chasing -- the argument there is the literal special, not buffer text, and the result is only ever fed to filereadable/fnamemodify/findfile. I also checked lib.nvim's composer to confirm that `values` is completion-only and `enum` is the validating facility, which is what makes the ERR-10 finding real rather than theoretical.

Not covered and why: CMT-16 -- docs/map/ is generated and now gitignored (52390bc 'stop committing the generated module map'), and docs/BINDINGS.md / doc/recommender.txt carry no generator banner, so I could not tell a hand-edit from a regeneration without running the generators, which this report-only task excludes. LLS-31 -- needs a LuaLS run over the tree; I did not run one, and I did not run TESTS/run.lua either. ERR-51/ERR-54 -- checked and found clean: DEFAULTS is deep-copied before every merge and no consumer mutates what `config.get()` hands back, so I report neither. XP-01 -- `find_files` correctly routes through `lib.nvim.fs.globbable` (project.lua:98), matching the existing Belege entry for this plugin; `find_files_async` uses `fs_scandir` where the pitfall does not apply. LUA-06 -- DEFAULTS.lua's two module-level requires are static data tables, matching the existing Belege note that clears recommender for this rule. I did not audit lib.nvim's or ui.nvim's internals, and I did not confirm whether replacer.nvim defines `:Replace` with `-bar`, which is why the SEC-35 finding rests on the newline carrier (confirmed) rather than the `|` one (not confirmed; it did not fire against a non-`-bar` command).

I considered and deliberately dropped three weaker leads to keep the list honest: the `A` (insert-all) key writing N alias lines without a confirmation (UI-01 -- it is a single undo block and the key's whole documented purpose); the module-level `ignore_by_buf` table in usrcmds.lua:183 growing per buffer with no BufDelete cleanup (a few strings per buffer, no correctness effect since Neovim does not reuse buffer handles in a session, and no weak-table claim is made, so LUA-48 does not really bite); and the statusline cache key omitting analyzer/threshold (PERF-46 -- unreachable in practice because the config is effectively frozen after the one-shot setup).

---

## rules.nvim

**10 Befunde** (7 × high). Roh gemeldet: 13.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/rules/engine/checks/init.lua:38` · `M.run` · confidence **high**

**Befund.** `M.run` calls `impl.run(check, root, ctx)` with no error isolation, even though its own contract already declares an `"error"` status and uses it for an unknown `check.type` two lines above.

**Regelbezug.** ERR-01 requires a pcall at the system boundary, and this is the boundary where a user-authored ruleset's data (an arbitrary Lua pattern, an arbitrary `spec` shape) first drives plugin code. It is not a hotpath — it runs once per rule.

**Auswirkung.** A ruleset-authored Lua pattern with an unescaped `(`/`[`/trailing `%` aborts the whole `:Rules check --family=X` run with a raw internal error naming checks/grep.lua, not the offending rule id or ruleset file. Because the two return values (`status`, `findings`) never come back, no report buffer opens and the quickfix list is left untouched — every other rule in the family goes unreported. The unescaped-`(` case is the nastiest: the family passes cleanly on a repo with no violation and throws only on the repo that has one.

### `ERR-02` — Type Guards & Literal Checks

`lua/rules/engine/checks/lua_predicate.lua:35` · `M.run` · confidence **high**

**Befund.** `if type(findings_or_msg) == "table" then return "fail", findings_or_msg end` passes a user predicate's return value through as the findings list after checking only that it is a table — never that its entries have the `{file, line, text}` shape the `Rules.Finding` class declares.

**Regelbezug.** ERR-02 requires `type(...)`/nil checks before API access. The consumer `report/buffer.lua:41` formats `f.line` with `%d`, which is a hard type requirement, and this is the only place a findings table enters the system without being constructed by the plugin itself.

**Auswirkung.** A `lua_predicate` — the documented free-form escape hatch — that returns findings without a `line` field produces a half-completed run: the findings reach the quickfix list, then the report buffer throws at render with an error naming report/buffer.lua. Nothing points back at the predicate that produced the malformed entry, and this is the only place a findings table enters the system without being built by the plugin itself.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/rules/engine/loader.lua:35` · `md_files_under` · confidence **high**

**Befund.** A ruleset path that is neither an existing directory nor a readable `.md` file returns `{}`, and `M.load` appends nothing to its `errors` channel — so "this directory has no rules" and "this path does not resolve at all" are the same answer.

**Regelbezug.** ERR-11: a function whose result may legitimately be empty must make "empty but ok" distinguishable from "empty because broken". `M.load` already has an `errors` return value for exactly this and does not use it here. `TESTS/loader_spec.lua:64` locks the behaviour in (`assert.are.equal(0, #errors)` for `/definitely/does/not/exist`).

**Auswirkung.** A ruleset path that does not resolve (a `~`-prefixed one, as the plugin's own quickstart shows in three places, or a typo) is indistinguishable from an empty ruleset directory: `loader.load` returns `{}, {}`, so `M.load_rules` notifies nothing and every `:Rules check`/`:Rules gate`/`:Rules stats` runs against zero rules and reports a clean, empty result. The user has no signal anywhere that the path was never read.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/rules/init.lua:98` · `M.check_family` · confidence **high**

**Befund.** A `--family=<PREFIX>` that matches zero loaded rules produces an empty result list, an empty quickfix list and a report buffer containing only `"rules.nvim report"` plus a blank line — with no warning. The gate path does the opposite: `run_gate_results` (init.lua:72-80) explicitly warns via `gate.unknown_families`.

**Regelbezug.** ERR-11: a typo'd or not-yet-loaded family is "empty because broken" and is rendered identically to "empty, nothing to report". A family prefix is derived from loaded rule ids, so a prefix matching zero rules is ALWAYS an error, never a legitimate empty result.

**Auswirkung.** A transposed `--family=SCE` opens a report tab containing only the title line and a blank line, and replaces the quickfix list with an empty one — visually identical to a clean run. Nothing distinguishes it from a family that genuinely has no rules, and the stale comment in usrcmds.lua tells the next maintainer this case is already handled.

### `PRIN-25` — Eingaben validieren

`lua/rules/engine/checks/file_exists.lua:16` · `M.run` · confidence **high**

**Befund.** `local full = root .. "/" .. spec.path` concatenates `spec.path` with no `type(spec.path) == "string"` guard, unlike the sibling `lua_predicate.lua:23`, which does guard its input and returns the `"error"` status.

**Regelbezug.** PRIN-25 requires arguments to be checked before being worked with, especially before a foreign API call. `spec` is a raw table from a user-authored Markdown file — the most untrusted-shaped input the plugin has.

**Auswirkung.** A misspelled or missing `path` key in a `file_exists`/`file_absent` rule throws out of the entire family run (nothing catches it between here and `:Rules check`), so no report opens and every other rule in the family is silently skipped. The error text names plugin internals only — neither the rule id nor the ruleset file — so the user cannot tell which of their rules is malformed.

### `PRIN-25` — Eingaben validieren

`lua/rules/engine/checks/json_key.lua:19` · `M.run` · confidence **high**

**Befund.** `root .. "/" .. spec.path` (line 19) and `spec.key:gmatch("[^.]+")` (line 32) both use unvalidated ruleset-supplied fields.

**Regelbezug.** Same as file_exists: PRIN-25 requires validating these before use, and the module's declared return type includes no path for a malformed spec.

**Auswirkung.** Same blast radius as the file_exists case: a `json_key_absent` rule missing either field aborts the whole `:Rules check --family=<X>` run before any report or quickfix output, with an error pointing at checks/json_key.lua instead of at the rule that is broken.

### `SEC-33` — Persistierte Snapshots sind untrusted

`lua/rules/engine/waivers.lua:44` · `M.load` · confidence **high**

**Befund.** `.rules-waivers.json` entries are validated for type only (`type(id) ~= "string" or type(reason) ~= "string"`) — no length cap, no count cap, and no check on the reason's content.

**Regelbezug.** SEC-33 requires every field of a persisted snapshot to be re-validated on load for type, length AND count cap. The reason string flows straight into `report/buffer.lua:30` and from there into `nvim_buf_set_lines`, which rejects strings containing newlines.

**Auswirkung.** A multi-line reason string (legal JSON, natural for a justification with a ticket reference) makes every `:Rules check`/`:Rules gate` run in that repo throw at report rendering with an error naming report/window.lua, not the waivers file — the user has to find the newline by hand. Separately, because the waivers file is read from the audited root and `json.exit_code` never counts `waived`, an audited third-party repo can suppress its own critical findings and flip a CI exit code from 1 to 0.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/rules/engine/parser.lua:47` · `M.extract_rules` · confidence **medium**

**Befund.** `local lines = vim.fn.readfile(file_path)` is called unguarded, after a `filereadable` pre-check. The same call is wrapped in `safe_error.safe_call` in `checks/grep.lua:81` with a comment explaining why — so the guarded form is the module author's own established pattern, just not applied here. Two more unguarded instances: `engine/waivers.lua:30` and `engine/checks/json_key.lua:25`.

**Regelbezug.** ERR-01 makes pcall mandatory at filesystem boundaries and this is not a hotpath (once per ruleset file). The check-then-read shape is a TOCTOU: `filereadable` reports openability at time T, `readfile` opens at T+1. Confirmed that `vim.fn.readfile` raises (`Vim:E484: Can't open file`) rather than returning an error value.

**Auswirkung.** Narrow trigger (the file must be removed, renamed or exclusively locked between `filereadable` and `readfile` — the realistic case is a Windows lock or a ruleset checked out/updated mid-run), but when it fires the throw bypasses the function's `(rules, errors)` contract entirely and propagates through `loader.load` → `M.load_rules` into every `:Rules` subcommand and the `RULES_FAMILY`/`RULES_ID` completion handlers (usrcmds.lua:24, :50), so even pressing <Tab> errors. waivers.lua:30 has the same shape and breaks the `(waivers, error)` contract that exists precisely to separate "no file" from "bad file".

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/rules/bindings/usrcmds.lua:127` · `M.setup` · confidence **medium**

**Befund.** `:Rules show` runs `vim.cmd.edit(vim.fn.fnameescape(rule.source_file))` followed immediately by `vim.api.nvim_win_set_cursor(0, { rule.source_line, 0 })`, neither guarded.

**Regelbezug.** ERR-01: `:edit` is a filesystem boundary that genuinely fails in ordinary situations. `nvim_win_set_cursor` then runs unconditionally on whatever buffer the window actually holds.

**Auswirkung.** `:Rules show <id>` on a rule whose source file cannot be opened (modified current buffer under `'nohidden'`, a swapfile, a file deleted or moved since the ruleset was loaded, an autocmd vetoing the edit) surfaces a raw Vim error (e.g. E37) instead of this file's own `[rules.nvim] ...` notify style, with no indication which rule or ruleset file was involved. The subsequent cursor jump simply never happens — there is no second error.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/rules/config/init.lua:31` · `validate` · confidence **medium**

**Befund.** `validate()` runs before the merge (correct ordering) but only ever inspects the two known keys `rulesets` and `gates` and returns `out` containing only those; any other key in `opts` is dropped without a notification and without a "did you mean" hint.

**Regelbezug.** ERR-50's stated purpose is that a typo'd option must not vanish silently into the default. Correct ordering alone does not achieve that here, because there is no unknown-key detection at all — the typo is discarded by the same mechanism that discards nothing.

**Auswirkung.** A typo'd top-level option (`ruleset` for `rulesets`, `gate` for `gates`) is discarded by `setup()` with no notification at all, and `config.get().rulesets` stays `{}`. The only downstream signal is `:checkhealth rules` printing `info("no rulesets configured -- setup({ rulesets = {...} }) to point at your own rules")` (health.lua:60) — which does flag that nothing is configured but gives no hint that a key was misspelled. Note the auditor's chained claim of a green `0 rule(s) loaded from 1 ruleset path(s)` health line is wrong for this case: with the typo, zero paths are configured, so health takes the `info` branch, not the `ok` branch.

> **Abdeckung dieses Laufs.** COVERAGE. I read all 21 files under lua/ (1612 LOC) line by line, plus scripts/minimal_init.lua and scripts/test.sh in full, README.md, docs/RULESET-FORMAT.md, docs/BINDINGS.md and the head of doc/rules.txt. TESTS/ (1204 LOC across 11 specs) was surveyed via a full describe/it inventory plus targeted excerpts (checks_spec 1-30/70-162, loader_spec 1-20/60-90) rather than read line by line, so the two test-code findings are almost certainly not exhaustive. Ignored per instructions: .git/, doc/tags, .deps/ (none present); .claude/ does not exist in this checkout.

VERIFICATION METHOD. Every "high" finding was reproduced live, not inferred: headless Neovim 0.12.2 with lua/ and a real lib.nvim checkout (E:/repos/lib.nvim) on the runtimepath, driving loader.load / runner.check_family / report.buffer.open directly. The malformed-pattern, missing-spec.path, newline-waiver, tilde-path, typo-family, lua_predicate-findings and typo-config-key cases all produced the exact failures quoted in their impact fields. I did not run the project's own suite (scripts/test.sh needs a plenary checkout I did not locate), so I cannot report on current suite health.

WHAT I COULD NOT COVER.
- lib.nvim's own modules (fs.collect_recursive, lib.lua.error, bindings.usercmd.composer) are out of scope. LUA-02 is satisfied by rules.nvim delegating the filesystem walk upward rather than keeping a private copy (fswalk.lua:16); whether those upstream modules obey the catalog is a separate audit.
- CMT-16 could not yield a finding: the only generated artifact is docs/map/, which .gitignore excludes and git does not track, and this repo has no CI gate that could go red on drift. docs/BINDINGS.md and doc/rules.txt are hand-written.
- XP-05 was not measured empirically; it needs no measurement here, as the plugin makes no vim.fn.executable()/exepath() calls at all (verified by grep).
- XP-02: the diff-scoping path (gate.lua:84 vs :103) derives both sides of its path key from the same `root`, so the 8.3/long-name split cannot open between them. I could not construct a case where the two normalizations disagree, so no finding - but I did not test it against a real Windows short-path repo.

OBSERVATIONS DELIBERATELY NOT FILED AS FINDINGS (no rule in the 76 covers them).
1. Arbitrary code execution by design: parser.lua:63 evaluates `load("return {" .. body .. "}")` for every fenced rule block in every .md file found RECURSIVELY under a configured rulesets directory. This is documented as an intentional trust decision ("same trust level as any require() of a local file"), and I accept that framing for a hand-curated checklist directory. It is worth the author knowing the blast radius anyway: the recursion means any .md file that lands in that tree - a cloned repo's docs, a shared or downloaded checklist - executes on every :Rules invocation and on every Tab completion, not just on an explicit check.
2. Cache scoped too narrowly: runner.lua:42 creates the shared `ctx` inside check_family, so gate.lua:28 gives each family in a gate its own. An N-family gate walks the tree and re-reads every matching file N times, defeating the cache that runner.lua:40-42 exists for. Pure efficiency, no rule violated.
3. config/init.lua:71 replaces the `state` table on setup() while M.get() (documented at :74-78) hands out a live reference. No current consumer caches that reference across a second setup(), so ERR-53's precondition is unmet and I did not file it - but the two contracts do contradict each other and would bite a future consumer that caches.

WHAT IS GENUINELY WELL DONE (so the report is not read as uniformly negative). ERR-54 is handled correctly and explicitly documented at config/init.lua:74-78. ERR-51 (deepcopy of DEFAULTS before merge), LUA-06 (DEFAULTS.lua is pure data), LUA-01 (lib.nvim is uniformly a hard dependency in code and in the README), LUA-17 (vim.w carries only a boolean, the serializable case), SEC-03 (gate.lua:67,74 use argv-list `vim.fn.system`, never a shell string), XP-01 (loader.lua:17-24 deliberately avoids globpath with a correct explanation, and TESTS/loader_spec.lua:71 covers it), and ERR-60 (grep.lua:74-87 rejects the `and/or` ternary for a nil-able value, with a regression test) are all met, several with the reasoning recorded in-code. The three remaining `a and b or c` sites (grep.lua:139, init.lua:66, buffer.lua:36) were each checked: none has a falsy middle operand that changes the outcome.

---

## spotlight.nvim

**9 Befunde** (3 × high). Roh gemeldet: 9.

### `ERR-22` — Ungültiger Config-Wert degradiert auf Default

`lua/spotlight/config/init.lua:203` · `M.setup` · confidence **high**

**Befund.** `lib_config.deep_merge` replaces a nested user table wholesale whenever `tables.is_array(v)` is true, and `is_array({})` returns true for an empty table — so any empty nested section in `setup()` discards every default in that section. The `normalize_*` pass afterwards only restores the numeric keys; booleans and strings stay nil and no issue is recorded.

**Regelbezug.** ERR-22 requires an unusable config value to degrade to its default and for the degradation to be visible through `:checkhealth`. Here a whole section's booleans silently degrade to nil (not to their defaults), and `M.issues` — the only thing `health.lua:106-112` reports — never mentions them.

**Auswirkung.** Any empty nested section passed to `setup()` (plausible via a lazy.nvim `opts = { keymaps = {} }` or a scaffolded config) discards every default in that section. Confirmed consequences: word-bounded matching silently off (`pattern.build` omits `\<`/`\>`, so `error` lights up inside `errors`), persistence entirely off (autocmds.lua:120 registers neither the VimEnter load nor the VimLeavePre flush), no preset keys bound, no `<cword>` fallback in the cursor resolver. Two corrections to the auditor: `config.issues` held 6 entries, not 5, and `cursor.patterns` IS restored to the defaults with an issue recorded (normalize_cursor_patterns' `type(list) ~= "table"` branch at init.lua:84-88 catches it). The booleans and strings remain nil with nothing in `config.issues`, so `:checkhealth` reports only the numeric knobs and says nothing about them.

### `LUA-01` — Hart oder weich, aber konsistent

`docs/installation.md:44` · `lazy.nvim spec` · confidence **high**

**Befund.** docs/installation.md:5-14 declares ui.nvim a **required** dependency "with no fallback", and the code backs that up (`integrations/menu.lua:20` bare-requires `ui.contextmenu` at module load). But all six install specs on that same page — lazy.nvim ×2 (l.44, l.56), packer (l.70), mini.deps (l.81), vim-plug (l.88), Lazy-alt (l.99), vim.pack (l.109) — list only `StefanBartl/lib.nvim`.

**Regelbezug.** LUA-01: a hard dependency must never be presented as optional in the documentation. README.md:52 goes further and states outright that "lib.nvim is the one real dependency", directly contradicting installation.md's "Both are **required** dependencies" three clicks away.

**Auswirkung.** A user copying any of the six specs installs spotlight without ui.nvim. `:Spotlight list` / `<leader>sL` then hits ui/list.lua:180-184 and refuses with "ui.kit.select unavailable — cannot open the list" — the plugin's single most-used surface, dead. A user following the documented menu recipe (menu.lua:9) with `require("spotlight.integrations.menu").items()` gets a hard throw at menu.lua:20. `:checkhealth` names it (health.lua:31-33) but only after the fact. Two corrections to the auditor: `ui.kit.select` is NOT bare-required — ui/list.lua:181 goes through `lib.try_require` and degrades with a notify, so installation.md:11's "with no fallback" overstates the code; and nothing in-tree requires `spotlight.integrations.menu`, so `setup()` itself never throws — only the user's own dispatcher does.

### `PRIN-20` — Keine stillen Fehler

`lua/spotlight/yank.lua:39` · `M.yank` · confidence **high**

**Befund.** `M.yank` flattens `registry.all()` into a bare pattern list and calls `count.matching_lines`, the one pattern-only scanner — while `qf.fill` uses `count.matching_lines_for` and `map.show` uses `count.matching_lines_by_item`, both of which special-case buffer-scoped items.

**Regelbezug.** A `scope == "buffer"` spotlight's pattern carries `\%l\%c` position atoms, which `vim.regex:match_str` does not evaluate (documented in `core/count.lua:19-40`, and I verified it: the pattern compiles and then returns nil on every line). So the pinned item is invisible to this scan, and the function reports `0, "no matching lines in this buffer"` — a wrong reason for a failure that is not a lack of matches. That is a silent error dressed as a legitimate empty result.

**Auswirkung.** With only "this occurrence only" spotlights active (`<leader>sk`, DEFAULTS.keymaps.toggle_here), `:Spotlight yank` returns 0 and reports "no matching lines in this buffer" while `:Spotlight qf` finds the line and the sign map places a mark — a wrong reason reported for a failure that is not a lack of matches. With a mix of global and pinned spotlights, the pinned ones are silently dropped from the yanked text with no truncation flag. One correction to the auditor: the unnamed register is not emptied, it is left untouched (verified: a sentinel written beforehand survives), because the `#entries == 0` early return at yank.lua:41-43 runs before `setreg`.

### `ERR-02` — Type Guards & Literal Checks

`lua/spotlight/init.lua:73` · `M.toggle_selection / M.toggle_here_selection` · confidence **medium**

**Befund.** Both visual-mode entry points call `vim.keycode("<Esc>")` (init.lua:73 and init.lua:113) with no existence check, while README.md:18, docs/installation.md:5 and health.lua:47-51 all declare Neovim 0.9+ as supported.

**Regelbezug.** `vim.keycode()` is a 0.10 addition — confirmed in the shipped `runtime/doc/news-0.10.txt:276` ("vim.keycode() translates keycodes in a string"). On 0.9 the field is nil, so the call raises before `nvim_feedkeys` is even reached. ERR-02 asks for a type/nil check before an API access; a version-gated API used under a lower declared floor is exactly that gap. (Note: the rule fit is by analogy — none of the 76 covers "API newer than the declared minimum" head-on.)

**Auswirkung.** On Neovim 0.9 — which `:checkhealth spotlight` reports as `ok` — `<leader>sk` and `<leader>sK` in visual mode (`M.toggle_here_selection`, `M.toggle_selection`) throw "attempt to call a nil value (field 'keycode')" at init.lua:73/113, after the selection has already been resolved and before it is used, so the work is discarded. These are the only two 0.10-only API uses in spotlight's own Lua, so the rest of the plugin keeps working and the failure reads as a Neovim bug rather than an unsupported version. Two caveats the auditor did not state: I verified the 0.10 introduction from the runtime docs but did not run an actual 0.9 build, and lib.nvim — a hard dependency — may carry its own 0.10 requirements that would make the 0.9 floor moot anyway. The cheapest honest fix is either a nil-guarded fallback to `nvim_replace_termcodes` or raising the declared floor to 0.10 in README.md:18, installation.md:5 and health.lua:47.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/spotlight/core/count.lua:97` · `M.count` · confidence **medium**

**Befund.** When `pattern.compile(item.pattern)` returns nil — its documented signal for "Vim rejected this pattern" — `M.count` returns `0, 0`, the same shape as a successful scan that found nothing.

**Regelbezug.** ERR-11: "empty but fine" and "empty because something broke" must be distinguishable. This function already has the right channel for it — its own doc comment (l.76-79) says nil means "we did not look" and that callers must render that as "not counted" rather than zero. A rejected regex is exactly "we did not look", yet it takes the zero path.

**Auswirkung.** Downgrade the auditor's impact substantially: I could find no reachable input, and I tried. `core.pattern` builds every pattern as `\C`/`\c` + `\V` + a backslash-escaped body, and I compiled six adversarial bodies in headless nvim — embedded newline (word and literal kinds), carriage return, NUL byte, trailing backslash, 256 consecutive backslashes — and all six compiled. `registry.restore` (registry.lua:426) rebuilds the regex from `text` rather than trusting the snapshot, so even a hand-edited JSON cannot inject an uncompilable pattern; it can only supply text, and text cannot produce one. So nothing currently breaks: this is a contract gap, not an observable bug. It still matters as a latent one — the day `core.pattern` gains a non-literal mode or a user-supplied regex path, the list will report `0` ("this token appears nowhere") for a spotlight Vim refused to compile instead of the `?` it shows for every other unscanned case. The same silent drop exists in `matching_lines` (count.lua:161-166), which skips uncompilable patterns without telling the caller.

### `ERR-51` — Merges kopieren Defaults tief

`lua/spotlight/config/init.lua:97` · `normalize_cursor_patterns / normalize_palette` · confidence **medium**

**Befund.** `lib_config.deep_merge` only shallow-copies the top level: a section the user did not override stays the *same table object* as `DEFAULTS`'s. `normalize_cursor_patterns` (l.97) and `normalize_palette` (l.52, l.63, l.73) then assign unconditionally into that section, writing through into `config/DEFAULTS.lua`, whose own header says "Never mutate it at runtime."

**Regelbezug.** ERR-51: a merge must deep-copy the defaults rather than mutate the shared defaults table. Verified in headless nvim — after a plain `config.setup()`, `rawequal(config.options.cursor, DEFAULTS.cursor)` is true, and both `DEFAULTS.cursor.patterns` and `DEFAULTS.palette.colors` are no longer the table objects the module returned at load.

**Auswirkung.** Latent, and the auditor is right to say so: every write-back is content-identical (the `kept` tables rebuild the same valid entries), so nothing observable breaks today. The concrete violation is that DEFAULTS' own "never mutate" contract is broken on every `setup()` call. It becomes a real bug the moment a normalizer writes a *changed* value into a section the user did not override, because the fallback branches (`o.palette[key] = DEFAULTS.palette[key]` at :52/:63, `o.match.max = DEFAULTS.match.max` at :106) then read the corrupted copy and a later corrected `setup()` cannot recover the real default. Two consequences the auditor did not name, both worth fixing in the same pass: config/init.lua:23 sets `M.options = DEFAULTS` outright, so before `setup()` the live options table IS the defaults table; and for an empty-table override (`setup({ match = {} })`, see the ERR-22 finding) the merge hands back the *user's own* table by reference and the normalizers write into that instead. Note the mutation only reaches DEFAULTS for sections the user did not override — an overridden section gets a fresh table from the recursive merge — which is precisely why it has stayed invisible.

### `ERR-54` — Getter auf geteiltem Zustand: Kopie oder dokumentierte Live-Referenz

`lua/spotlight/init.lua:608` · `M.spotlights` · confidence **medium**

**Befund.** The public facade hands `registry.all()` — the live `items` array the whole plugin mutates through — straight out to user code. Its docstring says "Live access to the registry, for users scripting against the plugin"; docs/api.md:99 says "The live registry — for a status line or a scripted check". Neither says do not mutate it.

**Regelbezug.** ERR-54 allows a live reference only if the getter documents "live reference, do not mutate" and every consumer honours it. `core/registry.lua:53-55` does carry that contract ("read-only by contract; mutate it only through this module") — but that is an internal note, and the consumer on the far side of `M.spotlights()` is the user, who cannot be held to it. Every in-tree consumer behaves (ui/list.lua:129 rebuilds via `M.filter` rather than sorting in place); the exported one is the unguarded edge.

**Auswirkung.** A statusline doing `table.sort(require("spotlight").spotlights(), by_slot)` permanently reorders the live registry for the session, changing list order, `registry.snapshot()`'s write order (and therefore what gets persisted) and `nav`'s alternation order. A `table.remove` on it is worse: `registry.remove(id)` looks the item up by iterating `items` (registry.lua:69-76), so it returns nil without ever calling `match.remove(id)`, leaving core/match's ledger holding live `matchadd()` ids for an item no longer in the registry — a highlight lit with nothing able to clear it. Correction to the auditor's severity: this is recoverable, not permanent — `registry.clear()` calls `match.clear()` (core/match.lua:218), so `:Spotlight clear` or `spotlight.refresh()` does clean up the orphaned matches. The minimal fix is either returning a shallow copy or adding "live reference — do not mutate" to init.lua:606 and docs/api.md:99.

### `LUA-87` — Eine selbstgeschriebene Config-Datei darf `setup()` nicht still überstimmen

`lua/spotlight/hover.lua:44` · `MAX_LINES` · confidence **medium**

**Befund.** `local MAX_LINES = 20000` is a module-level constant handed to `core.count.count` at hover.lua:136, never read from the config. Its own doc comment two lines up claims it "Matches the ceiling the spotlight list uses, so the two never disagree about whether a buffer was scanned."

**Regelbezug.** LUA-87's merge section requires config values to be read through `config.options.X`, never duplicated as a direct field on the module. `list.count_max_lines` defaults to 200000 (config/DEFAULTS.lua), ten times this constant, and a user raising or lowering it has no effect here at all. The doc comment asserts the opposite of what the code does. (The file carries a `CDX:` marker at line 41 saying the same; I confirmed both numbers independently rather than taking that comment's word for it.)

**Auswirkung.** On any buffer between 20,001 and 200,000 lines under default config, `:Spotlight list` prints a real occurrence count while hover.nvim's float over the same token says "too many lines to count here" (hover.lua:146) — two spotlight surfaces disagreeing about whether the buffer was scanned, which is exactly the nil-vs-0 distinction core/count.lua:76-79 exists to keep honest. Raising or lowering `list.count_max_lines` has no effect on the float. Nothing crashes and no wrong number is shown; the cost is the inconsistency plus a doc comment that states the opposite of what the code does. Note the repo already carries a `CDX:` marker on the constant (hover.lua:41-43) flagging this same gap, so this is a known open item rather than a discovery — but the constant and the comment are still both live in the tree. A tighter hover-specific ceiling may be defensible design (the float fires on CursorHold, the list on an explicit action); if so it belongs in DEFAULTS as its own key, with hover.lua:38-40 corrected.

### `PERF-42` — Invalidierbar

`lua/spotlight/sets.lua:51` · `loaded / save_cache` · confidence **medium**

**Befund.** `loaded()` reads `spotlight/sets` from the project store exactly once per session and caches it in the file-local `cache`; nothing ever invalidates or re-reads it. `save_cache` (l.79) then writes `{ version, sets = loaded() }` — the whole table — on every `sets save` / `sets delete`.

**Regelbezug.** PERF-42 requires a defined point at which a cache entry becomes invalid. This one has none: not a TTL, not an mtime check, not a re-read before write. Combined with a whole-file write, the stale cache becomes the authoritative content of the file.

**Auswirkung.** Cross-instance lost update on `:Spotlight sets`, the feature explicitly sold as a saved workspace that survives sessions. Instance A saves set "incident-4711"; instance B then saves "incident-4712" and writes its own cache as the whole file, and A's set is gone with no error on either side. `M.delete` has the same shape. One precondition the auditor stated but is worth pinning down, because it is what makes this a real-world bug rather than a certainty: B's cache must already have been populated before A's write — by any earlier `M.names()`/`M.count()`/`M.save`/`M.switch`/`M.delete`, which includes tab-completing a set name or running `:Spotlight sets list`. A B that has never touched sets reads fresh from disk on its first save and does not clobber. The same missing invalidation also means an external edit of the JSON, or a `store.project.clear`, is never picked up for the rest of the session.

> **Abdeckung dieses Laufs.** Coverage: I read every file under lua/ (27 modules, 5 475 lines) and plugin/ (8 lines) in full, plus README.md, docs/installation.md, docs/api.md, the generated docs/map/module_map.json, TESTS/run.lua and the relevant parts of TESTS/yank_spec.lua and TESTS/menu_spec.lua. Three findings were verified by running the real modules in headless nvim 0.12 rather than by reading alone (the yank/qf/map divergence on a pinned spotlight, the empty-nested-table config collapse, and the DEFAULTS mutation).

What I could not cover:
- TESTS/ was not audited line by line (29 spec files, ~4 000 lines). I only went in to check whether the yank gap and the ui.nvim hard require were covered by a spec. No is_test_code findings are reported, and that is a coverage gap, not a clean bill.
- Neovim 0.9 behaviour could not be exercised — only 0.12 is installed here. The `vim.keycode` finding rests on the shipped runtime/doc/news-0.10.txt listing it as a 0.10 addition, not on a 0.9 run.
- CMT-16 has no surface here: docs/map/ is generated and current (23 file + 3 module nodes against 27 lua files, 1 correctly marked outside), and docs/BINDINGS.md declares itself hand-maintained in this repo rather than renderer-produced.

Already-handled Belege, re-checked and deliberately not re-reported: ERR-11's load-modify-save collapse on the project store (root-fixed in lib.nvim cache/disk.lua's read_entry, which I confirmed still backs up to `.corrupt`); SEC-30 (core/pattern.lua's `\V` escape), SEC-31/32 (match.max_text_len, cursor.max_line_len, quickfix.max_entries all present and enforced), SEC-33 (registry.restore re-validates every field and rebuilds the regex from `text`), SEC-34's E348 side (both `expand("<cword>")` sites at cursor.lua:142/173 are pcall-guarded), ERR-22's original finding.

Two things I looked at hard and chose not to file:
- hover.lua:106 does `pcall(require, \"hover.registry\")` inside setup(), which under lazy.nvim is a load trigger and would pull hover.nvim into every startup — the shape LUA-92 warns about. Eight sibling repos (documentation, insights, language, markdown, reposcope, sandbox, …) register identically, so this is a fleet-level decision about hover.nvim's registry contract, not a spotlight defect. Worth raising once, at the fleet level, not here.
- health.lua:236 bare-requires `lib.nvim.bindings.usercmd.composer` as its last statement, after line 67 already pcall-probed the same module. If lib.nvim is absent, `:checkhealth spotlight` aborts on that line — but only after the whole report has been emitted, and a bare require is the correct shape for a declared hard dependency (LUA-01), so it is consistent rather than wrong.
- persist.lua shares sets.lua's read-once/write-whole-file shape, but follows the fleet's project-store semantics rather than keeping its own uninvalidated cache, so only the sets.lua case is filed.

Verified clean, with no findings: ERR-60 (checked every `a and b or c` in the tree — all middles are non-falsy; `""`, `0` and `1` are truthy in Lua), ERR-62 (no `pcall(f(args))` anywhere), LUA-17 (only booleans cross `vim.w`), SEC-03/SEC-35 (zero shell-string or `:execute`-string construction — no io.popen, os.execute, vim.fn.system, vim.system or jobstart in the plugin), XP-01 (no glob/globpath), XP-06 (TESTS/run.lua sets package.path from its own directory, so no case-sensitive require path), PERF-80 (util/lib.lua's timer fallback schedules before touching vim.api), PERF-93 (no CursorMoved/TextChanged/WinScrolled handler exists at all, by design).

---

## my.nvim

**7 Befunde** (4 × high). Roh gemeldet: 10.

### `ERR-11` — „Nichts zu melden" ≠ „Fehler beim Ermitteln"

`lua/my/bindings/usrcmds/init.lua:34` · `keys_of` · confidence **high**

**Befund.** `local ok, keys = pcall(C.keys, ns); return (ok and type(keys) == "table") and keys or {}` — a thrown error inside `C.keys` and a genuinely empty namespace both return the same `{}`, with nothing recorded and nothing notified. The identical shape is at lines 204-206 in `status_report`: `local ok, modified = pcall(C.modified, ns); local n = (ok and type(modified) == "table") and #modified or 0`.

**Regelbezug.** ERR-11 requires a function whose result *can* legitimately be empty to make "empty, but ok" distinguishable from "empty, because broken". Both return sites collapse the two onto one value, and every consumer (`starting_with` for `<Tab>` completion, `do_list`, `status_report`) treats the result as authoritative.

**Auswirkung.** Smaller reach than claimed. The `<Tab>` path does go quiet, but it blocks nothing: the registered arg type's `validate` returns `true, raw, nil` unconditionally (lines 74-76, with the comment at 63-65 explaining that rejection is left to `C.set`), so `:My hl set <key> <value>` still routes through and `C.set` reports an unknown key by name. `do_show` (line 120) and `M.setup` (line 224) call `C.modified`/`C.keys` WITHOUT pcall, so a genuinely broken config still throws loudly on those routes -- the plugin is not uniformly silent about it. The one diagnostic that is actually indistinguishable is `:My status`'s `N keys, N changed from shipped` line, which reports a healthy-looking `0`/`0` when `C.modified` or `C.keys` threw.

### `PERF-42` — Invalidierbar

`lua/my/italic_keywords/init.lua:23` · `M.setup` · confidence **high**

**Befund.** A `FileType` autocmd (registered per language, lines 20-26, with no `group`) calls `vim.fn.matchadd("ItalicKeywords_" .. lang, pattern)`. The returned match id is discarded, no previous match is ever deleted, and there is no autocmd or code path anywhere in the plugin that calls `matchdelete` for these.

**Regelbezug.** PERF-42 requires that it be defined when an entry becomes invalid. `matchadd` entries are window-local and permanent; here nothing defines their end of life. There is no dedupe either, so the same pattern is re-added on every FileType event for that language in that window.

**Auswirkung.** Accumulation is real -- N Lua files opened in one window leave N duplicate `ItalicKeywords_lua` matches, doubled again per extra `setup()` -- but the per-match redraw cost is small, so growth is the lesser half. The user-visible defect is placement, and it is worse than the finding says: `matchadd()` targets the CURRENT window at the moment FileType fires, so (a) a buffer loaded into a background window or by a plugin puts the italics in whatever window happened to be current, (b) `:split` on a Lua file gets no italics at all until its filetype is re-set, and (c) because matches are window-local, not buffer-local, switching that window to Markdown or text keeps italicising `return`/`if`/`for` there. Cosmetic in every case -- no crash, no wrong data.

### `PERF-46` — Cache-Key vollständig

`lua/my/hl_config/utils/separator.lua:35` · `nerd_or_fallback` · confidence **high**

**Befund.** `nerd_or_fallback = memo.fn(function(hex) ... end, { size = 16 })` is memoized on `hex` alone, but its body also reads `vim.o.columns` (line 37, `wide = columns >= 100`) and `vim.g.have_nerd_font` (line 40). I confirmed in lib.nvim (`lua/lib/lua/memo/memo.lua:41-51,73-86` via `memo/init.lua:32-56`) that `memo.fn` builds the LRU key purely from the argument tuple.

**Regelbezug.** PERF-46 requires the cache key to contain every parameter that influences the result, or the cache silently returns the wrong answer for a different configuration of the same input. Two such parameters are read from global state and never enter the key, and the LRU entry is never invalidated (no `VimResized` hook either — the PERF-92 failure mode one level down).

**Auswirkung.** Narrower and purely cosmetic, not the session-wide freeze the finding implies. It only bites when `vim.g.have_nerd_font` is not exactly `true` -- then the fallback arrow is chosen from the terminal width at the first breadcrumb render and frozen: start in an 80-column window and maximise it, and the winbar keeps the narrow `" › "` for the rest of the session, with no VimResized handler and no TTL to recompute it. Setting `vim.g.have_nerd_font = true` after the first render never produces the glyph. `:My hl set breadcrumbs_*` re-renders (init.lua:143) but hits the same cache entry, so there is no in-session escape short of changing the hex itself. No crash, no data loss -- a wrong-width separator glyph.

### `PERF-93` — Heißes Event: billiger Guard **oder** Throttle, nie ungeschützt

`lua/my/hl_config/cword_occurrences/init.lua:375` · `M.enable` · confidence **high**

**Befund.** `WinScrolled` (together with BufEnter/BufWinEnter) is wired straight to the undebounced `update_now`, while every other trigger in the same `enable()` — CursorMoved (367), CursorMovedI (371), TextChanged/TextChangedI (379) — goes through `update_debounced` and the 40 ms `Debounce.new` handle created on line 363.

**Regelbezug.** PERF-93 names `WinScrolled` as a hot event and requires either a throttle or a guard that leaves the frequent case cheaply. `update_now` does neither: in the common case (normal buffer, feature enabled, cword >= 2 chars) it runs the entire repaint — `nvim_buf_clear_namespace`, `std_skip`, an uncached `uv.fs_stat` in `is_large_file_guard` (lines 58-73, which does not use the TTL-cached `utils/large_file.lua` next door), `vim.fn.expand("<cword>")`, then a `vim.fn.matchstrpos` loop over every viewport line placing an extmark per hit.

**Auswirkung.** Every WinScrolled -- one per step of held <C-d>/<C-u> or wheel scroll, and also on window resize -- runs the whole repaint with no coalescing: one uncached fs_stat syscall, a full namespace clear, and a viewport-wide matchstrpos scan re-placing every extmark. It is the exact work the author deliberately debounced at 40ms for cursor movement and edits, on the one event that fires fastest. BufEnter/BufWinEnter on the same registration are one-shot and harmless; WinScrolled is the whole defect. No correctness impact -- highlights stay right -- so it shows up only as scroll latency in a large viewport, which is why it would never be reported as a regression.

### `ERR-02` — Type Guards & Literal Checks

`lua/my/health.lua:350` · `check_diagnostics_owner` · confidence **medium**

**Befund.** `local ok_lsp, lsp_diag = pcall(require, "lsp.core.diagnostics")` followed by `if ok_lsp and type(lsp_diag.applied) == "function" then` — `lsp_diag` is indexed after only the pcall's success flag is checked, with no `type(lsp_diag) == "table"` guard.

**Regelbezug.** ERR-02 requires a `type(...)` check before an API access. The plugin's own `util/soft_require.lua:31` (`if ok and type(mod) == "table"`) and `breadcrumbs/ctx/base.lua:29` both do exactly that check for the same `pcall(require, ...)` shape — this site is the one that skips it. A Lua module with no `return` statement makes `require` yield `true`, and `true.applied` throws.

**Auswirkung.** Correcting the blast radius: `M.check()` (lines 460-476) runs its sections sequentially with no pcall between them, so the throw does abort the rest -- but only TWO sections follow, `check_winbar_owner` and `check_breadcrumb_lsp_provider`, not six, and the `effective: signs=...` line at 362-369 is inside the aborted section itself, not a separate trailing line. Neovim's own health runner pcalls the plugin's `check()`, so the report does not crash -- it ends with a `Failed to run healthcheck for "my" plugin. Exception: attempt to index a boolean value` block where the remaining sections should be. Reachability is narrow: it needs `mode == "contributed"` (lsp.nvim present) AND `lsp.core.diagnostics` resolving to a non-table, i.e. a module mid-refactor with no return statement. Low probability, one-line fix, and it turns the diagnostic tool itself into the thing being debugged.

### `ERR-50` — Config-Validierung vor dem Merge

`lua/my/init.lua:38` · `M.setup` · confidence **medium**

**Befund.** `M.setup(opts)` reads the ten `My.EnableArgs` fields one by one (`on(key)` at 47-49, plus `opts.diff_profile`, `opts.line_numbers`, `opts.persist_overrides`, `opts.diagnostics`, `opts.indent_per_ft`, `opts.keymaps`) and never compares the keys the caller actually passed against the known set. I grepped for `KNOWN_OPTS`/`validate`/"did you mean" across `lua/`: nothing validates the setup table, and `health.lua` has no section that would surface an unrecognised key either.

**Regelbezug.** ERR-50's stated failure mode is precisely this: a typo in an option disappears silently into the default and is never detected. The plugin has the material to check against (`@types/init.lua:33-45` enumerates every field), and `config/core/setter.lua` already rejects an unknown key on the `:My hl set` route — the setup entry point is the one surface with no such gate.

**Auswirkung.** Every typo in the setup table degrades silently to the shipped default with no notification, no health warning, and no log line -- the plugin behaves as if the option were never passed. The nested case is the worst: a mistyped inner key discards a whole override table while the outer key still counts as "configured", so the subsystem reports as on and running with defaults. The only way to discover any of it is to read the source or notice the missing behaviour later, which for `persist_overrides` means noticing after a restart that the overrides are gone. The material for a gate already exists (the @types field list) and the sibling `:My hl set` route already does it -- setup() is the one entry point with no check.

### `PERF-93` — Heißes Event: billiger Guard **oder** Throttle, nie ungeschützt

`lua/my/hl_config/init.lua:212` · `ensure_window_autocmds` · confidence **medium**

**Befund.** `Autocmd.create({ "BufReadPost", "TextChanged", "TextChangedI" }, function() if vim.wo.cursorline then activate_window() end end, ...)` — the only guard on the keystroke-rate event is `vim.wo.cursorline`, which is `true` in the shipped configuration (`data/highlight.lua:5` `enable_line = true`, applied by `features/cursorline.lua:50` and `options_config/init.lua:28`).

**Regelbezug.** PERF-93's test is not "is there a timer" but "does the handler leave the frequent case cheaply". Here the frequent case is the guard being true, so every keystroke in insert mode runs `activate_window()` → `is_ui(0)` (two `nvim_get_option_value` calls plus `nvim_buf_get_name` and the name-pattern loop in `utils/skip.lua`), `should_enable_column` → `LargeFile.exceeds` → `nvim_buf_get_name` + cache lookup, three `vim.wo[win]` option writes, and `Winhl.update`.

**Auswirkung.** The auditor understated the cost. `std_skip` runs three times per keystroke, not once: `activate_window` (init.lua:59-66) calls `is_ui(0)`, then `CursorLine.activate` calls `is_ui(0)` again at cursorline.lua:43, and `should_enable_column` calls it a third time at line 21. Each pass is `classify` in utils/skip.lua:77-125 -- two `nvim_get_option_value` plus `nvim_buf_get_name` plus the name-pattern loop -- so six option reads and three buffer-name reads, plus `LargeFile.exceeds` (buf-valid check, name, os.time cache lookup), plus three `vim.wo[win]` writes at cursorline.lua:50-52 (each an `nvim_set_option_value`, which fires OptionSet), a table build, and `Winhl.update`. Roughly fifteen API calls per text-changing keystroke in insert mode, for a re-check whose answer provably cannot change at the events it is bound to. No behavioural bug -- purely wasted work, and the handler's documented intent is unreachable.

> **Abdeckung dieses Laufs.** Coverage: I read every non-@types Lua file under lua/ in full except lua/my/config/data/highlight.lua lines 90-269 (a colour table, scanned by grep for any computed value — none), the two ~290-line lang modules (ctx/lang/lua.lua, ctx/lang/javascript.lua, scanned by grep for vim.fn / pcall / memo / error — pure TSNode walking, nothing matched), and guicursor_profile/profiles.lua (a string table). That is ~8,100 of the 8,467 non-@types Lua LOC. The @types/*.lua files (~930 LOC of ---@meta annotations) were read only where a rule needed them (@types/init.lua for ERR-50). Of TESTS/ (2,213 LOC) I read persist_spec.lua's setup/teardown and grepped the whole tree for destructive operations, stdpath writes and XP-06-style require paths; I did not read the specs line by line, so any test-code finding below the grep threshold is uncovered — I have no test-code findings to report.

Rules I could not evaluate against real behaviour, only against the code: PERF-93's two findings and XP-05 are cost claims I did not measure on this machine; I reasoned from the call chains and from the measurements the plugin's own comments already record. SEC-34's E348 behaviour I took from the rule text and its Beleg rather than reproducing it.

Checked and clean, worth recording so the next sweep does not redo it: LUA-06 (config/data/*.lua and config/DEFAULTS.lua hold no env or filesystem lookup at module level — the only module-level work is the documented `vim.deepcopy` snapshot); LUA-48 (zero `__mode` in the repo, and both bufnr-keyed caches — ui/line_numbers/init.lua:118 and ctx/providers/lsp_symbols.lua:517 — clean up through an active BufDelete autocmd, which is the rule's prescribed path); ERR-60 (I read all 40 `a and b or c` sites; in every one the middle operand is a non-empty string, a table literal or a number that cannot be 0-and-meaningful — no fall-through); ERR-62 (the two `pcall(require(...).fn, arg)` sites at bindings/usrcmds/init.lua:354,369 pass the function by reference, they do not call it first); ERR-51/53 (indent_per_ft deepcopies DEFAULTS before `tbl_extend`; my.config mutates the live tables in place against a separately frozen deepcopy, which is the in-place form ERR-53 asks for); XP-01 (no glob/globpath anywhere); XP-07 (declarative/clipboard.lua's scrub_utf8 is an exemplary implementation of this rule); SEC-03/30/35 (every shell-out is argv — vim.system, systemlist with a list, fn.system with a list; the one `vim.cmd` string at options_config/init.lua:62 is the constant `\"set guicursor&\"`; cword patterns go through `\\V` plus `vim.fn.escape`); SEC-33 (persist.load pushes every file value through C.set, which type-checks it against the shipped default, so a hand-edited overrides.json cannot inject a wrong-typed value); CMT-16 (the only generated tree, docs/map/, is gitignored and nothing hand-edits it; docs/BINDINGS.md is hand-maintained by design per its own header); XP-06 (no `require(\"tests...\")` — plenary loads the specs by path).

Two things I judged real but below the bar for a finding, since neither maps cleanly onto one of the 76 and both are currently harmless: (1) ctx/providers/lsp_symbols.lua:314 guards its autocmd registration on `rawget(M, \"__au_lsp_breadcrumbs\")` while line 331 writes `M.__au_registered` — I grepped both names, each appears exactly once, so the guard can never be true; it costs nothing today because the module chunk runs once and `Autocmd.group(..., true)` clears anyway. (2) The same module registers six autocmds (BufEnter/CursorHold/CursorHoldI/InsertLeave/TextChanged/LspAttach) at require time in its own augroup, and `Breadcrumbs.enable(cfg)` only clears the \"Breadcrumbs\" augroup — so `:My hl set enable_breadcrumbs false` leaves those six warming an LSP documentSymbol cache nobody reads for the rest of the session.

One LUA-16 lead I could not confirm either way: ctx/providers/lsp_symbols.lua:156 does `if sym.detail and #sym.detail > 0`, and line 173 does `name:find(\"%)$\")`. If a server sent `\"detail\": null` and that reached Lua as `vim.NIL`, both would throw (vim.NIL is truthy userdata). I believe Neovim's LSP rpc decodes with `luanil = { object = true }`, which turns object nulls into Lua nil and makes the point moot, but I did not verify that against the installed Neovim, so I left it out rather than report it on an assumption.

Also noted, not reported: config/data/highlight.lua writes `breadcrumbs_separator = nil` (line 51) and `cword_occurrences.large_file_kb = nil` (line 40). A nil value is an absent key, so neither is enumerated by `M.keys`, neither has a `M.default`, and `:My hl set` answers \"Unknown key\" for both — two documented knobs that are unreachable through the plugin's own config system. Nothing in the 76 covers it (the closest, LUA-86, appears only inside LUA-87's Belege footnote and has no rule entry of its own).

---

## data.nvim

**5 Befunde** (2 × high). Roh gemeldet: 6.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/data/scope/resolve.lua:55` · `fenced_block_scope` · confidence **high**

**Befund.** `cma.fences.block_at(bufnr, row0, { lang = langs })` calls straight into color_my_ascii.nvim's API without a pcall; the guard above it only checks `type(cma.fences) ~= "table"` (line 51), never that `block_at` is a function.

**Regelbezug.** ERR-01 makes pcall mandatory for calls that touch plugin APIs, and this is not a hotpath. Every other third-party call in the plugin is wrapped -- `pcall(require, "pickers.refine")` and `pcall(refine.new, ...)`/`pcall(h.prompt, ...)` in filter/init.lua, `pcall(diff.run, ...)` in preview.lua, `pcall(window.open_scratch_split, ...)` in scope/sink.lua -- each with a comment saying why. color_my_ascii's own health.lua checks `type(fences.block_at) == 'function'`, showing the member check is the expected consumer-side idiom.

**Auswirkung.** The auditor overstated the surfacing. data.nvim registers its verbs through `lib.nvim.bindings.usercmd.composer`, whose `register` hands the handler to `usercmd.create` (composer/init.lua:214), and that wrapper pcalls every handler and reports `UserCommand 'JSON' failed: <lua error>` (lib.nvim usercmd/init.lua:72-80). So this is not a raw error escaping the usercmd handler -- it is a notification carrying a Lua internal message. There are no keymaps in this plugin (bindings/keymaps.lua defines none), so the only path that would see it raw is a direct Lua caller of `require("data").run/filter/run_auto`. The real consequence is the lost fallback: an upstream rename/removal of `block_at`, a signature change, or an error raised inside `list_blocks` aborts the command outright instead of falling through to the whole-buffer scope at resolve.lua:81 -- the graceful path a *missing* color_my_ascii already takes at lines 50-53. It affects only installations that actually have color_my_ascii and have not set `fenced_scope.enable = false`.

### `ERR-01` — `pcall()` an Systemgrenzen Pflicht

`lua/data/detect/init.lua:65` · `fenced_block_format` · confidence **high**

**Befund.** Same unguarded third-party call as scope/resolve.lua:55 -- `cma.fences.block_at(bufnr, row0, {})` after only a `type(cma.fences) ~= "table"` check on line 61.

**Regelbezug.** ERR-01: a plugin-API call at a system boundary, outside any hotpath, with no pcall and no check that the member being called is callable.

**Auswirkung.** An error inside `block_at`/`list_blocks`, or a renamed or removed member after a color_my_ascii update, aborts a rangeless `:Data pretty`/`lines`/`keys`/`sort`/`filter` entirely instead of falling through to the filetype-based detection written directly beneath it. It is reported as `UserCommand 'Data' failed: <lua error>` through lib.nvim's usercmd pcall wrapper (usercmd/init.lua:72-80), not as an uncaught raw error as the auditor claimed, and only on installations where color_my_ascii is present -- with it absent, line 60-63 already short-circuits cleanly.

### `ERR-02` — Type Guards & Literal Checks

`lua/data/init.lua:495` · `M.filter (on_done callback)` · confidence **medium**

**Befund.** `local mark = vim.api.nvim_buf_get_extmark_by_id(...)` (line 494) is followed by `source.s0 = mark[1]` with no check that the lookup succeeded; line 497 then calls `vim.api.nvim_buf_get_lines(bufnr, source.s0, ...)` unguarded. The very next line (496) DOES defend against the same empty result for `end_row`, so the omission is an asymmetry, not a deliberate contract.

**Regelbezug.** ERR-02 requires an explicit `type`/`nil` check before API access. `nvim_buf_get_extmark_by_id` returns an empty list when the id is absent, which makes `mark[1]` nil, and `nvim_buf_get_lines` rejects a nil `start` by raising.

**Auswirkung.** Two of the auditor's premises need correcting. The reload trigger is wrong: I tested `:edit!` on a real file and the extmark survived it intact, so autoread/`:e!` does not reach this. What does reach it is a foreign `nvim_buf_clear_namespace(buf, -1, 0, -1)` -- verified to wipe the mark, and a common enough idiom in plugins clearing highlights. And the error is usually not raw: with Neovim's default `vim.ui.select`/`vim.ui.input` (both synchronous), `pickers.refine`'s `Handle:prompt` (E:/repos/pickers.nvim/lua/pickers/refine/init.lua:199-250) invokes its done-callback before returning, so the throw is caught by `pcall(h.prompt, ...)` at lua/data/filter/init.lua:115 and re-enters the very same callback as `on_done(nil, err)`, surfacing as `notify.error("JSON filter: ...Invalid 'start': Expected Lua number")`. Only under an async `vim.ui.select` replacement (dressing.nvim, snacks, telescope-ui-select) does the error escape uncaught into that plugin's callback. Either way the outcome the rule exists to prevent holds: the filter result is lost, and the user is shown an API constraint rather than the clean, actionable message every other failure path in this function produces.

### `ERR-30` — Match/Edit vor dem Schreiben re-verifizieren

`lua/data/init.lua:500` · `M.filter (on_done callback)` · confidence **medium**

**Befund.** The filter result `out` is computed from `source.lines` (captured before the interactive pickers.refine prompt opened) and then written over the live scope; only the scope's POSITION is re-verified (via the extmark at lines 494-497), never its CONTENT.

**Regelbezug.** ERR-30 requires every edit computed during a scan to be re-verified against the *current* text immediately before writing, and skipped when it differs. Here the freshly re-read text is already in hand (`before`, line 497) and the original is still in `source.lines`, but the two are never compared -- `before` is only compared against `out` (line 500) to decide whether a diff is worth showing, not to detect that the scope drifted under the prompt.

**Auswirkung.** On the default path (`preview.filter` defaults to false, so line 500's `not preview` branch is taken), a character-level edit made inside the scope while the clause prompt is open is silently replaced by the result computed from the pre-edit text -- no message, recoverable only via undo. Narrower than the auditor stated: the specific triggers they name (format-on-save, an applied LSP text edit, any plugin rewriting the buffer line-wise) go through `nvim_buf_set_lines` over exactly the scope span, which inverts the extmark and ends in a loud `JSON filter: could not write the result: 'start' is higher than 'end'` refusal instead -- the repo documents and tests that separately at TESTS/filter_lifecycle_spec.lua:602-660. So the silent-overwrite class is the character-level one (`nvim_buf_set_text`, `:s///`) plus any edit that leaves the mark sane. With `--preview` the diff's before-side is the live text, so a user who reads the diff can still see the clobbered edit and decline.

### `ERR-51` — Merges kopieren Defaults tief

`lua/data/config/init.lua:16` · `M.options` · confidence **medium**

**Befund.** `M.options = DEFAULTS` aliases the shared defaults table directly, and the merge on line 71 (`lib_config.deep_merge(DEFAULTS, opts)`) only copies the top level -- any sub-table the user did not override (`out[k] = v` in lib.lua.config) is still the very same table as `DEFAULTS.json`/`DEFAULTS.preview`/etc. after setup.

**Regelbezug.** ERR-51 requires a merge to copy the defaults deeply rather than leave the shared defaults table exposed. `M.options` is declared public in the module's own `@class DataConfigModule ---@field options DataConfig`, so the aliasing is part of the documented surface -- inconsistent with `M.get`/`M.get_all`, which deep-copy precisely so "a caller that sorts/mutates it must not be able to corrupt the shared config".

**Auswirkung.** Strictly latent -- and narrower than the auditor implied in one respect they did not check. The merge does not mutate DEFAULTS: `deep_merge` writes only into its own fresh `out` and never into `base`, so the harm ERR-51 names most directly is already avoided, and a second `setup()` correctly re-merges from pristine defaults rather than accumulating. Both read accessors already copy -- `M.get` deep-copies any table result (lines 84-86) and `M.get_all` returns `vim.deepcopy(M.options)` (line 96) -- and a grep for `.options` across lua/ and TESTS/ finds no consumer at all outside config/init.lua itself. So nothing breaks today. What is real is the exposed surface: one write through the public field (`require("data.config").options.json.indent = 8`, or any write at all before `setup()` has run, where `M.options` is literally `DEFAULTS`) permanently rewrites `data.config.DEFAULTS` for the session, after which later `setup()` calls merge onto corrupted defaults and `:checkhealth`/docs report values the user never set. The auditor's own "latent today" caveat is accurate, and their pointer at the root fix belonging in `lib.lua.config.deep_merge` rather than a local patch is sound -- though a `vim.deepcopy` at line 16 is the separate, purely local half.

> **Abdeckung dieses Laufs.** Coverage: read all 22 Lua files under lua/ (2807 lines) in full, plus scripts/minimal_init.lua, scripts/test.sh, .luacheckrc, .luarc.json, .github/workflows/ci.yml, README.md, docs/requirements.md and docs/installation.md. Cross-checked three upstream dependencies where a rule turned on their behaviour: lib.lua.config.deep_merge, lib.lua.tables.paths.flatten, lib.nvim.json's vim.NIL normalization, color_my_ascii api/fences.block_at, and diff.nvim core/render side_by_side. Ignored .claude/, .git/, .deps/, doc/tags as instructed.

Rules verified as COMPLIANT rather than untested (each checked against actual code, not assumed): ERR-22 (every invalid config value provably degrades at its consumer -- indent clamped in format/{json,xml,yaml}.render, sep re-validated in path_flatten, register.default re-typed in register.name, target.split via SPLIT_DIRECTIONS, preview.view via VIEWS, preview.filter via `== true`, fenced_scope.enable via `~= false`); ERR-50 (validate() runs before the merge); ERR-54 (config.get/get_all deep-copy); ERR-20/PRIN-27 (a missing color_my_ascii fails open to whole-buffer scope); ERR-60 (all 15 `and/or` chains inspected; no possibly-falsy middle operand); ERR-62 (no `pcall(f(args))` form anywhere); ERR-33/LUA-13 (both async re-entry points re-validate the buffer handle -- the gap is content, not handle validity, see the ERR-30 finding); LUA-01 (lib.nvim hard everywhere, docs say "hard dependency, not optional"; the pcalls around lib.nvim.window and the format adapters are version-drift guards with matching :checkhealth errors, not a soft-dependency fallback); LUA-06 (DEFAULTS.lua is pure data, no env or FS lookup); LUA-16 (vim.NIL normalized upstream in lib.nvim.json, leaves re-checked via null.is_null); UI-55 (diff.nvim materializes its own scratch buffers for every view, so preview.lua's holder buffers are never displayed when drop_holders deletes them -- verified in diff.nvim core/init.lua:487-496); LUA-91/92 (diff.nvim's config.get falls back to DEFAULTS without setup, and neither adapter requires its plugin during data.nvim's setup); LUA-87 (docs use `opts`, not a `config` block; no self-written config file exists).

Genuinely no surface in this plugin: the whole SEC family (no shell string construction, no io.popen/os.execute/vim.fn.system/vim.system, no downloads, no secrets, no persistence, no vim.cmd, no vim.fn.expand), the whole XP family (no path handling, no glob, no executable() probe, no cross-platform command branch), PERF-07/42/46/47/62/72/80/82/92/93 (no caches, no timers, no libuv callbacks, no autocmds at all, no layout geometry), TS-04, LUA-17, LUA-48, ERR-31, CMT-16 (docs/BINDINGS.md is explicitly hand-maintained and says so; the composer's .document() generator is named as a cross-check, not as its renderer).

What I could NOT cover: the ~250 KB spec suite under TESTS/ was sampled, not read line by line -- I read the harness, the register/health/preview/filter stub-and-restore patterns and the package.loaded teardown (all of which are careful: stubs are pcall-protected and restored, buffers deleted in after_each), but did not audit all 30 spec files. I did not run the suite. One test-hygiene observation that no rule in the 76 cleanly covers, so it is not filed as a finding: TESTS/scope_register_edge_spec.lua:197-204 (`real_clipboard_works`) writes and clears the `+` register unconditionally without saving the prior contents, so running scripts/test.sh locally destroys whatever the developer had on the system clipboard. Also worth noting for coverage rather than as a rule violation: CI deliberately checks out neither color_my_ascii, pickers.nvim nor diff.nvim, so every spec gated on one of them registers zero tests in CI -- the fenced-scope, filter and preview paths are exercised only on a machine that has those siblings checked out.

---

## Anhang — widerlegte Rohbefunde

44 Rohbefunde hielten der Gegenprüfung nicht stand. Sie stehen hier,
damit ein späterer Lauf sie nicht erneut meldet und neu prüfen muss.

- **cascade.nvim** `ERR-60` `lua/cascade/sequence/renumber.lua:68` — The shape is at line 68 as described, but the code does satisfy the rule's intent and the stated harm is impossible — not merely latent. The fall-through can only be taken when `alpha.to_alpha(value)` is nil, and I checked both conversion domains empirically: alpha_to_alpha_fallback (util/lib.lua:368-370) returns nil exactly for a non-number or n < 1, and roman_to_roman_fallback (util/lib.lua:~272) returns nil for a non-number, n < 1 or n > 3999. Running both over -1, 0, 1, 26, 3999, 4000, 100000 and a string: every input where to_alpha is nil (-1, 0, "x") is an input where to_roman is nil too. So whenever the expression falls through, `c` is also falsy and the `if not out then return nil end` guard on line 69 catches it and returns nil correctly. There is no value — from any current or future caller, with any `start` value or signed seed — that yields the auditor's `a) b) iii)`; to_alpha's nil-domain is a strict subset of to_roman's by construction. The impact claim as written is fabricated.
- **casedesk.nvim** `LUA-12` `lua/casedesk/ui/commands.lua:109` — The line and the missing guard are as described (`local buf = vim.api.nvim_create_buf(false, true)` at line 109, used unchecked at 110-118 and `nvim_win_set_buf(0, buf)` at 119), but the stated failure mode cannot occur and the impact is fabricated. The 'returns 0 on error' contract in `:h nvim_create_buf` is the C/msgpack-RPC contract, where the error travels in a separate out-parameter. Through the Lua binding, any api function with an `Error *err` out-param raises instead of returning its sentinel — nvim_create_buf's failure path sets that error before returning 0. I verified the wrapper behaviour on three sibling calls in headless nvim: `nvim_buf_get_lines(9999, ...)`, `nvim_win_get_cursor(9999)` and `nvim_set_current_buf(9999)` all raise ('Invalid buffer id' / 'Invalid window id') rather than returning nil or 0. So `buf` is never 0 here; a creation failure surfaces as a loud error at line 109 and nothing below it runs. The command dump can never be written over the user's current buffer, and nothing is set `nofile`/`wipe`/`nomodifiable` behind their back. What remains is a bare letter-of-the-rule LUA-12 nit with no reachable consequence — not worth a fix entry, and the premise it rests on ('0 is the API's sentinel for the current buffer, so the failure value silently retargets every subsequent call') is wrong for Lua.
- **color_my_ascii.nvim** `SEC-30` `lua/color_my_ascii/debug/inspect.lua:30` — Refuting on rule applicability, not on the code fact. First, the line is 29, not 30 (line 30 is the `table.insert`). Second, the code fact is real and I verified it: `vim.pesc('%')` returns "%%" and `('+-%*'):find('%%', 1, true)` returns nil, and groups/operators.lua does list `+ - * / % =` among its characters — so `inspect_char('%')` really does report no groups. But SEC-30's requirement is that user input be literal-escaped *before a regex engine*, to prevent raw-pattern mismatches and pathological backtracking. Here `char` never reaches a pattern engine at all: `find(..., 1, true)` is a plain substring search, nothing is passed raw, and neither named harm can occur. The rule is satisfied vacuously; the defect is the inverse — escaping applied to an engine that does not want it. Report it, but as a correctness bug (drop `vim.pesc`, keep `plain = true`), not as a SEC-30 violation. The user-visible symptom the auditor describes is genuine: `:ColorMyAscii inspect char %` prints 'Groups: none' and `:ColorMyAscii hover` prints 'Char groups: none' (via hover.lua:142) for every magic character.
- **color_my_ascii.nvim** `SEC-34` `lua/color_my_ascii/commands/hover.lua:146` — The impact is fabricated. I tested the exact scenario in this machine's Neovim (v0.12.2): with the cursor on a whitespace-only line, `pcall(vim.fn.expand, '<cword>')` returned ok=true, r=""; on a fully empty line, also ok=true, r="". No E348. The rule's E348 sentence does not reproduce on a supported Neovim. On top of that the code already handles the empty case: line 147 is `if type(word) == 'string' and word ~= '' then`, so an empty result simply omits the Keyword section and the float still renders with the character/highlight/group lines gathered at lines 128-143. Finally, `'<cword>'` here is a static literal in the plugin's own source, not the buffer/user text SEC-34 forbids feeding to `expand`. Nothing breaks.
- **dap.nvim** `LLS-31` `TESTS/wkddap/core/setup_spec.lua:39` — The assertion exists as described (setup_spec.lua:34-40, assert.are.equal("3", vim.env.NVIM_DAP_LOG_LEVEL)), but this is not an LLS-31 violation and nothing breaks. LLS-31 targets a FUNCTION whose return or success is formed from planned rather than performed work; a spec asserting that setup() writes the env var is simply an accurate characterisation test of core/setup.lua:23 — the defect lives there and is already reported as its own finding. The stated impact is not a failure mode either: "a later fix turns this test red" is how characterisation tests are supposed to behave, and updating the assertion alongside the implementation is an ordinary part of the fix, not a regression. CMT-16 does not apply either — this is a hand-written spec, not a generated file. Duplicate of the core/setup.lua:23 finding, with no independent defect of its own.
- **dap.nvim** `LUA-13` `lua/wkddap/bindings/autocmds/init.lua:33` — The impact is fabricated: neither callback can ever run. I grepped the installed nvim-dap-ui (lazy/nvim-dap-ui, complete checkout — lua/dapui/{client,components,config,elements,render,windows,controls.lua,init.lua,util.lua}) for "DapUIWindow" and for nvim_exec_autocmds: zero hits for both. nvim-dap-ui emits no DapUIWindowOpen/DapUIWindowClose User event and fires no User autocmds at all, so the two autocmds registered at lines 25-39 are permanently inert — cursorline is never switched on or off in any window, in a DAP-UI window or a code window. (The module's own header comment at lines 4-5 asserting that nvim-dap-ui emits these events is likewise wrong.) The rule cited also does not fit this surface: LUA-13 is about re-validating handles captured before a vim.defer_fn/async callback, and these callbacks capture no window or buffer handle at all — they write vim.wo synchronously at event time. The genuine defect here is that the feature is dead code, which is a different finding under a different rule.
- **dap.nvim** `SEC-46` `lua/wkddap/languages/rust.lua:116` — The code is as described (rust.lua:116-118 embeds the sysroot unescaped in an LLDB double-quoted literal), but the claimed failure mechanism does not exist. I tested it against the LLDB that ships with the locally installed codelldb (mason/packages/codelldb/extension/lldb/bin/lldb.exe --batch -o 'command script import "C:\Users\tester\.rustup\toolchains\stable\lib\rustlib\etc/lldb_lookup.py"'). LLDB echoed and reported the path back byte-for-byte: "invalid pathname 'C:\Users\tester\.rustup\toolchains\stable\lib\rustlib\etc/lldb_lookup.py'". \U, \t, \r, \. and \l were all preserved literally — LLDB does not honour C-style escapes for those inside double quotes. A second test with a backslash immediately before the appended suffix ("C:\tools\rust\/lib/...") also came through intact. The premature-close case SEC-46 actually guards against is additionally unreachable here: the sysroot is never at the end of the literal ("/lib/rustlib/etc/lldb_lookup.py" is always appended), rustc --print sysroot emits no trailing separator, and a path segment containing a double quote is impossible on Windows and vanishingly unlikely elsewhere. The snippet is also the canonical nvim-dap-wiki construction, in wide use on Windows without this symptom.
- **data.nvim** `LUA-12` `lua/data/preview.lua:58` — The line and the unguarded usage are as described (`local bufnr = vim.api.nvim_create_buf(false, true)` at :58, then `nvim_buf_set_lines` at :59, `nvim_buf_set_name` at :60-64, `nvim_buf_delete(b, { force = true })` at :137), but the mechanism the impact rests on does not exist in Lua. The finding assumes `nvim_create_buf` hands back 0 as a value on failure; that is the RPC contract, not the Lua one. The `vim.api.*` bindings raise a Lua error whenever the API sets an error, and `nvim_create_buf`'s fail path always sets one (`Failed to create buffer`) before returning 0. I verified the raising behaviour empirically on this machine's nvim 0.12.2: `pcall(function() return vim.api.nvim_buf_get_lines(99999, 0, -1, false) end)` returns `ok=false, "Invalid buffer id: 99999"` rather than any sentinel value. `bufnr` at :58 is therefore either a real handle or control never reaches :59 at all -- it can never be 0. The described chain (current buffer overwritten wholesale, renamed, then `nvim_buf_delete(0, { force = true })` discarding unsaved changes before the confirmation prompt) is unreachable, and a failure at :58 throws before any holder buffer exists and before anything has been written, so nothing is destroyed. TESTS/preview_spec.lua:229-266 already pins the one real buffer-destruction regression in this module, which is a different one (teardown deleting a buffer it merely found in a diff.nvim window).
- **debugging.nvim** `PRIN-26` `lua/debugging/tools/vardump/init.lua:39` — The stated collapse does not exist. Line 39 is `local value = _G[varname]`, but in Lua there is no distinction between 'this global does not exist' and 'this global exists and holds nil' -- assigning nil to a global removes the key, so the two states the finding names are one state. There is nothing for the code to distinguish, and the output `Variable 'x': nil` is therefore unambiguous. The genuine sub-issue the impact describes -- `hello_from_cursor` dumping as `Variable 'hello'` -- does not originate at line 39 at all; it comes from `get_word_under_cursor`'s `line:find("%w+", col + 1)` at line 20, and the repo deliberately documents and pins that behaviour as acceptable: TESTS/tools_spec.lua:113-127 comments 'Not necessarily wrong (word-boundary definitions vary), but worth pinning'. The finding also carries `is_test_code: true` while pointing at production code.
- **diff.nvim** `ERR-01` `lua/diff/core/render.lua:432` — The claimed mechanism does not occur. Verified on nvim 0.12.2 under a genuinely exhausted layout (11 windows, winminheight=1): `pcall(vim.cmd, "silent! split | buffer 2")` returns **true** and `pcall(vim.cmd, "silent! vsplit | buffer 2")` returns **true** — `silent!` does suppress E36 for the first command of the bar chain. Only the bare form raises: `pcall(vim.cmd, "split | buffer 2")` -> false/E36, and `pcall(vim.cmd, "silent! split | split | split | split")` -> false, because `silent!` covers only the first chained command. Lines 432/435 use exactly the suppressed form (`silent! %s | buffer %d`). The auditor's stated verification ("returns false, Vim(split):E36") used the multi-`split` chain, which is not the code's shape. I also could not make `vim.cmd("tabnew")` throw (returns ok), and render.lua's own `split_into` comment claiming `silent! buffer <wiped>` raises E86 is likewise false here — `pcall(vim.cmd, "silent! buffer <wiped-id>")` returned true. So nothing escapes `M.three_way`, `scratch.discard` is not skipped, `scratch._bufs` does not grow and `on_done` does fire. There is a real defect at these lines, but it is a different one with a different rule: I verified that after the suppressed split failure the `| buffer %d` still executes and hijacks the current window (buffer went 1 -> target, window count unchanged at 11), which is the silent wrong-content failure `split_into` guards against — not the ERR-01 escaping-error claim made here.
- **diff.nvim** `ERR-01` `lua/diff/core/render.lua:726` — Same refutation as render.lua:432, verified against the identical command string. `pcall(vim.cmd, "silent! split | buffer N")` returns true even with no room, so no E36 escapes `M.inline` or `core.execute`. The specific impact chain is also wrong on its own terms: I verified the suppressed split still runs the `| buffer N`, so the buffer created on line 712 IS displayed (in the hijacked current window) — its `bufhidden = "wipe"` therefore does apply, it is not stranded in the registry, there is no permanent `diff:1`, and `done({...})` at core/init.lua:472-479 is reached so `on_done` fires normally.
- **diff.nvim** `ERR-01` `lua/diff/core/directory.lua:281` — Line 281 is `vim.cmd(string.format("silent! split | buffer %d", buf))` as claimed, but the same live verification applies: that exact form returns ok=true under an exhausted layout on nvim 0.12.2, so no E36 escapes `M.run` or `M.execute`. `directory.run` therefore still reaches its `return result({ buffers = { buf }, windows = { ... } })` on line 282, `core/init.lua:308-312` still calls `done(dir_result)`, and `on_done` fires. The summary buffer is displayed in the (hijacked) current window rather than leaked. The claimed consequence — neither `done` nor `fail` reached, buffer leaked into the registry — does not happen.
- **diff.nvim** `ERR-01` `lua/diff/features/origin.lua:61` — Line 61 is `vim.cmd(string.format("silent! %s | buffer %d", split_cmd, snap))` with `split_cmd` being `split` or `vsplit` — both verified to return ok=true through `pcall(vim.cmd, ...)` in a no-room layout on nvim 0.12.2. No E36 reaches the user as a raw Vim error, execution continues past line 61, and `require("diff.features.exit").attach_buffer(snap)` on line 72 DOES run, so the snapshot buffer is neither untracked-for-exit nor stranded — it is displayed in the hijacked window. The entire stated impact depends on a throw that does not occur.
- **diff.nvim** `LUA-01` `lua/diff/core/init.lua:526` — The four bare requires are real (`require("ui.kit").input` at 526 and 542, `require("ui.kit").select` at 588, `require("ui.kit.confirm").open` at 623), but the doc contradiction rests on a truncated quote. `docs/installation.md:11` reads in full: "Optional: ui.nvim — `ui.kit` backs the target/source picker (when pickers.nvim is absent) and the file-path/buffer-number prompts; the rest of the plugin loads without it, but those specific actions need it to work." The clause the auditor dropped states exactly which surfaces require it. LUA-01 permits a hard dependency (bare require, no fallback) as one of its two allowed choices and only forbids presenting one as optional in the docs — here the docs name the dependency, name the surfaces, and say those surfaces need it. Code and docs agree. LUA-01 is also written specifically about `lib.nvim`, which this plugin declares hard and documents as required on line 6. The health sub-claims are weaker than stated too: `vim.ui.select` is still genuinely used (pickers_bridge.lua:60, and `kit.select` is called with `respect_override = true` precisely to defer to a vim.ui.select override), so health.lua:40 is not describing a dead path. health.lua:85 reporting `ok(...)` without probing ui.kit is a real health-accuracy gap, but that is not the doc-vs-code inconsistency LUA-01 names.
- **diff.nvim** `SEC-21` `lua/diff/core/url.lua:94` — The description of the code is accurate — `--max-filesize` is passed to curl (lines 88-89 of the argv table) and `res.stdout` is never length-checked afterwards — but this is not a SEC-21 violation. The rule requires a timeout AND a byte limit, and the rule's own cited positive example is `images.nvim` `remote.lua:60-103, curl --max-time/--max-filesize` — the identical mechanism. diff.nvim supplies both required elements and its timeout is strictly stronger than the exemplar's: a libuv timer that SIGKILLs the process rather than `--max-time`. The rule's remaining clauses (URL-hashed cache against re-fetch, actively deleting aborted/failed downloads instead of leaving a corrupt file in the cache) do not apply — this path streams into memory and never writes a cache file. The chunked-transfer gap the auditor describes is a genuine hardening opportunity and the code comment on lines 40-43 is honest about the Content-Length precondition, but by the rule's own standard the requirement is met.
- **diff.nvim** `SEC-34` `lua/diff/features/origin.lua:36` — Line 36 is `local path = fn.expand(name)` as claimed, but the value cannot reach the shell. `name` comes from `api.nvim_buf_get_name(bufnr)` on line 31, which always returns a fully qualified absolute path — verified: `nvim_buf_set_name(b, "`whoami`")` then `nvim_buf_get_name(b)` yields `C:\`whoami``, and `nvim_buf_set_name(b, "%")` yields `C:\%`. Verified that `expand` leaves such path-shaped strings entirely literal: `expand("C:/tmp/`whoami`")` -> `C:\tmp\`whoami``, `expand("/a/b/`whoami`")` -> `\a\b\`whoami``, `expand("C:/tmp/%")` -> `C:\tmp\%`, `expand("C:/tmp/x`echo Q`y")` -> unchanged. Backtick substitution and the `%`/`#` specials only fire when the whole token is the span, which an absolute path never is. The empty-name case is already rejected on lines 32-34. The E282 impact claim also did not reproduce — every `expand` call I made returned ok=true. So this is the one SEC-34 site where the rule's harm cannot occur.
- **documentation.nvim** `ERR-22` `lua/documentation/bindings/usrcmds/init.lua:272` — The factual claim reads correctly -- line 272 is `local cfg = require("documentation.config").build(root, opts)` and line 308 the same, with only line 320 passing `notify` -- but ERR-22 does not apply to this surface. The rule's text names exactly one visibility channel: "sichtbar gemacht ueber `:checkhealth`". It does not require a per-command-dispatch warning, and `:DocMap`'s notify is not the surface it names; the actual ERR-22 breach for the editor host is the `health.lua:394` finding, and fixing that one discharges the obligation. The omission here is also deliberate and reasoned in the code (lines 316-319): `completion_names` runs `config.build` on every completion keystroke, so warning there would emit the same message per keystroke -- which is a worse outcome, not a rule violation. This is one rule breach filed twice, the second time against a channel the rule does not mention.
- **documentation.nvim** `LUA-12` `lua/documentation/editor/browse/init.lua:322` — Line 322 is indeed an unguarded `vim.api.nvim_win_get_width(st.slots.list.winid)`, but the rule is satisfied one frame up and the finding's supporting argument does not hold. `M.is_open()` (line 225-227) is `state ~= nil and state.group ~= nil and state.slots.list:is_valid()` -- a validity check on this exact handle. Every asynchronous path into `render` performs it synchronously with no yield before the call: `again()` (278-282) checks `state == st and M.is_open()` then calls `render(st)` immediately; the `on_change` subscription (1684) and the `kit.input` `on_submit` (1010) do the same; `M.open` calls `render(state)` at 1699 directly after mounting the layout; the remaining call sites (460, 476, 614, 630, 691) are keymap actions that only exist while the layout is mounted. The neighbouring guard at 326 is not the file's admission that the handle can be invalid there: it is paired with `#st.entries > 0` and an additional `pcall`, i.e. belt-and-braces around a cursor move, and four lines later `selected()` makes the identical unguarded access at line 347 (`vim.api.nvim_win_get_cursor(st.slots.list.winid)`) with no guard at all -- so the file's convention is demonstrably boundary-guarding, not per-call guarding. The finding itself concedes no reachable failure exists.
- **emojis.nvim** `ERR-11` `lua/emojis/overlay/frecency.lua:77` — The mechanics are exactly as described -- `load()` (lines 64-90) returns the same empty `_store` for 'file absent' (72-74), 'unreadable' (read_file returns nil, same branch) and 'json decode failed' (76-79), `record()` mutates it (137-155) and `save()` rewrites the whole file via `uv.fs_open(path, "w")` non-atomically without checking `fs_write` (115-121). But ERR-11's Belege explicitly carve this out: a load-modify-save collapse is 'kein Fund' when the code itself documents the loss tolerance deliberately ('a report file is a convenience artifact, not data' -- github_stats telemetry/store.lua, runtime-analysis's equivalents). frecency.lua does that in three separate places: the module header at lines 16-19 ('a missing, unreadable, or corrupt file degrades to "no usage recorded yet" rather than erroring, because losing a usage histogram must never break emoji insertion'), the save() comment at 101-105, and the load() comment at 81-82. The auditor's impact is also wrong on two counts: the file is not 'the only copy of state that cannot be regenerated' -- it only reorders `overlay.picks`, a config-owned curated list, so the overlay keeps working and falls back to the curated order, and the histogram rebuilds through normal use; and lines 83-87 filter per entry, so a file that decodes but has malformed entries keeps every well-formed one. Nothing the user authored is lost. This is the documented convenience-artifact case, not the bug class the rule names.
- **fileops.nvim** `ERR-33` `lua/fileops/bindings/usrcmds.lua:518` — ERR-33 (and LUA-13) require that a deferred callback re-validate the window/buffer handles it was given, with `nvim_win_is_valid`/`nvim_buf_is_valid`, at execution time rather than only at capture time. That is not what happens here, and the finding's own "why" concedes it: no handle is captured and carried across the async boundary at all. `file.delete_current` (ops/file.lua:702-712) starts with `local b = cur_buf()`, and `cur_buf()` (lines 21-25) is `api.nvim_get_current_buf()` followed by `api.nvim_buf_is_valid(b)`, then `buf_path(b)` re-checks validity again — so the handle the callback acts on is both freshly derived and validated at execution time. There is no stale handle and no invalid-handle path. What the finding actually describes is async target drift, which is a different concern from the one ERR-33 states. The impact claim is also overstated: `delete_path_from_disk` builds its message from the path it actually deleted (`fn.fnamemodify(path, ":t")`, line 681), so the notification names the file that was really removed rather than silently reporting success for the intended one. Reachability is narrow besides — `filetree_assets.confirm` returns `cb(nil)` synchronously whenever filetree.nvim is absent or `outgoing_assets_mode()` is "off" (integrations/filetree_assets.lua:73-76), and in "auto" mode it returns without any dialog (107-116).
- **filetree.nvim** `SEC-34` `lua/filetree/features/search/grep_in_dir/init.lua:254` — The impact claim is fabricated -- I tested it rather than trusting it. Under nvim 0.12.2 headless (-u NONE), on an empty line, a whitespace-only line, and a word line, `pcall(vim.fn.expand, "<cword>")` returned ok=true with "", "" and "word" respectively. No E348 is ever raised, because f_expand() increments emsg_off around eval_vars and discards the errormsg; the E348 the rule cites is raised by the eval_vars path used by :normal/:execute and cursor-token helpers like spotlight's, not by vim.fn.expand(). So the unguarded call at line 254 cannot produce the raw error out of the keymap callback that the finding describes. Separately, the rule does not apply to this surface in the first place: SEC-34 forbids expand() ON buffer/user text, and its own text exempts "jede legitime Verwendung auf einer eigenen, statischen Config-Zeichenkette". Here the argument is the static literal "<cword>" and the special is being used deliberately and correctly for its documented purpose; the buffer text never enters the expand() argument. The call is additionally only reachable via keymap_cword, which is nil by default (init.lua:40, @types/config.lua:452).
- **images.nvim** `ERR-03` `lua/images/paste.lua:215` — The finding's premise is that `vim.fn.mkdir` fails silently by returning 0, so the `pcall` cannot report it. That is wrong in Neovim, and I tested both of the failure modes the finding names rather than reasoning about it. (1) A file already occupying the name: created a regular file, then `pcall(vim.fn.mkdir, <file>/sub, "p")` returned `ok = false`, `err = 'Vim:E739: Cannot create directory ...: file already exists'`. (2) An unwritable location: `pcall(vim.fn.mkdir, "Z:/nope/deep", "p")` returned `ok = false`, `err = 'Vim:E739: Cannot create directory Z:/nope: operation not permitted'`. Neovim's `f_mkdir` emits the failure via `semsg`, and `vim.fn.*` calls convert an emitted error into a Lua error that `pcall` catches. So line 216's error branch is reachable and does fire, and `target_paths` correctly returns `nil, nil, "could not create the directory: " .. dir`. The claimed impact — a path returned under a directory that was never created, with the failure surfacing misleadingly as `move_file`'s "could not move the file" — does not occur. calibration.lua:72-73's extra `made == 0` check is belt-and-braces, not a correctness difference.
- **images.nvim** `LUA-01` `lua/images/integrations/menu.lua:19` — The auditor misread two separate statements as one. The module header's "soft, opt-in" and "images.nvim has no dependency on a menu plugin" are about **nvzone/menu**, not ui.nvim — and the very next clause names the ui.nvim source openly: "built with the helpers from `ui.contextmenu`" (menu.lua:5-6). The finding also quotes TESTS/menu_spec.lua:4 while omitting lines 6-10, which state the opposite of what it is cited for: "a host only ever loads this module because it is already building a menu with ui.nvim's builders, so that is a deliberate hard dependency, not a bug (see docs/CONTRIBUTING.md: this is one of the 'soft-dependency bridges' under `integrations/`, soft meaning the *target* — nvzone/menu — not ui.nvim itself)." docs/CONTRIBUTING.md:65 carries the same policy. The compare.lua:44-56 precedent does not transfer: `:Image compare` is a command the plugin registers itself, so it must degrade; `images.integrations.menu` is required by nothing in `lua/` or `plugin/` (grep: the only `require("images.integrations.menu")` in the repo is the usage example in its own docstring on line 9), so it loads only when a host opts in. `M.items`' documented return type is `Ui.ContextMenu.Item[]` — a ui.nvim type — so even a clean degradation to `{}` would be unusable to a caller without ui.nvim. The "documented empty list" the impact rests on is documented for the `menu.enable == false` and wrong-filetype cases (menu.lua:36-38), never for a missing ui.nvim.
- **lib.nvim** `PERF-42` `lua/lib/nvim/fs/scan_roots/init.lua:54` — The code is as quoted (line 54-55: `local fresh = opts.ttl_seconds == nil or (os.time() - (cached.saved_at or 0)) <= opts.ttl_seconds`), but the finding's load-bearing claim — that this is "undocumented behaviour rather than a considered default" — is false. `lua/lib/nvim/fs/scan_roots/@types/init.lua` line 7 declares it explicitly: `---@field ttl_seconds integer|nil Cache freshness window in seconds; `nil` means the cache never expires once written.` PERF-42 requires that it be *defined* when an entry becomes invalid; here it is defined in the public type contract, and the caller opts into the on-disk cache by supplying `cache_path`. That the default is permanent rather than always-rescan is a design choice one may disagree with, but it is a stated contract, not the undefined-invalidation case the rule targets. The auditor's supporting argument ("the module's own usage example shows cache_path and ttl_seconds together") describes the header example only and does not establish that the nil case is unconsidered.
- **mdview.nvim** `ERR-03` `lua/mdview/adapter/install.lua:147` — REFUTED — the premise is factually wrong for the vim.fn Lua binding, so the impact is fabricated. The auditor asserts "vim.fn.mkdir() returns 0 on failure rather than raising, so mkdir_ok is true whether or not the directory was created". I tested this under nvim 0.12.2 headless: `pcall(vim.fn.mkdir, <path-under-a-regular-file>, "p")` returned ok=false, res="Vim:E739: Cannot create directory ...: file already exists", and `pcall(vim.fn.mkdir, "C:/Windows/System32/config/mdview_probe_dir", "p")` returned ok=false, res="Vim:E739: ... operation not permitted". Neovim's mkdir() emits E739 via semsg, and calls made through vim.fn/vim.call run under TRY_WRAP, which converts an emitted error into a Lua error — so pcall catches it and `mkdir_ok` IS a valid success/failure signal. (This is the difference from vim.fn.system, which genuinely does return normally on a nonzero exit — I verified that in the same run, shell_error=127, which is why findings 3 and 4 stand and this one does not.) Consequently the error branch at install.lua:148-150 is reachable and reports the correct cause, the same holds for line 242 in ensure_client_bundle, and the claimed misdirection into "curl failed (exit 23)" does not occur: an unwritable stdpath('data') fails at line 148 with "failed to create install directory: <dir>", which is exactly right.
- **mdview.nvim** `PERF-93` `lua/mdview/core/breadcrumbs.lua:29` — REFUTED — the code satisfies the rule, and the impact does not hold against what the plugin already does. The line is real (nearest_heading at 28-44 does nvim_buf_get_lines(bufnr, 0, line, false) and walks it, and the dedup is at line 79, after the scan), but PERF-93's requirement is stated as a disjunction in its own title — "billiger Guard **oder** Throttle, nie ungeschützt" — and the handler has the throttle: bindings/autocmds/breadcrumbs.lua:27-30 returns immediately when `now - last_at < 300`. It is not an unprotected handler, which is the state the rule forbids. Beyond the throttle the scan sits behind three further gates that the finding does not account for: the autocmd is registered with `pattern = defaults.ft_pattern` (line 37) so it does not fire on arbitrary buffers; M.record returns false at line 52 unless previewable.is(bufnr); and nearest_heading is only called when the filetype is markdown/md (line 77), so under any_file it never runs at all. The cost claim also collapses in context: the scan only happens while a preview session is attached, and during exactly that time live_push serializes the ENTIRE buffer and POSTs it to the relay every 150ms (live_push.lua:147-153) — twice as often, for strictly more work than an in-process prefix scan. A 300ms-bounded read of the buffer prefix is not the hot-path cost the finding describes, and the module's header comment at lines 4-6 documents the design deliberately. The auditor's own framing ("the 300ms throttle bounds the rate, not the per-call cost") concedes the protection the rule asks for is present.
- **my.nvim** `SEC-34` `lua/my/hl_config/breadcrumbs/ctx/base.lua:98` — The code is as described (line 98 `local w = vim.fn.expand("<cword>")` unprotected, same at line 57 and at ctx/providers/word.lua:26), but the impact is fabricated. I tested the claim directly on this machine with NVIM v0.12.2: `pcall(vim.fn.expand, '<cword>')` with the cursor on an empty line returns `ok=true val=""`, and on a whitespace-only line likewise `ok=true val=""`. It throws ONLY once `'verbose'` is raised -- re-running the same snippet under `set verbose=1` gives `ok=false val="Vim:E348: No string under cursor"`. That matches `f_expand`, which increments `emsg_off` when `p_verbose == 0`, so E348 never sets `did_emsg` and never reaches Lua. At default settings the breadcrumb does not lose its context segment and `:My hl debug` does not render `<error: ...E348...>` (that formatter exists at usrcmds/debug.lua:49, but nothing reaches it here). Independently, SEC-34's prohibition is on passing BUFFER/USER TEXT as expand()'s argument -- the backtick-span command-substitution hazard -- and these three sites pass the static literal `"<cword>"`, which the rule's own closing note carves out ("jede legitime Verwendung auf einer eigenen, statischen Config-Zeichenkette"). The sibling pcalls at cword_occurrences/init.lua:319 and features/current_word.lua:37 are belt-and-braces, not evidence of a live throw.
- **my.nvim** `XP-03` `lua/my/declarative/shell.lua:25` — XP-03's failure mode is the DEFAULT `>`/`Out-File` writing UTF-16LE with BOM, and its prescribed fix is "Die Ausgabe aus stdout holen und aus Lua schreiben". Lines 25-26 do not use bare `>` -- they pass `-Encoding UTF8` explicitly, so the UTF-16LE outcome the rule exists to prevent cannot occur here. The rule's remedy is also structurally unavailable on this surface: `'shellredir'` and `'shellpipe'` are Vim options that Vim itself expands when it redirects, so there is no Lua-side capture to move to stdout; the rule's Beleg (insights.nvim's `:Insights tree` and `compress` file-list, "beide holen die Liste jetzt aus stdout") is a Lua caller reading back a redirect, which this is not. The residual fact -- Windows PowerShell 5.1's `Out-File -Encoding UTF8` emitting EF BB BF, and line 33-35 setting 5.1 synchronously with the pwsh upgrade at 66-79 never arriving without pwsh -- is correct. But the claimed consequence (quickfix/errorformat mis-parsing the first entry, failed jumps) is asserted, not demonstrated: no code path in this repo reads a redirected file, I found no evidence any `:make`/`:grep` route here is affected, and the auditor rates it low confidence. Per the instruction to default to refuted when the code does not confirm it.
- **my.nvim** `XP-05` `lua/my/declarative/clipboard.lua:28` — XP-05 is scoped to Windows in its own heading ("ist unter Windows teuer und ungecacht") and its entire cost model is PATH x PATHEXT -- "jeden PATH-Eintrag gegen jede PATHEXT-Endung", measured 67 x 11 = 737 stats, ~44ms. PATHEXT does not exist on Linux or macOS, where a failing `executable()` is one stat per PATH entry. The ~42ms in the module's own comment (lines 22-26) is explicitly the Windows number ("On Windows wl-copy can never be found, so that was 42ms"), and the `not is_windows` guard at line 27 is precisely the remedy XP-05 asks for, applied on the platform XP-05 covers. Carrying that Windows figure to Linux/macOS is the fabricated part of the impact. The claim that the answer is "knowable in advance" on Linux is also wrong -- Wayland is common there, so the probe is load-bearing, and the `and` chain means only `wl-copy` runs when it fails. The line-62 `fn.executable("win32yank")` site is on Windows, but the comment at 63-67 documents that win32yank ships with the Neovim Windows installer, so the probe succeeds (~0.2ms) on a normal install; on the rare machine without it, the fallback the code deliberately leaves in place is Neovim's own provider probe, which the same comment measures at ~28ms of process spawns -- more than the probe it replaced.
- **pdfport.nvim** `ERR-03` `lua/pdfport/util/tmpfile.lua:43` — The code reads as claimed -- tmpfile.lua:43 and :53 discard `vim.fn.writefile`'s return and :44/:54 return `path` unconditionally, and :25 ignores `vim.fn.mkdir` -- but the premise and the entire impact are wrong. `vim.fn.writefile` does not quietly return -1 in Neovim's Lua bridge; the Vimscript error becomes a Lua error. I verified both in this Neovim: `pcall(vim.fn.writefile, {"x"}, "Z:/nonexistent_dir_xyz/out.txt")` returns false with "Vim:E482: Can't open file Z:/nonexistent_dir_xyz/out.txt for writing: no such file or directory", and `pcall(vim.fn.mkdir, "Z:/nope/deep/dir", "p")` returns false with "Vim:E739: Cannot create directory Z:/nope: operation not permitted". So on a full disk, a read-only cache directory or a permission failure, the write raises before line 44 is ever reached. composer.lua:191 and :195 call these outside any pcall, so the error propagates out of `M.create` naming the real cause and the real path. Every consequence the finding lists therefore cannot occur: no non-existent path reaches the producer chain, no `pandoc exited 1` masquerades as the error, and composer.lua:205 never runs because `tmp_path` is never assigned. This is a loud failure, which is what ERR-03 asks for. The style point -- that a function whose job is "materialise this and give me the path" would be better as `(path, err)` than as a thrower -- stands, but there is no silent failure and nothing breaks.
- **pdfport.nvim** `LUA-16` `lua/pdfport/backends/claude.lua:136` — The lines are where the finding says (claude.lua:135-136 `---@diagnostic disable-next-line: undefined-field` then `text = res_or_err.text`; gemini.lua:139-140 identical), but the value cannot be `vim.NIL`, so the rule does not bite here. `res_or_err` is not a decoded HTTP body -- it is ai.nvim's normalized `Ai.Response`, and I read ai.nvim's own construction of that field. providers/claude.lua:105-112 builds `text_parts` under an explicit `if block.type == "text" and type(block.text) == "string"` filter and returns `text = table.concat(text_parts, "")`; providers/gemini.lua's `candidate_text` (:103-115) does the same, filtering on `type(part.text) == "string"` and returning `table.concat(text_parts, "")`, with an early `return "", nil` when there are no candidates at all. `table.concat` cannot return anything but a string, and `Ai.Response.text` is typed `string` (ai.nvim lua/ai/@types/init.lua:86-87). A refusal, an empty content array and a safety block all arrive as `""`, not as null -- gemini even has dedicated handling for the no-candidates case (`prompt_block_reason`). LUA-16 asks for the guard on fields coming from external data; the JSON boundary and its sanitizing are ai.nvim's, one layer down, and that layer does the work. The auditor flagged this low-confidence for exactly this uncertainty; the answer is that the value cannot arrive.
- **pdfport.nvim** `XP-05` `lua/pdfport/platform/init.lua:74` — The line exists as described -- platform/init.lua:74 is `vim.fn.system({ python, "-c", "import " .. module })`, synchronous, reached from docling.lua:28 and pdfplumber.lua:27 via resolver.lua:63 -- but the rule does not fit it. XP-05 is specifically about `vim.fn.executable()`/`exepath()`, whose cost comes from walking every PATH entry against every PATHEXT suffix on a *failing* probe, and whose stated defect is that "`vim.fn` cacht das Ergebnis nicht, zweimal probieren kostet zweimal". This is neither: it is a subprocess, and the result IS cached -- `_exe_cache["pymod:" .. module]` is checked at :68 and written at :76, so a second probe costs nothing. The rule then names three acceptable remedies: defer past the first event-loop tick, *cache the result*, or set a synchronous alternative and defer the upgrade. The code implements the second one verbatim, which is the rule being satisfied, not violated. The plugin's actual `executable()` probes also go through `lib.nvim.core.has_exec`, documented in lib.nvim/lua/lib/nvim/core/@types/init.lua:5 as "Memoized `vim.fn.executable(bin) == 1`". Finally, XP-05's evidence and framing are about the *startup* path ("einer der teuersten Einzelposten eines Startups", pwsh/shellcheck at init); `available()` here runs only on an explicit user-initiated extraction. The auditor's "torch and friends, tens of seconds" figure is asserted, not read out of any code in this repo. A synchronous foreground `import` with no timeout may well be worth fixing on its own merits, but it is not an XP-05 violation.
- **pickers.nvim** `ERR-11` `lua/pickers/smart/frecency.lua:67` — The code is as described but the impact is fabricated — the prescribed protection is already in force, at the root, exactly where ERR-11's own Belege say it was put. `store()` (frecency.lua:82-95) builds the handle with `namespace = "frecency", dir = dir`, and lib.nvim's frecency store persists through `lib.nvim.cache.disk` (frecency/init.lua:45, 113, 210) whose `cache_path` is `cache_dir(opts) .. "/" .. namespace .. ".json"` (cache/disk.lua:28-38) — with `opts.dir = dir` that is literally `dir .. "/frecency.json"`, the same file `migrate_legacy` opens at line 60. `read_entry()` (cache/disk.lua:62-91) detects the decode failure on non-empty content and writes the original bytes to `frecency.json.corrupt` before anything overwrites the file, once per corruption. The store loads lazily via `entries()` (frecency/init.lua:105-117), which runs on the first `record`/`score` — i.e. before any `flush()` — so the backup is taken on the same session in which the truncated file would be replaced. `migrate_legacy` returning early on a decode failure is moreover the correct behaviour: a file it cannot decode has nothing to migrate, and `seed()` refuses a non-empty store anyway. So the claim 'gone with no message, no backup and no way to tell it apart from a first run' is wrong on the backup, and the data is recoverable from the `.corrupt` file.
- **recommender.nvim** `PERF-93` `lua/recommender/statusline.lua:54` — Read statusline.lua:44-79 and the whole module. PERF-93 governs handlers on hot autocmd events (CursorMoved(I)/TextChanged(I)/WinScrolled) and explicitly names a `changedtick` comparison as 'der billigste denkbare Guard'; its own 2026-08-25 fleet sweep counted a changedtick comparison (lib.nvim cache/memory.lua) among the five false alarms. This surface is not an autocmd handler: the only autocmd the module registers is BufDelete/BufWipeout at lines 107-115 to drop cache entries, and a grep finds nothing in lua/ or plugin/ that wires M.status to any event — it is a function the user opts into by placing it in their own statusline. So the code carries precisely the guard the rule names as sufficient, on a surface the rule does not cover. The impact statement is also overstated: `parser:parse()` on a buffer-attached Lua parser reparses incrementally, not 'a full tree-sitter re-parse' per keystroke. A debounce or an insert-mode skip may still be a worthwhile optimization, but it is not a PERF-93 violation.
- **replacer.nvim** `LUA-87` `lua/replacer/config/init.lua:259` — The impact claim is fabricated — vim.tbl_deep_extend does not merge list-valued keys index by index. I ran it in headless nvim (v0.12.2): `vim.tbl_deep_extend("force", {}, { exclude = { "node_modules", "dist" } }, { exclude = { "build" } })` returns exclude = { "build" }, not { "build", "dist" }. Neovim's tbl_extend gates recursion on can_merge(), which excludes non-empty list-like tables and replaces them wholesale; that guard predates the plugin's declared 0.9 floor. So a second setup({ exclude = {"build"} }) replaces the list cleanly, and the same holds for file_types and globs. What remains of the finding is the cumulative-merge shape itself, and that is explicitly deliberate and covered: TESTS/config_merge.lua section 11 asserts 'setup({}): accumulates onto current state rather than resetting to DEFAULTS' with a comment stating 'Documented behavior (not a bug)', and config/init.lua:268-275 offers M.resolve() as the non-persisting override path. With the only claimed silent-corruption mechanism disproved, there is no violation left to confirm.
- **rules.nvim** `ERR-01` `TESTS/checks_spec.lua:98` — The two specs (91-109 and 111-128) do restore `fswalk.files` with an unguarded assignment at lines 106 and 125, but the calls in between cannot throw: they pass hardcoded valid specs (`{ type = "grep", pattern = "x" }` / `"y"`) against a fresh tmp dir holding one one-line file, and the monkey-patch is a counting passthrough that returns `original_files(...)` unchanged. The malformed-spec crash paths from the other findings are unreachable from these literals. The stated precedent is also a misreading: the `pcall(grep.run, ...)` at line 82 is not teardown protection — it is the test's subject, immediately asserted on at line 85 (`assert.is_true(ok)`) to prove grep.run converts an unreadable file into a `fail` finding instead of throwing; the restore at line 83 happens to sit after it. ERR-01 mandates pcall at *system boundaries* (filesystem, external processes, plugin APIs), not the restore half of a test monkey-patch, which would be an `after_each`/teardown-hygiene concern under a different rule.
- **rules.nvim** `ERR-22` `lua/rules/health.lua:65` — ERR-22 governs an *invalid config single value degrading to its default*, made visible via `:checkhealth`. No such degradation happens on this path: a `~`-prefixed `rulesets` entry is a valid string list, passes `config/init.lua:34-43`'s `is_string_list` check and is used as given — nothing falls back to a default, so there is no degradation event for health to surface. The degradation ERR-22 actually describes is handled at config/init.lua:38-42 and 58-62 (`vim.notify(... WARN)` + fall back to DEFAULTS). The health line is also not the fabricated reassurance claimed: it prints `("%d rule(s) loaded from %d ruleset path(s), no errors")`, i.e. it states `0 rule(s) loaded from 1 ruleset path(s)` — the zero count is in the message. This is the same single defect already reported (correctly) as ERR-11 at loader.lua:35, restated at a second call site under a rule that does not cover it.
- **rules.nvim** `SEC-35` `scripts/test.sh:25` — The line is real (`cmd="PlenaryBustedFile $target"`, `target="${1:-TESTS/}"`, passed as `nvim ... -c "$cmd"` at line 30), but SEC-35 does not apply here. The rule targets a topic/search term/path *aus Nutzerhand* reaching a plugin's `-c`/`vim.cmd` string, and prescribes passing it as an argument to the API instead (`vim.cmd.help(topic)` / the list form). There is no such alternative in a shell invocation — `-c "<ex command>"` is the only interface a shell has to Ex, so the prescribed fix does not exist at this surface. More importantly there is no trust boundary to cross: `$1` is an argument the maintainer types into their own shell in a script whose next action is `exec nvim`, so anyone who can supply it can already run any command directly; the `writefile` example is a fabricated escalation from a shell to the same shell's own Neovim. The residual real issue — a spec path containing a space splitting into two Ex arguments — is an ergonomics nit in a dev script, not a SEC-35 violation.
- **runtime-analysis.nvim** `ERR-60` `lua/runtime-analysis/telemetry/reminder.lua:70` — The lines are as cited (70/71 use `(config and config.X) or M.DEFAULTS.X`; the `days and`/`calls and` guards are at 80 and 84), but this is not an ERR-60 defect -- the fallthrough IS the documented intent. `@types/init.lua:10-12` declares `RA.Telemetry.RemindAfter` with `days?: integer` and `calls?: integer`, each documented with its own default, and states outright: "`false` opts out entirely; otherwise the first of the two thresholds to be reached fires the (single) reminder". README.md:125 repeats it: "`remind_after` | `{ days = 7, calls = 50000 }` | lifecycle reminder; `false` opts out". There is no documented or typed way to disable one trigger individually, so `remind_after = { calls = 100000 }` means "calls threshold 100000, days default 7" -- exactly what the code produces. The claimed impact describes a semantic the API never offered. `M.DEFAULTS` holds two non-nil integers, so `days`/`calls` are always truthy and the `and` guards at 80/84 are redundant defensive code, but they never change an outcome and nothing breaks. ERR-60's actual harm -- `c` being returned when the caller meant `b`'s falsy value -- cannot occur here because the type forbids a falsy `days`/`calls` and the nil case is supposed to yield the default.
- **sandbox.nvim** `PRIN-10` `lua/sandbox/ui/list_actions.lua:399` — The code shape is as described (lines 398-403 save, flip `config.options.confirm_destructive = false`, loop, restore, with no pcall), but the impact chain is fabricated -- I could not reach a throw between the flip and the restore, and all three sources the finding names are wrong for this path. (1) "a nil id": `ref(item)` returning nil is caught by every callee's own `if not id or id == ""` guard (container_commands.lua:190-193 for kill, same for remove) and returns early. (2) "an nvim_buf_set_name E95 clash": no buffer is created anywhere in this loop. (3) "the unguarded vim.system above": the bulk callees do not use `vim.system` -- adapters/docker/containers/kill_container.lua:12, remove_container.lua:12 and images/remove_image.lua:12 all use `vim.fn.jobstart`, which returns -1 for a non-executable command instead of raising. The five call sites (list_view.lua:239,246; image_list_view_{docker,podman}.lua; network_list_view.lua:76; volume_list_view.lua:70) all route to that same jobstart family. On top of that, PRIN-10 sits awkwardly here: LUA-87 explicitly prescribes `config.options.X` as the access path, and every module in this plugin reads it directly. Worth hardening the flip/restore with a pcall on principle, but nothing in the code as written breaks.
- **sandbox.nvim** `UI-55` `lua/sandbox/bindings/usrcmds/container_commands_buffer.lua:25` — The premise fails. The finding assumes a buffer named `sandbox.nvim://term/start/<id>` survives to be found by the loop at lines 23-28, but line 32 sets that name and lines 35-39 then hand the buffer to `jobstart(cmd, { term = true })` / `termopen(cmd)`, which renames the buffer to `term://{cwd}//{pid}:{cmd}` (that is what makes terminal buffers show a `term://` name at all). By the time the function returns, no buffer carries the `sandbox.nvim://term/...` name, so `nvim_buf_get_name(buf) == name` can never match on a subsequent run and the `nvim_buf_delete` at line 25 is unreachable dead code rather than a UI-55 violation. The finding's own supporting argument works against it too: with `bufhidden = "wipe"` (line 41) a hidden terminal buffer is gone, and a visible one no longer answers to that name either. Running the same `--buffer` command twice simply opens a second terminal split.
- **sandbox.nvim** `XP-05` `lua/sandbox/bindings/usrcmds/init.lua:934` — The call chain is as described (line 934 `if wsl_cmds.available() then` -> wsl_commands.lua:26 `engine_utils.is_executable("wsl")` -> engine_utils.lua:33 `require("lib.nvim.core").has_exec("wsl")`, reached from plugin/commands.lua:1), but the rule does not bite here. XP-05's cost is specifically a *failing* probe under Windows PATHEXT -- the rule's own measurement is "jeden PATH-Eintrag gegen jede PATHEXT-Endung, 67 x 11 = 737 Stats, ~44 ms". On Windows the probe does not fail: `wsl.exe` ships in System32 on Windows 10/11 whether or not a distro is installed, so it is the cheap first-hit case (~0.2 ms). On Linux and macOS, where it does fail, there is no PATHEXT multiplication -- a failing `executable()` is one stat per PATH entry, well under a millisecond -- so the finding's "full failing PATH scan" inverts the platform the rule is about. Additionally, `has_exec` memoizes (lib.nvim/lua/lib/nvim/core/init.lua:13-20), and "das Ergebnis cachen" is one of the three remedies XP-05 itself prescribes. health.lua:77-81 probes `wsl` again on the same memoized path, so the healthcheck is free too.
- **ui.nvim** `ERR-62` `lua/ui/init.lua:44` — Line 44 reads `local ok, err = pcall(require("ui.bindings.keymaps").setup, opts.keymaps)` -- that is `pcall(f, args)`, which is literally the form ERR-62 prescribes as the FIX ("Immer `pcall(f, args)` oder eine anonyme Funktion uebergeben"). The forbidden `pcall(f(args))` shape appears nowhere: line 51 is `pcall(require("ui.bindings.usrcmds").setup)` and line 65 is `pcall(require("ui.contextmenu").set_enabled, false)` -- both pass the function and its argument separately. The setup call IS protected, and each of the three blocks checks `ok` and calls `notify.error(...)`, so the comment's stated intent holds. The auditor's residual observation is true Lua semantics (the `require` in the argument position is evaluated before pcall is entered, so a module LOAD error is unprotected) but that is a different concern than ERR-62, which is exclusively about the call being made outside the pcall and its error never being caught.
- **ui.nvim** `UI-55` `lua/ui/bindings/keymaps/tabufline/state.lua:253` — Line 253 does contain `vim.cmd((skip_confirm and "bd! " or "confirm bd") .. bufnr)`, and it is true that only the current window is redirected beforehand (line 237 `vim.cmd("b" .. vim.t.bufs[idx + step])`, line 249 `vim.cmd("enew")`). But the harm UI-55 names does not occur. `:help :bdelete` states "Any windows for this buffer are closed", and Neovim implements this via `close_windows(buf, false)`, which closes every window showing the buffer and stops at `ONE_WINDOW`. Other windows are therefore closed, not left holding an empty scratch buffer. The empty-scratch outcome UI-55 exists to prevent applies only to the LAST remaining window -- and that is precisely the window this code already redirects, via the `:b <neighbour>` / `:enew` branches, which is why the doc comment at line 193 says it lands "on a sensible neighbour rather than whatever Neovim's own `:bdelete` would fall back to". The `M.close_all_bufs` corollary (line 276) inherits the same correction: once every listed buffer is deleted, one window survives with one empty buffer, not "a scratch buffer in each surviving window". A different, unclaimed consequence does exist -- splits showing the same file disappear rather than being redirected -- but that is not what UI-55 describes and not what this finding asserts.
