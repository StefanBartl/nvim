# lsp.nvim — Autocmds Cheatsheet

Sources: `lua/lsp/bindings/autocmds.lua`, `formatter/init.lua`,
`servers/lua_ls/reload.lua`, `languages/**`, `tools/**`

Erstellt 2026-08-25 im Zuge des Plugin-Sweeps. lsp.nvim war das einzige
Personal-Plugin ohne Autocmds-Seite in diesem Baum.

**Achtung — der eigene Docstring untertreibt.** `bindings/autocmds.lua` sagt
"One group, `lsp_nvim`". Das gilt nur fuer *Keymap*-Autocmds. Tatsaechlich
registriert das Plugin **25 Autocmds ueber 20 Augroups**, verteilt ueber
`languages/`, `tools/`, `formatter/` und `servers/`. Diese Datei ist die
vollstaendige Liste.

(20 = 18 benannte Literale + `lsp_nvim` aus der `M.GROUP`-Konstante +
`LspSignaturePopup_<winid>`, dessen Name zur Laufzeit gebaut wird. `grep` auf
Stringliterale findet die letzten zwei nicht.)

Alle 25 laufen ueber `lib.nvim.bindings.autocmd.create` — kein einziger auf der Roh-API.
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

- **Gemischte Augroup-Registrierung.** `Autocmd.group(name, true)` (lib) in
  csharp, lua, c, go, zig, astro (beide Dateien), markdown_words, lua_ls —
  Roh-API `vim.api.nvim_create_augroup` in dart, java, markdown, typescript,
  eslint_prettier, lsp_signature, noice_integration. Funktional identisch,
  rein kosmetisch. Kein Bug, nur uneinheitlich — **aber** genau in dieser
  Grauzone sind die zwei gruppenlosen Autocmds oben so lange unbemerkt
  geblieben.
- **`bindings/autocmds.lua`s Docstring** behauptet "One group, `lsp_nvim`" und
  nennt nur formatter + "diagnostics refresh in `core/`" als Ausnahmen. Der
  Diagnostics-Refresh existiert dort gar nicht (`core/root_scope.lua` feuert
  nur ein `nvim_exec_autocmds`, registriert keines), und die zwoelf
  `languages/`- und `tools/`-Gruppen fehlen komplett. Diese Seite ist
  massgeblich.
