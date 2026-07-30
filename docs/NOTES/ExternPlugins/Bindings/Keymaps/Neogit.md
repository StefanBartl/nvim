# Neogit — Keymaps

Plugin: [`NeogitOrg/neogit`](https://github.com/NeogitOrg/neogit).
Spec in [lua/plugins/git.lua](../../../../../lua/plugins/git.lua).

Diese Config nutzt Neogit **neben** vim-fugitive und lazygit.nvim gleichzeitig
(siehe [Lazygit.md](Lazygit.md) und die Fugitive-Doku). Hier wird ausschließlich
Neogits **eigener** Scope dokumentiert — keine Duplizierung von
fugitive-/gitsigns-Inhalten.

`opts` im Lazy-Spec setzt nur `kind = "split"` (Plugin-Default: `"tab"` —
**[custom]**) und `integrations = { diffview = true }` (**[custom]**, Plugin-
Default hat keine Integration aktiv). Die `mappings`-Tabelle wird **nicht**
angefasst — alle Tastenbelegungen unten sind daher Plugin-**[default]**,
unverändert aus `M.get_default_values().mappings` in
[neogit/config.lua](https://github.com/NeogitOrg/neogit/blob/master/lua/neogit/config.lua)
(lokal installiert unter `nvim-data/lazy/neogit/lua/neogit/config.lua`, außerhalb
dieses Repos, daher kein relativer Link).

---

## Öffnen (Keymap dieser Config)

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `<leader>gg` | Neogit-Status im Split öffnen | `:Neogit kind=split<cr>` | **[custom]** |

Das Plugin selbst registriert keinen eigenen globalen Keymap zum Öffnen — nur
den `:Neogit`-Command (lazy via `cmd = "Neogit"`). `<leader>gg` und
`kind=split` sind beides Entscheidungen dieser Config.

---

## Status-Buffer (`mappings.status`) — Kernworkflow, alle **[default]**

| Taste | Aktion |
|---|---|
| `j` / `k` | Zeile runter / rauf |
| `<tab>` / `za` | Section auf-/zuklappen |
| `zo` / `zc` | Section öffnen / schließen |
| `1` … `4` | Faltebene (Depth) 1–4 setzen |
| `zC` / `zO` | Kurzform für Depth1 / Depth4 |
| `<cr>` | Datei/Diff unter Cursor öffnen (`GoToFile`) |
| `<s-cr>` | Datei peeken, ohne Fokus zu wechseln (`PeekFile`) |
| `<c-v>` / `<c-x>` / `<c-t>` | In vsplit / split / Tab öffnen |
| `s` | Stage (Hunk/Datei unter Cursor) |
| `S` | Alle unstaged Änderungen stagen |
| `<c-s>` | Alles stagen (`StageAll`) |
| `u` | Unstage |
| `U` | Alles unstagen (`UnstageStaged`) |
| `x` | Discard (Änderung verwerfen) |
| `K` | Datei untracken |
| `R` | Umbenennen |
| `-` | Änderung umkehren (`Reverse`) |
| `<c-r>` | Buffer neu laden (`RefreshBuffer`) |
| `q` | Neogit schließen |
| `I` | Repo initialisieren (falls noch kein Git-Repo) |
| `Q` | Beliebigen Git-Befehl ausführen (`Command`) |
| `y` | Refs anzeigen (`ShowRefs`) |
| `Y` | Ausgewählte Zeile(n) yanken |
| `$` | Command-History anzeigen |
| `gp` | Zum Parent-Repo springen (Submodule) |
| `{` / `}` | Zum vorigen/nächsten Hunk-Header springen |
| `[c` / `]c` | Öffnen oder scrollen (up/down) |
| `<c-k>` / `<c-j>` | Peek up / down |
| `<c-n>` / `<c-p>` | Nächste/vorige Section |

## Popups (`mappings.popup`) — im Status-Buffer aufrufbar, alle **[default]**

| Taste | Popup |
|---|---|
| `?` | Help-Popup (Übersicht aller Popups) |
| `c` | Commit-Popup |
| `p` | Pull-Popup |
| `P` | Push-Popup |
| `b` | Branch-Popup |
| `f` | Fetch-Popup |
| `l` | Log-Popup |
| `m` | Merge-Popup |
| `r` | Rebase-Popup |
| `d` | Diff-Popup |
| `v` | Revert-Popup |
| `X` | Reset-Popup |
| `Z` | Stash-Popup |
| `A` | Cherry-Pick-Popup |
| `i` | Ignore-Popup |
| `t` | Tag-Popup |
| `B` | Bisect-Popup |
| `w` | Worktree-Popup |
| `M` | Remote-Popup |
| `L` | Margin-Popup |

## Sonstige Neogit-Buffer, alle **[default]**

Weitere Sub-Mappings existieren für `commit_editor`, `rebase_editor`, `finder`,
`refs_view` und `commit_view` (z. B. `<c-c><c-c>` = Submit, `<c-c><c-k>` =
Abort im Commit-/Rebase-Editor; `p`/`r`/`e`/`s`/`f`/`x`/`d` = Pick/Reword/Edit/
Squash/Fixup/Execute/Drop im interaktiven Rebase). Vollständige Tabelle:
`mappings` in
[neogit/config.lua](https://github.com/NeogitOrg/neogit/blob/master/lua/neogit/config.lua)
(`M.get_default_values().mappings`) — hier nicht einzeln aufgeführt, da für den
Kern-Workflow (Status, Staging, Commit, Push/Pull) nicht relevant und 1:1
Plugin-Default.

---

## Offene Punkte

- Keine Autocmds oder Usercmds, die spezifisch zu Neogit gehören, gefunden
  (`Neogit` als Command selbst kommt vom Plugin, keine eigenen Wrapper dieser
  Config). Daher keine `Autocmds/Neogit.md` / `Usercmds/Neogit.md` angelegt.
- `NeogitStatus` taucht als Filetype in den Skip-/Highlight-Listen von
  `lua/wkdoptions/config/data/skip.lua` und `.../highlight.lua` auf (UI-
  Ausschluss für Winbar/Statusline-Deko) — das ist keine Keybinding, sondern
  reine Filetype-Konfiguration, daher hier nicht als Binding dokumentiert.
