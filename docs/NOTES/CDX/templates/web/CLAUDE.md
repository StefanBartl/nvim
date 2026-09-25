# Web-Projekt (TypeScript)

- Paketmanager: pnpm. Vor "fertig": Lint, Typecheck und Tests des Projekts laufen lassen.
- Der globale Hook prueft Edits mit dem projektlokalen `prettier --check`
  (nur wenn in `node_modules` installiert).
- Neue Abhaengigkeiten nur nach Rueckfrage.
