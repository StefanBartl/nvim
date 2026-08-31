# luals-scan

Zählt die LuaLS-Befunde über die Lua-Workspaces dieser Maschine, so wie der
Editor sie sieht, und vergleicht zwei Läufe. Gebaut für die Roadmap-Arbeit in
[`docs/ROADMAP/personal/All/Diagnostics.md`](../../docs/ROADMAP/personal/All/Diagnostics.md),
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

---

## Wie die Messung dem Editor entspricht

Der Editor stellt die Config in zwei Schritten her, und die Reihenfolge ist der
ganze Punkt:

1. `lsp.nvim` übergibt `lua_ls` eine Settings-Tabelle. Deren `workspace.library`
   baut `lsp/servers/lua_ls/build_library.lua` zur Laufzeit -- `runtimepath`,
   geladene Plugins, `$VIMRUNTIME`, `${3rd}/luv`, `${3rd}/busted`.
2. Liegt im Workspace eine `.luarc.json`, **ersetzt** sie jeden Schlüssel, den
   sie nennt. Bei Listen wie `workspace.library` gibt es keinen Merge: die
   Liste aus Schritt 1 ist dann weg.

Genau das bildet `mkcfg.py` ab. Und weil Schritt 1 zu wichtig ist, um ihn
nachzumodellieren, holt `dump_library.lua` die Liste direkt aus einem laufenden
nvim, statt sie hier nachzubauen.

> Ausführlich, mit Nachweis:
> `E:/repos/WKDBooks/Development/wkdbook-Lua/LuaLanguageServer/_luarc_json/Reichweite-und-Praezedenz.md`

---

## Die Teile

| Datei | Aufgabe |
|---|---|
| `scan.sh` | Index bauen, Library-Dump anstoßen, Configs erzeugen, `--check` fahren |
| `dump_library.lua` | `build_library(root)` in laufendem nvim, Ergebnis als JSON |
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
- **Es bleibt ein Modell des Editors.** Nur die Library wird echt geholt; die
  übrigen Injektions-Defaults (`runtime.version`, `diagnostics.globals`) sind
  hier nachgebildet. In fast allen Repos überschreibt die `.luarc.json` sie
  ohnehin.
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
