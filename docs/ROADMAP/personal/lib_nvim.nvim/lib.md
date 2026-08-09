# `lib.nvim`

## Research

- [ ] plenary: was fehlt um es zu ersetzen? zu optimieren? zu erweitern?
- [ ] libuv: eigenee, optimierte Implementierung

## Neue Features implementieren

> alle Cross-Platform!
> Alle neuen features in die `docs/lib.txt` `vimdoc` sowie die `@types/all_functions` sowie die `init.lua` eintragen

---

## `cross.run`: Helfer für explizit ergänzte Subprozess-Umgebung

Befund (siehe `docs/ROADMAP/personal/00_MISC.md` Punkt 1, ausführlich erklärt
in `WKDBooks/Development/wkdbook-Neovim/Referenz_Notes/00_cmdline/crossplatform/SubprocessEnv.md`):
ein Subprozess aus `vim.system()`/`vim.uv.spawn()`/`jobstart()` erbt exakt
Neovims eigene Prozess-Umgebung — nicht die einer interaktiven Login-Shell.
Betrifft heute mindestens `reposcope.nvim` (gh/curl/wget), `github_stats.nvim`,
`pdfport.nvim` (pandoc/pdftotext/ollama), `sandbox.nvim` (docker/podman/nerdctl),
`replacer.nvim` (ripgrep), `pickers.nvim` (fd/rg).

Aktueller Stand, geprüft: `lib.nvim.cross.run`/`run_argv` bieten dafür noch
**keinen** Helfer — kein automatisches Ergänzen von PATH-Lücken oder
bekannten Keyring-/Session-Variablen (z. B. `DBUS_SESSION_BUS_ADDRESS` unter
Linux). Jedes Plugin, das das braucht, müsste es sich einzeln bauen.

- [ ] `lib.nvim.cross.run` (oder ein neues Submodul, z. B. `cross.run.env`)
      um einen Helfer ergänzen, der eine sinnvoll ergänzte `env`-Tabelle für
      Spawn-Aufrufe zusammenstellt — mind. garantiert vollständiger `PATH`,
      optional bekannte Keyring-/Session-Variablen durchgereicht.
- [ ] Sobald umgesetzt: **`SubprocessEnv.md`** im WKDBook aktualisieren —
      Abschnitt 4 ("Die Gegenmaßnahme") verweist aktuell auf den offenen
      Punkt; nach der Umsetzung dort den `lib.nvim`-Helfer referenzieren
      statt der manuellen `vim.tbl_extend(...)`-Lösung, plus Link auf den
      fertigen `lib.nvim`-Changelog-Eintrag/README-Abschnitt.
- [ ] Die betroffenen Plugins (Liste oben) nach Fertigstellung auf den neuen
      Helfer umstellen, statt der bisherigen Einzellösungen (falls
      vorhanden) oder des bisherigen impliziten Env-Erbens.

---

