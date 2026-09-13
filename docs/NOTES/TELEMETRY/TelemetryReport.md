# Telemetry-Auswertung — Stand 2026-08-27

Quelle: `runtime-analysis.telemetry`. Zwei Datensätze kombiniert:

- **Workstation** (`docs/TELEMETRY/Workstation/08262026/`) — der primäre,
  weil akkumulierte Datensatz: 2 bis 554 Sessions pro Plugin, je nachdem
  wie oft es seit der letzten `_control.json`-Rotation geladen wurde. Das
  ist der Datensatz, der unten pro Plugin ausgewertet ist.
- **PC** (`docs/TELEMETRY/PC/27082026_2/`) — eine frische Momentaufnahme von
  heute (6-45 Sessions, alles seit 2026-08-27 10:44), als Gegenprobe: taucht
  ein Plugin dort mit nennenswerten Zahlen auf, das auf der Workstation
  0 Aufrufe hat (oder umgekehrt), steht das unten explizit dabei.

Pro Funktion: Aufrufe gesamt, durchschnittliche Dauer (wo `timing` aktiv war),
Fehler. Nur die Top-Funktionen je Plugin sind aufgeführt (der volle Datensatz
steht in den Quelldateien oben).

## Table of content

  - [Zusammenfassung](#zusammenfassung)
  - [color_my_ascii.nvim](#colormyasciinvim)
  - [markdown.nvim](#markdownnvim)
  - [filetree.nvim](#filetreenvim)
  - [lib.nvim](#libnvim)
  - [emojis.nvim](#emojisnvim)
  - [recommender.nvim](#recommendernvim)
  - [cascade.nvim](#cascadenvim)
  - [spotlight.nvim](#spotlightnvim)
  - [lsp.nvim](#lspnvim)
  - [documentation.nvim](#documentationnvim)
  - [insights.nvim](#insightsnvim)
  - [debugging.nvim](#debuggingnvim)
  - [runtime-analysis.nvim](#runtimeanalysisnvim)
  - [gopath.nvim](#gopathnvim)
  - [replacer.nvim](#replacernvim)
  - [images.nvim](#imagesnvim)
  - [sessions.nvim](#sessionsnvim)
  - [fileops.nvim](#fileopsnvim)
  - [reposcope.nvim](#reposcopenvim)
  - [cmdlog.nvim](#cmdlognvim)
  - [open.nvim](#opennvim)
  - [buffer-ctx.nvim](#bufferctxnvim)
  - [pickers.nvim](#pickersnvim)
  - [sandbox.nvim](#sandboxnvim)
  - [github_stats.nvim](#githubstatsnvim)
  - [dap.nvim](#dapnvim)
  - [language.nvim](#languagenvim)
  - [mdview.nvim](#mdviewnvim)
  - [pdfport.nvim](#pdfportnvim)
  - [Ohne Daten](#ohne-daten)

---

## Zusammenfassung

### Die größten Ausreißer

| Plugin | Funktion | Aufrufe (Workstation) | Anteil am Plugin |
|---|---|---:|---:|
| **color_my_ascii.nvim** | `config.get_char_highlight` | 2.551.724 | 43 % |
| **markdown.nvim** | `hl_options.hl_groups.blockquote.highlight_line` | 485.693 | 85 % |
| **filetree.nvim** | `feature` | 86.821 | 34 % |
| **emojis.nvim** | `core.patterns.match_at` | 75.859 | 98 % |
| **recommender.nvim** | `blacklist.is_blacklisted` | 46.848 | 100 % |
| **lib.nvim** | `autocmd.create` | 27.180 | 19 % |
| **cascade.nvim** | `lists.marker.parse` | 10.645 | 33 % |
| **spotlight.nvim** | `core.match.reconcile_window` | 8.182 | 28 % |

Wie schon in der Auswertung vom 05.–12.08. sind die Top-Ausreißer fast alle Render-/Parse-Hotpaths (pro Zeile, pro Redraw, pro Tastendruck), nicht Features, die ein Nutzer bewusst aufruft — `color_my_ascii`s `config.get_char_highlight` und `markdown.nvim`s `highlight_line` dominieren aus demselben Grund wie vorher: Syntax-Highlighting läuft im Hot-Path, jede einzelne Zeile zählt als Aufruf. **Das ist die zentrale Einschränkung für die Priorisierungsfrage weiter unten.**

### Klare Memoisierungs-Kandidaten (≥90 % identisches Argument, ≥50 Aufrufe)

- `filetree.nvim` — `feature`: 86.821× davon 100 % derselbe Aufruf
- `cascade.nvim` — `core.patterns.unordered_class`: 9.205× davon 100 % derselbe Aufruf
- `lsp.nvim` — `completion.blink.spec`: 5.701× davon 100 % derselbe Aufruf
- `lsp.nvim` — `completion.blink.enabled`: 5.608× davon 100 % derselbe Aufruf
- `lsp.nvim` — `completion.register.applies`: 5.608× davon 100 % derselbe Aufruf
- `filetree.nvim` — `features.load`: 5.206× davon 97 % derselbe Aufruf
- `filetree.nvim` — `features.require`: 5.053× davon 100 % derselbe Aufruf
- `filetree.nvim` — `features.ui.breadcrumbs.update`: 4.136× davon 90 % derselbe Aufruf
- `markdown.nvim` — `scope.op_enabled`: 3.307× davon 100 % derselbe Aufruf
- `runtime-analysis.nvim` — `config.validate.check`: 3.092× davon 100 % derselbe Aufruf
- `color_my_ascii.nvim` — `highlighter.highlight_block`: 3.091× davon 99 % derselbe Aufruf
- `cascade.nvim` — `config.get`: 839× davon 91 % derselbe Aufruf
- … 20 weitere, kleinere Kandidaten in den Einzeltabellen unten.

### Ohne Daten

**Keine Telemetrie-Datei in beiden Datensätzen** (nie geladen, auch nicht über Monate): `diff.nvim`, `learn-cli.nvim`, `migrate.nvim`.

**Nur im PC-Datensatz fehlend** (auf der Workstation aber mit echten Zahlen — reines Artefakt des Ein-Tages-Fensters, nicht "ungenutzt"): `emojis.nvim`, `replacer.nvim`.

**Datei da, aber 0 Aufrufe (Workstation, langes Fenster)**: `language.nvim`, `mdview.nvim`, `pdfport.nvim`.

### Zwei Vorbehalte, die du kennen solltest

1. **Rohe Aufrufzahlen sind kein Proxy für "Feature-Wichtigkeit".** Die Top-Ausreißer-Tabelle oben zeigt es deutlich: interne Hotpath-Funktionen (Highlighting, Parsing, Fold-Berechnung) erzeugen um Größenordnungen mehr Aufrufe als tatsächliche Nutzeraktionen (ein Usrcmd, ein Keymap-Druck). Bei `markdown.nvim` z. B. macht `highlight_line` allein 85 % aller Aufrufe aus — die echten Feature-Einstiegspunkte (`bindings.usrcmds.apply`, `hover.trigger`, `core.refs.reconcile`, …) liegen in den zweistelligen bis niedrigen dreistelligen Bereichen. Für die Priorisierungsfrage unten heißt das: **nur an Einstiegspunkt-Funktionen messen** (`bindings.*`, `commands.*`, `handler.*`, Top-Level-Dispatcher), nicht an der Gesamtsumme des Plugins.
2. **Der Workstation-Datensatz ist informativ genug, um harte Nullen zu vertrauen, aber zu dünn, um schwache Signale zu vergleichen.** `diff.nvim`, `learn-cli.nvim`, `migrate.nvim` haben über den gesamten Erfassungszeitraum (bis zu 554 Sessions bei anderen Plugins) buchstäblich keine Telemetriedatei — nie geladen. Das ist ein starkes Signal. Aber ein Unterschied zwischen "12 Aufrufe" und "31 Aufrufe" bei zwei verschiedenen Features ist bei so kleinen Zahlen eher Rauschen als ein echter Wichtigkeits-Unterschied.

---

## color_my_ascii.nvim

Sessions (akkumuliert): 56 · Aufrufe gesamt: 5.907.747 · instrumentierte Funktionen: 95 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 1.048.510 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `config.get_char_highlight` | 2.551.724 | — | — |
| `utils.safe_api.safe_call` | 647.282 | — | — |
| `utils.safe_api.buf_set_extmark` | 634.911 | — | — |
| `utils.safe_api.set_extmark` | 634.911 | — | — |
| `config.get` | 563.793 | — | — |
| `config.get_keyword_languages` | 426.450 | — | — |
| `parser.tokenize_line` | 145.637 | — | — |
| `config.is_function_detection_enabled` | 138.973 | — | — |
| `config.get_unique_language` | 44.099 | — | — |
| `cache_manager.cleanup` | 19.762 | — | — |
| `utils.safe_api.buf_line_count` | 12.371 | — | — |
| `utils.safe_api.is_valid_buffer` | 8.362 | — | — |
| `parser.find_inline_codes` | 7.661 | — | — |
| `parser.scan_blocks_heuristic` | 7.531 | — | — |
| `parser.is_ascii_fence` | 6.380 | — | — |
| `debounce_manager.debounce` | 4.945 | — | — |
| `api.fences.list_blocks` | 4.525 | — | — |
| `fence_hl.clear` | 4.021 | — | — |

… 17 weitere Funktionen mit weniger Aufrufen, siehe Quelldatei.

---

## markdown.nvim

Sessions (akkumuliert): 56 · Aufrufe gesamt: 570.740 · instrumentierte Funktionen: 205 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 205.784 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `hl_options.hl_groups.blockquote.highlight_line` | 485.693 | — | — |
| `core.fold.foldexpr` | 61.917 | — | — |
| `config.feature_enabled` | 6.137 | — | — |
| `scope.enabled` | 3.310 | — | — |
| `scope.op_enabled` | 3.307 | — | — |
| `scope.row_fence_kind` | 3.304 | — | — |
| `core.slug.slugify` | 2.170 | — | — |
| `config.get` | 1.173 | — | — |
| `hover.float.close` | 739 | — | — |
| `core.slug.heading_anchors` | 382 | — | — |
| `hover.hide` | 376 | — | — |
| `hover.link_under_cursor` | 288 | — | — |
| `hover.show` | 288 | — | — |
| `hover.trigger` | 288 | — | — |
| `core.refs.baseline` | 188 | — | — |
| `hover.classify.classify` | 100 | — | — |
| `hover.float.open` | 100 | — | — |
| `hover.float.is_open` | 99 | — | — |

… 16 weitere Funktionen mit weniger Aufrufen, siehe Quelldatei.

---

## filetree.nvim

Sessions (akkumuliert): 50 · Aufrufe gesamt: 257.105 · instrumentierte Funktionen: 456 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 48.694 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `feature` | 86.821 | — | — |
| `features.nav.cwd_mode.badge` | 86.821 | — | — |
| `adapter.neotree.is_open` | 14.568 | — | — |
| `adapter.neotree.get_winid` | 8.707 | — | — |
| `adapter.neotree.get_bufnr` | 5.777 | — | — |
| `features.load` | 5.206 | — | — |
| `features.require` | 5.053 | — | — |
| `features.nav.cwd_mode.resolve` | 4.813 | — | — |
| `features.nav.cwd_mode.pinned` | 4.591 | — | — |
| `util.root.find` | 4.591 | — | — |
| `adapter.neotree.get_current_node` | 4.198 | — | — |
| `features.ui.breadcrumbs.update` | 4.136 | — | — |
| `features.nav.cwd_mode.refresh_indicator` | 4.004 | — | — |
| `adapter.neotree.refresh` | 2.923 | — | — |
| `util.buffer.is_stray_no_name` | 2.778 | — | — |
| `util.path.slashify` | 1.411 | — | — |
| `refs.pathutil.abs` | 1.399 | — | — |
| `refs.pathutil.key` | 1.154 | — | — |

… 105 weitere Funktionen mit weniger Aufrufen, siehe Quelldatei.

---

## lib.nvim

Sessions (akkumuliert): 242 · Aufrufe gesamt: 146.386 · instrumentierte Funktionen: 0 · Modus: counting
Heute zusätzlich (45 Session(s) seit 10:44): 26.733 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `autocmd.create` | 27.180 | — | — |
| `usercmd.create` | 25.836 | — | — |
| `notify.create` | 23.841 | — | — |
| `lazy.module` | 23.533 | — | — |
| `lazy.require` | 23.533 | — | — |
| `composer.verb` | 6.253 | — | — |
| `autocmd.group` | 5.793 | — | — |
| `composer.register_type` | 3.097 | — | — |
| `memo.fn` | 1.939 | — | — |
| `autocmd.get_augroup` | 1.694 | — | — |
| `hl.set` | 963 | — | — |
| `autocmd.norm_pattern` | 726 | — | — |
| `deps.show_once` | 599 | — | — |
| `autocmd.norm_events` | 484 | — | — |
| `system.setup` | 242 | — | — |
| `system_info.create_usercmd` | 242 | — | — |
| `unique_table.unique` | 159 | — | — |
| `run_argv.run_blocking_captured` | 104 | — | — |

… 6 weitere Funktionen mit weniger Aufrufen, siehe Quelldatei.

---

## emojis.nvim

Sessions (akkumuliert): 7 · Aufrufe gesamt: 77.418 · instrumentierte Funktionen: 42 · Modus: counting + args
Heute (PC-Export) noch nicht geladen worden.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `core.patterns.match_at` | 75.859 | — | — |
| `core.ops._clear_line` | 1.433 | — | — |
| `config.get` | 36 | — | — |
| `actions.edit` | 18 | — | — |
| `core.ops.clear` | 18 | — | — |
| `core.scope.resolve` | 18 | — | — |
| `util.lib.notifier` | 18 | — | — |
| `util.notify.info` | 18 | — | — |

---

## recommender.nvim

Sessions (akkumuliert): 82 · Aufrufe gesamt: 46.876 · instrumentierte Funktionen: 22 · Modus: counting + args
Heute zusätzlich (2 Session(s) seit 10:44): 0 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `blacklist.is_blacklisted` | 46.848 | — | — |
| `float.rendering.close` | 5 | — | — |
| `float.rendering.is_open` | 5 | — | — |
| `float.keymaps.attach_extra` | 3 | — | — |
| `float.keymaps.make_on_select` | 3 | — | — |
| `float.rendering.open` | 3 | — | — |
| `project.find_files` | 3 | — | — |
| `project.read_lines` | 3 | — | — |
| `project.supports_cwd` | 3 | — | — |

---

## cascade.nvim

Sessions (akkumuliert): 58 · Aufrufe gesamt: 32.463 · instrumentierte Funktionen: 155 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 14.364 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `lists.marker.parse` | 10.645 | — | — |
| `core.patterns.unordered_class` | 9.205 | — | — |
| `util.lib.map` | 3.025 | — | — |
| `lists.marker.is_blank_line` | 3.019 | — | — |
| `lists.marker.is_continuation` | 3.019 | — | — |
| `config.get` | 839 | — | — |
| `lists.marker.blank_run` | 735 | — | — |
| `lists.renumber.tree` | 555 | — | — |
| `core.context.writable` | 277 | — | — |
| `lists.renumber.at` | 218 | — | — |
| `lists.format.apply` | 121 | — | — |
| `lists.format.list_pat` | 121 | — | — |
| `_move` | 98 | — | — |
| `lists.move.line` | 98 | — | — |
| `lists.renumber.all` | 97 | — | — |
| `lists.transform.block_range` | 78 | — | — |
| `core.context.new` | 72 | — | — |
| `core.treesitter.in_skip_node` | 70 | — | — |

… 18 weitere Funktionen mit weniger Aufrufen, siehe Quelldatei.

---

## spotlight.nvim

Sessions (akkumuliert): 50 · Aufrufe gesamt: 28.746 · instrumentierte Funktionen: 132 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 10.028 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `core.match.reconcile_window` | 8.182 | — | — |
| `core.registry.all` | 8.182 | — | — |
| `core.registry.apply_to_window` | 8.182 | — | — |
| `core.match.forget_window` | 2.394 | — | — |
| `core.registry.remove_for_buffer` | 1.434 | — | — |
| `config.get` | 172 | — | — |
| `core.registry.snapshot` | 40 | — | — |
| `persist.flush` | 40 | — | — |
| `persist.save_now` | 40 | — | — |
| `util.lib.debug` | 40 | — | — |
| `util.lib.try_require` | 40 | — | — |

---

## lsp.nvim

Sessions (akkumuliert): 128 · Aufrufe gesamt: 23.004 · instrumentierte Funktionen: 235 · Modus: counting + args + timing
Heute zusätzlich (45 Session(s) seit 10:44): 36.475 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `completion.blink.spec` | 5.701 | 0.01 | — |
| `completion.register.spec` | 5.701 | 0.00 | — |
| `completion.blink.enabled` | 5.608 | 0.02 | — |
| `completion.register.applies` | 5.608 | 0.00 | — |
| `config.pack.completion` | 132 | — | — |
| `config.pack.opts` | 132 | — | — |
| `completion.blink.get_completions` | 92 | 1.78 | — |
| `bindings.keymaps.rebind_buffer_local` | 8 | 0.02 | — |
| `core.workspace_diagnostics.enabled` | 8 | 0.00 | — |
| `core.workspace_diagnostics.schedule_populate` | 4 | 0.01 | — |
| `languages.documentation.markdown.setup_reference_hl` | 4 | 0.02 | — |
| `config.get` | 2 | 0.00 | — |
| `completion.blink.execute` | 1 | 7.30 | — |
| `completion.register.picked` | 1 | 5.68 | — |
| `completion.usage.bump` | 1 | 5.65 | — |
| `status` | 1 | 0.24 | — |

---

## documentation.nvim

Sessions (akkumuliert): 2 · Aufrufe gesamt: 10.764 · instrumentierte Funktionen: 208 · Modus: counting
Heute zusätzlich (41 Session(s) seit 10:44): 2.368.131 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `core.lang.erlang.is_source` | 829 | — | — |
| `core.lang.kotlin.is_source` | 829 | — | — |
| `core.lang.scala.is_source` | 829 | — | — |
| `core.lang.swift.is_source` | 829 | — | — |
| `core.lang.csharp.is_source` | 803 | — | — |
| `core.lang.dart.is_source` | 803 | — | — |
| `core.lang.elixir.is_source` | 803 | — | — |
| `core.lang.haskell.is_source` | 803 | — | — |
| `core.lang.ocaml.is_source` | 803 | — | — |
| `core.lang.php.is_source` | 803 | — | — |
| `core.lang.ruby.is_source` | 803 | — | — |
| `core.lang.asm.is_source` | 185 | — | — |
| `core.lang.go.is_source` | 185 | — | — |
| `core.lang.python.is_source` | 185 | — | — |
| `core.lang.rust.is_source` | 185 | — | — |
| `core.lang.zig.is_source` | 185 | — | — |
| `core.lang.java.is_source` | 34 | — | — |
| `config.build` | 31 | — | — |

… 27 weitere Funktionen mit weniger Aufrufen, siehe Quelldatei.

---

## insights.nvim

Sessions (akkumuliert): 82 · Aufrufe gesamt: 4.188 · instrumentierte Funktionen: 31 · Modus: counting + args
Heute zusätzlich (34 Session(s) seit 10:44): 2.627 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `util.notify.create` | 3.997 | — | — |
| `devserver.kill_all` | 78 | — | — |
| `config.get` | 44 | — | — |
| `devserver.chan_cmd` | 23 | — | — |
| `devserver.consider` | 23 | — | — |
| `devserver.match` | 23 | — | — |

---

## debugging.nvim

Sessions (akkumuliert): 83 · Aufrufe gesamt: 3.764 · instrumentierte Funktionen: 34 · Modus: counting + args + timing
Heute zusätzlich (6 Session(s) seit 10:44): 574 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `views.display.get_window_tag` | 2.723 | 0.01 | — |
| `views.utils.is_target_view` | 868 | 0.01 | — |
| `views.utils.make_focusable` | 52 | 0.01 | — |
| `views.utils.ensure_bottom` | 27 | 0.01 | — |
| `views.utils.focus_and_bottom` | 27 | 0.67 | — |
| `views.utils.force_focus` | 27 | 0.48 | — |
| `views.display.execute_and_refresh` | 19 | 82.12 | — |
| `views.display.find_window_by_tag` | 19 | 0.14 | — |
| `views.display.refresh_log_view` | 2 | 4.00 | — |

---

## runtime-analysis.nvim

Sessions (akkumuliert): 554 · Aufrufe gesamt: 3.097 · instrumentierte Funktionen: 11 · Modus: counting + args
Heute zusätzlich (45 Session(s) seit 10:44): 228 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `config.validate.check` | 3.092 | — | — |
| `startup.is_running` | 2 | — | — |
| `startup.lines` | 1 | — | — |
| `startup.report` | 1 | — | — |
| `startup.stop` | 1 | — | — |

---

## gopath.nvim

Sessions (akkumuliert): 50 · Aufrufe gesamt: 2.378 · instrumentierte Funktionen: 97 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 150 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `config.get` | 510 | — | — |
| `truncated.cache.needs_refresh` | 486 | — | — |
| `util.log.debug` | 253 | — | — |
| `truncated.cache.build_async` | 252 | — | — |
| `util.safe_notify.safe_notify_defer` | 252 | — | — |
| `truncated.cache._finalize_build` | 251 | — | — |
| `truncated.cache._save_to_disk` | 251 | — | — |
| `util.path.invalidate_caches` | 107 | — | — |
| `util.cross.to_forward` | 2 | — | — |
| `util.path.exists` | 2 | — | — |
| `commands.resolve_and_open` | 1 | — | — |
| `open.open` | 1 | — | — |
| `providers.builtin.expand_cfile` | 1 | — | — |
| `resolve.resolve_at_cursor` | 1 | — | — |
| `resolvers.common.filetoken.resolve` | 1 | — | — |
| `resolvers.common.help.resolve` | 1 | — | — |
| `util.cross.to_native` | 1 | — | — |
| `util.location.create_range` | 1 | — | — |

… 4 weitere Funktionen mit weniger Aufrufen, siehe Quelldatei.

---

## replacer.nvim

Sessions (akkumuliert): 4 · Aufrufe gesamt: 1.562 · instrumentierte Funktionen: 74 · Modus: counting + args
Heute (PC-Export) noch nicht geladen worden.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `encoding.strip_cr` | 1.432 | — | — |
| `pickers.common.format_display` | 61 | — | — |
| `encoding.strip_bom` | 15 | — | — |
| `pickers.common.preview_lines_with_pos` | 15 | — | — |
| `apply.apply_matches` | 5 | — | — |
| `history.add` | 5 | — | — |
| `history.load` | 5 | — | — |
| `pickers.common.notify_result` | 5 | — | — |
| `pickers.common.register_which_key` | 5 | — | — |
| `util.notify.info` | 5 | — | — |
| `util.notify.notify` | 5 | — | — |
| `command.parse_request` | 1 | — | — |
| `command.resolve_scope` | 1 | — | — |
| `config.resolve` | 1 | — | — |
| `rg.collect_async` | 1 | — | — |

---

## images.nvim

Sessions (akkumuliert): 57 · Aufrufe gesamt: 372 · instrumentierte Funktionen: 46 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 2 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `config.get` | 171 | — | — |
| `scale.anchor_box` | 117 | — | — |
| `scale.fit_cells` | 57 | — | — |
| `config.setup` | 8 | — | — |
| `calibration.load` | 4 | — | — |
| `cell.parse` | 4 | — | — |
| `calibration.as_config` | 3 | — | — |
| `calibration.path` | 2 | — | — |
| `cell.query` | 2 | — | — |
| `cell.reset` | 2 | — | — |
| `calibration.save` | 1 | — | — |
| `cell.pixels` | 1 | — | — |

---

## sessions.nvim

Sessions (akkumuliert): 73 · Aufrufe gesamt: 232 · instrumentierte Funktionen: 29 · Modus: counting + args
Heute zusätzlich (33 Session(s) seit 10:44): 579 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `core.mark_dirty` | 230 | — | — |
| `core.save` | 2 | — | — |

---

## fileops.nvim

Sessions (akkumuliert): 83 · Aufrufe gesamt: 194 · instrumentierte Funktionen: 67 · Modus: counting + args + timing
Heute zusätzlich (6 Session(s) seit 10:44): 25 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `ops.file.ensure_parent` | 174 | 0.07 | — |
| `config.get` | 6 | — | — |
| `ops.cycle.get_root_dir` | 3 | — | — |
| `ops.cycle.navigate` | 3 | — | — |
| `ops.cycle.open_path` | 3 | — | — |
| `util.notify.report` | 3 | — | — |
| `ops.file.copy_path` | 1 | — | — |
| `util.notify.info` | 1 | — | — |

---

## reposcope.nvim

Sessions (akkumuliert): 2 · Aufrufe gesamt: 124 · instrumentierte Funktionen: 240 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 63 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `utils.repos.is_git_repo` | 76 | — | — |
| `ui.actions.status_view.render` | 14 | — | — |
| `utils.debug.is_dev_mode` | 14 | — | — |
| `utils.progress.create` | 8 | — | — |
| `utils.repo_actions.push` | 3 | — | — |
| `ui.actions.status_view.show` | 2 | — | — |
| `ui.actions.status_view.summary` | 2 | — | — |
| `utils.repo_actions.pull` | 2 | — | — |
| `utils.repo_status.status_all` | 2 | — | — |
| `utils.repo_actions.fetch` | 1 | — | — |

---

## cmdlog.nvim

Sessions (akkumuliert): 71 · Aufrufe gesamt: 111 · instrumentierte Funktionen: 20 · Modus: counting + args
Heute zusätzlich (36 Session(s) seit 10:44): 56 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `core.store.save_json` | 43 | — | — |
| `core.project_history.get_git_root` | 20 | — | — |
| `core.project_history.record` | 20 | — | — |
| `core.stats.record` | 20 | — | — |
| `core.store.load_json` | 5 | — | — |
| `core.errors.record` | 3 | — | — |

---

## open.nvim

Sessions (akkumuliert): 9 · Aufrufe gesamt: 64 · instrumentierte Funktionen: 33 · Modus: counting + args
Heute zusätzlich (8 Session(s) seit 10:44): 87 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `config.is_debug` | 22 | — | — |
| `config.get` | 12 | — | — |
| `context.resolve` | 8 | — | — |
| `registry.dispatch` | 4 | — | — |
| `registry.get` | 4 | — | — |
| `context.default_target` | 2 | — | — |
| `context.gather` | 2 | — | — |
| `context.with_cache` | 2 | — | — |
| `integrations.menu.items` | 2 | — | — |
| `integrations.menu.submenu` | 2 | — | — |
| `registry.list_keys` | 2 | — | — |
| `platform.get` | 1 | — | — |
| `util.run_detached` | 1 | — | — |

---

## buffer-ctx.nvim

Sessions (akkumuliert): 10 · Aufrufe gesamt: 52 · instrumentierte Funktionen: 86 · Modus: counting + args
Heute zusätzlich (20 Session(s) seit 10:44): 162 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `commands._dispatch` | 9 | — | — |
| `ops.filepath._format_segments` | 8 | — | — |
| `ops.filepath.get_path` | 8 | — | — |
| `ops.filepath.parse_args` | 8 | — | — |
| `util.clip.copy` | 8 | — | — |
| `util.notify.info` | 8 | — | — |
| `ops.boilerplate.get` | 1 | — | — |
| `ops.boilerplate.list_keys` | 1 | — | — |
| `util.cursor.insert_lines` | 1 | — | — |

---

## pickers.nvim

Sessions (akkumuliert): 253 · Aufrufe gesamt: 52 · instrumentierte Funktionen: 36 · Modus: counting + args
Heute zusätzlich (45 Session(s) seit 10:44): 12 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `config.get` | 46 | — | — |
| `history.dir` | 3 | — | — |
| `history.fzf_opts` | 3 | — | — |

---

## sandbox.nvim

Sessions (akkumuliert): 50 · Aufrufe gesamt: 40 · instrumentierte Funktionen: 517 · Modus: counting + args
Heute zusätzlich (6 Session(s) seit 10:44): 5 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `logger.flush` | 40 | — | — |

---

## github_stats.nvim

Sessions (akkumuliert): 37 · Aufrufe gesamt: 37 · instrumentierte Funktionen: 143 · Modus: counting + args
Heute zusätzlich (22 Session(s) seit 10:44): 30.140 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `config.get` | 37 | — | — |

---

## dap.nvim

Sessions (akkumuliert): 24 · Aufrufe gesamt: 6 · instrumentierte Funktionen: 80 · Modus: counting + args
Heute zusätzlich (31 Session(s) seit 10:44): 9 Aufrufe.

| Funktion | Aufrufe | Ø ms | Fehler |
| --- | ---: | ---: | ---: |
| `config.get` | 2 | — | — |
| `integrations.menu.items` | 2 | — | — |
| `integrations.menu.submenu` | 2 | — | — |

---

## language.nvim

Sessions (akkumuliert): 50 · Aufrufe gesamt: 0 · instrumentierte Funktionen: 17 · Modus: counting
Heute zusätzlich (6 Session(s) seit 10:44): 3 Aufrufe.

*(keine instrumentierten Aufrufe aufgezeichnet)*

---

## mdview.nvim

Sessions (akkumuliert): 56 · Aufrufe gesamt: 0 · instrumentierte Funktionen: 128 · Modus: counting
Heute zusätzlich (6 Session(s) seit 10:44): 0 Aufrufe.

*(keine instrumentierten Aufrufe aufgezeichnet)*

---

## pdfport.nvim

Sessions (akkumuliert): 29 · Aufrufe gesamt: 0 · instrumentierte Funktionen: 70 · Modus: counting
Heute zusätzlich (1 Session(s) seit 10:44): 0 Aufrufe.

*(keine instrumentierten Aufrufe aufgezeichnet)*

---

## Ohne Daten

Kein Telemetrie-File in keinem der beiden Datensätze: `diff.nvim`, `learn-cli.nvim`, `migrate.nvim`.
