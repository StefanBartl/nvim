# Neue Features & Bindings — Commits der letzten 24h (Stand 2026-09-24)

Zusammenfassung aller `feat`/relevanten `fix`-Commits der letzten 24 Stunden über
alle Plugins unter `$REPOS_DIR/repos`. Reine `docs: link back to the wkd family
site`-Commits (in praktisch jedem Plugin) sind ausgelassen — kosmetischer
Bulk-Commit ohne Testrelevanz.

---

## buffer-ctx.nvim

### feat(reveal): `:RevealInFm` / `:OpenInBrowser` für den aktuellen Buffer
Zwei neue argumentlose Commands, analog zum bestehenden mark/format-Subsystem.

- `:RevealInFm` → öffnet den Dateimanager auf dem aktuellen Buffer (über lib.nvim's `cross.reveal_in_fm`, dieselbe Route wie filetree.nvim `<leader>fm`).
- `:OpenInBrowser` → öffnet den Buffer-Pfad im Browser, bevorzugt open.nvim's Handler, sonst `vim.ui.open`-Fallback.
- **Neue Default-Keymaps:** `<leader>of` (RevealInFm), `<leader>ob` (OpenInBrowser) — bewusst *nicht* `<leader>fm`, das ist global schon "Format file".
- Deaktivierbar über neue Config-Tabelle `reveal = false`.

**Testen:** Buffer mit Datei öffnen, `<leader>of` drücken → Dateimanager sollte sich mit der Datei markiert öffnen. `<leader>ob` → Standardbrowser öffnet die Datei (bzw. bei Markdown ggf. Preview).

### feat(commands): `markdownlink`/`imagepaste` Shims in `:Insert`/`:Copy`
- `:Insert markdownlink` / `:Copy markdownlink` — baut einen Markdown-Link zum aktuellen Buffer-Pfad (nutzt markdown.nvim falls vorhanden, sonst Fallback `[title](path)`).
- `:Insert imagepaste` — nur als Insert-Route (kein `:Copy`-Pendant), delegiert an images.nvim's Paste-Feature (Clipboard → Bild einfügen).

**Testen:** In einem Markdown-Buffer `:Insert markdownlink` ausführen → Link zur aktuellen Datei wird an der Cursorposition eingefügt. `:Insert imagepaste` mit einem Bild in der Zwischenablage → Bild wird eingefügt/referenziert.

### refactor(commands): `markdownlink` → `mdlink` umbenannt
Nachfolgecommit (Konsistenz-Pass): der Subcommand-Token heißt jetzt `mdlink` (wie bei filetree.nvim `:Filetree mdlink` und mdview.nvim `:MDLinksView`). **Falls du `markdownlink` irgendwo verwendet hast, umstellen auf `mdlink`.**

### feat(filepath): neuer `repos`-Modus, relativ zu `$REPOS_DIR`
Neuer Command `:CopyFilepathRepos` (analog zu `:CopyFilepathAbsolute`/`:CopyFilepathRelative`), kopiert den Pfad relativ zu `$REPOS_DIR`. Wirft einen Fehler statt still auf cwd zurückzufallen, wenn `$REPOS_DIR` nicht gesetzt ist.

**Testen:** In einer Datei unter `$REPOS_DIR` `:CopyFilepathRepos` ausführen → Zwischenablage sollte den `$REPOS_DIR`-relativen Pfad enthalten.

### fix(reveal): pcall-Guard für open.nvim's Browser-Handler
Kein Test nötig — reine Absicherung gegen einen crashenden Custom-Handler; jetzt gibt's eine `notify.warn` statt Absturz.

---

## fileops.nvim

### feat(delete): Bestätigung statt Ablehnung bei ungesicherten Änderungen/vorhandenem Ziel
`:File delete` (und die delete/delete_force-Keymaps) fragt jetzt bei einem geänderten Buffer per `ui.kit.confirm` nach, statt nur zu verweigern und `:File!` einzufordern. "Ja" löscht sofort mit Force. Gleiche Behandlung bei rename/move/duplicate/copy auf ein existierendes Ziel ohne `!` — Bestätigungsdialog bietet direkt das Überschreiben an.

**Testen:** Buffer mit ungesicherten Änderungen öffnen, Löschen-Keymap auslösen → sollte jetzt ein Confirm-Dialog erscheinen statt einer Fehlermeldung. "Nein"/Abbruch → nichts wird gelöscht.

---

## filetree.nvim (dieses Repo)

### fix(link_marker, cwd_sync): Symlink-Icons beim Attach zeichnen; toter reveal-active-Check entfernt
Symlink-Icon wurde vorher erst gezeichnet, wenn der Tree-Buffer fokussiert/bewegt wurde. Jetzt wird es direkt beim Attach gezeichnet.

**Testen:** Tree mit Symlinks im Hintergrund öffnen (ohne ihn zu fokussieren) → Symlink-Icons sollten sofort sichtbar sein, nicht erst nach Fokuswechsel.

### fix(auto_reveal): Re-Root für Datei außerhalb des aktuellen Tree-Roots
Neue Option `follow_root` (Default `true`) in `features.auto_reveal`: Wenn die aktuelle Datei außerhalb des Tree-Roots liegt, rootet der Tree jetzt automatisch um (über dieselbe root_markers → project_root → parent-dir-Logik wie cwd_sync). Rührt Neovims eigenes `cwd` nicht an.

**Testen:** Tree auf Projekt A geöffnet, dann eine Datei aus Projekt B öffnen (z.B. via Picker) → Tree sollte automatisch auf Projekt B umrooten. Mit `follow_root = false` in der Config sollte das alte Verhalten (kein Re-Root) zurückkehren.

### feat(open_variants): `<S-CR>` klappt eine `group_empty_dirs`-Merge-Directory ein
Bei neo-tree's "merged directory"-Darstellung (verschachtelte leere Ordner zu einer Zeile zusammengefasst, z.B. "personal/All/Finish") kollabierte `<S-CR>` vorher nicht richtig zurück. Jetzt fällt `<S-CR>` auf den nächsten kollabierbaren Vorfahren zurück (wie neo-trees eigenes `C`), bei Root-Chain auf einen Refresh.

**Testen:** Einen Ordnerpfad mit mehreren verschachtelten Ordnern anlegen, die nur je einen Unterordner enthalten (damit neo-tree sie zu einer Zeile mergt), diese Merge-Zeile mehrfach mit `<CR>` aufklappen, dann `<S-CR>` drücken → sollte wieder zur gemergten "personal/All/Finish"-Ansicht zurückspringen statt tiefer zu gehen.

### fix(cursor_hide): `cursorline` bleibt erzwungen an, solange der Blockcursor versteckt ist
Absicherung gegen andere Plugins/Colorschemes, die `cursorline` ausschalten, während der Cursor in der Tree versteckt ist (sonst kein sichtbarer Positionszeiger mehr). Opt-out via `force_cursorline = false`.

**Testen:** Nur relevant, falls du ein Colorscheme/Plugin nutzt, das `cursorline` global toggled — schwer isoliert zu testen, eher beobachten ob der Cursor im Tree je "verschwindet".

---

## gitsuite.nvim

### fix(ui): `:Git ui` `<Tab>`-Completion listet kein nicht-installiertes lazygit/neogit mehr
`:Git ui <Tab>` filtert jetzt lazygit/neogit raus, wenn nicht installiert (via `executable()`/adapter.resolve()). `diffview` bleibt immer gelistet (degradiert zu diff.nvim-Split). Nachfolgecommit korrigiert, dass `:checkhealth gitsuite` dadurch fälschlich einen ERROR für einen fehlenden optionalen Adapter meldete (jetzt wieder nur INFO).

**Testen:** `:Git ui ` + `<Tab>` in einer Umgebung ohne lazygit → lazygit sollte nicht mehr in der Completion-Liste auftauchen. `:checkhealth gitsuite` sollte weiterhin nur INFO (nicht ERROR) für den fehlenden Adapter zeigen. **Benötigt lib.nvim ≥ 96f8809.**

---

## gopath.nvim

Der aktivste Plugin heute — viele neue Features rund um `env-shorten`, `probe`, Menü-Integration.

### feat(env-shorten): `GopathToNvimDir`, ein `stdpath('config')`-bewusstes `$VAR`
Neuer Command `:GopathToNvimDir` / `:Gopath to-nvim-dir` — schreibt Vorkommen des absoluten Nvim-Config-Pfads in `$NVIM_CONFIG_DIR` um, ohne dass eine echte Env-Var gesetzt sein muss (via neuer `shorten_known_dirs`-Map). Die Rückrichtung (`gF`) löst `$NVIM_CONFIG_DIR` transparent wieder auf.

**Testen:** In einer Zeile mit dem absoluten Pfad zu deiner Nvim-Config `:GopathToNvimDir` ausführen → sollte zu `$NVIM_CONFIG_DIR/...` werden. Cursor auf `$NVIM_CONFIG_DIR/...` setzen und `gF` → sollte die Datei öffnen, obwohl keine echte Env-Var exportiert ist.

### feat(env-shorten): Visual-Range + relative Markdown-Link-Auflösung
`:GopathToReposDir` / `:GopathToNvimDir` nehmen jetzt eine Visual-Range (`:'<,'>GopathToNvimDir`) — nur der markierte Bereich wird umgeschrieben. Zusätzlich erkennen beide Commands jetzt relative Pfade *innerhalb* eines Markdown-Links (`[text](path)` / `![alt](path)`) auch ohne Selektion und lösen sie relativ zum Buffer-Verzeichnis auf.

**Testen:** Text markieren, der einen absoluten Pfad enthält, `:GopathToNvimDir` im Visual-Mode ausführen → nur die Selektion wird ersetzt. In einer Markdown-Datei unter einem konfigurierten Root ein `![x](./assets/a.png)` einfügen und `:GopathToNvimDir` (ohne Selektion) ausführen → sollte zu `![x]($NVIM_CONFIG_DIR/.../assets/a.png)` werden.

### fix(env-shorten): URLs werden nie mehr als relativer Pfad behandelt
Bugfix zum vorigen Feature: ein Markdown-Link wie `[GitHub](https://github.com/foo/bar)` wurde fälschlich in den Buffer-Pfad hineingejoint und kaputt umgeschrieben. Jetzt werden URLs (per Schema/TLD-Erkennung) explizit ausgeschlossen.

**Testen:** `[GitHub](https://github.com/foo/bar)` in einer Datei unter einem konfigurierten Root, `:GopathToNvimDir` ausführen → Link sollte unverändert bleiben.

### feat(menu): `gopath.integrations.menu` — Rechtsklick-Eintrag "Paths"
Neue Kontextmenü-Integration (Pattern-B, wie open.nvim/filetree.nvim's eigene Menüs). Löst die Cursorposition auf, oder — falls gerade eine Visual-Selektion aktiv ist — die Selektion via `gopath.resolve_selection`. Einträge: "Open", plus "Reveal in File Manager" / "Reveal in filetree.nvim" für Dateien.

**Testen:** Rechtsklick auf ein `$VAR`/Pfad-Token oder eine URL im Buffer → Kontextmenü sollte "Paths"-Untermenü mit Open/Reveal-Optionen zeigen. Mit aktiver Visual-Selektion eines Teilstrings sollte es ebenfalls funktionieren.

### feat(probe): Reveal einer (Teil-)Selektion in filetree.nvim / Dateimanager
`:GopathProbe filetree` / `:GopathProbe explorer` (bzw. `open_cmd`-Option) — die Selektions-basierten Probe-Modi unterstützen jetzt dieselben Reveal-Modi wie die Cursor-basierten `gM`/`gT`-Keymaps.

**Testen:** Teil eines Pfads visuell markieren, `:GopathProbe filetree` ausführen → sollte den Pfad in filetree.nvim fokussieren statt einen Buffer zu öffnen.

### feat(probe): Direkte Auflösung einer partiellen `$VAR`/URL-Selektion
`:GopathProbe` (`<leader>pp`) erkennt jetzt auch eine nur teilweise markierte `$VAR/rest`-Referenz oder URL direkt, statt nur über die (langsamere) Tailsearch-Fallback-Suche.

**Testen:** Nur einen Teil von `$REPOS_DIR/foo/bar` markieren (z.B. nur `REPOS_DIR/foo`) und `<leader>pp` drücken → sollte trotzdem korrekt auflösen.

### feat(open): neuer "filetree"-Modus — `gT` fokussiert aufgelöste Pfade in filetree.nvim
`gT` (analog zu `gM` für den Dateimanager) fokussiert den aufgelösten Pfad direkt in filetree.nvim's Sidebar, ohne den Editor zu verlassen. Soft-Dependency — warnt statt Fehler, wenn filetree.nvim nicht installiert/geladen ist.

**Testen:** Cursor auf einen erkennbaren Pfad/Token setzen, `gT` drücken → filetree.nvim sollte sich öffnen und die Datei fokussieren.

### fix(alternate): Ablehnen eines Vorschlags bietet weiterhin Create-on-Missing an
Vorher: "did you mean X?"-Picker abgebrochen → man musste `gF` neu auslösen, um den Create-Dialog für den ursprünglich getippten Pfad zu bekommen. Jetzt fällt es direkt durch zum Create-Angebot.

**Testen:** `gF` auf einem nicht existierenden, aber ähnlichen Pfad auslösen, den Alternate-Vorschlag mit `<Esc>`/Abbruch ablehnen → sollte direkt das "Create file?"-Angebot für den Originalpfad zeigen.

### fix(create): Nachfragen statt "Create file" anbieten, wenn der aufgelöste Pfad ein Verzeichnis ist
Bei einem existierenden Verzeichnis wird jetzt gefragt: Datei darin anlegen, oder in filetree.nvim öffnen — statt fälschlich "Create file" anzubieten.

**Testen:** `gF` auf einem Pfad-Token, das zu einem existierenden Ordner auflöst → Dialog mit "Datei erstellen"/"In filetree öffnen" statt Fehler.

### fix: diverse Bugs/Ineffizienzen aus Session-Review
- Linewise-Visual-Mode (`V`) in `menu.lua` wählte vorher ein zufälliges Zeichen statt der Selektion — jetzt korrekt ausgeschlossen/fällt auf Cursor-Pipeline zurück.
- Rechtsklick-Menü blockierte bis zu 200ms durch den LSP-Provider bei jedem Klick — jetzt übersprungen (nur treesitter/builtin).
- "Create file in this folder"-Prompt erlaubte `..`-Segmente zum Verzeichnis-Escape — jetzt abgelehnt.

**Testen:** Kein direkter Bindings-Test nötig, eher Verhaltens-Absicherung. Rechtsklick-Menü sollte jetzt spürbar ohne Verzögerung erscheinen.

### fix(open): pcall-Guard gegen werfenden filetree.nvim-Adapter — keine funktionale Änderung, nur Absicherung.

---

## hover.nvim

### feat(directory): Interaktive Mini-Filetree-Navigation in einem Directory-Hover
Ein Directory-Hover zeigte vorher nur die Root-Ebene statisch an. Jetzt navigierbar, ohne dass der Float den Fokus bekommt:

- `h`/`j`/`k`/`l` (nav_keys) steuern die Mini-Tree-Navigation: hoch/runter bewegt die Auswahl, links geht zum Elternverzeichnis, rechts öffnet den Eintrag.
- `<LeftMouse>` wählt/öffnet den Eintrag unter dem Mauszeiger; ein Klick daneben wird normal durchgereicht.
- Datei öffnet als echter Buffer im Ursprungsfenster; Unterordner wird die neue Listing-Ansicht.

**Testen:** Cursor auf einen Verzeichnispfad/Token setzen, Hover forciert öffnen (z.B. via `<leader>...`-Keymap, siehe `docs/BINDINGS.md`), dann mit `j`/`k` navigieren, `l` auf einen Unterordner drücken → sollte in den Unterordner wechseln, `h` sollte zurück zum Elternordner gehen.

### fix(directory): Symlink-Verzeichnisse korrekt aufgelöst; fehlgeschlagenes Öffnen wird gemeldet
Symlinks wurden vorher immer als Datei klassifiziert (versucht `:edit` statt Listing). Jetzt korrekt über `fs_stat` aufgelöst. Ein fehlgeschlagenes `:edit` (z.B. `nohidden` + ungesicherte Änderungen) wird jetzt über `hover.notify` gemeldet statt still verschluckt.

**Testen:** Symlink auf ein Verzeichnis im Directory-Hover aktivieren → sollte als Verzeichnis gelistet werden, nicht versuchen es als Datei zu öffnen.

### fix(show): Unforcierter Re-Trigger schließt nicht mehr einen explizit angeforderten Hover
Jede Aktion, die eine geborgte Taste nutzt (Scroll, Resize, Directory-Nav), re-armt `CursorHold` — vorher schloss das den gerade offenen, explizit geöffneten Hover sofort wieder. Jetzt bleibt er offen.

**Testen:** Hover forciert öffnen, dann innerhalb des Hovers scrollen/navigieren und kurz warten (CursorHold-Zeit abwarten) → Hover sollte offen bleiben statt sich zu schließen.

---

## images.nvim

### feat(paste): `path=relative|absolute|repos|<prefix>` für `:Image paste`
Neue optionale Pfad-Modi für den eingefügten Markdown-Link (unabhängig vom tatsächlichen Speicherort der Datei): `relative` (Default, unverändert), `absolute`, `repos` ($REPOS_DIR-relativ), oder ein beliebiger String als literales Präfix. Neue Config-Option `paste.default_path_mode` (Default `"relative"`); auf `false` gesetzt fragt interaktiv per `ui.kit.select`.

**Testen:** `:Image paste path=repos` mit einem Bild in der Zwischenablage in einer Datei unter `$REPOS_DIR` ausführen → eingefügter Markdown-Link sollte `$REPOS_DIR`-relativ sein statt buffer-relativ.

---

## lib.nvim

### fix(composer): `route.check` in `check` + `available` aufgeteilt
Infrastruktur-Fix, betrifft alle Plugins, die lib.nvim's Composer für `<Tab>`-Completion + Routen nutzen (gitsuite.nvim). `route.available` steuert jetzt nur noch `<Tab>`-Completion-Ausblendung, `route.check` bleibt exklusiv für `checkhealth`/`check_all` — verhindert, dass ein optionaler fehlender Backend fälschlich als ERROR gemeldet wird.

**Kein direkter Bindings-Test** — wirkt sich indirekt über gitsuite.nvim aus (siehe oben).

---

## pickers.nvim

### feat(builtins): `git_status_marks` (später umbenannt zu `git_status_filtered`) — Staged/Unstaged-Dateiliste
Neuer eigener Builtin-Picker (nicht der reine Passthrough des Engine-eigenen git-status-Pickers): listet uncommitted Files, filterbar über drei Kopfzeilen (staged/unstaged/both), die den Picker beim Auswählen neu öffnen.

**⚠️ Wichtig:** Der Name wurde noch am selben Tag von `git_status_marks` zu `git_status_filtered` umbenannt (reiner Rename, keine Verhaltensänderung) — falls du den Picker aufrufst, den neuen Namen `git_status_filtered` verwenden.

**Testen:** In einem Git-Repo mit uncommitted Changes den Picker öffnen (z.B. `:Pickers git_status_filtered` oder das entsprechende Keymap, siehe pickers.txt) → Liste sollte Staged/Unstaged-Dateien zeigen, Filter-Kopfzeilen sollten beim Anwählen umschalten.

### feat(entry_actions): kuratierte filetree.nvim-Pfadkopier-Aktionen in Picker-Ergebniszeilen
Neue Entry-Actions `copy_absolute` / `copy_dirname` / `copy_env_rooted` / `markdown_link`, Default-Keys `[a` / `a` / `[e` / `ML` — engine-übergreifend (telescope/fzf/snacks) automatisch verfügbar, kein Config-Change downstream nötig. Nur im Ergebnisfenster (Normal-Mode), nicht während der Query-Eingabe. fzf-lua nutzt stattdessen physische Tasten `ctrl-y`/`alt-y`/`alt-r`/`alt-m` mangels Chord-Support.

**Testen:** In einem beliebigen Picker mit Dateiergebnissen (z.B. find_files) im Ergebnisfenster `[a` drücken → absoluter Pfad sollte in der Zwischenablage landen. Bei fzf-lua stattdessen `ctrl-y` testen.

### fix(entry_actions): `path_copy`/`create_file` extrahierten Garbage bei Nicht-Datei- und Preview-Zeilen
Bugfix aus Review der beiden obigen Features — betrifft fzf-lua (hidden path field nach Tab wurde ignoriert) und snacks (`.path` vs `.file`-Priorität falsch) sowie die drei Filter-Toggle-Zeilen im neuen git-status-Picker (trugen keinen Pfad, jetzt Repo-Root als Fallback). Reine Korrektheits-Fixes, kein neues Binding.

**Testen:** Im `git_status_filtered`-Picker eine der drei Filter-Kopfzeilen anwählen und `[a` (copy_absolute) drücken → sollte den Repo-Root kopieren statt einen Garbage-String.

---

## reposcope.nvim

### feat(dashboard): `dashboard.extra_paths` — Repos außerhalb des Scan-Roots
`:Reposcope dashboard` scannt bisher nur `$REPOS_DIR`. Neue Config-Option `dashboard.extra_paths` erlaubt, weitere Repo-Pfade (z.B. die Nvim-Config selbst) manuell hinzuzufügen — werden dedupliziert und als echte Git-Repos validiert.

**Testen:** `extra_paths = { vim.fn.stdpath("config") }` in die reposcope-Config eintragen, `:Reposcope dashboard` öffnen → die Nvim-Config sollte zusätzlich zu den `$REPOS_DIR`-Repos im Dashboard auftauchen.

### fix(dashboard): Pfadtrenner/Case beim Dedupe von `extra_paths` normalisiert
Folgefix — ohne diesen tauchte ein Repo doppelt auf, wenn `extra_paths` mit Backslashes/anderer Drive-Letter-Case getippt wurde. Kein separates Testen nötig, im obigen Test mit abweichender Schreibweise mitgetestet.

---

## ui.nvim

### feat(statusline): Kurzbeschreibung im Modul-Kontextmenü-Header
Rechtsklick auf ein Statusline-Modul zeigt jetzt zusätzlich zum Key eine kurze (~3 Wörter) Beschreibung aus dem Statusline-Katalog im Menü-Header.

**Testen:** Rechtsklick auf ein bereits in der Statusline platziertes Modul → Menü-Header sollte jetzt "`<key>` — Kurzbeschreibung" statt nur `<key>` zeigen.

### fix(statusline): Globale Statusline-Zeile wird auch bei `cmdheight=0` erkannt
Bugfix: Mit `laststatus=3` + `cmdheight=0` (einzelnes Fenster, keine Splits) funktionierte Hover/Rechtsklick-Menü auf der globalen Statusline vorher gar nicht, weil `getmousepos()` nicht `winid==0` meldete.

**Testen:** Falls du `cmdheight=0` + `laststatus=3` nutzt: Hover über die globale Statusline bewegen bzw. rechtsklicken → sollte jetzt reagieren (vorher: keine Reaktion).

---

## Cross-Plugin-Hinweise

- **lib.nvim → gitsuite.nvim:** gitsuite.nvim braucht lib.nvim ≥ `96f8809` für den korrigierten `route.available`/`route.check`-Split. Bei separatem Plugin-Update sicherstellen, dass beide zusammen aktualisiert werden.
- **buffer-ctx.nvim:** `markdownlink` → `mdlink` Rename — falls du das Subcommand irgendwo referenzierst (Keymap, Skript), anpassen.
- **pickers.nvim:** `git_status_marks` → `git_status_filtered` Rename, gleicher Tag.
- Mehrere Plugins (gopath.nvim, buffer-ctx.nvim, images.nvim, filetree.nvim) konvergieren heute auf gemeinsame Konventionen: `$REPOS_DIR`-relative Pfadmodi ("repos"), `mdlink`-Naming, soft-dependency pcall-Guards für Cross-Plugin-Aufrufe.

---

*Erstellt automatisch aus `git log --since="24 hours ago"` über alle Repos unter `$REPOS_DIR/repos`.*
