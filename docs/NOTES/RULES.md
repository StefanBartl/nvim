# RULES — verschoben

**Stand 2026-08-18.** Der Ordner `docs/ROADMAP/RULES/` gibt es nicht mehr. Sein Inhalt
ist in die kanonische Regelsammlung gemergt:

```
E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists
```

Es gibt jetzt nur noch **einen** Ort für Regeln.

| Was | Wo jetzt |
| --- | -------- |
| Die 33 Plugin-Reports + `nvim-config.md` (Rohbefunde mit `file:line`) | `Checklists/belege/` |
| Die Themen-Synthese (`themes/*.md`) | aufgelöst — jeder Punkt ist entweder eine Regel in `Checklists/regeln/` (mit Beleg-Rückverweis) oder blieb reiner Befund |
| Auftrag/Methode/Stand der Erhebung (`00-TASK.md`) | `Checklists/belege/README.md` |
| Ideen für Flags/Optionen, Count- und Completion-Lücken, Plugin-Ideen | hier in der Roadmap: [IDEAS/RULES-flags-options.md](IDEAS/RULES-flags-options.md), [IDEAS/RULES-audit-count.md](IDEAS/RULES-audit-count.md), [IDEAS/RULES-audit-completion.md](IDEAS/RULES-audit-completion.md), [IDEAS/RULES-plugin-ideas.md](IDEAS/RULES-plugin-ideas.md) |

Ideen sind **Backlog** und bleiben deshalb in der Roadmap: sie werden abgearbeitet und
gestrichen. Regeln nicht — die gelten weiter und leben in `Checklists/`.

Einstieg dort: `Checklists/README.md` (Struktur, Regel-IDs) und
`Checklists/WORKFLOW.md` (welche Liste wann). Begründung der Struktur und Ablauf der
Zusammenführung: `Checklists/KONZEPT.md`.
