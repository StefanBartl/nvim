# GS-18 — README-Doku: Rest, `:DocMap`, vimdoc-Abgleich

**Repo:** gitsuite.nvim · **Nutzen** 2 · **Risiko** niedrig · **Welle** 4
(Dokumentation) · erledigt 2026-09-22.

## Umsetzung

Die restlichen sieben Fassung-3-Seiten angelegt:

- `what-you-get.md`: acht Punkte, alle gegen echten Code verifiziert (der
  diff3/zdiff3-Parser, die `nvr`-Brücke, die Option-Validierung).
- `around-it.md`: Abgrenzung gegen jedes einzelne Nachbarplugin
  (gitsigns, diffview, neogit, fugitive/rhubarb/git-conflict.nvim/
  lazygit.nvim, reposcope.nvim, insights.nvim) — nicht pauschal, sondern
  je Plugin die tatsächliche Beziehung (adaptiert / ersetzt / kein Bezug).
- `scope.md`: "Does" (die acht `:Git`-Familien) und "Does not" (keine
  Staging-UI, kein Side-by-Side-Diff-Engine, kein Interactive-Rebase, keine
  Repo-übergreifende Ansicht, keine Hosting-API).
- `architecture.md`: die Adapter-Registry (`resolve`/`resolve_first`,
  `package.loaded`-Check statt `require`), die K-5-Konsumenten-Regel
  (Abhängigkeit zeigt nach unten oder bleibt weich, nie zurück) mit den drei
  konkreten Fällen, in denen das schon verhindert wurde, `gitsuite.events`
  als dieselbe Regel für "auf gitsuite reagieren" statt "von gitsuite
  adaptiert werden".
- `health.md`: alle vier Abschnitte von `:checkhealth gitsuite`
  zeilenweise, aus `health.lua` gelesen.
- `cross-platform.md`: argv-only-Git-Aufrufe (kein Shell-Quoting-Problem),
  Text- vs. Byte-Erfassung, der `nvr`-Roundtrip auf Windows als offen
  benannt statt verschwiegen.
- `CONTRIBUTING.md`: Ground rules (inkl. der K-5-Regel), Projekt-Layout,
  "Adding a `:Git` scope"/"Adding an adapter", lokaler Testbefehl mit
  `LIB_NVIM_DIR`/`DIFF_NVIM_DIR`/`PLENARY_DIR`.

## `:DocMap` geprüft

`documentation.nvim`s `config.build()` gegen dieses Repo laufen lassen
(`config.build(root)`, kein `.docmap.json` vorhanden): erkennt
`lua/gitsuite` als Quelle automatisch, kein Setup nötig.
**Nebenbefund, der GS-16 belegt:** `repo_url`/`branch` wurden dabei
tatsächlich vom echten Remote/Branch dieses Checkouts abgeleitet
(`https://github.com/StefanBartl/gitsuite.nvim`, der reale aktuelle
Branch) — die erste echte End-to-End-Bestätigung von GS-16s
Ableitungslogik gegen ein reales Repo.

## `doc/gitsuite.txt` gegen die Seiten abgeglichen

Der Vimdoc-Inhalt war bereits korrekt und aktuell — kein Neuschreiben,
nur drei kurze Querverweise ergänzt (Requirements-, Installation- und
Configuration-Abschnitt verweisen jetzt auf die jeweils ausführlichere
`docs/*.md`-Seite).

## `NEW-14` geprüft

Kein Verweis auf `docs/ROADMAP.md` oder das Wkdbook in irgendeiner der 14
neuen/geänderten Dateien (per Grep verifiziert).

## Ergebnis

Gemeinsamer Commit mit GS-17 (`ec3af5a`), CI grün auf allen drei Systemen.
Details zum Commit und den fünf Pflichtseiten: [GS-17](GS-17_readme-doku-pflichtseiten.md).
Damit ist Welle 4 (Dokumentation) **komplett**.
