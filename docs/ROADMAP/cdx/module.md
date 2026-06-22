# Module

Let me look deeper at the ambiguous modules and the find/path cluster, and map what user commands each registers.

I've mapped the whole `custom/` and `usrcmds/` surface (plus how the commands and engine adapters are wired). Here are the consolidation candidates, ranked by how much overlap actually exists — not just surface naming.

## Table of content

  - [Tier 1 — strong overlap, real duplication](#tier-1-strong-overlap-real-duplication)
    - [1. Fuzzy file/dir/grep pickers → one shared engine layer](#1-fuzzy-filedirgrep-pickers-one-shared-engine-layer)
    - [2. `custom/pathfinder` + `custom/pathprobe` (your example) ✓](#2-custompathfinder-custompathprobe-your-example)
    - [3. `custom/insert` + `usrcmds/copy` → shared path-text core](#3-custominsert-usrcmdscopy-shared-path-text-core)
  - [Tier 2 — related, worth a closer look](#tier-2-related-worth-a-closer-look)
    - [4. Project inspection & code scanning](#4-project-inspection-code-scanning)
    - [5. File navigation](#5-file-navigation)
  - [Tier 3 — structural note, not a code merge](#tier-3-structural-note-not-a-code-merge)
  - [Leave as-is (cohesive / unrelated)](#leave-as-is-cohesive-unrelated)

---

## Tier 1 — strong overlap, real duplication

### 1. Fuzzy file/dir/grep pickers → one shared engine layer
This is the biggest win. Seven modules independently wrap **fzf-lua + telescope** to do "build a picker over a list/command":

| Module | Command(s) | What it finds |
|---|---|---|
| `custom/find_config` | `WkdBookFind/Grep` | files in nvim config |
| `custom/find_in_folder` | `FindInFolder` | files in a picked folder |
| `custom/dir_picker` | `CwdHere` | directories |
| `custom/repo_pickers` | `RepoFiles*`, `RepoGrep*` | files/grep in repos |
| `custom/grep` | (live grep; header even says `usrcmds.live_grep`) | grep |
| `usrcmds/search_all_drives` | `AllDrives`, `AllDrivesFzf` | grep+files across drives |
| `usrcmds/system_find` | `FindOnSystem` | files via `fd` |

Evidence of duplication: each carries its **own** `fzf.lua` + `telescope.lua` adapter — `find_in_folder/`, `grep/`, `repo_pickers/select/`, `find_config/engines/` are four+ parallel implementations of the same two adapters. Plus `find_in_folder/dir_select.lua` and `dir_picker/` both do "pick a directory."

**Proposal:** a single `custom/pickers` (or `lib/pickers`) with one fzf adapter, one telescope adapter, engine auto-detect, and `pick_files / pick_dir / live_grep`. The seven modules above shrink to thin *sources* (root + scope + args). Optionally collapse the file-finders into one `:Find <config|folder|system|drives>` and grep into one `:Grep <scope>`.

### 2. `custom/pathfinder` + `custom/pathprobe` (your example) ✓
Both take text (selection / `<cfile>`) → sanitize → resolve to a real on-disk file across candidate roots → open at line/col. `pathfinder` has the richer `extractor/` + `finder.lua`; `pathprobe` is a single-file specialization for truncated error-message paths. → **pathprobe becomes a resolution strategy inside pathfinder**, sharing the extractor + root-search + open logic.

### 3. `custom/insert` + `usrcmds/copy` → shared path-text core
`:Insert filepath|module` (inserts at cursor) and `:Copy path|module` (to clipboard) format the *same* things: cwd-relative / absolute / lua-module / custom separator / depth. We already shared `get_module_path` last session — the rest (modes/formats/depth) is still duplicated in both. → extract one path-formatting core; Insert and Copy become two *sinks* (cursor vs clipboard).

## Tier 2 — related, worth a closer look

### 4. Project inspection & code scanning
`usrcmds/project_tree` (tree/count/clipboard), `custom/lua_project_file_stats` (metrics), `custom/function_index` (ripgrep symbol index), `usrcmds/gather` (`GatherLua`), and partly `usrcmds/fileinfo`. All scan the project FS / shell out to ripgrep and present aggregates. `function_index` + `gather` likely overlap most (both enumerate code defs project-wide). → a `project`/`inspect` namespace with shared scan+ripgrep infra; merge `function_index`+`gather` first.

### 5. File navigation
`custom/filecycle` (`NextFile`/`PreviousFile` in dir) + `custom/tabufline` (buffer nav, no centering) — both "move between files/buffers," different axes. Co-locate under a `navigation` namespace; low code savings, better discoverability.

## Tier 3 — structural note, not a code merge
The **`custom/` vs `usrcmds/` boundary is not principled**: finders live in *both* (`custom/find_*`, `custom/grep`, `custom/repo_pickers` **and** `usrcmds/search_all_drives`, `usrcmds/system_find`). Module headers disagree with their location too (`custom/grep` → `usrcmds.live_grep`, `usrcmds/newfile` → `utils.newfile`, `usrcmds/update_repos` → `usrcmds.repos.update`). Worth deciding a rule (e.g. `custom/` = feature subsystems, `usrcmds/` = thin command registrations) — Tier 1 #1 is a natural moment to fix this.

## Leave as-is (cohesive / unrelated)
`format`, `open`, `pdfport`, `diff`, `markdown`, `migrate`, `reload`, `recommender`, `emojis`, `newfile` (already bundles 5 commands cleanly), `compress_dir`, `update_repos`, `line_marker`, `commands_keymaps`.

---

My recommendation for sequencing: **#2 (pathfinder/pathprobe)** and **#3 (insert/copy)** are small, self-contained, high-confidence wins to do first; **#1 (picker engine)** is the highest-value but largest refactor.

Which one do you want to dig into?
