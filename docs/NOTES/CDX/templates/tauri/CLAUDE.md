# Tauri-Projekt (Rust-Backend + Web-Frontend)

- Backend (`src-tauri/`): `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`.
- Frontend: pnpm; Lint/Typecheck/Tests des Projekts vor "fertig".
- Der globale Hook prueft `.rs` (rustfmt) und Frontend-Dateien (lokales prettier).
- `cargo tauri build`/`dev` nicht selbst starten, ausser ausdruecklich gewuenscht.
- Neue Abhaengigkeiten (crates/npm) nur nach Rueckfrage.
