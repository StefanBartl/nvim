# luals-scan

Zählt die LuaLS-Befunde über die Lua-Workspaces dieser Maschine, so wie der
Editor sie sieht, und vergleicht zwei Läufe. Gebaut für die Roadmap-Arbeit in
[`docs/ROADMAP/personal/All/Diagnostics.md`](../../docs/ROADMAP/personal/All/FINISH/ERLEDIGT/DIAGNOSTICS/Diagnostics.md),
deren stehende Regel „Messen statt schätzen" pro Repo je einen Scan davor und
danach verlangt.

Vorher wurde das zweimal ad hoc gebaut und zweimal weggeworfen. Deshalb liegt
es jetzt hier.

---

## Benutzung

```bash
export REPOS_DIR=E:/repos          # in dieser Config ohnehin gesetzt

scripts/luals-scan/scan.sh before lsp.nvim     # ein Workspace, ~1 min
# ... Änderung machen ...
scripts/luals-scan/scan.sh after lsp.nvim

python scripts/luals-scan/compare.py before after
```

Ohne Repo-Argumente läuft der Scan über **alle** Workspaces -- jedes
Verzeichnis unter `$REPOS_DIR` mit einer `.luarc.json`, plus diese Config.
Das dauert eine gute Viertelstunde; für die vertikale Arbeit an einem Repo ist
die Ein-Argument-Form der Normalfall.

Gemessen: ein `--check` braucht mit der echten injizierten Library rund eine
Minute pro Workspace -- deutlich mehr als mit einer handgeschriebenen
Drei-Zeilen-Library, weil dabei tatsächlich alle Plugin-Typen indiziert werden.
Das ist der Preis dafür, dass die Zahlen dem Editor entsprechen.

`compare.py` mit nur einem Pass-Namen gibt statt eines Vergleichs die Summen
pro Workspace und pro Regel aus.

Arbeitsverzeichnis ist `$LOCALAPPDATA/nvim-data/luals-scan`, überschreibbar
mit `LUALS_SCAN_DIR`. Die Roh-JSONs pro Lauf liegen unter `out/<pass>/` und
sind nach Datei gruppiert -- für Fragen wie „welche Datei trägt die 173
`duplicate-doc-field`" reicht ein kurzes Python darüber.

| Env | Wirkung |
|---|---|
| `REPOS_DIR` | wo die `*.nvim`-Repos liegen (erforderlich) |
| `LUALS_SCAN_DIR` | Arbeitsverzeichnis |
| `LUALS_SCAN_JOBS` | parallele LuaLS-Instanzen, Standard 3 |
| `LUALS_SCAN_REFRESH=1` | injizierte Library neu holen statt aus dem Cache |

### Läufe aus einem git-Worktree

`nvim-config` ist immer **die Config, aus der `scan.sh` gestartet wurde** -- in
einem Worktree also der Worktree, nicht der Haupt-Checkout. Gemessen werden
dessen Lua-Dateien und dessen `.luarc.json`; für die Arbeit an einem Branch
ist das genau richtig, man sollte es nur wissen.

Zwei Dinge folgen daraus:

- Der Library-Cache ist **nicht** nach Worktree getrennt -- es gibt nur ein
  `library/nvim-config.json`. Wer den Vorher-Lauf aus dem Worktree und den
  Nachher-Lauf aus dem Haupt-Checkout fährt, misst den zweiten mit der
  Library des ersten. Beim Wechsel einmal mit `LUALS_SCAN_REFRESH=1` laufen
  lassen.
- Beide Läufe einer Messreihe gehören in dieselbe Arbeitskopie, sonst
  vergleicht man zwei Checkouts statt einer Änderung.

Das headless nvim des Dumps läuft dabei immer mit der echten Config
(`stdpath("config")`), egal von wo aus gestartet -- die injizierte Library ist
also die des installierten Plugin-Bestands. Nur der geprüfte Root wechselt.

---

## Wie die Messung dem Editor entspricht

Der Editor stellt die Config in zwei Schritten her, und die Reihenfolge ist der
ganze Punkt:

1. `lsp.nvim` übergibt `lua_ls` eine Settings-Tabelle. Deren `workspace.library`
   baut `lsp/servers/lua_ls/build_library.lua` zur Laufzeit -- `runtimepath`,
   geladene Plugins, `$VIMRUNTIME`, `${3rd}/luv`, `${3rd}/busted`,
   `${3rd}/luassert`. Dazu ein `workspace.ignoreDir` aus lib.nvims
   gemeinsamer Ignore-Liste: 124 Muster, `**/.claude` darunter.
2. Liegt im Workspace eine `.luarc.json`, **ersetzt** sie jeden Schlüssel, den
   sie nennt. Bei Listen wie `workspace.library` gibt es keinen Merge: die
   Liste aus Schritt 1 ist dann weg.

Genau das bildet `mkcfg.py` ab. Und weil Schritt 1 zu wichtig ist, um ihn
nachzumodellieren, holt `dump_library.lua` **beide** Listen direkt aus einem
laufenden nvim, statt sie hier nachzubauen.

`ignoreDir` steht nicht aus Ordnungsliebe dabei. Die nvim-Config haelt elf
git-Worktrees unter `.claude/worktrees/`, jeder eine volle Kopie von ihr, und
der Config-Root ist fuer jedes Repo ein Library-Eintrag. Einer dieser
Worktrees stammt aus der Zeit vor der Extraktion von lsp.nvim und traegt noch
`lua/lsp/**` -- ohne `**/.claude` liest lua_ls also eine aeltere Kopie des
Plugins neben der echten, und jedes `@class` darin kollidiert mit sich selbst.
In lsp.nvim waren das 180 von 359 Befunden.

### Warum der Dump nicht ganz die Injektion ist

`dump_library.lua` ruft `build_library(root)`. Der **Attach-Pfad des Editors**
benutzt dagegen `library_profiles.build_runtime_library()` -- drei Pfade
(`${3rd}/luv`, `${3rd}/busted`, `$VIMRUNTIME/lua`); die Plugin-Typen zieht
lazydev bei Bedarf nach. `build_library` erreicht den laufenden Server nur
über `:LuaLsReloadLibrary` von Hand.

Der Dump ersetzt damit faktisch lazydev, und das ist Absicht: ohne die
Plugin-Typen meldet der Scan Hunderte Phantome auf `Lib.*`, `RA.*` und
Konsorten. **Eine Sache musste dafür aber angeglichen werden.** lazydev trägt
`<plugin>/lua` ein, `build_library` dagegen den `runtimepath`-Eintrag, also die
**Wurzel** -- und damit auch das `TESTS/` jedes Plugins. Bei 21 Repos mit einer
`TESTS/harness.lua` findet ein `require("harness")` dann 21 Kandidaten, und
LuaLS greift irgendeinen: bei spotlight.nvim gemessen 346
`param-type-mismatch` gegen die `H.eq(a, b, msg)` eines fremden Repos, von
denen eine laufende Session (`vim.diagnostic.get`) keinen einzigen zeigt.

Deshalb trägt der Dump `<plugin>/lua` ein, wo es das gibt.

> Ausführlich, mit Nachweis:
> `E:/repos/WKDBooks/Development/wkdbook-Lua/LuaLanguageServer/_luarc_json/Reichweite-und-Praezedenz.md`

---

## Die Teile

| Datei | Aufgabe |
|---|---|
| `scan.sh` | Index bauen, Library-Dump anstoßen, Configs erzeugen, `--check` fahren |
| `dump_library.lua` | `build_library(root)` + `ignore.as_luals_patterns()` in laufendem nvim, Ergebnis als JSON. Plugin-Wurzeln werden dabei durch ihr `lua/` ersetzt -- siehe oben |
| `mkcfg.py` | injizierte Defaults + `.luarc.json` des Repos -> eine Config pro Workspace |
| `compare.py` | einen Lauf zusammenfassen oder zwei vergleichen |

Der Dump selbst ist schnell -- unter einer Sekunde pro Workspace. Gecacht wird
er (`library/<name>.json`) trotzdem, und zwar nicht aus Geschwindigkeitsgründen:
so sieht der Nachher-Lauf **garantiert dieselbe Library** wie der
Vorher-Lauf. Sonst könnte ein zwischenzeitlich geladenes Plugin den Vergleich
verfälschen, ohne dass man es merkt.

