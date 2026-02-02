# Problemstatement: LSP-Signature-Popup fokussiert sich selbst (Noice aktiviert)

# Kurzfassung

Beim Tippen eines Funktionsaufrufs öffnet Noice das LSP-Signature-Popup. Unmittelbar nach dem Öffnen springt der Eingabefokus vom Edit-Fenster in das Signature-Float: Insert-Mode wird verlassen, der Cursor „landet“ im Popup. Das passiert auch dann, wenn der View für Signaturen in Noice explizit mit `enter = false` und/oder `focusable = false` konfiguriert wird. Deaktiviert man dagegen die Noice-Signature-Integration vollständig, tritt das Verhalten nicht auf. Das Problem ist in der Community mehrfach beobachtet; ein zugehöriges Issue wurde jedoch als „not planned“ geschlossen. ([GitHub][1])

# Betroffene Umgebung (typisch)

• Neovim 0.10.x (häufige Repro), teilweise auch 0.11 nightlies/releases berichtet
• Plugins: `folke/noice.nvim` (LSP-Integration aktiv), `nvim-lspconfig`, häufig in NvChad-Setups (Base46/Noice vorkonfiguriert)
• Sprache/Server: unabhängig (reproduzierbar mit ts/js/python/lua) ([GitHub][1])

Wichtig zur Versionierung: Ab Neovim 0.11 ist `vim.lsp.handlers.signature_help()` intern nicht mehr der Weg, um Verhalten zu steuern; Handler-Overrides (z. B. `vim.lsp.with(..., {focusable=false})`) greifen daher nicht mehr wie in 0.10. Das erklärt, warum einige Workarounds in 0.11 wirkungslos sind. ([Neovim][2])

# Symptome

• Beim Tippen von `(` oder – je nach Mapping – beim Drücken von <Space> innerhalb der Klammern erscheint das Signature-Popup.
• Unmittelbar danach wechselt der Fokus ins Popup: Insert-Mode wird verlassen, der Cursor/Key-Focus liegt im Float.
• In der Praxis äußert sich das als scheinbares „Einfrieren“, bis man das Popup schließt oder den Fokus manuell zurückbringt.
• Tritt ausschließlich auf, solange Noice für Signaturen aktiv ist; ein reines Built-in-Popup mit `focusable=false` zeigt das Verhalten nicht (in 0.10). ([GitHub][1])

# Erwartetes Verhalten

• Das Signature-Popup soll sich nicht fokussieren; der Cursor bleibt im Edit-Fenster im Insert-Mode.
• Optional sollte ein expliziter Fokuswechsel nur auf Benutzeraktion (z. B. zweiter Aufruf, spezielles Mapping) erfolgen – analog zum Hover-Verhalten in den Neovim-Docs. ([Neovim][3])

# Tatsächliches Verhalten

• Das Signature-Popup erhält (kurzzeitig oder dauerhaft) den Fokus, obwohl der View mit `enter=false`/`focusable=false` konfiguriert ist.
• In manchen Setups wird der Edit-Fokus unmittelbar in Normal-Mode versetzt (sichtbar: Cursorform/-modus wechseln). ([GitHub][1])

# Reproduktionsschritte (minimal)

1. Neovim mit aktivem LSP und Noice starten, Noice-LSP-Signature einschalten.
2. In einer Datei eine Funktion mit bekannter Signatur tippen (z. B. `array.filter(|`) und `(` bzw. <Space> eingeben.
3. Beobachten, dass der Cursor in das Signature-Popup springt und der Insert-Mode verlassen wird. ([GitHub][1])

# Bereits getestete/ineffektive Gegenmaßnahmen

• `views.hover.enter = false`, `views.popup.enter = false` (Noice)
• Eigener View (z. B. `sig_nofocus`) mit `focusable=false` und Route `filter={event="lsp", kind="signature"}` → `view="sig_nofocus"`
• `lsp.signature = { enabled = true, auto_open = {...} }` (Varianten)
• Diverse Deaktivierungen anderer UI-Plugins (autopairs, autotag etc.)
• Ergebnis: Fokusproblem bleibt bestehen (nur vollständiges Deaktivieren von `lsp.signature` in Noice „hilft“, ist aber kein Fix). ([GitHub][1])

# Beobachtungen/Indizien

