# wkd — Live-Test-Checkliste (Stand 2026-09-29)

Alle Features/Fixes aus diesem Chat, die noch nicht live (sichtbarer Browser-Tab, echte
60fps-Bedienung) getestet wurden — in dieser Sandbox war das teils technisch nicht
möglich (`requestAnimationFrame` läuft bei ausgeblendetem Browser-Pane nicht/kaum, siehe
`Backlog/wkd_Completed.md` in wkdbook-wkd). Checkbox-Konvention: `- [ ]` offen, `- [x]`
verifiziert. Bei jedem Punkt eine Zeile `Notiz:` zum Eintragen von Beobachtungen.

**Wichtig für den Fight-Tab:** unbedingt auch auf der echten deployten Seite
(`https://stefanbartl.github.io/wkd/`) testen, nicht nur lokal per `pnpm dev` — der
CSP-Fix für die Charakterauswahl-Vorschau war in `pnpm dev` unsichtbar, weil der
Astro-Dev-Server die strikte CSP nicht durchsetzt wie das echte GitHub-Pages-Deployment.

---

## Wie starte ich das?

**Deployte Seite (empfohlen für die meisten Punkte, Pflicht für den CSP-Hinweis oben):**
einfach `https://stefanbartl.github.io/wkd/` im Browser öffnen. Alle Commits aus diesem
Chat sind bereits auf `main` gemergt und `.github/workflows/deploy.yml` deployt bei jedem
Push nach `main` automatisch — sollte also schon live sein (im Zweifel unter
`github.com/StefanBartl/wkd/actions` den letzten „deploy"-Run prüfen, falls die Seite
noch alt aussieht: GitHub Pages cached teils ein paar Minuten).

**Lokal per `pnpm dev`:** dein Haupt-Checkout unter `$REPOS_DIR/wkd` (nicht diese
Worktree-Session) steht noch auf dem alten Stand `9c6b500` — erst pullen:

```bash
cd $REPOS_DIR/wkd
git pull
pnpm install   # nur nötig, falls sich Dependencies geändert haben
pnpm dev
```

Dann `http://localhost:4321/wkd/` öffnen (Pfad-Präfix `/wkd/` nicht vergessen, sonst
404). **Für den Fight-Tab lokal:** Charakterauswahl-Vorschau/Filter werden dort
funktionieren, obwohl der zugrunde liegende CSP-Bug real war — der Dev-Server setzt die
CSP einfach nicht durch. Nur die deployte Seite ist der echte Test dafür.

Kein `pnpm build`/`pnpm preview` nötig zum Testen — beides nur für den reinen
Build-Check, nicht zum interaktiven Durchklicken.

---

## T13 — Mobile-Optimierung

- [ ] Header-Nav bei 375px und 768px (echtes Handy/Tablet oder Android-Emulator) — kein
      horizontaler Scroll, `[ tui ]`-Link nicht abgeschnitten.
  - Notiz:
- [ ] Kachel-Grid, Orbit, Tree, `/stack`, `ui.nvim`-Detailseite auf Mobile/Tablet — kein
      Overflow.
  - Notiz:
- [ ] Kachel-Hover-Flyout (T2) auf einem echten Touch-Gerät antippen — sollte (bekannt)
      strukturell nicht erreichbar sein, nur zur Bestätigung.
  - Notiz:
- [ ] Tree-Ansicht auf Mobile: horizontaler Scroll-Container ohne Swipe-Hinweis —
      spürbar/verwirrend, oder ok so?
  - Notiz:

---

## T14 — Grid/Tree/Orbit-Crossfade

- [ ] Zwischen Grid → Tree → Orbit → Grid wechseln — sanftes Einfaden, kein Layout-Sprung,
      keine kurz klickbaren/fokussierbaren Elemente der ausgeblendeten Ansicht.
  - Notiz:

---

## T15 — Bug-Sweep (7 Fixes) + Folgefix `prefs.ts`

- [ ] Skin-Präferenz auf `tui` stellen (z. B. einmal auf `/tui/` wechseln), dann zurück zur
      `modern`-Startseite, Tree-Ansicht öffnen, einen Plugin-Knoten anklicken — sollte zum
      `tui`-Skin führen (nicht zurück nach `modern`).
  - Notiz:
- [ ] Dasselbe für die Orbit-Ansicht (Spoke anklicken statt Tree-Knoten).
  - Notiz:
- [ ] Kategorie-Filter rein per Tastatur ansteuern (Tab zu einem Filter-Pill, nicht
      Maus-Hover) — Pill sollte die Neon-Hover-Farbe wechseln.
  - Notiz:
