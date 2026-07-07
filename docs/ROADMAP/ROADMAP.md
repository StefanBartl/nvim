# Roadmap for `main-workstation` branch

- filetreepicker
- netree-fs-refactor
- `config` durchgehen auf fetaures, die zu meinen eigenen plugins passen


- pdfport tags
- filertreee_ beim pasten bestätigung nicht notwendig. vieleicht wäre das auhc in der user config super einstellbar:  alle aktinen, bei denen confirmation möglih ist, togglebar machen
- color_my_Ascciii: Innerhlab eines markdown enced block soll markdow headlines als ein zusammengeehörigesm neues dokument behandelt werden, dass auch... markdown.nvim nicht im toc aufgenommen wird (wenn markdown.nvim hierzu color my ascii as dependency benötigt ist es ok, weventuelle mehr features denkbar?)
 cascade: C-y soll inkrementiern! checken, was es jetzt macht1



## Table of content

  - [ZIEL](#ziel)
  - [High](#high)
  - [General](#general)
  - [Bugs](#bugs)
  - [menus](#menus)

---

- Spellchecking nochmnal durchgehen und notizen machen. Spell Strategie ausarbeiten - entweder Plugin einbindne oder Modul debuggen

## ZIEL

1. ROADMAP.md durchgehen
2. Alle plugin fähigen Module augliedern
3. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
4. Checklisten anwenden
  1. Funktionen/Module die man in der nvim config mit ffi c perfomranter machen könnte?
  2. ToDo's duchgehen
5. Branch küren (so wenig commits wit möglch, damit die .git folder nicht groß ist)

---

## High

1. `leader wq`: Alle issues lösen
2. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
3. `nvim/init.lua` durchgehen
4. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - [ ] `/nvim/lua/` – alle Module durchgehen und checken, ob sie irgendwo hineinpassen
5. `C-a` markiert manchmal niucht mehr

## LSP

7. lightbulb: Manchmal stört sie und ich möchhte das schnell ausblenden können, am besten mit Keymap togglebnar (markdown lsp)

---

## General

1. lsp: Einen switch einbauen, mitdem ich regeln kann, was der root für lsp ist: Switch zwischen cwd/nächstes_git/pfad/ zb mit `leader lsp`öffnet ein `lib.nvim -> hover_select` und den scope den man wählt wir lua_ls nochmal neu berechnet auf den scope
2. `ZenMode` sollte auch eienen usrcmds toggle schalter haben

---

## Bugs

1. manchmal bricht `C-c` mit sigint nvim ab, es solte aber alles kopieren des buffers

---

