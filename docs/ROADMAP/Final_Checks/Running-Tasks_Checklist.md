# Live-Test-Checkliste — nvim-Plugin-UX-Backlog (Stand 2026-09-29)

Alle Features/Fixes aus dem heutigen UX-Backlog-Chat (T1–T9 + der anschließende
ultracode-Review mit vier Nachbesserungsrunden), die eine echte, interaktive
nvim-Session brauchen — Lint/Tests laufen bereits automatisiert grün, aber Fokus-
Verhalten, Live-Refresh-Timing und visuelles Theming lassen sich nur am echten
Bildschirm beurteilen. Checkbox-Konvention: `- [ ]` offen, `- [x]` verifiziert.
Bei jedem Punkt eine Zeile `Notiz:` zum Eintragen von Beobachtungen.

---

## Wie starte ich das?

Alle Commits sind bereits auf `main` gepusht (lib.nvim, ui.nvim, filetree.nvim,
replacer.nvim, sessions.nvim, lsp.nvim, WKDBooks, nvim-config). Betroffene
Repos: `lib.nvim`, `ui.nvim`, `filetree.nvim`, `replacer.nvim`, `sessions.nvim`,
`lsp.nvim`.

1. Falls deine `lazy.nvim`-Specs NICHT direkt auf `$REPOS_DIR/repos/<plugin>`
   zeigen (sondern eigene Klone unter `~/.local/share/nvim/lazy/` halten):
   dort für die sechs Repos oben `git pull` laufen lassen.
2. nvim neu starten (oder `:Lazy reload <plugin>` für jedes der sechs).
3. Für die `:UI kit-preset`-Punkte unten: mit `:UI kit-preset rounded`
   (Standard) starten, damit der Vorher/Nachher-Kontrast beim Umschalten
   sichtbar ist.

---

## T3 — lsp.nvim: keine Autocompletion bei `---`

- [ ] In einer Markdown-Datei `---` tippen (z. B. Frontmatter-Trenner) — keine
      Plugin-Namen-Liste sollte mehr aufploppen.
  - Notiz:
- [ ] Zum Vergleich: "do" tippen — "documentation.nvim" (oder ähnliche
      Plugin-Namen) sollte weiterhin ganz normal vorgeschlagen werden
      (Regressions-Check, dass normales Tippen nicht kaputtgegangen ist).
  - Notiz:

---

## T4 — lib.nvim: Chip ohne "mehr"-Flackern (`messages`-Default jetzt `false`)

- [ ] Eine beliebige Chip-Notification auslösen (z. B. `:Hover all off`, oder
      eine gitsuite-Dashboard-Aktion) — nur der Chip rechts oben sollte
      erscheinen, kein zusätzliches Aufblitzen/Echo mehr unten am Bildschirm.
  - Notiz:
- [ ] Danach `:Lib notify last` bzw. `:Lib notify history` öffnen — der volle
      Text sollte trotzdem vollständig da sein (History ist unconditional).
  - Notiz:
- [ ] **Wichtig zu entscheiden:** `:messages` selbst bekommt den Eintrag jetzt
      NICHT mehr automatisch (globaler Default geändert, betrifft alle ~30
      Plugins die `lib.nvim.notify` nutzen). Prüfen, ob dir das für alle
      Fälle reicht, oder ob bestimmte Meldungen (z. B. git push/pull-Fehler)
      weiterhin zwingend in `:messages` stehen sollen — dafür müsste der
      jeweilige Call-Site `messages = true` explizit setzen (noch nicht
      fleet-weit auditiert, nur der globale Default wurde umgestellt).
  - Notiz:

---

## T5 — lib.nvim: Chip-Titel aus der ersten Zeile

- [ ] Eine echte mehrzeilige Fehlermeldung auslösen (z. B. gitsuite Dashboard
      `p`/`P` push gegen ein absichtlich veraltetes Remote, oder ein `git
      push` das lokal fehlschlägt) — Chip-Titel sollte die erste Zeile zeigen
      (z. B. "[gitsuite] docmap-desktop: push failed"), NICHT mehr generisch
      "[gitsuite] error"; der Rest der Meldung steht im Chip-Body darunter.
  - Notiz:
- [ ] Eine normale einzeilige Meldung auslösen (z. B. `:CmpReloadWords`) —
      Titel bleibt wie bisher "quelle level" (z. B. "lsp.completion.personal_names info").
  - Notiz:

---

## T9 — ui.nvim: Statusline-Hover Live-State + `:UI progress`

- [ ] `plugin_progress`-Segment in der Statusline hovern, während z. B.
      `:MyReposUpdate`, `:Reposcope update` oder ein `:Replace` mit Progress
      läuft — Tooltip zeigt den echten Live-Text, nicht nur die statische
      Beschreibung "Whichever plugin is currently running…".
  - Notiz:
- [ ] Maus auf dem Segment stehen lassen (NICHT bewegen), während sich der
      Progress ändert — Tooltip sollte sich alle ~1s selbst aktualisieren
      statt einzufrieren.
  - Notiz:
- [ ] Zwei Operationen gleichzeitig laufen lassen, falls möglich (z. B. zwei
      Repo-Updates parallel anstoßen) — Tooltip zeigt sie als getrennte
      Zeilen, nicht als einen verschmolzenen Textblock.
  - Notiz:
