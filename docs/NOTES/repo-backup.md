# Wochen-Backup der Repos ohne Remote

Manche Repos liegen absichtlich nur auf diesem Rechner, heute `WKDBook-Tricentis` (Kundendaten, kein GitHub). Für sie
schreibt `lua/config/repo_backup.lua` einmal pro Woche ein Backup.

## Ablauf

- Beim Start von Neovim (Phase `repo_backup` in `init.lua`, nach dem Aufbau der Oberfläche, im Hintergrund).
- Fällig ist ein Repo, wenn seine Backup-Datei fehlt oder älter als 7 Tage ist (`M.EVERY`). Sonst passiert nichts.
- `git bundle create <repo>.bundle.tmp --all`, dann `git bundle verify`, erst danach wird die alte Datei ersetzt.
  Ein fehlgeschlagener Lauf meldet sich und lässt das vorige Backup stehen.
- Fehlt der Repo-Ordner (anderer Rechner), wird er still übersprungen.

## Ort

`$REPO_BACKUP_DIR`, sonst `<Elternordner von $REPOS_DIR>/repos-backup/weekly/`, hier also
`C:/repos-backup/weekly/WKDBook-Tricentis.bundle`. Eine Datei pro Repo, keine Historie von Backups.

## Wiederherstellen

```sh
git clone C:/repos-backup/weekly/WKDBook-Tricentis.bundle WKDBook-Tricentis
```

Der Klon hat das Bundle als `origin`; danach `git remote remove origin`, damit das Repo wieder ohne Remote ist.

## Grenzen

Das Backup liegt auf derselben Platte. Es schützt vor git-Unfällen und gelöschten Ordnern, nicht vor einem Plattenausfall
oder dem Verlust des Rechners.

## Ein Repo hinzufügen

Ordnernamen (unter `$REPOS_DIR`) in `M.REPOS` eintragen. Test: `nvim -n -i NONE --headless -u NONE -l TESTS/run.lua repo_backup`.
Sofort ein Backup erzwingen: die `.bundle`-Datei löschen und Neovim neu starten.
