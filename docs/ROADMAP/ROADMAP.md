# Roadmap for `main-workstation` branch


- learn-cli.nvim vielleicht doch ?
- `mdview.nvim`: Das war eigentlich mein Websocket Lern Prozess...
- `lua/config/menu` nach `lua/wkdnvchad`?
- beim öfgfnen eienr datzei über harpoon aktualisere filetree.nvim den filetree noch nicht cwd_sync



lernen: https://www.browserstack.com/

## Table of content

  - [ZIEL](#ziel)
  - [High](#high)
  - [LSP](#lsp)
  - [General](#general)
  - [Bugs](#bugs)

---

## ZIEL

1. ROADMAP.md durchgehen
2. Alle plugin fähigen Module augliedern
3. Funktionen/Module/ganze Custom Plugins, die man mit ffi über vc performanter machen könnte?
  1.  Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wir Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wirdd
4. `BINDINGS.lua`: In der Descrtiptionder Keymaps und Usrcmds: Das plugin selbst nicht nennen,, wie zb.: "[iletree]:" in fileteree.nvim keymap descreiption
5. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
6. Checklisten anwenden
  1. ToDo's duchgehen
7. Branch küren (so wenig commits wit möglch, damit die .git folder nicht groß ist)

---

## High

8. `leader wq`: Alle issues lösen
9. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
10. `nvim/init.lua` durchgehen
11. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - [ ] `/nvim/lua/` – alle Module durchgehen und checken, ob sie irgendwo hineinpassen

---

## LSP

12. lightbulb: Manchmal stört sie und ich möchhte das schnell ausblenden können, am besten mit Keymap togglebnar (markdown lsp)

---

## General

13. lsp: Einen switch einbauen, mitdem ich regeln kann, was der root für lsp ist: Switch zwischen cwd/nächstes_git/pfad/ zb mit `leader lsp`öffnet ein `lib.nvim -> hover_select` und den scope den man wählt wir lua_ls nochmal neu berechnet auf den scope
14. `ZenMode` sollte auch eienen usrcmds toggle schalter haben
15. ✅ **[No Name]-Buffer-Guard** — wenn nvim aus irgendeinem Grund einen `[No Name]`-Buffer in einem Fenster anzeigen würde (Buffer gelöscht, Fenster geschlossen), aber ein echter benannter Buffer existiert, wird das Fenster stattdessen dorthin umgeleitet. Ausnahmen bleiben intakt: existiert kein Alternativ-Buffer (z.B. letzter Datei-Buffer schließt, oder ein Tree-Plugin ist mit `close_if_last_window = false` das letzte Fenster), bleibt der `[No Name]`-Buffer unangetastet; bewusst erzeugte Scratch-/Temp-Buffer (`:enew`, Plugin-eigene Buffer mit `buftype ~= ""` oder unlisted) werden nie umgeleitet, da die Erkennung rein zustandsbasiert ist (leer, unbenannt, `buftype=""`, gelistet, unmodifiziert) und nur auf `BufDelete`/`BufWipeout`/`WinClosed` reagiert, nie auf jeden Fensterwechsel. Implementiert in `lua/autocmds/general/{init,helpers,defaults,@types}.lua` (`no_name_guard`), verallgemeinert die bereits bewährte Logik aus `filetree.nvim`s `util/buffer.lua:close_for_path()`.

---

## Bugs

16. manchmal bricht `C-c` mit sigint nvim ab, es solte aber alles kopieren des buffers

---

