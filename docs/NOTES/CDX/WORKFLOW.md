# Workflow: neuer Claude-Code-Chat

Kurzanleitung, was beim Start eines neuen Chats passiert und was du selbst
tun musst. Hintergrund und Dateien: [README.md](README.md),
[KONZEPT-multi-stack.md](KONZEPT-multi-stack.md).

## 1. Was Claude Code automatisch laedt (du musst nichts einfuegen)

| Quelle                                   | Inhalt                                             | Wo es herkommt                  |
|------------------------------------------|----------------------------------------------------|---------------------------------|
| `~/.claude/CLAUDE.md`                    | Sprache, Arbeitsweise, Doku-Struktur, Git-Regeln   | Symlink auf `CLAUDE.global.md`  |
| `~/.claude/settings.json`                | Allowlist + Hooks (`check-hook.js`, `check-stop.js`)| Merge aus `settings.global.json`|
| `<repo>/CLAUDE.md`                       | Stack-Regeln (Lua, Rust, C++, Web, Tauri)          | `templates/<stack>/`            |
| `<repo>/.claude/settings.json`           | Stack-Allowlist (cargo, pnpm, cmake ...)           | `templates/<stack>/`            |
| Env-Vars `NVIM_CONFIG`, `REPOS_DIR`      | Pfade fuer Docs/Repos                              | `setup-claude-code`             |

Deshalb: **keine Regeln mehr in den Chat pasten.** Aendern sich Regeln, dann
in der jeweiligen Datei anpassen, committen, pushen.

## 2. Ablauf pro neuem Chat

1. **Projektordner waehlen** (Desktop-App: Repo-Ordner statt "Kein Ordner").
   Ohne Ordner arbeitet Claude im leeren Scratch-Workspace und sieht weder
   `CLAUDE.md` noch Projekt-Settings des Repos.
2. **Aufgabe in einem Satz + Ziel-Repo nennen.** Beispiel:
   "Im ui.nvim: Picker X um Y erweitern, Tests in /TESTS."
3. **Bei Bedarf Kontext verlinken statt einfuegen:** Handover-Datei aus
   `$NVIM_CONFIG/docs` oder Backlog aus den wkdbooks nennen, Claude liest sie.
4. **Ein Chat = eine Aufgabe.** Nach Abschluss committet/pusht Claude auf
   `main` (Regel aus `CLAUDE.global.md`). Fuer die naechste Aufgabe neuen Chat
   starten; Zwischenstaende gehoeren in ein Handover-File, nicht in den Chat.
5. **Am Ende pruefen:** `git log -1`, ggf. auf den anderen Maschinen `git pull`.

## 3. Neues Repo einrichten (einmal pro Repo)

```powershell
cd B:\repos\<repo>
node "$env:NVIM_CONFIG\docs\NOTES\CDX\new-project-claude.js" <nvim-plugin|rust|cpp|tauri|web>
git add CLAUDE.md .claude/settings.json; git commit -m "chore: add Claude Code project config"
```

- Existiert schon eine `CLAUDE.md`, wird die Vorlage als `CLAUDE.md.new`
  daneben gelegt (nichts wird ueberschrieben) - manuell zusammenfuehren.
- Alle `.nvim`-Plugin-Repos brauchen einmal `nvim-plugin`, sonst fehlen die
  Lua-Regeln (der Lua-Hook laeuft trotzdem global).
- Tauri-Projekte (docmap-desktop): Stack `tauri`.

## 4. Neue Maschine einrichten (einmal pro Rechner)

1. Nvim-Config-Repo klonen bzw. pullen (Windows: `%LOCALAPPDATA%\nvim`).
2. Node.js installieren (Voraussetzung fuer Setup und Hooks), Claude
   Code/Desktop-App installieren und mit dem Account anmelden.
3. Setup ausfuehren:
   - Windows: `pwsh -File "$env:LOCALAPPDATA\nvim\docs\NOTES\CDX\setup-claude-code.ps1"`
   - Linux/macOS: `bash ~/.config/nvim/docs/NOTES/CDX/setup-claude-code.sh`
   Am Ende fragt das Skript nach Toolchain-Profilen (`nvim,cpp,rust,web,tauri`).
   Einzeln nachholen: `node setup-devtools.js --profile nvim,rust --dry-run`
   (ohne `--dry-run` installiert es nach Rueckfrage).
4. Claude-App/Terminal **neu starten** (Env-Vars greifen erst dann).
5. Repos klonen, pro Repo Abschnitt 3.

## 5. Schnelltest, ob alles greift

Im neuen Chat in einem Repo fragen: "Welche Regeln aus CLAUDE.md gelten hier,
und was sind NVIM_CONFIG und REPOS_DIR?" Claude sollte die globalen und die
Repo-Regeln nennen und die richtigen Pfade kennen. Hooks pruefst du, indem
eine `.lua`-Datei absichtlich falsch formatiert wird: Claude bekommt dann den
stylua-Fehler zurueck.

## 6. Branches aus Claude-Sessions

Laeuft eine Session in einem Worktree, entsteht ein Branch `claude/<name>`.
Auf den lokalen Rechner holen:

```bash
git fetch --all
git merge origin/claude/<name>   # oder: git checkout claude/<name>
git push
```

`claude/learn-plan-viewer` ist bereits nach `main` gemergt.

## 7. Hook-Verhalten im Ueberblick

- **Nach jedem Edit** (`check-hook.js`): schnelle Einzeldatei-Checks
  (stylua/luacheck, rustfmt, clang-format, prettier).
- **Am Ende eines Durchlaufs** (`check-stop.js`): nur bei geaenderten Dateien
  `cargo clippy --all-targets -- -D warnings` (Rust) bzw. `tsc --noEmit` (TS,
  wenn lokal installiert). Schlaegt das fehl, muss Claude erst korrigieren.
- Fehlende Tools werden uebersprungen, nie hart blockiert.
