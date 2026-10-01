# noice.nvim — Feature-Abdeckung durch die eigenen Plugins

Stand 2026-10-01. Erfüllt den Roadmap-Punkt „noice.nvim & übrige externe Plugins auf Feature-Abdeckung prüfen —
was ist durch eigene Plugins schon abgedeckt, was fehlt noch? **Nur dokumentieren, keine Ersatz-Entscheidung**"
(`00_ROADMAP.md`, Konkurrenzanalyse). Dieser Report entscheidet deshalb nichts; er hält fest, was ist, und markiert
Lücken. Er ist außerdem die Vorbedingung für das Message-Popup-Konzept
(`WKDBooks/…/lib.nvim/ROADMAP/messages-log-and-recent-popup.md`).

## Kurzfassung

- **Du nutzt noice für drei Dinge:** (1) *alle* nativen Meldungen (`:echo`, `:write`, Fehler, `showmode`) als
  kompakte **mini**-Meldungen mit einer langen Liste von Skip-/Routing-Regeln, (2) `vim.notify` mit demselben
  Routing, (3) die Cmdline (klassisch unten, aber von noice gezeichnet: Icons, Syntax-Highlighting) samt
  LSP-Hover-Markdown-Rendering und Hover-Scrolling.
- **Deine eigenen Plugins decken davon bisher nur die Plugin-Seite ab** (`lib.nvim.notify`/`output`/`echo`/
  `progress`, `ui.kit.toast`/`viewer`/`input`, `debugging.nvim`-Views): Toast, History, Viewer, Fortschritt. Alles, was
  *native* Neovim-Meldungen oder die Cmdline betrifft, ist **nicht** abgedeckt — das geht technisch nur über
  `vim.ui_attach` mit `ext_messages`/`ext_cmdline`.
- **Es laufen heute zwei parallele Meldungs-Pipelines**, die sich nicht sehen (siehe §2). Das ist der wichtigste
  Strukturbefund und gilt unabhängig von jeder Ersatzfrage.
- **Neu seit Neovim 0.12:** eine eingebaute, experimentelle Message-/Cmdline-UI (`vim._core.ui2`) ersetzt einen
  Teil dessen, wofür man noice brauchte. Sie kann *nicht* alles, was dein noice-Setup tut (kein Routing nach Text,
  kein Skip, keine History mit Zeit) — §5.
- **Geprüft/verifiziert** (nicht nur gelesen): mehrere `ui_attach(ext_messages)`-Listener koexistieren in 0.12.2;
  `vim._core.ui2` existiert in 0.12.2 und ist per `require("vim._core.ui2").enable({})` zuschaltbar;
  `lib.nvim.notify`-Toasts umgehen `vim.notify` und damit noice. **Nicht geprüft:** Laufzeitverhalten in einer echten
  TUI (kommt mit dem Spike, siehe §8).

## 1. Grundlage

| Was | Quelle |
|---|---|
| noice.nvim | installiert `7bfd942` (2025-11-03), `lazy/noice.nvim`; README + Defaults gelesen |
| Deine noice-Konfiguration | `lua/config/noice/init.lua`, Spec `lua/plugins/ui.lua`, Keymaps `lua/bindings/mappings/noice.lua`, `docs/NOTES/ExternPlugins/Bindings/*/Noice.md` |
| Neovim | 0.12.2 (`vim._core.ui2` im Runtime gelesen) |
| Eigene Plugins | Quelltext/Doku von lib.nvim, ui.nvim, debugging.nvim, lsp.nvim, hover.nvim, filetree.nvim gelesen |

Die Matrix unten beruht auf **Code- und Doku-Lektüre**. Wo etwas ausgeführt wurde, steht es dabei.

## 2. Wie noice bei dir heute konfiguriert ist

Aus `lua/config/noice/init.lua` (Kurzform):

- **Meldungen:** `messages.view = "mini"`, `notify` → `mini` (Route `event = "notify"`), `msg_showmode` → `mini`;
  Catch-all ganz unten: jede weitere `msg_show` → `mini`. `view_search = false` (Suchzähler-Route: skip).
