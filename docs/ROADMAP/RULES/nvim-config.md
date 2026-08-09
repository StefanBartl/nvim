# nvim-config (Core)

## Zweck / Struktur

Der Core (alles außer `nvchad`/`wkdnvchad`/`wkdoptions` und den einzelnen
`plugins/personal/*.nvim`-Repos selbst) gliedert sich in klar getrennte
Verantwortlichkeiten:

- `lua/options.lua` — reine `vim.o`/`vim.opt`-Einstellungen, thematisch
  gruppiert (Appearance, Clipboard, Editing, Search, Folding, Performance,
  Files, Diff, Terminals, WSL). Delegiert an `wkdoptions.*` für alles, was
  mehr als eine Zeile Logik braucht (Zeilennummern, Diff-Profile).
- `lua/machine.lua` — Ein einziger globaler Schalter (`NVIM_MACHINE_ROLE`
  Env-Var, `"default"|"workstation"`), der quer durch die Config von
  `plugins/personal/source.lua`, `config/lazy/init.lua` und
  `github_stats.nvim`s Spec gelesen wird, um pro Maschine unterschiedliches
  Verhalten (lokale vs. Remote-Plugins, Update-Checker an/aus) zu steuern,
  ohne dass jede Stelle ihre eigene Erkennung baut.
- `lua/autocmds/` — jede thematische Gruppe (`general`, `git`, `terminals`,
  `text`) folgt demselben Dreier-Muster: `init.lua` (Orchestrierung,
  `enable(cfg)`), `defaults.lua` (ein einziges `AUTOCMDS_X_DEFAULTS`-Objekt),
  `helpers.lua`/Feature-Dateien (die eigentliche Logik). Jedes Feature ist
  einzeln über `cfg.<feature>.enable` toggle-bar und per
  `vim.tbl_deep_extend("force", DEFAULTS, cfg)` gemergt — nie hartkodiert an.
  `lua/autocmds/init.lua` selbst ist die Liste "was ist aktuell aktiv",
  inklusive Kommentaren, warum ein Feature bewusst `enable = false` ist
  (`no_name_guard`, `cursorline`, `last_loc` in `general`).
- `lua/config/` — Setup-Layer für Drittanbieter- und größere Plugins
  (harpoon, neotree, neotest, fzf, menu, telemetry …). Nicht Teil dieses
  Audits im Detail (siehe Task), aber `config/lazy/init.lua` und
  `config/telemetry.lua` sind zentrale Policy-Dateien, die von
  `plugins/personal/*` gelesen werden.
- `lua/plugins/personal/` — bewusste Trennung **Policy vs. Spec-Implementierung**:
  `source.lua` entscheidet *welche Quelle* (lokal/`dir`, `remote`, `disabled`)
  pro Repo, inkl. eines globalen `OVERRIDE`-Schalters und Machine-Role-Gating;
  `init.lua` deklariert nur die eigentlichen `lazy`-Specs und ruft
  `plugins.add({...}); return plugins.export()`. `utils.lua` löst den
  lokalen Repo-Root auf (Env-Var → Kandidatenpfade → Remote-Fallback).
  `list.lua` liest die *tatsächlich geladene* Spec-Tabelle zurück, statt
  eine separate Markdown-Liste zu pflegen, die driften könnte (siehe
  Kommentar `list.lua:7-14` zu genau diesem Problem in der Vorgänger-Version).
- `lua/startup/` — Event-getriebener Phasen-Runner (`startup.now`/`startup.on`)
  mit eingebauter Zeitmessung, ersetzt ein früheres `vim.defer_fn(..., N)`-
  Schema, das nachweislich zu spät lief (siehe `startup/init.lua:1-9`).
- `lua/bindings/` — `mappings/init.lua` ist der einzige Ort, der alle
  Mapping-Module lädt; jedes Modul bekommt einen globalen Helper
  (`vim.g.__map_helper`) injiziert und exportiert `M.setup()`. `usrcmds/`
  registriert Ex-Commands, teils simpel (`vim.api.nvim_create_user_command`),
  teils über `lib.nvim.usercmd.composer` (typisierte Argumente, Routing-Trie,
  Tab-Completion) — letzteres deutlich das robustere Muster (siehe Audit
  unten).

