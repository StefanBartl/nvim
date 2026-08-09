# `pdfport.nvim`

Done (2026-08-09):
- ~~Warn 3:37:11 PM notify.warn [filetree.pdf] pdfport.nvim not installed~~
  → Already fixed on disk: `filetree/util/pdf.lua`'s `M.has_pdfport()`/`M.open()`
    call `require("pdfport")` (matching `lua/pdfport/init.lua`'s actual module
    name), not `require("pdfport_nvim")`. No further action needed.
- ~~PDF-Erstellung als API (images.nvim / markdown.nvim / filetree.nvim als
  Aufrufer)~~ → P0 (Gerüst + Bilder) implemented in pdfport.nvim: see
  `pdfport.nvim/docs/FEATURES.md` in the project, and the full design/roadmap
  for P1-P3 in `pdfport.nvim/docs/ROADMAP/PDF_CREATE.md`.

---
