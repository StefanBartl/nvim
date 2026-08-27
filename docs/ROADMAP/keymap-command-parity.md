# Keymap ↔ Usercommand Parity

Stand: 2026-08-27. Beantwortet den MERGED.md-Punkt *"Alle Keymaps/Features
zusätzlich via Usrcmd ausführbar machen — nicht zwingend, aber einen Grund
wenn nicht."*

## Ergebnis

**Keine Lücke.** Über alle 29 Plugins ist jede deklarierte Keymap-Action auch
über ein Kommando erreichbar. Es gibt keinen Fall, für den ein "Grund, warum
nicht" nötig wäre.

Das ist nachgemessen, nicht geschätzt: seit der Keymap-Registry kennt
`lib.nvim.bindings.keymap.registered()` jede Action jedes Plugins, und der
Composer kennt über `composer.registry()` jede Route. Beide Listen lassen sich
gegeneinander halten, statt sie aus dem Quelltext zu erraten.

## Wie es gemessen wurde

`tools/keymap_command_audit.lua` (neben dieser Datei) lädt ein Plugin
headless, ruft `setup({})`, und gibt zwei Listen aus:

```
KEY  <surface>  <action>  <lhs>  <desc>
CMD  <verb>     <route>   <desc>
```

Ein Skript paart sie nach Namen und Beschreibungswörtern und meldet
**Kandidaten**. Jeder Kandidat wurde von Hand geprüft — was nötig war, denn
die Automatik kann eine ganze Klasse von Abdeckung nicht sehen:

> Eine Route mit typisiertem Argument deckt N Actions ab, ohne eine davon
> beim Namen zu nennen.

`:Open firefox` ist eine Route (`path = {}`) mit einem `OPEN_TARGET`-Argument,
das aus derselben Registry vervollständigt wird, aus der die 18
`open_*`-Keymap-Actions stammen. Die Namensgleichheit steht nirgends im
Routen-Baum — die Automatik meldete alle 18 als Lücke, tatsächlich ist es die
sauberste Abdeckung von allen.

## Die geprüften Kandidaten, und warum keiner eine Lücke ist

| Plugin | Kandidat | Tatsächlich erreichbar über |
| --- | --- | --- |
| open | alle 18 `open_*` | `:Open <handler>` — Argument vom Typ `OPEN_TARGET`, vervollständigt aus `open.registry` |
| fileops | `next_current`, `next_background`, `prev_*`, `*_vsplit` | `:File next\|prev [target] [glob]` — `FILEOPS_CYCLE_ARG`, gleiche Targets wie die Keys |
| fileops | `delete_force` | `:File! delete` — der Bang *ist* die Force-Variante |
| fileops | `next_filtered` / `prev_filtered` | `:File next *.lua` — zweiter Slot ist das Glob |
| gopath | `open_explorer` | `:Gopath open explorer` — `OPEN_MODES` enthält `explorer` |
| pickers | `explorer` | `:Pickers builtin explorer` — `PICKERS_BUILTIN_NAME` |
| recommender | `cwd`, `high_threshold` | `:Recommender -c` bzw. `:Recommender regex 5` — Flag und Positional, keine eigene Route |
| language | `panel` | `:Spellcheck` — das Kommando *ist* der Toggle |

## Nebenbefund: die Zahlen allein lügen

Rohe Zählungen aus dem Audit, als Warnung an künftige Ich:

| Plugin | Keymap-Actions | Kommando-Routen |
| --- | --- | --- |
| open | 18 | 4 |
| filetree | (buffer-lokal) | 171 |
| lsp | 39 | 70 |
| recommender | 8 | 2 |

`open` sieht nach der größten Lücke aus und hat keine. `recommender` hat 8
Keys auf 2 Routen und ist vollständig abgedeckt, weil Flags keine Routen sind.
Umgekehrt sagt eine hohe Routenzahl nichts über Keymap-Parität.

Ebenso: `keys=0` im Audit heißt oft nur, dass ein Plugin buffer-lokal auf ein
FileType-Event bindet, das headless nie feuert (dap, cascade, pdfport,
sandbox, markdown, filetree). Für die brauchte es den passenden Filetype im
Scratch-Buffer — filetree z. B. `netrw`, weil ohne installiertes neo-tree der
netrw-Adapter greift.

## Wiederholen

```bash
nvim --clean -l docs/ROADMAP/tools/keymap_command_audit.lua E:/repos/<plugin>.nvim <modul>
```

Ausgabe ist TSV auf stdout, damit `grep`/`cut` reichen. Der Vergleich selbst
ist bewusst *kein* Teil des Skripts: die Paarung ist eine Ermessensfrage
(siehe `:Open firefox`), und ein Skript, das sie als Urteil ausgibt, würde
falsche Sicherheit erzeugen.