**Genau deshalb veraltet der Cache irgendwann.** Wenn sich der Plugin-Bestand
wirklich geändert hat, einmal mit `LUALS_SCAN_REFRESH=1` laufen lassen -- aber
dann für beide Läufe einer Messreihe, nicht nur für einen.

---

## Fallen, die schon Zeit gekostet haben

Alle vier scheitern **stumm** -- kein Fehler, nur leere oder falsche
Ergebnisse. Sie sind im Code behandelt; hier stehen sie, damit niemand sie
zweimal sucht.

1. **Ohne `--check_out_path` gibt es kein JSON.** Die Ausgabe auf stdout ist
   mit Fortschrittsbalken durchsetzt und schlecht zu parsen.
2. **Parallele LuaLS-Instanzen brauchen je einen eigenen `--metapath`.** Sonst
   überschreiben sie sich den Meta-Cache und *jeder* Lauf kommt leer zurück.
3. **Der Kindprozess erbt stdin.** In einer `while read`-Schleife im
   Hintergrund frisst er die restliche Index-Datei -- daher `</dev/null`.
4. **Windows-Python schreibt Textdateien mit CRLF.** Ein `\r` am Ende eines
   Pfades lässt den Lauf scheitern, ohne ein Wort zu sagen.
5. **`pwd` antwortet in Git Bash mit `/c/Users/...`.** Das versteht weder das
   Windows-`nvim` noch `lua-language-server`. Beim Server gibt es immerhin
   einen Fehler -- headless nvim dagegen meldet, dass die Datei nicht da ist,
   und **wartet dann für immer**. Dieselbe Klasse Hänger wie eine fehlende
   `PLENARY_PATH`. Daher `pwd -W` und ein abschließendes `-c "qa!"` als
   Sicherung.

Und eine, die keine Falle im Code ist, sondern beim Zusehen: **`| tail` und
`| grep` puffern.** Wer die Ausgabe eines langen Laufs durch eine Pipe
betrachtet, sieht bis zum Ende gar nichts und hält den Lauf für hängend. In
eine Datei umleiten und die beobachten.

---

## Was die Zahlen nicht hergeben

- **Rauschen.** Zwei identische Läufe über einen unveränderten Workspace
  unterscheiden sich um einige Zähler, `param-type-mismatch` ist der unruhige
  Kandidat (einmal gemessen: dasselbe Repo, keine Änderung, -7 und später +7).
  `compare.py` markiert Verschlechterungen unter 10 als „within noise" --
  ohne zweiten Lauf sind sie kein Befund.
- **Es bleibt ein Modell des Editors.** Library und `ignoreDir` werden echt
  geholt; die übrigen Injektions-Defaults (`runtime.version`,
  `diagnostics.globals`) sind hier nachgebildet. In fast allen Repos
  überschreibt die `.luarc.json` sie ohnehin -- was bei `ignoreDir` der
  eigentliche Befund ist und nicht die Entwarnung: elf Repos und die Config
  nennen den Schlüssel und werfen damit die 124 injizierten Muster weg.
- **Absolutzahlen sind nur innerhalb einer Messreihe vergleichbar.** Gegen
  ältere Zahlen aus `Diagnostics.md` Abschnitt 2 und 3 zu rechnen, führt in
  die Irre -- die sind mit einer anderen Prüf-Config entstanden.
- **Für eine harte Aussage gehört die Gegenprobe im laufenden Server dazu.**
  Datei öffnen, auf einen stabilen Zählerstand warten, `vim.diagnostic.get(0)`
  auszählen. Das hat in dieser Arbeit zweimal etwas geradegerückt, das der
  CLI-Lauf anders gesehen hatte.

---

## Verwandtes

Die Testsuiten der Plugins laufen über plenary und brauchen zwei Pfade in der
Umgebung, sonst existiert `PlenaryBustedFile` nicht und headless nvim wartet
stumm bis zum Timeout:

```bash
PLENARY_PATH="$LOCALAPPDATA/nvim-data/lazy/plenary.nvim" \
LIB_NVIM_PATH="$REPOS_DIR/lib.nvim" \
nvim --headless --noplugin -u TESTS/minimal_init.lua \
  -c "PlenaryBustedFile TESTS/lsp/config_spec.lua"
```