- [ ] `tui`-Skin: `modern` als Präferenz speichern, dann `/tui/` aufrufen — gelber
      Skin-Hinweisbalken erscheint, Sidebar/Footer bleiben an der richtigen Stelle (kein
      aufgeblähter Hinweisbalken, keine verschobene Fußzeile).
  - Notiz:
- [ ] `scripts/pull-demos.sh` einmal laufen lassen — `public/demos/` sollte sauber neu
      befüllt werden (alte, nicht mehr im `demo-assets`-Branch vorhandene Dateien
      verschwinden).
  - Notiz:
- [ ] Nächstes Mal, wenn ein VHS-Tape mit `scripts/tape-chapters.mjs` generiert wird:
      Kapitel-Liste prüfen, falls das Tape zwei Titel-Starts während einer `Hide`-Phase
      hintereinander hat.
  - Notiz:

---

## T7 — Fight-Minigame

- [ ] Fight-Tab öffnen — Charakterauswahl zeigt zwei Karten, je ein sauberes Sprite-
      Standbild (nicht gequetscht/als Streifen).
  - Notiz:
- [ ] Martial Hero ist farblich (grünlich getönt) klar von Samurai Mack unterscheidbar.
  - Notiz:
- [ ] Kämpfer wählen — Arena erscheint, beide Health-Bars bei 100 %, Timer bei 60.
  - Notiz:
- [ ] Bewegung: Pfeil links/rechts bewegt den Charakter erwartungsgemäß.
  - Notiz:
- [ ] Sprung: Pfeil hoch springt (nur wenn am Boden, kein Doppelsprung in der Luft).
  - Notiz:
- [ ] Angriff: Leertaste löst eine Angriffsanimation aus, danach geht der Charakter
      wieder normal in Idle/Run/Jump über (bleibt NICHT dauerhaft in der Angriffspose
      hängen).
  - Notiz:
- [ ] Kein „Phantom-Treffer": Health der Gegenseite sinkt nur, wenn wirklich kurz zuvor
      angegriffen wurde, nicht einfach beim Wieder-Annähern ohne neuen Angriff.
  - Notiz:
- [ ] KI-Gegner bewegt sich Richtung Spieler, greift gelegentlich an, springt selten.
  - Notiz:
- [ ] Match endet nach 60 s (Timer-Ablauf) oder bei K. o. — Ergebnistext („You win." /
      „You lose." / „Draw.") stimmt mit dem tatsächlichen Verlauf überein.
  - Notiz:
- [ ] Rematch-Button startet ein neues Match; Level-Farbfilter (Tag/Dusk/Nacht) wirkt über
      mehrere Rematches hinweg sichtbar unterschiedlich (zufällig gewählt).
  - Notiz:
- [ ] Escape während eines laufenden Matches drücken — zurück zu Grid, UND das Match
      pausiert wirklich (Health ändert sich danach nicht mehr im Hintergrund).
  - Notiz:
- [ ] Nach Escape/Tab-Wechsel: ins Suchfeld klicken, Leertaste/Pfeiltasten tippen —
      landet im Suchfeld, bewegt/attackiert NICHT den (pausierten) Kämpfer.
  - Notiz:
- [ ] Bewegungstaste (Pfeil links/rechts) gedrückt halten, während gehalten zu
      Grid/Tree/Orbit wechseln oder Tab wechseln, Taste dabei loslassen, dann zurück zu
      Fight — Charakter sollte NICHT von selbst weiterlaufen.
  - Notiz:
- [ ] Esc-Hinweis („Esc back to grid") ist auch auf dem Charakterauswahl-Screen sichtbar
      (bevor ein Kämpfer gewählt wurde), nicht erst in der Arena.
  - Notiz:
- [ ] Gesamteindruck Performance: läuft spürbar flüssig, keine Ruckler/Hänger.
  - Notiz:
- [ ] **Auf der echten deployten Seite** (`stefanbartl.github.io/wkd`) wiederholen,
      mindestens die Charakterauswahl-Vorschau (CSP-Fix) und einen kompletten Kampf.
  - Notiz:

---

*Erstellt aus dem Chat-Verlauf der wkd-Handover-Fortsetzungs-Session vom 2026-09-29
(T13/T14/T15/T7 + alle Nachfixe). Vollständige Historie/Details in
`$REPOS_DIR/WKDBooks/Development/wkdbook-wkd/Backlog/wkd_Completed.md`.*