• Die Meldungen und Videos in Community-Threads zeigen denselben Fokuswechsel; Autor\*innen betonen, dass das Problem nur mit Noice aktiv sei. Das Issue wurde vom Maintainer mit Verweis „kommt nicht von Noice“ geschlossen, was jedoch in mehreren Setups nicht mit der Beobachtung korrespondiert. ([GitHub][1], [Reddit][4])
• In Neovim 0.11 hat sich die LSP-Handler-Architektur geändert; Workarounds, die in 0.10 funktionierten (Handler-Override), greifen dort nicht mehr. ([Neovim][2])

# Mögliche Ursachen (Hypothesen)

1. Fokuswechsel beim Öffnen des Floats durch eine interne Noice-Route/-View, die in bestimmten Pfaden dennoch `enter` oder `nvim_set_current_win()` triggert (z. B. durch generische LSP-View statt spezifischer Signature-View).
2. Race-Condition zwischen Auto-Open der Signatur (Insert-Mode) und anderen Events (Completion/Popupmenu/`InsertCharPre`), wodurch Neovim kurzzeitig den Float als „aktives“ Fenster behandelt.
3. In 0.11: Wegfall des klassischen Signature-Handlers → „alte“ Konfig-Schalter (z. B. `focusable=false` per Handler-Wrap) werden ignoriert; Noice übernimmt die Darstellung über `vim.lsp.util.open_floating_preview`-Overrides. ([Neovim][2])

# Scope/Impact

• Hohe Beeinträchtigung des Schreibflusses (Insert-Mode-Abbruch).
• Tritt in vielen Sprachen/Servern auf; unabhängig von Autopairs/Mappings.
• Betrifft besonders NvChad-Nutzer\*innen, weil Noice dort häufig default-aktiv ist. ([GitHub][1])

# Workarounds (keine echten Fixes)

• Noice-Signature vollständig deaktivieren (`lsp.signature.enabled = false`) – funktional, aber entfernt die gewünschte Feature-DARSTELLUNG. ([GitHub][1])
• Auf 0.10: Signatur via Built-in-Handler mit `focusable=false` rendern und Noice für Signaturen umgehen (nicht zukunftssicher, da 0.11 die Handler nicht mehr nutzt). ([Neovim][2])

# Diagnostikvorschlag (für eine zielgerichtete Ursachenanalyse)

• Instrumentierung von Fokuswechseln: `WinEnter`/`WinLeave`-Autocmds, die bei Float-Fenstern (`nvim_win_get_config(win).relative ~= ""`) Logeinträge erzeugen (Zeitpunkt, `buftype`, `filetype`, `noice`-Metadaten).
• „Event-Trace“ rund um die Signatur-Öffnung: `InsertCharPre`, `TextChangedI`, `CompleteChanged`, Noice-Route-Treffer.
• Testmatrix:
– Noice an/aus, `override.open_floating_preview` an/aus
– 0.10 vs. 0.11
– Nur LSP + Noice (ohne cmp/autopairs) vs. volles Setup
• Ziel: exakten Codepfad finden, der `enter`/Fokus setzt, obwohl der View anders konfiguriert ist.

# Referenzen

• GitHub-Issue „Noice integration with LSP 'steals' the focus into Signature buffer“ (geschlossen): Repro-Beschreibung, Video, NvChad-Kontext. ([GitHub][1])
• Neovim 0.11-News: `vim.lsp.handlers.signature_help()` wird nicht mehr verwendet (relevant für gescheiterte Handler-Workarounds). ([Neovim][2])
• Community-Berichte mit gleichem Symptom (Fokuswechsel ins Signature-Popup). ([Reddit][4])

# Akzeptanzkriterien für einen Fix

• Bei aktivem Noice-Signature-Popup bleibt der Fokus garantiert im Edit-Fenster (Insert-Mode bleibt erhalten).
• Kein „Jitter“/Fokus-Flip bei Auto-Open; der Float darf erst auf explizite Aktion fokussierbar sein.
• Lösung funktioniert auf Neovim ≥0.11 ohne Handler-Overrides und ist unabhängig vom Completion-Plugin.

[1]: https://github.com/folke/noice.nvim/issues/1016 "bug: Noice integration with LSP 'steals' the focus into Signature buffer.  · Issue #1016 · folke/noice.nvim · GitHub"
[2]: https://neovim.io/doc/user/news-0.11.html?utm_source=chatgpt.com "News-0.11 - Neovim docs"
[3]: https://neovim.io/doc/user/lsp.html?utm_source=chatgpt.com "Lsp - Neovim docs"
[4]: https://www.reddit.com/r/neovim/comments/1m0ebm8/need_help_with_the_signaturehelp_popup/?utm_source=chatgpt.com "Need help with the signatureHelp popup : r/neovim"
