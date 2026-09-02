# lsp.nvim — Autocmds Cheatsheet

Sources: `lua/lsp/bindings/autocmds.lua`, `core/inlay_hints.lua`,
`core/lightbulb.lua`, `core/supervisor.lua`, `formatter/init.lua`,
`integrations/lspsaga.lua`, `servers/lua_ls/reload.lua`, `languages/**`,
`tools/**`

Erstellt 2026-08-25 im Zuge des Plugin-Sweeps. lsp.nvim war das einzige
Personal-Plugin ohne Autocmds-Seite in diesem Baum.

**Achtung — der eigene Docstring untertreibt.** `bindings/autocmds.lua` sagt
"One group, `lsp_nvim`". Das gilt nur fuer *Keymap*-Autocmds. Tatsaechlich
registriert das Plugin **33 Autocmds ueber 25 Augroups**, verteilt ueber
`languages/`, `tools/`, `formatter/`, `servers/`, `integrations/` und
`core/`. Diese Datei ist die vollstaendige Liste.

(25 = 20 benannte Literale + `lsp_nvim`, `lsp_nvim_inlay_hints`,
`lsp_nvim_lightbulb` und `lsp_nvim_supervisor` aus `M.GROUP`-Konstanten +
`LspSignaturePopup_<winid>`, dessen Name zur Laufzeit gebaut wird. `grep` auf
Stringliterale findet die letzten fuenf nicht.)

Gezaehlt werden Aufrufstellen, nicht Event-Registrierungen: der
Lightbulb-Aufruf horcht auf vier Events, `nvim_get_autocmds` zaehlt ihn also
vierfach. Die 33 sind, wie oft `autocmd.create` aufgerufen wird — nachgezaehlt
am Quelltext, nicht fortgeschrieben.

Alle 33 laufen ueber `lib.nvim.bindings.autocmd.create` — kein einziger auf der
Roh-API. Der Inlay-Hints-Autocmd von 2026-08-29 war beim ersten Wurf die
Ausnahme; nachgezogen, bevor er committet wurde, genau wegen dieser Zeile.
Der Breadcrumb-Waechter von 2026-09-02 war die zweite — und die erste, die es
tatsaechlich in einen Commit geschafft hat (`b260fc8`, korrigiert in
`89f68fc`). Der Satz hier hat den Fehler gefunden, nicht umgekehrt: das ist
der Zweck, den er hat.
Die *Augroups* sind gemischt: teils `Autocmd.group(name, true)`, teils
`vim.api.nvim_create_augroup`. Funktional identisch, siehe "Offene Punkte".

## Kern — `bindings/autocmds.lua`

| Augroup (clear=true) | Event | Pattern | Bedingung | Aktion |
| --- | --- | --- | --- | --- |
| `lsp_nvim` | `LspAttach` | — | `cfg.keymaps.enable` | Re-bindet die Katalogeintraege `rename` und `goto_type_definition_gr` buffer-lokal |

**Warum das existiert:** Neovim setzt die `gr*`-Familie (`grn`, `grr`, `gri`,
`grt`, `gO`) beim Server-Attach **buffer-lokal**, und buffer-lokal schlaegt
global. Ein Katalogeintrag auf so einem lhs waere genau in den Buffern still
verschattet, fuer die er gedacht ist. `LspAttach` ist die einzige Stelle, die
danach laeuft. `M.setup()` gibt die Anzahl registrierter Autocmds zurueck (1).

## Inlay Hints — `core/inlay_hints.lua`

| Augroup (clear=true) | Event | Pattern | Bedingung | Aktion |
| --- | --- | --- | --- | --- |
| `lsp_nvim_inlay_hints` | `LspAttach` | — | `vim.lsp.inlay_hint` vorhanden | Setzt den aufgeloesten Hint-Zustand (global + Filetype-Override) auf den frisch attachten Buffer |

