# Web-Projekt (TypeScript)

- Paketmanager: pnpm. Vor "fertig": Lint, Typecheck und Tests des Projekts laufen lassen.
- Der globale Hook prueft Edits mit dem projektlokalen `prettier --check`
  (nur wenn in `node_modules` installiert).
- Neue Abhaengigkeiten nur nach Rueckfrage.

## Fallen bei Svelte 5 und Browser-Tests

- **Ein `$effect` trackt alles, was der Aufruf in ihm liest.** Ruft er eine Methode,
  die selbst Zustand liest (`this.graph`, `this.doc`), hängt er an diesem Zustand:
  wird er durch die Antwort der Methode wieder angestoßen, fragt er für immer neu
  (gesehen: 167 Anfragen in unter einer Sekunde). Der Aufruf gehört in
  `untrack(() => ...)`, und der Effekt hört nur auf das, worauf er hören soll
  (`void app.snapshot?.rev`). Was „schon gefragt für Stand X“ heißt, gehört in die
  App, nicht in eine lokale Variable der Komponente (sie ist weg, wenn die Ansicht
  neu gezeichnet wird).
- **Ein Effekt, der ein Element fokussiert, läuft vor dem Element.** Der Fokus
  kommt nach dem Bild (`requestAnimationFrame`), sonst nimmt ihn ein schließender
  Dialog zurück.
- **Unit-Tests sehen keine `$effect`.** Die Svelte-Unit-Tests laufen im Server-Build,
  `$effect` läuft dort nie. Was ein Effekt tut, nur im Browser-Test absichern:
  **Anfragen zählen** (`page.on('request')`, 1 s warten, Anzahl prüfen), nicht nur
  das Ergebnis ansehen. Ein Effekt-Fehler zeigt sich als zu viele Anfragen, nicht
  als falsche Anzeige.
- **Playwright**: `keyboard.press('F')` sendet keinen Shift (`event.shiftKey` ist
  false), ein Mensch mit Umschalt+f ist `press('Shift+f')`. Tests, die den
  gemeinsamen Vault ändern, brauchen eindeutige Titel (ein Suchbegriff eines anderen
  Tests darf nicht passen).
- **Nach `pnpm build` ist das eingebettete Binary alt**, wenn die Oberfläche in ein
  Binary eingebettet wird (Tauri/Rust): erst das Binary neu bauen (bei `include_dir`
  genügt `touch` auf die einbettende Datei), dann den Browser-Test starten.
