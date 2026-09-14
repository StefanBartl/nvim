# Wiener Linien WKD APP

WICHTIG: Die haltestell für de bim (straßenbahn) ist nicht myrthengasse, sondern strozzigasse - das btte mitbedenken für das was folgt!

## Table of content

  - [Zielbild](#zielbild)
  - [Datenquelle: Wiener-Linien-Echtzeitdaten](#datenquelle-wiener-linien-echtzeitdaten)
  - [Haltestellen und Richtungen ermitteln](#haltestellen-und-richtungen-ermitteln)
  - [Architekturempfehlung](#architekturempfehlung)
  - [CORS-Frage und Backend-Bedarf](#cors-frage-und-backend-bedarf)
  - [Code-Skeleton (TypeScript)](#code-skeleton-typescript)
  - [Umsetzungsschritte](#umsetzungsschritte)

---

## Zielbild

Eine Anwendung, die beim Öffnen ohne weitere Interaktion zwei Werte gleichzeitig anzeigt:

- Nächste Straßenbahn ab der Haltestelle nahe Myrthengasse, Richtung Thaliastraße, mit Minuten-Countdown
- Nächster Bus ab der Haltestelle Neustiftgasse/Zieglergasse, Richtung Thaliastraße, mit Minuten-Countdown

Beide Werte werden periodisch aktualisiert, ohne dass man etwas anklicken muss.

---

## Datenquelle: Wiener-Linien-Echtzeitdaten

Die Wiener Linien betreiben eine offene, kostenlose Echtzeitschnittstelle (Datendrehscheibe). Seit 2020 ist dafür kein API-Key mehr nötig.

```
Base URL: https://www.wienerlinien.at/ogd_realtime
Endpoint: /monitor
```

Beispiel-Request für eine Haltestelle mit mehreren Steigen (Richtungen):

```
GET https://www.wienerlinien.at/ogd_realtime/monitor?rbl=<RBL_1>&rbl=<RBL_2>&aArea=1
```

- `rbl` ist die ID eines einzelnen Steigs (Haltepunkt, eine Richtung). Man kann den Parameter mehrfach angeben.
- `aArea=1` liefert zusätzlich alle anderen Steige, die zur selben Haltestelle (DIVA-Nummer) gehören. Das ist praktisch, weil man dann nicht zwingend die exakte RBL der gewünschten Richtung kennen muss, sondern clientseitig anhand des Felds `towards` filtern kann.
- `activateTrafficInfo=stoerungkurz` liefert zusätzlich Störungsmeldungen, falls relevant.

Relevanter Ausschnitt der Antwortstruktur:

```json
{
  "data": {
    "monitors": [{
      "locationStop": {
        "properties": { "title": "Neustiftgasse/Kaiserstraße", "attributes": { "rbl": 1234 } }
      },
      "lines": [{
        "name": "5",
        "towards": "Praterstern",
        "direction": "H",
        "departures": {
          "departure": [
            { "departureTime": { "timePlanned": "...", "timeReal": "...", "countdown": 4 } },
            { "departureTime": { "timePlanned": "...", "timeReal": "...", "countdown": 12 } }
          ]
        }
      }]
    }]
  }
}
```

`countdown` ist bereits in Minuten fertig berechnet, das erspart eigene Zeitberechnung. Die Datendrehscheibe verarbeitet die Fahrzeugpositionen alle 15 Sekunden, ein Polling-Intervall von 20 bis 30 Sekunden auf Client-Seite ist also ausreichend und schont die Schnittstelle.

---

## Haltestellen und Richtungen ermitteln

Die Schnittstelle kennt zwei Ebenen von IDs:

- DIVA-Nummer: identifiziert die Haltestelle als Ganzes (z. B. "Neustiftgasse/Zieglergasse")
- RBL-Nummer: identifiziert einen einzelnen Steig, also eine konkrete Fahrtrichtung an dieser Haltestelle

Für den Monitor-Aufruf wird die RBL benötigt, nicht die DIVA. Die Zuordnung findet man in zwei offiziellen CSV-Dateien:

```
Haltestellen (Name -> DIVA):
https://data.wien.gv.at/csv/wienerlinien-ogd-haltestellen.csv

Haltepunkte (DIVA -> RBL, inkl. Koordinaten):
https://www.wienerlinien.at/ogd_realtime/doku/ogd/wienerlinien-ogd-haltepunkte.csv
```

Beide lassen sich lokal herunterladen und filtern, zum Beispiel:

```bash
curl -s "https://data.wien.gv.at/csv/wienerlinien-ogd-haltestellen.csv" | grep -i "Zieglergasse"
curl -s "https://www.wienerlinien.at/ogd_realtime/doku/ogd/wienerlinien-ogd-haltepunkte.csv" | grep "60200XXX"
```

Recherchestand zu den beiden konkreten Haltestellen:

| Haltestelle | Status | Linie(n) laut offiziellen Quellen |
|---|---|---|
| Neustiftgasse/Zieglergasse | Amtlicher Haltestellenname bestätigt | Bus 48A, vermutlich auch 13A |
| "Myrthengasse" | Kein offizieller Haltestellenname dieses Namens gefunden | — |

Für die Straßenbahnhaltestelle gibt es keinen amtlichen Namen "Myrthengasse" – vermutlich ist das die umgangssprachliche Referenz über die nahe gelegene Jugendherberge bzw. Straße. Die einzige Straßenbahnhaltestelle direkt an der Neustiftgasse, die sich verifizieren ließ, ist Neustiftgasse/Kaiserstraße (Linie 5, dort mit Richtungsangabe Praterstern in eine Richtung dokumentiert). Das ist der wahrscheinlichste Kandidat, sollte aber vor dem Bau kurz mit der eigenen Adresse abgeglichen werden, zum Beispiel indem man die RBL dieser Haltestelle einmal testweise abfragt und im Feld `title` bzw. `towards` prüft, ob das passt.

Sobald beide RBL-Werte feststehen, empfiehlt es sich, sie nicht hart in den Code zu schreiben, sondern in eine kleine Konfigurationsdatei auszulagern, etwa:

```json
{
  "tram": { "rbl": 1234, "line": "5", "towardsContains": "Thaliastraße" },
  "bus": { "rbl": 5678, "line": "48A", "towardsContains": "Thaliastraße" }
}
```

Falls die gesuchte Richtung nicht direkt als eigene RBL existiert, sondern nur über `aArea=1` mitgeliefert wird, filtert man beim Rendern client- oder serverseitig nach `towards`.

---

## Architekturempfehlung

Bewertung der drei genannten Optionen für genau diesen Anwendungsfall, ein winziges, latenzkritisches Ein-Blick-Widget:

| Kriterium | PWA (Webapp) | Tauri | Electron |
|---|---|---|---|
| Plattformunabhängig | Ja, inkl. Handy | Ja, aber kein Mobile-Support | Ja, aber kein Mobile-Support |
| Installierbar auf dem Handy | Ja, "Zum Homescreen hinzufügen" | Nein | Nein |
| Ressourcenbedarf / Binärgröße | Minimal | Klein (Rust-Binary + Webview) | Groß (eigene Chromium-Instanz) |
| Aufwand für dieses Feature | Gering | Mittel | Mittel bis hoch |
| Auto-Start / Tray-Icon | Nicht nativ möglich | Ja | Ja |

Empfehlung: PWA als primäre Lösung. Der Use Case – kurz vor dem Verlassen der Wohnung nachsehen – spielt sich in der Praxis vermutlich am Handy ab, und eine PWA lässt sich dort ohne App Store als Icon installieren, startet in unter einer Sekunde und deckt "plattformunabhängig" vollständig ab.

Tauri ist die sinnvolle Ergänzung, falls zusätzlich ein Desktop-Widget gewünscht ist, das dauerhaft sichtbar ist (z. B. Tray-Icon unter Windows). Da Tauri ebenfalls eine Webview als Frontend nutzt, lässt sich der komplette UI-Code aus der PWA eins zu eins wiederverwenden – nur die Storage- und Polling-Logik unterscheidet sich leicht.

Electron wird für diesen Zweck nicht empfohlen: Der Funktionsumfang (zwei Zahlen, ein Netzwerk-Call) steht in keinem Verhältnis zum Ressourcenbedarf einer eigenen Chromium-Instanz.

---

## CORS-Frage und Backend-Bedarf

Die Wiener-Linien-Schnittstelle ist primär für Server-zu-Server-Aufrufe konzipiert; die meisten Community-Projekte (Python/Node-Backends, ESP32-Dashboards, Raspberry-Pi-Widgets) fragen sie serverseitig ab statt direkt aus dem Browser. Das deutet darauf hin, dass kein `Access-Control-Allow-Origin`-Header gesetzt ist und ein direkter `fetch()` aus dem Browser vermutlich an CORS scheitert. Das lässt sich in einer Minute selbst verifizieren:

```js
fetch("https://www.wienerlinien.at/ogd_realtime/monitor?rbl=1234")
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);
```

Schlägt das fehl, genügt ein sehr schlanker Proxy, der nur den Request weiterreicht und cached, zum Beispiel als Cloudflare Worker, Vercel Edge Function oder ein einzeiliger Handler in Go. Dieser Proxy bietet zwei Vorteile gleichzeitig: er löst CORS und er kann die Antwort für z. B. 15 Sekunden cachen, sodass mehrere Geräte oder Tabs nicht unnötig oft gegen die Wiener-Linien-API laufen.

---

## Code-Skeleton (TypeScript)

```typescript
// Shape of the fields actually needed from the Wiener Linien monitor response.
interface DepartureTime {
  timePlanned: string;
  timeReal?: string;
  countdown: number; // minutes until departure
}

interface Line {
  name: string;
  towards: string;
  departures: { departure: { departureTime: DepartureTime }[] };
}

interface Monitor {
  locationStop: { properties: { title: string } };
  lines: Line[];
}

interface MonitorResponse {
  data: { monitors: Monitor[] };
}

/**
 * Fetches the next departure for a given stop (rbl) filtered by direction.
 * Returns the minutes until departure, or null if nothing matched.
 */
async function getNextDeparture(
  rbl: number,
  towardsContains: string,
  proxyBaseUrl: string
): Promise<number | null> {
  const url = `${proxyBaseUrl}/monitor?rbl=${rbl}&aArea=1`;
  const res = await fetch(url);
  const json: MonitorResponse = await res.json();

  for (const monitor of json.data.monitors) {
    for (const line of monitor.lines) {
      if (line.towards.includes(towardsContains)) {
        const next = line.departures.departure[0];
        return next ? next.departureTime.countdown : null;
      }
    }
  }
  return null;
}

// Example usage, polled every 25 seconds from the UI layer.
async function refreshWidget() {
  const [tram, bus] = await Promise.all([
    getNextDeparture(1234, "Thaliastraße", "/api"),
    getNextDeparture(5678, "Thaliastraße", "/api"),
  ]);

  // Render tram/bus countdowns into the two fixed UI slots here.
}
```

---

## Umsetzungsschritte

1. RBL-Werte für beide Haltestellen und Richtungen über die CSV-Dateien bzw. eine Testabfrage mit `aArea=1` verifizieren
2. CORS-Verhalten mit dem obigen `fetch()`-Test prüfen, bei Bedarf eine schlanke Proxy-Funktion aufsetzen
3. Projekt-Grundgerüst als Vite-Projekt (vanilla TypeScript oder eine sehr leichte Bibliothek) aufsetzen
4. `manifest.json` und Service Worker für die Installierbarkeit als PWA ergänzen, inklusive Cache der letzten bekannten Werte, damit beim Öffnen sofort etwas sichtbar ist, während im Hintergrund neu geladen wird
5. Polling-Logik und Zwei-Werte-UI nach obigem Skeleton umsetzen
6. Deployment z. B. über GitHub Pages oder Netlify für das Frontend, Proxy separat als Edge Function
7. Optional später: Tauri-Wrapper um dieselbe Codebasis für ein Desktop-Tray-Widget

---

