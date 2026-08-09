# replacer.nvim

## Zweck
Projektweites Search-and-Replace mit ripgrep (nativer `vimgrep`-Fallback ohne
externe Abhängigkeit), interaktivem Picker (fzf-lua/Telescope, auto-erkannt),
Live-Preview und präziser, bottom-up angewandter Änderung. Zusätzlich: `:Surround`
(Match umschließen), Regex-Backreferences, Case-preserving Replace,
Tree-sitter-gestütztes "code-only"-Filtern, Soft-LSP-Rename, Undo-Checkpoints,
History/Presets, Batch-Replace über mehrere Paare, und Datei-Umbenennung
(`:ReplaceFNames`). Quelle: `E:\repos\replacer.nvim\README.md`.

## Nicht-standard Patterns / Algorithmen
- `lua/replacer/checkpoint.lua:1-11`: Undo-Snapshots werden bewusst als reine
  Datei-Kopien implementiert, nicht als `git stash`/Temp-Branch — der
  Docstring begründet das explizit: ein Stash würde auch unabhängige,
  nicht-committete Arbeit im selben Repo mit einsammeln, was ein
  Korrektheitsrisiko wäre, das dieses Plugin nicht eingehen will. Restore ist
  ein byte-exaktes Zurückschreiben (`write_exact`, `checkpoint.lua:31-49`) ohne
  Zeilenumbruch-Normalisierung.
- `lua/replacer/checkpoint.lua:51-69` (`read_current`): Liest den *aktuellen*
  Inhalt einer Datei bevorzugt aus einem geladenen Buffer statt von der Platte
  — damit ein Checkpoint auch ungespeicherte Änderungen korrekt sichert,
  konsistent mit dem Dry-Run-Verhalten des Plugins.
- `lua/replacer/apply.lua:79-138` (`compute_file_edits`) und `213-343`
  (`apply_matches`): Änderungen werden pro Zeile bzw. pro Datei **bottom-up**
  (höchste `col0`/`lnum` zuerst) angewendet, damit frühere Edits die
  Byte-Offsets nachfolgender Matches nicht verschieben — vermeidet den
  klassischen "Index-Shift-Bug" bei Mehrfach-Ersetzungen in derselben Zeile/Datei.
- `lua/replacer/apply.lua:117-129,266-274`: Jedes Match wird vor dem Schreiben
  gegen den *aktuellen* Text an seiner Position verifiziert (`seg == old_text`);
  bei Abweichung wird das Match als "stale" übersprungen statt blind zu
  überschreiben — schützt gegen zwischenzeitliche Buffer-Änderungen zwischen
  Scan und Apply.
- `lua/replacer/apply.lua:167-180` (`is_binary_file`): Klassische
  Binary-Heuristik (NUL-Byte in den ersten 512 Bytes), dieselbe wie
  grep/git verwenden — statt einer teuren vollständigen Inhaltsprüfung.