- [ ] Während des Hovers normal im aktuellen Buffer weitertippen (Insert-Mode)
      — der Cursor darf NICHT in den Tooltip springen, Fokus bleibt im Buffer.
  - Notiz:
- [ ] `:UI progress` direkt ausführen (auch ohne zu hovern) — zeigt Popup mit
      allen laufenden Operationen, oder "No plugin operation is currently
      running." wenn nichts läuft.
  - Notiz:

---

## T1 — ui.kit Theme-System (`:UI kit-preset`, neuer `hacker`-Preset)

- [ ] `:UI kit-presets` ausführen — Liste zeigt u. a. `ascii`, `dock_left`,
      `double`, `hacker`, `menu`, `minimal`, `rounded`, `solid`; aktiver
      Preset ist markiert.
  - Notiz:
- [ ] `:UI kit-preset hacker` ausführen — danach ein Popup/Toast auslösen
      (z. B. `:UI notify on` + irgendeine Notification, oder ein
      Confirm-Dialog) — sollte Matrix-Grün auf Schwarz + ASCII-Box zeigen.
  - Notiz:
- [ ] Direkt danach die Tabline anschauen — Chips sollten automatisch auf den
      flush/eckigen "hacker"-Style gewechselt haben (kombinierter Schalter),
      nicht mehr rounded.
  - Notiz:
- [ ] `:UI kit-preset rounded` (oder einen anderen Preset) danach ausführen —
      alles wechselt zurück, Tabline ebenfalls.
  - Notiz:
- [ ] Statusline-Hover-Tooltip (siehe T9 oben) während `hacker`-Preset aktiv
      ist erneut hovern — sollte jetzt AUCH grün/ASCII sein (vorher immer
      hart auf "rounded" gepinnt, unabhängig vom aktiven Preset).
  - Notiz:
- [ ] filetree.nvim Float-Preview (`<Tab>` im Tree bei `mode = "float"`)
      während `hacker`-Preset aktiv öffnen — auch themed.
  - Notiz:
- [ ] replacer.nvim `:ReplaceTest`-Panel während `hacker`-Preset aktiv öffnen
      — auch themed UND weiterhin normal editierbar (Cursor landet im Panel,
      Tippen in Pattern-/Sample-Zeile funktioniert).
  - Notiz:
- [ ] sessions.nvim Marks-Preview (falls genutzt) öffnen — themed, wenn
      ui.nvim installiert ist.
  - Notiz:

---

## Fokus-Diebstahl-Fixes (aus dem ultracode-Review, wichtig zu bestätigen)

- [ ] Statusline hovern, während im aktuellen Buffer normal weitergetippt
      wird — Fokus bleibt im Buffer, Cursor springt NICHT in den Tooltip
      (Duplikat von T9 oben, hier nochmal als eigener Fokus-Check).
  - Notiz:
- [ ] filetree.nvim im Float-Preview-Modus (`mode = "float"`): `<Tab>` auf
      einem Datei-Knoten drücken, dann normal im Tree weiternavigieren
      (j/k) während die Preview offen ist — Cursor bleibt im Tree, landet
      NICHT im Preview-Fenster.
  - Notiz:

---

## replacer.nvim / pickers.nvim — nur Doku-Ergänzung, zur Bestätigung (T6)

Kein Code geändert, nur `docs/BINDINGS.md` ergänzt — bereits vorhandene
fzf-lua-Features, die vorher nirgends dokumentiert waren:

- [ ] `:Replace` ausführen (fzf-lua-Backend, Standard wenn installiert) —
      `<S-Up>`/`<S-Down>` scrollt die Preview seitenweise.
  - Notiz:
- [ ] `<F3>` in derselben Preview drücken — togglet Zeilenumbruch (löst das
      "lange URL wird abgeschnitten"-Problem eleganter als Scrollen).
  - Notiz:
- [ ] `<F1>` drücken — öffnet das eingebaute fzf-lua-Cheatsheet mit allen
      aktiven Tasten (ersetzt den ursprünglich gewünschten eigenen
      Legend-Popup).
  - Notiz:

---

## Bereits verifiziert / kein Live-Test nötig

Diese Punkte aus dem ursprünglichen Backlog brauchten keine Code-Änderung
(Ist-Zustand war schon korrekt) — nur zur Vollständigkeit gelistet:

- **T2** (filetree.nvim blinkendes "unsaved changes"-Icon) — bestätigte,
  dokumentierte Neo-tree-Grenze, nichts zu testen.
- **T7** (runtime-analysis.nvim 7-Tage-Reminder) — läuft bereits über
  `lib.nvim.notify` mit `popup = true`, profitiert automatisch von T4 oben.
- **T8** (`:MyPlugins reclone` Popup) — Summary-Text vor Ja/Nein war schon
  vollständig, nichts geändert.

---

*Erstellt aus dem Chat-Verlauf der Session vom 2026-09-29 (UX-Backlog T1–T9 +
ultracode-Review mit vier Nachbesserungsrunden zu Fokus-Diebstahl,
Live-Refresh-Race-Condition und Chip-Titel-Truncation). Vollständige
Commit-Liste mit Hashes im Handover:
`docs/ROADMAP/handovers/myplugins_ux_backlog_HANDOVER.md`.*