Wiederkehrende Konventionen:
- **Policy/Implementation-Trennung** wie `plugins/personal/source.lua` vs.
  `init.lua` taucht auch in `autocmds/*` (`defaults.lua` = Policy-Werte,
  Feature-Dateien = Implementierung) und in `bindings/usrcmds/case/config.lua`
  vs. `ui.lua` wieder.
- **`pcall`-Guards** um jedes optionale Fremd-Plugin (`gitsigns`, `noice`,
  `trouble`, `which-key`, `nvchad.tabufline`, `copilot-lsp.nes`) statt harter
  `require`.
- **`notify = require("lib.nvim.notify").create("[modulname]")`** als
  Standard-Notify-Pattern in praktisch jeder Datei mit Fehlerausgabe.
- **Lazy-Requires im Callback statt beim `setup()`**, um ein Modul nicht
  vorzeitig zu laden, obwohl seine Spec `lazy`/`cmd`/`ft`-gated ist (explizit
  dokumentiert in `bindings/mappings/harpoon.lua:59-64` und
  `bindings/mappings/noice.lua:12-15`).

## Nicht-standard Patterns / Algorithmen

1. **Workstation-Freeze-Fix (kommentiert, aber dokumentiert)** —
   `lua/options.lua:171-193`: OneDrive spiegelt `Documents\WindowsPowerShell\
   Modules` als Cloud-Platzhalter; jeder PowerShell-Spawn löste eine
   Rehydrierung aus (gemessen: 95s für einen `Get-Module -ListAvailable`-Scan).
   Der Fix (PSModulePath von OneDrive-Pfaden bereinigen) ist aktuell
   auskommentiert, aber die Ursache bleibt als Kommentar dokumentiert — Vorbild
   für "warum deaktiviert" statt stillem Löschen.
2. **Lazy-Update-Checker auf der Workstation deaktiviert** —
   `lua/config/lazy/init.lua:16-30`: Auf `machine.is("workstation")` sind alle
   ~25 personal plugins `remote` (siehe Punkt 4), macht insgesamt ~116 Git-
   Repos. Der Checker feuert bei jedem interaktiven Start `git fetch` auf
   jedes; Firmen-EDR scannt jeden `git.exe`-Spawn → 60-90s UI-Freeze. Fix:
   `checker.enabled = not machine.is("workstation")`.
3. **Source-Resolver-Präzedenz** — `lua/plugins/personal/source.lua:73-95`:
   `resolve()` wendet die Reihenfolge repo-eigenes `"disabled"` > globales
   `OVERRIDE`/`SOURCE` > repo-eigener Modus > Default `"dir"` an — eine
   Deaktivierung gewinnt *immer*, unabhängig vom globalen Schalter.
4. **Mehrstufiger Local-Repo-Root-Fallback** — `lua/plugins/personal/utils.lua:12-43`:
   `$REPOS_DIR` → Kandidatenliste (`E:\repos`, `D:\repos`, `C:\repos`, `/repos`)
   → Remote-Fallback mit Notify, welcher Pfad tatsächlich verwendet wird.
5. **Multi-Strategie-Buflist-Auflösung** —
   `lua/bindings/mappings/buffer_jump.lua:95-117`: `robust_tabpage_buflist()`
   probiert nacheinander `vim.t.bufs` (nvchad tabufline) → `tabpagebuflist()`
   → offene Fenster der aktuellen Tabpage → `getbufinfo({buflisted=1})`, damit
   `<leader>N` auch funktioniert, wenn tabufline (noch) nicht geladen ist.
6. **Cross-Plugin-Koordination mit Doppel-Defer** —
   `lua/autocmds/explorer-singleton.lua`: Hält neo-tree und snacks.picker's
   `explorer`-Source exklusiv (nur eines gleichzeitig offen), merkt sich, wer
   wen verdrängt hat, und öffnet den Verdrängten beim Schließen genau einmal
   wieder. Zwei `vim.schedule`-Defers sind Pflicht, nicht kosmetisch: ein neu
   erzeugtes Fenster (insbesondere ein Floating Picker) kann bei `WinEnter`
   kurzzeitig noch den Buffer des *vorherigen* Fensters melden — durch eigenen
   Smoke-Test verifiziert (`explorer-singleton.smoke.lua`), nicht nur
   angenommen.
