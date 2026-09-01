# RULES — verschoben

**Stand 2026-08-18, Pfad korrigiert 2026-08-30.** Der Ordner `docs/ROADMAP/RULES/` gibt es nicht mehr. Sein Inhalt
ist in die kanonische Regelsammlung gemergt:

```
<repos>/WKDBooks/Development/wkdbook-Lua/Checklists
```

`<repos>` ist das Repo-Wurzelverzeichnis dieser Maschine — also `$REPOS_DIR`,
falls gesetzt, sonst der erste existierende Kandidat aus `E:`, `D:`, `C:`,
`/repos`, in genau dieser Reihenfolge. Das ist dieselbe Auflösung, die
[`lua/plugins/personal/utils.lua`](../../lua/plugins/personal/utils.lua) für die
lokalen Plugin-Checkouts benutzt; `require("plugins.personal.utils").repos_path`
gibt sie in einer laufenden Sitzung aus. Hier stand bis 2026-08-30 fest `E:`,
was auf dieser Maschine ins Leere zeigte — die Sammlung liegt unter `C:`.

Es gibt jetzt nur noch **einen** Ort für Regeln.

| Was | Wo jetzt |
| --- | -------- |
| Die 33 Plugin-Reports + `nvim-config.md` (Rohbefunde mit `file:line`) | `Checklists/belege/` |
| Die Themen-Synthese (`themes/*.md`) | aufgelöst — jeder Punkt ist entweder eine Regel in `Checklists/regeln/` (mit Beleg-Rückverweis) oder blieb reiner Befund |
| Auftrag/Methode/Stand der Erhebung (`00-TASK.md`) | `Checklists/belege/README.md` |
| Plugin-Ideen (offener Backlog) | [../ROADMAP/IDEAS/RULES-plugin-ideas.md](../ROADMAP/IDEAS/RULES-plugin-ideas.md) |
| Flags/Optionen, Count- und Completion-Lücken | **abgearbeitet** im Plugin-Sweep, archiviert unter [ARCHIVE/plugin-sweep-2026-08/](./ARCHIVE/plugin-sweep-2026-08/) |

Ideen sind **Backlog** und bleiben deshalb in der Roadmap: sie werden abgearbeitet und
gestrichen. Regeln nicht — die gelten weiter und leben in `Checklists/`.

Einstieg dort: `Checklists/README.md` (Struktur, Regel-IDs) und
`Checklists/WORKFLOW.md` (welche Liste wann); die Begründung der Struktur und
der Ablauf der Zusammenführung stehen in `Checklists/KONZEPT.md`.

**Auch die Plugin-Audits sind hier aufgegangen.** `Arch&Coding.md`,
`Checklist.md` und `Zentral-Prinzipien.md` sind keine eigenständige Regelquelle
mehr — wer wissen will, was gilt, liest in `Checklists/`, nicht in einem
Repo-ROADMAP-Ordner. Die Kopien unter `wkdbook-myplugins/<plugin>/ROADMAP/`
existieren weiter, sind aber ab jetzt historischer Stand. Der Abgleich gegen
den Code ist in
[PLUGIN_ROADMAPS.md §3.1](../ROADMAP/personal/All/FINISH/ERLEDIGT/ROADMAPS/PLUGIN_ROADMAPS.md)
protokolliert.
