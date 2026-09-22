# LazyGit — User-Commands

> **Entfernt, ersetzt durch gitsuite.nvim.** `kdheepak/lazygit.nvim` ist aus
> [lua/plugins/git.lua](../../../../../lua/plugins/git.lua) raus; gitsuite.nvims
> `:Git ui lazygit [dir]` öffnet denselben `lazygit`-Binary in einem eigenen
> Float. Die Bridge-Commands unten (`:LazygitBadd`/`:LazygitReplace`, vormals
> `lua/config/lazygit/`, jetzt entfernt) leben als `O`/`<C-o>` unverändert in
> gitsuite.nvims `features/ui/lazygit/{badd,replace}.lua` weiter. Blatt bleibt
> als historischer Extern-Korpus-Eintrag stehen, alle Links unten zeigen auf
> entfernte Dateien.

Plugin: [`kdheepak/lazygit.nvim`](https://github.com/kdheepak/lazygit.nvim).

Zwei Quellen von Commands:

1. **Plugin-eigene Commands** — vom Plugin selbst registriert
   (`plugin/lazygit.vim` im Plugin-Repo), in dieser Config unverändert benutzt.
2. **Bridge-Commands** dieser Config — registriert in
   `lua/config/lazygit/init.lua` (entfernt, siehe Hinweis oben)
   (`M.setup()`, aufgerufen aus dem `config`-Hook des Lazy-Specs in
   [lua/plugins/git.lua](../../../../../lua/plugins/git.lua)) —
   ermöglichen es LazyGit-Custom-Commands (via `nvr`), Dateien in der
   Eltern-Neovim-Instanz zu öffnen, ohne LazyGit zu verlassen.

---

## 1. Plugin-eigene Commands **[default]**

Vom Plugin selbst über `cmd = {...}` im Lazy-Spec lazy-geladen
([lua/plugins/git.lua](../../../../../lua/plugins/git.lua) Z. 11-17), inhaltlich
unverändert gegenüber dem Plugin-Default.

| Command | Wirkung |
|---|---|
| `:LazyGit` | LazyGit-Floating-Window im aktuellen Arbeitsverzeichnis öffnen. |
| `:LazyGitCurrentFile` | LazyGit im Projekt-Root der **aktuellen Datei** öffnen (statt des globalen cwd). |
| `:LazyGitConfig` | LazyGits `config.yml` direkt in Neovim öffnen (erzeugt Defaults, falls die Datei fehlt). |
| `:LazyGitFilter` | LazyGit-Commit-Historie des **Projekts** im Floating-Window. |
| `:LazyGitFilterCurrentFile` | LazyGit-Commit-Historie der **aktuellen Datei** im Floating-Window. |
| `:LazyGitLog` | LazyGit im `log`-Modus öffnen. Vom Plugin registriert, aber **nicht** im `cmd`-Table dieser Config gelistet — daher nur nutzbar, nachdem das Plugin bereits (z. B. via `:LazyGit`) geladen wurde. |

`vim.g.lazygit_use_neovim_remote = 1` wird im `config`-Hook explizit gesetzt
(Plugin-Default ist ohnehin `1`, sofern `nvr` im `PATH` gefunden wird — hier
**[custom]**, weil bewusst hart gesetzt statt der Auto-Detection überlassen).

---

## 2. Bridge-Commands dieser Config **[custom]**

Register von `M.setup()` in `lua/config/lazygit/init.lua` (entfernt).
Existierten nur, weil LazyGit ein externer Prozess ist und keinen direkten
Zugriff auf `vim.api` hat — Rückkanal lief über Neovims RPC-Server (`$NVIM`)
und `nvr` (neovim-remote). Mechanik im Detail stand in
`lua/config/lazygit/README.md` (entfernt).

| Command | Wirkung | Aufgerufen von |
|---|---|---|
| `:LazygitBadd <pfad>` | Datei als Hintergrund-Buffer hinzufügen (`:badd`, kein Fokus/Fensterwechsel). Implementierung war `lua/config/lazygit/actions/badd.lua` (entfernt, siehe Hinweis oben). | LazyGit-Taste `O` (Custom Command in `config.yml`) |
| `:LazygitReplace <pfad>` | Ersetzt die im Editor sichtbare Datei, fokus-sicher via `nvim_win_call`. Bei ungespeicherten Änderungen im Ziel-Buffer: Fallback auf `:LazygitBadd` statt Überschreiben. Implementierung war `lua/config/lazygit/actions/replace.lua` (entfernt, siehe Hinweis oben). | LazyGit-Taste `<C-o>` (Custom Command in `config.yml`) |

Beide Commands erwarteten genau **ein** Argument (`nargs = 1`, damit Leerzeichen
im Pfad erhalten bleiben) und wurden ausschließlich über die LazyGit-
`customCommands` in der externen `config.yml` aufgerufen (Referenz-Kopie lag
in `lua/config/lazygit/docs/config.yml`, entfernt), nicht manuell aus Neovim
heraus.

Falls `nvr` beim Laden des Plugins nicht im `PATH` gefunden wird, warnt
`M.setup()` einmalig (`notify.warn`), tut aber sonst nichts — die Commands
werden trotzdem registriert.

---

## Offene Punkte

- `:LazyGitLog` ist ein Plugin-Default-Command, fehlt aber im `cmd`-Table des
  Lazy-Specs — vermutlich schlicht vergessen, nicht bewusst ausgeschlossen.
  Rein informativ hier vermerkt, keine funktionale Einschränkung, solange das
  Plugin einmal über einen der gelisteten Commands geladen wurde.
