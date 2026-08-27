# Merged Roadmap -- Erledigt

Aus `MERGED.md` herausgenommene Tasks, sobald sie abgeschlossen sind.
Neueste zuerst. Gilt fuer alle `*.nvim`-Repos unter `C:/repos` plus diese
nvim-Config.

---

## 2026-08-27

### Bindings, Keymaps & UI

- [x] **Neues `lib.nvim`-Keymap-Modul + alle Plugins darauf umgestellt.**

      Pfad wie gewuenscht: `lua/lib/nvim/bindings/keymap`. Das Modul ist mehr
      als ein Wrapper um `vim.keymap.set` — es ist eine **Registry**: ein
      Plugin *deklariert* seine Keymaps als benannte Actions, der User
      ueberschreibt sie ueber die Install-Spec.

      **Zur Frage aus MERGED.md, `"[a": "]u"` vs. Aktionsnamen:** Aktionsnamen
      gewonnen, und zwar aus dem Grund, den du selbst geahnt hast. Die
      lhs-als-Key-Variante kann nicht sagen, *wessen* `[a` gemeint ist — zwei
      Plugins mit demselben Default-Key waeren nicht unterscheidbar, und ein
      Tippfehler im lhs waere von "diese Taste ist eben nicht gemappt" nicht zu
      trennen. Mit Namen ist beides geloest:

      ```lua
      {
        keymaps = {
          copy_absolute = "<leader>yp",          -- verschieben
          jump_anchor   = { "mj", "gj" },        -- mehrere Tasten
          open_image    = false,                 -- abschalten
          preset        = false,                 -- gar nichts binden
        },
      }
      ```

      Der Aufwand fuer "jedes Mapping braucht einen sinnvollen Namen" war
      klein: die Namen kommen aus den `desc`-Strings, die ohnehin ueberall
      standen ("logs (follow)" -> `logs_follow`).

      **Was das Modul kann** (ueber das Umbiegen hinaus):

      - **Tippfehler werden gemeldet, mit Levenshtein-Vorschlag.** `oepn` sagt
        `no such keymap action: oepn (did you mean open?)`. Vorher war ein
        vertippter Override komplett stumm — die Map erschien nicht, und
        nirgends stand warum. Das ist der Fehler, der einen Nachmittag kostet.
      - **Eine Action, mehrere Tasten** (`{ "<CR>", "i" }`) und **eine Action,
        mehrere Modes** (spotlights `toggle_here`: Cursor in Normal, Selektion
        in Visual — ein Name, ein Key, ein Override).
      - **Deklariert != gebunden.** Eine abgeschaltete Action bleibt
        registriert, damit `:checkhealth` und generierte Docs beantworten
        koennen, was es *gibt*, nicht nur was gerade gebunden ist.
      - **`keymap.registered()` / `keymap.conflicts()`** — die zentrale Liste
        aller Actions aller Plugins, inklusive Kollisionserkennung ueber
        Plugin-Grenzen.
      - **which-key**: nur das, was which-key *nicht* selbst herausfindet.
        which-key liest Mappings und deren `desc` naemlich selber (siehe
        `which-key/buf.lua`) — ein `which_key = true`-Schalter pro Key waere
        ein No-op gewesen. Bleiben: Gruppenlabels, Icons und Verstecken
        (`which_key_ignore`). **Nebenbefund:** vier Plugins haben genau das
        doppelt registriert, teils mit abweichendem Wortlaut, also mit zwei
        Orten zum Auseinanderdriften. Die `bindings/which_key.lua`-Dateien
        sind entsprechend geloescht (documentation.nvim behaelt seine, die
        macht mehr).
      - **Icons nur mit Nerd Font.** Neues `lib.nvim.ui.nerd_font` mit
        `available()` / `glyph(hex, fallback)`. Detektion ist nachweislich
        unmoeglich (`strdisplaywidth` liefert fuer *jeden* Codepoint 1, auch
        fuer `U+10FFFD`), also entscheidet `vim.g.have_nerd_font` — deklariert
        statt geraten, damit ohne Font keine Kasterl erscheinen.

      **Umgestellt** (29 Repos): spotlight, emojis, insights, fileops, open,
      diff, buffer-ctx, images, cmdlog, dap, pickers, reposcope, cascade,
      learn-cli, lsp, migrate, color_my_ascii, github_stats, debugging,
      pdfport, recommender, sandbox, sessions, language, markdown, filetree.

      **Bewusst nicht umgestellt, mit Grund:**

      - `gopath.nvim` — die Keys muessen auf `g*` bleiben, das ist der Witz
        daran (deine Vorgabe). Kein Gruppenlabel, weil ein Label auf `g` die
        19 eingebauten Vim-`g`-Mappings mitbeschriften wuerde (nachgemessen).
      - `runtime-analysis.nvim` — hat per Design null Keymaps, jeder
        Einstiegspunkt ist ein `:RA`-Subcommand.
      - `documentation.nvim` — `:DocBrowse` hat die Registry-Semantik bereits
        selbst (Namen, Listen, `false`, Tippfehler-Report) *plus* drei Dinge,
        fuer die die Registry keine Form hat: `where` (Liste- vs. Detail-Pane),
        `only` (Mode-Scope) und Closures ueber *eine* Browser-Instanz, von
        denen zwei gleichzeitig offen sein koennen. Steht als Begruendung im
        Modulkopf.

      **Was dabei an echten Bugs herausfiel:**

      - `lib.nvim`s `set()` schrieb `desc`/`noremap`/`silent`/`buffer` in die
        *uebergebene* Options-Tabelle zurueck. Wer eine Tabelle fuer mehrere
        Bindings wiederverwendet, schleppte den `desc` des vorigen Keys mit —
        documentation.nvim hatte deshalb in which-key jede Taste als "close"
        beschriftet und baute zur Umgehung pro Binding eine frische Tabelle.
        Kopiert jetzt; Regressionstest pinnt beide Haelften.
      - `which_key.add_group` war lokal, also gar nicht aufrufbar, und `apply`
        ignorierte ein `prefix` in der Gruppenspec — Plugins ohne gemeinsamen
        `spec.prefix` registrierten still gar keine Gruppe.
      - `language.nvim`: `clear()` loeste die Session ueber den *aktuellen*
        Buffer auf, aber `list.open` laesst den Cursor im Quickfix-Fenster —
        die Session vom dort aus abschalten fand nichts und liess die echte
        weiterlaufen, samt Keymaps. Faellt jetzt auf die einzige aktive
        Session zurueck.
      - `filetree.nvim`: der `?`-Cheatsheet baute aus dem Default-Katalog, hat
        also nach einem Remap selbstbewusst eine Taste genannt, die es nicht
        mehr gab. Liest jetzt die Registry.

      **Nebeneffekt, groesser als erwartet:** `filetree.nvim` hatte denselben
      Bindungsblock 36-mal, in vier bis fuenf Varianten, mit dem `desc`-Praefix
      in zwei Schreibweisen. Das ist jetzt ein `util/bind.lua`. `pdfport.nvim`
      hatte dieselben fuenf Actions dreimal (netrw/oil/nvim-tree), die sich in
      genau einer Sache unterschieden — wie der Pfad unterm Cursor gefunden
      wird; jetzt einmal, parametrisiert.

      **Neu konfigurierbar, was es vorher nicht war:** sandbox' saemtliche
      List-View-Keys (vorher gar keine Konfiguration), markdowns
      `<leader>tv*`-TableView-Keys, recommenders Float-Keys (`y`/`A`/`<BS>`/
      `U`/`?`) inkl. `?`-Hilfe, die liest was gebunden *ist*, filetrees
      `<Nop>`-Prefix-Unblocking in copy_move.

- [x] **`lib.nvim.autocmd` / `lib.nvim.usercmd` -> `bindings/`** und alle
      Plugins darauf umgestellt (809 Aufrufstellen in 30 Repos).

- [x] **Shims geloescht — du hattest recht.** Deine Frage in MERGED.md
      ("halte ich einen Shim fuer nicht notwendig, siehst du das anders?"):
      nein, sehe ich nicht anders. Der Shim war die richtige *Zwischen*stufe,
      weil die Reihenfolge des Nachziehens beim Plugin-Manager liegt und nicht
      bei dir — aber er hatte genau eine Aufgabe, und die ist erledigt. Alle
      30 Repos sind migriert (per grep verifiziert), alle 29 Plugins laden
      gegen ein lib.nvim ohne Shims. Dazu steht in Zeile 1 der lib.nvim-README,
      dass Breaking Changes wahrscheinlich sind. Weg damit; eine
      Kompatibilitaetsschicht, die ihre Migration ueberlebt, wird nie wieder
      geloescht.

- [x] **Keymap ↔ Usrcmd-Parität nachgemessen — keine Lücke.** Über alle 29
      Plugins ist jede deklarierte Keymap-Action auch über ein Kommando
      erreichbar; es gibt keinen Fall, für den ein "Grund, warum nicht" nötig
      wäre. Nachgemessen statt geschätzt: seit der Registry kennt
      `keymap.registered()` jede Action, `composer.registry()` jede Route.

      Alle Kandidaten aus dem automatischen Abgleich waren falsch positiv,
      weil eine Route mit typisiertem Argument viele Actions abdeckt, ohne
      eine davon beim Namen zu nennen — `:Open firefox` deckt alle 18
      `open_*`-Actions, `:File next vsplit` die ganze Cycle-Familie,
      `:File! delete` die Force-Variante. Report + Skript:
      `docs/ROADMAP/keymap-command-parity.md`.

- [x] **Featureliste "implementiert, aber nicht konfigurierbar"** — 45
      Kandidaten in 15 Repos, sortiert in *konfigurierbar machen* (21),
      *bleibt Konstante mit Grund* (9, u. a. Base64-Alphabet, `MIN_NVIM`,
      Telemetrie-Fingerprint) und *strittig* (6, davon 4 mit Rückfrage
      geklärt). Report: `docs/ROADMAP/nicht-konfigurierbare-features.md`.

- [x] **Konfigurierbarkeit, Durchgang eins: 21 Konstanten umgesetzt** in 12
      Plugins, jeder Key mit unverändertem Default und LuaLS-Typ, jeder
      einzeln getestet.

      Nebenbefund, der die Runde überhaupt erst nutzbar machte:
      `github_stats.setup()` verwarf **jede** Option außer `repos` still,
      sobald eine `config.json` existierte — und die schreibt das Plugin beim
      ersten Lauf selbst. `setup({ dashboard = { … } })` tat also nichts,
      ohne dass irgendwo stand warum. Reihenfolge jetzt: Datei (oder Default)
      als Basis, `setup()` gewinnt darüber.

      Die vier strittigen Fälle sind entschieden: Sparklines fallen über
      `lib.nvim.ui.nerd_font` auf eine ASCII-Rampe zurück (dafür neu:
      `nerd_font.chars`, das einen Zeichensatz als *Ganzes* wählt — eine
      Reihe, die `█` mit `#` mischt, liest schlechter als jede der beiden
      allein); reposcopes Spaltenbreiten bleiben fest, dafür werden
      Branch-Namen **mittig** gekürzt, weil bei `claude/…-47a46e` der Hash am
      Ende der unterscheidende Teil ist; sandbox bekommt `max_error_length`
      **plus** einen Hinweis, wo der volle Text steht; der Logger nimmt
      `max_depth`/`max_items` als Instanz-Default *und* pro Aufruf.

- [x] **Konfigurierbarkeit, Durchgang zwei: Zahlen ohne Namen.** 43 Zahlen,
      47 Plattform-Verzweigungen. Das Ergebnis war ausdrücklich *nicht* "43
      neue Keys": 26 der 43 sind Float-Größen (`vim.o.columns * 0.8`) in neun
      Plugins, also **eine** Entscheidung. Gelöst, indem `lib.nvim`s
      `make_scratch` jetzt Bruchteile nimmt — die Konvention stand längst in
      `kit.layout`, nur nicht dort, wo alle 26 Aufrufe landen.

      Beinahe ein stiller Regressionsbug dabei: `kit.layout` liest `1` als
      "das Ganze", `make_scratch` muss es als *eine Zelle* lesen — `kit.input`,
      `kit.live_input`, beide Progress-Styles und die Statusline übergeben
      `height = 1` und meinen es so. Bruchteil ist deshalb strikt zwischen 0
      und 1, gegen HEAD gegengeprüft.

      Die Plattform-Verzweigungen brauchen fast durchweg kein Opt-out, weil
      sie Tatsachen über das OS sind. Der einzige echte Fund dort war ein
      **Bug**: filetrees Größenanzeige rief `du -sb` auf, und `-b` ist
      GNU-only — auf macOS/BSD endete der Prozess mit Exit ≠ 0 und die Spalte
      blieb dauerhaft leer, ohne Fehlermeldung. Jetzt `du -sk` mal 1024.
      Report: `docs/ROADMAP/zahlen-ohne-namen.md`.

---

## 2026-08-26

### Git & Repo-Hygiene

- [x] **Claude-Branches entfernen — jetzt wirklich alle.** Der Eintrag vom
      25.08. ("26 von 28") zählte nur die *Remote*-Branches; die beiden dort
      genannten sind tatsächlich weg. Lokal lagen aber noch **107**: 59 in
      16 Plugin-Repos und 48 in dieser Config, dazu **33 verwaiste Worktrees**
      unter `.claude/worktrees/`, von denen einige Branches ausgecheckt hielten
      und damit deren Löschung blockierten.

      Endstand: 0 Claude-Branches, lokal wie remote, in allen Plugin-Repos und
      in der Config — bis auf die zwei, die in noch offenen Config-Worktrees
      ausgecheckt sind. 33 Worktrees entfernt, 7 Remote-Branches gelöscht.

      **Nichts davon wurde blind gelöscht.** 10 Branches trugen je einen
      Commit, der nicht auf `main` war, und 3 Worktrees hatten unversionierte
      Änderungen. Jeder einzelne wurde gegen den heutigen Stand geprüft, statt
      nach Alter zu entscheiden. Sieben waren überholt — die Arbeit war auf
      anderem Weg gelandet, was jeweils belegt und nicht angenommen wurde:
      `get_module_path` wird benutzt, `check_heading_gaps` und
      `sanitize_on_save` existieren, `spotlight.winopt` existiert, die
      `pcall`-Regel und die Deprecated-API-Tabelle stehen als `ERR-62` bzw.
      `DEP-01`…`DEP-07` in den WKDBooks-Checklists, die Windows-Foreground-Lock-
      Analyse wortgleich in `lib.nvim/…/reveal_in_fm/init.lua`, und
      `wkdoptions/commands/{highlight,options}.lua` sind längst weg.

      Drei waren es nicht und wurden gerettet.

