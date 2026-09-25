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

| Datei                    | Zweck                                                                 |
|---------------------------|------------------------------------------------------------------------|
| `CLAUDE.global.md`        | Quelle der Wahrheit fuer `~/.claude/CLAUDE.md` (Verhaltensregeln, Konventionen) |
| `settings.global.json`    | Quelle der Wahrheit fuer `~/.claude/settings.json` (Permissions-Allowlist + Hooks) |
| `check-lua-hook.js`       | Vom PostToolUse-Hook aufgerufenes Skript: prueft `.lua`-Dateien nach jedem Edit/Write mit `stylua --check` + `luacheck` |
| `setup-claude-code.ps1`   | Rollt die beiden Vorlagen oben nach `~/.claude/` aus. Idempotent, auf jeder Maschine erneut ausfuehrbar. |

## Funktionsprinzip

- **`CLAUDE.md`**: Wird per Symlink nach `~/.claude/CLAUDE.md` verlinkt.
  Aenderungen an `CLAUDE.global.md` wirken sich nach `git pull` sofort aus -
  kein erneutes Setup noetig. Nur falls Symlinks auf einer Maschine nicht
  moeglich sind (kein Developer Mode, keine Admin-Rechte), wird stattdessen
  kopiert - dann muss man nach Aenderungen `setup-claude-code.ps1` erneut
  laufen lassen.
- **`settings.json`**: Wird **gemerged**, nicht ueberschrieben. Bestehende
  Eintraege (z. B. maschinenspezifische Permissions) bleiben erhalten, die
  Vorlage wird nur ergaenzt (Allowlist-Eintraege vereinigt, Hooks nur
  hinzugefuegt, wenn noch nicht vorhanden). Vor jedem Schreiben wird ein
  Backup `settings.json.bak-<timestamp>` angelegt.
- **Env-Variablen**: `$NVIM_CONFIG` wird automatisch aus dem Speicherort
  dieses Skripts ermittelt. `$REPOS_DIR` ist pro Maschine unterschiedlich
  (z. B. `B:\repos` hier, ggf. andere Pfade auf Heim-PC/Workstation) und wird
  beim ersten Lauf interaktiv abgefragt, danach wiederverwendet. Beide werden
  als **User-Env-Var** gesetzt (`[Environment]::SetEnvironmentVariable(...,
  'User')`) - gelten also erst in neu gestarteten Shells/der Claude-Code-App.

## Was die Hooks konkret machen

`settings.global.json` registriert einen `PostToolUse`-Hook auf
`Edit|Write`: Nach jedem Datei-Edit prueft `check-lua-hook.js`, ob die
betroffene Datei auf `.lua` endet, und laesst dann `stylua --check` sowie
`luacheck` darueber laufen. Schlaegt eine der beiden Pruefungen fehl, bricht
der Hook mit Exit-Code 2 ab - Claude bekommt die Fehlermeldung direkt
zurueckgespielt und muss die Datei korrigieren, bevor es weitergeht. Das
erzwingt technisch, was in `CLAUDE.global.md` als Regel steht ("Code muss
luacheck/stylua clean sein").

Die Permissions-Allowlist in `settings.global.json` erlaubt ein paar
ungefaehrliche, haeufig gebrauchte Befehle ohne Rueckfrage (`git status/diff/
log/add/commit/push/pull`, `luacheck`, `stylua`, `ls`, `find`). Das reduziert
Permission-Prompts, ohne echte Freigaben wie `push --force` o.ae. pauschal
zu erteilen.

## Setup auf einer (neuen) Maschine

```powershell
pwsh -File "$env:LOCALAPPDATA\nvim\docs\NOTES\CDX\setup-claude-code.ps1"
```

Ablauf:

1. Setzt/prueft `NVIM_CONFIG` (automatisch) und `REPOS_DIR` (fragt beim
   ersten Mal nach, falls noch nicht gesetzt).
2. Verlinkt/kopiert `CLAUDE.global.md` nach `~/.claude/CLAUDE.md` (mit
   Backup, falls dort schon etwas anderes liegt).
3. Merged `settings.global.json` in `~/.claude/settings.json` (mit Backup).

Danach Claude-Code-App/Terminal neu starten, damit die Env-Vars gezogen
werden.

## Bei Aenderungen an den Regeln

1. `CLAUDE.global.md` bzw. `settings.global.json` in diesem Ordner anpassen.
2. Committen/pushen (siehe Git-Regel in `CLAUDE.global.md` - main branch,
   sofort).
3. Auf den anderen Maschinen `git pull` (+ bei `settings.json`-Aenderungen
   `setup-claude-code.ps1` erneut ausfuehren, da die Merge-Logik nicht
   automatisch bei jedem Claude-Code-Start laeuft).

## API-Zugang

Kein `ANTHROPIC_API_KEY` als Env-Var setzen - die Anmeldung laeuft ueber die
Claude-Desktop-App-Subscription (OAuth-Login), nicht ueber einen API-Key.
Ein API-Key waere nur fuer separates API-Billing (z. B. CI-Nutzung ausserhalb
der App) relevant und gehoert dann in keinem Fall in eine versionierte Datei
in diesem Ordner, sondern hoechstens als maschinenlokale User-Env-Var oder
Secret-Manager-Eintrag.

## Bekannte Einschraenkungen

- Der Merge in `setup-claude-code.ps1` ist bewusst simpel gehalten (Array-
  Union bei Permissions, Vorhandensein-Check bei Hooks ueber
  `matcher`+`command`). Komplexere manuelle `settings.json`-Strukturen
  (z. B. verschachtelte `PreToolUse`-Hooks mit demselben Matcher aber
  anderem Inhalt) bitte im Zweifel manuell pruefen statt blind laufen
  lassen.
- Symlink-Erstellung fuer `CLAUDE.md` braucht auf Windows entweder
  Developer Mode oder Admin-Rechte. Ohne beides faellt das Skript automatisch
  auf eine Kopie zurueck (siehe oben).
