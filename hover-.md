```markdown
Viel Substanz — danke. Ich halte alles fest. Erst prüfe ich den Zoom-Stand, weil deine Beobachtung dort eine faktische Frage ist:

**Dein Zoom-Befund stimmt zur Hälfte, und die Hälfte ist wichtig:** Zoom *ist* gebaut (`204d083`) und steht in hover.nvims eigener `docs/BINDINGS.md`, README und Vimdoc. Was fehlt, ist die Zeile in **deinen** Config-Notes — `PersonelPlugins/BINDINGS/Keymaps/hover.nvim.md` kennt `dismiss`, `open` und `scroll`, aber kein `zoom_keys`. Genau die Drift, die du beschreibst.

Erst die Office-Befunde, weil die frisch sind:

Jetzt die Doku-Ergänzung zum LibreOffice-PATH — das war ein echter Stolperstein und steht nirgends:

Und die Health-Zeile, damit man den Hinweis dort findet, wo man das Problem trifft:

Escape-Kollaps wieder — und in Lua wäre `\P` ein Ladefehler. Ich nehme die Backslashes ganz raus:

Health-Modul lädt sauber (die Diagnose oben ist vom Stand davor). Jetzt die Office-Zeile in der Evidenzdatei — mit dem, was du tatsächlich gesehen hast:

Jetzt der Zoom. Erst die Wahrheit über die aktuellen Tasten:

Bevor ich deine Tasten-Vorgaben festschreibe, prüfe ich eine davon — `<S-+>` ist auf einer deutschen Tastatur verdächtig:

Neovim akzeptiert alle vier Schreibweisen und hält sie von `+`/`-` getrennt. **Aber:** ob das Terminal `<S-+>` überhaupt *sendet*, ist eine andere Frage — auf deutscher Tastatur ist Shift+`+` das Zeichen `*`, und ohne Kitty-Keyboard-Protokoll sieht Neovim nie ein `<S-+>`. WezTerm kann das Protokoll, also ist es plausibel — aber das ist ein Ein-Minuten-Handtest, kein Ratespiel. Ich schreibe es als offene Frage fest, nicht als Entscheidung.

Alles festgehalten und gepusht. Zurück zum sandbox.nvim-Fix.

Jetzt die Auflösung: die Lebendprüfung darf nur greifen, wenn die Engine *erkannt* und nicht *konfiguriert* wurde.

Jetzt die zwei Stellen, die die Auflösung umgehen — und `reset`, damit ein nachträglich gestarteter Daemon erkannt wird:

Jetzt der Spec — und der Sabotage-Test, der beweist, dass er etwas prüft:

11/11 grün. Sabotage-Test — Hausregel:

Sabotage bestätigt. Volle Suite und der LuaLS-Stil des Repos:

Volle Suite: 15 Dateien, 0 Fehler. Jetzt die LuaLS-Annotationen im Stil des Repos, plus etwas Ballast raus:

**Der Fix greift auf der echten Maschine:** Erkennung wählt jetzt `docker` statt `podman`, und der Container-Hover antwortet. Dieselbe Sonde, die den Fehler gefunden hat, zeigt ihn behoben. Jetzt die Doku:

Fünf LuaLS-Befunde — das Repo stand auf 0 (`9bc3d12`), also sind es meine. Ich sehe sie mir an:

4 der 5 sitzen in `hover_spec.lua`, das ich nicht angefasst habe — `3647a17` (die hover-Integration) kam **nach** `9bc3d12` („sandbox auf 0") und hat sie mitgebracht, ungescannt. Genau die Klasse, gegen die deine Hausregel „nach einem *Spec* auch scannen" steht. Ich behebe alle fünf:

Vier weg, einer bleibt. Der sitzt auf einer anderen Zeile als angenommen:

LuaLS wieder auf 0. Letzte Verifikation vor dem Commit:

Suite grün (15 Dateien), Health meldet jetzt „docker answers". Commit und Push:

Zuletzt die Roadmap-Einträge nachziehen — der sandbox-Auftrag ist erledigt, der Umgehungs-Hinweis in hover.nvims Doku damit veraltet:

Alles in `main`, alle drei Repos sauber.

## Deine Fragen

**Ist das Handover outdated?** War es — an sechs Stellen, alle behoben und gepusht: 229 statt 220 Specs, 13 statt 11 Doku-Prüfungen, veraltete LuaLS-Pässe, zwei „noch nicht gepusht"-Zeilen die längst falsch waren, und language.nvim/insights.nvim doppelt geführt (Handover *und* Roadmap §4 — genau die Drift, gegen die deine Hausregel steht). Zählt jetzt A–J statt A–G.

**Cache-Listing:** ja, genau das wollten wir sehen — eine konvertierte PDF in `<cache>/hover.nvim/office`. Deine korrigierte Befehlszeile steht jetzt in der Doku, meine war kaputt (`--headless -c echo` mischt die Startmeldung in die Ausgabe).

**Office-Pfad:** zwei von drei Punkten bestätigt und datiert. Das „generate pdf" für 0,3 s beim Neustart ist genau richtig — das ist pdfports Rasterung, **nicht** LibreOffice; ein LibreOffice-Start dauert Sekunden. Der Konvertierungs-Cache hat die Sitzung also überlebt. Offen bleibt nur der Alters-Sweep (eine Datei dort zurückdatieren, dann irgendein Office-Dokument hovern).

**LibreOffice-PATH:** festgehalten in `docs/installation.md` mit deinem Einzeiler, und die Health-Zeile sagt jetzt „Schon installiert? Der Windows-Installer erweitert PATH nicht" statt nur „Install LibreOffice" — das war Rat, den du gerade befolgt hattest.

## Zoom

**Zoom *ist* gebaut** (`204d083`) und steht in hover.nvims `docs/BINDINGS.md`, README und Vimdoc. Was fehlte, war die Zeile in **deinen** Config-Notes — nachgetragen, samt deiner Akkord-Tabelle. Zwei Dinge dabei gefunden:

- **`<S-+>` ist ungeprüft, nicht frei.** Neovim nimmt die Schreibweise an und hält sie von `+` getrennt (mit `maparg` nachgemessen). Ob dein Terminal sie *sendet*, ist offen: auf deutscher Tastatur ist Shift+`+` das Zeichen `*`. WezTerm kann das Kitty-Protokoll, also plausibel. Test: `:nnoremap <S-+> :echo "kommt an"<CR>`
- **Es gibt gar keine `:Hover`-Route für Zoom**, anders als für `scroll`. `hover.zoom(delta)` ist öffentlich, aber nur über die geliehene Taste erreichbar. **Meine Empfehlung: die Route vor dem Mausrad** — kleinerer Bau und braucht überhaupt keinen Akkord.

## sandbox.nvim-Fix

Ursache: `get_engine()` wählte nach PATH-Anwesenheit und fragte nie, ob die Engine antworten kann. Jetzt nimmt die Erkennung die erste **antwortende** — faul und pro Sitzung gemerkt, weil eine Lebendprüfung ~385 ms kostet und beim Start nichts zu suchen hat. Eine *benannte* Engine wird nie geprüft: das ist eine Anweisung, keine Vermutung.

Verifiziert mit derselben Sonde, die den Fehler fand:

```
engine            : docker (detected)
engine answers    : yes, 4 image(s) in 283 ms
alpine:edge            quiet  565ms  2  pulled  ·  12.1MB
```

Zwei Funde nebenbei: `container_commands_buffer` las `config.options.engine` direkt und ignorierte damit still `:Sandbox engine set` *und* `.sandboxrc`; und der LuaLS-Scan des Repos stand auf 5 statt 0 — vier davon aus `3647a17`, nach dem „auf 0"-Commit hereingekommen und nie gescannt. Alles behoben, Scan wieder 0, Suite 15 Dateien grün, zentraler Spec sabotage-getestet.

Sag Bescheid, wenn du den Zoom angehen willst — ich würde mit `:Hover zoom in|out` anfangen.
```

ja, mach den zoom - erst die :Hover zoom route
