# hover.nvim — Handover

Stand: **2026-09-02**. Diese Datei ist der **aktuelle Stand**: was das Plugin
ist, wo es steht, und was man wissen muss, um daran weiterzuarbeiten.

Repo: <https://github.com/StefanBartl/hover.nvim> · lokal `E:/repos/hover.nvim`
Branch: **`main`**, alles gepusht.

## Drei Dokumente, drei Fragen

| Wo | Frage | Adressat |
| --- | --- | --- |
| **diese Datei** | wo steht es, und wie arbeite ich daran | ich, beim Wiedereinstieg |
| [hover.nvim-roadmap.md](hover.nvim-roadmap.md) | was kommt als Nächstes, was ist noch nicht entschieden | ich, beim Weiterbauen |
| `hover.nvim/docs/FEATURES/` | **warum** ist ein Feature so, wie es ist | wer mitliest (im Repo, englisch) |

**Ausgemistet am 2026-09-02.** Diese Datei war auf 1 400 Zeilen gewachsen und
führte zehn abgeschlossene Auftragsberichte. Die Begründungen daraus liegen
jetzt im Repo unter `docs/FEATURES/` (`2927e38`), das Offene in der Roadmap.
Die Regel dahinter ist dieselbe wie zwischen den beiden Roadmaps: **jeder
Punkt lebt an genau einer Stelle.**

---

## Wo es steht

**Fertig und öffentlich.** Die Extraktion aus lib.nvim ist abgeschlossen,
`lua/lib/nvim/hover/` dort gelöscht (`5450dd4`). CI grün auf ubuntu-latest
*und* windows-latest. Beide Gates durch: `RELEASE.md` 29 von 32 mit drei
begründeten Ausnahmen, `REVIEW.md` grün.