- [x] **Drei verwaiste Arbeitsstände aus Worktrees nach `main` geholt.**
      - `spotlight.nvim`, Duplicate-Helptag: `*that*` in einer `.txt`-Helpdatei
        ist keine Hervorhebung, sondern eine **Tag-Definition** — und das Wort
        kam zweimal vor. `:helptags doc` brach deshalb nicht mit einer Warnung
        ab, sondern mit `E154: Duplicate tag "that"`: die Help-Tags des Plugins
        liessen sich überhaupt nicht erzeugen.
      - `spotlight.nvim`, buffer-scoped Spotlights: eigener Eintrag unten.
      - Config, casedesk: ein Datenschutz-Vermerk zum anstehenden KI-Ausbau
        (Anhänge vor der Übergabe an eine KI schwärzen). Beide darin genannten
        Referenzen gegen den heutigen Baum nachgeprüft statt kopiert: `:Image
        redact` gibt es noch, die Beschreibung ist aber von
        `docs/ROADMAP/REDACT.md` nach `docs/FEATURES/CAPTURE.md` gewandert.

### Fehlerbilder aus dem laufenden Betrieb

- [x] **blink.cmp: "Failed to create frecency database directory … (os error
      183)" bei jeder Completion.** Kein Mapping-Problem, sondern ein
      Versions-Mismatch in `lsp.nvim`s Spec: `version = "1.*"` zog die Lua-Seite
      auf 1.10.2, `prebuilt_binaries.force_version = "v1.4.0"` nagelte die
      Rust-DLL auf 1.4.0 fest. Die alte Binary erwartet als Frecency-Pfad noch
      das LMDB-*Verzeichnis*, blink >= 1.5 übergibt die *Datei* `frecency.dat` —
      `create_dir_all()` läuft damit gegen eine existierende reguläre Datei.
      Weil `init_db()` vor `has_init_db = true` abbricht, kam der Fehler bei
      jeder Completion neu. Pin entfernt; der Downloader holt jetzt die Binary
      zum tatsächlich aufgelösten Tag.

- [x] **`[gopath] no match: no-match` direkt nach dem Start.** Installations-Spec:
      `open_here = { "gF", "<2-LeftMouse>" }`. gopath registriert jedes
      `open_here`-lhs als *globales* Normal-Mode-Mapping ohne Fallback — jeder
      Doppelklick in jedem Buffer löste einen Pfad-Resolve aus statt das Wort zu
      selektieren, und jeder Fehlschlag warnte. Auf `gF` reduziert.

- [x] **`clipboard: … "stream did not contain valid UTF-8"`.** `win32yank.exe -i`
      liest stdin mit `read_to_string().unwrap()`: ein einziges ungültiges Byte
      lässt den Prozess panicken und bricht den **gesamten** Write ab — die
      Zwischenablage behält ihren alten Inhalt, während `y` so aussieht, als
      hätte es funktioniert. Neovim-Register sind Byte-Strings, das trifft rohe
      Termcodes, latin-1-`fileencoding`, OEM-Codepage-Output. `copy` ist jetzt
      eine Lua-Funktion, die ungültige Bytes durch `?` ersetzt und danach
      dasselbe Kommando fährt; gültiges UTF-8 läuft byte-identisch durch.

### CI

