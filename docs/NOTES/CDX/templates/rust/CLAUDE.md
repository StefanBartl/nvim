# Rust-Projekt

- Vor "fertig": `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`.
- Der globale Hook prueft nach jedem Edit einer `.rs`-Datei `rustfmt --check`.
- Keine `unwrap()`/`expect()` in Library-Code; Fehler ueber `Result` propagieren.
- Neue Abhaengigkeiten nur nach Rueckfrage.