- **Skip-Regeln** (`opts.skip`): „search hit BOTTOM/TOP", die Fehler E23/E20/E37/E31/E351/E418, „No signature help",
  „Error detected while processing BufReadPost Autocommands for", „Buffer is not modifiable" (notify/warn),
  `search_count`, **`lsp`/`progress`** (→ LSP-Fortschritt wird bewusst *nicht* angezeigt).
- **Kompaktansicht** für „written" und „Conflict [n".
- **Cmdline:** `view = "cmdline"` (klassisch unten statt Popup), Suche ebenfalls klassisch; Presets
  `bottom_search`, `long_message_to_split`, `inc_rename` (inc-rename.nvim installiert), `lsp_doc_border = false`.
- **LSP:** `hover` an; `signature` **aus**; die Markdown-Overrides (`convert_input_to_markdown_lines`,
  `stylize_markdown`, `cmp.entry.get_documentation`) an. Buffer-lokale Keymaps in `noice*`-Buffern:
  `<A-j/k/Down/Up>` scrollen den Hover-Float, `<A-x>` dismisst.
- **Abhängigkeiten laut Spec:** `nui.nvim`, `snacks.nvim`, `nvim-notify`.

### Strukturbefund: zwei Pipelines, die sich nicht sehen

`specs/foundation.lua:72` stellt `lib.nvim.notify` global auf `popup = true`. `lib.nvim.notify.popup.deliver` öffnet
den Toast **direkt über `ui.kit.toast`** und ruft `vim.notify` nur als Rückfall auf (kein Toast möglich, oder
`ui.notify` aktiv). Folge:

| Quelle | Weg | In `:Noice` History? | In `:Lib notify history`? | In `:messages`? |
|---|---|---|---|---|
| Plugin mit `lib.nvim.notify` (popup an) | Toast direkt | **nein** | ja | nur mit `messages = true` |
| Plugin mit direktem `vim.notify` / `popup = false` (z. B. filetree) | noice → `mini` | ja | nein | ja |
| native Meldungen (`:echo`, `:w`, Fehler) | noice → `mini`/Routen | ja | nein | ja (noice leitet `:messages` um) |

Das erklärt Beobachtungen wie „bei filetree sehe ich die Meldung in `:messages`/more, im Picker nicht" (Picker-Toast
ging über den Toast-Weg und lag zusätzlich unter dem Picker — behoben mit ui.nvim `a1574ca`). Es heißt auch:
**es gibt keine einzelne vollständige Meldungs-History**; jede der beiden Pipelines kennt nur ihre Hälfte.

## 3. Feature-Matrix

Legende: ✅ abgedeckt · 🟡 teilweise · ❌ nicht abgedeckt · ➖ nutzt du nicht · **ui2** = von Nvim 0.12 `ui2` (experimentell)
mitgebracht.

