# Profile: `full` und `enterprise`

Die Config kennt zwei Plugin-Sätze. `full` ist alles. `enterprise` ist für Rechner in einer Firma (Tricentis-Workstation):
keine KI-Plugins, die Buffer-Inhalte an ein LLM schicken, und keine Clients fremder APIs, die mit Tokens arbeiten.

| Datei | Inhalt |
|---|---|
| [mechanik.md](mechanik.md) | Wie das Profil bestimmt wird, was beim Umschalten passiert, beteiligte Dateien |
| [wartung.md](wartung.md) | Ein Plugin in `enterprise` abschalten oder wieder zulassen, Tests, Fallen |
| [git-self-hosting-konzept.md](git-self-hosting-konzept.md) | Symlink auf die Task `ALL/git-self-hosting-konzept` im tasks-vault (Firmen- und Privatdaten trennen) |

## Bedienung

```vim
:Profile                " aktives Profil und Herkunft (env, state, default)
:Profile enterprise     " für den nächsten Start merken
:Profile full
```

Dauerhaft pro Rechner, gewinnt über `:Profile`:

```powershell
setx NVIM_PROFILE enterprise
```

Das Profil gilt ab dem **nächsten Start**: Die Plugin-Specs werden einmal beim Start ausgewertet.

## Was `enterprise` abschaltet

Die Liste ist `ENTERPRISE_OFF` in `lua/plugins/personal/core/source.lua`:

| Plugin | Warum |
|---|---|
| `ai.nvim` | schickt Buffer-Inhalte an ein LLM (Claude, Ollama) |
| `buffer-ctx.nvim` | baut Kontext für KI-Prompts |
| `github_stats.nvim` | ruft die GitHub-API mit `GITHUB_TOKEN` auf |
| `reposcope.nvim` | durchsucht GitHub über die API |

Bleibt aktiv: alles andere, auch `mdview.nvim` mit seinem Build (`npm ci && npm run build:go && npm run build`).
`pdfport.nvim` bleibt geladen; seine Backends `ollama` und `claude` laufen über ai.nvim und schlagen ohne es sauber fehl,
die lokalen (`pdftotext`, `pdfplumber`, …) gehen weiter. Die Builds über `:MyNative` laufen nur auf Befehl und sind vom
Profil unabhängig.

## Umschalten und nvim-data

- `full` → `enterprise`: Beim ersten Start danach löscht lazy die abgeschalteten Plugins aus `nvim-data/lazy`
  (einmal, im Hintergrund, mit Meldung).
- `enterprise` → `full`: lazy klont die fehlenden Plugins beim Start von selbst (`install.missing`).
- `lazy-lock.json` bleibt beim Umschalten gleich: lazy behält die Einträge abgeschalteter Plugins.