**Woher es kommt**, weil die Entscheidung sonst nirgends mehr steht: der
Hover war ein Modul in lib.nvim und traf die dortige Ausschlussregel („kein
Feature mit eigener UI, eigenem Zustand und eigener Historie") **dreifach** —
vier `nvim_open_win`, global geliehene Keymaps und eigene Highlight-Gruppen;
LRU, Session-Schalter und On-Disk-Cache; Scroll-Offset und Fetch-Cache. Dazu
3 949 LOC = 8,3 % von lib.nvim, drittgrößtes Modul, in vier Tagen entstanden,
und das einzige, das gleichzeitig Fenster öffnet, Autocmds installiert *und*
Routen mitbringt. Der Präzedenzfall war zweimal gelaufen (`lib.nvim.docmap` →
documentation.nvim, `lib.nvim.telemetry` → runtime-analysis.nvim). Kosten des
Umzugs: neun Module generischer Infrastruktur mit null lib.nvim-Kopplung.

**Gemessen nach `2927e38`:**

| Prüfung | Ergebnis |
| --- | --- |
| Specs | **233 grün**, 0 Fehler (bare_git 10, bare_path 48, config 17, docs 13, registry 71, scope 26, switches 30, zoom 18) |
| `stylua --check` / `luacheck` | sauber (30 Dateien) |
| LuaLS (`scan.sh`, echte injizierte Library) | 0 Befunde, Pass `post-f` — **mit Vorbehalt**, siehe Roadmap §3 |
| CI | grün auf beiden Runnern |
| Helptags | 30 |

**Was es kann**, in einem Satz je Klasse: Datei- und Verzeichnisvorschauen,
Bilder und PDF-Seiten gezeichnet, Office-Dokumente über LibreOffice (opt-in),
URLs mit optionalem Abruf, Bare Paths mit Zeilen und Ranges
(`init.lua:42`, `file.lua:10-20`), Git-Objekte auf Nachfrage,
Position-Previews fremder Plugins, `:Hover why`, `:Hover pin`, Zoom für Bilder
(Tasten, Rad, Route), ein Schalter-Chooser über lib.nvims UI-Kit — und seit
`c374d5e` ein eigener Hover **ohne Plugin drumherum** (`setup({ contribute })`).

Einzelheiten im Repo: [README](https://github.com/StefanBartl/hover.nvim),
`docs/BINDINGS.md`, `docs/FEATURES/`.

## Wer beiträgt

**Sechs über die Registry** (das Plugin nennt keinen davon beim Namen):
markdown.nvim, migrate.nvim, reposcope.nvim, documentation.nvim,
spotlight.nvim, sandbox.nvim.

**Vier namentlich als weiche Abhängigkeit** (hover `pcall`t sie selbst):
gopath.nvim, open.nvim, images.nvim, pdfport.nvim.

Wer was beisteuert und was ohne ihn ausfällt: `docs/INTEGRATIONS.md` im Repo.
Alle sind optional, keiner erforderlich.

## Was offen ist

Wenig, und das meiste bewusst. Es steht **einmal**, in der
[Roadmap](hover.nvim-roadmap.md):

- **§2** — was ich als Nächstes bauen würde, in Reihenfolge.
- **§3** — offene Messungen. Zwei davon brauchen dich: das **Demo-GIF**
  (`REL-09`) und der **Office-Pfad von Hand**.
- **§4** — fünf Aufträge, die in fremden Repos liegen.
- **§6** — offene Entscheidungen: die kollidierende Lua-Modulwurzel, und ob
  `manual` der bessere Default wäre.

---

## Was beim Weiterarbeiten zu wissen ist

- **Regelwerk:** `WKDBooks/Development/wkdbook-Lua/Checklists/`, für dieses
  Repo `gates/NEW_PROJECT.md` (einmal durch, `NEW-01`…`NEW-46`),
  `regeln/LUA_NVIM.md` beim Schreiben.
- **Commits ohne KI-Co-Author** — steht so in `NEW_PROJECT.md` und ist hier so
  gehalten.
- **Keine Lizenzdatei** (`NEW-06`, `REL-28`) — bewusst keine angelegt, auch
  wenn pdfport/gopath welche haben.
- **stylua-Stil:** `collapse_simple_statement = "Never"`, wie lib.nvim. Nicht
  wie markdown.nvim (`"Always"`) — der übernommene Code ist in lib.nvims Stil
  geschrieben, und eine Extraktion ist der falsche Moment, den ganzen
  Quelltext umzuformatieren.
- **Tests:** `LIB_NVIM_DIR=E:/repos/lib.nvim
  PLENARY_DIR=C:/Users/bartl/AppData/Local/nvim-data/lazy/plenary.nvim
  bash scripts/test.sh`
- **LuaLS messen:** `REPOS_DIR=E:/repos bash scripts/luals-scan/scan.sh <pass>
  hover.nvim`, dann `python scripts/luals-scan/compare.py <pass>`. Die nackte
  `lua-language-server --check`-Zahl ist wertlos (`LLS-01`).
- **Der Scan sieht `TESTS/` mit, und das ist nicht theoretisch.** Am
  2026-09-02 kam `zoom-post` mit **+2** zurück, beide Befunde im neuen
  `docs_spec.lua`. Die Suite war grün, stylua sauber, CI grün — **nur der Scan
  hat es gesehen** (behoben in `65ba8dd`). Ein Spec ist Code, und nach dem
  Schreiben eines gehört ein Lauf dazu, nicht nur nach einer Änderung an
  `lua/`.
- **Git-Bash-Falle:** headless nvim mit einem `/tmp/...`-Pfad **hängt still**,
  statt zu scheitern. Windows-Pfade verwenden. (Steht auch in
  `scripts/luals-scan/scan.sh`.)
- **luals-scan liegt in der Config**, nicht im Plugin-Repo:
  `nvim/scripts/luals-scan/`. Und: **nicht den Worktree scannen** — die
  injizierte Library kommt vom Haupt-Checkout, dieselben `Hover.*`-Klassen
  also zweimal, Ergebnis ~100 unechte `duplicate-doc-field`. Erst den
  Haupt-Checkout nachziehen, dann den scannen.
- **Ein voller Config-Start headless hängt still.** Auch mit Windows-Pfaden.
  Isoliert prüfen (`-u NONE` plus `set rtp+=`) oder interaktiv.
- **Mauseingaben lassen sich headless nicht treiben.** `nvim_input_mouse`
  feuert ohne angehängtes UI **null** Mappings; `feedkeys` mit demselben
  Termcode feuert eines. Was ein echtes Rad angeht, ist deshalb Handprüfung.
- **Die Doku ist spec-geprüft.** `TESTS/docs_spec.lua` liest README, Vimdoc
  und `docs/**/*.md` gegen die Quelle: Schalternamen, alle `:Hover`-Routen in
  beide Richtungen, Zieltypen, Augroups und Highlight-Gruppen, die
  Tastenlisten aus `DEFAULTS`, und die Regeln, die `MANUAL-EVIDENCE.md` über
  sich selbst aufstellt. **Wer eine Option oder Route ergänzt, bekommt vom
  Spec gesagt, welches Dokument fehlt** — verlassen kann man sich darauf für
  alles außer den Integrations-Tabellen, die fremde Plugins beschreiben.
- **Vor dem Bauen messen.** Drei Messungen in diesem Repo haben der Intuition
  widersprochen, die sie prüfen sollten; zweimal war die naheliegende Lösung
  die falsche. Die Zahlen stehen in den Modulköpfen von `hover.scope` und
  `hover.bare_path`, nicht in Commit-Messages, damit sie beim Ändern des Codes
  gelesen werden. Ausführlich: `docs/FEATURES/BARE-PATHS.md`.

---

## Wo was steht

| Frage | Datei |
| --- | --- |
| Was tut es, wie konfiguriere ich es | `README.md` im Repo |
| Welche Taste, welches Kommando, welcher Autocmd | `docs/BINDINGS.md` |
| **Warum** ist das so gebaut | `docs/FEATURES/` |
| Wer ist wie angebunden, was fällt ohne ihn aus | `docs/INTEGRATIONS.md` |
| Was ist bewusst *nicht* gebaut | `docs/ROADMAP.md` (an Mitlesende) |
| Was kann keine CI prüfen | `docs/MANUAL-EVIDENCE.md` |
| Was baue ich als Nächstes, was ist unentschieden | [hover.nvim-roadmap.md](hover.nvim-roadmap.md) |
| Welche Tasten/Kommandos/Autocmds in **dieser** Config | `docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/hover.nvim.md` |

## Zuletzt passiert

Umgekehrt chronologisch, nur was den Stand ändert. Die Begründungen stehen in
den Commits und unter `docs/FEATURES/`.

- `2927e38` — `docs/FEATURES/` angelegt, diese Datei ausgemistet.
- `c11e397`, `83922f0`, `2493e1b`, `204d083` — Zoom für Bilder: Tasten, Route
  `:Hover zoom`, Mausrad mit Zeigerprüfung.
- `e62f5e9`, `b7c4c45` — `on_request` als wiederholbare Sonde
  (`scripts/onrequest_probe.lua`) plus Evidenzzeile; ein flackernder
  LuaLS-Befund festgenagelt.
- `aca73fa` — `:checkhealth` sagt, wer was registriert hat.
- `4e1760f` — der Doku-Spec.
- `3e12c9f` — der Hauptschalter schlägt jetzt `force`: `vim.g.hover_disable`
  war von jeder ausdrücklichen Route aushebelbar, auch von der Keymap eines
  Hosts.
- `87a1017` — zwei Augroups hießen noch nach markdown.nvim.
- `c374d5e` — `contribute`: ein eigener Hover ohne Plugin.
- `a57d390`, `f01511f` — README- und Roadmap-Tabellen, die fünf der sechs
  Integrationen nicht kannten.
- `836a15a` — ein `on_request`-Beitrag war über keinen Weg erreichbar.