| # | noice-Feature | Du nutzt es? | Eigene Plugins | Nvim 0.12 `ui2` | Lücke / Anmerkung |
|---|---|---|---|---|---|
| 1 | Meldungen als eigene Views (mini, notify, popup, split, virtualtext, notify_send) | ja (`mini`, Split für lange) | 🟡 Toast/Chip (`ui.kit.toast`, `lib.nvim.notify.popup`), `ui.kit.viewer` — **nur für Plugin-Meldungen** | 🟡 `cmd`/`msg`/`pager`/`dialog`-Fenster, `msg.timeout` | native Meldungen als Toast/mini: ❌ (braucht `ext_messages`) |
| 2 | **Routing/Filter** nach `event`/`kind`/`find`/`error`/`warning`/`any`, `skip`, `merge`, `replace` | ja, ausgiebig (≈20 Regeln) | ❌ nur `toast_min_level` (nach Level) in `lib.nvim.notify.popup`; kein Textfilter | 🟡 Ziel je `kind`/`trigger` (`cmd`/`msg`/`pager`), **kein** `find`, kein `skip` | zentrale Lücke für dein Setup |
| 3 | Highlights der Meldungen bleiben erhalten | ja | 🟡 Toast färbt nach Level (`hl`), Inhalte plain | 🟡 liefert die Highlight-Chunks der Meldungen aus (nicht ausprobiert) | – |
| 4 | `:messages` als normaler Buffer | ja | 🟡 `:Debug messages` (Capture), `:Lib notify history` (nur Plugin-Seite) | ✅ `pager` (`g<`) | – |
| 5 | **History** `:Noice`, `last`, `errors`, `all`, `dismiss`; Telescope/fzf-Picker | ja (Keymaps `<A-x>`) | 🟡 `:Lib notify history\|last\|clear`, `:UI notify history`, `:Debug noice` (liest noices Fenster) | ❌ keine History mit Zeit/Level | native + Plugin-Meldungen nirgends vereint (§2); keine Zeitstempel |
| 6 | Kein more-/hit-enter-Prompt | ja | 🟡 Plugin-Meldungen: ja (Toast); native: nein | ✅ „kollabiert" + `[+x]`, `g<` | – |
| 7 | **Cmdline-UI** (Icons, Syntax-Highlighting vim/lua, Popup-Variante) | ja (klassisch unten + Highlight/Icons) | ❌ (`ui.kit.input` ersetzt `vim.ui.input`, nicht die Cmdline) | 🟡 `cmd`-Fenster **mit Treesitter-Highlighting für `:`-Zeilen** (`vim`-Parser), kein Icon-/Format-System | Icons/Formate: ❌ |
| 8 | **Popupmenu** (Cmdline-Completion, nui oder cmp-Backend) | an (Default) | ❌ (Cmdline-Completion bedient bei dir blink.cmp, Keymap in `plugins/completion.lua`; kein eigenes UI der eigenen Plugins) | 🟡 Wildmenu/`dialog`-Fenster | – |
| 9 | Command-Redirection (`noice.redirect(cmd)`, `<S-Enter>`) | nein (nicht gebunden) | 🟡 `lib.nvim.output.dump(lines, title)` (Viewer), `debugging.nvim` Capture | 🟡 `pager` zeigt Befehlsausgabe | ➖ |
| 10 | **LSP-Fortschritt** (`lsp.progress`) | **aktiv unterdrückt** (Route `skip`) | ❌ kein `LspProgress`-Handler in lsp.nvim/lib/ui; `lib.nvim.progress` ist für Plugin-Operationen, nicht LSP | ❌ | Lücke, derzeit bewusst leer |
| 11 | LSP-Hover (Markdown-Rendering, Links, `|help|`-Verweise, Scroll) | ja (Override an, Scroll `<A-j/k>`) | ❌ (`hover.nvim` = Datei-Hover für Pfade/Links, **kein** LSP-Hover) | ➖ natives `vim.lsp.buf.hover` rendert Markdown selbst | Scrollen/Link-Folgen im Hover: noice-spezifisch |
| 12 | LSP-Signature-Help (auto-open) | nein (`enabled = false`) | ➖ nativ `vim.lsp.buf.signature_help` (lsp.nvim-Keymap) | ➖ | ➖ |
| 13 | LSP-`window/showMessage` | ja (→ `notify`-View) | 🟡 landet über `vim.notify` bei noice | ➖ | – |
| 14 | **Statusline-Komponenten** (ruler, `showcmd`, mode/`@recording`, search, letzte Meldung) | nein (Routen schieben `showmode`/Suchzähler weg) | 🟡 ui.nvim: `macro_counter` (Tastenzahl der Aufnahme), `search_count` (nicht in einem Preset verdrahtet); `showcmd`/letzte Meldung ❌ | 🟡 `search_count` als Virtual-Text im `cmd`-Fenster | – |
| 15 | Preset `bottom_search` | ja | ➖ | ✅ (Suche bleibt in `cmd`) | – |
| 16 | Preset `long_message_to_split` | ja | 🟡 `lib.nvim.notify`: lange Meldung gekürzt, voller Text per `:Lib notify last` im Viewer | ✅ `pager` | – |
| 17 | Preset `inc_rename` (Eingabe für inc-rename.nvim in der Cmdline) | ja | ❌ | ➖ | hängt an inc-rename.nvim + noice-Cmdline |
| 18 | Preset `lsp_doc_border`, `command_palette` | nein | ➖ | ➖ | ➖ |
| 19 | `vim.notify`-Ersatz mit Routing + History | ja (`notify.enabled`) | ✅ `ui.notify` (`:UI notify on`, Toast + History + Level/Timeouts/Titel) und `lib.nvim.notify.popup`; **kein Routing nach Text** | ➖ (ui2 fasst `vim.notify` nicht an) | Routing: ❌ |
| 20 | Health-Check, Throttle, Debug (`:Noice stats`) | – | ➖ | ➖ | ➖ |

