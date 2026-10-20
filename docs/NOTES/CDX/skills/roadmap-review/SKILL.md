---
name: roadmap-review
description: Work through a roadmap file or area step by step - read the first items, working modes and next recommended step, explain each step (what, why, user benefit, effort/value, recommendation), let the user decide, implement, then archive the finished item and analyze the next one. Use when the user says "Roadmap durchgehen", "nächster empfohlener Schritt", "Roadmap-Review", "plugin roadmap", names a ROADMAP/*.md or an area like lsp.nvim and wants the next step handled.
---

# Roadmap-Review

Zyklus: Schritt verstehen -> erklären -> User entscheidet -> umsetzen ->
abhaken/archivieren -> nächsten Schritt analysieren.

## 1. Einlesen

- Quelle: vom User genannte Roadmap-Datei, sonst die Area (Ordner in
  `$REPOS_DIR/tasks-vault/<area>`). Unbekannte Area nicht anlegen, nachfragen.
- Die ersten Punkte lesen, dazu Arbeitsmodi und "nächster empfohlener
  Schritt" der Datei. Bei Tasks im Vault (tasks.nvim): `show`/`next` laut
  Task-Regeln in CLAUDE.md/Base-Prompt, nicht an der CLI vorbei arbeiten.
- Tasks mit `actor=me`, `status=decision`, `parked` oder offenem Blocker
  nicht selbst starten, Stand melden und nachfragen.

## 2. Schritt erklären (vor jeder Umsetzung)

Pro Schritt kurz, auf Deutsch, in dieser Gliederung:

1. **Was?** Der Schritt in einem Satz.
2. **Warum?** Problem/Auslöser.
3. **Nutzen für User?** Was ändert sich spürbar.
4. **Aufwand/Nutzen** (ehrlich, XS..XL, Risiken).
5. **Empfehlung:** implementieren / nicht / anders, mit Begründung.

Dann **anhalten und auf die Entscheidung warten**. Mögliche Antworten:

- umsetzen,
- ersatzlos streichen,
- zurückstellen (mit Begründung dokumentieren).

Bei Ablehnung/Rückstellung: Roadmap entsprechend aktualisieren, dann den
nächsten Punkt der Liste nehmen und wieder bei 2 anfangen.

## 3. Umsetzen

- Qualitätsregeln des Repos einhalten: luacheck/stylua grün, Tests im
  `/TESTS/` des Plugins, jeder Fix mit Test, der ohne Fix rot ist.
  `$REPOS_DIR/lib.nvim` nutzen, wo sinnvoll.
- Bei Binding-Änderung auch `$NVIM_CONFIG_DIR/docs/NOTES/BINDINGS`
  aktualisieren. README/Docs nachziehen, wenn es Endnutzer betrifft.
- Beim Arbeiten gefundene Restarbeit, Bugs oder Ideen, die nicht sofort
  erledigt werden: als Task im Vault anlegen (nie als Absatz in Roadmap,
  Handover oder Chat). Roadmap-Einträge nur im Vault, nie im Plugin-Repo.
- Dateien mit Backslashes nur mit Edit/Write schreiben
  (`$REPOS_DIR/tasks-vault/HEREDOC.md`).

## 4. Abschließen

1. Committen auf `main`, vorher pullen, vor dem Push
   `git log origin/main..HEAD` prüfen, pushen. Keine PRs, keine
   Co-Autorenschaft von Claude. CI abwarten und Status nennen.
2. Roadmap-Datei aktualisieren und den erledigten Punkt in die zugehörige
   `*_FINISHED.md` daneben verschieben (z. B. `PLUGIN_ROADMAPS.md` ->
   `PLUGIN_ROADMAPS_FINISHED.md`). Bei Vault-Tasks stattdessen
   `done <id> --commits=<repo>@<sha>,<repo>@<sha>` (alle Commits der Task,
   `commits` ist ein Listenfeld), nie `status=done` von Hand.
   Vault-Änderungen separat committen/pushen (Repo `tasks-vault`).
3. Den **nächsten empfohlenen Schritt** analysieren (Abschnitt 2). Dabei
   nicht begründen, welche Punkte übersprungen wurden.

## 5. Ausgabe

- Immer sagen, was gerade passiert und ob es etwas Interessantes gab.
- Am Ende jeder Ausgabe die laufende Commit-Liste (Kurztext + Repository).
  Grüner Haken nur bei Docs-only-Commits oder nach ultracode-Review; für
  Code-Commits bei Bedarf `commit-review` bzw. `/code-review ultra <SHA>`
  anbieten.
