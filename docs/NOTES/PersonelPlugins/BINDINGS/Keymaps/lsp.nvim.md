# lsp.nvim — Keymaps Cheatsheet

Source: `C:\repos\lsp.nvim\lua\lsp\config\KEYMAPS.lua` (Katalog),
`C:\repos\lsp.nvim\lua\lsp\bindings\keymaps.lua` (Registrierung)
Konzept: `docs/ROADMAP/personal/lsp.nvim.md` (Source of Truth), §8.1

> **Stand 2026-08-23: keine Keymaps.** Der Katalog ist leer, `setup()` bindet
> nichts. Das ist Absicht, kein Versäumnis — die LSP- und Diagnostics-Keys
> liegen weiterhin in der Config, verteilt auf `bindings/mappings/lsp.lua`,
> `bindings/mappings/trouble.lua`, `config/inc_rename/`, die FzfLua-LSP-Maps
> und `lsp/diagnostics/keymaps.lua`. Die Hälfte davon hier zu beanspruchen
> gäbe denselben Tasten zwei Besitzer — genau das Problem, das das Dachplugin
> beseitigen soll. Sie ziehen in einem Schritt um (Migrationsphase 3).

Die heutige, verstreute Belegung ist in §1.3 des Konzeptpapiers vollständig
inventarisiert; sie steht bewusst nicht zusätzlich hier, damit es keine zweite
Liste gibt, die veraltet.

## Mechanismus (steht bereits)

Keymaps sind Daten: ein Eintrag pro Aktion im Katalog (`lhs`, `mode`, `rhs`,
`desc`, optional `requires`), `bindings/keymaps.lua` bindet, was nach den
User-Overrides übrig bleibt. Eine neue Map heißt: ein Katalogeintrag — nichts
ist an der Bindungsstelle fest verdrahtet.

| Config | Wirkung |
| --- | --- |
| `keymaps.enable = false` | Gar nichts binden |
| `keymaps.preset` | `"default"` / `"minimal"` / `"none"` |
| `keymaps.map.<action> = "<lhs>"` | Aktion auf eine andere Taste legen |
| `keymaps.map.<action> = false` | Diese Map weglassen |

Einträge mit `requires` werden vorerst übersprungen: eine Taste an eine
Integration zu koppeln („die Trouble-Variante nur, wenn Trouble geladen ist")
braucht die Integrations-Registry aus Phase 4. Überspringen ist die sichere
Richtung — eine nicht gebundene Taste fällt auf ihren bisherigen Besitzer
zurück, eine falsch gebundene nicht.

## which-key

Gebundene Prefixe werden als Gruppe gelabelt (v2- und v3-API), wenn
which-key.nvim installiert und `which_key.enable` gesetzt ist. Die Gruppen
werden aus den tatsächlich registrierten Keymaps abgeleitet, nicht aus einer
zweiten handgepflegten Liste — derzeit also keine.

## Changelog

- 2026-08-23: Repo-Gerüst nach `gates/NEW_PROJECT.md` angelegt. Keymap-
  Mechanismus vorhanden, Katalog leer.
