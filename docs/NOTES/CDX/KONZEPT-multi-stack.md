# Konzept: Claude-Code-Setup fuer mehrere Stacks (Nvim / C++ / Rust / Web / Tauri)

Status: umgesetzt (2026-09-25). Abweichungen: `setup-devtools` und `new-project-claude` sind Node-Skripte (ein Code fuer alle OS) statt ps1/sh; der Hook-Dispatcher enthaelt nur schnelle Checks, ein Stop-Hook fuer `clippy` ist noch offen. Entscheidungen: winget, MSVC (Fallback clang), Neovim-Installation ueber winget im Profil `nvim`. Ergaenzt `README.md` in diesem Ordner.

## Projekte und Stacks

| Projekt         | Stack                     |
|-----------------|---------------------------|
| `*.nvim`-Plugins| Lua (Neovim)             |
| docmap-desktop  | Tauri (Rust) + Web (TS)   |
| takt            | C++ / Rust (in Planung)   |
| wkd             | C++                       |

## Kernentscheidung: drei getrennte Schichten

Nicht ein grosses Setup-Skript, sondern drei Schichten mit je eigenem Zweck:

1. **Claude-Setup** (`setup-claude-code.ps1/.sh`, existiert schon)
   Nur `~/.claude/CLAUDE.md`, `settings.json`, Env-Vars. Stack-neutral.
   Aendert sich selten, laeuft auf jeder Maschine gleich.
2. **Toolchain-Bootstrap** (NEU: `setup-devtools.ps1/.sh`)
   Installiert Programme (nvim, stylua, luacheck, node, rustup, cmake,
   clang-format ...) ueber winget/scoop bzw. apt/brew. Profil-basiert.
3. **Projekt-Konfiguration** (pro Repo, versioniert im Repo)
   `CLAUDE.md` + `.claude/settings.json` mit stack-spezifischer Allowlist
   und Hooks. Wandert per `git clone` automatisch auf alle Maschinen.

## Soll nvim-Installation ins Claude-Setup?

**Nein, nicht in `setup-claude-code`.** Gruende:

- Software installieren hat Seiteneffekte (Admin-Rechte, Versionen, PATH).
  Das gehoert nicht in ein Skript, das "nur Konfig verlinkt" und beliebig oft
  gefahrlos laufen soll.
- Claude Code *kann* Tools per Skript installieren, aber ich wuerde das nicht
  von Claude ausfuehren lassen, sondern selbst starten. Claude braucht die
  Tools nur *vorhanden*, nicht selbst installiert.
- Nvim-Installation ist bereits Teil der Config bzw. des Repos; eine
  zweite, konkurrierende Installationslogik wuerde auseinanderlaufen.

Stattdessen: eigenes `setup-devtools` mit Profilen, das `setup-claude-code`
optional am Ende anbietet ("Toolchains jetzt auch installieren? [j/N]").

## Toolchain-Bootstrap mit Profilen

```
pwsh -File setup-devtools.ps1 -Profile nvim,rust,web
```

| Profil | Installiert                                             |
|--------|---------------------------------------------------------|
| core   | git, node, ripgrep, fd (immer)                          |
| nvim   | neovim, stylua, luacheck, lua-language-server           |
| cpp    | cmake, ninja, clang/clang-format, (Windows: VS Build Tools) |
| rust   | rustup, rustfmt, clippy (Tauri: WebView2 auf Windows)   |
| web    | node (fnm/volta), pnpm, prettier, eslint                |

- Idempotent: pro Tool `Get-Command` pruefen, nur fehlendes installieren.
- Windows: winget bzw. scoop; Linux: apt; macOS: brew. Paketnamen in einer
  Tabelle (`tools.json`), nicht im Skriptcode verteilt.
- Pro Maschine reicht ein Profil-Satz, z. B. Workstation = alles,
  Heim-PC = nvim+web. Auswahl wird in `~/.claude/devtools.profile` gemerkt.

