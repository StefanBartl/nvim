# Windows File-Lock-Problem: Handle-Guard für filetree.nvim

> Auslöser: sporadisch lassen sich Files/Folder nach move/rename/modify nicht
> mehr verschieben/umbenennen/löschen ("manchmal, nicht immer"). Vermutung war
> Windows-File-Locking. Analyse bestätigt das — mit konkreter Ursache statt
> pauschal "Windows halt".

## Table of content

- [Root Cause](#root-cause)
- [Architektur-Entscheidung](#architektur-entscheidung)
- [Implementationsstand](#implementationsstand)
- [Was noch fehlt](#was-noch-fehlt)
- [Nebenfunde / Notizen](#nebenfunde--notizen)

---

## Root Cause

Ursache ist **`use_libuv_file_watcher = true`** in [`lua/plugins/neotree.lua:168`](../../../../lua/plugins/neotree.lua) kombiniert mit einem echten Handle-Leak in neo-trees `fs_watch.lua`
(`…/lazy/neo-tree.nvim/lua/neo-tree/sources/filesystem/lib/fs_watch.lua`).

Neo-tree legt pro expandiertem Ordner ein `uv_fs_event_t` an (`fs_scan.lua:197`), auf Windows ein offenes `ReadDirectoryChangesW`-Handle. Drei Defekte:

1. **`handle:close()` wird nirgends aufgerufen** — im ganzen neo-tree-Repo nur `:stop()`. Handles verschwinden erst beim Lua-GC, nicht deterministisch → erklärt das "manchmal, nicht immer".
2. **`stop_watching()` macht `watchers = {}`** (`fs_watch.lua:116`) — wirft die Tabelle weg, ohne zu schließen. Handles danach unerreichbar *und* offen.
3. **Externe Renames umgehen den Refcount komplett.** `smart_rename` ruft `uv.fs_rename()` direkt (`filetree.nvim/lua/filetree/features/fileops/smart_rename/init.lua:471`). Neo-tree bekommt das nicht mit, `unwatch_folder(old_path)` wird nie gerufen — der Watcher bleibt auf dem *verschobenen* Verzeichnis aktiv. Kernel hält das Objekt offen → nächstes Rename/Delete des Ordners oder Parents: `EPERM`/`ERROR_SHARING_VIOLATION`.

**`watcher_quarantine`** (aktiv via `lua/plugins/personal/init.lua:389`) behebt das nicht — es patcht `vim.notify` und Callback-Wrapper, um die EPERM-*Meldung* zu unterdrücken, gibt aber **kein einziges Handle frei**. Macht das Symptom unsichtbar, lässt die Ursache stehen. Vermutlich der Grund, warum das Problem lautlos auftritt.

Der eigentliche Bug (`handle:close()` fehlt) ist ein **neo-tree-Upstream-Bug**, keine reine Konfigurationssache — ein Upstream-Issue wäre die nachhaltigere Lösungshälfte, unabhängig vom lokalen Workaround unten.

**Sofort-Test (noch offen, siehe unten):** `use_libuv_file_watcher = false` in [`neotree.lua:168`](../../../../lua/plugins/neotree.lua) setzen. Kostet Auto-Refresh, sollte die Locks aber komplett beseitigen — bestätigt/widerlegt die Diagnose ohne Implementationsaufwand.

---

## Architektur-Entscheidung

Ursprünglich als reines filetree.nvim-Feature geplant. Nach Durchsicht von `c:\repos` (alle 26 Plugins nach `fs_rename|fs_unlink|fs_rmdir|new_fs_event` durchsucht) auf zwei Schichten aufgeteilt:

- **Treffer nur in:** `lib.nvim`, `filetree.nvim`, indirekt `fileops.nvim`. Alle anderen (sessions, reposcope, pdfport, github_stats, color_my_ascii, insights, …) haben keine FS-Mutation/Watcher-Berührung — kein Nutzen von einer Abstraktion dort.
- **`lib.nvim.cross.fs.mutate` existierte bereits** als zentraler Mutations-Chokepoint, genutzt von `fileops.nvim` (`ops/file.lua:7`). War der naheliegende Ort für einen generischen Retry-Layer — profitiert automatisch, ohne Codeänderung dort.
- Die Watcher-Registry dagegen ist **kein generisches FS-Problem**, sondern neo-tree-Domänenwissen (patcht `neo-tree.sources.filesystem.lib.fs_watch`). Zielort: `lib.nvim/lua/lib/nvim/neotree/` (existiert bereits, aktuell nur `node`) — konsistente Adresse für neo-tree-Wissen, nicht weil andere Plugins es bräuchten.
- filetree.nvim selbst bleibt am Ende nur noch **dünne Verdrahtung**.

Reihenfolge (unabhängig verwertbar, nicht strikt sequentiell):

1. `use_libuv_file_watcher = false` testen (Diagnose-Bestätigung, kein Code)
2. Retry-Layer in `cross/fs/mutate` (lohnt sich unabhängig vom Testergebnis)
3. filetree.nvim von rohem `uv.fs_rename`/`uv.fs_copyfile` auf `cross.fs.mutate` umstellen
4. `lib.nvim/neotree/watch`-Registry + dünnes `handle_guard`-Feature in filetree.nvim

---

## Implementationsstand

### ✅ Schritt 2 — Retry-Layer in `lib.nvim.cross.fs.mutate` (fertig, ungetestet im echten Windows-Lock-Fall)

Repo: `c:\repos\lib.nvim`, committet & gepusht (`96afd50`).

- [`lua/lib/nvim/cross/fs/mutate/init.lua`](../../../../../../repos/lib.nvim/lua/lib/nvim/cross/fs/mutate/init.lua) — `M.retry(op, opts)`:
  - Retried nur bei `EPERM`/`EACCES`/`EBUSY` (Code-Prefix-Match auf libuv-Fehlerstring). Alles andere (`ENOENT` etc.) schlägt sofort durch.
  - Eskalierender Backoff via `vim.wait` (50ms, 100ms, 200ms, …) — bewusst `vim.wait` statt `uv.sleep`, damit die Event-Loop weiterläuft und schwebende libuv-Handle-Close-Callbacks in der Wartezeit tatsächlich durchkommen.
  - Default `attempts`: **3 auf Windows, 1 auf POSIX** (`is_windows()`-Check via `vim.fn.has("win32"/"win64")`) — auf POSIX bedeuten die Codes was sie sagen, Retry wäre dort Unsinn.
  - `on_retry`-Hook: Callback vor jedem erneuten Versuch — der vorgesehene Anknüpfungspunkt für Schritt 4 (filetree/lib gibt dort eigene Watcher-Handles frei, bevor erneut versucht wird).
  - Alle vier Primitive (`delete_file`, `copy_file`, `rename_file`, `mkdir_p`) routen jetzt darüber, nehmen optionales `RetryOpts` als letztes Argument.
- `@types/init.lua` aktualisiert (`Lib.Cross.Fs.Mutate.RetryOpts`, Signaturen).
- `README.md` neu angelegt (Konvention wie bei `lib.nvim/lua/lib/nvim/debounce/README.md`).
- 8 neue Assertions in `docs/TESTS/nvim_helpers_spec.lua` (Retry-bis-Erfolg, kein Retry bei `ENOENT`, Attempts-Exhaustion, `on_retry`-Hook-Count). Gesamte Suite (`docs/TESTS/run.lua`) grün, inkl. bestehender `cross.fs.mutate`-Tests.
- **API rückwärtskompatibel verifiziert:** alle bestehenden Aufrufer in `c:\repos` (nur `fileops.nvim/lua/fileops_nvim/ops/file.lua`) übergeben keine zusätzlichen Positionsargumente, die durch das neue optionale `opts` umgedeutet würden.

**Bekannte Grenze:** Der Retry hilft gegen spurious Windows-Locks (Defender/Indexer/OneDrive). Gegen die eigentliche Ursache (neo-tree schließt Watcher-Handles nie) hilft er nur zufällig, wenn der GC dazwischenkommt — das ist erst mit Schritt 4 wirklich behoben.

### ✅ Schritt 3 — filetree.nvim auf `cross.fs.mutate` umgestellt (fertig)

Repo: `E:\repos\filetree.nvim`, committet & gepusht (`fix(fileops): route rename/copy through lib.nvim.cross.fs.mutate`).

- `copy_move/init.lua` — beide `uv.fs_copyfile()` (in `copy_dir` + `do_copy`) auf `fsops.copy_file()` umgestellt; Modul-Level-`require("lib.nvim.cross.fs.mutate")`, die zwei lokalen `local uv = vim.uv or vim.loop` entfernt.
- `smart_rename/init.lua` — der **async** `uv.fs_rename(old, new, cb)` auf das **synchrone** `fsops.rename_file()` umgestellt. Der alte `vim.schedule`-Wrap um das Post-Work war nur nötig, weil der libuv-Rename-Callback off-loop lief; der `function(workspace_edit)`-Kontext ist bereits Main-Loop (das un-scheduled `apply_workspace_edit` darüber beweist es), was der Retry-Backoff-`vim.wait` genau braucht → Post-Work läuft jetzt inline.
- **Kontext-Sicherheit geprüft:** `do_copy`/`do_move` rufen bereits `vim.fn.mkdir`/`readdir`/`isdirectory` (Main-Loop-pflichtige vimL-Funktionen), laufen also schon auf dem Main-Loop — `vim.wait` im Retry dort sicher, ohne Änderung.
- **Verifiziert:** beide Module laden headless mit lib.nvim auf rtp; realer copy+rename auf Temp-Dateien über `cross.fs.mutate` (Inhalt erhalten, alt weg/neu da); Testsuite ohne neue Fehler (die zwei bestehenden Fails — fehlende `docs/BINDINGS.lua`, `units.lua:453` — sind vorbestehend).

**Offene Lücke (bewusst nicht Teil dieser Migration, aber verwandt):** `copy_move/init.lua`s `do_move` nutzt weiterhin `vim.fn.rename()` (nicht `uv.fs_rename`) für den eigentlichen Move — das ist der *primäre* Lock-Trigger laut Root-Cause und umgeht den Retry-Layer weiterhin. Kandidat für einen Folge-Commit: `do_move` ebenfalls auf `fsops.rename_file` umstellen.

---

## Was noch fehlt

### 🔲 Schritt 1 — Diagnose-Bestätigung (kein Code)

`use_libuv_file_watcher = false` in [`neotree.lua:168`](../../../../lua/plugins/neotree.lua) testen, über mehrere Tage (Fehler ist sporadisch). Bestätigt oder widerlegt die Root-Cause-Analyse, bevor weiter Arbeit in Schritt 4 fließt. **Vom User noch nicht zurückgemeldet.**

### 🔲 Schritt 4 — `lib.nvim/neotree/watch`-Registry + `handle_guard`-Feature

Noch nicht begonnen. Geplanter Umfang:

1. **`lib.nvim/lua/lib/nvim/neotree/watch/init.lua`**: patcht `neo-tree.sources.filesystem.lib.fs_watch` (Patch-Mechanismus existiert schon als Vorlage in `filetree.nvim`s `watcher_quarantine.patch_neotree_watch`). Wrapt `watch_folder`, `unwatch_folder`, `stop_watching` so, dass vor dem Verwerfen eines Watchers immer `handle:stop()` **und** `handle:close()` passiert, plus Entfernen aus der internen `watchers`-Tabelle.
2. **`M.release(paths)`**: schließt alle Handles auf `path` und alle Unterpfade (Prefix-Match auf normalisierten Pfaden, `util/path.lua`-Normalisierung nutzen) — bei Ordner-Rename hängen Kind-Watcher mit dran und blockieren genauso.
3. **`M.with_release(paths, fn)`**: `release(paths)` → `fn()` → nach Erfolg nochmal `release({old, new})`, dann `adapter.refresh()`. Der zweite Release fängt Watcher ab, die neo-tree zwischenzeitlich neu angelegt hat.
4. **Integration via `on_retry`-Hook** (aus Schritt 2) in den Fileops, die dann Schritt 3 nutzen: `smart_rename`, `copy_move` (beim Move), `rename_batch` (mehrere Pfade in Folge — hier besonders relevant), `trash`.
5. **`watcher_quarantine` umbauen statt duplizieren**: `M.enter(duration, paths)` soll zusätzlich `handle_guard.release(paths)` rufen. Der Notify-Patch bleibt als Netz für Race-Fenster, aber die Ursache wird behoben statt nur versteckt. Alternative, eher bevorzugt: `watcher_quarantine` komplett in das neue Feature auflösen — ein Konzept statt zwei.
6. **Diagnose:** `:Filetree handles` listet offene Handles pro Pfad; Health-Check in `checkhealth/features.lua`, der auf Windows warnt, wenn Watcher auf nicht mehr existierende Pfade zeigen (= die Leak-Signatur, sofort sichtbar).

---

## Nebenfunde / Notizen

- **Upstream-Bug-Kandidat:** fehlendes `handle:close()` in neo-trees `fs_watch.lua` ist unabhängig von diesem Workaround meldenswert (`stop_watching()` wirft die Handle-Tabelle weg ohne zu schließen). Noch nicht als Issue eingereicht.
- **Plugin-Liste durchsucht, keine weiteren Kandidaten:** `buffer-ctx`, `cascade`, `color_my_ascii`, `debugging`, `dap`, `diff`, `emojis`, `github_stats`, `gopath`, `language`, `markdown`, `mdview`, `migrate`, `cmdlog`, `sandbox.nvim`, `open`, `pdfport`, `pickers`, `insights`, `recommender`, `replacer`, `reposcope`, `sessions` — keine Treffer auf FS-Mutation/Watcher-Pattern. `cross.fs.mutate` bleibt trotzdem sinnvoll generisch (z. B. `fs/json`s atomarer tmp+rename-Write, `fs/trash`, die beide dasselbe Windows-`fs_rename`-Verhalten dokumentiert hatten, siehe `lib.nvim/lua/lib/nvim/fs/json/README.md:31`).
- **`fs/json` und `fs/trash` profitieren indirekt**, sobald sie (separat, nicht Teil dieses Plans) auf `cross.fs.mutate.rename_file` statt direktem `uv.fs_rename` umgestellt werden — aktuell rufen beide noch roh auf, siehe `lib.nvim/lua/lib/nvim/fs/json/init.lua:68` und `lib.nvim/lua/lib/nvim/fs/trash/init.lua:99,120`. Nicht Teil dieses Plans, aber derselbe Chokepoint-Gedanke.

---
