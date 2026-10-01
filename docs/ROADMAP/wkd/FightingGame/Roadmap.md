# `wkd` - `FightingGame`

- ~~Wenn man den "Fight"-Button hovert, wird ein Sound Effect ausgespielt~~ — erledigt als
  T16, siehe `$REPOS_DIR/WKDBooks/Development/wkdbook-wkd/Backlog/wkd_Completed.md`.
- Netzwerk: Sind 2 Personen glerichzeitig auf der Website, können sie einen Kämpefernamen eingeben und gegen einen zufälligen Gegner spielen, der auch gerade auf der Website ist. Anbsonsten spielt man gegen KI. Das wäre ein witziger Gag und könnte mehr Personen auf die Seite bringen.

---

## Cutting-Edge-Tech als Lernvehikel (Stand 2026-09-29)

Motivation ausdrücklich nicht "Feature um des Features willen", sondern gezielt neue
Technik-Bereiche lernen — das Spiel selbst ist der Vorwand. Kandidaten, grob nach
Bereich, mit Lernwert/Aufwand-Einschätzung für DIESES Spiel:

### Grafik/Rendering

- **WebGPU** (nicht WebGL) — aktuell die wirklich neue Browser-Grafik-API, näher an
  Vulkan/Metal/DirectX12 als WebGL. Chrome/Edge gut unterstützt, Safari zieht nach. Muss
  nicht "3D-AAA" heißen:
  - Sprites bleiben 2D, aber Partikel (Trefferfunken, Staub beim Landen) über einen
    WebGPU-Compute-Shader (WGSL) — echte GPU-Programmierung, ohne das ganze Spiel
    umzubauen.
  - Oder: echte 3D-Arena (Low-Poly-Bäume/Boden mit Tiefe/Parallax), Charaktere bleiben
    Sprite-Billboards davor ("2.5D", bekanntes Muster, technisch aber echtes
    3D-Rendering).
  - **Lernwert:** hoch (das wird in 2-3 Jahren Standard). **Aufwand:** mittel-hoch, neue
    Rendering-Pipeline neben dem bestehenden Canvas-2D-Code.

### WebAssembly

Bringt für ein Spiel dieser Größe **keinen** echten Performance-Gewinn (die
Canvas-2D-Logik ist trivial leichtgewichtig) — der Wert ist rein das Lernen der
Toolchain selbst: Physik-/Kollisionslogik in Rust schreiben, nach WASM kompilieren,
über eine schlanke JS-Bridge einbinden. Bestes "reines Lernen ohne sich selbst
belügen zu müssen, dass es nötig wäre"-Verhältnis, weil der JS-Weg daneben
weiterläuft und man ehrlich vergleichen kann, was WASM bringt (und was nicht).

**Kombiniert mit WebGPU** (siehe oben) ist das im Kern, wie moderne
Browser-Game-Engines tatsächlich gebaut sind (z. B. Bevy, kompiliert nach
WASM+WebGPU) — größerer Sprung, aber näher an "wie macht man das wirklich".

### Netzwerk — deckt sich mit der Matchmaking-Idee oben

**WebRTC DataChannels** für echtes 1v1 zwischen zwei Browsern, ganz ohne eigenen
Server (Peer-to-Peer, nur ein Signaling-Schritt nötig) — genau die Technik, die die
"Live-Matchmaking gegen zufälligen Website-Besucher"-Idee oben brauchen würde.

Fachlich der spannendste Kandidat: Fighting Games sind DAS klassische
Härtefall-Problem im Netcode (Rollback Netcode, Input-Prediction, frame-genaue
Synchronisation bei ~100ms Latenz) — dazu gibt es exzellente öffentliche
Aufarbeitung (GGPO, von praktisch jedem modernen Fighting Game genutzt). Am meisten
übertragbares Wissen (Netzwerk-/Distributed-Systems-Denken), nicht nur
Browser-API-Trivia.

### Kleinere Kandidaten

- **AudioWorklet** statt der aktuellen `setInterval`-Bastellösung für Musik/Sound —
  sample-genaues Timing, läuft auf dem Audio-Rendering-Thread. Kleiner, sauberer
  nächster Schritt, direkt am bestehenden Platzhalter-Sound anknüpfbar.
- **OffscreenCanvas + Web Worker** — Game-Loop komplett vom Main-Thread lösen. Echtes,
  gebräuchliches Pattern für Canvas-Apps, moderat lehrreich.
- **Gamepad API** — kein "cutting edge", aber echter Controller-Support, eine der eher
  unbekannten Browser-APIs.
- **ONNX Runtime Web / TF.js (WebGPU-Backend)** — KI-Gegnerlogik statt Handcode über ein
  winziges, im Browser laufendes Modell. Eher Spielerei als Substanz bei diesem
  einfachen Gegnerverhalten, aber als "ML im Browser ausprobieren"-Übung legitim.

### Einschätzung, wo der beste Lernwert pro Aufwand liegt

WebGPU-Partikel/Effekte als nächster kleiner Schritt (schnell sichtbares Ergebnis,
echte GPU-API), WebRTC-Multiplayer als das große, fachlich lohnendste Folgeprojekt
(deckt sich mit der Matchmaking-Idee oben). WASM nur, wenn die Toolchain selbst
interessiert — nicht weil das Spiel es bräuchte.

---

