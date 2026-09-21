# CI-Hardening — Handover (nur offene Punkte)

> Der Flotten-Rollout der CI-Sofortmaßnahmen ist **fertig** (2026-09-21, alle
> 39 Plugin-Repos, Protokoll:
> [sofortmassnahmen.md](../personal/All/FINISH/ERLEDIGT/sofortmassnahmen.md)).
> Die vier danach noch roten Repos sind **repariert**, `diff.nvim`
> veröffentlicht `ci-verified` und `gitsuite.nvim` pinnt darauf (siehe
> [Erledigt](#erledigt-2026-09-21)); offen bleibt nur der Kleinkram.

## Table of content

- [Regeln für diese Session](#regeln-für-diese-session)
- [Orte](#orte)
- [Erledigt 2026-09-21](#erledigt-2026-09-21)
- [Offene Punkte](#offene-punkte)
  - [Kleinkram](#kleinkram)
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
| Vorlage für `publish-ci-verified` | `E:\repos\diff.nvim\.github\workflows\ci.yml`, Job `publish-ci-verified` (vorwärts, fail-closed, `--force-with-lease`); gleiche Fassung in allen acht Repos mit Publish-Job (`lib`, `hover`, `runtime-analysis`, `pickers`, `ui`, `documentation`, `lsp`, `diff`); Scan: Workflows nach `refs/heads/ci-verified` durchsuchen und `--force-with-lease` zählen |
| Gelöschter Transformer | `git show 96c3b8537^:scripts/ci_hardening.py` — **ohne** die Pins für ui/documentation/pickers (diese Ergänzung ging mit der Löschung verloren; für einen Folge-Rollout `PIN_BRANCH` neu erweitern) |

## Erledigt 2026-09-21

Alle vier waren schon vor dem Rollout rot; die Ursachen lagen ausnahmslos im
**Testcode**, nicht im Produktcode. Stand nach den Fixes: CI voll grün auf
ubuntu, windows und macOS in `fileops`, `emojis`, `diff` und `filetree`
(damit 39 von 39 Repos grün).

| Repo | Commit | Ursache | Fix |
|---|---|---|---|
| `fileops.nvim` | `cad3e1a` | eine Zeile in `TESTS/cycle_edge_spec.lua` nicht stylua-konform | `stylua` |
| `emojis.nvim` | `2202683` | `unicode_spec` las `getreg("*")` zurück; ein Linux-Runner ohne Clipboard-Provider (xclip/wl-copy) speichert das Register nicht | Rücklesen von `*` nur bei `has("clipboard") == 1`, Rundreise zusätzlich über das immer vorhandene Register `-` |
| `diff.nvim` | `f1e0dbc`, `60fe9d4` | `history_spec` verglich den Buffernamen mit dem unaufgelösten `tempname()`; nvim speichert Buffernamen umgeschrieben (macOS `/var` → `/private/var`, Windows behält `RUNNER~1`). Der `url_spec`-„404"-Fehler war ein **Folgefehler** davon (s. u.) | Erwartung aus dem tatsächlichen Buffernamen ableiten |
| `filetree.nvim` | `fbe3812` | `TESTS/refs/run.lua` täuscht den OS-Restore über `run_argv.run_blocking` vor; das ruft nur `restore_windows` bedingungslos auf, `restore_linux_mac` braucht ein echtes `gio`/XDG-Trash → „Could not restore" auf ubuntu und macOS | Einträge der „chunked race"-Spec als `windows` aufzeichnen (`platform.current` kurz überschrieben), sodass jeder Host den vorgetäuschten Zweig nimmt |

Lehren (auch für künftige rote Repos):

- **Kaskadenfehler zuerst ausschließen.** Wirft ein `eq` in einer Spec, bricht
  sie ab, ohne ihre Aufräumzeilen (`vim.system = saved_system`) auszuführen;
  der Stub leckt in die **nächste** Spec. Der `url_spec`-Fehler war die
  zurückgegebene URL aus dem `vim.system`-Stub von `history_spec`. Die zweite
  rote Spec im Log erst nach der ersten prüfen. (Passt zu `busted-cascade-failures`.)
- **`fs_realpath` ist kein plattformübergreifender Normalisierer.** Es löst
  unter macOS Symlinks auf (richtig), expandiert unter Windows aber
  8.3-Kurznamen, die der Buffername behält. Erwartungswerte besser aus dem
  ableiten, was das System tatsächlich liefert (`nvim_buf_get_name`).
- **Ein Stub, der nur auf einer Plattform greift, ist ein versteckter
  Plattformtest.** Sitzt der Stub hinter einer `if platform`-Verzweigung im
  Produktcode, zwingt man den Test in diese Verzweigung, statt ihn
  „zufällig" nur unter Windows grün zu haben.
- **Ein Clipboard-Restore ist unzuverlässig.** Provider wie `win32yank`
  schreiben asynchron; trotz Sichern/Wiederherstellen stand in 2 von 3 Läufen
  der Testwert im System-Clipboard. Specs, die `*`/`+` schreiben, brauchen
  einen In-Memory-Provider (`vim.g.clipboard`, vor dem ersten Registerzugriff
  im Runner), keinen Restore.
- **Stubs im Runner isolieren, nicht nur in der Spec.** Die Aufräumzeile einer
  Spec läuft nicht, wenn ein `eq` davor wirft. `diff.nvim/TESTS/run.lua`
  sichert deshalb die gestubbten Funktionen vor jeder Spec und stellt sie
  danach wieder her.

### `ci-verified`: Job und Guard

Der Auto-Mode-Classifier lehnte das Anlegen des Jobs zunächst ab (Kategorie
„Unauthorized Persistence“: ein CI-Job, der per `--force` einen
Remote-Branch überschreibt); nach ausdrücklicher Freigabe des Nutzers
umgesetzt.

| Repo | Commit | Was |
|---|---|---|
| `diff.nvim` | `84987ab`, `a0807a9` | Job `publish-ci-verified` (`needs: [lint, tests]`); `a0807a9` ersetzt die Vorwärts-Vorlage aus pickers.nvim durch den gehärteten Guard (s. u.) |
| `gitsuite.nvim` | `b458053` | `diff.nvim`-Checkout mit `ref: ci-verified`; der letzte ungepinnte Konsument. CI grün auf allen drei Plattformen |
| `lib.nvim` | `2400f7e` | gehärteter Guard statt bedingungslosem `--force`; `docs/CONTRIBUTING.md` und `templates/README.md` sprechen nicht mehr von „force-pushed“ |
| `hover.nvim` | `dce6f07` | gehärteter Guard statt bedingungslosem `--force` |
| `runtime-analysis.nvim` | `4b513e4` | gehärteter Guard statt bedingungslosem `--force`; `map` bleibt bewusst **nicht** in `needs` |
| `pickers.nvim` | `fa90048` | ersetzt die Vorwärts-Fassung mit `\|\| status=new`; `needs` unverändert |
| `ui.nvim` | `3890818` | wie oben |
| `documentation.nvim` | `088c27f` | wie oben; `needs` bleibt `stylua, luacheck, tests, map, standalone` |
| `lsp.nvim` | `3147e92` | ersetzt das bedingungslose `--force` (`needs: [lint, test, smoke]` unverändert); `docs/CONTRIBUTING.md` sagt nicht mehr „force-pushes“ |

Der Guard (Skript im Job-Schritt „Publish ci-verified“):

- Der aktuelle Stand von `ci-verified` kommt aus `git ls-remote`, nicht aus
  einer API-Antwort: „Branch fehlt“ ist damit sauber von einem Fehler
  unterscheidbar, und ein fehlgeschlagener Lookup **stoppt den Job**. Die
  Vorlage aus pickers.nvim verschluckte jeden Compare-Fehler
  (`|| status=new`) und pushte dann trotzdem mit `--force`.
- `behind`/`identical` (Stand ist schon veröffentlicht oder überholt) wird
  übersprungen; `ahead`/`diverged` aktualisiert mit
  `--force-with-lease=refs/heads/ci-verified:<verglichener Stand>`. Läuft
  zwischen Vergleich und Push ein neuerer Lauf durch, lehnt der Server den
  Push ab, statt ihn zu überschreiben. Beides lokal gegen ein Bare-Remote
  mit flachem Klon und Stub-`gh` durchgespielt (Erst-Publish, ahead, behind,
  identical, diverged, API-Fehler, Race, unerreichbares Remote); die alte
  Vorlage fällt bei API-Fehler und Race durch.
- **Bekannte Grenze:** laufen zwei Läufe praktisch gleichzeitig ab, kann der
  spätere am Lease scheitern; der Job ist dann rot und `ci-verified` bleibt
  auf dem früheren Commit. Sicher (fail-closed), ein Re-run genügt.
- `map` in `runtime-analysis.nvim` bleibt draußen: der Self-Heal-`git push`
  dort kann bei einem Push-Race scheitern, ohne dass der Code kaputt wäre; die
  frühere Review-Notiz „wartet nicht auf `map`“ war demnach kein Fehler, der
  Kommentar im Workflow hat recht.

### Review der Commits dieser Session

| Fund | Repo | Commit | Fix |
|---|---|---|---|
| Guard schluckte API-Fehler und hatte ein Race-Fenster (s. o.) | `diff`, `lib`, `hover`, `runtime-analysis`, `pickers`, `ui`, `documentation`, `lsp` | `a0807a9`, `2400f7e`, `dce6f07`, `4b513e4`, `fa90048`, `3890818`, `088c27f`, `3147e92` | fail-closed + Lease; bei allen acht lief der Lease-Pfad im echten Lauf (`<alt>...<neu> (forced update)`), `ci-verified` steht jeweils auf dem gepushten Commit |
| Test überschrieb bei jedem lokalen Lauf das System-Clipboard mit „233“ (schon im Original; ein Restore-Versuch erwies sich als unzuverlässig) | `emojis.nvim` | `532d633` | In-Memory-Provider im Runner; `*` wird nun auch auf nacktem Linux getestet, das `has("clipboard")`-Gate entfällt |
| Runner ließ Stubs nach einer fehlgeschlagenen Spec in die nächste lecken (Ursache des irreführenden `url_spec`-Fehlers) | `diff.nvim` | `4c2c5ad` | Snapshot/Restore pro Spec; mit absichtlich gebrochener Spec belegt: nur noch 1 statt 2 Fehlschläge |
| `record_as_windows` stellte `platform.current` nicht wieder her, wenn `record` wirft | `filetree.nvim` | `498330d` | `pcall` + Restore + erneutes Werfen |

Geprüft ohne Befund: `fileops.nvim` `cad3e1a` (reine Formatierung),
`gitsuite.nvim` `b458053` (nur `ref`), der Standard-`GITHUB_TOKEN` ist in
allen fünf berührten Repos **read-only** (`contents: write` gibt es nur im
Publish-Job), der neue Publish-Schritt reicht `github.*`-Werte über `env:` durch
statt sie in die Shell zu interpolieren, und keine Commit-Message trägt eine Co-Author-Zeile.
Der Flotten-Scan findet keinen Publish-Job mehr ohne Guard (8 von 8), und
`scripts/ci_status.sh` bestätigt am Ende: **39 / 39 voll grün**.

## Offene Punkte

### Kleinkram

- **13 Kind-Prozess-Spawns in Specs** (`"--headless"` in `casedesk`,
  `cmdlog`, `insights`, `language`, `media`, `pdfport` u. a.) ohne
  `-n`/`--clean`: prüfen, ob eines davon Dateien öffnet (E326-Risiko), bevor
  man Testcode anfasst.
- **Node-20-Verdacht** bei Aktionen außerhalb des Rollouts (mdview-WASM- und
  `release-engine`-Artefakte, `setup-node@v4`, `setup-go@v5`, `cache@v4`,
  Pages-Aktionen): Liste im Abschlussprotokoll; erst die Annotation eines
  echten Laufs lesen, dann gezielt anheben.
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
- **luacheck im Repo-Wurzelverzeichnis** (`luacheck .`) meldet in
  `filetree.nvim` Treffer aus fremden Worktrees unter `.claude/worktrees/`.
  Wie CI aufrufen (`luacheck lua docs/BINDINGS.lua TESTS`), sonst falsche Alarme.

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

- **Fehlgeschlagene Specs aus dem Log ziehen:**

  ```bash
  gh run view "$id" --log-failed | grep -n "FAIL"
  ```

  Bei einem Verdacht auf Kaskade (Lehren oben) den Fehler-Text im Test
  vorübergehend um den tatsächlich erhaltenen Wert erweitern; das hat beim
  `url_spec`-Fall die Ursache in einem Lauf sichtbar gemacht.
- **`ci_status.sh` meldete einmal „no CI run for this commit"** (replacer.nvim),
  obwohl der Lauf grün war (vermutlich ein Timing-Effekt, nicht geprüft) —
  dann `gh run list --limit 3` direkt lesen.
- **`docs_linkcheck.py` unter Windows:** mit `PYTHONUTF8=1
  PYTHONIOENCODING=utf-8` starten, sonst bricht es bei Emoji-Zeichen mit
  `UnicodeEncodeError` ab.
- **Push auf `main` verifizieren:** `main` wird gelegentlich aus dem
  Hauptcheckout force-gepusht, ein eigener Push kann dabei verschwinden
  (so geschehen mit dem Akten-Commit dieser Session; die Plugin-Repos
  waren nicht betroffen). Nach jedem Push `git fetch` und
  `git merge-base --is-ancestor HEAD origin/main`; bei `NO` auf das neue
  `origin/main` rebasen und neu pushen. Die Remote-Tracking-Refs teilen
  sich alle Worktrees: eine andere Session kann sie zwischen zwei Befehlen
  weiterbewegen.
- **Worktree-Falle:** In einer Worktree-Session Dateien nur unter dem
  Worktree-Pfad ändern, nicht im Hauptcheckout (`nvim-worktree-vs-main-checkout-trap`).
