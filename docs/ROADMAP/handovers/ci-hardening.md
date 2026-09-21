# CI-Hardening — Handover (nur offene Punkte)

> Der Flotten-Rollout der CI-Sofortmaßnahmen ist **fertig** (2026-09-21, alle
> 39 Plugin-Repos, Protokoll:
> [sofortmassnahmen.md](../personal/All/FINISH/ERLEDIGT/sofortmassnahmen.md)).
> Diese Akte hält nur, was danach übrig ist: vier vorbestehende rote Repos
> und ein fehlender `ci-verified`-Branch.

## Table of content

- [Regeln für diese Session](#regeln-für-diese-session)
- [Orte](#orte)
- [Ausgangslage](#ausgangslage)
- [Offene Punkte](#offene-punkte)
  - [1. fileops.nvim: stylua-Abweichung](#1-fileopsnvim-stylua-abweichung)
  - [2. emojis.nvim: eine Spec rot unter ubuntu](#2-emojisnvim-eine-spec-rot-unter-ubuntu)
  - [3. diff.nvim: macOS-Suite rot, dann ci-verified](#3-diffnvim-macos-suite-rot-dann-ci-verified)
  - [4. filetree.nvim: ubuntu und macOS rot](#4-filetreenvim-ubuntu-und-macos-rot)
  - [5. Kleinkram](#5-kleinkram)
- [Handwerkszeug](#handwerkszeug)

---

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden à 1 Agent, repo-für-repo.
- Antworten Deutsch, Quellcode (inkl. Kommentare) Englisch.
- Keine Co-Autorenschaft von Claude in Commits.
- Nach jedem fertigen Schritt committen/pushen/pullen, `main` bleibt aktuell.
- Code muss luacheck/stylua-grün sein (stylua v2.5.2, luacheck 1.2.0).
- Plugin-Docs/README mitpflegen, wo es Sinn macht.
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten, falls Nebenbei-Tooling entsteht.
- Vor jedem Commit in einem Plugin-Repo `git status` lesen, nie `git add -A`
  (andere Sessions arbeiten in denselben Checkouts).

## Orte

| Was | Wo |
|---|---|
| Abschlussprotokoll Runde 1+2 | `docs/ROADMAP/personal/All/FINISH/ERLEDIGT/sofortmassnahmen.md` |
| Plugin-Repos | `E:\repos\<name>.nvim` |
| CI-Verdikt je Plattform | `scripts/ci_status.sh [--red] [<name>]` (braucht `gh`) |
| Vorlage für `publish-ci-verified` | `E:\repos\lib.nvim\.github\workflows\ci.yml`, Job `publish-ci-verified` |
| Gelöschter Transformer | `git show 96c3b8537^:scripts/ci_hardening.py` — **ohne** die Pins für ui/documentation/pickers (diese Ergänzung ging mit der Löschung verloren; für einen Folge-Rollout `PIN_BRANCH` neu erweitern) |

## Ausgangslage

`scripts/ci_status.sh` am 2026-09-21: **35 von 39** Repos voll grün. Die vier
roten waren es schon vor dem Rollout (Jobs und Steps in `HEAD~1` und `HEAD`
identisch), sie hängen also nicht an Timeouts, Flags, Artefakten oder Pins.
Alle vier laden inzwischen bei Fehlschlag ihr Testlog als Artefakt hoch
(`test-output-<job>-<os>`), das ist der schnellste Einstieg:

```bash
cd E:/repos/<repo>
id=$(gh run list --workflow CI --limit 1 --json databaseId -q '.[0].databaseId')
gh run view "$id" --log-failed | tail -60
gh api repos/StefanBartl/<repo>/actions/runs/$id/artifacts -q '.artifacts[].name'
```

## Offene Punkte

Reihenfolge nach Aufwand, kleinstes zuerst.

### 1. fileops.nvim: stylua-Abweichung

- **Symptom:** `lint (stylua + luacheck)`, Step `stylua --check`.
- **Befund:** Diff in `TESTS/cycle_edge_spec.lua` um Zeile 280 — die Zeile
  `local rnok, rnmsg = cycle.navigate(missing, "next", opts_with({ root = "buffer_dir_recursive" }), 1)`
  muss nach stylua umbrochen werden (`local rnok, rnmsg =` / Aufruf eingerückt
  in der Folgezeile).
- **Vorgehen:** im Repo `stylua TESTS/cycle_edge_spec.lua` (v2.5.2!),
  `git diff` prüfen, committen, pushen. Kein Verhalten betroffen.

### 2. emojis.nvim: eine Spec rot unter ubuntu

- **Symptom:** ubuntu, Step „Run TESTS suite": `1 spec(s) failed (885 checks
  ran)`; windows und macos grün.
- **Offen:** welche Spec, und warum nur ubuntu. Das Log-Ende zeigt die
  passierten Dateien (`api_spec`, `bindings_spec`, `health_spec`,
  `install_spec_spec`), nicht die fehlgeschlagene — im vollen Log nach
  `FAIL` suchen, dann lokal mit dem CI-Aufruf
  (`nvim -n -i NONE --headless … TESTS/run.lua` bzw. was `ci.yml` nennt)
  nachstellen.
- **Hypothese (ungeprüft):** Plattformabhängigkeit (Pfad/Case-Sensitivity,
  fehlendes `rg`/`curl` auf dem Runner — `docs/install.json` deklariert `rg`
  und `curl` seit `da9daaf`).

### 3. diff.nvim: macOS-Suite rot, dann ci-verified

- **Symptom:** macOS, Step „Run spec suite" (Job „Headless spec suite
  (macos-latest)"); ubuntu/windows grün.
- **Offen:** Ursache unbekannt. **Erste Hypothese:** derselbe macOS-Fall wie
  bei `pickers.nvim` (`/var/folders/…` vs. `/private/var/folders/…` — ein
  Test vergleicht `tempname()` mit einem aufgelösten Pfad, oder Produktcode
  vergleicht Buffernamen mit dem übergebenen Pfad). Dort war der Fix
  `vim.uv.fs_realpath` vor dem Verschieben (siehe `d48ca24` in pickers.nvim,
  `lua/pickers/browse/init.lua`, `M.rename`) plus realpath-Vergleich im Test.
  Erst am Log bestätigen, nicht blind übertragen.
- **Danach (Folgearbeit, hängt an diesem Punkt):**
  1. `publish-ci-verified`-Job in `diff.nvim/.github/workflows/ci.yml`
     ergänzen (Vorlage lib.nvim; `needs:` = alle Gate-Jobs, mit
     `python`-Snippet oder von Hand, **CRLF im Arbeitsbaum beachten**).
  2. Push, CI grün abwarten, `git ls-remote --heads
     https://github.com/StefanBartl/diff.nvim ci-verified` bestätigen.
  3. In `gitsuite.nvim/.github/workflows/ci.yml` den `diff.nvim`-Checkout um
     `ref: ci-verified` ergänzen (der einzige noch ungepinnte
     Konsument; ein Dry-Run des alten Transformers meldete ihn als `NOTE`).

### 4. filetree.nvim: ubuntu und macOS rot

- **Symptom:** ubuntu und macOS, Step „Run test suites"; windows grün.
- **Offen:** Ursache unbekannt. Zwei Plattformen rot, eine grün: eher etwas
  Unix-Spezifisches (Pfad-Trenner, Rechte, Symlinks, `/private/var`) als ein
  Logikfehler. Log per `gh run view --log-failed` lesen.
- Der Rollout hat hier nur den Kommentar zum fehlenden `ui.nvim`-Pin
  entfernt (`ebc5131`) und die Pins gesetzt; die Fehlerursache liegt im
  Repo-Code.

### 5. Kleinkram

- **`TESTS/run.lua`-Kopfkommentare** nennen in mehreren Repos weiterhin die
  alten Aufrufe ohne `-n` — Dokumentationsdrift, kein Funktionsproblem;
  bei Gelegenheit mit den `ci.yml`-Aufrufen angleichen.
- **Timeout-Werte** (15/30 min) sind Heuristik. Wird ein Job (z. B. langsamer
  macOS-Runner) knapp, dort gezielt hochsetzen, nicht global.
- **Third-Party-Pins** (plenary, nui, neo-tree, telescope, nvim-tree) stehen
  auf dem HEAD vom 2026-09-20 und veralten bewusst; ein Anheben ist ein
  eigener, sichtbarer Commit je Repo.
- **ui.nvim-Primärcheckout:** nicht in diesem Rollout angefasst; falls dort
  ein Pull ansteht, vorher den Arbeitsbaum prüfen (andere Sessions haben
  eigene Worktrees unter `ui.nvim/.claude/worktrees/`).

## Handwerkszeug

- **Rot vorher/nachher unterscheiden:** Jobs und Steps von `HEAD~1` und
  `HEAD` gegenüberstellen, nie „rot nach dem Commit" mit „rot wegen des
  Commits" gleichsetzen:

  ```bash
  cd E:/repos/<repo>
  for sha in HEAD~1 HEAD; do
    id=$(gh run list --commit "$(git rev-parse $sha)" --workflow CI --json databaseId -q '.[0].databaseId')
    gh run view "$id" --json jobs -q '.jobs[]|select(.conclusion=="failure")|.name'
  done
  ```

- **`ci_status.sh` meldete einmal „no CI run for this commit"** (replacer.nvim),
  obwohl der Lauf grün war (vermutlich ein Timing-Effekt, nicht geprüft) —
  dann `gh run list --limit 3` direkt lesen.
- **`docs_linkcheck.py` unter Windows:** mit `PYTHONUTF8=1
  PYTHONIOENCODING=utf-8` starten, sonst bricht es bei Emoji-Zeichen mit
  `UnicodeEncodeError` ab.
- **Worktree-Falle:** In einer Worktree-Session Dateien nur unter dem
  Worktree-Pfad ändern, nicht im Hauptcheckout (`nvim-worktree-vs-main-checkout-trap`).
