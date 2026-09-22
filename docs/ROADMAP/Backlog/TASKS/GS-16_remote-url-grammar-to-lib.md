# GS-16 — Remote-URL-Grammatik nach `lib.nvim` heben

**Repos:** lib.nvim (`git/remote.lua` neu), gitsuite.nvim, github_stats.nvim,
documentation.nvim · **Nutzen** 4 · **Risiko** mittel · **Welle** 3
(Duplikate) · erledigt 2026-09-22.

## Ausgangslage

`gitsuite.features.browse.url` war laut eigenem Kopfkommentar rein (kein
`vim.api`, kein Prozess), wurde aber von mehr als gitsuite gebraucht:
`github_stats/statusline.lua`s `resolve_slug` parste Remotes mit einer
eigenen, nur GitHub-tauglichen Regex direkt über `vim.fn.systemlist`;
`documentation.nvim`s Docmap-Pipeline verlangte `--repo-url=`/`--branch=`
von Hand, obwohl die Antwort im `.git`-Verzeichnis bereits steht — `branch`
fiel dabei sogar still auf das wörtliche `"main"` zurück, unabhängig vom
tatsächlichen Standardbranch des Repos.

## Umsetzung, je Repo

- **lib.nvim** (`1db2bf6`): `lib.nvim.git.remote` (`parse_remote`,
  `host_kind`, `build`) — wortgleich aus gitsuites `url.lua` übernommen, rein,
  kein Prozess. Alle 15 Fälle aus `browse_url_spec.lua` wanderten nach
  `TESTS/git_remote_spec.lua` mit.
- **gitsuite.nvim** (`ad09a26`): `features/browse/init.lua` requiret jetzt
  `lib.nvim.git.remote` unter demselben lokalen Namen (`url`) — der Rest der
  Datei blieb unverändert. `features/browse/url.lua` und dessen Test
  komplett gelöscht, nichts blieb dort zu testen übrig.
- **github_stats.nvim** (`c9d2de0`): `statusline.lua`s `resolve_slug` nutzt
  jetzt `lib.nvim.git.remote_url` + `lib.nvim.git.remote.parse_remote` statt
  eigenem `vim.fn.systemlist` + Regex. Das Modul verfolgt weiterhin nur
  github.com — die anderen von `parse_remote` erkannten Host-Arten fallen
  einfach auf `slug = false` zurück, wie jedes Nicht-Repo auch.
- **documentation.nvim** (`369cd77`): `config.build()` leitet `repo_url`/
  `branch` jetzt automatisch aus dem echten Git-Remote/-Branch ab (via
  `lib.nvim.git.remote_url` + `lib.nvim.git.remote`), wenn weder Host, Repo-
  eigene `.docmap.json` noch CLI-Flag sie setzen. **`pcall`-abgesichert, nicht
  nur eine Capability-Prüfung:** `standalone/vim_shim.lua` (der Neovim-freie
  Parser-less-MVP-Build, reines PUC Lua) stellt weder `vim.system` noch
  `vim.fn.system` bereit — ein direkter Aufruf hätte den Standalone-Build
  beim ersten echten Lauf zum Absturz gebracht. Ein fehlendes Remote, ein
  fehlendes `git`-Binary und ein fehlendes `vim.system` degradieren jetzt
  alle gleich: `repo_url`/`branch` bleiben unverändert, wie vor dieser
  Änderung. `DEFAULTS.lua`s statisches `branch = "main"` entfernt — es
  gewann in `build()`s Merge-Reihenfolge immer gegen die Ableitung, hätte den
  neuen Code also tot gemacht; `core/scan.lua`s eigenes `opts.branch or
  "main"` ist jetzt die einzige Stelle, an der dieses Literal noch lebt.

## Nicht angefasst — dokumentierte Entscheidung

Die von `html.lua`s generiertem JS gebaute Blob-URL
(`repo + "/blob/" + branch + "/" + path`) ist weiterhin GitHub-only-Format
(keine GitLab-`/-/blob/`- oder Codeberg-`/src/branch/`-Grammatik) — das war
schon vor dieser Karte so und ist ein separater, nicht angefasster Bug: der
Plan-Umfang nannte nur "docmap leitet die Blob-URL aus dem echten Remote ab"
(Herkunft der URL, nicht ihr Format für andere Hosts).

## Tests

`TESTS/git_remote_spec.lua` (lib.nvim, 15 Fälle, wortgleich aus gitsuite
übernommen). `documentation.nvim`s `TESTS/config_file_spec.lua`: die zwei
Assertions, die `branch == "main"` direkt aus `build()` erwarteten, liefen
gegen einen anderen, weiterhin statischen `DEFAULTS`-Schlüssel um (sie
prüften eigentlich nie `branch` selbst, nur "Defaults überleben"); ein neues
echtes Git-Fixture belegt, dass `repo_url`/`branch` tatsächlich abgeleitet
werden und ein expliziter Override weiterhin gewinnt. Der Standalone-Build
selbst wurde nicht end-to-end nachgestellt (die Rocks `lfs`/`dkjson` sind in
dieser Umgebung nicht installiert) — stattdessen belegt, dass
`lib.nvim.git`s Legacy-Fallback (`vim.fn.system`) einen gewöhnlichen,
`pcall`-fangbaren Lua-Fehler wirft, wenn sowohl er als auch `vim.system`
fehlen — genau das, worauf dieser Code im Shim trifft.

## Ergebnis

Alle vier Commits einzeln CI-grün auf allen Systemen (lib.nvim zuerst,
`ci-verified` abgewartet, dann die drei Konsumenten, K-6). Lokale Suiten
grün: `LIB_TESTS_OK`, gitsuites volle `TESTS/gitsuite/`-Suite,
`github_stats.nvim`s volle Suite (inkl. Integration), `documentation.nvim`s
volle Suite (`DOCUMENTATION_TESTS_OK`). `stylua`/`luacheck` sauber in allen
vier Repos.

## Dokumentation mitgezogen

`lib.nvim/lua/lib/nvim/git/README.md` (verlinkt aus `remote.lua`s
Modul-Docstring); `documentation.nvim/docs/docmap.schema.json` (`repo_url`/
`branch`-Beschreibungen), `lua/documentation/@types/init.lua`,
`lua/documentation/config/DEFAULTS.lua` (Kopfkommentar: vier statt drei
bewusst fehlende Felder), `standalone/docmap.lua` (Asymmetrie
Standalone/Neovim-Host erklärt).

## Nachwirkung

`lib.nvim.git.remote` ist jetzt öffentliche API — jeder weitere Konsument,
der einen Git-Remote in einen Host/Owner/Repo zerlegen oder eine
Blob-/Repo-Web-URL bauen will, braucht keine eigene Regex mehr. `hover.nvim`
und `buffer-ctx.nvim` (Permalinks) sind laut Plan als Welle-5-Konsumenten
vorgemerkt, nicht Teil dieser Karte.
