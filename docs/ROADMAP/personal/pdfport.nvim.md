# `pdfport.nvim`

- [ ]   Warn  3:37:11 PM notify.warn [filetree.pdf] pdfport.nvim not installed — opening PDF in system viewer
      → Ursache gefunden (2026-08-07): `filetree/util/pdf.lua` macht
        `require("pdfport_nvim")`, das Modul heißt aber `pdfport`. Die Warnung
        kommt deshalb immer, auch bei installiertem pdfport.

- [ ] PDF-Erstellung als API (images.nvim / markdown.nvim / filetree.nvim als Aufrufer)
      → Konzept: `C:\repos\pdfport.nvim\docs\ROADMAP\PDF_CREATE.md` (2026-08-07)

 ---