**Warum eine eigene Augroup und nicht `lsp_nvim`:** die wird geleert, sobald
`keymaps.enable = false` gesetzt ist (`bindings/autocmds.lua` ruft `M.clear()`
und registriert dann nichts). Inlay Hints sind keine Keymap-Sache und duerfen
nicht mit den Keymaps verschwinden.

Der Callback ist `vim.schedule`d: `server_capabilities` steht zum
`LspAttach`-Zeitpunkt, das *Filetype* des Buffers beim allerersten Attach einer
Sitzung nicht zuverlaessig — und das Filetype ist es, was den Override
aufloest. `M.detach()` raeumt die Gruppe wieder ab.

## Code-Action-Indikator — `core/lightbulb.lua`

| Augroup (clear=true) | Event | Pattern | Bedingung | Aktion |
| --- | --- | --- | --- | --- |
| `lsp_nvim_lightbulb` | `CursorMoved`, `BufEnter`, `InsertLeave`, `DiagnosticChanged` | — | — | Fragt `textDocument/codeAction` fuer die Cursorposition, debounced (`lightbulb.debounce_ms`, Default 150ms), und markiert die Zeile bei einem Treffer |
| `lsp_nvim_lightbulb` | `InsertEnter` | — | — | Loescht die Markierung, **ohne** Debounce |
| `lsp_nvim_lightbulb` | `LspAttach` | — | — | Fragt einmal nach, sobald ein Client da ist |

Drei `autocmd.create`-Aufrufe, sechs Event-Registrierungen — dieselbe Augroup.

**`DiagnosticChanged` ist kein Beiwerk:** die `quickfix`-Actions, um die der
Default-Allowlist herumgebaut ist, haengen an Diagnostics. Kommt die Diagnostic
eine Sekunde nach dem Cursorstopp an, bewegt sich die Position nie wieder und
nichts sonst wuerde nachfragen.

**`InsertEnter` bewusst ohne Debounce:** Verstecken ist nie das, was
Rate-Limiting braucht, und eine Lampe, die den Moduswechsel um 150ms
ueberlebt, ist genau das Flackern, gegen das der Debounce existiert.

Eigene Augroup aus demselben Grund wie bei den Inlay Hints. `M.detach()`
raeumt sie ab und macht einen von `setup()` eingeplanten Refresh unwirksam —
sonst zeichnet ein Callback, der den Zustand ueberlebt hat, eine Markierung,
die danach niemand mehr wegnimmt.

## Auto-Restart — `core/supervisor.lua`

| Augroup (clear=true) | Event | Pattern | Bedingung | Aktion |
| --- | --- | --- | --- | --- |
| `lsp_nvim_supervisor` | `LspAttach` | — | — | Merkt sich pro Client-ID Servername, Buffer und Startzeit |
| `lsp_nvim_supervisor` | `VimLeavePre` | — | — | Setzt das Flag, das Client-Exits waehrend `:qa` nicht mehr als Absturz zaehlt |

**Warum ueberhaupt Buchfuehrung beim Attach:** der eigentliche Trigger ist kein
Autocmd, sondern `on_exit` aus der `vim.lsp.config("*")`-Konfiguration. Der
bekommt `code`, `signal` und eine Client-ID — sonst nichts, und zu einem
Zeitpunkt, an dem der Client schon im Abbau ist. Ohne diese zwei Zeilen weiss
der Handler nicht, *welcher Server* gestorben ist und in *welchen Buffer* er
zurueckgehoert.

`on_exit` laeuft ausserdem im Fast-Event (auf 0.12.2 nachgemessen:
`vim.in_fast_event()` ist darin `true`), also wird dort nur eingesammelt und
per `vim.schedule` auf dem Mainloop entschieden.

## Formatter

| Augroup (clear=true) | Event | Bedingung | Aktion |
| --- | --- | --- | --- |
| `LspFormatOnSave` | `BufWritePre` | `STATE.enabled` **und** `buftype == ""` | Synchrones Format-on-save mit View-Erhalt |

