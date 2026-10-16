Das Handover ist auf dem neuesten Stand und gepusht (tasks-vault `b93a127`). Seitdem hat sich nichts an meinen Repos geändert. `rules.nvim`, `rules-vault` (`draft/go`) und der Vault sind alle mit `origin` synchron.

Es steht unter `rules.nvim/handovers/rules-authoring-stand-2026-10-14_HANDOVER.md`, Abschnitt "Stand 2026-10-16". Dort stehen auch der Text zum Reinkopieren in einen neuen Chat und die Hinweise für die nächste Sitzung.

## Zusammenfassung

**Gesamtstand:** `rules.nvim` `main` = `c14ed80`, 1296 Specs, CI auf allen fünf Jobs grün (Ubuntu, macOS, Windows, `luacheck`, `stylua`).

**Fertig in diesem Chat:**
- **Engine und Vertrag:** `rules-export/1` und `rules-ops/1` mit `new`, `set`, `retire`, `reinstate`, `move` und den Waiver-Operationen `waive`, `renew`, `remove`. Dazu `rules-export.d.ts`, aus dem JSON-Schema erzeugt und in der CI geprüft.
- **Konfiguration und Sicherheit:** `.rules.json` mit Rangfolge, Vault-Auflösung (`vault`, `$RULES_VAULT`, `@vault/<name>`) und das Vertrauens-Gate. Lua-Prädikate laufen nur aus `setup()`, dem Aufruf und dem Vault.
- **Neovim:** `:Rules new/set/retire/reinstate/move/list/waive/renew/unwaive`, das Formular mit konfigurierbaren Tasten und `:RulesVault` mit allen Verben samt `create`.
- **Vault:** Die Prüfung `check` erkennt stillgelegte IDs, leere Regeldateien und Merge-Konflikt-Marker, dazu optional ID-Lücken (`--gaps`). Die CI-Vorlage prüft den Checkout auf `eol=lf`.
- **rules-vault:** Das Repo `StefanBartl/rules-vault` (privat) ist angelegt. `main` enthält den Import beider Regelwerke (652 Dateien, byte-identisch belegt), `draft/go` die 53 Go-Entwurfsregeln. In den WKDBooks sind die alten Ordner entfernt und 166 Verweise in 6 Repos umgeschrieben.
- **Reviews:** Zwei unabhängige Review-Runden mit Reasoning `high`, zusammen 38 reproduzierte Funde, alle behoben. Die Runde zu den ersten 21 Commits ergab 29 Funde (2 hoch: Sicherheit, `create` in bestehenden Vault), die Runde zu den Feature-Commits davor 9. Die Round-Trip-Abweichungen der Layouts gingen von 21 auf 0.
- **Regelableitung aus den WKDBooks:** Verfahren festgelegt, Go-Pilot erfolgreich. Die Stichprobe ergab 13 gut, 5 ändern, 1 verworfen, das sind 5 % Ausschuss bei 25 % Grenze.

**Offen bei dir:**
- `$RULES_VAULT` setzen.
- Die 33 Go-Regeln auf `draft/go` durchsehen, dann merge ich nach `main`.
- Billing der Vault-CI klären.
- `C:\x` aufräumen.
- Zwei Entscheidungen: ob `retire` die Stelle in `_retired` festhält, und wohin die 598 Migrationsnotizen gehören.
- Die Agenten-Entscheidungen bestätigen (Waiver-Format, Projektwahl, Trennlinie `---` und weitere).

**Offen für Agenten:**
- Ein Review der acht Commits ohne unabhängiges Review.
- Die Prompt-Vorlagen im nvim-config nachziehen.
- Die Go-Notizen korrigieren.
- Den Agent-Strang (`agent-plan-validate`).
- Die Regelableitung für C++, JavaScript/Node und OS/CLI.
- `appkit` und `rules-desktop`.
- Die Aufräumarbeiten auf lib.nvim-Seite.

**Commits dieses Chats** (⭐ = ultracode-Review, ✅ = Review mit höherem Reasoning, Fix-Commit bereits geprüfter Commits oder Doku, ohne Haken = noch ohne Review). Gekürzt:

| Repo | Commit | Inhalt | |
| --- | --- | --- | --- |
| rules.nvim | `dbfe5f5` … `925b85a` (8) | Review-Fixes, `:Rules new/set/retire/move/list` samt Formular | ⭐ |
| rules.nvim | `c910aeb`, `282b510` … `71034fc` (7); `d03b847` … `71568b9` (8), `b7ce574`, `146df90` | Fixes des ersten Reviews; `.rules.json`, Vault-Auflösung, `:RulesVault`, CI-Vorlage, `new`-Platzierung | ✅ Review (Reasoning high) |
| rules.nvim | `3b95973` … `65f2755` (15); `25db009`, `c14ed80` | Etappen A bis D, 9 weitere Fixes | ✅ Fix-Commits geprüfter Commits, CI grün |
| rules.nvim | `51ff75b`, `5f60e2e`, `f87be18`, `2651616`; `4eee477`, `abc1e6b`; `2d14304`, `388d88a`, `07e47fc`, `5064b26` | Waiver, `reinstate`, `keys.form`, `waive`-Befehle | ✅ Review im Workflow (Reasoning high) |
| rules.nvim | `6335ef4`, `73f79be`, `6c0f580`, `a76624e`, `e8c6d05`, `ee3201e`, `810cf17`, `100bfbb` | `["severity"]`, Round-Trip-Spec, `retire`-Meldung, ID-Lücken, `rules-export.d.ts` | kein Review, nur Agenten-Selbstprüfung und CI |
| rules-vault | `569a494`, `4102086`; draft/go `842a336` … `027090a` (13) | Gerüst, Import, 53 Go-Entwurfsregeln | kein Review für draft/go; check, catalog, roundtrip grün |
| Pfadverweise in 6 Repos | `5917c25`, `026f8070`, `a3fe8e8a`, `16228c7`, `81aa476`, `82385c1`, `55dc9441`, `aab4db9c` | Verweise umgeschrieben, `RULES_VAULT`, alte Ordner entfernt | ✅ Doku, Link-Prüfung, Hash-Vergleich |
| tasks-vault | `1eae90e` … `e05ee0b`, `7329906`, `dbd701e`, `b93a127` | Handover, Spezifikation, Verfahren, Stichprobe, Review-Bericht, Task-Abschlüsse | ✅ Doku |
