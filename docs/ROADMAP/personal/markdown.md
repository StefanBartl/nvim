# `markdown.nvim`

## Bugs
Ich schaue mir zuerst an, wie diese drei Features im Plugin aufgesetzt sind — dann kann ich fundiert sagen, wovon sie abhängen und wo zwei „identische" Maschinen auseinanderlaufen können.

Lass mich die relevanten Dateien ansehen: wie `:Markdown`, die URL-Öffnung und `leader [` registriert werden und wovon sie abhängen.

Jetzt die Keymaps (leader-[ und Doppelklick/URL) und wie das Plugin überhaupt initialisiert wird:

Ja — und der wichtigste Punkt zuerst: **das sind nicht drei unabhängige Bugs, sondern ein einziger.** Alle drei Features werden über denselben Mechanismus installiert. Wenn der auf dem Laptop nicht greift, fallen genau diese drei (und nur die) gleichzeitig aus.

## Warum die drei zusammenhängen

Alle drei hängen an der `FileType`-Autocmd-Kette, die `M.setup()` registriert:

| Symptom | Installiert von | Autocmd-Gruppe |
|---|---|---|
| `:Markdown` | [`usrcmds.apply` → `create_markdown_command`](lua/markdown_nvim/bindings/usrcmds.lua:28) | `MarkdownNvimUserCommands` |
| `<leader>[` | [`keymaps.apply`](lua/markdown_nvim/bindings/keymaps.lua:47) | `MarkdownNvimKeymaps` |
| Doppelklick-URL (`<2-LeftMouse>`) | [`keymaps.apply`](lua/markdown_nvim/bindings/keymaps.lua:75) | `MarkdownNvimKeymaps` |

Beide Autocmd-Gruppen werden nur angelegt, wenn `M.setup()` **komplett bis [Zeile 27](lua/markdown_nvim/init.lua:27)** durchläuft und danach das `FileType`-Event für den Buffer als `markdown` feuert. Genau das ist der eine gemeinsame Fehlerpunkt.

## Warum „identische Dateien" trotzdem verschieden laufen können

Identische Plugin-*Dateien* garantieren keine identische *Laufzeit*. Realistische Ursachen (nach Wahrscheinlichkeit):

1. **`setup()` bricht auf dem Laptop mit Fehler ab.** In [init.lua:13](lua/markdown_nvim/init.lua:13) wird `_setup_done = true` **vor** der eigentlichen Arbeit gesetzt. Wirft ein früherer `require` (config, hl_options, fenced_fix) einen Fehler — z. B. wegen anderer **Neovim-Version** oder einer Datei, die über den Remote-Mount nicht sauber gesynct/gelockt ist — dann wird [`bindings.setup` (Zeile 27)](lua/markdown_nvim/init.lua:27) nie erreicht, und der Guard verhindert jeden Retry. Ergebnis: exakt diese drei Ausfälle.

2. **Filetype wird nicht als `markdown` erkannt.** Ist `ft` leer/anders, feuert die Kette nie ([`is_md`](lua/markdown_nvim/bindings/autocmds.lua:16) schlägt fehl). Passt zu „render wird nicht angezeigt".

3. **Lazy-Timing / anderer geladener Commit.** Auch wenn das Plugin remote hängt: prüfe, ob `:Lazy` auf beiden Maschinen denselben Commit-Hash zeigt. Und die *anderen* (lokalen) Plugins unterscheiden sich — eines kann `<2-LeftMouse>` oder `<leader>[` überschreiben oder die Augroup-Reihenfolge verschieben.

4. **Remote-Mount-Eigenheiten** (Cache, Locking, Zeilenenden, partielle Syncs) → ein `require` schlägt nur auf dem Laptop fehl → Fall 1.

## Was du auf dem Laptop prüfen solltest

In einer offenen `.md`-Datei auf dem Laptop:

```vim
:messages                     " Rote Fehler beim Start? (wichtigster Check)
:lua =vim.version()           " Nvim-Version mit dem PC vergleichen
:set filetype?                " steht da 'markdown'?
:verbose command Markdown     " existiert der Befehl? woher?
:verbose nmap <leader>[       " ist die Map da? von wem überschrieben?
:autocmd FileType markdown    " sind MarkdownNvim*-Gruppen registriert?
:Lazy                         " gleicher Commit wie am PC?
:checkhealth markdown_nvim
```

Mein Tipp: **fang mit `:messages` und `:lua =vim.version()` an.** Wenn `:messages` einen Startup-Fehler aus dem Plugin zeigt oder die Nvim-Versionen auseinanderlaufen, hast du Fall 1 — die mit Abstand wahrscheinlichste Erklärung dafür, dass ausgerechnet diese drei zusammen sterben.

Schick mir die Ausgabe von `:messages` und den beiden Versionen, dann sage ich dir genau, welche der Ursachen es ist.


## mögliche Features

1. !!! Images ? !!!
2. Referenz Feature: Wenn man in den Mardkwon headlines etwas verändert, werden alle Refrenzen in markdown links / toc autopamtisch upgedatet, sodass diese immer stimmen. Was wäre dazu nötig? Wieviel Performance würde das kosten?
3. Die plug keymaps: Plug ist nicht notwendig, besser wäre wenn es `whichkey` imlementierung gibt und das reicht - die nvim_create_keymap() reciht hier vollkomemn aus.
4.
5. [ ] DoppelklickRechts auf markdown headline -> fold/unfold toggle
6. Wenn sich ein Markdown Link Url nicht ausgeht in einer Zeile, dann wird ein langer Unterstrich angezeigt:

  ```markdown
  Dies ist nur text um die Zeile brechen zu lassen[Dieser KB-Artikel](https://support-hub.tricentis.com/open?id=kb_article_view&sysparm_article=KB0011252&sys_kb_id=eafc32943b29fe14bef83fc5e4e45ade&spa=1) beschreibt, wie Sie die Support-Info und Logdateien von Tosca Commander, TBox, Workspace, der Migration, dem Flexera-Lizenzserver und dem Installationsprozess des Tricentis-Lizenzservers sammeln.
  ```

  Es wäre toll, wenn man das schöner machen könnte! [Screenshot](./MATERIALS/ML_Link_Thing.png)

### Exra

5. [ ] nivm/lua/config/menu -> neuer eintrag wenn auf mardkown headline: Fold/unfold diese headline, fold/unfold alle darunter, usw... wenn das möglich wäre, dass man menu als dependency nmmt und kdann kann man ies ientreöäge hinzufügen, geren. wenne snur so geht, dass diese in der nvim cuser configi implementiert weren, dann dort

## Bugs & Generell fixes

1. tableview
  1. toggle sollt emit `q` bzw `Escape im Normal Mode` geschlossen werden können (`lib.nvim.windows.nice_quit` ?).
  2. tableview open browser und open browser nice funkltioeren nicht (workstation)
3. `   Info  21:31:47 notify.info [markdown_nvim.handler] Handler: No recognized target under cursor` - diese message bei doppel rechtsklick mit der maus  unterdrücken. nur wenn es probleme gibt, dann message ausgeebn.
4. !!! `C-f` funktoinert nicht korrekt


---
