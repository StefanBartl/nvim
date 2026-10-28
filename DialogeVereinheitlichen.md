Ich habe alles zusammengestellt. Die CI ist aber nicht grün: Von 21 gepushten Repos sind 8 rot, 3 hängen in der Queue, 1 läuft noch. Reparieren konnte ich nichts mehr. Die Test-Logs gaben im Tail nur Aufräum-Zeilen her, und ein neueres stylua ließ sich nicht installieren (Download wurde blockiert). Der Stand folgt unten zum Einfügen in den anderen Chat.

---

# Übergabe: Dialoge auf den gemeinsamen Dialog (`lib.nvim.ui.dialog` / `ui.kit`)
Stand 2026-10-28. Alle Commits liegen auf `main` des jeweiligen Repos.

## 1. Entscheidungen und Ziel
- Alle Nutzerdialoge (Ja/Nein, Auswahl, Eingabe) laufen über `lib.nvim.ui.dialog`, optisch wie `d` in filetree.
- Das Kit liegt nur noch in `lib.nvim/lua/lib/nvim/ui/kit/`. `ui.nvim/lua/ui/kit/*` sind Re-Exports.
- `dialog.yesno` ist eingeführt (Nein zuerst und vorgewählt, `n`/`y`). filetree-Stand-in ist entfernt. Für altes ui.nvim gibt es keinen Schutzcode, nur Docs und Health-Check.
- API: `confirm`, `ask`, `choose(msg, choices, default, cb, msg_type, opts)`, `input`, `yesno(question, yes_label, cb, opts)`. Neu: `choose` nimmt als sechstes Argument `opts.title` und `opts.kind`.
- Der Callback läuft genau einmal und nie vor Rückkehr des Aufrufs. Testdoubles müssen eine truthy Surface liefern (`return {}`).

## 2. Commits
**Reviewt (xhigh-Review, danach gefixt):**
- lib.nvim: Kit-Fixes, nativer Dialog, `yesno`, Health (603f564).
- ui.nvim: Kit als Re-Exports (bfa305a).
- tasks.nvim: 53be983, d992bbf, 7a59c63.
- filetree.nvim: 028defd, 70ef692, 8ca2fc8, 81870b9, b12b2e9, 65fdacc.

**Danach gepusht, nicht reviewt** (nur lokal gegen die Baseline-Fehlerliste geprüft):

| Repo | Commit | Änderung |
|---|---|---|
| casedesk.nvim | a5f0220 | AI-Bestätigungen, deutsche Buttons |
| cmdlog.nvim | 4b6c589 | Delete-Frage |
| rules.nvim | f49c414 | `:Rules`-Fragen |
| github_stats.nvim | 6f69ba5 | Fetch-Frage |
| nvim (Config) | 25bee9e9 | `:Execute`, `:MyNative`, `:MyPlugins` |
| buffer-ctx.nvim | 94db77b | Guard-Template asynchron |
| color_my_ascii.nvim | 6263fe0 | Overwrite-Frage |
| data.nvim | fd17345, ad39769 | Preview-Dialog; ad39769 repariert meinen Syntaxfehler |
| docmap.nvim | 6845783 | `:DocMap`-Angebote |
| gitsuite.nvim | 6686fd7 | Conflict, Plugins |
| images.nvim | 242fe7b | Delete, Calibrate, Paste |
| insights.nvim | dfc0ae1 | Cache-Offer |
| markdown.nvim | 0f65e37 | Heading-Gap-Frage |
| pickers.nvim | d62e369 | Browser-Delete |
| sandbox.nvim | 52c8c22 | destruktive Bestätigungen |
| sessions.nvim | 549fdc1 | Pinned-Removal und `delete-stale`, asynchron |
| ui.nvim | 1e1b59b | Tabufline-Verwerfen-Fragen |
| lib.nvim | fd91bd7 | Progress-Abbruch (float, kit), `deps/view.lua` |
| ui.nvim | 5756594 | Einzel-Close eines geänderten Buffers: Save/Discard/Cancel statt `confirm bd` |
| lib.nvim | dcb94d6 | `choose` mit `opts.title`/`opts.kind` |
| ui.nvim | 0550107 | Titel „Unsaved changes“ in den Tabufline-Dialogen |

**Vault (`tasks-vault`):** 2f64577, 776d70f, 3129923, 02d5ecc, 4d03f2b und der Commit „bq-close-all … done“ (Hash nach Rebase nicht mehr notiert; CI-Run auf 6849ef3).

## 3. Tasks
- **Erledigt (done):** `dialoge-auf-ui-kit` in tasks.nvim, filetree und, per 02d5ecc, in casedesk, cmdlog, rules, github_stats, nvim-config, buffer-ctx, color_my_ascii, data, docmap, gitsuite, images, insights, markdown, pickers, sandbox, sessions, ui.nvim. Außerdem `ui.nvim/bq-close-all-live-pruefen` (war ein Tastenfehler `bg` statt `bq`).
- **Angelegt:** `lib.nvim/dialog-yesno-handle-ein-kit`, `ui.nvim/kit-confirm-cancel-und-fokus-dedup`, `filetree.nvim/dialog-stand-in-ohne-ask`, `ui.nvim/bq-close-all-live-pruefen` (inzwischen geschlossen).

