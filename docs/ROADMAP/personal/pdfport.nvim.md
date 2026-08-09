# `pdfport.nvim`

PDF_CREATE

P1 shipped and pushed to main (5d85d63..ed59ce9).

What's new:

producers/pandoc.lua — Markdown/text → PDF, auto-detects a PDF engine (tectonic → typst → xelatex → lualatex → pdflatex), or pin one via pdf_engine. No separate typst producer — it only ever appears as pandoc's --pdf-engine, matching the concept doc's own conclusion.
core/composer.lua now also accepts opts.text/opts.bufnr (not just opts.inputs), materialized via new util/tmpfile.lua and cleaned up after the callback fires.
create_chain defaults: markdown/text → {"pandoc"}.
Tests extended (registration, engine-independent chain resolution, text/bufnr validation + cleanup), health.lua checks pandoc + engine, all docs and docs/ROADMAP/PDF_CREATE.md updated to mark P1 done.
Still open per the concept: P2 (wiring into images.nvim/markdown.nvim/filetree.nvim) and P3 (HTML/Office producers, pdfport.merge()). Say the word if you want to keep go

---