## 4. Was nur `ext_messages` kann (und warum das die Grenze ist)

- Native Meldungen (`:echo`, `:echoerr`, `E354: …`, `:w`-Bestätigung, `showmode`) laufen **nie** durch `vim.notify`
  und durch keinen von Lua erreichbaren Hook — außer über das UI-Protokoll `vim.ui_attach(ns, { ext_messages = true },
  cb)`. Das ist exakt der Mechanismus von noice (und von `ui2`). Der frühere Befund aus dem UX-Backlog
  (`nvim-plugins-ux-backlog-2026-09-29.md`, Punkt 6: „automatische Titel-Erkennung für rohe Nvim-Fehler technisch nicht
  umsetzbar") ist damit genauer: *nicht umsetzbar ohne eigene `ext_messages`-UI*.
- **Verifiziert (Nvim 0.12.2, headless):** zwei `vim.ui_attach`-Namespaces mit `ext_messages = true` bekommen beide
  jedes `msg_show`-Event (`echo`, `echomsg`). Ein reiner **Logger** kann also neben noice mitlaufen.
- **Falle (aus der Nvim-Dokumentation, nicht ausprobiert):** sobald ein Listener `ext_messages` anfordert, zeichnet
  die TUI Meldungen nicht mehr selbst. Ein Logger ohne Renderer würde Meldungen verschlucken → er darf nur attachen,
  wenn ein Renderer (noice, `ui2` oder ein eigener) existiert.
- `vim._core.ui2` benutzt dasselbe `ui_attach` für Meldungen und Cmdline; noice und `ui2` gleichzeitig zu
  aktivieren ist erwartbar problematisch (zwei Renderer für dieselben Events) und **nicht getestet**.

## 5. Nvim 0.12 `ui2` — was die eingebaute UI mitbringt

Gelesen in `$VIMRUNTIME/lua/vim/_core/ui2.lua`, `ui2/messages.lua`, `ui2/cmdline.lua` (Header: *„WARNING: This is an
experimental feature intended to replace the builtin message + cmdline presentation layer"*).

- Aktivierung: `require("vim._core.ui2").enable({ enable = true, msg = { targets = …, msg = { timeout = 4000 }, … } })`.
- Vier Fenster: **cmd** (Cmdline, `showcmd`/`showmode`/`ruler`), **msg** (flüchtige Meldungen, Timeout), **pager**
  (`:messages` und nie-kollabierte Meldungen), **dialog** (Prompts).
- Meldungen über `'cmdheight'` werden „kollabiert" mit `[+x]`-Anzeige; Vollansicht per ENTER nach `:`-Befehl oder `g<`.
- Ziel je Meldungs-`kind` oder `trigger` wählbar (`cmd`/`msg`/`pager`) — **das ist das gesamte Routing**: kein `find`,
  kein Skip, keine eigenen Views, keine Zeit/Level-History, keine Behandlung von `vim.notify`.
- `:`-Zeile im `cmd`-Fenster wird per Treesitter (`vim`-Parser) gehighlightet; Suchzähler als Virtual-Text; Matchparen.
- **Konsequenz für dein Setup (nur Beobachtung):** `ui2` entspricht ungefähr noice mit *leerer* Route-Liste und ohne
  Icons/Formate. Deine ≈20 Skip-/Kompakt-Regeln, die `mini`-Ansicht und Hover-Rendering hat es nicht.

## 6. Lücken, geordnet (nur dokumentiert)

1. **Routing/Skip nativer Meldungen** (Matrix #2) — braucht `ext_messages`; weder eigene Plugins noch `ui2` haben es.
2. **Vereinte History** nativ + Plugin, mit Zeit und Level (#5) — die zwei Pipelines (§2) kennen jeweils nur ihre
   Hälfte; ein Message-Log (`lib.nvim.messages`-Konzept) wäre die gemeinsame Quelle.
3. **Cmdline-Darstellung** (#7: Icons/Formate) und **Cmdline-Popupmenu** (#8).
4. **LSP-Fortschritt** (#10) — derzeit absichtlich nicht angezeigt; niemand hört auf `LspProgress`.
5. **LSP-Hover-Komfort** (#11: Float scrollen, Links/`|help|` folgen) — `hover.nvim` ist ein anderes Feature.
6. **`inc_rename`-Eingabe** (#17) — gebunden an noice-Cmdline.
7. Kleinere: `showcmd`/letzte-Meldung als Statusline-Komponente (#14), Textrouting für `vim.notify` (#19).

Nicht als Lücke gezählt, weil abgedeckt: Toast/Chip, History und Viewer für Plugin-Meldungen, Fortschritt von
Plugin-Operationen (`lib.nvim.progress`), `vim.notify`-Ersatz (`ui.notify`), lange Meldungen im Viewer, Makro-Zähler.

## 7. Abhängigkeiten rund um noice (Beobachtung)

- `nvim-notify` ist als Abhängigkeit eingetragen, wird von deiner Konfiguration aber nicht benutzt: `notify.view =
  "popup"` und alle Routen laufen über `mini`; kein anderer Treffer auf `rcarriga/nvim-notify` in den Specs. Ob noice
  die Abhängigkeit hart braucht, wurde **nicht** geprüft.
- `snacks.nvim` steht in noices `dependencies`, ist aber ohnehin als Picker-Engine installiert.
- `nui.nvim` ist zusätzlich eigenständig in `plugins/ui.lua` eingetragen; wer es außer noice benutzt, wurde nicht geprüft.

## 8. Offene Prüfpunkte (nicht Teil dieses Reports)

- **Spike in echter TUI:** `ext_messages`-Logger neben noice (Verschlucken? Reihenfolge? Kosten), und `ui2` isoliert
  mit deiner Config ausprobieren. Headless sagt dazu nichts Belastbares. Plan im Konzeptdokument (Schritt 1).
- Ob die Routing-Regeln (§2) in der Praxis alle noch greifen (Neovim 0.12 hat neue `kind`-Werte) — nicht geprüft.
- **Übrige externe Plugins** (zweiter Teil der Roadmap-Zeile): **noch nicht geprüft.** Stand der Config
  (`lua/plugins/*.lua`, ohne `StefanBartl/…`): search.nvim, nui.nvim, neogit, neo-tree-tests-source, vim-matchup,
  mini.ai, noice, snacks, tokyonight, which-key, nvim-cmp, fzf-lua, gitsigns, mason, vim-visual-multi, plenary,
  neo-tree (+diagnostics-Source), neotest, telescope (+file-browser, fzf-native, github), nvim-web-devicons,
  nvim-treesitter (+textobjects), nvim-notify, blink.cmp, diffview, targets.vim, nvim-autopairs, nvim-ts-autotag.
  Bereits **abgelöst** am 2026-09-19 (laut Kommentaren in `plugins/ui.lua`): nvim-window-picker → `ui.windowpicker`,
  nvim-bqf → pickers.nvims `quickfix`, zen-mode → `ui.zen`, minty/volt → `ui.colorpicker`. Eine Einordnung der Rest-Liste
  wäre ein eigener Report.

## 9. Zusammenhang mit dem Message-Popup-Konzept

Das Popup „letzte *n* Sekunden" und der `lib.nvim.messages`-Log (WKDBooks `lib.nvim/ROADMAP/messages-log-and-
recent-popup.md`) adressieren Lücke 2 (vereinte History) und teilweise 1. Dieser Report ist die dort geforderte
Vorbedingung („Feature-Matrix noice ↔ eigene Plugins"). Er trifft **keine** Entscheidung, ob noice ersetzt wird; die
Matrix zeigt, dass ein Ersatz mehr wäre als ein Log: Routing (#2), Cmdline (#7/#8) und Hover-Komfort (#11) hängen an
der UI-Seite von `ext_messages`/`ext_cmdline`.