Der Toggle (`:LspFormatToggle`/`On`/`Off`, `<leader>tft`) *loescht und
registriert neu*, statt ein Flag zu pruefen — `create_autocmd_if_enabled()`
ruft erst `nvim_clear_autocmds` auf die Gruppe. Deshalb ist im Ausschaltzustand
gar kein Autocmd vorhanden, nicht nur einer, der nichts tut.
Synchron und nicht async, damit der View-Restore innerhalb der Write-Kette
deterministisch bleibt.

## Sprachen

| Augroup (clear=true) | Event | Pattern | Aktion |
| --- | --- | --- | --- |
| `LangCs` | `FileType` | `cs` | **No-op-Stub** |
| `LangLua` | `FileType` | `lua` | **No-op-Stub** |
| `LangC` | `FileType` | `c`, `cpp` | **No-op-Stub** |
| `LangGo` | `FileType` | `go` | **No-op-Stub** |
| `LangZig` | `FileType` | `zig` | **No-op-Stub** |
| `LangDart` | `FileType` | `dart` | Buffer-lokales `Flutter: Hot Reload`-Keymap |
| `LangJava` | `FileType` | `java` | Setzt Buffer-Optionen; registriert **verschachtelt** ein `BufWritePre` |
| `LangHtml` | `FileType` | `html`, `htmldjango`, `djangohtml` | HTML-Buffer-Optionen |
| `LangTs` | `BufWritePre` | `*.ts`, `*.tsx`, `*.js`, `*.jsx` | TypeScript-Aktion beim Speichern |
| `LangMarkdownQoL` | `FileType` | `markdown`, `mdx` | UTF-8, Soft-Defaults, buffer-lokales Format-Keymap |

**Die fuenf No-op-Stubs sind Absicht, nicht Versehen.** `go.lua` sagt es
selbst: "registers the `go` FileType group but the callback is a no-op — the
same stub shape as c.lua/zig.lua next to it". Platzhalter fuer kuenftige
QoL-Erweiterungen. Wer hier Verhalten sucht, findet keines — deshalb steht es
hier. Sie sind die einzigen Autocmds des Plugins **ohne `desc`**.

`LangJava` ist der einzige Fall mit einem Autocmd *innerhalb* eines Autocmds:
das `FileType` registriert beim Feuern ein `BufWritePre`.

## Markdown-Wortvervollstaendigung (`markdown_words`)

| Augroup (clear=true) | Event | Pattern | Aktion |
| --- | --- | --- | --- |
| `MdWordsCompletionSource` | `FileType` | `markdown`, `mdx` | Registriert die Completion-Quelle beim ersten Markdown-Buffer |
| `MdWordsInitialScan` | `FileType` | `markdown`, `mdx` | Initialer Wort-Cache-Build beim ersten Markdown-Oeffnen |
| `MdWordsDirChanged` | `DirChanged` | — | Debounced Rebuild bei cwd-Wechsel |

Die ersten beiden sind bewusst getrennte Augroups statt zweier Handler in
einem: sie feuern beide auf demselben Event/Pattern, haben aber verschiedene
Lebensdauern (`once`-Semantik beim Scan).

## Astro

| Augroup (clear=true) | Event | Pattern | Aktion |
| --- | --- | --- | --- |
| `AstroQoL` | `BufWritePre` | `*.astro` | Format on save |
| `AstroQoL` | `BufWritePre` | `*.astro` | Organize imports on save |
| `AstroQoL` | `FileType` | `astro` | Astro-Buffer-Optionen |
| `AstroQoL` | `FileType` | `astro` | Eigenes Astro-Syntax-Highlighting |

Vier Handler in **einem** Augroup — das saubere Gegenbeispiel zu den
Einzel-Gruppen oben.

| Augroup (clear=true) | Event | Pattern | Aktion |
| --- | --- | --- | --- |
| `LangAstro` | `FileType` | `astro` | Astro-Keymaps, Autotag-Fallback, `commentstring` + 2-Space-Indent |

