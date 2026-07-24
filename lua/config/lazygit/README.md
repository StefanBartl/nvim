# LazyGit ↔ Neovim Bridge

Öffnet Dateien, die man **innerhalb von LazyGit** auswählt, in der **Neovim-Instanz**,
aus der LazyGit gestartet wurde — ohne LazyGit zu verlassen.

| Taste (in LazyGit) | Aktion | Effekt in Neovim |
|---|---|---|
| `o` | (LazyGit-Default) | Datei im System-Dateimanager öffnen |
| `O` | `:LazygitBadd` | Datei als **Hintergrund-Buffer** (`:badd`) — landet in Bufferliste/Bufferline, **kein** Fokus, **kein** Fensterwechsel |
| `<C-o>` | `:LazygitReplace` | Datei **ersetzt** die im Editor sichtbare Datei (fokus-sicher, LazyGit bleibt offen) |

Idee: Während man durch LazyGit browst, sammelt man interessante Dateien mit `O`
ein. Nach dem Schließen von LazyGit hat man sie alle als Buffer offen.

## Warum das nicht trivial ist

Neo-tree läuft **in-process** als Lua und hat direkten Zugriff auf `vim.api`,
Fenster und Buffer. **LazyGit ist ein externer Prozess** in einem Terminal-Float.
Es kann nicht einfach `vim.api.nvim_*` aufrufen. Der einzige Rückkanal ins
Eltern-Neovim ist dessen **RPC-Server**.

## Der Mechanismus (Schritt für Schritt)

```
┌─ Neovim (Eltern) ──────────────────────────────────────────┐
│  RPC-Server lauscht auf einer Pipe-Adresse                  │
│  exportiert sie als  $NVIM  an Terminal-Subprozesse        │
│                                                             │
│   ┌─ :terminal (lazygit.nvim Float) ───────────────────┐   │
│   │  lazygit  (erbt $NVIM)                              │   │
│   │     │  Taste O / <C-o>                              │   │
│   │     ▼  customCommand:                               │   │
│   │     nvr --nostart -c "LazygitBadd <pfad>"           │   │
│   │     │  nvr liest $NVIM aus os.environ               │   │
│   └─────┼──────────────────────────────────────────────┘   │
│         ▼  RPC                                              │
│   :LazygitBadd <pfad>  ──►  :badd / nvim_win_call(edit)     │
└────────────────────────────────────────────────────────────┘
```

1. **`$NVIM`** — Neovim setzt diese Env-Variable (Adresse des RPC-Servers)
   automatisch für jeden `:terminal`-Subprozess. lazygit.nvim startet LazyGit in
   so einem Terminal-Float, also erbt LazyGit `$NVIM`.
2. **LazyGit Custom Command** (`~/AppData/Local/lazygit/config.yml`, unter Linux/
   macOS `~/.config/lazygit/config.yml`) ist auf `O` / `<C-o>` gebunden und ruft
   `nvr` auf. `{{.SelectedFile.Name}}` ist der **repo-relative** Pfad (Forward-
   Slashes).
3. **`nvr`** (neovim-remote) liest `$NVIM` direkt aus der Umgebung
   (`address = env.get('NVIM') or env.get('NVIM_LISTEN_ADDRESS')`) und sendet via
   `-c` einen Ex-Command an den RPC-Server. `--nostart` = kein neues Neovim
   starten, falls keine Adresse da ist.
4. **`:LazygitBadd` / `:LazygitReplace`** sind hier registrierte User-Commands
   (`init.lua` → `setup()`), aufgerufen im Eltern-Neovim. Sie lösen den Pfad auf
   und führen die Aktion aus.

## Warum es cross-platform funktioniert

- **Kein Shell-Quoting von Env-Vars.** `nvr` liest `$NVIM` aus `os.environ`
  (Python), nicht über Shell-Expansion. Es ist also egal, ob die LazyGit-Shell
  cmd, PowerShell, bash, zsh oder fish ist (`$NVIM` vs `%NVIM%` vs `$env:NVIM`
  spielt keine Rolle).
- **Doppelte Anführungszeichen** in `-c "..."` gruppieren in cmd, PowerShell und
  POSIX-Shells gleichermaßen — funktioniert also überall (Windows/Arch/Ubuntu/Mac).
- **Pfade**: LazyGit liefert Forward-Slash-Pfade; `resolve_path.lua` macht sie via
  `fnamemodify(':p')` plattform-nativ absolut (mit git-root- und cwd-Fallback,
  falls Neovims cwd nicht der Repo-Root ist).

**Einzige Voraussetzung:** `nvr` muss im `PATH` sein.

```sh
pip install neovim-remote        # alle Plattformen
# Arch:  AUR-Paket  neovim-remote
# macOS: brew install neovim-remote   (oder pipx install neovim-remote)
```

`setup()` warnt einmalig, falls `nvr` beim Laden des LazyGit-Plugins fehlt.

## Dateien

| Datei | Zweck |
|---|---|
| `init.lua` | Dünne Verdrahtung: registriert die beiden User-Commands |
| `resolve_path.lua` | Repo-relativen LazyGit-Pfad → absoluter Pfad |
| `actions/badd.lua` | `O`: `:badd` (Hintergrund-Buffer) |
| `actions/replace.lua` | `<C-o>`: fokus-sicheres Ersetzen via `nvim_win_call` |
| `docs/config.yml` | Referenz-Kopie der LazyGit-Config |
| `docs/README.md` | wohin die `config.yml` pro OS gehört |

Eingehängt in [`lua/plugins/git.lua`](../../plugins/git.lua) im `config`-Hook des
`kdheepak/lazygit.nvim`-Specs.

## Geteilte Helfer in `lib.nvim`

Die buffer-/window-Primitiven liegen in
[`lib.nvim.buf_win_tab.normal_buffer`](https://github.com/StefanBartl/lib.nvim)
(`lua/lib/nvim/buf_win_tab/normal_buffer/`) und sind so auch von Neo-tree
nutzbar:

- `is_normal_file_buffer(bufnr)` — echter, gelisteter Datei-Buffer?
- `find_last_normal_window(exclude_win?)` — letztes Editor-Fenster (Terminal-
  Floats/Trees werden übersprungen).
- `edit_in_window(winid, path)` — `:edit` via `nvim_win_call`, **ohne** Fokus zu
  ändern.
- `prompt_save(bufnr)` — interaktiver Save-Prompt (blockierend; **nicht** für den
  LazyGit-Float geeignet, daher nutzt `replace.lua` ihn bewusst nicht).

> Hinweis: Die `<C-o>`-Variante prompt-et **nicht** bei ungespeicherten
> Änderungen — hinter dem LazyGit-Float wäre ein `confirm()` unsichtbar. Statt-
> dessen: ist der Ziel-Buffer modifiziert, wird **nicht** überschrieben, sondern
> auf `:badd` zurückgefallen. So geht nichts verloren.
