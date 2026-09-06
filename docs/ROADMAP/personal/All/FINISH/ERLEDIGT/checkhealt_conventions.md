# Checkhealth-Konventionen

Analyse vom 2026-08-31: Woher die `:checkhealth`-Schreibweise kommt, welches Level
wann richtig ist, und was der Scan über alle 30 Plugins ergeben hat.
Report als Artifact: https://claude.ai/code/artifact/4b9e86e3-b542-4ac7-88b4-dec1fac62d62

---

## Table of content

  - [Woher die Schreibweise kommt](#woher-die-schreibweise-kommt)
  - [Warum WARNING für "not installed" nicht kosmetisch ist](#warum-warning-fr-not-installed-nicht-kosmetisch-ist)
  - [Die Regel](#die-regel)
  - [Eigenes Icon für "not installed"](#eigenes-icon-fr-not-installed)
  - [Scan über alle Repos](#scan-ber-alle-repos)
  - [Umsetzung](#umsetzung)

---

## Woher die Schreibweise kommt

Es gibt **keine Spezifikation und kein RFC**. Die Strings sind hartcodiert in
`$VIMRUNTIME/lua/vim/health.lua`, Funktion `format_report_message()`.
Doku: `:h health-dev`, `:h vim.health`.

| API | Gerenderte Zeile | zählt in die Summary |
| --- | --- | --- |
| `start(name)` | `\n<name> ~` | nein — Sektionsüberschrift |
| `info(msg)` | `- <msg>` | nein — **kein Icon, kein Tag** |
| `ok(msg)` | `- ✅ OK <msg>` | nein |
| `warn(msg, advice?)` | `- ⚠️ WARNING <msg>` | **ja** |
| `error(msg, advice?)` | `- ❌ ERROR <msg>` | **ja** |

Die Icons sind nicht konfigurierbar: `g:health` kennt genau einen Schlüssel,
`style = 'float'`. Die einzige dokumentierte Abschaltung ist ein FileType-Autocmd,
der Nicht-ASCII wegsubstituiert (steht als Kommentar in `health.lua`).

**Es gibt kein INFO-Level.** `info()` gibt bewusst gar keinen Tag aus — Info-Zeilen
sind im Core-Design untergeordneter Kontext, keine Statuszeilen. Passend dazu kennt
`$VIMRUNTIME/syntax/checkhealth.vim` exakt drei Keywords: `ERROR`, `WARNING`, `OK`
→ `DiagnosticError`, `DiagnosticWarn`, `DiagnosticOk`. `INFO` fehlt, weil Core es
nie schreibt.

---

## Warum WARNING für "not installed" nicht kosmetisch ist

`warn()`/`error()` erhöhen `check_summary`; daraus baut `get_summary()` die
rechtsbündige Kopfzeile jeder Sektion:

```
==============================================================================
filetree.nvim:                                                            4 ⚠️
```

Statt `✅`. Wer `:checkhealth` ohne Argument aufruft, überfliegt genau diese
Kopfzeilen. Vier nicht installierte Adapter kippen das Häkchen, obwohl nichts
kaputt ist — das verbrennt das Signal für die eine Zeile, die wirklich zählt.

Neovim selbst macht das nie:

- `lua/vim/provider/health.lua:109` → `info('Disabled (…)')` — deaktivierter Provider = INFO
- `lua/vim/pack/health.lua:40` → ``ok('`vim.pack` is not used')`` — nicht benutzt = OK

---

## Die Regel

**Ein-Satz-Test: Muss der Nutzer etwas tun? Nein → niemals `warn`.**

| Situation | Level |
| --- | --- |
| Pflicht-Abhängigkeit fehlt, Plugin lädt/arbeitet nicht | `error` |
| Nutzer hat es eingeschaltet/konfiguriert, aber es fehlt oder ist kaputt | `warn` + ADVICE |
| Ein Feature fällt aus, der Rest läuft weiter | `warn` + ADVICE |
| Eine von N Alternativen fehlt, mindestens eine ist da | `info` |
| Rein optional; ohne es ist es nur anders, nicht schlechter | `info` |
| Umgebungsfakten: Version, Pfad, Anzahl, aktive Config | `info` |
| Vorhanden und funktioniert | `ok` |

Zweiter Test: "Wenn diese Zeile die Kopfzeile von ✅ auf ⚠️ kippt — verdient sie das?"

---

## Eigenes Icon für "not installed"

Geht nur als selbstgeschriebenes Präfix, eine API dafür gibt es nicht. Headless
verifiziert; zählt nicht in die Summary:

```
- ✅ OK   netrw (netrw (builtin)) — available
- ℹ️ INFO oil (oil.nvim) — not installed
```

Helfer, drei Zeilen, kein `lib.nvim` nötig — bei 30 Repos ist eine kopierte Zeile
billiger als eine Kopplung:

```lua
-- oben in health.lua, neben den anderen Aliases
local function note(msg) health.info("ℹ️ INFO " .. msg) end
```

Farbe dazu **einmal in der eigenen Config**, nicht in 30 Plugins — ein `after/syntax`
aus einem Plugin heraus verändert jeden fremden checkhealth-Buffer mit:

```vim
" ~/.config/nvim/after/syntax/checkhealth.vim
syn keyword DiagnosticInfo INFO
```

Verifiziert: `synID()` liefert danach `DiagnosticInfo` am Token. Der checkhealth-Buffer
nutzt klassisches Syntax-Highlighting, kein Treesitter (`ts_active=false`) — der
Nachtrag greift zuverlässig. `DiagnosticInfo` ist eine Standardgruppe, jedes
Colorscheme setzt sie.

Den Tag **nur in Statuslisten** (Adapter, Backends, Engines) — dort trägt die Spalte
Information. Bei reinen Fakten (Version, Pfad, Config) bleibt nacktes `info()` richtig.

---

## Scan über alle Repos

35 `health.lua`-Module, rund 260 `warn`/`error`-Aufrufe, davon **40 mit ADVICE-Block
(15 %)**. Der von Core vorgesehene Ort für "so behebst du das" liegt fast brach.

Vier systematische Fehlklassen:

**A — Eine von N Alternativen als Warnung.** Der echte Ausfall ist schon durch das
`error` im "keine davon"-Fall abgedeckt; die Einzelzeilen sind reine Bestandsaufnahme.

- `filetree.nvim` — `lua/filetree/health.lua:70`
- `pickers.nvim` — `lua/pickers/health.lua:39, 45, 51` (telescope / fzf-lua / snacks)

**B — Der Text sagt "(optional)", das Level sagt WARNING.** Die Zeile widerspricht
sich selbst. Beide Fundstellen sitzen in *geteilten Helfern* → systemisch, nicht punktuell.

- `lib.nvim` — `lua/lib/nvim/deps/health.lua:58` `h_warn(label .. " NOT found (optional)")`
- `pdfport.nvim` — `lua/pdfport/health.lua:30, 131, 221`
- `neotree-fs-refactor.nvim` — `:30` "(recommended)", `:55` "disabled in configuration"

`lib/nvim/deps/health.lua` ist laut eigenem Modulkommentar der Ersatz für das
handgerollte `check_exe`-Muster in pdfport / images / mdview / migrate — **eine Zeile
dort korrigiert mehrere Plugins gleichzeitig.** Konsumenten heute: dap, debugging,
documentation, filetree.

**C — Warnungen, die eigentlich Fehler sind** (Gegenrichtung, deshalb leicht zu
übersehen): der Meldungstext sagt bereits "will fail", das Level sagt nur `warn`.

- `cascade.nvim` — `lua/cascade/health.lua:39` "lib.nvim not found — :Cascade will fail to load"; der Kommentar zwei Zeilen darüber sagt *required*
- `fileops.nvim` — `lua/fileops/health.lua:39` "libuv not found; file I/O will fail"
- `buffer-ctx.nvim:20`, `sessions.nvim:32` — gleiches libuv-Muster

**D — "call setup() first" unter Lazy-Loading.** `:checkhealth` lädt das Plugin nicht.
Bei `event`/`cmd`-Lazy-Loading ist "command not registered" der *Normalzustand* — ein
garantiertes False Positive für jeden, der lazy lädt.

- `sessions.nvim:147, 152, 157` · `open.nvim:158, 185`
- `buffer-ctx.nvim:90, 96, 121, 165`
- `filetree.nvim:88` macht es bereits richtig: `info("No adapter resolved yet (call setup() first)")` — Vorlage

---

## Umsetzung

Nach Hebelwirkung sortiert, nicht nach Repo-Reihenfolge.

- [ ] `lib.nvim` `lua/lib/nvim/deps/health.lua:58` — "(optional)" auf `info`. Wirkt sofort in allen Konsumenten.
- [ ] `pdfport.nvim:30` — eigene Kopie desselben Helfers, gleiche Korrektur.
- [ ] Eine-von-N auflösen: `filetree.nvim`, `pickers.nvim`. Das `error` im "keine davon"-Fall behalten.
- [ ] Gegenrichtung: `warn` → `error` überall, wo der Text schon "will fail" sagt (cascade, fileops, buffer-ctx, sessions).
- [ ] `setup()`-Zeilen auf `info` oder Ladezustand prüfen (sessions, open, buffer-ctx).
- [ ] ADVICE nachziehen: jede verbleibende Warnung, die eine Handlung verlangt, bekommt den `{...}`-Block. Eine Warnung ohne Handlungsanweisung ist eine halbe Warnung.
- [ ] Erst zuletzt kosmetisch: `ℹ️ INFO`-Tag in Statuslisten + `after/syntax/checkhealth.vim` in der Config.
- [ ] Regel in `MATERIALS/CHECKLIST.md` aufnehmen, damit sie bei jedem Repo-Durchgang mitläuft.

---