7. **Debounced Auto-Center mit Maus-Cooldown** —
   `lua/autocmds/auto-center-fexplorer.lua`: Zentriert den Cursor in
   Explorer-Fenstern (`zz`) nur bei Tastatur-Navigation. Zwei Guards:
   Fokus-Guard (Fenster muss aktiv sein) und ein 200ms-Maus-Cooldown via
   `vim.on_key` + `keytrans()`, damit Mausklicks/-Scroll kein Zentrieren
   auslösen. Pro-Buffer-Timer (`vim.uv.new_timer`) statt globalem Timer.
8. **Wortweises Cycling mit Case-Preservation** —
   `lua/bindings/mappings/ctrl_cycle.lua`: `<C-a>`/`<C-x>` cyclen
   `true/false`, `on/off`, `enabled/disabled` etc. unter dem Cursor (Fallback
   auf natives Inc/Dec bei Zahlen), inklusive Erkennung/Anwendung der
   Groß-/Kleinschreibform (`_case_shape`/`_apply_shape`, Zeilen 123-157).
9. **Trim-on-Paste** — `lua/bindings/mappings/editing.lua`: `p`/`P`/visuelles
   `p` entfernen führende/nachfolgende Leerzeilen und Randwhitespace aus dem
   eingefügten Text (nicht aus dem Register selbst — `nvim_put` statt
   `normal! p`), inklusive manueller Clipboard-Provider-Auflösung
   (`resolve_unnamed`, Zeilen 65-84), weil `getreg()` bei `unnamedplus` sonst
   veralteten internen Registerinhalt statt des echten Systemclipboards liest.
10. **Event-basierter Startup-Runner statt Timer** —
    `lua/startup/init.lua`: `M.now`/`M.on(event, label, fn)` binden Phasen an
    echte Autocmd-Events oder das synthetische `"UIReady"` (VimEnter +
    `vim.schedule`, bewusst *nicht* `User VeryLazy`, weil das im Headless-Mode
    gemessen nie feuerte). Phasen, deren Event nie feuert, bleiben sichtbar
    als `PENDING` in `:StartupReport` statt sich unsichtbar zu verschlucken.
11. **Telemetry-Keying über den vollen Repo-String** —
    `lua/config/telemetry.lua:99-112`: Bewusst `"StefanBartl/dap.nvim"` als
    Key, nicht der normalisierte Kurzname — `lazy.core.util.normname` würde
    `mfussenegger/nvim-dap` und `StefanBartl/dap.nvim` beide auf `"dap"`
    abbilden (verifiziert, nicht nur befürchtet: ein synthetisches `LazyLoad`
    für `"nvim-dap"` erzeugte genau diese Kollision).
12. **Git-Status-gated Deletion** —
    `lua/bindings/usrcmds/plugin_repos/init.lua` (`remove_all`/`reclone_all`):
    Jeder Kandidat wird erst per `git status --porcelain --branch` geprüft;
    alles mit uncommitted/unpushed Änderungen wird gemeldet und *nie*
    gelöscht, unabhängig vom Kommando. Löschung erfolgt erst nach expliziter
    `fn.confirm()`-Bestätigung mit vollständiger Namensliste.
13. **`OVERRIDE` per Text-Patch statt Runtime-Setter** —
    `plugin_repos/init.lua:695-774` (`read_override`/`write_override`):
    `:MyPlugins mode <x>` liest/schreibt direkt die `OVERRIDE`-Zeile in
    `source.lua` per Zeilen-Pattern-Match, weil `require()`-Caching einen
    Runtime-Setter ohnehin wirkungslos machen würde — bewusst dokumentiert,
    dass ein Neustart nötig ist und `:Lazy reload` das NICHT triggert.

## Abgeleitete Guidelines

1. Jedes optional geladene Fremd-Plugin per `pcall(require, ...)` kapseln,
   nie hart `require`n — Config muss auch mit fehlendem/deaktiviertem Plugin
   starten.
2. Policy (welcher Modus, welche Werte) und Implementierung (was passiert
   in diesem Modus) in getrennte Dateien legen, sobald mehr als eine Stelle
   die Policy lesen könnte (`source.lua`/`init.lua`, `defaults.lua`/Feature-
   Datei) — macht spätere `:MyPlugins mode`-artige Text-Patches möglich, ohne
   Implementierungscode anzufassen.
3. Bei Requires innerhalb eines Keymap-Callbacks: das Modul erst *im*
   Callback requiren, nie beim `setup()`, wenn die Ziel-Plugin-Spec lazy ist
   — sonst forced man das Laden allein durch das Definieren des Keymaps.
