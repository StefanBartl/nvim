# Roadmap `lib.nvim`

## Nebenbefund (lib.nvim-intern) aus einer pdfport.nvim runde

Es gibt zwei überlappende System-Opener: lib.nvim.cross.open_default und lib.nvim.fs.open.url.system_opener. Für eine lokale PDF-Datei ist open_default die richtige Wahl (macht wslpath-Konversion + expand_path, was der URL-orientierte system_opener nicht tut) — pdfport hat also korrekt gewählt.

terminal.lua — Shell-basiert, aber nicht kaputt

Dispatch ist vim.cmd("split | terminal <shellstring>") mit vim.fn.shellescape(png_path). Anders als jobstart geht :terminal absichtlich über &shell, also lösen chafa/kitten/imgcat korrekt auf, und shellescape ist richtig mit &shell gepaart. Auf nativem Windows liefert best_terminal_renderer() nil (keins dieser Tools existiert dort), display_png bricht sauber mit Notify ab — kein fehlgeschlagener Spawn.

Nicht shellescape gegen lib.nvim.terminal.escape tauschen: letzteres macht nur Backslash-Escaping (%s %$ \ \), verfehlt Shell-Metazeichen und quotet nicht — das wäre eine Regression und für cmd.exe` falsch.
Mögliche Härtung (keine Delegation): auf argv-Form jobstart({tool, ...}, { term = true }) umstellen, dann fällt Shell + shellescape weg. Es gibt dafür aber keinen geteilten lib.nvim-Helper („argv in :terminal-Split"), und es ist eine Verhaltensänderung mit realem Risiko. Ungefragt nicht sinnvoll.
lib.nvim.image_preview existiert, ist aber ein anderer Mechanismus (In-Neovim-Grafik über images.nvim/snacks/image.nvim, schwerere Soft-Deps, grafikfähiges Terminal nötig) — eine Alternativ-Funktion, keine Delegation.
Vorbestehender, unabhängiger Schönheitsfehler: der ueberzug-Zweig in display_png fällt auf chafa durch, startet nie ueberzug.
core/rasterize.lua — schon korrek

---
