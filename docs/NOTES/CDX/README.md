# Claude-Code-Setup (Multi-Machine: PC / Heim-PC / Workstation)

Dieser Ordner ist Teil des nvim-Config-Repos (`StefanBartl/nvim` auf GitHub)
und damit auf allen drei Maschinen per `git pull` synchron. Er enthaelt die
Vorlagen fuer die globale Claude-Code-Konfiguration - die eigentlich in
`~/.claude/` (also pro Maschine, nicht versioniert) liegt - plus ein Skript,
das diese Vorlagen dorthin ausrollt.

Hintergrund: `~/.claude/CLAUDE.md` und `~/.claude/settings.json` sind reine
Maschinen-lokale Dateien, die Claude Code selbst nicht synct. Ohne diesen
Ordner muesste man Regeln/Settings auf jedem Rechner von Hand nachpflegen.

## Dateien in diesem Ordner

| Datei                       | Zweck                                                                 |
|------------------------------|------------------------------------------------------------------------|
| `CLAUDE.global.md`           | Quelle der Wahrheit fuer `~/.claude/CLAUDE.md` (Verhaltensregeln, Konventionen) |
| `settings.global.json`       | Quelle der Wahrheit fuer `~/.claude/settings.json` (Permissions-Allowlist + Hooks) |
| `check-hook.js`              | Vom PostToolUse-Hook aufgerufener Dispatcher: prueft je nach Endung `.lua` (stylua+luacheck), `.rs` (rustfmt), C/C++ (clang-format, nur mit `.clang-format`), `.ts/.js/.css/.json` (projektlokales prettier) |
| `setup-devtools.js` + `tools.json` | Installiert fehlende Toolchains pro Profil (`nvim`, `cpp`, `rust`, `web`, `tauri`) via winget/apt/brew. `node setup-devtools.js --profile nvim,rust --dry-run` |
| `new-project-claude.js`      | Kopiert die Projekt-Vorlage aus `templates/<stack>/` (`CLAUDE.md` + `.claude/settings.json`) in ein Repo: `node new-project-claude.js rust [zielordner]` |
| `templates/`                 | Vorlagen je Stack: `nvim-plugin`, `rust`, `cpp`, `tauri`, `web` |
| `KONZEPT-multi-stack.md`     | Begruendung/Architektur der drei Schichten |
| `merge-claude-settings.js`   | Gemeinsame Merge-Logik fuer `settings.json`, von beiden Setup-Skripten unten aufgerufen (verhindert, dass Windows- und Unix-Skript bei dieser Logik auseinanderlaufen) |
| `setup-claude-code.ps1`      | Windows: rollt die Vorlagen oben nach `~/.claude/` aus. Idempotent. |
| `setup-claude-code.sh`       | Linux/macOS: dasselbe wie oben, plus `~/.claude/env.sh` fuer die Env-Variablen. Idempotent. |

## Funktionsprinzip

- **`CLAUDE.md`**: Wird per Symlink nach `~/.claude/CLAUDE.md` verlinkt.
  Aenderungen an `CLAUDE.global.md` wirken sich nach `git pull` sofort aus -
  kein erneutes Setup noetig. Nur falls Symlinks auf einer Maschine nicht
  moeglich sind (kein Developer Mode, keine Admin-Rechte), wird stattdessen
  kopiert - dann muss man nach Aenderungen `setup-claude-code.ps1` erneut
  laufen lassen.
- **`settings.json`**: Wird **gemerged**, nicht ueberschrieben (Logik in
  `merge-claude-settings.js`, per `node` von beiden Setup-Skripten
  aufgerufen). Bestehende Eintraege (z. B. maschinenspezifische Permissions)
  bleiben erhalten, die Vorlage wird nur ergaenzt (Allowlist-Eintraege
  vereinigt, Hooks nur hinzugefuegt, wenn noch nicht vorhanden). Vor jedem
  Schreiben wird ein Backup `settings.json.bak-<timestamp>` angelegt.
  Braucht `node` auf PATH (wird eh fuer `check-hook.js` gebraucht).
- **Env-Variablen**: `$NVIM_CONFIG` wird automatisch aus dem Speicherort
  dieses Skripts ermittelt. `$REPOS_DIR` ist pro Maschine unterschiedlich
  (z. B. `B:\repos` hier, ggf. andere Pfade auf Heim-PC/Workstation) und wird
  beim ersten Lauf interaktiv abgefragt, danach wiederverwendet.
  - **Windows**: als User-Env-Var gesetzt
    (`[Environment]::SetEnvironmentVariable(..., 'User')`) - gilt in neu
    gestarteten Shells/der Claude-Code-App.
  - **Linux/macOS**: es gibt kein Registry-Pendant, daher landen die Werte in
    `~/.claude/env.sh` (bei jedem Lauf neu generiert), und `setup-claude-code.sh`
    ergaenzt eine `source`-Zeile in `~/.bashrc` und/oder `~/.zshrc` (welche
    Datei jeweils existiert), falls dort noch nicht vorhanden. Gilt ab der
    naechsten Shell bzw. `source ~/.claude/env.sh`.

## Drei Schichten (Multi-Stack)

1. **Claude-Setup** (`setup-claude-code.*`): globale `CLAUDE.md` (stack-neutral) + `settings.json`.
2. **Toolchains** (`setup-devtools.js`): Programme pro Profil installieren (winget; MSVC primaer, clang als Fallback). Gewaehlte Profile landen in `~/.claude/devtools.profile`.
3. **Projekt-Konfig** (`new-project-claude.js`): stack-spezifische `CLAUDE.md` + Allowlist pro Repo, im Repo versioniert.

