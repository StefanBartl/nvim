# usrcmds.update_repos

Kleiner Neovim-User-Command zum Aktualisieren mehrerer Git-Repositories in einem gemeinsamen Verzeichnis.

---

## Voraussetzung

* Neovim ≥ 0.10
* `git` ist im `PATH`
* Repositories liegen jeweils in eigenen Unterordnern
* Optionale Umgebungsvariable `REPOS_DIR` zeigt auf das Basisverzeichnis

Beispiel:

```
REPOS_DIR=~/repos
```

---

---

## Verwendung

Standardmäßig wird `REPOS_DIR` verwendet:

```
:ReposUpdate
```

Alternativ kann ein expliziter Pfad angegeben werden:

```
:ReposUpdate ~/src/repos
```

---

## Verhalten

* alle Unterordner werden geprüft
* nur Verzeichnisse mit `.git` werden verarbeitet
* ausgeführt werden:

  * `git fetch --all --prune`
  * `git pull --ff-only`
* Fehler werden gesammelt und am Ende ausgegeben
* nicht funktionierende Repositories blockieren die anderen nicht

---

## Hinweise

* keine automatischen Merges
* lokale Änderungen verhindern ein Update
* ideal geeignet für Plugin-, Tool- oder Monorepo-Sammlungen

---

