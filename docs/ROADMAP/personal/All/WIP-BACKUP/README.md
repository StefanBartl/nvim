# WIP-Backup — cmdlog.nvim: plenary-Abhängigkeit entfernen

> ## ✅ ERLEDIGT — dieser Ordner wird nicht mehr gebraucht
>
> Die Arbeit ist inzwischen zurückgeholt, **fertiggestellt** und auf `main`
> gepusht (Commit `e96ba2b` "chore: drop the plenary.nvim dependency").
>
> Beim Zurückholen kam heraus, dass die Entfernung noch unvollständig war:
> `lua/cmdlog/core/store.lua` kam mit den stats/errors/project-history-
> Features von `main` dazu — also *nachdem* die Entfernung begonnen wurde —
> und war die letzte Datei, die noch `plenary.path` importierte. Sie ist
> jetzt ebenfalls umgestellt, und dabei deutlich kürzer geworden (~65 → ~35
> Zeilen), weil `lib.nvim.fs.write.to_file` das Anlegen der Elternverzeichnisse
> schon übernimmt und die handgebaute `ensure_parent_exists`-Kaskade samt
> `io.open`-Fallback entfallen konnte.
>
> Verifiziert **ohne plenary im runtimepath**: alle Module laden, `setup()`
> läuft, `:Cmdlog` registriert sich, `store.save_json`/`load_json` machen
> einen korrekten Round-Trip inkl. Anlegen eines fehlenden Verzeichnisses.
>
> Der Stash `stash@{0}` existiert noch als zusätzliche Sicherheit und kann
> mit `git stash drop` entfernt werden. Dieser Ordner ebenfalls.

---

**Angelegt:** 2026-07-30, im Rahmen der Roadmap-Umsetzung.
**Grund:** In `E:/repos/cmdlog.nvim` lagen uncommittete Änderungen im Working
Tree (Branch `feature-notes`). Sie wurden gestasht, um die Roadmap-Arbeit auf
einem sauberen Baum zu machen — und hier zusätzlich als Patch gesichert,
damit sie unabhängig vom Stash (und unabhängig von der laufenden Session)
greifbar bleiben.

## Was drin ist

Entfernung von `nvim-lua/plenary.nvim` als Abhängigkeit:

| Datei | Änderung |
|---|---|
| `README.md` | plenary aus allen 5 Installations-Blöcken (lazy/packer/vim-plug) + Feature-Liste entfernt |
| `doc/cmdlog.nvim.txt` | dito in der Vimdoc |
| `lua/cmdlog/core/favorites.lua` | plenary-Nutzung ersetzt |
| `lua/cmdlog/health.lua` | plenary-Check aus `:checkhealth` entfernt |
| `lua/cmdlog/ui/telescope-previewer.lua` | plenary-Nutzung ersetzt (größter Block, ~56 Zeilen) |

Insgesamt 5 Dateien, +36/−68 Zeilen.

## Zurückholen — zwei Wege

**Weg 1 (Normalfall): aus dem Stash.** Der Stash trägt eine eindeutige
Nachricht, damit er auch nach Wochen wiederauffindbar ist:

```bash
cd E:/repos/cmdlog.nvim && git stash list
```

Suche den Eintrag `WIP: drop plenary dependency (pre-roadmap-work backup)` und
hole ihn zurück:

```bash
cd E:/repos/cmdlog.nvim && git stash pop
```

**Weg 2 (Fallback): aus diesem Patch.** Falls der Stash weg ist, verloren
ging, oder du auf einem anderen Rechner sitzt:

```bash
cd E:/repos/cmdlog.nvim && git apply "C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/WIP-BACKUP/cmdlog-plenary-removal.patch"
```

Wenn der Patch wegen zwischenzeitlicher Änderungen nicht sauber greift, hilft
ein Drei-Wege-Merge:

```bash
cd E:/repos/cmdlog.nvim && git apply --3way "C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/WIP-BACKUP/cmdlog-plenary-removal.patch"
```

## Achtung: Branch prüfen

Der Patch wurde auf `feature-notes` erstellt. Im Zuge der Roadmap-Arbeit wurde
`feature-notes` nach `main` gemergt. Vor dem Zurückholen also prüfen, auf
welchem Branch du stehst:

```bash
cd E:/repos/cmdlog.nvim && git branch --show-current && git status --short
```

`cmdlog-files.txt` in diesem Ordner listet die betroffenen Dateien so, wie
`git status --porcelain` sie zum Zeitpunkt der Sicherung gemeldet hat.

## Wenn alles zurück ist

Dieser Ordner kann dann gelöscht werden — er ist reines Sicherungsmaterial,
kein Teil der Doku.