4. Jede Automatisierung, die auf einen Nachbar-Zustand reagiert (Fokus,
   Maus, ein anderes offenes Fenster), braucht einen Guard gegen die eigene
   Nebenwirkung — siehe Mouse-Cooldown in `auto-center-fexplorer.lua` und den
   Doppel-Defer in `explorer-singleton.lua`. Ohne Guard/Defer feuert der
   Handler auf Zwischenzustände, die der jeweilige Event-Name suggeriert,
   aber nicht garantiert.
5. Destruktive Repo-Operationen (`rm -rf`-artig) immer gegen `git status
   --porcelain` gaten, nie gegen bloße Anwesenheit prüfen — siehe
   `plugin_repos/init.lua`s `check_removable`. Eine Aktion, die *nichts*
   löscht, aber lügt "wäre sicher gewesen", ist schlimmer als eine, die
   einfach verweigert.
6. Wenn ein Wert aus zwei Quellen gespeist wird, die auseinanderlaufen
   können (Markdown-Liste vs. tatsächliche Spec), die abgeleitete Quelle
   bevorzugen — siehe `plugins/personal/list.lua`s explizite Begründung
   gegen die vorherige handgepflegte Markdown-Liste.
7. Neue Ex-Commands mit Argumenten immer über `lib.nvim.usercmd.composer`
   registrieren (typisierte Argtypen mit `validate`/`complete`), nicht über
   rohes `nvim_create_user_command` mit `nargs = "?"` ohne `complete` — siehe
   Audit unten, `:MyReposUpdate` als Negativbeispiel.
8. Maschinen-abhängiges Verhalten immer über `machine.is(role)` gaten, nie
   über Ad-hoc-Erkennung (Hostname, Pfadprüfung) an der Verwendungsstelle —
   ein Ort für Definition/Erweiterung der Rollen (`machine.lua`s `ROLES`-
   Tabelle).
9. Debounce/Timer-State pro Buffer (Tabelle `timers[bufnr]`), nie global,
   wenn das Feature buffer-lokal ist — verhindert, dass ein Buffer-Wechsel
   den Timer eines anderen Buffers kanselt.
10. Kommentare, die eine Deaktivierung begründen (`no_name_guard`,
    `cursorline`, PSModulePath-Fix), im Code stehen lassen statt beim
    Entfernen zu löschen — sie sind die einzige Doku, *warum* etwas trotz
    vorhandenem Code aus ist, und verhindern ein versehentliches
    Wieder-Einschalten ohne den Kontext.
11. Notify-Handles konsequent per `require("lib.nvim.notify").create("[modul]")`
    erzeugen statt `vim.notify` direkt zu rufen (Ausnahme: Bootstrap-Code wie
    `plugins/personal/utils.lua`, der vor `lib.nvim` selbst läuft — dort ist
    plain `vim.notify` korrekt und explizit begründet).
12. Bei mehreren möglichen Quellen für dieselbe Information zur Laufzeit
    (Buflist, Repo-Pfad) eine Kette von Fallback-Strategien implementieren
    statt sich auf die "wahrscheinlichste" zu verlassen — siehe
    `buffer_jump.lua`s vierstufige Kette.

## Keybindings-Audit (lua/bindings/)

### Count-Unterstützung: fehlt, wäre aber sinnvoll

- `lua/bindings/mappings/buf_win_tab.lua:96-99` — `<leader>tn`/`<leader>tp`
  (Tab next/prev) rufen fest `:tabnext`/`:tabprevious` ohne `v:count`
  einzubinden. `3<leader>tn` springt aktuell genau ein Tab weiter statt drei.
  Nativ unterstützt `:tabnext` einen Count-Präfix; die Mappings müssten ihn
  nur durchreichen (`(vim.v.count > 0 and vim.v.count or "") .. "tabnext"`).
- `lua/bindings/mappings/buf_win_tab.lua:61-87` — Fenster-Resize
  (`<S-h>/<S-l>/<S-j>/<S-k>`) nutzt einen festen Schritt von 5 Spalten/Zeilen
  (`"vertical resize -5"` etc.). `3<S-l>` würde aktuell trotzdem nur 5
  verschieben. `v:count1 * 5` als Schrittweite wäre die naheliegende
  Erweiterung.