## Tools und Server

| Augroup (clear=true) | Event | Bedingung | Aktion |
| --- | --- | --- | --- |
| `MasonEslintPrettier` | `BufWritePre` | `ctx._enabled` **und** ft ∈ js/jsx/ts/tsx/vue/svelte | ESLint/Prettier beim Speichern |
| `ToolsNoiceIntegration` | `BufWinEnter` | Buffer ist ein Noice-Preview | Installiert Type-Lookup-Keymaps im Preview |
| `LspSignaturePopup_<winid>` (pro Fenster) | `BufWipeout`, `BufHidden`, `BufLeave`, `WinClosed` | `once = true`, buffer-lokal | Schliesst das Signature-Popup und **loescht die eigene Augroup** |
| `LspLuaLsRootScope` | `User LspRootScopeChanged` | — | Rechnet `root_dir` offener Buffer neu |

`LspSignaturePopup_<winid>` ist das einzige Muster mit einer Augroup **pro
Fenster**, die sich per `nvim_del_augroup_by_id` selbst abraeumt — noetig, weil
sonst pro geoeffnetem Popup eine Gruppe zurueckbliebe.

`ToolsNoiceIntegration` wird auf **Modulebene** registriert (nicht in einer
`setup()`-Funktion), feuert also schon beim `require`.

## Breadcrumb-Tiefe — `integrations/lspsaga.lua`

| Augroup (clear=true) | Event | Pattern | Bedingung | Aktion |
| --- | --- | --- | --- | --- |
| `LspNvimSagaWinbarDepth` | `CursorMoved` | — | Filetype hat eine Tiefengrenze | Schneidet den von lspsaga geschriebenen Winbar auf Pfad + N Symbole |
| `LspNvimSagaWinbarDepth` | `User` | `SagaSymbolUpdate` | dieselbe | dasselbe, nach einer frischen Symbolantwort |

Zwei Aufrufstellen, zwei Events, eine Augroup. Registriert aus
`M.configure()`, das der Pack-Spec beim Laden von lspsaga aufruft (`event =
"LspAttach"`) — ohne installiertes lspsaga existiert die Gruppe nicht.

**Warum ueberhaupt ein Autocmd und keine Option:** lspsaga kennt keine
Tiefenbegrenzung. `find_in_node` steigt in jedes Kind ab, das die Cursorzeile
enthaelt, und marksman liefert Markdown-Ueberschriften als verschachtelte
Gliederung — der Cursor sitzt also in drei Symbolen gleichzeitig, und der
Winbar liest `Ordner > Datei > H1 > H2 > H3`. `ignore_patterns`, der einzige
verwandte Schalter, matcht auf den Buffernamen und wuerde Ordner und
Dateinamen mitnehmen. Also wird nachgeschnitten, was lspsaga schon
geschrieben hat.

**Warum `vim.schedule` und nicht Autocmd-Reihenfolge:** lspsaga legt seinen
eigenen `CursorMoved`-Handler pro Buffer zum `LspAttach`-Zeitpunkt an. Ein
hier zur `config`-Zeit registrierter Autocmd kann sich nicht darauf verlassen,
danach zu laufen. Das Verschieben auf den Event-Loop ist
reihenfolgeunabhaengig.

**Kosten auf dem heissen Pfad:** der Callback steigt nach einem
Tabellenzugriff wieder aus, wenn der Filetype keine Grenze hat — also bei
allen ausser `markdown`. Der Schnitt selbst laeuft erst im `vim.schedule`.

## Behoben 2026-08-25 — zwei stapelnde Autocmds

Beide **hatten gar keine Augroup**, beide aus demselben Grund: ihre
`setup()`/`enable()` hat keinen Idempotenz-Guard und laeuft bei jedem
Config-Reload erneut. Die Usercmds daneben ueberleben das, weil
`usercmd.create` auf `force = true` steht — ein gruppenloser Autocmd hat kein
solches Ueberschreiben und **stapelt**. Beide Male vorher/nachher gemessen,
nicht nur gelesen.

