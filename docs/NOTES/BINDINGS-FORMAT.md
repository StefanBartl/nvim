# BINDINGS-FORMAT — Regeln für Keymaps/Usercmds/Autocmds-Cheatsheets

Gilt für beide Bäume:

```
docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,Autocmds}/<plugin>.nvim.md
docs/NOTES/ExternPlugins/Bindings/{Keymaps,Usercmds,Autocmds}/<Plugin>.md
```

**Warum jetzt**: kein Neuentwurf — ein Blick über die 30 Personal-Keymaps-
Dateien zeigt, dass bereits ein De-facto-Standard existiert (Titel, `Source:`-
Zeile, Intro, Haupttabelle, `## which-key`, `## Notes`, datierte
Changelog-Zeilen), nur nirgends aufgeschrieben und nicht überall konsequent
angewendet. Konkreter Beleg: 18 von 30 Dateien erwähnen which-key irgendwo,
aber nur 11 unter einer eigenen `## which-key`-Überschrift; **keine einzige**
Datei hat eine eigene `## Changelog`-Überschrift (die Einträge hängen überall
lose am Ende von Notes). `images.nvim.md` — von mir diese Sitzung gepflegt —
gehört selbst zu den 12 Dateien **ohne jede** which-key-Erwähnung, obwohl
images.nvim die Gruppe tatsächlich registriert (siehe
`docs/ROADMAP/README.md` → "which-key-Gruppe für den `<leader>i`-Präfix").
Das hier formalisiert also etwas Bewährtes, statt etwas Neues zu erfinden —
und macht images.nvim.md gleich zum ersten Korrekturfall.

Zweiter Grund: das hier gebaute Schema ist genau das, was
[bindings-explorer.nvim.md](ROADMAP/personal/bindings-explorer.nvim.md)s
Phase 2 (Tabellenzeilen als Datensätze) und Phase 3 (Drift-Erkennung)
brauchten — beide seit 2026-08-09 implementiert (`:Bindings browse`/
`:Bindings check`, siehe dessen
[FEATURES.md](../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md)).
Mit festen Überschriften statt freier Prosa wurde aus dem dort skizzierten
*toleranten* Scraper ein einfacher, verlässlicher Parser (`records.lua`,
weiterverarbeitet von `drift.lua`) — die "eigene Überschrift über jeder
Tabelle"-Pflicht aus §1 unten ist genau das Scope-Label, das der Scraper
pro Zeile braucht.

---

## 1. Gemeinsames Grundgerüst (alle drei Kategorien)

```markdown
# <Plugin> — <Kategorie> Cheatsheet

Source: `pfad/zur/datei.lua`[, `pfad/zur/zweiten.lua`]
Docs: `docs/BINDINGS.md`, ...                          <!-- optional -->

<ein bis drei Absätze Fließtext: Mechanismus, Opt-in-Verhalten,
Besonderheiten. Frei, nicht geparst.>

## <Optionale Zwischenüberschrift, wenn mehr als eine Tabelle nötig ist>

| ... |
| --- |

## which-key                                            <!-- nur Keymaps, siehe §3 -->

...

## Notes

- Rationale, Caveats, "nicht zur Laufzeit verifiziert"-Hinweise. Frei.

## Changelog

- 2026-08-06: ...
- 2026-08-06 (2): ...
```

Titel-Casing bleibt wie gewachsen: `plugin.nvim` klein in PersonelPlugins,
`Plugin` PascalCase in ExternPlugins — keine Umbenennung, nur die
Struktur darunter wird vereinheitlicht.

**Verbindlich neu ab jetzt:**
- `## Changelog` ist eine eigene Überschrift, nie Teil von `## Notes`.
- Jede Tabelle, die nicht die einzige im Dokument ist, bekommt eine eigene
  `##`/`###`-Überschrift direkt darüber — auch wenn die Tabelle selbst nur
  zwei Zeilen hat. Ein zukünftiger Parser braucht diese Überschrift als
  Scope-Label pro Zeile (siehe bindings-explorer.nvim.md §3, Phase 2).

## 2. Pro Kategorie

