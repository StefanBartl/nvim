# Handover — media.nvim, und Video-Previews in hover.nvim

**Stand:** 2026-09-08, Session abgebrochen auf Zuruf. Alles unten Beschriebene ist
gebaut und getestet; die offenen Punkte stehen am Ende und sind alle klein.

**Ausgangsfrage:** „hover.nvim Videos abspielen möglich? Eventuell im Kontext von
`docs/ROADMAP/IDEAS/media.nvim` betrachten."

---

## Die Antwort auf die Ausgangsfrage

**Abspielen: nein, und das ist kein Konfigurationsproblem.** Drei unabhängige
Gründe, jeder für sich ausreichend:

1. **Das Protokoll kann es nicht.** Aus Neovim heraus rendert nur OSC 1337
   (Kitty-APC nie — Messung 2026-08-05, WezTerm/Windows). OSC 1337 kennt keine
   Placement-IDs und keine Frame-Updates: jedes Einzelbild ist ein vollständiger
   Base64-Blob durch `nvim_ui_send`, grob ein halbes MB/s bei 12 fps.
2. **Der Redraw frisst es.** `preview/media.lua` dokumentiert das schon für ein
   *einzelnes* Bild (deshalb der `defer`-Trick). Ein Timer-Loop läge dauerhaft im
   Wettlauf mit dem Repaint-Zyklus.
3. **Kein ffmpeg im Ökosystem.** Geprüft: lib.nvim, pdfport.nvim, images.nvim,
   open.nvim — nirgends `ffmpeg`, `ffprobe`, `mpv`. Der Unterbau fehlte komplett.

**Was stattdessen gebaut wurde:** ein Standbild aus der Datei, plus die
vorhandenen Paging-Tasten als Scrub. Punkt 3 ist damit geschlossen.

---

## Was fertig ist

### 1. `media.nvim` — neues Repo, öffentlich, gepusht

<https://github.com/StefanBartl/media.nvim> · lokal `E:/repos/media.nvim` ·
Commit `44e9041`.

**Warum ein eigenes Repo und nicht ffmpeg in hover.nvim.** `images/pdf.lua` sagt
es wörtlich über PDFs: *„images.nvim draws pictures; it does not read PDFs, and
it does not want to."* Derselbe Satz mit „videos" ist die Begründung. Die
Struktur ist bewusst pdfport.nvim nachgebaut: eine externe Toolchain, einmal
gekapselt, als Verben exponiert, von allem konsumierbar was sie will.

Drei Antworten, mehr nicht:

| | |
| --- | --- |
| `media.probe(path, cb)` | ein flacher Record aus einem `ffprobe`-Lauf |
| `media.frame(path, opts, cb)` | ein Standbild als PNG auf Platte |
| `media.sheet(path, opts, cb)` | Kontaktbogen: die ganze Laufzeit als Raster |

Dazu `available()`, `is_video/is_audio/is_media`, `probed()` (synchroner
Cache-Blick), `play()`, `clear_cache()`, und `media.ui.summary(probe)` für die
Einzeiler-Form `1920x1080 · 4:32 · h264 · 100 MB`.

**Die drei Entscheidungen, die das Plugin rechtfertigen** (alle in den
Modulköpfen begründet):

- **`-ss` vor `-i`.** Als Input-Option ist es ein Seek, nach `-i` dekodiert
  ffmpeg die Datei von vorn und wirft alles vor dem Offset weg. Zwei Stunden:
  0,2 s gegen eine halbe Minute.
- **Rotation wird angewandt.** Ein Handy-Video speichert 1920×1080 plus
  90°-Display-Matrix und ist auf dem Schirm 1080×1920. ffmpeg autorotiert beim
  Dekodieren — die gespeicherte Zahl zu melden hieße, die beiden Hälften des
  Plugins widersprechen sich über dieselbe Datei.
- **Cover-Art ist kein Video.** Eine mp3 mit Albumcover *hat* einen Video-Stream,
  ffprobe sagt das wahrheitsgemäß. Ungeprüft übernommen sieht jede getaggte
  Musikdatei wie ein Ein-Frame-Film aus, und ein Seek 10 % in ihr einziges Bild
  schreibt gar keine Datei. `has_video` / `has_cover` sind getrennt.

Bedienung: `:Media [probe|frame|sheet|play|cache clear|health] [path]` mit
Tab-Completion über den lib.nvim-Composer, plus `<leader>Mp/Mf/Ms/Mo` (der ganze
Capital-M-Leader-Raum war in dieser Config frei — geprüft).

