# lspsaga.nvim vs. lsp.nvim — welche Features fehlen noch?

**Stand:** 2026-09-21
**Verglichen:** `nvimdev/lspsaga.nvim` @ `cf6fc94` (die im `lazy-lock.json` gepinnte Version, Nvim 0.12.2)
gegen `E:/repos/lsp.nvim` @ `main` (`StefanBartl/lsp.nvim`) samt den Plugins, die dein Stack
ohnehin mitbringt (fzf-lua, Trouble, snacks, gitsigns, lensline, inc-rename).

---

## Table of content

  - [Kurzfazit](#kurzfazit)
  - [Ausgangslage: was lsp.nvim heute mit lspsaga macht](#ausgangslage-was-lspnvim-heute-mit-lspsaga-macht)
  - [Skalen](#skalen)
  - [Übersicht](#übersicht)
  - [Die echten Lücken im Detail](#die-echten-lücken-im-detail)
  - [Bereits abgedeckt (keine Lücke)](#bereits-abgedeckt-keine-lücke)
  - [Bewusst nicht empfohlen](#bewusst-nicht-empfohlen)
  - [Empfohlene Reihenfolge](#empfohlene-reihenfolge)
  - [Checkliste bei der Umsetzung](#checkliste-bei-der-umsetzung)
  - [Methode und Grenzen](#methode-und-grenzen)

---

## Kurzfazit

lspsaga wird in lsp.nvim **nur für die Winbar-Breadcrumbs** benutzt (samt eigener Tiefenkappung und
Chips-Darstellung). Alle anderen Module sind in `integrations/lspsaga.lua` ausgeschaltet
(`hover`, `lightbulb`, `rename`, `term_toggle`, `beacon`); `finder`, `definition`, `code_action`,
`diagnostic`, `outline`, `callhierarchy`, `typehierarchy`, `implement` bleiben ungenutzt liegen,
obwohl sie durch `event = "LspAttach"` ohnehin geladen sind.

Fehlen tut davon **wenig**, und das meiste davon ist **billig**:

- **1 echte funktionale Lücke:** *Peek Definition* (editierbares Float mit der Definition). Dafür
  gibt es weder nativ noch in fzf-lua/Trouble ein Äquivalent.
- **4 Lücken, die nur ein fehlender Keymap sind**, weil fzf-lua/Trouble das Feature schon können:
  Finder (`lsp_finder`), Code-Action mit Diff-Vorschau (`lsp_code_actions`), Type Hierarchy
  (`lsp_type_super`/`lsp_type_sub`), Outline-Seitenleiste (`Trouble symbols`).
- **3 Kleinigkeiten** mit geringem Nutzen (Implementations-Marker, Diagnose→Code-Action,
  Winbar-Toggle).
- Alles andere (Hover, Rename, Lightbulb, Call Hierarchy, Diagnose-Listen, Floaterm,
  `project_replace`) ist **bereits abgedeckt oder bewusst besser gelöst**.

**Gesamtaufwand für alles Sinnvolle: ca. 3–5 Stunden**, davon 2 h Runde 1 (vier Keymaps) und
1–3 h für Peek Definition.

---

## Ausgangslage: was lsp.nvim heute mit lspsaga macht

| Ort | Was |
|---|---|
| `lua/lsp/pack/ui.lua` | Spec `nvimdev/lspsaga.nvim`, `event = "LspAttach"`, abschaltbar über `pack.disable = { "lspsaga.nvim" }` |
| `lua/lsp/integrations/lspsaga.lua` | `setup()` mit `symbol_in_winbar` an, **alles andere aus**; Winbar-Nachbearbeitung (`trim_winbar`, `style_winbar`), `M.hard = false` |
| `lua/lsp/integrations/lspsaga_chips.lua` | Rundet die Breadcrumb zu farbigen Chips |
| Autocmds | `LspNvimSagaWinbarDepth` auf `CursorMoved`, `User SagaSymbolUpdate`, `LspAttach`, `BufWinEnter`, `ColorScheme` |
| `lua/lsp/config/KEYMAPS.lua` | **Kein einziger** Eintrag ruft lspsaga auf |

Konsequenz: lsp.nvim baut die LSP-Navigation komplett auf Neovim-nativen Funktionen, fzf-lua,
Trouble und eigenen Modulen (`core/lightbulb.lua`, `tools/lsp_signature`, `tools/ts_type_lookup`)
auf. lspsaga ist ein Winbar-Renderer, kein LSP-UI.

---

## Skalen

**Aufwand** (Zeit für Umsetzung inkl. Doku und Tests im Plugin-Stil von lsp.nvim):

| Stufe | Bedeutung |
|---|---|
| **XS** | ≤ 30 min — ein Katalogeintrag in `KEYMAPS.lua`, keine neue Logik |
| **S** | 30 min – 2 h — dünner Adapter oder kleine Logik |
| **M** | 2 h – 1 Tag — eigenes Modul mit UI |
| **L** | mehrere Tage |

**Nutzen** (1–5, subjektiv für deinen Alltag: Lua-Plugins, Markdown, TypeScript/Astro):
1 = kaum spürbar, 3 = nett, wird gelegentlich benutzt, 5 = täglich, spart merklich Zeit.

Beides sind **Schätzungen**, keine Messungen.

---

## Übersicht

| # | Feature (lspsaga-Befehl) | Lücke in lsp.nvim? | Weg | Aufwand | Nutzen | Empfehlung |
|---|---|---|---|---|---|---|
| 1 | Peek Definition / Type Definition (`peek_definition`, `peek_type_definition`) | **Ja, echt** | lspsaga nutzen | XS | 4 | **Machen** |
|   |   |   | oder eigenes Modul | M | 4 |   |
| 2 | Finder: refs + impl + def in einem Fenster mit Vorschau (`finder`) | Ja, nur Keymap | `FzfLua lsp_finder` | XS | 3 | **Machen** |
| 3 | Code-Action mit Diff-Vorschau (`code_action`) | Ja, nur Keymap | `FzfLua lsp_code_actions` | XS–S | 4 | **Machen** |
| 4 | Outline-Seitenleiste mit Cursor-Folgen (`outline`) | Ja, nur Keymap | `Trouble symbols toggle` | XS | 3 | **Machen** |
| 5 | Type Hierarchy (`supertypes`, `subtypes`) | Ja, nur Keymap | `FzfLua lsp_type_super/sub` | XS | 2 | Machen (nachrangig) |
| 6 | gitsigns-Hunk-Aktionen in der Code-Action-Liste (`extend_gitsigns`) | Ja | lspsaga-Flag | S | 2 | Optional |
| 7 | Diagnose → „Code-Action dafür“ im Diagnose-Float (`exec_action`) | Teilweise | lspsaga oder eigener Keymap | S | 2 | Optional |
| 8 | Implementations-Marker an Interfaces/Methoden (`implement`) | Ja | lspsaga-Flag | XS (+ Perf-Prüfung S) | 2 | Zurückstellen |
| 9 | Beacon (Aufblitzen nach Sprung) | Ja | lspsaga-Flag | XS | 1 | **Nur zusammen mit #1** |
| 10 | Winbar an/aus (`winbar_toggle`) | Ja | 1 Subcommand | XS | 1 | Optional |

---

## Die echten Lücken im Detail

### 1. Peek Definition / Peek Type Definition

**Was lspsaga tut:** öffnet die Definition in einem schwebenden Fenster **über** dem aktuellen
Code. Das Fenster enthält den echten Buffer — man kann darin editieren, weiterspringen (verschachteltes
Peek), es per `<C-o>` / `<C-v>` / `<C-x>` / `<C-t>` in das Hauptfenster, einen Split oder einen Tab
übernehmen und mit `q` schließen. Ohne den Sprung zu verlieren.

**Warum das eine echte Lücke ist:** `lsd`/`lst` (nativ) springen und zerstören den Kontext,
`lsr`/`lsi` listen nur. Zwischen „springen“ und „nur Liste“ gibt es nichts, und dort fällt genau der
Fall „ich will nur kurz sehen, was `foo()` macht“. Weder Neovim 0.12 noch fzf-lua noch Trouble noch
snacks haben ein editierbares Peek-Float.

**Zwei Wege:**

| Weg | Aufwand | Für | Wider |
|---|---|---|---|
| **A. lspsaga benutzen** — zwei Katalogeinträge `peek_definition` (`lsp`) und `peek_type_definition` (`lsT`), `rhs = "<cmd>Lspsaga peek_definition<cr>"`, `requires = "lspsaga"` | **XS** (~20 min inkl. `definition`-Config und Doku) | lspsaga ist ohnehin geladen (`LspAttach`) und aktiv gepflegt (gepinnter Commit vom 2026-07-16); keine neue Abhängigkeit | Ein weiteres Feature hängt an lspsaga — wer `pack.disable = { "lspsaga.nvim" }` setzt, verliert es (Katalogeintrag mit `requires` löst das sauber: Health meldet es, sonst inert) |
| **B. eigenes Modul** `lsp/tools/peek/` | **M** (~150–250 Zeilen: Float aus `vim.lsp.buf_request`, Buffer-Reuse, Stack für Verschachtelung, Split/Tab-Aktionen, Aufräumen bei `WinClosed`) | Unabhängig von lspsaga; passt zur Linie „lspsaga abbauen“, falls die je kommt | Nachbau von etwas, das es fertig gibt |

**Empfehlung:** Weg A. Weg B erst, wenn lspsaga sowieso entfernt werden soll.

**Wechselwirkung:** Mit Peek wird auch **#9 Beacon** sinnvoll (siehe dort).

---

### 2. Finder

**Was lspsaga tut:** ein Fenster, links ein aufklappbarer Baum aus Referenzen + Implementierungen
(einstellbar: auch Definitionen und Typdefinitionen, `finder.default = "ref+imp"`), rechts eine
Code-Vorschau, `o` öffnet, `s`/`i`/`t`/`r` öffnen in vsplit/split/tab/neuem Tab.

**Lücke:** lsp.nvim hat `lsr` (nativ → Quickfix), `lsi` (nativ), Trouble-Ansichten und die
fzf-Picker, aber keinen **kombinierten** Aufruf.

**Schon vorhanden im Stack:** `FzfLua lsp_finder` (`fzf-lua/init.lua:314`, Provider
`finder` in `providers/lsp.lua:757`) — dieselbe Idee, alle LSP-Locations in einer Liste mit
Vorschau, und die Splits/Tabs kommen über die normalen fzf-lua-Aktionen.

**Vorschlag:** ein Eintrag `picker_finder` (`lsf`), `rhs = "<cmd>FzfLua lsp_finder<cr>"`,
`requires = "fzf-lua"`. Exakt das Muster von `picker_incoming_calls` (`lsc`). Wandert in
`presets.default` und `minimal` (kostet in `minimal` keinen weiteren `ls*`-Timeout, `lsc` und `lsC`
sind dort schon aktiv).

**Aufwand XS, Nutzen 3.** Unterschied zu lspsaga: fzf-lua zeigt eine flache Liste, keinen Baum. Für
„wo wird das benutzt“ ist das eher schneller; wer den Baum vermisst, nimmt `<leader>xlr` (Trouble).

---

### 3. Code-Action mit Diff-Vorschau

**Was lspsaga tut:** eigenes Auswahlfenster mit **Ziffern-Shortcuts**, optionalem Servernamen, und
einer **Vorschau des Edits als Diff**, bevor man ihn anwendet (`code_action/preview.lua`, löst bei
Bedarf `codeAction/resolve` auf).

**Lücke:** `lsa` ruft `vim.lsp.buf.code_action` auf — nackte `vim.ui.select`-Liste, keine Vorschau. Bei
`refactor.*`-Aktionen (ts_ls „Move to new file“, gopls-Refactorings) ist blindes Anwenden
unangenehm.

**Schon vorhanden im Stack:** `FzfLua lsp_code_actions` (`providers/lsp.lua:955`) hat einen
`codeaction`-Previewer, der den `WorkspaceEdit` als Diff rendert
(`previewer/builtin.lua`, Diff-Code aus `actions-preview.nvim`; mit `delta` auch farbig).

**Vorschlag:** `code_action` (`lsa`) umlenken auf `FzfLua lsp_code_actions` **oder** einen
zweiten Eintrag daneben. Ersteres ist konsistenter zur Regel „ein Picker, kein zweiter“ aus
`docs/FEATURES/TOOLS.md`. Zu klären: fzf-lua warnt, wenn es nicht als `vim.ui.select`-Backend
registriert ist — `silent = true` übergeben oder einmalig `:FzfLua register_ui_select` (das würde
dann *alle* `vim.ui.select`-Aufrufe übernehmen; für die Code-Action nicht nötig).

**Aufwand XS–S** (S wegen der `ui_select`-Frage und des `range`-Falls im Visual-Mode), **Nutzen 4**.
Der Nutzen ist der höchste unter den Keymap-Lücken, weil `lsa` ein täglicher Griff ist.

---

### 4. Outline-Seitenleiste

**Was lspsaga tut:** Symbolbaum rechts, `auto_preview`, `auto_close`, folgt dem Cursor.

**Lücke ist nur ein Keymap:** Trouble hat den Modus **`symbols`** bereits fertig konfiguriert
(`trouble/config/init.lua:132`: `mode = "lsp_document_symbols"`, `focus = false`,
`win.position = "right"`, filtert `Package` heraus). lsp.nvim bindet dagegen
`<leader>xls` → `Trouble lsp_document_symbols` — das ist die **Listenansicht** ohne die
Seitenleisten-Voreinstellungen.

**Vorschlag:** neuer Eintrag `trouble_outline`, `rhs = "<cmd>Trouble symbols toggle<cr>"`,
`requires = "trouble"`. Kein neuer Prefix nötig, `<leader>xo` ist im `<leader>x`-Namensraum frei.
Für Markdown (marksman meldet Überschriften als verschachtelte Symbole, siehe
`integrations/lspsaga.lua`) ist das ein brauchbares Inhaltsverzeichnis.

**Aufwand XS, Nutzen 3.**

---

### 5. Type Hierarchy

**Was lspsaga tut:** Baum der Super-/Subtypen, lazy nachgeladen.

**Lücke:** in lsp.nvim **gar nichts** (`grep` nach `typehierarchy|supertypes|subtypes` liefert null
Treffer). Nativ gibt es `vim.lsp.buf.typehierarchy("supertypes"|"subtypes")` (Quickfix, nvim 0.12
verifiziert), fzf-lua hat `lsp_type_super` / `lsp_type_sub`.

**Warum nachrangig:** Type Hierarchy unterstützen von deinen konfigurierten Servern nach meinem
Wissensstand nur `clangd`, `jdtls` und `dartls`. `lua_ls`, `ts_ls`, `marksman`, `gopls` liefern
sie nicht. In deinem Alltag (Lua/TS/Markdown) wäre der Eintrag meistens tot.

**Vorschlag:** zwei Einträge (`lsh` = Supertypen, `lsH` = Subtypen), `requires = "fzf-lua"`.
Optional mit Capability-Check (`typeHierarchyProvider`), damit die Taste auf einem Server ohne
Unterstützung eine klare Meldung statt „No results“ gibt.

**Aufwand XS, Nutzen 2.** Verwerfen ist hier legitim.

---

### 6. gitsigns-Aktionen in der Code-Action-Liste

**Was lspsaga tut:** `code_action.extend_gitsigns = true` hängt die Hunk-Aktionen von gitsigns
(Stage/Reset/Preview Hunk) an die Liste (`codeaction/init.lua:198`).

**Lücke:** die Aktionen liegen in deiner Config auf eigenen Keys; in der Code-Action-Liste tauchen sie
nicht auf. Nur relevant, wenn #3 über **lspsaga** statt über fzf-lua gelöst wird — fzf-lua kennt das
nicht. Ein Grund, #3 *nicht* über lspsaga zu machen, ist es nicht wert.

**Aufwand S, Nutzen 2.**

---

### 7. Diagnose → Code-Action direkt aus dem Float

**Was lspsaga tut:** `diagnostic_jump_next/prev` springt und zeigt die Diagnose im Float;
`o` darin führt die passende Code-Action aus. Zusätzlich `extend_relatedInformation` und
Ziffern-Shortcuts in der Liste.

**Was lsp.nvim schon hat:** `]d`/`[d` (nativ mit `jump.float = true`, siehe
`core/diagnostics.lua:128`, oder in der Trouble-Liste), Trouble, Quickfix/Loclist, vier
fzf-Picker. Den Sprung + Float gibt es also. Es fehlt nur „Fix für diese Diagnose anwenden“ in einem
Handgriff — heute wäre das `]d`, dann `lsa`.

**Aufwand S, Nutzen 2.** Wenn #3 (fzf-lua-Code-Actions) drin ist, ist der Mehrwert klein.

---

### 8. Implementations-Marker

**Was lspsaga tut:** `implement.enable = true` setzt Sign/Virtualtext an Interface-Methoden und
Typen, die eine Implementierung haben (`implement/init.lua`).

**Lücke:** ja. lensline (installiert) zeigt Referenzen usw., aber keine Implementierungen.

**Warum zurückstellen:** braucht pro Buffer zusätzliche `textDocument/implementation`-Anfragen —
das ist genau die Art Dauerlast, die in `integrations/lspsaga.lua` beim Lightbulb schon einmal
gemessen wurde (~214 ms im Startup-Sample). Für Lua und Markdown (`implementation` gibt es dort nicht)
bringt es nichts, nur für TS/Go/Java.

**Aufwand XS für den Schalter, S für Perf-Prüfung; Nutzen 2.**

---

### 9. Beacon

**Was lspsaga tut:** kurzes Aufblitzen der Zielzeile nach einem Sprung.

**Wichtige Korrektur zur heutigen Config:** `beacon = { enable = false }` ist bei lsp.nvim gesetzt.
Dabei ist Beacon gar kein allgemeines „Cursor sprang weit“-Highlight: im Quellcode wird
`jump_beacon` **nur** aus `definition.lua` und `callhierarchy.lua` aufgerufen. Solange keiner der
Sprünge über lspsaga läuft (heute: keiner), hätte es auch eingeschaltet **keinen Effekt**.

**Konsequenz:** Beacon ist ein Anhängsel von #1. Wird Peek/Goto über lspsaga gebaut, kann
`beacon.enable = true` gesetzt werden; sonst lassen.

**Aufwand XS, Nutzen 1.**

---

### 10. Winbar an/aus

**Was lspsaga tut:** `:Lspsaga winbar_toggle`.

**Lücke:** kein `:Lsp winbar`-Subcommand. Sinnvoll wäre `:Lsp winbar [on|off|toggle]` im Stil der
Toggles für Inlay-Hints und Lightbulb. `style_winbar` ignoriert Zeilen ohne `%#Saga`, ein
ausgeschalteter Winbar bleibt also in Ruhe.

**Aufwand XS, Nutzen 1.**

---

## Bereits abgedeckt (keine Lücke)

| lspsaga-Feature | Abdeckung in lsp.nvim / deinem Stack | Beleg |
|---|---|---|
| Winbar-Breadcrumbs | genutzt **und** erweitert (Tiefenkappung, Chips) | `integrations/lspsaga.lua`, `lspsaga_chips.lua` |
| Lightbulb | eigenes `core/lightbulb.lua`, **besser**: nach Kind gefiltert (nur `quickfix`/`source`), sonst leuchtet ts_ls dauerhaft; lspsaga-Lightbulb ist bewusst aus (`lightbulb.enable`) | `core/lightbulb.lua` |
| Rename-UI | `inc-rename` über `rename.provider`, `grn` und `<leader>rn` auf einer Aktion | `KEYMAPS.lua` |
| `project_replace` | nicht lsp-spezifisch (ripgrep-Suche + Ersetzen im Projekt), gehört zu `replacer.nvim` | `personal/init.lua` |
| Call Hierarchy | `lsc`/`lsC` über fzf-lua; zusätzlich hat Trouble `lsp_incoming_calls`/`lsp_outgoing_calls` als Baum | `KEYMAPS.lua`, Trouble `sources/lsp.lua` |
| Hover mit Scrollen | `tools/lsp_signature` (`<C-b>`, dauerhaftes Popup, Parameter-Hervorhebung, Hover-Fallback über alle Clients); nativ `vim.lsp.buf.hover` ist fokussierbar | `tools/lsp_signature/Readme.md` |
| Diagnose nur in der Cursorzeile (`virt.lua`) | nativ: `virtual_text = { current_line = true }` in 0.12 (im Runtime-Quelltext verifiziert). Heute: Virtualtext an allen Zeilen, `core/diagnostics.lua:162` | `diagnostic.lua:241` |
| Diagnose-Listen (`show_buf/workspace/line/cursor_diagnostics`) | Trouble (`<leader>xd/xw`), Quickfix/Loclist (`<leader>wq/lq`), vier fzf-Picker, Workspace-Diagnostics-Toggle mit Größenlimit | `KEYMAPS.lua`, `core/workspace_diagnostics.lua` |
| Document Symbols | `lss`, `<leader>dos`, `<leader>xls` | `KEYMAPS.lua` |
| `open_log` | `:LspDoctor` / `:checkhealth lsp` | `lspdoctor/` |

---

## Bewusst nicht empfohlen

| Feature | Grund |
|---|---|
| **Floaterm** (`term_toggle`) | Kein LSP-Feature. Terminals sind in deiner Config bereits Thema (`autocmds/terminals`, snacks). Ein dritter Terminal-Weg wäre Schaden, kein Nutzen. |
| **Hover-UI von lspsaga** (`hover_doc`) | `tools/lsp_signature` und nativer Hover decken das ab. Was lspsaga zusätzlich bietet (Link öffnen mit `gx`, Scroll-Tasten) ist Kosmetik. |
| **Rename-UI von lspsaga** | inc-rename zeigt die Änderung live im Buffer, lspsagas Rename nur eine Eingabezeile. Kein Gewinn. |
| **lspsagas Lightbulb** | Siehe oben; dein eigenes ist gefiltert und besser. |
| **Layouts** (`float`/`normal`/`dropdown`) | Nur relevant, wenn man lspsagas Panels nutzt. Bei Weg B wären sie hinfällig. |

---

## Empfohlene Reihenfolge

**Runde 1 — vier Katalogeinträge, ~1–2 Stunden gesamt, kein neues Plugin, keine neue Logik**

| Schritt | Eintrag | Taste (Vorschlag) | Aufwand | Nutzen |
|---|---|---|---|---|
| 1a | `code_action` auf `FzfLua lsp_code_actions` (mit Diff-Vorschau) | `lsa` (besteht) | XS–S | 4 |
| 1b | `picker_finder` → `FzfLua lsp_finder` | `lsf` | XS | 3 |
| 1c | `trouble_outline` → `Trouble symbols toggle` | `<leader>xo` | XS | 3 |
| 1d | `picker_type_super` / `picker_type_sub` (nachrangig, ggf. weglassen) | `lsh` / `lsH` | XS | 2 |

Die vorgeschlagenen Tasten `lsf`, `lsp`, `lsP`, `lsh`, `lsH`, `lsT`, `lsA` und `<leader>xo` sind in
`lsp.nvim/lua/lsp/config/KEYMAPS.lua`, in `docs/BINDINGS.md` der nvim-Config und in deren
`lua/**`-Mappings **frei** (per grep geprüft; die einzigen Treffer waren der String `"lsp"`, kein
Mapping). Sie erweitern allerdings die `ls*`-Familie, die jede Normal-Mode-`l` um
`timeoutlen` verzögert — in `default` schon so (neun Einträge), `minimal` behält nur `lsc`/`lsC`.
Neue `ls*`-Einträge in `minimal` **nicht** aufnehmen, sonst verliert der Preset seinen Sinn.

**Runde 2 — Peek Definition, XS (lspsaga) bis M (eigenes Modul)**

| Schritt | Eintrag | Taste | Aufwand | Nutzen |
|---|---|---|---|---|
| 2a | `peek_definition` / `peek_type_definition` über `Lspsaga` | `lsp` / `lsT` | XS | 4 |
| 2b | Beacon aktivieren, weil lspsaga jetzt springt | — | XS | 1 |

**Runde 3 — nur bei Bedarf:** `:Lsp winbar`, Diagnose→Code-Action, Implementations-Marker.

Reihenfolge nach Nutzen/Aufwand: **1a → 2a → 1b → 1c → 1d → Rest.** 1a kommt zuerst, weil `lsa`
täglich gedrückt wird; 2a vor 1b/1c, weil es die einzige Funktion ist, die man heute gar nicht hat.

---

## Checkliste bei der Umsetzung

Jeder neue Eintrag ist ein Katalogeintrag in `KEYMAPS.lua` (`requires` für fzf-lua/Trouble/lspsaga),
danach:

- [ ] `scripts/gen_bindings.lua` laufen lassen, `docs/BINDINGS.md` (generiert) im lsp.nvim-Repo
      aktualisieren — CI prüft mit `--check`
- [ ] `docs/BINDINGS.md` in der **nvim-Config** aktualisieren (`docs/NOTES/ExternPlugins/Bindings/`,
      sofern dort geführt)
- [ ] `docs/FEATURES/TOOLS.md` / `INTEGRATIONS.md` im lsp.nvim-Repo ergänzen (Abschnitt „Peek“,
      „Finder“, „Code-Actions“), README-Feature-Liste prüfen
- [ ] `integrations/menu.lua` prüfen: neue Einträge landen automatisch in den Fly-outs; Gruppenzuordnung
      per Katalogname (`picker_*` → Picker, `trouble_*` → Trouble). `peek_*` und `code_action`
      müssen in *Navigation* landen
- [ ] `presets.minimal` bewusst **nicht** erweitern (siehe oben)
- [ ] `requires = "lspsaga"` an den Peek-Einträgen; Health (`lsp.health`) meldet sie bei
      `pack.disable = { "lspsaga.nvim" }`
- [ ] Tests im Plugin-Ordner `TESTS/` ergänzen: Katalog-Invarianten (jeder Eintrag hat `lhs`,
      `mode`, `desc`; keine doppelten `lhs`), Preset-Zugehörigkeit
- [ ] `luacheck` und `stylua --check` grün

---

## Methode und Grenzen

**Gelesen:** `lspsaga.nvim` (`init.lua`, `command.lua`, `definition.lua`, `codeaction/*`,
`beacon.lua`, `diagnostic/*`, `rename/project.lua`, `symbol/*`), sämtliche lsp.nvim-Adapter zu lspsaga,
`KEYMAPS.lua`, `pack/ui.lua`, die Feature-Docs, sowie in fzf-lua, Trouble und im
Neovim-0.12-Runtime die Stellen, auf die dieser Report sich beruft (jeweils mit Datei/Zeile oben).

**Belegt, nicht angenommen:** Beacon feuert nur aus `definition.lua`/`callhierarchy.lua`; fzf-lua hat
`lsp_finder`, `lsp_code_actions` (mit Diff-Previewer), `lsp_type_super/sub`; Trouble hat den
Modus `symbols`; Neovim 0.12 hat `virtual_text.current_line` und `vim.lsp.buf.typehierarchy`; die
vorgeschlagenen Tasten sind frei.

**Nicht geprüft:**

- **Nichts davon wurde in einer laufenden nvim-Session ausprobiert.** Ob z. B. `lsp_code_actions` in
  der Praxis mit Vorschau ohne `register_ui_select` sauber läuft, ist aus dem Quelltext gelesen, nicht
  beobachtet. Das ist der erste Test bei Umsetzung von 1a.
- **Server-Unterstützung für Type Hierarchy** (`clangd`, `jdtls`, `dartls`) stammt aus meinem Wissen
  über die Server, nicht aus einer Abfrage ihrer Capabilities in deiner Umgebung. `:LspDoctor` oder
  `vim.lsp.get_clients()[1].server_capabilities.typeHierarchyProvider` klärt das pro Server.
- **Aufwand und Nutzen sind Schätzungen.** Die Nutzen-Werte beruhen auf deinem Stack (Lua, Markdown,
  TS/Astro), nicht auf gemessener Nutzung.
- Ob `lsa`-Umlenkung den Visual-Mode-Fall (`range`) sauber mitnimmt, ist offen.
