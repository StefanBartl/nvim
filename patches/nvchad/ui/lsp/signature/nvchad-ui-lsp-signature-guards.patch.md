# nvchad/ui – LSP Signature: zusätzliche Guards gegen Race-Conditions

## Table of content

  - [Plugin / Repo](#plugin-repo)
  - [Ausgangslage](#ausgangslage)
  - [Upstream-Status (neue Version)](#upstream-status-neue-version)
  - [Ziel dieses Patches](#ziel-dieses-patches)
  - [Patch-Typ](#patch-typ)
  - [Entfernen des Patches](#entfernen-des-patches)
  - [Hinweis bei Patch-Fehlschlag](#hinweis-bei-patch-fehlschlag)

---

## Plugin / Repo
- Projekt: NvChad
- Subrepo: ui
- Datei: lua/nvchad/lsp/signature.lua

---

## Ausgangslage

In einer älteren Version existierte ein Crash bei schneller Buffer-
Invalidierung (z. B. beim Schließen von Fenstern), ausgelöst durch:

- ungültige Buffer-IDs
- fehlende Guards in Autocmd-Callbacks
- ungeprüften Zugriff auf `client.server_capabilities.signatureHelpProvider`

Ein lokaler Fix hatte diese Fälle vollständig abgesichert.

---

## Upstream-Status (neue Version)

Upstream hat inzwischen **teilweise** reagiert:

- `nvim_buf_is_valid(bufnr)` wird vor `nvim_clear_autocmds` geprüft

Nicht gefixt sind weiterhin:

- fehlende Prüfung von `signatureHelpProvider`
- fehlende Prüfung von `triggerCharacters`
- kein Guard im Autocmd-Callback
- kein defensives `pcall` bei `nvim_clear_autocmds`

Damit bestehen weiterhin potenzielle Race-Conditions.

---

## Ziel dieses Patches

- Ergänzt nur die fehlenden Guards
- Bewahrt Upstream-Änderungen
- Macht das Verhalten vollständig robust
- Kein funktionaler Unterschied bei gültigen Zuständen

---

## Patch-Typ

- defensive Programmierung
- race-condition hardening
- upstream-kompatibel

---

## Entfernen des Patches

Dieser Patch kann entfernt werden, sobald upstream:

- `signatureHelpProvider` validiert
- `triggerCharacters` validiert
- Callback-seitig `nvim_buf_is_valid` prüft

Dann wird der Patch entweder nicht mehr anwendbar
oder inhaltlich redundant.

---

## Hinweis bei Patch-Fehlschlag

Ein Fehlschlag beim Anwenden bedeutet sehr wahrscheinlich:

- Datei wurde refaktoriert
- oder der Fix ist upstream vollständig enthalten

In diesem Fall:
- neue Version manuell prüfen
- Patch ggf. löschen

---