Qualitätsstand: 7 Specs grün, framework-frei und **ohne ffmpeg lauffähig**
(argv-Reihenfolge, Offset-Arithmetik, ffprobe-JSON-Formen und Cache-Key-Trennung
sind alle reine Funktionen, genau deshalb). luacheck 0/0, stylua clean,
`lua-language-server --checklevel=Warning` **0 Befunde** (NEW-44).

### 2. `hover.nvim` — Video-Previews, gepusht

Commit `263a0b7` auf `main`.

`classify` kennt jetzt den Typ `video`; `preview/video.lua` holt das Standbild
über `pcall(require, "media")` — genau wie pdfport schon eingebunden ist — und ab
da ist es ein Bild-Hover: dieselbe Canvas-Geometrie, derselbe Draw, dieselben
Tasten.

**Die Paging-Tasten sind der Scrub, und das brauchte auf keiner Seite Code.**
`preview.media.pdf` meldet `scroll = { page = n }`, die Next/Prev-Tasten bewegen
es — `preview/video.lua` meldet dasselbe, und Seite *n* ist das Standbild bei
`video.at + (n-1) * video.step`. Beide Defaults sind `"10%"`: zehn Tastendrücke
laufen einen Zehn-Sekunden-Clip und einen Zwei-Stunden-Film gleichermaßen von
Anfang bis Ende durch. Jeder besuchte Offset ist ein media.nvim-Cache-Eintrag
(Key trägt die mtime), Zurückblättern ist ein `stat` und ein Draw.

**Kein `convert`-Schalter, anders als bei `office`:** ein Standbild ist ein
Keyframe-Seek (~210 ms auf einer 4-GB-h265-Datei nahe dem Ende), also dieselbe
Größenordnung wie eine PDF-Seite, für die auch niemand opt-in machen musste.
`auto_hover.video` bleibt aus — aus demselben Grund, aus dem jeder Typ aus ist.

**`.ts` und `.mts` werden bewusst NICHT beansprucht.** Sie sind MPEG-Transport-
Streams *und* TypeScript, und im Editor gewinnt die zweite Lesart um
Größenordnungen — sonst ginge jede TypeScript-Datei im Projekt an ffmpeg.
`.m2ts` ist eindeutig und bleibt drin. `.ogg` bleibt Audio.

Angefasst: `formats.lua` (`video`-Flag + `is_video`), `classify.lua`,
`@types/init.lua` (Union + `Hover.VideoConfig` + drei `PreviewOpts`-Felder),
`config/DEFAULTS.lua` (`video`-Block, `auto_hover.video = false`),
`config/init.lua` (Options-Assembly), `init.lua` (Dispatch-Branch + `paged`),
`health.lua`, `preview/video.lua` (neu), `TESTS/video_spec.lua` (neu, 16 Specs),
`docs/FEATURES/VIDEO.md` (neu) und die üblichen Doku-Stellen inkl.
`doc/hover.txt` und `docs/install.json`.

Volle Suite grün, luacheck 0/0, stylua clean, das neue Modul erzeugt **null**
LuaLS-Befunde (die 837 im Repo sind der bestehende Test-Global-Bodensatz, davon
5 in `lua/` und alle vorbestehend).

### 3. Zwei Drive-by-Fixes in hover.nvim (waren schon rot auf main)

- **`docs_spec` las `<type>` als Routen-Wort.** `:Hover auto <type>` in
  `README.md` und `docs/CONTRIBUTING.md` galt als erfundenes Kommando
  `auto type` — zwei Failures, die seit `1e84e3f` auf main standen. `<` ist jetzt
  neben `[` und `{` ein Platzhalter-Öffner.
- **`docs/integrations.md` behauptete**, konvertierte PDFs würden bei
  `VimLeavePre` gelöscht. Sie werden seit dem Cache-Umbau einmal pro Session nach
  Alter gekehrt (`office.cache_days`).

---

## ⚠️ Ungetestet gegen echte Dateien — ffmpeg fehlt auf dieser Maschine

`which ffmpeg` und `which ffprobe` kommen leer zurück. **Kein einziges echtes
Standbild wurde erzeugt.** Was verifiziert ist: jede reine Funktion (argv,
Offsets, ffprobe-JSON-Parsing gegen ein aufgezeichnetes Dokument, Cache-Keys),
jeder Degradationspfad, und dass alles lädt.

Was noch nie gelaufen ist: ffmpeg selbst, der Kontaktbogen-Filtergraph, und der
Draw ins Hover-Float.

```bash
winget install Gyan.FFmpeg
```

