# Roadmap für die Markdown-Konfiguration

## Table of content

  - [Ideen](#ideen)
  - [wrap](#wrap)
  - [toc](#toc)
  - [`/custom/markdown`-Modul](#custommarkdown-modul)
    - [Folding](#folding)
    - [Headings](#headings)
    - [`/custom/markdown` als 'single source of truth' für Markdown config etablieren](#custommarkdown-als-single-source-of-truth-fr-markdown-config-etablieren)
      - [`/autocmds/markdown` mit `/custom/markdown/ui/autocmds/` zusammenführen](#autocmdsmarkdown-mit-custommarkdownuiautocmds-zusammenfhren)

---

## Ideen

- Markdown: Tabellen genormed bzw gerendert anzeigen:
    - Wenn man mit dem cursor innerhalb der tabelle ist in einem floating window oder via MardkwownPreview im Browser (optional mit trigger key oder automatisch)
    - Usercommand sammelt alle Tabellen des Dokuments, gibt sie in einer select aus und wird dann, je nach option gerendert in einem floating window oder via Markdown Preview im Browser
 Sollte MarkdownPreview sich nicht dafür eigenen, eventuelle ein eigenes Tool erstellen

---

## `/custom/markdown`-Modul

1. markdown mappings/utils/markdown, mappings/marjkdown, utils/markdown und /utils/markdown_headings zusammenholen

---

### Folding

1. `zf` und `za` falten nicht korrekt, wenn weitere Unter-Headings da sind

---