## Braucht jeder Stack eine eigene "Umgebung"?

**Nein.** Keine separaten Claude-Umgebungen/Accounts/Container noetig. Die
Trennung passiert ueber das Arbeitsverzeichnis:

- Claude Code liest beim Start `CLAUDE.md` und `.claude/settings.json` des
  Projekts *zusaetzlich* zur globalen Konfig. Ein Repo = eine "Umgebung".
- Globale `CLAUDE.md` bleibt schlank und stack-neutral (Sprache, Git-Regeln,
  Doku-Struktur, Agent-Regel). Die aktuellen Lua-/Nvim-spezifischen Regeln
  ("luacheck/stylua clean", Plugin-Pfade) wandern in eine Projekt-Vorlage.
- Projekt-Vorlagen liegen hier in `templates/`:
  - `templates/nvim-plugin/CLAUDE.md` + `.claude/settings.json`
  - `templates/tauri/...`, `templates/cpp/...`, `templates/rust/...`
  - `new-project-claude.ps1 -Stack rust` kopiert die passende Vorlage in das
    aktuelle Repo (einmalig pro Repo).

### Stack-spezifische Allowlist (Beispiele)

- rust: `cargo build/check/test/fmt/clippy`
- cpp: `cmake --build`, `ctest`, `clang-format --dry-run`
- web/tauri: `pnpm install/build/test/lint`, `cargo tauri build` (letzteres
  eher mit Rueckfrage lassen)
- Bewusst NICHT freigeben: `cargo run`, `pnpm run <beliebig>`, `npx`
  (fuehren beliebigen Code aus), `git push --force`.

### Hooks pro Stack

`check-lua-hook.js` wird zu einem Dispatcher `check-hook.js`, der nach
Dateiendung waehlt:

| Endung        | Pruefung                              |
|---------------|----------------------------------------|
| `.lua`        | `stylua --check`, `luacheck`           |
| `.rs`         | `cargo fmt --check`, ggf. `clippy`     |
| `.cpp/.h`     | `clang-format --dry-run --Werror`      |
| `.ts/.tsx/.js`| `prettier --check`, `eslint`           |

Fehlt ein Tool auf einer Maschine, wird der Check uebersprungen (wie heute).
Langsame Checks (`clippy`, `cargo check`) nicht als PostToolUse-Hook pro
Edit, sondern als Stop-Hook (einmal am Ende eines Durchlaufs).

## Vorgeschlagene Ordnerstruktur

```
docs/NOTES/CDX/
  README.md                 (besteht)
  KONZEPT-multi-stack.md    (diese Datei)
  CLAUDE.global.md          (verschlankt, stack-neutral)
  settings.global.json
  merge-claude-settings.js
  check-hook.js             (aus check-lua-hook.js)
  setup-claude-code.ps1/.sh (besteht)
  setup-devtools.ps1/.sh    (NEU)
  tools.json                (NEU, Paketnamen pro OS/Profil)
  new-project-claude.ps1/.sh(NEU)
  templates/{nvim-plugin,rust,cpp,tauri,web}/
```

## Umsetzungsreihenfolge

1. `CLAUDE.global.md` aufteilen (global neutral + `templates/nvim-plugin`).
2. `check-lua-hook.js` -> `check-hook.js` (Dispatcher), Stop-Hook fuer
   langsame Checks.
3. Templates fuer rust/cpp/tauri/web anlegen.
4. `new-project-claude` schreiben.
5. `setup-devtools` + `tools.json` (zuletzt, hat die meisten Seiteneffekte
   und muss pro OS getestet werden).

## Offene Fragen

- Soll `setup-devtools` auch Neovim selbst installieren, oder nutzt du dafuer
  weiter deinen bisherigen Weg?
- Windows-Paketmanager: winget (vorinstalliert) oder scoop?
- C++-Toolchain unter Windows: MSVC (Build Tools) oder clang/MinGW?
