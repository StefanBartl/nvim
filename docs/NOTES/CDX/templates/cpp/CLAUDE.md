# C++-Projekt

- Toolchain: MSVC (Windows, Fallback clang), CMake + Ninja.
- Build: `cmake -S . -B build -G Ninja && cmake --build build`, Tests: `ctest --test-dir build`.
- Format: `.clang-format` im Repo-Root ist massgeblich; der globale Hook
  prueft Edits nur, wenn diese Datei existiert.
- Neue Abhaengigkeiten nur nach Rueckfrage.
