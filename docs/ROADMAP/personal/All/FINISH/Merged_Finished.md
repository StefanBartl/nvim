# Merged Roadmap -- Erledigt

Aus `MERGED.md` herausgenommene Tasks, sobald sie abgeschlossen sind.
Neueste zuerst. Gilt fuer alle `*.nvim`-Repos unter `C:/repos` plus diese
nvim-Config.

---

## 2026-08-25

### Git & Repo-Hygiene

- [x] **Branch auf `main` umstellen, wo noch nicht geschehen.**
      Einziges Repo abseits von `main` war `lsp.nvim`
      (`feat/diag-severity-completion-and-autocmd-groups`, ein unveroeffentlichter
      Commit). Fast-forward nach `main` gemergt, gepusht, Feature-Branch geloescht.
      Alle 31 Plugin-Repos stehen jetzt auf `main`.

### Dokumentation & Cheatsheets

- [x] **`.luarc.json` pro Plugin-Root anlegen.**
      War in allen 31 Repos bereits vorhanden. Bei der Pruefung fiel auf, dass
      `sandbox.nvim/.luarc.json` durch zwei nachgestellte Kommata kein gueltiges
      JSON war (LuaLS' eigener Parser toleriert das, jeder andere Consumer nicht) --
      korrigiert. Alle 31 Dateien parsen jetzt als striktes JSON.

### Security, Tests & CI/CD

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