- `lua/bindings/mappings/trouble.lua:53-56` — `[q`/`]q`/`[l`/`]l` rufen
  `:cprevious`/`:cnext`/`:lprevious`/`:lnext` fest ohne Count, obwohl diese
  Ex-Commands nativ einen numerischen Präfix respektieren. `3]q` springt
  aktuell wie `1]q`.
- `lua/bindings/mappings/trouble.lua:101-102` — `]w`/`[w` (Workspace-
  Diagnostics via `trouble.next`/`trouble.prev`) haben ebenfalls keinen
  Count-Parameter, obwohl `trouble.next({..., count = n})` (falls von der
  API unterstützt) naheläge.
- `lua/bindings/mappings/harpoon.lua:50-57` — `<M-1>`…`<M-9>` sind fest an
  feste Indizes gebunden (kein Count-Fall anwendbar, da Ziffer selbst der
  Index ist) — hier wäre eher eine `<leader>h<N>`-Variante für "add at
  position N" ein sinnvolles neues Feature, kein Count-Fix.
- `lua/bindings/usrcmds/who_locks/init.lua` / `update_repos/init.lua` — kein
  Keymap-Bezug, aber als Ideen-Kandidat: keine Analogie nötig.

### Count bereits sauber gelöst (Vorbild)

- `lua/bindings/mappings/view_scroll.lua:39-59` — `map_default_keys` liest
  `vim.v.count` explizit und reicht ihn an `view_scroll_down/up(count)`
  weiter; `0` fällt sauber auf "halbe Fensterhöhe" zurück. Bestes Vorbild im
  Repo für Count-Handling — aber **aktuell nicht aktiv**: der Aufruf in
  `bindings/mappings/init.lua:32` ist auskommentiert
  (`-- require("bindings.mappings.view_scroll").map_default_keys(...)`),
  d.h. das Modul ist totes/inaktives Vorbild, nicht produktiv.
- `lua/bindings/mappings/archive.lua:11-37` — `j`/`k`/`<Down>`/`<Up>` als
  `expr`-Mappings mit `v:count == 0 ? 'gjzz' : 'jzz'`: ohne Count screen-line-
  aware (`gj`), mit Count physische Zeile (`j`) — sauberes Muster für "Count
  ändert die Bewegungsart, nicht nur die Wiederholung". Aber: `archive.lua`
  wird von **keinem** `require` aus `bindings/mappings/init.lua` eingebunden
  (`map = {}` ist ein Dummy-Objekt für den LSP, keine echte Ausführung) —
  totes Archiv-Muster, kein aktiver Code. Guter Kandidat, um es entweder zu
  reaktivieren oder den Ordner klar als `archive/` statt `mappings/`
  zu kennzeichnen.

### Ex-Commands (usrcmds/): Completion-Audit

- `lua/bindings/usrcmds/plugin_repos/init.lua` — vorbildlich: eigene
  Argtypen `MYPLUGINS_DIR` (Zeilen 788-804, inkl. `$REPOS_DIR`-Vorschlag) und
  `MYPLUGINS_NAME` (Zeilen 811-831, live gegen `plugins.personal.list`
  validiert und komplettiert) über `composer.register_type`.
- `lua/bindings/usrcmds/case/init.lua` — vorbildlich: `CASE`-Argtyp
  (Zeilen 19-31) normalisiert eine eingefügte volle SNOW-ID auf die Kurznummer
  und komplettiert gegen die Registry; `BLOCK`-Argtyp (Zeilen 38-51) mit
  bewusst permissiver Validierung, weil die Bibliothek auf manchen Maschinen
  fehlen kann.
- `lua/bindings/usrcmds/who_locks/init.lua:103-107` — hat `complete = "file"`
  für den optionalen Pfad — gut, aber knapp: bei einem Verzeichnis statt Datei
  im Argument gäbe `"file"` trotzdem brauchbare Vorschläge, kein Problem.
- **Fehlt:** `lua/bindings/usrcmds/update_repos/init.lua:156-164` —
  `:MyReposUpdate [path]` ist mit `nargs = "?"` registriert, aber **ohne
  `complete`**. Im Gegensatz zu `:MyPlugins clone/remove/... [dir]`, das für
  denselben Zweck (`$REPOS_DIR`-Vorschlag + Verzeichnis-Completion) den
  `MYPLUGINS_DIR`-Argtyp nutzt, muss der Pfad hier blind getippt werden.
  Naheliegender Fix: dieselbe Completion-Logik wie `plugin_repos/init.lua:794-804`
  (oder direkt den `MYPLUGINS_DIR`-Typ) hierher übernehmen.