| Betroffen | Vorher | Nachher | Folge des Bugs |
| --- | --- | --- | --- |
| `servers/lua_ls/reload.lua` → jetzt `LspLuaLsRootScope` | 1 → 2 → 3 | konstant 1 | N × `recompute_root()` pro Scope-Wechsel |
| `languages/webdev/astro/init.lua` → jetzt `LangAstro` | 1 → 2 → 3 | konstant 1 | N × Keymap-Attach + Buffer-Optionen pro Astro-Buffer |

Der Astro-Fall zeigt die Entstehung im Quelltext: die Zeile
`-- local grp = api.nvim_create_augroup("LangAstro", ...)` war
**auskommentiert**, der zugehoerige Autocmd blieb aber stehen und verlor damit
still seine Gruppe. Deshalb tauchte `LangAstro` in der Namensliste auf, ohne
dass es die Gruppe zur Laufzeit je gab.

## Offene Punkte

- **Gemischte Augroup-Registrierung.** Nachgezaehlt 2026-09-02, in beide
  Richtungen unvollstaendig gewesen. `Autocmd.group(name, true)` (lib) in
  `bindings/autocmds.lua`, `core/inlay_hints`, `core/lightbulb`,
  `core/supervisor`, `integrations/lspsaga`, csharp, lua, c, go, zig, html,
  astro (beide Dateien), markdown_words (drei), lua_ls — Roh-API
  `vim.api.nvim_create_augroup` in `formatter/init.lua`, dart, java, markdown,
  typescript, eslint_prettier, lsp_signature, noice_integration. Funktional
  identisch, rein kosmetisch. Kein Bug, nur uneinheitlich — **aber** genau in
  dieser Grauzone sind die zwei gruppenlosen Autocmds oben so lange unbemerkt
  geblieben.
- **`bindings/autocmds.lua`s Docstring** behauptet "One group, `lsp_nvim`" und
  nennt nur formatter + "diagnostics refresh in `core/`" als Ausnahmen. Der
  Diagnostics-Refresh existiert dort gar nicht (`core/root_scope.lua` feuert
  nur ein `nvim_exec_autocmds`, registriert keines), und die zwoelf
  `languages/`- und `tools/`-Gruppen fehlen komplett. Diese Seite ist
  massgeblich.

## Changelog

- 2026-09-02: `LspNvimSagaWinbarDepth` aufgenommen (zwei Aufrufstellen, zwei
  Events). Jetzt 33 ueber 25. Die beiden Autocmds liefen bei ihrem ersten
  Commit (`b260fc8`) auf der Roh-API und haben damit die Zeile oben falsch
  gemacht; korrigiert in lsp.nvim `89f68fc`, bevor diese Seite nachgezogen
  wurde. Bei der Gelegenheit die Aufrufstellen neu gezaehlt statt
  fortgeschrieben (33 `autocmd.create`, 20 Augroup-Literale) und die
  lib/Roh-API-Aufteilung unter "Offene Punkte" korrigiert — `html` fehlte auf
  der lib-Seite, `formatter/init.lua` auf der Roh-Seite.
- 2026-08-30 (2): `lsp_nvim_supervisor` aus Roadmap-M3 aufgenommen (zwei
  Aufrufstellen, zwei Events). Jetzt 31 ueber 24.
- 2026-08-30: `lsp_nvim_lightbulb` aus Roadmap-M2 aufgenommen (drei
  Aufrufstellen, sechs Events). Bei der Gelegenheit die Kopfzahl korrigiert:
  sie stand auf "26 Autocmds ueber 21 Augroups", waehrend die eigene
  Aufschluesselung daneben 22 ergab (19 Literale + 2 `M.GROUP` + 1
  Laufzeitname). Jetzt 29 ueber 23, und dass Aufrufstellen gezaehlt werden und
  nicht Event-Registrierungen, steht jetzt dabei.