Neues Repo einrichten: `node $NVIM_CONFIG/docs/NOTES/CDX/new-project-claude.js <stack>` im Repo-Root, dann committen.
Wichtig: Die Lua-/Plugin-Regeln stehen nicht mehr global, sondern in `templates/nvim-plugin/CLAUDE.md` - jedes Plugin-Repo einmal mit `new-project-claude.js nvim-plugin` ausstatten.

## Was die Hooks konkret machen

`settings.global.json` registriert einen `PostToolUse`-Hook auf
`Edit|Write`: Nach jedem Datei-Edit prueft `check-hook.js` anhand der Dateiendung und laesst die
passenden Checks darueber laufen (bei `.lua`: `stylua --check` und `luacheck`). Schlaegt eine der beiden Pruefungen fehl, bricht
der Hook mit Exit-Code 2 ab - Claude bekommt die Fehlermeldung direkt
zurueckgespielt und muss die Datei korrigieren, bevor es weitergeht. Das
erzwingt technisch, was in `CLAUDE.global.md` als Regel steht ("Code muss
luacheck/stylua clean sein").

Die Permissions-Allowlist in `settings.global.json` erlaubt ein paar
ungefaehrliche, haeufig gebrauchte Befehle ohne Rueckfrage (`git status/diff/
log/add/commit/pull`, `luacheck`, `stylua`, `ls`). `git push` ist bewusst
**nicht** als `push:*`-Wildcard freigegeben, sondern nur als exakte,
ungefaehrliche Formen (`git push`, `git push origin main`, `git push origin
HEAD`) - ein Wildcard wuerde stillschweigend auch `git push --force`
durchlassen. `find` ist aus demselben Grund nicht in der Liste: `find -exec`
kann beliebige Befehle ausfuehren, ein `find:*`-Wildcard haette das ohne
Rueckfrage erlaubt.

## Setup auf einer (neuen) Maschine

Windows:

```powershell
pwsh -File "$env:LOCALAPPDATA\nvim\docs\NOTES\CDX\setup-claude-code.ps1"
```

Linux/macOS (Pfad je nach `NVIM_CONFIG`-Ort anpassen, z. B.
`~/.config/nvim` oder `~/.local/share/nvim` - wo auch immer dieses Repo dort
liegt):

```bash
bash ~/.config/nvim/docs/NOTES/CDX/setup-claude-code.sh
```

Ablauf (beide Skripte, gleiches Prinzip):

1. Setzt/prueft `NVIM_CONFIG` (automatisch) und `REPOS_DIR` (fragt beim
   ersten Mal nach, validiert dass der Pfad existiert).
2. Verlinkt/kopiert `CLAUDE.global.md` nach `~/.claude/CLAUDE.md` (mit
   Backup, falls dort schon etwas anderes liegt).
3. Merged `settings.global.json` in `~/.claude/settings.json` (mit Backup,
   ueber `merge-claude-settings.js`).

Danach Claude-Code-App/Terminal neu starten, damit die Env-Vars gezogen
werden.

## Bei Aenderungen an den Regeln

1. `CLAUDE.global.md` bzw. `settings.global.json` in diesem Ordner anpassen.
2. Committen/pushen (siehe Git-Regel in `CLAUDE.global.md` - main branch,
   sofort).
3. Auf den anderen Maschinen `git pull` (+ bei `settings.json`-Aenderungen
   das jeweilige Setup-Skript erneut ausfuehren, da die Merge-Logik nicht
   automatisch bei jedem Claude-Code-Start laeuft).

## API-Zugang

Kein `ANTHROPIC_API_KEY` als Env-Var setzen - die Anmeldung laeuft ueber die
Claude-Desktop-App-Subscription (OAuth-Login), nicht ueber einen API-Key.
Ein API-Key waere nur fuer separates API-Billing (z. B. CI-Nutzung ausserhalb
der App) relevant und gehoert dann in keinem Fall in eine versionierte Datei
in diesem Ordner, sondern hoechstens als maschinenlokale User-Env-Var oder
Secret-Manager-Eintrag.

## Bekannte Einschraenkungen

- Der Merge in `merge-claude-settings.js` ist bewusst simpel gehalten
  (Array-Union bei Permissions, Vorhandensein-Check bei Hooks ueber
  `matcher`+`command`). Komplexere manuelle `settings.json`-Strukturen
  (z. B. verschachtelte `PreToolUse`-Hooks mit demselben Matcher aber
  anderem Inhalt) bitte im Zweifel manuell pruefen statt blind laufen
  lassen.
- Symlink-Erstellung fuer `CLAUDE.md` braucht auf Windows entweder
  Developer Mode oder Admin-Rechte. Ohne beides faellt `setup-claude-code.ps1`
  automatisch auf eine Kopie zurueck (siehe oben). Auf Linux/macOS
  funktionieren unprivilegierte Symlinks immer, `setup-claude-code.sh` hat
  daher keinen Kopie-Fallback.
- Beide Setup-Skripte brauchen `node` auf PATH (fuer den Settings-Merge und
  fuer `check-hook.js`). `stylua`/`luacheck` sind nur fuer den Hook
  noetig - fehlen sie auf einer Maschine, wird der jeweilige Check
  uebersprungen statt hart zu blockieren (siehe `check-hook.js`).