- `lua/bindings/usrcmds/init.lua` — `CwdHere`, `PowershellProfile`,
  `BindingsPath` haben keine Argumente, Completion ist folgerichtig nicht
  nötig.

### Ideen für neue Flags/Optionen

- `:MyPlugins clone/reclone --dry-run` — zeigt, was geklont/gelöscht würde,
  ohne es zu tun (das Grundgerüst für die Vorschau existiert bereits in
  `finish_check`/`finish_reclone`, nur ohne isolierten Dry-Run-Pfad).
- `:MyReposUpdate --only=<name>` — analog zu `:MyPlugins fetch/pull/update
  --only=<name>`, aktuell nicht vorhanden (immer alle Repos im Verzeichnis).
- `:WhoLocks --json` — für eine spätere pickers.nvim-Integration (aktuell
  reines Text-Notify + `print`).
- `:Trouble`-Mappings (`[w`/`]w`) um ein `<leader>x`-Präfix-Pendant mit
  explizitem `count`-Argument ergänzen, sobald Trouble's API das unterstützt.

## Ideen für neue Plugins

- **Explorer-Singleton als eigenständiges Plugin.** Das in
  `autocmds/explorer-singleton.lua` gelöste Problem (zwei konkurrierende
  Datei-Browser-UIs sollen sich gegenseitig verdrängen/wiederherstellen) ist
  generisch genug (jede "zwei Picker/Trees gleichzeitig offen"-Situation),
  um als kleines, testbares Plugin mit eigenem Smoke-Test-Harness zu leben,
  statt als Config-lokale Autocmd-Datei.
- **Word/Number-Cycler als eigenständiges Plugin.** `ctrl_cycle.lua` (Case-
  aware Cycling von Wortpaaren wie `true/false`, `on/off`) ist bereits
  komplett eigenständig (keine Config-Abhängigkeiten außer `vim.g.__map_helper`)
  und ein natürlicher Kandidat für ein `cycler.nvim`, konfigurierbar mit
  eigenen Wortpaaren statt der hartkodierten `DEFAULTS.cycles`-Tabelle.
- **EmmyLua-aware Comment-Toggler.** `toggle_comment.lua` behandelt
  `---@`-Annotationen separat von normalen Kommentaren (auskommentierte
  Annotation wird zu `-- ---@...` statt einfach `-- ---@...` wie ein
  generischer Commenter es täte) — spezifisch genug für Lua-Config-Autoren,
  um als eigenes kleines Plugin nützlich zu sein.
- **Robuste Buffer-Jump-Logik generalisieren.** `buffer_jump.lua`s
  Mehrstufen-Fallback (`vim.t.bufs` → `tabpagebuflist` → Fenster → `getbufinfo`)
  ist tabufline-spezifisch motiviert, aber die Fallback-Kette selbst wäre als
  generischer robuster "welche Buffer sind in dieser Session sichtbar"-Helper
  in `lib.nvim` wiederverwendbar (aktuell an dieser einen Stelle dupliziert).
- **Auto-Center-Explorer als Feature von filetree.nvim.** Bereits im Code
  als Migrationsabsicht markiert (`autocmds/init.lua:9-10`: "AUDIT: not
  exercised against a live neo-tree + snacks session yet" und das
  `no_name_guard`-Beispiel, das exakt diesen Weg schon gegangen ist — siehe
  `autocmds/init.lua:28`: "Re-implemented tree-aware in filetree.nvim"). Die
  Debounce+Mouse-Cooldown-Logik in `auto-center-fexplorer.lua` sollte
  denselben Weg nehmen, statt als generische, tree-unabhängige Autocmd-Datei
  im Core-Config zu bleiben.
- **Startup-Phase-Runner als eigenständiges, minimales Plugin.**
  `lua/startup/` hat keine Abhängigkeit auf etwas Config-Spezifisches außer
  `lib.nvim.notify`/`lib.nvim.ui.kit` (beide bereits eigenständige Plugins)
  und wäre als generischer "Measure and report your own config's startup
  phases"-Baustein für andere Neovim-Configs direkt wiederverwendbar.
