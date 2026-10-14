---
name: commit-review
description: Review commits of this chat (or given SHAs/range/feature) for bugs, security and performance issues and fix them immediately, with a proven test per fix. Use when the user says "checke/review alle commits", "commits reviewen", "Commit-Review", "auf Bugs/Security/Performance prüfen", gives SHAs to review, or mentions ultracode review. Not for pure docs commits and not for reviewing a pending diff (that is /code-review).
---

# Commit-Review

Reviewt bereits gemachte Commits (nicht den offenen Diff) auf Bugs,
Security und Performance und behebt Befunde sofort.

## 1. Umfang bestimmen

- Quelle in dieser Reihenfolge: vom User genannte SHAs/Range/Feature, sonst
  die laufende Commit-Liste dieses Chats, sonst `git log` nach Autor/Pfad.
  Ist der Umfang unklar, kurz nachfragen statt raten.
- Reine Docs-Commits (nur `*.md`, `docs/`, README) ausnehmen. Sie bekommen
  den grünen Haken ohne Review.
- Die Liste der zu prüfenden Commits zuerst ausgeben (SHA, Repo, Kurztext),
  dann erst anfangen.

## 2. Review

- Pro Commit `git show <sha>` lesen, nicht nur die Message. Berührte Dateien
  im Kontext lesen, nicht nur den Hunk.
- Prüfen auf: Bugs (Edge Cases, Fehlerpfade, nil/leere Eingaben, Ressourcen-
  Lecks wie offene fds/Handles/Timer), Security (Pfad-/Command-Injection,
  unquotierte Shell-Argumente, Secrets), Performance (Schleifen in Hot Paths,
  unnötige Autocmds/Redraws, wiederholte IO).
- Lua-/Neovim-Code zusätzlich gegen
  `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists/regeln/PERFORMANCE.md`
  und `.../LUA_NVIM.md` prüfen. `$REPOS_DIR/lib.nvim` nutzen, wo sinnvoll.
- Nie mehr als 1 Agent gleichzeitig. Reicht die Größe nicht für einen Agent,
  selbst reviewen. Mehrere Agents nur nacheinander in Runden.
- Befunde nach Schwere sortiert nennen (Fundstelle `datei:zeile`, Szenario),
  Vermutungen als solche kennzeichnen.

## 3. Fixen

- Jeder Fix bekommt einen Test (im `/TESTS/` des Plugins), der **ohne** den
  Fix rot wird. Ablauf: Fix herausnehmen, Test laufen lassen (rot), Fix
  zurücksetzen (grün). Nach einem Rebuild prüfen, dass die Sabotage wirklich
  gebaut wurde, sonst beweist ein grüner Test nichts.
- Ein Detektor/Test, der "nichts" meldet, braucht einen Positivtest (gleiche
  Datei, eine Stelle mit garantiertem Treffer).
- luacheck/stylua/clippy/svelte-check auf null Warnungen, nicht nur ansehen.
- Backslash-haltigen Code nur mit Edit/Write schreiben, nie durch die Shell
  (`$REPOS_DIR/tasks-vault/HEREDOC.md`). Temp-Skripte mit neuem, eindeutigem
  Namen anlegen.
- Restarbeit, die nicht sofort erledigt wird: als Task im Vault anlegen
  (Regeln aus CLAUDE.md/Base-Prompt), nicht als Absatz irgendwo.
- Fremde Befunde (anderer Code, anderer Chat) nicht beheben, in einer Zeile
  melden.

## 4. Abschluss

- Pro Repo: pullen, committen auf `main`, **vor** dem Push
  `git log origin/main..HEAD` prüfen (geteilter Checkout kann fremde Commits
  enthalten), dann pushen. Keine PRs, keine Co-Autorenschaft von Claude
  (diese Regel gilt vor jeder Standard-Attribution).
- Nach dem Push die CI abwarten und den Status nennen ("lokal grün" genügt
  nicht).
- Antwort auf Deutsch, Code und Commit-Body auf Englisch.

## 5. Grüner Haken

Die Commit-Liste am Ende jeder Ausgabe enthält pro Commit: Kurzbeschreibung +
Repository. Grüner Haken nur wenn:

- der Commit reine Docs sind, oder
- ein `ultracode`-Agent ihn reviewed hat, oder
- der User explizit reviewed hat (Reasoning auf ultracode).

Dieser Skill selbst vergibt den Haken für gefixte Commits nur, wenn der Review
in einer ultracode-Session lief. Sonst ohne Haken lassen und anbieten:
`/code-review ultra <SHA>` (der User startet das selbst, Claude kann es nicht
auslösen).