- `lua/replacer/apply.lua:288-298`: Wenn ≥50 % der Matches einer Datei beim
  Apply übersprungen werden mussten, wird explizit gewarnt ("buffer may have
  changed; re-run") — eine Heuristik-Schwelle, um bei systematischen
  Verschiebungen (z. B. Datei extern verändert) den Nutzer aktiv zu informieren,
  statt nur eine generische "N skipped"-Zahl zu zeigen.
- `lua/replacer/casing.lua:24-38` (`split_words`): Wort-Splitting erkennt sowohl
  Separator-Zeichen (`_`, `-`, Whitespace) als auch interne
  lower→upper-camelCase-Grenzen, damit `"fooBar"` und `"foo_bar"` zum gleichen
  `{"foo","bar"}` normalisiert werden — nötig, damit Case-Preserve-Replace über
  alle gängigen Identifier-Stile hinweg funktioniert.
- `lua/replacer/casing.lua:44-69` (`M.detect`): Unterscheidet "title" (ein
  einzelnes großgeschriebenes Wort, z. B. "Foo") von "camel"/"pascal"
  (mehrere Wörter) anhand der Wortanzahl nach dem Split — ein einzelner Groß-
  Kleinschreibungs-Check allein könnte das nicht trennen.
- `lua/replacer/apply.lua:22-37` (`wrap_with_original_whitespace`): Bewahrt
  führenden/nachfolgenden Whitespace des Original-Matches um den Ersatztext,
  wenn dieser über eine Regex wie `\s*foo\s*` mitgematcht wurde — verhindert,
  dass ein `--preserve-ws`-Replace die umgebende Formatierung zerstört.
- README (`--stream`, Zeilen 268-282): Der inkrementelle
  ripgrep-`--json`-Streaming-Collector ist laut README bewusst *nicht* an die
  Picker-Live-Befüllung angebunden, obwohl die Infrastruktur dafür existiert
  und testäquivalent zum nicht-streamenden Collector ist — explizit als
  zurückgestellt dokumentiert wegen des Integrationsrisikos von nicht
  automatisiert testbarem Terminal-UI-Live-Code.
- README (`:ReplaceFNames`, Zeilen 216-232): Umbenennungen werden aus einem
  *einzigen* Snapshot des Verzeichnisbaums berechnet; wenn ein Treffer
  innerhalb eines anderen Treffers verschachtelt ist, wird in diesem Lauf nur
  der äußere umbenannt (der innere "fährt kostenlos mit") — ein bewusster
  Kompromiss gegen doppelte/kollidierende Umbenennungsoperationen im selben Lauf.
- README (`root`-Scope, Zeilen 162-181): Bei mehreren Projekt-Root-Kandidaten
  (Monorepo) wird deterministisch der äußerste mit `.git` bevorzugt, ohne
  nachzufragen — für den interaktiven Fall gibt es den separaten Command
  `:ReplaceRoot`. Eine bewusste Trennung von "schneller Default" und
  "expliziter Nutzerentscheidung" in zwei verschiedenen Commands statt einem
  Prompt im Normalfall.

## Abgeleitete Guidelines
1. Undo-/Snapshot-Mechanismen für gezielte Dateiänderungen als reine
   Datei-Kopien implementieren, nicht über VCS-Mechanismen wie `git stash` —
   letztere haben einen zu breiten Wirkungsradius (erfassen unabhängige
   Änderungen) und sind damit ein Korrektheitsrisiko.
2. Bei Mehrfach-Edits in derselben Zeile/Datei: immer bottom-up (höchste
   Position zuerst) anwenden, damit Offsets nicht verschoben werden. Diese
   Regel gilt für jede Text-Transformation mit mehreren Positions-basierten
   Edits, nicht nur für Replace.
3. Vor jedem Schreiboperationen-Batch: jedes einzelne Match gegen den
   *aktuellen* Zustand verifizieren (nicht den zum Scan-Zeitpunkt gecachten) und
   bei Abweichung überspringen statt zu überschreiben.
4. Bei signifikanter Skip-Rate (z. B. >50 %) proaktiv warnen statt nur eine
   Zahl zu berichten — der Nutzer soll erkennen, dass etwas Systematisches
   (nicht nur vereinzeltes) vorliegt.
5. Reine, seiteneffektfreie Kernlogik (Case-Detection, Edit-Berechnung) klar von
   der seiteneffektbehafteten Anwendung trennen (`compute_file_edits` vs.
   `apply_matches`) — macht die Kernlogik trivial unit-testbar und
   wiederverwendbar für Dry-Run/Export, ohne echte Buffer-Mutation zu
   benötigen.
6. Riskante, nicht automatisiert testbare UI-Integration (Live-Picker-Befüllung
   während eines laufenden Streams) bewusst zurückstellen, auch wenn die
   Infrastruktur schon fertig ist — Trennung von "Backend fertig" und "UI-Layer
   sicher integriert" ist eine explizite Entscheidung, kein Versehen.
7. Bei mehrdeutigen Situationen mit einem sinnvollen deterministischen Default
   (z. B. äußerster Git-Root): einen schnellen Default-Pfad UND einen
   expliziten interaktiven Pfad als getrennte Commands anbieten, statt in
   jedem Fall zu fragen.
8. Konfigurierbare Nachrichten-Templates (`messages` in `setup()`) mit
   Fallback auf "zeige die Template-Definition wörtlich, wenn sie ungültig
   ist" statt zu crashen — robust gegenüber Nutzerfehlern in der Konfiguration.
9. Hooks (`before_apply`/`after_apply`/`before_write`/`after_write`) um
   Kernoperationen anbieten, mit Veto-Möglichkeit (Rückgabewert `false`
   überspringt) und garantiertem Error-Catching (ein Hook-Fehler bricht den
   Gesamtlauf nie ab) — macht das Plugin erweiterbar ohne Fork.

## Keybindings-Audit
Quelle: `docs/BINDINGS.md`, README (Picker Keymaps).

Picker-Keymaps (buffer-lokal, nur im Picker-Fenster, konfigurierbar über
`setup({ keymaps = {...} })`):

- `<CR>` (fest, Apply Selection/Multi-Selection):
  - Count: n. a. — Picker-Kontext.
  - Autocompletion: n. a.
- `<Tab>` / `<S-Tab>` (`toggle_select` / `toggle_select_prev`, Default `<Tab>`/
  `<S-Tab>`): Selektion umschalten + zum nächsten/vorherigen Eintrag springen.
  - Count: n. a.
- `<C-a>` (`apply_all`, Default `<C-a>`): alle Matches ersetzen, respektiert
  `confirm_all`.
  - Count: n. a.
- `<C-r>` (`replace_and_reopen`, Default `<C-r>`): wendet den Eintrag unter dem
  Cursor an und öffnet den Picker mit den verbleibenden Matches neu. Bewusst
  ein Modifier statt eines bloßen Buchstabens — README begründet das explizit
  damit, dass die Query-Zeile Live-Text-Input ist und ein Buchstabe dort
  ankäme statt die Aktion auszulösen (`docs/BINDINGS.md:46-48`).
- `<Esc>` (`quit`, Default `<Esc>`): 1. Druck verlässt Insert/Terminal-Insert
  (fest), 2. Druck (Normal-Mode) schließt den Picker.
  - which-key-Einschränkung dokumentiert: fzf-lua's `toggle_select`/`apply_all`/
    `replace_and_reopen` sind native fzf-Terminal-Bindings, die nie durch
    Neovims Keymap-Layer laufen — which-key kann sie für das fzf-Backend nicht
    labeln, wohl aber für Telescope (echte `vim.keymap.set`-Aufrufe).

Ex-Commands (`:Replace`, `:Surround`, `:ReplaceRoot`, `:ReplaceBatch`, u. a.):
kein eigenes normaler-Modus-Keymap, stattdessen ein sehr reichhaltiges
Flag-/kv-System (`--regex`, `--type=`, `--glob=`, `--exclude=`, `--changed=`,
`--engine=`, `--context=`, etc.). Aus dem gelesenen Code/README nicht abschließend
geprüft, ob `:Replace`-Argumente vollständige Tab-Completion haben
(`command.lua` selbst wurde nicht gelesen); README zeigt aber `:ReplacePreset`
mit expliziter `<Tab>`-Namens-Completion (Zeile 187) — Pflicht-Einschätzung: bei
einem derart flag-reichen Command ist vollständige kv-/Flag-Completion für
Adoption/Fehlervermeidung praktisch unverzichtbar; das Ausmaß der tatsächlichen
Completion-Abdeckung wurde hier nicht vollständig verifiziert.

Count-Bewertung generell: Keine der Picker- oder Ex-Command-Bindings nutzt
einen vorangestellten Count — das ist sachgerecht, da alle Aktionen entweder
Text-basierte Scope-/Match-Auswahl (Picker) oder explizite Flags
(`--all`, Range) sind, für die ein Count keine natürliche Bedeutung hätte.

## Ideen für andere Plugins
- Das Checkpoint/Undo-Snapshot-Muster (`checkpoint.lua`) als generisches
  `lib.nvim`-Utility ("Snapshot + Manifest + byte-exact restore") anbieten,
  wiederverwendbar für jedes destruktive Multi-File-Tool (z. B. `fileops.nvim`,
  `migrate.nvim` bei `cwd`-Scope-Anwendungen).
- Case-Detection/-Preservation (`casing.lua`) als eigenständiges,
  seiteneffektfreies `lib.nvim`-Modul extrahieren — nützlich für jedes
  Rename-/Refactoring-Tool (auch `migrate.nvim`, `fileops.nvim`s Rename-Assist).
- Ein generisches "Hooks"-Muster (`before_apply`/`after_apply`/`before_write`/
  `after_write` mit Veto + Error-Isolation) als `lib.nvim`-Baustein für alle
  Plugins mit einer Apply-Pipeline (migrate.nvim, pdfport.nvim-Extraktion).
- Die "bottom-up Edit + Stale-Match-Verifikation"-Kombination als generische
  `lib.nvim.buffer.apply_edits`-Funktion, damit jedes Plugin, das mehrere
  Positions-basierte Textänderungen anwendet, dieselbe Sicherheit ohne
  Neuimplementierung bekommt.
