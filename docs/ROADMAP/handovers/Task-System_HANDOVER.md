# Handover — Task-System für die wkdbooks

> **Stand 2026-10-03.** Phasen 0–3 sind gebaut und auf `main`; offen sind die Migration der übrigen
> Plugins (Phase 4) und die Politur (Phase 5).
>
> **Konzept (Spec, Regeln R1–R12, Entscheidungen):**
> [Task-System-Konzept.md]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/ALL/Task-System-Konzept.md)
> — dort steht das *Warum*; diese Datei sagt, *wo was liegt und was als Nächstes ansteht*.

## Worum es geht

Offene Aufgaben der eigenen Plugins stehen als eine Datei pro Task unter
`<plugin>/ROADMAP/tasks/<slug>.md` (flaches YAML-Frontmatter) im Vault
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/`. Pro Plugin wird eine `ROADMAP/TASKS.md`
**generiert** (nie von Hand editieren). Erledigt = Datei nach `Backlog/FEATURES|TASKS/` verschieben.
Die globale `ALL/TASKS.md` wird **nicht** committet, nur bei Bedarf erzeugt.

## Wo was liegt

| Teil | Ort |
|---|---|
| Frontmatter-Modul (generisch) | `lib.nvim`: `lua/lib/nvim/markdown/frontmatter/` (+ `TESTS/frontmatter_spec.lua`) |
| Engine (reines Lua, ohne UI) | nvim-config: `lua/tasks/` (vault, model, scan, index, mutate, check, cli, fsio) + README dort |
| Headless-CLI | nvim-config: `scripts/tasks.lua` — `nvim --headless -u NONE -l scripts/tasks.lua <list\|index\|new\|set\|done\|check\|template\|areas\|export>` |
| `:MyPlugins`-Routen | nvim-config: `lua/bindings/usrcmds/plugin_repos/` (Routen-Datei + `README.md`) |
| Dashboard | nvim-config: neben `plugin_repos/picker.lua` (Snacks-Picker, Fallback ohne Snacks) |
| Specs der Engine | nvim-config: `TESTS/` (neu; Runner `nvim -n -i NONE --headless -u NONE -l TESTS/run.lua`) |
| Pilot-Tasks | Vault: `lib.nvim/ROADMAP/tasks/` (57 Dateien, davon 6 schon wieder nach `Backlog/` erledigt) |
| Regeln R1–R12 | Vault-`README.md`, Abschnitt "Open tasks" |

## Bedienung (verb-first, kein plugin-first-Shim — entschieden)

```
:MyPlugins tasks [<area>|all] [--status= --prio= --kind= --tag= --stale=<d> --blocked] [--to=buffer|file:<p>|clipboard|qf] [--format=md|csv]
:MyPlugins tasks index [<area>|--all] [--check]
:MyPlugins task new <area> [title…] [kind= prio= effort= tags=]
:MyPlugins task set <id> key=value…
:MyPlugins task done <id> [done_in=…]
:MyPlugins task template
:MyPlugins task open <id>
:MyPlugins open <area> <tasks|roadmap|backlog|handover|notes|all>
```

Dashboard-Tasten: `<CR>` öffnen, `<Tab>` markieren, `s`/`p` Status/Prio als Batch, `D` erledigen,
`f` Filter, `e` Export, `gb`/`gr` Backlog/ROADMAP, `g?` Hilfe. `<id>` = `<area>/<slug>`.

## Commits (alle auf `main`)

| Repo | Commit | Inhalt |
|---|---|---|
| lib.nvim | `2bc2874`, `c6d274c` | Frontmatter-Modul; Fix: Zahlen-Strings quoten, Prosa-Blöcke ablehnen, Temp-Name |
| nvim-config | `ef8641fa` | Engine, CLI, Specs |
| nvim-config | `be270dfa` | `:MyPlugins`-Routen, Collection `vault` |
| nvim-config | `c61cd4f1` | Dashboard |
| nvim-config | `efcab018`, `80ef2946` | Fixes: Temp-Name, Warnung bei Titel mit ` #` |
| WKDBooks | `b6c8edb`, `571390f`, `d0f098d`, `f7b037c`, `85cfe95`, `2b24f99`, `a18aedd`, `1e37d97` | Konzept, Entscheidungen, Statusstände, Pilot, Regeln |

Review: lib.nvim- und nvim-config-Code (`2bc2874`, `ef8641fa`, `be270dfa`, `c61cd4f1`) wurde durch einen
Review-Agenten adversarial geprüft, alle 13 Befunde bestätigt und behoben. **Die drei Fix-Commits
(`c6d274c`, `efcab018`, `80ef2946`) sind noch nicht reviewt.**

## Offen / nicht verifiziert

- **Nicht geprüft:** nur unter Windows 11 gelaufen (ubuntu/macOS ungetestet); die nvim-config-Specs laufen
  nicht in der CI. Dashboard headless nur teilweise geprüft — `D` mit echtem `ui.kit.confirm`,
  Clipboard am echten Provider, Insert-Modus und Maus sind ungetestet.
- **Vorbestehend rot:** `stylua --check` meldet einen Diff in
  `lua/bindings/usrcmds/learn_plan_viewer/init.lua` (nicht Teil dieser Arbeit).
- **Nicht gebaut:** `fs.watch`-Refresh und Frecency im Dashboard; Statusline-Zähler; `--stale` mit
  `refs:`-Prüfung; CI-Check für den Vault.
- **Pilot-Qualität:** ca. 40 der `lib.nvim`-Tasks tragen `needs-verification` (nicht gegen den aktuellen
  Baum nachgemessen); die 19 `parked`-Tasks und die gesetzten Prios sind Interpretation der Quellen.
- **Entscheidungen offen:** (1) Collection `vault` ist Duplikat von `plugins_book`, `ALL` über
  `:Pickers vault` nicht erreichbar — behalten oder entfernen? (2) Task `lib.nvim/messages-module-cut`
  (`status: decision`) wartet auf dich. (3) Dashboard-Letter-Keys `s p D …` überschreiben im Normalmodus
  des Input-Fensters gleichnamige Editierbefehle — ggf. auf Alt-Kombinationen. (4) `md_lint` meldet 88
  `$REPOS_DIR`-Pseudolinks in `lib.nvim/ROADMAP/MIDDLE-SMALL-FIXES.md` (vorbestehend).
- **Bekannte Eigenheiten:** Titel mit ` #` werden nach YAML-Regel abgeschnitten (`check` warnt);
  Namespace `tasks` ist generisch (bei Kollision umbenennen); `tasks index --check` im Editor führt die
  volle Regelprüfung aus, im CLI nur die Staleness.

## Nächste Schritte

1. **Phase 4 — Migration**, pro Plugin eine Runde (max. 1 Agent): ROADMAP/NOTES/Handover lesen, offene
   Punkte als Task-Dateien (CLI `new`), Prosa bleibt mit Link auf `TASKS.md`. Reihenfolge nach Menge:
   `lsp`, `mdview`, `documentation`, `casedesk`, `markdown`, `github_stats`, … Vorher `checkpoint`.
2. Review der drei Fix-Commits.
3. `pickers.nvim`: generische Items-Quelle (Konzept §6) als eigener Task anlegen und bauen.
4. Phase 5: Politur (Statusline, `mdview`, `--stale`, Vault-CI).
5. Die offenen Entscheidungen oben beantworten.