- [x] **Zwei rote map-Gates grün.** `runtime-analysis.nvim`: der Rename
      `docs/FEATURES/FINISHED.md` → `docs/FEATURE_LOG.md` hat 22 Links
      zerrissen — drei Verweise darauf und, weil die Datei eine Ebene höher
      landete, sämtliche `../../`-Links *in* ihr. Wichtig dabei: die Karte wird
      aus einem Drift-Scan erzeugt, der tote Links meldet. Sie einfach neu zu
      generieren hätte den kaputten Zustand als neuen Sollzustand einbetoniert.
      Erst Links repariert, dann Karte — zurück auf 0 Warnungen.
      `documentation.nvim`: Karte schlicht nicht nach Quelländerungen erneuert.

      **Offen, nicht unser Fehler:** GitHub Actions legt seit ca. 12:35 UTC für
      neue Pushes keine Workflow-Läufe mehr an (passend zu "Our services aren't
      available right now" in den älteren Logs). Alle Gates wurden lokal mit
      denselben Kommandos gefahren und sind grün.

### Bugfixes in Plugins

- [x] **`spotlight.nvim`: buffer-scoped Spotlights waren für jeden Scan
      unsichtbar.** Ein "this occurrence only"-Spotlight trägt `\%l\%c`-
      Positionsatome im Pattern. Die werden von Vims eigener Such- und
      Render-Maschinerie ausgewertet — und von sonst nichts:
      `vim.regex:match_str` liefert auf **jeder** Zeile `nil`, auch auf der
      richtigen. Direkt nachgemessen, nicht gefolgert.

      Jeder Scan in `core/count.lua` fährt über `vim.regex`, das Ergebnis war
      also leise und widersprüchlich: das Spotlight ist sichtbar auf dem
      Schirm, weil `matchadd()` das Pattern sehr wohl versteht, aber die Liste
      zählt 0, `:Spotlight qf` antwortet "no matching lines in this buffer",
      und die Map hat kein Sign dafür.

      So ein Item lässt sich nicht suchen, nur nachschlagen — sein Treffer ist
      ein bereits gespeicherter Punkt. `M.count` liest ihn direkt; der
      Quickfix-Pfad läuft über ein neues `matching_lines_for`. Das ebenfalls
      betroffene `matching_lines_by_item` (die Map, später dazugekommen und dem
      alten Fund noch unbekannt) bekam dieselbe Behandlung.

      Die Doku behauptete genau das Gegenteil — "needs no special handling at
      all … a position-anchored pattern is still just a valid Vim regex to
      them" — und war damit die Annahme, die den Bug erzeugt hat. Beide Stellen
      nennen jetzt die Engine, von der die Aussage abhängt.
      `TESTS/qf_buffer_scope_spec.lua` pinnt alles: 6 Fehlschläge ohne den Fix,
      449 grün mit ihm.

### Beantwortet, kein Code nötig

- [x] **`docmap-desktop`: `workspace.json` ist ein Objekt, `workspaces/*.json`
      eine Liste — Formatbruch?** Nein, Absicht und im Code begründet.
      `workspace.json` sind Maschinen-Settings plus der aktive Workspace; sein
      `projects: []` wird von `write_workspace` bewusst leer geschrieben ("it
      would be a stale second copy the moment anything is added to the real
      one"). Das Feld bleibt nur im Struct, weil `read_workspace` es als
      Migrationspfad für Dateien aus der Zeit vor den Workspaces braucht.

---

## 2026-08-25

### Git & Repo-Hygiene

- [x] **Claude-Branches aufräumen — 26 von 28** (Rest: die zwei jüngeren als
      3 Tage, siehe MERGED.md).

      18 waren vollständig in `main` — ersatzlos gelöscht, lokal wie remote,
      plus vier verwaiste `.claude/worktrees/`-Checkouts.

      Die 8 älteren mit unveröffentlichten Commits wurden nicht weggeworfen,
      sondern eingebaut. `main` war überall 24–52 Commits weiter, also war kein
      einziger ein glatter Cherry-Pick:

      - `replacer.nvim` — vier `*tag*`-Definitionen statt `|tag|`-Referenzen in
        `doc/replacer.txt`. Doppelte Tag-Definitionen brechen `:helptags` und
        damit `:Lazy sync`.
      - `buffer-ctx.nvim` — `:Insert/:Copy date` bekommt dieselbe
        `[format] [--utc]`-Grammatik wie `timestamp`, plus 5 neue Formate.
      - `filetree.nvim` — zwei Commits: `no_name_guard` aus sechs
        Test-Setups heraus (es löschte die Scratch-Buffer, bevor der Test ihre
        Keymaps lesen konnte), und `lua_require_copy` auf
        `lib.nvim.lua_ls.get_module_path` konsolidiert. Die zweite Hälfte des
        ersten Commits wurde verworfen: `main` hatte denselben Bug inzwischen
        präziser gefixt.
      - `markdown.nvim` — zwei Features: `:Markdown links sanitize` +
        Sanitize-on-save, und der Heading-Gap-Checker (`:Markdown gaps`,
        `check_heading_gaps`, `--check-gaps`). Beide Branches hatten ältere
        Fassungen von Config-Block, Subcommand-Tabelle und vimdoc-Kapitel-
        nummerierung, die durch die aktuellen ersetzt wurden.
      - `pickers.nvim` — von 9 Commits war genau einer noch nicht auf `main`:
        die Systemscope suchte unter Windows in `"/"`, also im Root des
        *aktuellen* Laufwerks statt überall, und `pick_dir` in den
        telescope-/snacks-Engines kannte `fdfind` nicht (Debian/Ubuntu). Gegen
        `main`s inzwischen asynchrone `drives.lua` neu implementiert.
      - `mdview.nvim` — vollständig überholt: `main` hat `:MDView blanklines`
        eigenständig gelöst, client-seitig in TypeScript statt in Rust/WASM.
        Übrig blieb eine echte Doku-Lücke: `doc/mdview.txt` kannte das Feature
        als einziges nicht.

      Aufgefallen und mitgenommen: `docs/NOTES/PersonelPlugins/BINDINGS`
      beschrieb drei dieser Features bereits, aber mit Verweis auf Branches, die
      es jetzt nicht mehr gibt — auf "seit 2026-08-25 auf `main`" umgestellt.

- [x] **`gh repo edit` (Description, Topics) pro Repo.**
      Description und Topics waren in allen 31 Repos schon gesetzt; offen war
      die Konsistenz. Basis-Set `neovim` / `neovim-plugin` / `lua` -- die drei
      Topics, über die auf GitHub tatsächlich gesucht wird -- fehlte in sechs
      Repos: `color_my_ascii.nvim`, `dap.nvim`, `language.nvim`,
      `replacer.nvim`, `sessions.nvim` (jeweils `nvim-plugin` statt
      `neovim-plugin`) und `mdview.nvim`. `mdview.nvim` stand bereits auf dem
      GitHub-Maximum von 20 Topics, deshalb ist `local` (als Topic
      bedeutungslos) für `lua` gewichen.

      Nebenbei die Homepage-URLs: `lib.nvim` hat eine Pages-Site
      (stefanbartl.github.io/lib.nvim), war aber nicht verlinkt -- jetzt schon.
      `fileops.nvim` und `spotlight.nvim` zeigten als "Homepage" auf ihre
      eigene GitHub-Seite, was GitHub ohnehin schon tut -- geleert.


- [x] **Branch auf `main` umstellen, wo noch nicht geschehen.**
      Einziges Repo abseits von `main` war `lsp.nvim`
      (`feat/diag-severity-completion-and-autocmd-groups`, ein unveroeffentlichter
      Commit). Fast-forward nach `main` gemergt, gepusht, Feature-Branch geloescht.
      Alle 31 Plugin-Repos stehen jetzt auf `main`.

### Dokumentation & Cheatsheets

- [x] **`docs/FEATURES/` über alle 31 Repos vereinheitlicht — 0 Features ohne
      Metadaten, 0 Repos unsichtbar.**

      Ausgangslage laut Roadmap: „27 von 31 sind Katalog + Bullets, drei ohne
      Bullets, einer ein Changelog". Gemessen mit
      `documentation.core.features.resolve` selbst stimmte davon fast nichts.

      **Neun Repos waren für den Features-Tab komplett unsichtbar.**
      `CANDIDATE_FOLDERS` suchte nur nach einem *Ordner*; `diff`, `emojis`,
      `fileops`, `github_stats`, `lsp`, `migrate`, `recommender`, `sessions`
      und `spotlight` haben je eine einzelne `docs/FEATURES.md` — zusammen 147
      sauber geschriebene Features, alle schon mit Bullets, und `resolve()`
      gab für jedes `nil` zurück. Der Parser liest sie jetzt; der Ordner
      gewinnt weiterhin, wenn beides da ist. `FEATURES_FORMAT.md` sagte selbst
      „one `FEATURES.md` for a small plugin" neben einem Codeblock, der einen
      Ordner zeigt — genau die Mehrdeutigkeit, nach der sich die neun
      gerichtet hatten. Jetzt eindeutig, plus Reihenfolge-Regel: `core.md`
      zuerst, `FEATURES.md` zweitens, Rest alphabetisch (vorher stand
      `ARCHITECTURE.md` über `CORE.md`). Vier neue Spec-Blöcke.

      **Derselbe Befund in sieben Repos: ein Dokument, das `##` für die eigene
      Gliederung benutzt, lag im Features-Ordner** — und jede Überschrift
      darin wurde als Feature gezählt. Das war der Löwenanteil aller
      gemeldeten „fehlenden Bullets", nicht fehlende Bullets:

      | Repo | Was dort lag | Phantom-Features |
      |---|---|---:|
      | `color_my_ascii` | sieben Feature-Handbücher (2649 Zeilen) | 102 |
      | `documentation` | Decision Record, Ecosystem-Essay, Naming-Survey | 72 |
      | `lib` | zwei Problem/Lösung-Essays | 11 |
      | `mdview` | der Überblicksteil der `FEATURES.md` | 5 |
      | `filetree` | Implementierungs-Status `CWD_MODES.md` | 3 |
      | `runtime-analysis` | `FINISHED.md`, das Decision Record | 3 |
      | `language` | `TEMP.md`, eine Phasen-Checkliste | 1 |

      Nichts gelöscht: jedes Dokument behielt seinen Inhalt, bekam einen Kopf,
      der sagt woher es kommt und warum, und alle Verweise darauf sind
      nachgezogen (allein in `documentation.nvim` 24 Stellen in 13 Dateien,
      eine davon in `standalone/vim_shim.lua`; in `lib.nvim` acht, zwei davon
      in Lua-Doc-Kommentaren). Neue Heimat je nach Sorte: `docs/guides/` für
      Langfassungen, `docs/FEATURE_LOG.md` für Decision Records (der Name, den
      `color_my_ascii` schon hatte), `docs/ROADMAP/` für Status- und
      Build-Notizen. In `mdview` ein Split statt eines Umzugs: der Überblick
      wurde zum `README.md` des Ordners — das ist laut Format das Intro und
      wird nie als Thema gelesen —, die elf echten Features blieben in
      `FEATURES.md`.

      **`pickers.nvim` hatte als einziges gar keinen Katalog**, sondern einen
      Feature-Changelog unter `docs/FEATURES.md`. Sieben Themen, 26 Features
      neu geschrieben — aus der Quelle, nicht aus dem Changelog paraphrasiert:
      drei Behauptungen, die der Changelog produziert hätte, haben die
      Quellprüfung nicht überlebt. Der Changelog liegt als `docs/CHANGELOG.md`
      daneben, nach deiner Logik: Rohmaterial behalten, aus dem Weg räumen.

      **Erst danach kam die eigentliche Fleißarbeit**: 16 echte Bullet-Sets in
      neun Repos. Modulpfade aus dem Baum gelesen statt aus der Prosa
      abgeleitet — zwei lagen nicht dort, wo der Text es nahelegte
      (`sandbox`s `.sandboxrc` in `util/project_config.lua` statt in einem
      `engine/`, `runtime-analysis`' bench als `bench.lua` statt `bench/`).

      **Zwei Nebenfunde:** `color_my_ascii`s Features-Ordner war als einziger
      der 31 kleingeschrieben (`docs/features/`) — auf einem case-sensitiven
      Dateisystem unsichtbar für jeden Link, der ihn anders schreibt; und
      dessen `docs/FEATURES.md` war ein Commit-Log ein Zeichen neben dem
      Ordner, der etwas anderes meint.

      **Stand jetzt:** 31 von 31 Repos sichtbar, 842 Features mit 1845
      Metadaten-Bullets, keines ohne.

      **Später, wenn du willst:** Sub-Tabs im Features-Reiter, jede Themendatei
      ein Untermenü. Die Reihenfolge dafür (`core` → `FEATURES` → Rest) ist
      schon gebaut, weil sie zehn Zeilen war. Der Rest ist eine Funktion in
      `html.lua` und kein Parser-Eingriff — Kostenschätzung und die eine offene
      Designfrage (Verhältnis zu `- **Tab:** true`) in
      `documentation.nvim/docs/ROADMAP/IDEAS/FeaturesSubTabs.md`.

### Cross-Plattform

- [x] **Erste Runde: die 45 Windows-Testfälle in `filetree.nvim` — 45 → 0.**
      Der Task bleibt offen (siehe MERGED.md), aber der eingetragene Befund
      ist erledigt, und er war anders begründet als notiert.

      **Die Diagnose im Roadmap-Eintrag war falsch.** Dort stand
      „Erwartungswert-Problem in den Tests". Es war ein Bug in `lib.nvim`:
      `normkey` — der *kanonische* Cache-/Dedup-Schlüssel für einen Pfad —
      gab für denselben Pfad **vor und nach `mkdir` zwei verschiedene
      Schlüssel** zurück. `uv.fs_realpath` scheitert an einem Pfad, den es
      noch nicht gibt, und der Fallback lieferte die Eingabe unverändert.
      Unter Windows ist `$TEMP` die 8.3-Kurzform (`C:/Users/STEFAN~1/…`) für
      jeden Profilnamen über acht Zeichen — also keyte dasselbe Verzeichnis
      vorher kurz und nachher lang. Ein Schlüssel, der sich ändert, sobald
      das Verzeichnis entsteht, ist kein Schlüssel: was vorher darunter
      gecacht wurde, ist danach unauffindbar.

      Gefixt, indem der **nächste existierende Vorfahre** aufgelöst und der
      unauflösbare Rest wieder angehängt wird. Der Lauf stoppt an einer
      echten Wurzel (`//server/share`, `C:/`, `/`), damit ein UNC-Pfad nicht
      zerlegt wird, und ein abschließender Separator wird nicht mehr von
      einem nackten Laufwerk gestrippt (`C:` ist unter Windows *das cwd auf
      Laufwerk C*, nicht die Wurzel — das war eine Regression, die der
      eigene Test gefangen hat). Neue `TESTS/normkey_spec.lua`, 20 Fälle.

      **Allein das brachte `filetree.nvim` von 45 auf 4 Fehler.** Keine
      Testdatei angefasst — die Tests hatten recht.

      **Die restlichen 4 waren zwei verschiedene Dinge.** Zwei echte:
      `find_files`' builtin-Backend fand in einem Verzeichnis voller Dateien
      nichts. Grund: `vim.fn.glob`/`globpath` lesen ihr Argument als
      **Pattern**, und ein `~` darin ist eine Home-Verzeichnis-Referenz.
      Unter `C:/Users/STEFAN~1/…` versucht glob, `~1` als Benutzer
      aufzulösen, findet keinen — und gibt eine **leere Liste** zurück, ohne
      Fehler und ohne Warnung. Direkt nachgemessen: derselbe Baum globt
      unter dem Langpfad zu 2 Einträgen, unter dem Kurzpfad zu 0. Der Nutzer
      sah „No files found in: …", was schlicht nicht stimmte. Die anderen
      zwei waren tatsächlich Erwartungswerte (`TMP_ROOT` aus dem rohen
      `$TEMP` zusammengebaut, gegen ein aufgelöstes `getcwd()` verglichen) —
      kanonisiert.

      **Dieselbe Bug-Klasse noch zweimal gefunden**, beide unabhängig von
      filetree:

      - `pdfport.nvim/backends/marker.lua`: `tempname()`-Verzeichnis, zwei
        `glob`-Aufrufe. Der Recovery-Suchlauf nach der erzeugten `.md` fand
        sie nie, wenn sie nicht am geratenen Pfad lag — und die
        Fehlermeldung listete den Verzeichnisinhalt durch denselben glob,
        sagte also „Present:" und nichts, für ein nicht-leeres Verzeichnis.
      - `sessions.nvim/config`: die %TEMP%-Blacklist ist ein reiner
        Präfix-Vergleich gegen den Buffernamen und kannte nur die
        `$TEMP`-Schreibweise. Ein Buffer, der über einen aufgelösten Pfad
        geöffnet wurde — was `fs_realpath`, ein LSP oder ein Picker liefert
        — trug die Langform und wurde **nicht** geblacklistet: Scratch-Files
        unter %TEMP% landeten in der Session-Datei. Headless verifiziert
        (`:edit` auf den Langpfad → nicht geblacklistet). Beide
        Schreibweisen registriert, je mit eigener Separator-Form; dazu ein
        Default-Eintrag repariert, der Vorwärts- und Rückwärts-Slash mischte
        (`C:/Users/…/Temp\`) und damit auf gar nichts passen konnte.

      Alle vier Suites von `filetree.nvim` sind unter Windows grün, `lib.nvim`
      (inkl. der neuen Spec), `sessions.nvim` und `pdfport.nvim` ebenfalls.

      **Nebenbefund, nicht cross-platform und daher nicht hier gefixt:**
      `filetree.nvim/TESTS/refs/` hat 2 von 54 Fällen rot
      (`nested/deep/c.lua` wird beim Rename nicht mitgezogen, `nested/b.lua`
      schon). Reproduziert vor und nach dieser Änderung identisch, und auch
      ohne ripgrep — also weder eine Regression noch ein Pfad-Problem. In
      `filetree.nvim`s eigener Roadmap eingetragen.

- [x] **Zweite Runde: die konditionalen `glob`-Aufrufstellen und die
      Shell-Aufrufe — beides abgearbeitet.** Damit ist der Task zu.

      **Zehn Aufrufstellen, aber kein elftes Helferlein.** Der Eintrag in
      MERGED.md sagte „Fix ist jeweils zweizeilig". Stimmt — nur wären das
      dann fünf bis sechs private Kopien derselben vier Zeilen gewesen,
      `filetree` und `pdfport` hatten schon je eine. Stattdessen neu:
      **`lib.nvim.fs.globbable`** (Modul + README + `@types` + Spec, im
      Hausstil ein Verzeichnis pro Funktion), und jede der Stellen
      verbraucht es. `filetree`s private Kopie ist migriert und gelöscht.
      Die Spec-Zusicherung, die zählt, prüft nicht den Rückgabewert: sie
      globt einen echten Baum und vergleicht die Trefferzahl — das ist die
      Behauptung, die den Originalbug gefangen hätte.

      Verbraucher: `insights.nvim` (5 — Import-Glob-Fallback ohne ripgrep,
      Metrics-Datei-Lister, die drei Treesitter-Symbol-Scanner),
      `markdown.nvim` (4 — beide `links`-cwd-Scopes, `file_refs`'
      Pure-Lua-Fallback, `md_files.collect`), `recommender.nvim` (1),
      `buffer-ctx.nvim` (1).

      **Eine Stelle war nicht zweizeilig.** `insights`'
      `analyzer.list_files` schneidet `#dir` Bytes von jedem Treffer ab, um
      den Relativpfad für die Ignore-Prüfung zu bekommen. Nur den
      glob-Aufruf zu tauschen hätte jeden Relativpfad um die Differenz
      zwischen Kurz- und Langform verschoben — also einen neuen Bug
      eingebaut. `dir` wird jetzt einmal umgebunden.

      **Die Shell-Runde brachte einen Befund, den ich nicht erwartet
      hatte.** Unter Windows startet `lib.nvim.cross.run` `powershell
      -Command`, und dort ist `>` ein Alias für `Out-File` — dessen Default
      **UTF-16LE mit BOM** ist. Nachgemessen, nicht vermutet:

          powershell -Command "'hello' > f.txt"  ->  ff fe 68 00 65 00 …

      `:Insights tree` schrieb seine Dateiliste also als Wide Chars, und
      `compress`' `file-list.txt` ebenso — während dieselbe Ausgabe über die
      Unix-Engines (`sh`) sauberes UTF-8 wurde. Beide holen die Liste jetzt
      aus stdout und schreiben sie aus Lua: eine Kodierung auf jeder
      Plattform, kein Quoting pro Shell. `-Encoding utf8` wäre die kleinere
      Änderung gewesen, tauscht aber nur das UTF-16-BOM gegen ein UTF-8-BOM.
      `write_tree` verliert dabei noch ein `shellescape`, das für `cmd.exe`
      quotete, während das Kommando drumherum für PowerShell quotete.

      **Und dahinter lag ein zweiter, älterer Bug:** `platform.run_shell`
      reichte den Callback direkt aus `vim.system` durch, also im *fast
      event context*, wo `vim.fn.*` und `vim.notify` mit „must not be called
      in a fast event context" abbrechen. Jeder Verbraucher endet in einem
      Notify. Jetzt wird einmal zentral gescheduled, statt dass sich jeder
      Aufrufer daran erinnern muss.

      **Zwei `io.popen`-Shell-Strings auf argv umgestellt.**
      `github_stats`' Curl-Versionsprüfung trug deswegen einen
      Plattform-Zweig (`2>nul` gegen `2>&1`), um stderr zu unterdrücken, das
      `curl --version` gar nicht schreibt — argv braucht den Zweig nicht.
      `replacer`s rg-Smoke-Test hatte als Pre-`vim.system`-Fallback eine
      POSIX-Pipeline (`echo test | rg … 2>&1`), die unter `cmd.exe` ein
      anderes Kommando ist: `echo test |` speist dort „test " mitsamt dem
      Leerzeichen vor der Pipe.

      **Als korrekt bestätigt und bewusst nicht angefasst:**
      `lib.nvim/system/info.lua` und `gopath/truncated/cache.lua` (bewusst
      POSIX, sauber verzweigt), `cmdlog`s fzf-Previewer (gibt unter Windows
      `nil` zurück, statt ein kaputtes Kommando zu emittieren — inklusive
      Begründung im Modulkopf), `insights compress`' Engine-Auswahl
      (tar/zip gegen `Compress-Archive`), `pickers`' fzf-Kommandostrings
      (`fd`/`rg` sind plattformübergreifend, `shellescape` quotet für
      dieselbe `&shell`, die fzf-lua benutzt), `pdfport`s Terminal-Renderer.

      Suites grün: `lib.nvim` (inkl. neuer Spec), `insights.nvim`,
      `markdown.nvim`, `recommender.nvim`, `buffer-ctx.nvim`,
      `filetree.nvim` (alle drei), `replacer.nvim`. `tree` und
      `file-list.txt` unter Windows end-to-end nachgemessen: beide kommen
      als reines UTF-8 mit den richtigen Zeilenzahlen zurück.

      **Nebenbefund:** `markdown`s `md_files` rief `globbable` in einem
      Zwischenstand ohne `require` auf — luacheck hat es gefangen, die Tests
      nicht, weil keiner davon `M.collect` erreicht.

### Security

- [x] **Erste Runde: drei Klassen, jede mit reproduziertem Befund.** Der Task
      bleibt offen (siehe MERGED.md) — was hier steht, ist abgeschlossen.

      **1. Ausführung beim *Preview* (`cmdlog.nvim`).** Beide Previewer
      führten den Eintrag unter dem Cursor aus. Mit dem Cursor an
      `:!rm -rf build` vorbeizugehen hat es ausgeführt; an
      `:lua vim.fn.delete(x)` hat es ausgewertet; an `:term <cmd>` hat es
      gespawnt. Nachgestellt, nicht vermutet: ein
      `:lua vim.fn.writefile(…)`-Eintrag hat seine Datei allein durch das
      Preview geschrieben.

      Das ist für sich schon falsch — Previewen ist Blättern —, aber die
      Einträge sind nicht mal zwingend die eigenen: `extra_files` faltet
      beliebige Textdateien als History-Quelle ein, Shell-History ebenso.
      „Ist ja nur, was du selbst mal ausgeführt hast" hält also nicht.

      Der `:help`-Zweig war zusätzlich eine **Vim-Command-Injection**: das
      Topic ging ungeprüft in einen `-c`-String, wo `|` einen neuen Befehl
      beginnt — `:help x | call writefile(…)` hat das `writefile`
      ausgeführt, ebenso nachgestellt. Auf der fzf-Seite gingen Topic *und*
      der ganze `:lua`-Ausdruck ungeescaped zusätzlich in einen **Shell**-String.

      Neu: `cmdlog.ui.preview_policy` hält die Entscheidung, die beide
      Previewer inline getroffen und beide gleich falsch beantwortet haben —
      ein Preview liest, es führt nicht aus. `:edit <file>` braucht kein
      Gate. Alles Ausführende braucht `preview_execute = true` (neu, default
      false) und wird selbst dann für einen Eintrag aus `risky_patterns`
      verweigert. Zwei Argument-Prüfungen statt einer: ein Filter, der streng
      genug für ein Shell-Wort ist, verwirft `vim.fn.getcwd()` wegen der
      Klammern — das schaltet das Feature ab, statt es abzusichern. 11 Tests,
      beide Repros darunter.

      **2. Credentials in `argv` (`lib.nvim.net.curl`, `reposcope.nvim`).**
      `bearer_token` wurde zu `-H "Authorization: Bearer …"` in der
      Kommandozeile, `auth` zu `-u user:pass`. Die Kommandozeile eines
      Prozesses ist für jeden anderen Prozess lesbar. Nachgemessen, während
      der Request lief:

          curl.EXE -sS -H "Authorization: Bearer SECRET_IN_ARGV_123" …

      Beides geht jetzt in eine curl-Config über stdin (`-K -`) — curls
      eigene Antwort auf genau das. Jeder `headers`-Eintrag namens
      `Authorization`, `Proxy-Authorization` oder `Cookie` ebenso. Dieselbe
      Messung danach zeigt nur noch `curl.EXE -K - -sS -X GET -i <url>`.
      `spawn_capture` hat dafür `stdin` bekommen (das war der Blocker für
      reposcope, das eine eigene Request-Tool-Schicht hat). Im
      `curl_spec.lua` gegen den vorhandenen mitschneidenden Server
      abgesichert: Header kommt auf der Leitung an, Plain-Header unberührt.

      **Nicht abgedeckt und so dokumentiert:** `body` steht weiterhin als
      `-d <body>` in argv. Ein Body lässt sich nicht als Config-Wert
      ausdrücken (ein echter Zeilenumbruch beendet die Option), und stdin ist
      jetzt belegt.

      **3. Credentials in Log, `:messages` und auf Platte (`reposcope`).**
      Die Debug-Zeile des curl-Tools druckte das komplette Kommando samt
      Authorization-Header — und `:messages` ist das Erste, was in einen
      Bugreport kopiert wird. Schlimmer das gh-Tool: es hängte den vollen
      argv bei **jedem** Request an
      `stdpath("cache")/reposcope/logs/gh-debug.txt` an, nicht nur im
      Debug-Modus, womit die Datei auch unbegrenzt wuchs. gh authentifiziert
      normalerweise über `GITHUB_TOKEN` in der Umgebung, aber `headers` ist
      aufrufer-geliefert. Beides redigiert, das Datei-Log zusätzlich hinter
      `debug` gehängt.

      **Dazu, als Härtung ohne belegten Exploit:** `owner`/`repo_name` aus
      der API-Antwort wurden in `readme_cache` direkt zu einem Dateipfad
      verkettet. Kein echter GitHub-Name enthält einen Separator — aber „das
      schickt der Server schon nicht" ist die falsche Annahme für ein
      Cache-Verzeichnis, und der Provider-Host ist konfigurierbar.
      Segment-Sanitisierung; gewöhnliche Namen bleiben unverändert, damit
      bestehende Cache-Einträge ihre Dateinamen behalten.

      **Als korrekt bestätigt:** `runtime-analysis`' `-k`/`--insecure` steht
      in einer Liste von Flags, die aus *nutzergelieferten* curl-Argumenten
      **entfernt** werden — genau andersherum als es aussieht. `cmdlog`s
      `redact_patterns` (kein Token in History/Stats/Error-Log) und
      `sessions`' %TEMP%-Blacklist sind bereits richtig. `github_stats`'
      Debug-Ausgabe nennt nur die Token-Länge, nie den Wert.

      CI grün: `cmdlog.nvim`, `lib.nvim`, `reposcope.nvim`.


- [x] **Zweite Runde: die restlichen Klassen — Task damit zu.** Drei weitere
      echte Befunde, jeder vor dem Fix reproduziert und danach gegengeprüft.

      **1. Backtick-Expansion: Command Execution aus einem Markdown-Link.**
      Der schwerste der ganzen Runde. `vim.fn.expand()` ist Vims
      *Dateinamen*-Expansion, und ein Backtick-Span in ihrem Argument ist eine
      **Kommando-Substitution** über `&shell`. Zuerst am Mechanismus selbst
      belegt: `vim.fn.expand("`echo X`")` gibt `"X "` zurück — die Shell lief.

      Und genau dort landete Link-Text aus dem Buffer:
      `markdown.util.path`s vier Resolver und `images.resolve.to_path`. Mit
      echtem Payload nachgestellt —

          ![x](`mkdir -p /tmp/pwned; echo a.png#`)

      — und das Verzeichnis entstand. Das `#` am Ende ist der Trick: `is_image`
      matcht in seiner zweiten Alternative eine Endung *irgendwo* vor `?`/`#`,
      also darf das `.png` **innerhalb** der Backticks stehen, während der
      String als Ganzes für Vim ein einziger Span bleibt — und nur diese Form
      expandiert Vim (ein Suffix nach dem schließenden Backtick unterdrückt es,
      was ich beim ersten Versuch erst falsch hatte).

      Gewollt war hier nur `~` und Umgebungsvariablen, also
      `lib.nvim.cross.fs.expand_path`: kein Shell, kein Globbing, keine
      `%`/`#`/`<cfile>`-Specials. Beide Repos gefixt — markdown ist der
      Resolver, an den images zuerst delegiert, also hätten beide gemusst. Der
      Test sichert beide Hälften: dass der Payload weiterhin an `is_image`
      vorbeikommt (das Gate ist *nicht* der Fix) und dass beim Auflösen nichts
      läuft.

      **2. AppleScript-Quoting in `filetree`s Trash.** Der macOS-Fallback
      bettet den Pfad in ein AppleScript-String-Literal und escapte nur `"`.
      AppleScript escapt aber mit `\` wie C — ein Pfad, der auf einen
      Backslash endet, kam als `\\"` heraus: ein literaler Backslash und
      dann ein Quote, das den String vorzeitig schließt. Alles danach ist
      AppleScript-Quelltext, und `do shell script` ist ein Wort entfernt:

          /tmp/a\" & (do shell script "id") & "

      Beide Zeichen sind in einem macOS-Dateinamen erlaubt — ein präparierter
      Name in einem geklonten Repo plus ein `d` im Tree reicht. Backslash
      zuerst escapen fixt es. Ehrlich gesagt: durchdacht und unit-getestet,
      nicht gegen einen echten Finder gelaufen, weil diese Maschine Windows
      ist. Der Windows-Zweig war schon korrekt (PowerShell verdoppelt `'`).

      **3. Symlink-Escape aus mdviews Relay.** `/asset` und `/preview`
      begrenzten den Request per `filepath.Clean` plus Prefix-Check auf das
      Dokumentverzeichnis. Das ist rein lexikalisch, und `ServeFile`/`os.Open`
      folgen Symlinks ungefragt — ein Symlink *im* Verzeichnis liegt
      lexikalisch drin und zeigt wohin er will. Ein geklontes Repo mit
      `logo.png -> ~/.ssh/id_rsa` bekam das ausgeliefert, vorbei am
      Token-Check und vorbei an der Endungs-Allowlist, die nur den
      *angefragten* Namen ansieht.

      Beide Richtungen bewiesen, in WSL (Symlinks brauchen unter Windows ein
      Privileg, das eine normale Shell nicht hat): vor dem Fix
      `got 200: SECRET-CONTENTS`, danach 403. Der lexikalische Check bleibt —
      er stoppt `../..` —, dazu ein aufgelöster. Das Verzeichnis wird
      mitaufgelöst, sonst würde ein macOS-Temp-Dir unter dem symlinkten `/var`
      völlig normale Pfade ablehnen. Ein nicht auflösbarer Pfad bleibt beim
      lexikalischen Check allein: die Datei existiert nicht, es wird nichts
      gelesen, und 404 ist die richtige Antwort — ein Test hält das fest,
      sonst wäre jeder vertippte Bildpfad zu „path escapes document
      directory" geworden.

      **Zwei Klassen geprüft und sauber:**

      - **Vorhersagbare Temp-Dateien.** Kein `os.tmpname()`, kein Schreiben
        nach `/tmp` irgendwo. Alles geht über `vim.fn.tempname()` (Neovim legt
        pro Prozess ein eigenes Verzeichnis an) oder `stdpath("cache")`.
        `pdfport`s soffice-Producer baut `stdpath("cache")/…/soffice-<hrtime>` —
        im eigenen Cache, also kein Symlink-Race über Nutzergrenzen.
      - **Secrets in persistierten Stores.** Kein Token erreicht Storage,
        Export, Cache oder State-Layer; `reposcope`s Metrics halten URL und
        Status, nie Header. `cmdlog`s `redact_patterns` greifen in `tracker.lua`
        und decken damit genau die drei *automatischen* Senken ab (Project
        History, Stats, Error-Log). Favorites/Tags/Notes sind bewusst nicht
        redigiert — das ist eine explizite Nutzerhandlung an genau einem
        Befehl, kein stilles Mitschreiben; die DEFAULTS-Doku sagt es auch so.

      CI grün: `images.nvim`, `markdown.nvim`, `filetree.nvim`, `mdview.nvim`.

      **Was eine dritte Runde ansehen würde** (nicht offen im Sinne von
      bekannt-kaputt, sondern schlicht nicht angefasst): der Rust/WASM-Renderer
      und die ammonia-Allowlist, die WebTransport-Zertifikats-Pinning-Pfade,
      und die Frage, was der Client-Bundle im Browser-Tab an externen Requests
      auslösen kann (ein feindliches README kann externe Bilder referenzieren —
      das leakt „wurde angesehen", keine Inhalte, aber ich habe es nicht
      systematisch durchgespielt).


### Performance

- [x] **Startup: ~1300ms → ~990ms (−24%), eager geladene Plugins 44 → 29.**
      Der Task bleibt offen (siehe MERGED.md), aber diese Runde ist fertig —
      und sie ist gemessen, nicht geraten.

      **Erst messen.** `--startuptime` über fünf Läufe: Median ~1300ms. Die
      Config bringt ihr eigenes Phasen-System mit, also `:StartupReport` bzw.
      `require("startup").slowest()` — das sagte: die erste Phase startet erst
      bei **694ms**. Alles davor ist lazy.nvim. `require("lazy").stats()`
      dazu: **114 Plugins, 44 davon beim Start geladen**, `LazyDone` bei
      660ms.

      Wer davon, und warum — `lazy.core.config.plugins[..]._.loaded` trägt
      den Grund mit. Nach Zeit sortiert standen ganz oben:
      **neo-tree 243ms** (`lazy = false`) und **neotest 227ms**, letzteres
      mit dem Grund `{ plugin = "neo-tree.nvim" }` — also nur geladen, weil es
      Dependency des Ersten ist. Dahinter dessen acht Adapter, treesitter,
      devicons, nui, plenary, vim-test und FixCursorHold.

      **Der erste Versuch war falsch, und das ist der interessante Teil.**
      Naheliegend war, `"nvim-neotest/neotest"` aus neo-trees `dependencies`
      zu streichen — neotest hat ja eine eigene, korrekt lazy Spec mit `cmd`.
      Gemessen: 1300 → 1130ms, 44 → 33 Plugins. Nur ist es eine Regression:
      `:Neotree tests` stirbt danach an einem nil-Consumer, weil die
      tests-Source ihre Items über einen **neotest-Consumer** baut, der bei
      neotests `setup()` registriert werden muss. Gegenprobe auf dem
      Originalstand — dort geht es. Also zurückgenommen. Die Dependency ist
      nicht überflüssig, sie ist die Reihenfolge-Garantie.

      **Der richtige Hebel war neo-tree selbst.** `cmd = "Neotree"` plus ein
      `init`, das genau den Fall abfängt, für den `lazy = false` eigentlich da
      war: ein Verzeichnis-Argument (`nvim <dir>`) soll den Tree öffnen statt
      netrw. Die Dependency bleibt — lazy lädt Dependencies gemeinsam mit dem
      Parent, die Reihenfolge stimmt also weiterhin, nur eben später.

      Vier Verhaltensproben, alle grün: neo-tree beim Start **nicht** geladen,
      `:Neotree` lädt es nach, `:Neotree tests` baut seinen Buffer, und
      `nvim <dir>` öffnet den filesystem-Tree mit filetype `neo-tree`.

      **Was die Messung sonst noch ergeben hat** (offen, steht mit Zahlen in
      MERGED.md): die `lsp`-Phase ist mit ~288ms jetzt der mit Abstand größte
      Einzelposten — davon `build_capabilities` **84ms**, das `blink.cmp` beim
      Start hochzieht, nur um dessen Capability-Tabelle zu lesen, und
      `languages` **66ms**. Dafür habe ich `lsp.nvim`s `step()`-Helfer
      temporär mit Zeitmessung versehen und danach sauber zurückgesetzt.

      `trouble.nvim` (79ms) plus das von ihm gezogene `nvim-web-devicons`
      (71ms) wären der nächste Brocken, aber dessen `lazy = false` steht in
      `lsp.nvim` **mit Begründung** (`]w`/`[w` auf eine bereits offene Liste).
      Die wirkt zu vorsichtig — `cmd` plus Require-Hook dürfte beides
      abdecken —, aber eine dokumentierte fremde Entscheidung stoße ich nicht
      im Vorbeigehen um.

- [x] **Zweite Runde: options und trouble. Zusammen ~1050ms → ~942ms.**

      **`options.lua`: 63ms → 17ms, und der Befund ist allgemeiner als die
      Datei.** Zwei Drittel der Zeit steckten in genau einem Aufruf:
      `vim.fn.executable("pwsh")` auf einer Maschine ohne PowerShell 7.

      Ein *fehlschlagendes* `executable()` läuft unter Windows jeden
      PATH-Eintrag gegen jede PATHEXT-Endung ab — hier 67 × 11 = **737 Stats,
      ~44ms** — und `vim.fn` cacht das Ergebnis **nicht**, zweimal probieren
      kostet zweimal. Ein *erfolgreiches* stoppt beim ersten Treffer (~0.2ms),
      weshalb `powershell` im Profil gar nicht auftauchte. Das gilt config-weit
      für jede Probe auf ein nicht installiertes Tool im Startpfad.

      Beide PowerShell-Zweige wollten byte-identische Optionen bis auf den
      Binary-Namen, also fallen sie in eine Funktion zusammen: das immer
      vorhandene Windows PowerShell 5.1 wird synchron gesetzt, die
      pwsh-Bevorzugung passiert auf dem nächsten Event-Loop-Tick. Genau *weil*
      der Unterschied eine Option ist, ist das sicher — die Shell ist fertig
      konfiguriert, bevor die Probe läuft, und wer vorher shellt, bekommt 5.1:
      eine ältere Version, kein anderes Verhalten. Beide Richtungen verifiziert
      (ohne pwsh bleibt `powershell.exe` und ein echter `system()`-Roundtrip
      geht durch; mit einem auf den PATH geschobenen pwsh-Shim greift das
      Upgrade und `o.shell` wird `pwsh.exe`).

      **`trouble.nvim`: die dokumentierte Begründung hatte recht in der
      Prämisse und unrecht im Schluss.** `]w`/`[w` bewegen sich in einer
      *bereits offenen* Liste, lösen also kein `cmd` aus — stimmt. Nur
      brauchten sie das Plugin nie geladen, um korrekt zu antworten:
      `trouble_move` fragt jetzt zuerst `package.loaded["trouble"]`, und wenn
      Trouble nie geladen wurde, kann keine seiner Listen offen sein. Dieselbe
      Notify, ohne das Plugin dafür hochzuziehen. Das ist für sich schon
      besser und macht `cmd = "Trouble"` erst richtig.

      Vier Proben: beim Start nicht geladen; `]w` ohne Liste notified und lässt
      es ungeladen; `:Trouble diagnostics open` lädt und funktioniert; `]w`
      gegen eine Liste mit echten Diagnostics bewegt statt zu notifien — für
      Letzteres mussten erst Diagnostics gesetzt werden, weil eine leere
      Session nichts zu öffnen hat und der Test sonst aus dem falschen Grund
      durchgeht.

      **Nebenbefund, bewusst nicht angefasst:** der WORKSTATION-FREEZE-FIX in
      `options.lua` (PSModulePath von OneDrive-Pfaden befreien) ist
      auskommentiert. Der Kommentar dort beschreibt einen 60-90s-Freeze, an dem
      er hing. Entweder nicht mehr nötig oder versehentlich deaktiviert — das
      ist eine Entscheidung für den Autor, nicht für mich.


- [x] **`:Recommender perf` ausgewertet — und das Ergebnis war ein Fix am
      Analyzer, nicht an der Config.**

      Über alle 353 Lua-Dateien der Config: **398 Funde**, verteilt als
      353× `ipairs`, 28× `table.insert`, 14× `string.format` — und **3×
      Concat-Akkumulator**, die einzige Kategorie mit *algorithmischem*
      Gewicht (O(n²)) statt eines konstanten Faktors.

      **Alle drei waren False Positives**, in zwei Formen:

      - Zweimal ein `local`, das *innerhalb* der Schleife neu deklariert wird:
        `local ident = ts_identifier_of(u)` … `ident = ident .. "()"`. `ident`
        startet jede Iteration frisch, das ist ein 2-Zeichen-Suffix auf einem
        neuen String, kein Akkumulator.
      - Einmal ein Tabellenfeld, das eine gleichnamige *äußere* Variable liest:
        `{ short = short, dir = dir .. "/" .. short }`. Die ungeankerte
        Rückreferenz las den Schlüssel als Zuweisungsziel.

      Also in `recommender.nvim` gefixt: der Block-Tracker führt jetzt die pro
      Frame deklarierten `local`-Namen mit, und der Match ist an den
      Zeilenanfang geankert. Vier Regressionsfälle, beide Richtungen — ein
      außerhalb deklarierter Akkumulator wird weiterhin gefunden, auch aus
      einer verschachtelten Schleife heraus. Danach: 395 Funde, die
      O(n²)-Kategorie leer. Das ist die nützliche Antwort, weil es die
      Kategorie ist, auf die man zuerst reagieren würde.

      **Die restlichen 395 bewusst nicht angefasst.** Das sind konstante
      Faktoren (`ipairs` ~2x, `table.insert` ~4-5x, `string.format` ~3x — laut
      den Benchmarks des Analyzers selbst), und 2x von Nanosekunden lohnt nur
      in einer Schleife, die oft genug läuft. Der einzige wirklich heiße Pfad
      der Config ist die Statusline, also gemessen statt vermutet:
      `nvim_eval_statusline` 200×, **6,70 ms → 0,033 ms pro Redraw**. Selbst
      bei 100 Redraws/Sekunde sind das 0,3 % eines Kerns. Dort ist nichts zu
      holen, und 353 `ipairs`-Schleifen in numerische umzuschreiben würde
      Lesbarkeit gegen Unmessbares tauschen.


- [x] **FFI/C-Kandidaten: keiner, der es rechtfertigt** — mit Messwerten statt
      Bauchgefühl. Ausführlich in `docs/NOTES/ffi-c-candidates.md`.

      Der Punkt, der die halbe Frage beantwortet: **`ffi` macht Lua-Code nicht
      schneller.** Es erlaubt Lua, C zu rufen. Ein Gewinn entsteht nur, wenn man
      einen Algorithmus nach C verschiebt und ein kompiliertes Artefakt
      ausliefert — mit Build-Schritt, Artefakten pro Plattform und
      Release-Pipeline. `mdview.nvim` zahlt diesen Preis (Go + Rust/WASM), der
      Preis ist also bekannt; die Frage ist nur, ob ihn sonst irgendwo eine
      vergleichbare Rechenlast rechtfertigt.

      - **Startup: nein.** Gemessen: die Zeit geht an Plugin-Laden (Datei-I/O +
        Lua-Parsing, beides Neovims eigenes C) und Prozess-Spawns. Die drei
        Fixes dieser Runde bestätigen es von der anderen Seite — alle drei
        *vermeiden* Arbeit, keiner musste schneller rechnen.
      - **Runtime-Analysis: nein, und FFI wäre kontraproduktiv.** Die Telemetrie
        erhöht pro Aufruf einen Zähler in einer Lua-Tabelle. Ein Übergang über
        die Lua/C-Grenze kostet mehr als ein Increment, das LuaJIT wegoptimiert.
      - **Docmap: der einzige Ort mit echter CPU-Last — und trotzdem nein.**
        Gemessen an `documentation.nvim` selbst (135 Dateien, 2,0 MB): Lesen
        **17,8 ms**, Lesen + volles Treesitter-Parsing **193 ms**, kompletter
        `gen_map` **4133 ms**. Also ~0,2 s I/O und Parsing, **~3,9 s
        Lua-Arbeit**. Aber: es ist eine CI-/manuelle Operation, „FFI
        hinzufügen" gibt es dort nicht (der IR-Builder *ist* der Kern), und vor
        einem C-Port kommt ein Profil — 2 ms/KB kann nah am Möglichen liegen
        oder ein O(n²) verstecken, und das ist nicht gemessen.

      Die Notiz hält außerdem fest, **wann man die Antwort neu stellen sollte**
      (interaktiv + gemessen CPU-gebunden + abgeschlossen genug für eine
      C-Signatur) und die sechs Zwischenschritte, die vor FFI kommen — mit dem
      häufigsten Fehler an Position drei: vorhandenes C nachbauen, statt
      `vim.treesitter`/`vim.diff`/`vim.json`/`vim.uv` zu benutzen.


- [x] **Feature-Liste für `filetree.nvim` — die zwei fehlenden Quellen
      nachgeholt.** `filetree.nvim/docs/ROADMAP/NEOTREE_FEATURES.md` gab es
      schon (192 Zeilen, zwei Durchgänge), aber der Task nennt **drei** Quellen:
      Neo-tree, NvimTree, Netrw. Die letzten beiden kamen dort nur als
      *Adapter-Ziele* vor, nie als Feature-Quelle. Pass 3 liest sie als Quelle.

      Nicht aus dem Gedächtnis: gegen nvim-trees echte Action-Oberfläche
      (`lua/nvim-tree/actions/*/`, also genau die Menge dessen, worum man es
      bitten kann) und Netrws Kommandosatz, gemappt auf
      `lua/filetree/features/*/`. Das Meiste ist bereits abgedeckt — die
      Mapping-Tabelle hält das fest, damit der nächste Leser den Vergleich
      nicht wiederholt.

      **Drei Lücken**, jede am Baum belegt statt vermutet: Sibling-Navigation
      (`tree_traverse`s `up()`/`down()` wechseln die *Wurzel*, es gibt keinen
      Zug auf derselben Ebene; `grep -ri sibling` ist leer), Collapse-All, und
      Sort-Cycling nach Name/Größe/mtime. Die letzten beiden sind vermutlich
      Adapter-Methoden statt Features — jedes Backend kann das nativ.

      **Drei bewusst keine Lücke**, mit Begründung: der Hidden-Toggle ist in
      `infra/ignore_list` absichtlich an den Adapter delegiert und dort
      dokumentiert (zwei Schalter für ein Verhalten wäre schlechter), Netrws
      Remote-Editing ist Transport statt Verwaltung, und dessen Listing-Styles
      gehören zum Rendering des Adapters.


- [x] **Ersetzbare Fremd-Dependencies analysiert** —
      `docs/NOTES/replaceable-dependencies.md`. Ermittelt aus den echten
      `require("<fremd>…")`-Stellen in allen Repos, nicht aus den
      Spec-Deklarationen: eine deklarierte Dependency, die nie gerufen wird,
      ist ein anderes Problem.

      **Das Beispiel aus dem Task hat eine klare Antwort: `nvzone/menu` ist
      ersetzbar, heute.** `lib.nvim.ui.kit.menu` existiert bereits — eine
      cursor-verankerte Aktionsliste auf `ui.kit.chooser`, mit derselben
      Navigation wie nvzone und zusätzlich `ui.kit`s Theme-Engine, getestet in
      `ui_kit_spec.lua`. Was fehlt, ist nicht das Rendern, sondern die Brücke:
      `lib.nvim.contextmenu` baut die Einträge und bindet den Maus-Trigger,
      rendert aber weiter über nvzone — dieses eine `require("menu")` ist die
      letzte Stelle. Vorschlag: ein Renderer-Schalter mit Default `"auto"`;
      die beiden Konsumenten (filetree, github_stats) ändern sich **gar
      nicht**, weil sie nur `contextmenu.entry`/`group` benutzen. Vorher zu
      klären: kann `ui.kit.menu` verschachtelte Submenüs? 47 Zeilen, die an
      den Chooser delegieren, sehen nach *flach* aus — das wäre der einzige
      echte Implementierungsaufwand.

      **Zweiter Fund: `nvim-treesitter` in `debugging.nvim`/`gopath.nvim`** ist
      zur Laufzeit vermutlich verzichtbar. Parsen und Queries sind seit 0.9/0.10
      im Core (`vim.treesitter`); das Plugin ist im Wesentlichen noch
      Parser-Installer.

      **Grenzfall `lualine`** (filetree, sandbox): diese Config hat eine eigene
      Statusline *und* `lib.nvim` bringt ein `ui/statusline` mit — zwei Systeme,
      die niemand gewählt hat. Vor einem Urteil ist zu klären, was die beiden
      Plugins von lualine überhaupt wollen. Als nächster Schritt notiert.

      **Bewusst nein:** `telescope`/`fzf-lua`/`snacks` (ein Fuzzy-Picker ist ein
      Teilsystem, und `pickers.nvim` *ist* bereits die Abstraktion, die sie
      austauschbar macht), `cmp`/`blink`, `noice`. `trouble` ist optional und
      `pcall`-geschützt, kostet also nichts, wenn es fehlt.


- [x] **vimdoc pro Plugin — war bereits erledigt, mit einem Defekt.** Alle 31
      Repos haben `doc/*.txt`, und zwar substanziell: 189 bis 1536 Zeilen, 13
      bis 101 Tags. `lib.nvim` ist auf 17 Dateien nach Themen aufgeteilt
      (`lib.nvim-fs.txt`, `-kit`, `-composer`, …).

      Gefunden und behoben: **`cmdlog.nvim` fehlte die
      `vim:tw=78:ts=8:ft=help:norl:`-Modeline** als einziges Repo. `:help`
      funktionierte trotzdem — deshalb fiel es nicht auf —, aber `doc/cmdlog.txt`
      direkt zu öffnen gab einen Plaintext-Buffer statt eines Help-Buffers: keine
      versteckten Tags, kein `<C-]>` auf eine Tag-Referenz.

      Kein Defekt, obwohl es so aussieht: 18 Repos haben kein `doc/tags`. Die
      Datei ist gitignored und wird von lazy.nvim beim Install/Update erzeugt.


- [x] **`lib.nvim.selection` bei Visual-Mode-Mappings — bereits erfüllt.**
      Geprüft über alle 31 Repos, und die Antwort ist enger, als der Task
      vermuten lässt.

      Das Modul löst genau einen Fall: ein Mapping, das **den Buffer verändert**
      und danach die Selektion behalten soll (Neovim wirft sie weg, sobald die
      gemappte Funktion zurückkehrt). Ein Mapping, das die Selektion nur
      *liest*, braucht es nicht.

      **`cascade.nvim` ist das einzige Plugin mit buffer-verändernden
      Visual-Mappings** — 13 davon (Bullets/Checkboxen togglen, sortieren,
      umkehren, ein-/ausrücken, Zeilen verschieben) — und es nutzt
      `lib.nvim.selection` bereits: `cascade.util.lib` ist eine
      `pcall`-geschützte Brücke mit eigenständigem Fallback, und `init.lua`
      ruft `keep_lines`, `reselect_chars` und `reselect_chars_multiline`.

      Alle anderen Visual-Mappings im Ökosystem (dap, emojis, filetree, gopath,
      images, language, lsp, pdfport, sandbox, documentation) **schreiben
      nicht** in den Buffer — `nvim_buf_set_lines`/`set_text` kommt in keiner
      der Dateien vor. Sie werten die Selektion aus (DAP-Ausdruck, Pfad öffnen,
      Snippet ausführen). Dort wäre das Modul nicht „noch nicht benutzt",
      sondern unzutreffend.

      Ein Fehlalarm auf dem Weg, der Erwähnung wert: `buffer-ctx`s
      `format/enum_lines` sieht wie ein Kandidat aus (verändert eine
      Visual-Selektion zeilenweise), wird aber über einen **Usercmd** gerufen.
      Beim `:` ist Visual-Mode schon verlassen, es wird über `'<`/`'>`
      gearbeitet — es gibt keine Selektion zu behalten.


- [x] **Autocmds auf Optimierungspotential geprüft — nichts zu holen, und die
      Methode ist der interessantere Teil.**

      Über alle 31 Repos nach Event gezählt. Nur drei Klassen sind interaktiv
      teuer, weil sie pro Tastendruck bzw. Cursorbewegung feuern:
      `CursorMoved(I)` (5), `TextChanged(I)` (10), `WinScrolled` (1). Alles
      andere (`FileType`, `VimLeavePre`, `BufWritePost`, …) feuert selten genug,
      dass ein Handler dort kosten darf, was er will.

      **Erste Messung war das falsche Maß.** „Hat die Datei einen
      Throttle/Timer?" ergab sieben ungeschützte Kandidaten — davon waren
      **fünf Fehlalarme**:

      - `debugging/autocmds/sources.lua` und `images/config/DEFAULTS.lua`:
        *Listen* bekannter Event-Namen, keine Handler.
      - `filetree/bindings/autocmds.lua`: ein **Katalog**
        (`{ event, feature, desc }`); die echten Handler liegen in den Features,
        und `preview`/`git_status` sind dort throttled.
      - `insights/imports/definition.lua`: `CursorMoved` steht in den
        `close_events` eines Floats, ist also gar keine Registrierung.
      - `lib.nvim/cache/memory.lua`: vergleicht `changedtick` — ein
        Integer-Vergleich ist der billigste denkbare Guard.

      Die richtige Frage ist nicht „gibt es einen Timer", sondern **„verlässt
      der Handler den häufigen Fall billig?"**. `filetree`s Breadcrumbs sind das
      Musterbeispiel: `CursorMoved` auf `*`, aber die erste Zeile ist
      `if ft ~= "neo-tree" and ft ~= "NvimTree" then return end` — im normalen
      Editor-Buffer, wo man die ganze Zeit ist, kostet das ein
      Filetype-Lesen. Throttling wäre dort überflüssige Komplexität.

      **Ergebnis: kein ungeschützter Handler auf einem heißen Event im gesamten
      Ökosystem.** Entweder Guard oder Throttle, überall.


### Sonstiges

- [x] **Docs auf Englisch — abgeschlossen.** Die zweite Runde nach der
      Code-/User-Docs-Runde unten: alles Dev-seitige liest sich jetzt in einer
      Sprache.

      **`lsp.nvim`** — `docs/ROADMAP.md` (1380 Zeilen, das komplette
      Migrations-Protokoll samt der 19 B-Befunde und der Phasen 0–6) plus elf
      modulnahe READMEs: `lsp_signature`, `lua_ls`, `markdown_words`,
      `eslint_prettier` (README + autorun), `deprecated_help` (POC + ROADMAP),
      Astros `COMMANDS.md`, `diagnostics/ACTIONS.md`, lua_ls-Troubleshooting,
      `ts_type_lookup`. Die Schätzung von 197 deutschen Zeilen war zu
      niedrig — die Roadmap war praktisch durchgehend deutsch.

      **`mdview.nvim`** — die beiden `IDEAS/KONZEPT_*`-Entwürfe, das
      Overlay-Konzept, die archivierten Checkpoints und die
      WebTransport-Recherche (`Machbarkeit.md`, `Rolluout.md`), `CI/V_1.0.md`,
      die vier `testdoku`-/`server`-Seiten und `TESTS/CHECK.md`.
      `docs/ROADMAP/personal/LECTURE.md` bleibt deutsch — die Datei sagt in
      Zeile 3 selbst, dass sie eine persönliche Notiz und kein Roadmap-Teil
      ist.

      **`replacer.nvim`** — der UTF-8-Offset-Bericht, der Debug-Guide, die
      Feature-Matrix, der Richtlinien-Review und die Parser-Notiz.

      Dazu Einzelseiten in `gopath.nvim` (Audit + geplante Features),
      `documentation.nvim` (drei Banner), `color_my_ascii.nvim`,
      `debugging.nvim`, `emojis.nvim`, `fileops.nvim`, `markdown.nvim`,
      `migrate.nvim` und `images.nvim`.

      **Zwei Befunde nebenbei.** `images.nvim/doc/images.txt` zitierte für den
      Remote-Fall die Fehlermeldung `"Remote-Bilder sind deaktiviert"` — die
      gibt es im Code nirgends, `remote.lua:67` sagt *„remote images are
      disabled"*. Wer nach dem Text aus der Doku gesucht hat, fand nichts. Und
      `lib.nvim/docs/map/overview.md` trug noch deutsche Namespace-Beschreibungen,
      obwohl die Quell-Docstrings längst englisch sind: eine veraltete
      generierte Datei, die ohnehin gitignored ist.

      **Zitate bleiben Zitate.** In `documentation.nvim` (`FEATURES.md`,
      `PIPELINE.md`, `CORE.md`, `ECOSYSTEM.md`, `FEATURES_FORMAT.md`),
      `lib.nvim/docs/ROADMAP/dependency-installer.md`,
      `runtime-analysis.nvim/docs/FEATURES/FINISHED.md` und
      `filetree.nvim`s Neotree-Audit steht wörtlich zitiertes Deutsch in
      englischem Fließtext — die ursprüngliche Roadmap-Formulierung, die
      dortige Herleitung. Übersetzt wäre das ein Falschzitat. Ebenso
      unangetastet: `replacer.nvim`s deutsches i18n-Beispiel in README und
      vimdoc (es *demonstriert* Übersetzung) und die Test-Fixtures in
      `cascade.nvim`/`mdview.nvim`.

      **Weiterhin bewusst deutsch:** die `Arch&Coding`/`Checklist`/
      `Zentral-Prinzipien`-Ableitungen, `lsp.nvim/docs/CHECKLISTS/`, und die
      absichtlichen deutschen Fassungen mit englischem Gegenstück
      (`README-de.md`, `QUICKSTART-de.md`, `docs/features/de/**`, `*-DE.md`).

- [x] **Quellcode und Kommentare auf Englisch** — plus die nutzerseitigen Docs.
      (Die internen Roadmap-/Audit-Dokumente bleiben offen, s. MERGED.md.)

      **Code: 55 deutsche Kommentarzeilen in 8 Repos → 0.** Übersetzt in
      `lib.nvim` (16), `lsp.nvim` (16), `images.nvim` (11), `gopath.nvim` (5),
      `dap.nvim` (2), `migrate.nvim` (1). Nicht angefasst: sechs Stellen, an
      denen *zitiertes* Deutsch in englischem Text steht — ein deutscher
      Abschnittsname aus der Regelsammlung, eine deutsche Commit-Message im
      Test, ein deutscher Ausgabestring. Zitate bleiben Zitate.

      Wo die deutsche Fassung weniger sagte als sie konnte, sagt die englische
      jetzt das Ganze statt der wörtlichen Hälfte:
      `lib.nvim`s `get_alternate` benennt jetzt, *warum* ein Buffer mit Namen
      trotzdem unbrauchbar sein kann (Terminal, Help, Quickfix haben einen
      Namen, aber keinen Pfad), und der JSON-`@types`-Block sagt, dass die
      Key-Sortierung dafür da ist, dass die Ausgabe nicht von `pairs`-Reihenfolge
      abhängt.

      **Dev-seitige Docs, erste Runde:** `filetree.nvim/TESTS/MANUAL.md` (die
      manuelle Testanleitung, die ein anderer Entwickler abarbeitet — 14
      Checklisten-Abschnitte, Bekannte-Grenzen-Liste, Fehlerbild-Tabelle) und
      `lsp.nvim`s rootresolver-Vergleich. Letzterer endete auf eine Frage an
      einen Assistenten („Willst du, dass ich so eine vereinheitlichte Version
      skizziere?") — ein Rest aus dem Chat, aus dem er stammt. Die Version gibt
      es längst: beide Resolver laufen über
      `lib.nvim.fs.polymorphic_rootresolver`. Das Dokument sagt das jetzt,
      statt zu fragen.

      **Nutzerseitige Docs: 287 Zeilen → 0 echte.** 181 davon waren
      **absichtliche** deutsche Fassungen mit englischem Gegenstück
      (`README-de.md`, `docs/features/de/**`, `*-DE.md`) — die bleiben, das ist
      kein Versehen, sondern eine Übersetzung. Der Rest war `mdview.nvim`s
      `docs/FEATURES/FEATURES.md`, der Katalog, auf den README und jede andere
      FEATURES-Seite zeigen: 222 Zeilen, übersetzt statt paraphrasiert — der
      Entwickler-Teil behält jedes „warum", das er trug.

### Dokumentation & Cheatsheets

- [x] **`docs/BINDINGS.md` pro Plugin + die zentralen Cheatsheets, inkl.
      `lhs`-Dopplungs-Check über alle Plugins.**

      Der größte Teil stand schon: 28 der 31 Repos hatten ihre `BINDINGS.md`,
      und die Ordner unter `docs/NOTES/PersonelPlugins/BINDINGS/` waren mit
      31 Keymap-, 36 Usercmd- und 31 Autocmd-Blättern gefüllt. Offen war
      genau das, was ein einzelnes Repo nicht beantworten kann.

      **Die drei fehlenden `BINDINGS.md`** — `filetree.nvim`, `lib.nvim`,
      `markdown.nvim`. Alle drei hatten ihre Bindings dokumentiert, nur nicht
      unter dem Namen, den die anderen 28 benutzen: filetree in
      `docs/BINDINGS/{KEYMAPS,USERCOMMANDS,AUTOCMDS}.md` plus einem
      maschinenlesbaren `BINDINGS.lua`, markdown ausschließlich als
      `BINDINGS.lua` (dessen Kopfzeile sich selbst „docs/BINDINGS.md" nennt),
      lib.nvim nur mit `docs/BINDINGS/Usercmds.md`. Die neuen Seiten kopieren
      nichts: filetrees ist ein Einstiegspunkt auf die drei Detailseiten,
      markdowns rendert den Lua-Katalog, lib.nvims hält fest, dass die
      Keymap-Fläche **leer ist** — und warum (eine Library, von der andere
      Plugins abhängen, hat kein Recht, in deren Namen eine Taste zu belegen).

      **Der Dopplungs-Check** (`BINDINGS/Keymaps/Collisions.md`). Beide
      `All.md`-Indizes endeten auf ein „See also" mit dem Ziel `REF!` — die
      Analyse war angekündigt und nie geschrieben. Grundlage sind die Quellen,
      nicht die Blätter: die Defaults kommen aus `keymaps.lua`/`DEFAULTS.lua`,
      und der **Scope** jedes Mappings wurde an seiner `map(...)`-Aufrufstelle
      geprüft. Das war nötig: `images.nvim` und `pdfport.nvim` sehen in ihren
      Docs global aus und sind es nicht (Filetype- bzw. Dateibaum-lokal), und
      ohne diese Korrektur hätte der Bericht zwei Konflikte gemeldet, die es
      nicht gibt.

      Ergebnis: **keine einzige exakte Dopplung** in den 100 globalen
      Mappings von zwölf Plugins. Das ist ein Befund, keine Leerstelle — die
      Präfixe wurden offensichtlich gegeneinander gewählt. Was es gibt:

      - **Drei Cross-Scope-Überdeckungen**: `<leader>ps` (insights global vs.
        pdfport im Dateibaum), `gP` (gopath global vs. filetree im Tree),
        `+`/`-` (cascade vs. filetree). Immer dasselbe Muster — ein
        Tree-Plugin nimmt eine Taste, die ein Datei-Plugin schon hat; im Tree
        gibt es keine Datei, also geht nichts verloren.
      - **Drei überschriebene Builtins**: `<S-m>` (buffer-ctx nimmt `M` —
        Cursor in die Fenstermitte), `<C-e>` (emojis nimmt das Zeilen-Scroll),
        `+`/`-` (cascade, aber mit Fallback auf die native Bedeutung).
      - **Vier Prefix-Waits**, drei davon plugin-intern (`<leader>lr`,
        `<leader>nf`, `<leader>pf`, `<leader>xl`).
      - **Ein latenter Cross-Plugin-Konflikt**: `<leader>ss` ist
        language.nvims Spell-Toggle, und sessions.nvim schlägt in seiner
        README `<leader>ssa`/`<leader>sst` als Beispielwerte vor. sessions
        bindet per Default nichts — aber wer die Beispiele übernimmt, wartet
        ab da eine Sekunde auf jedes `<leader>ss`. Der einzige Konflikt, den
        man sich durch Befolgen der Doku einhandelt.
      - **Drei geteilte which-key-Präfixe** (`<leader>s`, `<leader>c`,
        `<leader>p`), bei denen jeweils ein Plugin das Gruppenlabel setzt und
        zwei bis drei andere dort ebenfalls Tasten haben.

      **Der Usercmd-Überblick** (`BINDINGS/Usercmds/Overview.md`), zweites
      `REF!`. 148 Kommandonamen über 31 Plugins, **alle 148 verschieden**.
      Vier Präfix-Überschneidungen zwischen Plugins (`:File`/`:Filetree`,
      `:Mark`/`:Markdown`, `:Lib`/`:LibInspect`, `:Open`/`:OpenWith…`) kosten
      nur Tab-Completion, weil Vim den exakten Namen zuerst auflöst.

      Der Fund, für den sich die Übung gelohnt hat: `lsp.nvim` registriert
      `:LspInfo`/`:LspLog` — **dieselben Namen wie nvim-lspconfig**, das über
      NvChad auf `User FilePost` geladen wird, also *später*.
      `nvim_create_user_command` überschreibt still, lspconfig müsste gewinnen.
      Es gewinnt nicht: Zeile 6 seiner `plugin/lspconfig.lua` ist
      `if vim.fn.exists(':lsp') == 2 then return end`, und die Suche ist
      case-insensitiv — `lsp.nvim`s `:Lsp`-Verb lässt lspconfigs komplette
      Plugin-Datei aussteigen, bevor sie irgendetwas registriert. Headless
      verifiziert (`lspconfig loaded: true`, trotzdem lsp.nvims Beschreibungen;
      `:LspStart`/`:LspStop`/`:LspRestart` existieren gar nicht). **Der
      Verbname `Lsp` ist damit tragend**: benennt man ihn um, tauchen fünf
      lspconfig-Kommandos auf und zwei davon überschreiben lsp.nvims eigene.

      **Zwei Tippfehler nebenbei behoben** (`lsp.nvim@329245c`): `desc_tag`
      stellte jeder Kommandobeschreibung `[lps.usercmds]` voran — sichtbar in
      `:command` und in which-key. Derselbe Dreher stand in
      `deprecated_help/doc/InstallationNotes.md`, dort nicht kosmetisch: das
      Snippet sagte `require("lps.tools.deprecated_help")` und scheitert beim
      Einfügen.

      **Und die Indizes repariert**: zwei tote Links auf `cmdlog.md` (die
      Datei heißt `cmdlog.nvim.md`), `lsp.nvim` fehlte in zwei Indizes,
      `images.nvim` in einem dritten, und der `:Bindings`-Explorer — das
      Werkzeug, mit dem man genau diese Blätter durchsucht — stand in keinem.

- [x] **`.luarc.json` pro Plugin-Root anlegen.**
      War in allen 31 Repos bereits vorhanden. Bei der Pruefung fiel auf, dass
      `sandbox.nvim/.luarc.json` durch zwei nachgestellte Kommata kein gueltiges
      JSON war (LuaLS' eigener Parser toleriert das, jeder andere Consumer nicht) --
      korrigiert. Alle 31 Dateien parsen jetzt als striktes JSON.

### Dokumentation & Cheatsheets

- [x] **Verweise auf die Quell-Checklisten korrigiert** (die offene Frage aus
      dem Roadmap-Task, von dir beantwortet: die Checklisten sind in den Regeln
      unter `WKDBooks/Development/wkdbook-Lua/Checklists/` aufgegangen).

      19 Verweise in 7 Repos zeigten auf `Notes/MyNotes/Checklists/Lua/`, die
      meisten noch mit dem alten `E:`-Laufwerk. Umgehängt nach der Zuordnung,
      die das `archiv/README.md` der Regelsammlung selbst festhält:
      `Arch&Coding-Regeln.md` → `regeln/PRINCIPLES.md` (+ `regeln/LUA_NVIM.md`),
      `Zentrale-Prinzipien.md` → `regeln/PRINCIPLES.md`, `Checklist.md` →
      `regeln/` + `gates/`.

      Der Linktext nannte jeweils noch die stillgelegte Datei, obwohl er aufs
      neue Ziel zeigte — jetzt benennt er das Ziel, plus eine Zeile, dass die
      Quellen aufgegangen und nicht verloren sind.

      `gopath.nvim` ist der Sonderfall: dort liegt eine 776-Zeilen-Kopie der
      *alten* Checkliste statt eines gopath-Audits. Sie sagt jetzt selbst, dass
      sie nicht die kanonischen Regeln ist und wo die stehen. Ob sie ganz weg
      soll, ist deine Entscheidung — die Regelsammlung sagt „Kopien an anderen
      Orten verweisen hierher und enthalten selbst keine Regeln".

      Damit sind die Roadmap-Dokumente aller 31 Repos frei von toten Links
      (vorher 38).

- [x] **`docs/ROADMAP.md` pro Plugin anlegen bzw. durchgehen.**
      Jedes Repo hatte etwas, aber in drei verschiedenen Formen: mal
      `docs/ROADMAP.md`, mal nur ein `docs/ROADMAP/`-Ordner, mal beides ohne
      Verbindung.

      *Angelegt:* `filetree.nvim` war das einzige Repo mit Ordner und ohne
      Einstiegspunkt — vier Dokumente, keine Aussage darüber, welche noch offen
      sind. Der README verwies auf den Ordner und zählte geplante Arbeit auf,
      die davon abgewichen war.

      *Durchgegangen:* neun Repos hatten `docs/ROADMAP.md` **und**
      `docs/ROADMAP/` nebeneinander, und die Datei erwähnte den Ordner nie —
      die Audits und Konzeptpapiere darin waren nur zu finden, wenn man das
      Verzeichnis bemerkte. Jede dieser Dateien indexiert ihren Ordner jetzt und
      sagt, dass nichts davon offene Arbeit ist, sofern es nicht dasteht. Wo die
      Roadmap nur aus Überschrift und Trennlinie bestand, steht jetzt, dass
      nichts offen ist, statt den Leser raten zu lassen.

      *Dabei gefunden:*
      - `filetree.nvim`s Neotree-Audit führte zwei der vier Lücken noch als
        „konkrete Arbeitspakete", obwohl beide gebaut sind
        (`paths.markdown_links`, `system.pdf_open`/`pdf_create`). Auch die
        Feature-Zahl war veraltet (62 → 56).
      - **38 tote Links** in den Roadmap-Dokumenten, jetzt 14 — und die
        verbleibenden sind alle dieselbe offene Frage (s. MERGED.md). Darunter
        drei, die `gen_map` in `images.nvim` bei *jedem* Lauf gemeldet hat, und
        neun in `filetree.nvim`s `Refs_Engine.md`, die als repo-root-relativ
        geschrieben waren, obwohl das Dokument drei Ebenen tief liegt.
      - `filetree.nvim` schloss Fixtures unter `TESTS/smart_rename_refs/` aus —
        in `.luacheckrc` **und** in der `.styluaignore`. Die Suite ist längst
        `TESTS/refs/`; beide Ausschlüsse liefen also ins Leere und die Fixtures
        wurden wie Plugin-Quellcode gelintet.
      - `gopath.nvim`s `Checklist.md` ist eine wörtliche Kopie der geteilten
        Checkliste, kein gopath-Audit wie in allen Geschwister-Repos — inklusive
        elf Querverweise auf Dateien des Quell-Repos.

- [x] **README.md pro Plugin an Spec anpassen.**
      Punkt für Punkt gegen alle 31 READMEs geprüft. Das meiste war schon da:

      | Spec-Punkt | Stand |
      | --- | --- |
      | Badges / ASCII-Art | 31/31 ✅ |
      | Auf Englisch | 31/31 ✅ (kein deutscher README-Text gefunden) |
      | Lizenzverweise löschen | 31/31 ✅ — kein README hat einen Lizenz-Abschnitt |
      | `dir = vim.env…` entfernen | 31/31 ✅ — kein lazy-`dir`-Feld irgendwo (der eine Treffer war `repos_dir = vim.env.REPOS_DIR`, eine echte Plugin-Option) |
      | `lazy=false`/`VeryLazy` explizit | 31/31 ✅ — die vier Treffer ohne Trigger waren `mini.deps`/`vim.pack`-Snippets, die keinen kennen |
      | Cross-Link zu verwandtem Plugin | war 30/31 |
      | Installation für mehrere Package-Manager | war 27/31 |

      Geschlossen wurden also zwei Lücken:

      - **`sandbox.nvim`** war das einzige README, dessen Kopf auf kein
        Schwester-Plugin zeigte. `reposcope.nvim` ist die ehrliche Paarung:
        reposcope klont ein Repo in ein Verzeichnis, und sandbox liest die
        `compose.yml` / `.devcontainer/`, die dieses Repo mitbringt, aus dem cwd
        oder einem Vorfahren — die beiden treffen sich, ohne dass eines von
        beiden einen Pfad konfiguriert bekommt.
      - **`images.nvim`, `language.nvim`, `sandbox.nvim`** zeigten nur ein
        lazy-Snippet. Alle drei haben jetzt `docs/installation.md` im Format der
        übrigen Repos (Prerequisites getrennt nach „required" und „schaltet
        genau eine Sache frei", dazu packer.nvim und vim-plug). Dabei kam jeweils
        etwas heraus, das im README nirgends stand: images braucht ein Terminal
        mit OSC 1337 (und warum die Spec `cmd` **und** `ft` trägt), sandbox
        braucht überhaupt eine Container-Engine auf dem `PATH`.

      Anmerkung: die bestehenden Cross-Link-Absätze beginnen mit einem
      Emoji (`> 💡 Pairs well with …`). Der neue in `sandbox.nvim` nicht — nach
      deiner stehenden Regel „keine Emojis in generiertem Inhalt". Sag Bescheid,
      wenn er der Optik zuliebe doch eines bekommen soll.

### Healthchecks, Config & Defaults

- [x] **`:checkhealth`-Unterstützung pro Plugin implementieren.**
      War in 30 von 31 Repos vorhanden. Headless über alle 31 verifiziert:
      `:checkhealth <name>` findet überall ein Modul und wirft keine Exception.

      Die eine Lücke war `documentation.nvim`: nach dem core/editor-Split lag
      der Healthcheck unter `documentation.editor.health`. Neovim löst
      `:checkhealth documentation` aber ausschließlich nach
      `lua/documentation/health.lua` auf und durchsucht keine
      Unter-Namespaces -- der Aufruf, den README, vimdoc und drei weitere Docs
      nennen, lief also ins Leere. Weiterleitungs-Modul angelegt.

      Aufgefallen dabei: der Name, den `:checkhealth` erwartet, ist der
      Lua-Modulname, nicht der Repo-Name -- und bei `dap.nvim` (intern
      `wkddap`, damit es nicht mit `nvim-dap` kollidiert) ist der nicht zu
      erraten. Die vollständige Zuordnung steht jetzt in
      `docs/NOTES/PersonelPlugins/Misc.md`.

- [x] **`/bindings`-Ordner (usrcmds/keymaps/autocmds) anlegen.**
      29 von 31 Repos hatten ihn. Die beiden Lücken sind geschlossen, und beide
      haben beim Aufräumen je einen echten Fehler hergegeben:

      - `replacer.nvim`: die Usercmds wurden von einer handgepflegten
        `pcall`-Leiter in `plugin/replacer.lua` registriert, die neun Module
        nannte und keines der Kommandos, die sie anlegen; der eine Autocmd und
        die zwei Panel-Keymaps standen inline in `regex.lua`.
        `lua/replacer/bindings/` hält jetzt alle drei. Der Autocmd bekam dabei
        eine benannte Gruppe (`ReplacerTestPanel`) — stapeln konnte er nicht,
        aber ein namenloser Autocmd ist für jeden unsichtbar, der prüfen will,
        was ein Plugin installiert.
      - `lib.nvim`: die ganze Bindings-Fläche lag in einer 168-Zeilen-
        `init.lua`. Aufgeteilt in `actions`/`usrcmds`/`autocmds` (kein
        Keymaps-Modul — eine Library, von der andere Plugins abhängen, hat
        keine Taste zu belegen). **Dabei gefunden:** der Helptags-Autocmd hatte
        keine Augroup, und `setup()` läuft bei jedem Config-Reload erneut. Nach
        zwei Reloads lief `helptags ALL` bei einem `:Lazy sync` also dreimal —
        ~229 ms pro Lauf bei 116 Plugins, und nicht inkrementell. Jetzt
        idempotent.

### Healthchecks, Config & Defaults

- [x] **Sinnvolle Features default aktivieren, Init-Spec so schlank wie möglich
      halten.**
      Zielbild war eine Spec, die nur noch aus Repo, Lazy-Trigger und `opts`
      besteht. **746 Spec-Zeilen → 639**, und danach ist in `opts` nichts mehr
      übrig, was nicht bewusst gesetzt ist.

      Zwei Sorten Ballast, beide mechanisch gefunden:

      *Optionen, die den Default des Plugins bloß wiederholten.* Jede
      `opts`-Tabelle gegen die `config/DEFAULTS.lua` des Plugins verglichen —
      sieben Specs erzählten dem Plugin seine eigenen Defaults zurück. `cascade`
      listete alle sechzehn Feature-Schalter (nur `keymaps.preset` weicht ab),
      `fileops` dreizehn (nur `cycle.open_target`), dazu buffer-ctx komplett,
      `diff.features.*`, `emojis.default_scope`, `debugging.features.neotree`,
      `images.display.draw_inset`, `cmdlog.picker`, `replacer.default_scope`.
      Eine wiederholte Default-Zeile ist schlechter als gar keine: sie sieht aus
      wie eine Entscheidung und hört still auf, dem Plugin zu folgen, wenn sich
      der Default bewegt.

      *`config`-Blöcke, die taten, was `opts` von selbst tut.*
      `config = function(_, opts) require(X).setup(opts) end` ist exakt
      lazy.nvims eigenes Verhalten für eine Spec mit `opts`. Von 16 solchen
      Blöcken sind 5 übrig — die, die wirklich etwas berechnen (pickers'
      collections, filetrees Feature-Tabelle, documentations
      bindings/generate_all-Builder).

      Verifiziert, nicht angenommen: jedes umgestellte Plugin headless geladen
      und geprüft, dass sein Modul auflöst und sein Command registriert ist.

      **Zur ersten Hälfte des Tasks:** die Defaults *sind* schon sinnvoll. Der
      Beweis ist genau das obige Ergebnis — nachdem alles Redundante raus ist,
      bleiben über 31 Plugins sechs echte Einstellungen übrig (Engine-Wahl,
      `progress_style = "statusline"`, cascades Keymap-Preset, fileops'
      `open_target`, images' gemessenes `cell_aspect`, pickers' collections).
      Kein Feature gefunden, das per Default an sein sollte und es nicht ist.

      **READMEs nachgezogen** (16 Repos), weil User die Spec von dort kopieren.
      Dabei drei echte Fehler in den Install-Anleitungen:
      - `cmdlog.nvim` bot drei Lazy-Load-Rezepte gleichrangig an; **zwei davon
        leeren genau die History, die das Plugin zeigen soll** — der
        `CmdlineLeave`-Tracker startet dann erst beim ersten `:Cmdlog`. Steht
        jetzt als Warnung unter beiden.
      - `replacer.nvim`s Snippets sagten `StefanBartl/replacer` mit
        `name`/`as`-Override daneben. Das Repo heißt `replacer.nvim`; die
        Kurzform funktioniert nur über GitHubs Redirect vom alten Namen, und der
        Override existierte nur, um das zu kaschieren.
      - `color_my_ascii.nvim` zeigte unter der Spec noch ein separates
        `require(...).setup()` — las sich wie ein zweiter Pflichtschritt.

- [x] **`config/init.lua` + `config/DEFAULTS.lua` pro Plugin anlegen,
      pluginseitige Defaults dorthin.**
      Die Struktur stand bereits in **allen 31 Repos**. Geprüft wurde deshalb
      die zweite Hälfte: liegen die Defaults auch wirklich dort?

      Gesucht nach Default-Tabellen außerhalb von `config/DEFAULTS.lua` — 6
      Repos, 10 Stellen. Nach Durchsicht sind acht davon korrekt am Platz:
      Funktionsargument-Defaults (`sessions.nvim`s Statusline-Komponente),
      interne Transport-Konstanten (`mdview.nvim`s Websocket-Backoff),
      Highlight-Konstanten (`lsp.nvim`) und drei filetree-Features, deren
      Defaults laut der dokumentierten Architektur beim Feature bleiben
      („Per-feature defaults that are not listed here live in the feature
      module itself").

      Zwei waren echte Befunde:

      - **`filetree.nvim`, `cwd_mode`:** `config/DEFAULTS.lua` führte eine
        von Hand gepflegte **Teilkopie** der Feature-Tabelle — und war schon
        abgedriftet. Der ganze `nearest`-Block (zehn Package-Marker, die
        komplette Konfigurationsfläche eines der sechs Modi) stand nur im
        Feature; wer die zentralen Defaults las, konnte nicht erkennen, dass es
        überhaupt konfigurierbar ist. Dasselbe bei `indicator.labels` und
        `align`. Nach `features/nav/cwd_mode/DEFAULTS.lua` ausgelagert und von
        beiden Seiten `require`d — genau die Anordnung, die
        `filetree.refs.DEFAULTS` in derselben Datei schon benutzt. Gemerged
        wurde vorher wie nachher gleich (die kopierten Keys stimmten zufällig
        überein, und der Merge ist tief); es geht um den nächsten Edit, nicht
        um diesen.
      - **`runtime-analysis.nvim`:** `setup()` akzeptiert vier Optionen —
        `KNOWN_OPTS` validiert genau dagegen — aber `DEFAULTS.lua` beschrieb
        drei. `telemetry` existierte nur in der `@param`-Annotation. Steht
        jetzt dort, bewusst **ohne Default-Wert**: Auto-Instrumentierung ist
        opt-in, und gerade die *Abwesenheit* des Keys bedeutet „nicht
        instrumentieren" — eine Default-Tabelle hätte sie für alle
        eingeschaltet, die nie danach gefragt haben.

- [x] **Prüfen: sind wirklich alle Plugins lazy geladen?**
      Nein — und das ist überwiegend richtig so. Von 31 Specs in
      `lua/plugins/personal/init.lua` laden 7 eager (`lazy = false`):

      | Plugin | Eager, weil | War begründet? |
      | --- | --- | --- |
      | `lib.nvim` | Library + registriert `:Lib`/`:CwdHere` beim Start (Priority 1000) | ja |
      | `lsp.nvim` | Capabilities müssen global stehen, bevor der erste Client attached (Priority 900) | ja |
      | `runtime-analysis.nvim` | Telemetrie muss die anderen Plugins umschließen, bevor die laden | ja |
      | `insights.nvim` | conflicts/unimported/devserver sind Autocmds aus `setup()` | ja |
      | `sessions.nvim` | `VimEnter`-Autoload und `VimLeavePre`-Autosave | **nein, jetzt** |
      | `pickers.nvim` | `setup()` leitet ~20 Keymaps aus der `collections`-Tabelle ab | **nein, jetzt** |
      | `cmdlog.nvim` | `setup()` startet den `CmdlineLeave`-Tracker | **nein, jetzt** |

      `learn-cli.nvim` steht ebenfalls auf `lazy = false`, ist in `source.lua`
      aber `"disabled"` — lädt also ohnehin nie.

      **Der eine echte Fund:** `cmdlog.nvim` hatte `lazy = false` **und**
      `cmd = { "Cmdlog" }`. lazy.nvim ignoriert das `cmd` dann, aber die Zeile
      las sich, als wäre das Plugin kommando-lazy — und wer sie „aufräumt",
      indem er `lazy = false` entfernt, bricht das Plugin auf eine Art, die
      niemand als Fehler sieht: der Tracker startete dann erst in dem Moment,
      in dem man die History zum ersten Mal öffnet, die also immer leer wäre.
      Das tote `cmd` ist weg, der Grund steht jetzt dort.

      Die drei unbegründeten Fälle haben jetzt ihre Begründung im Spec. Kein
      Plugin wurde umgestellt: bei allen sieben ist eager nach Prüfung die
      richtige Antwort.

### Security, Tests & CI/CD

- [x] **Testdateien unter `TESTS/**` schreiben** — die zweite Hälfte des
      Test-Tasks. **Alle 31 Repos haben jetzt eine Suite und einen Test-Job in
      CI**, vorher waren es 25.

      Fünf Repos hatten überhaupt keine Tests. Jedes hat jetzt vier bis sechs
      Specs im Haus-Stil (`TESTS/run.lua` + `harness.lua`, headless, keine
      Netzwerk-/UI-Abhängigkeit), ein `TESTS/README.md` und einen dritten
      CI-Job mit lib.nvim als Sibling-Checkout.

      Was dabei zutage kam — in allen fünf Fällen habe ich das **tatsächliche**
      Verhalten festgeschrieben und den Kommentar dazugeschrieben, statt zu
      „reparieren", was eine Entscheidung von dir wäre:

      - **`reposcope.nvim`**: `setup()` merged in die *aktuelle* Optionstabelle
        (`vim.tbl_deep_extend("force", M.options, opts)`), nicht in eine Kopie
        von DEFAULTS wie in allen Geschwister-Plugins. Es akkumuliert also:
        ein zweites `setup({})` setzt nichts zurück, und eine einmal gesetzte
        Option lässt sich später nicht mehr abwählen. Für den normalen
        Einmal-`setup()`-Pfad egal, für Runtime-Rekonfiguration überraschend.
      - **`insights.nvim`**: `require("a." .. kind)` wird als Modul `a.`
        gemeldet — der Scanner sieht nur das Literal vor der Konkatenation. Das
        ist genau die False-Positive-Klasse, die die `:DocMap`-Notizen der
        nvim-Config beschreiben. Zu unterdrücken bräuchte eine Entscheidung,
        was ein dynamisches require beitragen soll: nichts, oder das Präfix als
        Hinweis.
      - **`recommender.nvim`**: eine Dreiteil-Kette liefert bei Threshold 1
        *zwei* Vorschläge, weil auch ihr Zweiteil-Präfix ein Kandidat ist —
        genau deshalb ist der Default über 1. Und die Blacklist matcht
        Strings, nicht Segmente: `vim.a` blockt `vim.api`.
      - **`sessions.nvim`**: die sicherheitsrelevante Stelle ist
        `git.sanitize` — ein Session-Name wird zu einem Dateipfad, und die
        Namen kommen aus Branch und Verzeichnis. `feature/login`, `..`, ein
        Backslash und eine ANSI-Farbsequenz müssen alle zu etwas werden, das
        das Sessions-Verzeichnis nicht verlassen kann.
      - **`language.nvim`**: `is_compound` darf nie „nein" sagen, wo `split`
        Arbeit gehabt hätte — dieser Vorab-Check ist das Einzige, was still
        einen echten Fund kosten kann.

      **Und ein sechstes Repo:** `color_my_ascii.nvim` *hatte* eine Suite mit
      16 Spec-Dateien — CI hat sie nie aufgerufen, der Workflow hieß „Lint" und
      tat genau das. Jetzt läuft sie. Beim ersten Lauf über `TESTS/` kam
      heraus, dass das Verzeichnis noch nie geprüft worden war (falscher
      Quote-Stil, eine tote Zuweisung).

- [x] **Bestehende Tests nach `TESTS/**` verschieben (Root statt `docs`)** —
      die Verschiebe-Hälfte des Test-Tasks. Vorher lagen sie an vier
      verschiedenen Orten, jetzt an einem: **25 von 31 Repos haben `TESTS/` im
      Root**, keines mehr `docs/TESTS/`, `tests/` oder `test/`.

      - 12 Repos: `docs/TESTS/` → `TESTS/`.
      - 5 Repos: `tests/` → `TESTS/` (als zwei git-moves, weil eine reine
        Groß-/Kleinschreibungs-Umbenennung auf einem case-insensitiven
        Dateisystem ein No-op ist).
      - `filetree.nvim` hatte beides: `test/` mit den vier Headless-Suites und
        `TESTS/` mit den Fixture-Tests. Zusammengelegt; `test/README.md` war
        keine Dublette, sondern eine manuelle Integrations-Checkliste — liegt
        jetzt als `TESTS/MANUAL.md` daneben.
      - `github_stats.nvim` hatte seine Specs unter `lua/github_stats/tests/`,
        also **im Runtime-Tree** — sie wurden mit ausgeliefert und lagen auf dem
        runtimepath. Jetzt im Root.

      **Der teure Fund dabei:** luacheck bringt eingebaute busted-Defaults mit,
      die auf `**/spec/**`, `**/test/**` und `**/tests/**` matchen — alles
      klein. Solange die Suite in `tests/` lag, bekam sie den busted-std
      geschenkt; `TESTS/` matcht keines davon, und `assert.has_no.errors` &
      Co. wurden zu 465 Warnungen in `lsp.nvim`, von denen keine einzige den
      Code betraf. Jetzt explizit deklariert — was ohnehin besser ist, weil
      vorher nirgends stand, woher die busted-Globals kamen.

      Zwei weitere Fallen, die nur auf Linux sichtbar wurden:
      - `sandbox.nvim` hatte drei `require("tests.sandbox.helpers.…")` —
        Modulpfade, keine Dateipfade, also für eine `tests/`-Suche unsichtbar.
        Unter Windows löste das weiter auf (case-insensitiv), auf CI nicht: jede
        Spec meldete Erfolg und der Prozess ging trotzdem mit 1 raus.
      - `runtime-analysis.nvim`s `parse_spec.lua` lud `ftdetect/` über
        `TESTS/../../` — zwei Ebenen hoch, weil die Suite unter `docs/` lag.


- [x] **`ci`/`stylua`/Tests über alle Plugins grün ziehen.**
      Ausgangslage: 21 Repos rot, 4 ohne jeden Workflow, 7 grün.
      Endstand: **alle 31 Repos grün, in jedem Workflow** -- und ohne
      `continue-on-error` irgendwo, das Grün also echt.

      Was rot war, nach Ursache:

      *stylua* (16 Repos) -- Dateien, die älter als die `stylua.toml` waren
      oder daran vorbeigedriftet sind. Formatierung, keine Verhaltensänderung.

      *luacheck* (10 Repos). Zwei davon waren echte Bugs, nicht nur Lint:
      - `emojis.nvim`: `open_grid` wurde im `/`-Filter mehrere hundert Zeilen
        vor seiner `local function`-Definition aufgerufen, war dort also gar
        kein Upvalue, sondern ein nil-Global -- Filtern im Grid ist
        geknallt statt neu zu rendern. Jetzt forward-deklariert.
      - `reposcope.nvim`: `metrics.lua` baute einen Authorization-Header und
        übergab ihn nicht, `/rate_limit` lief unauthentifiziert und meldete die
        anonyme Quote (60/h) statt der des Tokens (5000/h).
      Der Rest waren tote Zuweisungen, ungenutzte Argumente/Shims, ein leerer
      `if`-Zweig, ein Shadowing von `pcall`s `ok`-Flag, plus drei Config-Fixes
      (`bit` als LuaJIT-Global in `images.nvim`; `max_line_length` an stylua
      abgegeben, wo es nur Stringliterale und LuaCATS-Kommentare traf;
      `.luarocks/` aus dem Prüfpfad von `github_stats.nvim`).

      *Tests / Job-Setup* -- Gates, die strukturell nie grün werden konnten:
      - `diff.nvim`: `git_spec` rief das längst callback-basierte
        `core.git.resolve` positionell auf und las einen Rückgabewert. `cb` war
        damit nil, die Guard-Clauses sind mit "attempt to call upvalue 'cb'"
        auf dem Main-Loop hochgegangen -- mitten in `url_spec`, das dadurch die
        ganze Suite mitgerissen hat.
      - `documentation.nvim`: der `<Tab>`-Completion-Abschnitt war von Hand in
        das **generierte** `docs/BINDINGS.md` geschrieben. Jeder `:DocMap`-Lauf
        hat ihn gelöscht, und weil die Modul-Map BINDINGS.md einbettet, war
        auch sie danach "stale" -- rotes Gate ohne irgendetwas im Working Tree,
        das es erklärt hätte. Der Abschnitt liegt jetzt im Renderer, wo der
        Kommentar direkt darunter das auch vorschreibt.
      - `images.nvim`: das map-Gate lief `gen_map.lua --check`, das gegen eine
        *committete* Map vergleicht -- `docs/map/` steht dort aber in der
        `.gitignore`. Auf einem frischen Checkout gab es nichts zu vergleichen,
        das Gate konnte nie grün werden.
      - `github_stats.nvim`: `scripts/test.sh` war ohne Executable-Bit
        committet, der Runner hat es mit exit 126 abgelehnt.
      - `replacer.nvim`: CI checkt lib.nvim *in* den Workspace aus, der
        Resolver sucht ein *Geschwister*-Verzeichnis. Alle drei Suites brachen
        vor dem ersten Check ab.
      - `open.nvim`: `features_spec` behauptete, `filemanager.reveal=true/false`
        bauten immer verschiedene Kommandos. Ohne select-fähigen Dateimanager
        (also auf jedem Runner) degradiert `reveal=true` per Design zum
        Öffnen des Elternverzeichnisses -- der Test hat geprüft, ob der Runner
        einen Desktop hat.

      *Advisory-Gates abgeschafft* -- `filetree.nvim` (105 Dateien
      nachformatiert; die vier Headless-Suites melden davor und danach exakt
      dieselben Pass/Fail-Zahlen), `fileops.nvim`, `markdown.nvim`. Bei
      `fileops.nvim` kam dabei heraus, dass der stylua-Schritt nie gelaufen
      war: ohne `token` bricht die Action ab, was durch `continue-on-error`
      niemand gesehen hat.

- [x] **GitHub Actions einrichten (z. B. `luacheck`).**
      Vier Repos hatten ueberhaupt keinen Workflow: `insights.nvim`,
      `language.nvim`, `reposcope.nvim`, `sessions.nvim`. Alle vier haben jetzt
      `.github/workflows/ci.yml` mit `stylua --check` (auf 2.5.2 gepinnt) und
      `luacheck`, im Stil der Geschwister-Repos.

      Was dabei mitkam:
      - `sessions.nvim` hatte weder `stylua.toml` noch `.luacheckrc` -- beide
        angelegt (Haus-Stil); die 139 luacheck-Findings waren nur der Default-`std`,
        der `vim` nicht kennt.
      - `insights.nvim/stylua.toml` stand auf `line_endings = "Windows"`, waehrend
        `.gitattributes` `eol=lf` erzwingt. Jeder Linux-Runner haette damit
        *jede* Datei als unformatiert gemeldet. Auf `Unix` umgestellt.
      - `reposcope.nvim`: luachecks einziges Finding war ein echter Bug --
        `metrics.lua` baute einen Authorization-Header und uebergab ihn nicht,
        `/rate_limit` lief also unauthentifiziert und meldete die anonyme
        Quote (60/h) statt der des Tokens (5000/h).