Danach **Terminal neu starten** (winget erweitert den *User*-PATH, den jeder
schon laufende Prozess beim Login geerbt hat — media.nvim sucht die
Shim-Verzeichnisse allerdings selbst ab). Dann:

```vim
:checkhealth media
:Media probe ~/pfad/zu/video.mp4
:Media frame
:Media sheet
```

Und im Hover: Cursor auf einen `.mp4`-Pfad, `:Hover show`, dann die
Paging-Tasten zum Durchscrubben.

---

## Offen

1. **`E:/repos/WKDBooks/Development/wkdbook-myplugins/media.nvim/`** ist noch
   nicht angelegt. Alle anderen 32 Plugins haben dort einen Ordner.
2. **`lua/plugins/personal/init.lua`**: die media.nvim-Spec ist geschrieben, aber
   noch nicht committet (siehe unten, „Was im Working Tree liegt").
3. **`docs/ROADMAP/IDEAS/media.nvim/MEDIA-TO-TEXT.md`** weiß noch nichts davon,
   dass ihre Phase 0 zur Hälfte existiert. Ein Hinweis oben im Dokument fehlt:
   die ffmpeg-Kette steht, `media.audio()` (16-kHz-Mono-WAV) ist jetzt
   `frame.lua` mit anderem Filter, und die Transkriptions-Hälfte ist in
   `media.nvim/docs/ROADMAP.md` als Punkte 1–4 aufgeschrieben.
4. **`gh repo edit --add-topic`** ist gesetzt, aber der erste CI-Lauf wurde nicht
   angesehen. `.github/workflows/ci.yml` ist die pdfport-Fassung (stylua v2.5.2,
   luacheck 1.2.0, checkout@v5, lib.nvim@`ci-verified` als Sibling).
5. **Prefetch beim Scrubben** — beim Anzeigen von Offset *t* schon *t + step*
   rendern. Etwa zehn Zeilen, und es ist der Unterschied zwischen „sofort" und
   „Viertelsekunde". Steht in `media.nvim/docs/ROADMAP.md`.

### Was im Working Tree liegt

Im Worktree `nvim/.claude/worktrees/hover-nvim-video-playback-6215f6`, auf
`origin/main` rebased (`a108d6c65`):

- `lua/plugins/personal/init.lua` — media.nvim-Spec (`event = "VeryLazy"`, weil
  die vier Keymaps existieren müssen, bevor eine gedrückt wird; ein
  `cmd`-Trigger kann sie nicht binden).
- diese Datei.

`hover.nvim` und `media.nvim` sind beide sauber und gepusht.

---

## Was bewusst nicht gebaut wurde

**Block-Grafik-Playback — inzwischen begonnen, siehe
[video-hover-playback.md](./video-hover-playback.md).** Der hier vermutete
Preis („ein ImageMagick-Pixel-Read pro Frame, der in *einen* Aufruf gebatcht
werden müsste") war richtig und ist bezahlt: `images.blocks` sampelt beliebig
viele Bilder in einem Prozess (186 ms statt 1593 ms für 24 Frames, gemessen
2026-09-08) und malt einen Frame in 6,3 ms — 7 % eines 12-fps-Budgets.

Der eigentliche Blocker lag woanders und war hier nicht vermutet: Neovim
stoppt bei **19 602 Highlight-Gruppen** und gibt keine wieder frei, während
ein Truecolour-Zellraster eine Gruppe pro Farbe erzeugt (2 880 Zellen je
80x36-Frame). `images.ascii` trug diesen Fehler latent seit seiner ersten
Fassung. Quantisierung ist deshalb kein Qualitätsregler, sondern das, was das
Verfahren überhaupt beschränkt. Erledigt in `images.nvim@cd2f9e4`.

Offen bleiben `media.frames()` und die Transportsteuerung im Hover
(Play/Pause — ausdrücklich **kein** Autoplay).

**Ein `BufReadCmd` für Mediendateien.** `*.mp4` global zu beanspruchen kämpft
gegen netrw, oil und jeden Dateibaum mit eigener Meinung, und macht aus einem
`:e`-Vertipper ein Dekodieren. Wer es will, baut es aus `media.frame` in drei
Zeilen — steht als Kommentar in `media.nvim/lua/media/bindings/autocmds.lua`.

**Ein zweiter Renderer.** ImageMagick, GStreamer und mpv können alle ein
Standbild. Keiner kann eins, das ffmpeg nicht kann — eine Backend-Kette, deren
Zweige ununterscheidbar sind, ist Komplexität ohne Antwort. Das Gegenteil von
pdfport, wo sich sieben Backends echt darin unterscheiden, was sie lesen können.