**Keymaps** — Basisspalten `| Key | Mode | Effect | Option/Source |`.
Zusätzliche Spalten sind erlaubt und teils nötig (`sessions.nvim.md`s
`condition`-Spalte für Opt-in-per-Config-Key ist ein echter semantischer
Unterschied, keine Nachlässigkeit) — Pflicht ist nur, dass Taste, Modus und
Wirkung irgendwo in der Zeile stehen, nicht eine feste Spaltenzahl.

**Usercmds** — Basisspalten `| Command | Range | Effect |`. `Range` entfällt,
wenn der Plugin-Verb keine Range-Unterstützung hat (dann zweispaltig).

**Autocmds** — `| Event(s) | Augroup | Pattern | Action |`, identisch zum
Format, das jedes Plugin inzwischen in seiner eigenen `docs/BINDINGS.md`
führt (z.B. [lsp.nvim](https://github.com/StefanBartl/lsp.nvim/blob/main/docs/autocmds.md)).
Hier gibt es nichts Neues zu erfinden — nur sicherstellen, dass jede
einzelne `Autocmds/<plugin>.md` dieselbe Spaltenform benutzt wie die
Sammel-Datei, die daraus gespeist wird.

## 3. which-key-Regel (Keymaps-Dateien)

**Wenn** die Plugin-Quelle ein `which_key`-Modul/Setup hat (Beispiel-Fund:
`lua/<plugin>/bindings/which_key.lua`, oder ein `cfg.which_key.enable`-Flag),
**dann** ist eine `## which-key`-Überschrift Pflicht — kein Absatz in Notes,
keine beiläufige Erwähnung. Bereits etabliertes Phrasierungsmuster (aus
`dap.nvim.md`/`cascade.nvim.md`, wörtlich übernehmen, nur Gruppe/Präfix
anpassen):

```markdown
## which-key

`<leader>X` — "<Label>"-Gruppe, nur wenn which-key installiert ist und
<Bedingung, z.B. "cfg.which_key.enable (default on)"> gilt.
```

Bei Plugins mit **hergeleitetem** Präfix statt festem (images.nvim: die
Gruppe ergibt sich aus dem längsten gemeinsamen Präfix der konfigurierten
Keys, nicht aus einer festen Config-Option) den Mechanismus kurz nennen
statt die feste Phrase zu kopieren — das ist ein echter Unterschied, den
die Vorlage nicht verstecken soll.

**Wenn** die Quelle kein which-key-Modul hat, wird das nicht stillschweigend
ausgelassen, sondern eine Zeile in `## Notes` bestätigt die Abwesenheit
("Kein which-key — <Grund, falls bekannt>"), damit klar ist: geprüft und
verneint, nicht vergessen zu prüfen.

## 4. Extern-spezifisch: `[default]`/`[custom]`-Markierung

`ExternPlugins/Bindings/*` dokumentiert fremde Plugins mit eigenen
Werkseinstellungen — anders als bei Personal-Plugins ist hier "wurde das
hier überschrieben oder ist das Plugin-Standard" die zentrale Frage. Jede
Tabellenzeile (oder eine Status-Spalte, wie in `Telescope.md` bereits
vorgemacht) bekommt **[default]** oder **[custom]**. Für Dateien mit
mehreren Tabellen unterschiedlicher Herkunft (Leader-Keymaps vs.
In-Picker-Mappings vs. Extension-eigene Defaults, wieder `Telescope.md` als
Muster) reicht die pro-Tabelle-Überschrift aus §1, wenn eine ganze Tabelle
durchgehend denselben Status hat — dann genügt ein Satz direkt unter der
Überschrift statt einer Spalte pro Zeile.

## 5. `**Repo:**` — wenn der Dateiname nicht auf das Plugin führt (2026-09-02)

Optional, und für die meisten Blätter überflüssig. `:Bindings check` muss zu
jedem Blatt wissen, welches lazy.nvim-Plugin gemeint ist — davon hängt ab, ob
eine fehlende Registrierung überhaupt eine Aussage ist (nicht geladenes
Plugin = übersprungen) und wo der Quelltext liegt. Der Prüfer leitet das aus
dem Dateinamen ab, normalisiert um Groß-/Kleinschreibung, die
`nvim`/`vim`-Affixe und die Trennzeichen: `NeoTree.md` und `neo-tree.nvim`
treffen sich so, ebenso `Fugitive` und `vim-fugitive`.

Wo das nicht reicht, sagt es das Blatt selbst — als **zweite Zeile unter dem
Titel**, in genau dieser Form:

```markdown
# nvchad/ui — Keymaps

**Repo:** `NvChad/ui` — kurze Begründung, warum die Ableitung hier nicht trägt.
```

Der Slug darf `owner/name` oder nur `name` sein; gelesen wird das letzte
Segment. Die Zeile gewinnt immer gegen die Ableitung.

Drei Fälle im heutigen Korpus, und alle drei brauchen sie wirklich:

| Blatt | Repo | Warum |
| --- | --- | --- |
| `Blink` | `Saghen/blink.cmp` | keine Normalisierung führt von `Blink` auf `blink.cmp` |
| `Dap` | `StefanBartl/dap.nvim` | `dap.nvim` und `nvim-dap` normalisieren beide auf `dap` — mehrdeutig |
| `NvChadUI` | `NvChad/ui` | das Repo heißt schlicht `ui` |

Eine neue Zeile ist nur nötig, wenn `:Bindings check` das Blatt als
übersprungen führt, obwohl sein Plugin geladen ist — oder umgekehrt Befunde
für ein Plugin meldet, das gar nicht läuft. Alles Weitere in
[FEATURES.md](../../lua/bindings/usrcmds/bindings_explorer/docs/FEATURES.md),
„Wie ein Cheatsheet-Stamm zu seinem Plugin findet".

## 6. `**Nicht live:**` — wenn eine Tabelle gar nichts über diese Session sagt (2026-09-02)

Optional, und die meisten Tabellen brauchen es nicht. `:Bindings check`
vergleicht jede Keymap-Zeile mit dem, was gerade registriert ist. Drei Sorten
Tabelle beantworten diese Frage aber gar nicht — sie beschreiben etwas
anderes:

* **Abgeschaltete Plugin-Defaults.** `Keymaps/VisualMulti.md` listet, was
  vim-visual-multi mitbringt und was diese Config mit
  `VM_default_mappings = 0` abschaltet. Nie registriert, absichtlich.
* **Tasten einer fremden Oberfläche.** `Keymaps/Lazygit.md`s Spalte
  „Taste (in LazyGit)" nennt Tasten des LazyGit-TUI. Neovim registriert sie
  nie, egal ob LazyGit gerade läuft.
* **Verweistabellen.** `Keymaps/Telescope.md`s „Verwandte Keymaps außerhalb
  dieser Datei" zeigt auf Maps, die andere Blätter besitzen.

Solche Abschnitte sagen es selbst — als Zeile **direkt unter der
Überschrift**, vor der Tabelle:

```markdown
### Durch `VM_default_mappings = 0` deaktiviert

**Nicht live:** Plugin-Defaults, die diese Config abschaltet.
```

Der Text nach dem Marker ist frei und für Menschen; gelesen wird nur der
Marker selbst. Er gilt **bis zur nächsten Überschrift**, ein Blatt kann also
eine unprüfbare Tabelle neben fünf gewöhnlichen haben — `VisualMulti.md` tut
genau das.

**Nur die Live-Richtung ehrt ihn.** Die Zeilen werden weiter geparst,
erscheinen in `:Bindings browse` und zählen als Dokumentation für die
Gegenrichtung. Dieselbe Trennung, die `META_FILES` (`All.md`,
`Collisions.md`, `Overview.md`) macht.

**Warum nicht einfach die Spalte umbenennen.** Weil der Scraper eine
Klammer-Gruppe im Header absichtlich wegwirft: `Default-Mapping (Plugin)` und
`Taste (in LazyGit)` werden beide zu einem bekannten lhs-Header. Das ist
gewollt — der Korpus schreibt die Key-Spalte in einem Dutzend Varianten.
Einen Header umzubenennen, damit der Parser wegschaut, koppelt die Formulierung
an Parser-Interna und bricht beim nächsten Umformulieren. Ein Marker sagt,
was er meint.

Der Bericht zählt die markierten Zeilen und druckt sie unter den Befunden
(„16 documented rows marked …"), damit ein Opt-out nicht unsichtbar wird.

## 7. Retrofit — durchgeführt (2026-08-07)

Ursprünglich als 5-Schritt-Plan über vermutlich alle 137 Dateien angelegt —
die tatsächliche Prüfung ergab einen viel kleineren echten Korrekturbedarf,
als die anfängliche Compliance-Zählung (§0 oben) nahelegte:

- **Changelog-Überschrift**: fast der ganze Korpus (Personal wie Extern)
  hat schlicht **keine** datierten Changelog-Bullets zum Verschieben — nur
  `images.nvim.md` (beide Kategorien) und `fileops.nvim.md` (Usercmds +
  Autocmds) hatten welche, beide korrigiert. Die "0 von 30 haben eine
  eigene Überschrift"-Zahl aus §0 war korrekt, aber missverständlich: es
  gab meist nichts zu verschieben, nicht eine ignorierte Pflicht.
- **which-key (Personal/Keymaps, alle 30 Dateien geprüft)**: 5 Dateien
  bekamen eine echte, aus der jeweiligen Plugin-Quelle verifizierte
  `## which-key`-Sektion (`debugging.nvim`, `language.nvim`,
  `markdown.nvim`, `filetree.nvim`, `pickers.nvim`). 5 weitere hatten die
  Info schon, nur unformatiert (`documentation.nvim`, `insights.nvim`,
  `migrate.nvim`, `nvim-cmdlog`, `replacer.nvim`) — in die Überschrift
  gezogen. 6 bekamen eine explizite "geprüft, kein which-key"-Zeile in
  `## Notes` (`diff.nvim`, `reposcope.nvim`, `lib.nvim`, `mdview.nvim`,
  `open.nvim`, `runtime-analysis.nvim`) — bei `reposcope.nvim`/`open.nvim`
  ein echter Fund: beide haben einen ungenutzten Shared-Prefix
  (`<leader>r`/`<leader>o`), der sich anböte, aber nirgends gruppiert wird.
  2 waren schon konform (`color_my_ascii.nvim`, `sandbox.nvim`).
- **Usercmds/Autocmds-Tabellenform (Personal, alle Dateien überflogen)**:
  keine echten Abweichungen gefunden — Varianten wie `Invocation` statt
  `Command`, oder ein Verweis auf die Plugin-eigene, größere Command-
  Referenz statt einer Duplikat-Tabelle (`debugging.nvim`, `filetree.nvim`,
  `reposcope.nvim` — bei 50–64 Subcommands sinnvoll), sind bewusste,
  vertretbare Entscheidungen, keine Lücken.
- **ExternPlugins `[default]`/`[custom]`**: 34 von 38 Dateien hatten die
  Markierung schon. Die drei `Harpoon.md`-Dateien (Keymaps/Usercmds/
  Autocmds) nicht — zu Recht: harpoon.nvim selbst bringt weder eigene
  Keymaps noch Commands noch Autocmds mit, die hier "custom" überschreiben
  könnte, jede Zeile ist ohnehin komplett eigener Code. Bekamen je einen
  erklärenden Satz statt einer bedeutungslosen Zeilen-Markierung.

**Zwei Funde außerhalb des Formats, nicht behoben (nicht Teil dieser
Aufgabe)**: `Usercmds/Case.md` (seit 2026-09-04 `Usercmds/casedesk.nvim.md`,
umbenannt weil casedesk jetzt ein eigenes Repo ist und `:Bindings drift` den
Stamm gegen den Checkout-Namen paart) und `Usercmds/lib.nvim.md`/`MyPlugins.md`
sind bewusste dünne Verweis-Dateien (casedesk/lib.nvim haben ihre
Command-Referenz woanders) — kein Fehler. `Usercmds/dap.nvimMERGE.md` war
dagegen ein echtes Merge-Artefakt: eine ältere Fassung von `dap.nvim.md`,
die unter einem Tippfehler-Namen als eigene Datei überlebt hatte, mit drei
Sätzen, die in der aktuellen `dap.nvim.md` nicht mehr vorkamen (der
`languages/<lang>.lua`-Merge aus vormals getrennten `adapters/`/
`configurations/`-Dateien, `auto_install`s `:MasonInstall`-Verhalten,
`configurations`s `replace = true`) — gegen den echten dap.nvim-Quellcode
geprüft (alle drei noch zutreffend), in `dap.nvim.md` nachgezogen, die
Datei gelöscht (2026-08-09, ausgelöst durch einen `:Bindings check`-Fund).
