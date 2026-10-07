# Usrcmd-Hilfe-Float: Rollout-Aufwand ueber alle eigenen Plugins (2026-10-07)

Messung: echte Sitzung (nvim-config, alle lazy-Plugins geladen), `composer.registry()` und
`nvim_get_commands()` ausgelesen. Plan: tasks.nvim `lib.nvim/usrcmd-help-float-cheatsheet`;
Handover: `../handovers/usrcmd-help-float_HANDOVER.md`.

## Bestand

| Was | Zahl |
|---|---|
| Composer-Verben (davon `Ft`/`Filetree`, `Sbx`/`Sandbox` je Doppelregistrierung) | 69 (nur `:Clipboard` hat `help = true`) |
| Routen | 1152 (ohne die Doppelregistrierungen ca. 900) |
| Routen **ohne** `desc` | 290; eindeutig ca. 181 |
| Verben mit Gruppen (zweite Ebene) | 30 mit 157 Gruppen |
| Args (eindeutig) | 667; davon 487 frei, 84 mit Enum/`values` (87 verschiedene Mengen, 927 Werte) |
| Flags (eindeutig) | 318, nur **171 verschiedene Namen** (geteilte Tabellen, z. B. Replace/Surround/Wrap) |
| kv-Paare (eindeutig) | 142, nur **52 verschiedene Keys** |
| Args/Flags/kv/Enum mit `desc` / `enum_desc` | 0 (die Felder sind neu) |
| Nicht-Composer-Commands | 305, davon ca. 150 Fremdplugins (Dap*, Noice*, Neotest*, Mason, Telescope, ...), ca. 100 eigene flache Commands, ca. 55 aus Presets/Generatoren |

Routen ohne `desc`: `Ft`/`Filetree` 109 (doppelt gezaehlt), `Debug` 36, `File` 22, dazu je 1 bei `Diff*`,
`Replace`/`Surround`/`Wrap`, `LspDoctor`, `LspMdHints`, `Recommender`. Alle anderen Verben sind vollstaendig beschrieben.

## Aufwand (ein Mensch/Agent, inkl. Tests und Commits)

| Stufe | Inhalt | Aufwand |
|---|---|---|
| 0 | `composer.setup({ help = { enable = true } })` in der Config: alle 69 Verben bekommen das Float, Plugins bleiben unberuehrt | 5 min (+ Probierphase) |
| 1 | fehlende Routen-`desc`: Filetree (Texte liegen in README/Help, ggf. ableitbar), Debug, File, 9 Einzelfaelle | 4-5 h |
| 2 | Flags: 171 Namen. Mit einem kleinen **Vokabular** (`help.vocab.flags = { dry = "...", force = "..." }`, ca. 1-2 h Feature) statt 318 Einzel-`desc` | 3-4 h (ohne Vokabular 5-6 h) |
| 3 | kv: 52 Keys, gleiches Vokabular | 1-2 h |
| 4 | Enum-Werte: nur nicht selbsterklaerende (ca. 30 % von 927, Theme-/Filetype-Listen ausnehmen) | 4-5 h |
| 5 | freie Args: 447 von 487 sind selbsterklaerend (`path`, `name`, getypt); ca. 40 brauchen eine `desc` | 1 h |
| 6 | `:UI`/`:Theme` (ui.nvim): anbinden 2 h oder auf Composer migrieren ca. 1 Tag | 2 h-1 d |
| 7 | flache eigene Commands (lsp.nvim 47, gopath 10, replacer 9, buffer-ctx 6, runtime-analysis 6, nvim-config 16, ...) in vorhandene Verben falten | ca. 4 Tage, **nicht empfohlen** (Umbenennungen, kaum Gewinn: meist Blatt-Commands ohne Optionen) |

Gesamt:
- **Minimum** (Stufe 0 + 1): ca. 0,5 Tag.
- **Gute Qualitaet** (0-6, ohne 7): ca. 2 Tage.
- Repos mit Aenderungen fuer Stufe 1-5: ca. 15 (jeweils Commit/Push); Stufe 0 braucht keinen.

## Empfehlung
1. Stufe 0 jetzt (global an), Stufe 1 danach (macht die Floats ueberhaupt erst lesbar).
2. Vokabular-Feature, dann Stufe 2/3 in einem Rutsch.
3. Enums und freie Args nur dort, wo ein Wert nicht fuer sich spricht.
4. `:UI` entscheiden; flache Commands (Stufe 7) nicht anfassen.
