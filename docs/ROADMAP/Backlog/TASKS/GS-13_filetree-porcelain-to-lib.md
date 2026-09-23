# GS-13 — `filetree.nvim`: eigener Porcelain-Parser → `lib.nvim.git`

**Repos:** filetree.nvim, lib.nvim (`status_porcelain`/`_async` erweitert) ·
**Nutzen** 4 · **Risiko** niedrig · **Welle** 3 (Duplikate) · erledigt
2026-09-22.

## Ausgangslage

`features/git/git_status/init.lua` in filetree.nvim spawnte
`git -C <root> status --porcelain -u [--ignored]` selbst und parste die
zeilenweise Ausgabe von Hand. Ohne `-z` quotet Git jeden Pfad mit Leerzeichen
oder Nicht-ASCII-Byte in C-Escapes (`"a b.txt"`, `"ü.txt"`) — genau die
Lücke, die `lib.nvim.git.status_porcelain` für gitsuites eigenes
`:Git status quickfix` bereits geschlossen hatte (`GS-01`). Die
Rename-Erkennung lief zusätzlich über eine Regex auf `" -> "`, die einen
Dateinamen mit genau dieser Zeichenfolge fehlinterpretiert hätte.

## Umsetzung

- **lib.nvim** (`eeb53e2`): `status_porcelain`/`_async` um `opts.ignored`
  erweitert — reines `-u` listet nie ignorierte Pfade, filetree's eigenes
  `show_ignored` brauchte `--ignored` im Argv.
- **filetree.nvim** (`d2c29e6`): ruft jetzt `status_porcelain_async` statt
  des eigenen Parsers auf. Die Antwort-Map ist bereits über den `-z`-Pfad
  Repo-root-relativ geschlüsselt, Renames kommen vorgesplittet (`orig_path`
  statt Regex). Eine neue Anfrage stoppt die vorherige über das von
  `status_porcelain_async` zurückgegebene Stop-Handle, statt dass eine
  überholte Antwort ein neueres Render überschreiben könnte.
- `TESTS/gaps.lua`: Fixture auf echte `-z`/NUL-Form umgestellt, Argv-Check auf
  Mitgliedschaft (`-C`/`--porcelain`/`-z`/`-u`) statt Position (lib.nvim's
  `status_argv` fügt inzwischen auch `--no-optional-locks` hinzu); neuer Fall
  gegen einen echten Git-Prozess mit echten `"a b.txt"`/`"ü.txt"`-Dateien —
  belegt, dass die Quoting-Lücke wirklich geschlossen ist, nicht nur gemockt.

## Ergebnis

Lokale Suite grün (smoke/units/menu/cwd_mode/sidebar_guard/gaps/
config_schema/nav_switch_toggle/refs/adapter_lines), `stylua`/`luacheck`
sauber. CI grün auf allen drei Systemen (`d2c29e6`, `eeb53e2`).

## Nachwirkung

`opts.ignored` auf `status_porcelain`/`_async` ist jetzt öffentliche
lib.nvim-API — Grundlage für jeden weiteren Konsumenten, der ignorierte
Pfade braucht (u. a. genutzt von `GS-14`s `insights.nvim`-Swap).