## 4. Offen
- **Neu offen:** CI-Fehler in 8 Repos (Abschnitt 6), das ist der wichtigste Punkt.
- **Offene Tasks:**
  - lib.nvim `deps/install/init.lua` (`install.run`) und `deps/project/init.lua` (`project.install`) haben noch `vim.fn.confirm`. Beide geben synchron einen Wert zurück; für `dialog.yesno` braucht der Vertrag einen Callback, die Aufrufer müssen mit. Der Task `lib.nvim/dialoge-auf-ui-kit` bleibt offen.
  - `ui.nvim/kit-lazy-load`, `kit-dialog-hook-fuer-tests`, `kit-vim-ui-provider`
  - `nvim-config/vim-ui-provider-aktivieren`
  - `testing.nvim/guard-kit-dialoge`
  - `rules.nvim/regel-keine-nativen-prompts`
  - `lib.nvim/dialog-yesno-handle-ein-kit` (der `yesno`-Teil ist erledigt)
  - `ui.nvim/kit-confirm-cancel-und-fokus-dedup`, `filetree.nvim/dialog-stand-in-ohne-ask`
  - Ziel-Task `ALL/alle-user-dialoge-auf-ui-kit-vereinheitlichen`
- **`kit.sync`** existiert noch (deprecated, außerhalb der Kit-Docs keine Aufrufer). Entfernen ist nicht entschieden.
- **Veraltet:** `lib.nvim/ui-nvim-lua-ui-kit-…weichen` ist durch den Kit-Umzug erledigt, ich habe ihn nicht aktualisiert.
- **Live-Check:** filetree `d`, `<Esc>` im Fortschritts-Float, Marks-Editor und `<leader>bq` sind ok. Noch zu prüfen: `<leader>bc` mit einem geänderten Buffer nach dem Update (jetzt Dialog „Unsaved changes“ mit Save/Discard/Cancel) und `:Session delete-stale` mit einer echten stale Session.

## 5. Nicht reviewt
Alle Commits aus der zweiten Tabelle in Abschnitt 2. Genauer ansehen würde ich:
- sessions: asynchrone Pinned-Removal-Fragen (ein zweites `:w` stapelt keine zweite Frage, eine verspätete Antwort greift auch bei geschlossenem Menü).
- ui.nvim Tabufline: `close_bufs(bufnrs, done)` gibt `nil` zurück, solange die Frage offen ist; `close_n_buffers` ebenfalls.
- buffer-ctx und nvim-config: Aufrufer wurden auf Callbacks umgebaut.

## 6. CI-Stand (jeweils letzter Push-Run auf `main`)

**Grün:**
- lib.nvim (Runs 831 und 830 auf dcb94d6 und fd91bd7)
- github_stats (6f69ba5), color_my_ascii (6263fe0), docmap (6845783), gitsuite (6686fd7)
- markdown (0f65e37), pickers (d62e369), sandbox (52c8c22), sessions (549fdc1)

**Rot:**

| Repo (Commit) | Befund |
|---|---|
| ui.nvim (5756594, Run 316) | luacheck und stylua grün; `tests` auf ubuntu, macos und windows rot, Ursache nicht gelesen. Run 317 auf 0550107 läuft noch. |
| filetree.nvim (65fdacc, Run 370) | lint grün; `tests` auf allen drei OS rot, Ursache nicht gelesen |
| cmdlog.nvim (4b6c589, Run 88) | lint grün; `test` auf allen drei OS rot, Ursache nicht gelesen |
| insights.nvim (dfc0ae1, Run 135) | stylua und luacheck grün; `tests` auf allen drei OS rot, Ursache nicht gelesen |
| images.nvim (242fe7b, Run 220) | `lint`: stylua-Format rot; `test` auf allen drei OS grün |
| data.nvim (ad39769, Run 55) | `stylua` rot; luacheck und Tests grün |
| buffer-ctx.nvim (94db77b, Run 124) | `stylua + luacheck` rot (luacheck übersprungen); Tests grün |
| nvim (25bee9e9, Run 1478) | `stylua` rot (betroffen u. a. `TESTS/dialogs_spec.lua`); luacheck grün |

Vermutung zu den vier stylua-Fehlern: Die CI nutzt ein neueres stylua als mein lokales 0.20 und formatiert meine neu geschriebenen Specs und Code-Blöcke anders. Das wäre dasselbe Muster wie bei filetree 81870b9. Bei den vier Repos mit roten Tests habe ich noch nicht nachgesehen, ob die Fehler schon vor meinen Commits da waren.

**In der Queue (private Repos, ohne Ergebnis):** tasks.nvim (7a59c63, Run 168 `queued`), casedesk (a5f0220, Run 303 `pending`), rules (f49c414, Run 86 `queued`). tasks-vault (Run 417) ist ebenfalls `queued`.

## 7. Nächster Schritt
1. Die vier stylua-Fehler (images, data, buffer-ctx, nvim) beheben. Dafür bräuchte ich entweder die Formatierung aus den CI-Logs oder ein stylua mit der CI-Version. Dass ich das binäre Nachladen nicht machen konnte, liegt an der Freigabe, nicht am Code.
2. In ui.nvim, filetree, cmdlog und insights je die rote Test-Stelle aus dem CI-Log lesen und fixen.
3. Danach die CI-Läufe erneut prüfen und die drei Queue-Repos bei dir ansehen (Runner oder Abrechnung?).

Soll ich damit weitermachen? Für Punkt 1 brauche ich deine Freigabe, das aktuelle stylua herunterzuladen. Sonst gehe ich die roten Tests zuerst an.
