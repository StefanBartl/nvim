# DRM im Browser: EME, CDM, Widevine & Co. – wie das aufgebaut ist und warum

Stand: 2026-10-30 · Zweck: Lernunterlage. Erklärt, **was** DRM im Browser ist, **warum** es so
gebaut ist, **wie** die Schichten technisch zusammenspielen und **wo** die Grenzen liegen.
Bewusst kein Code und keine Anleitung zum Umgehen; der letzte Abschnitt zeigt, wie man das
Thema legal am eigenen Material lernen kann.

## Inhalt

- [1. Warum gibt es DRM überhaupt?](#1-warum-gibt-es-drm-überhaupt)
- [2. Das Bedrohungsmodell: der Nutzer ist der Gegner](#2-das-bedrohungsmodell-der-nutzer-ist-der-gegner)
- [3. Die Schichten im Überblick](#3-die-schichten-im-überblick)
- [4. Schicht A: Inhaltsverschlüsselung (CENC)](#4-schicht-a-inhaltsverschlüsselung-cenc)
- [5. Schicht B: Die Browser-API (EME)](#5-schicht-b-die-browser-api-eme)
- [6. Schicht C: Das Content Decryption Module (CDM)](#6-schicht-c-das-content-decryption-module-cdm)
- [7. Schicht D: Lizenzserver, Geräteidentität, Policy](#7-schicht-d-lizenzserver-geräteidentität-policy)
- [8. Schicht E: Robustheitsstufen (L1/L2/L3, SL2000/SL3000)](#8-schicht-e-robustheitsstufen-l1l2l3-sl2000sl3000)
- [9. Schicht F: Ausgabeschutz (Secure Video Path, HDCP)](#9-schicht-f-ausgabeschutz-secure-video-path-hdcp)
- [10. Warum Chrome oft nur 720p bekommt](#10-warum-chrome-oft-nur-720p-bekommt)
- [11. Whitebox-Kryptografie: wie L3 ohne Hardware auskommt](#11-whitebox-kryptografie-wie-l3-ohne-hardware-auskommt)
- [12. Wo DRM in der Praxis gebrochen wurde (und was daraus folgte)](#12-wo-drm-in-der-praxis-gebrochen-wurde-und-was-daraus-folgte)
- [13. Was man „machen müsste“: die Angriffsflächen und warum jede schwer ist](#13-was-man-machen-müsste-die-angriffsflächen-und-warum-jede-schwer-ist)
- [14. Rechtliche Lage (AT / DE / EU / US)](#14-rechtliche-lage-at--de--eu--us)
- [15. Legal lernen: Hands-on mit ClearKey und eigenem Material](#15-legal-lernen-hands-on-mit-clearkey-und-eigenem-material)
- [16. Glossar](#16-glossar)
- [17. Quellen zum Weiterlesen](#17-quellen-zum-weiterlesen)

---

## 1. Warum gibt es DRM überhaupt?

Kurzfassung: nicht, weil Netflix es will, sondern weil Netflix ohne DRM keine Lizenzen bekäme.

- Studios und Rechteinhaber lizenzieren Filme an Streaming-Dienste nur unter Auflagen. Die
  Branchenorganisation **MovieLabs** (Disney, Paramount, Sony, Universal, Warner) definiert in
  den „Enhanced Content Protection“-Spezifikationen (ECP), was für 4K/HDR/frühe
  Verfügbarkeitsfenster an Schutz nötig ist: Hardware-DRM, sicherer Videopfad, HDCP 2.2+,
  forensisches Wasserzeichen, Widerrufbarkeit kompromittierter Geräte.
- Ohne diese Maßnahmen gibt es den Inhalt gar nicht, oder nur in SD, oder erst Monate später.
- Das Ziel von DRM ist **nicht**, Kopieren unmöglich zu machen (das geht nicht, siehe „analoge
  Lücke“), sondern:
  1. Kopieren so teuer zu machen, dass Massenpiraterie nicht trivial automatisierbar ist,
  2. kompromittierte Geräte/Schlüssel erkennen und **widerrufen** zu können,
  3. eine rechtliche Grundlage zu schaffen: das Umgehen einer „wirksamen technischen
     Maßnahme“ ist eigenständig verboten, unabhängig von der Urheberrechtsverletzung.

Man sollte DRM also als Kombination aus Technik + Vertragsrecht + Strafrecht verstehen. Die
Technik allein wäre nach allen Erfahrungen nicht ausreichend.

---

## 2. Das Bedrohungsmodell: der Nutzer ist der Gegner

In normaler Kryptografie (TLS, Festplattenverschlüsselung) gibt es Alice, Bob und einen
Angreifer in der Mitte. Alice und Bob haben ein gemeinsames Interesse an Geheimhaltung.

Bei DRM ist das anders: Der Inhalt soll auf **dem Gerät des Angreifers** entschlüsselt und
angezeigt werden, und derselbe Angreifer soll den Schlüssel und den Klartext **nicht**
bekommen. Das ist ein grundsätzlicher Widerspruch, und deshalb ist jedes DRM-System
„nur“ eine Frage des Aufwands. Alle Schichten unten dienen dazu, diesen Aufwand so hoch wie
möglich zu treiben und Schäden einzugrenzen, wenn eine Schicht fällt.

Konsequenzen für den Entwurf:

- Schlüssel dürfen nie im normalen Prozessspeicher liegen → separates Modul, idealerweise
  separate Hardware.
- Entschlüsselte Frames dürfen nie im normalen Speicher liegen → sicherer Videopfad bis zum
  Bildschirm.
- Jedes Gerät braucht eine eigene Identität → wenn ein Gerät geknackt wird, verliert nur
  dieses Gerät (bzw. dieses Modell) den Zugang, nicht alle.
- Software muss regelmäßig erneuert werden → Obfuskation veraltet, Versionen werden
  widerrufen.

---

## 3. Die Schichten im Überblick

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Streaming-Dienst (Netflix, Prime, …)                                     │
│   ├─ Packager: verschlüsselt Inhalt mit Content Keys (CENC)             │
│   ├─ CDN: liefert verschlüsselte Segmente (DASH/HLS)                     │
│   └─ Lizenzserver: gibt Content Keys nur an vertrauenswürdige CDMs      │
└─────────────────────────────────────────────────────────────────────────┘
                 │ verschlüsselte Segmente          ▲ Lizenz-Challenge
                 ▼                                  │ / Lizenz-Response (opak)
┌─────────────────────────────────────────────────────────────────────────┐
│ Browser                                                                  │
│   JavaScript-Player (Shaka, dash.js, Netflix-eigener)                   │
│     ├─ MSE: appendBuffer(verschlüsseltes Segment)                        │
│     └─ EME: requestMediaKeySystemAccess → MediaKeys → Session           │
│              │ initData (pssh)      ▲ license request/response (Blobs)  │
│              ▼                      │                                   │
│   ┌──────────────────────────────────────────────────────────┐          │
│   │ CDM (Widevine / PlayReady / FairPlay) – eigene Sandbox   │          │
│   │   Geräteschlüssel · Lizenz entschlüsseln · Policy prüfen │          │
│   │   Content Key → Samples entschlüsseln (→ ggf. dekodieren)│          │
│   └──────────────────────────┬───────────────────────────────┘          │
└──────────────────────────────┼──────────────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Hardware / OS                                                            │
│   TEE (TrustZone, SGX-Nachfolger, Apple Secure Enclave): L1-Entschlüsselung│
│   GPU: geschützte Oberflächen (Protected Media Path / PAVP)              │
│   Display-Link: HDCP                                                     │
└─────────────────────────────────────────────────────────────────────────┘
```

Merksatz: **Der JavaScript-Player sieht nie einen Schlüssel und nie einen Klartext-Frame.**
Er ist nur der Bote, der verschlüsselte Segmente an MSE und opake Blobs zwischen CDM und
Lizenzserver hin- und herträgt. Darum nützt ein MSE-Hook bei DRM nichts: man bekommt
Chiffrat.

---

## 4. Schicht A: Inhaltsverschlüsselung (CENC)

**Common Encryption** (ISO/IEC 23001-7) ist der gemeinsame Nenner, mit dem **eine**
verschlüsselte Datei von **mehreren** DRM-Systemen abgespielt werden kann (Widevine in Chrome,
PlayReady in Edge, FairPlay in Safari). Der Dienst muss den Inhalt nur einmal packen.

Kernideen:

- **Nur die Samples werden verschlüsselt**, nicht der Container. `moov`, `moof`, Zeitstempel,
  Sample-Größen bleiben im Klartext → der Player kann puffern, spulen, Bitraten wechseln,
  ohne irgendetwas entschlüsseln zu müssen.
- **Subsample-Verschlüsselung**: Bei H.264/H.265 bleiben die NAL-Header und Slice-Header im
  Klartext, nur die Nutzdaten der Slices sind verschlüsselt. Damit kann ein Decoder die
  Struktur parsen, bevor die Entschlüsselung erfolgt. Das ist eine Anforderung aus der
  Hardware-Welt (Decoder brauchen Header-Infos zum Einrichten).
- **Zwei Schemata**:
  - `cenc`: AES-128-CTR, volle Subsample-Verschlüsselung. Klassisch (Widevine, PlayReady).
  - `cbcs`: AES-128-CBC mit „Pattern Encryption“ (z. B. 1 von 10 Blöcken verschlüsselt).
    Von Apple/FairPlay vorgegeben, inzwischen von allen unterstützt. Das Muster spart
    Rechenzeit und erlaubt Hardware-Decodern, mit teilweise verschlüsselten Daten zu arbeiten.
  - Ein Dienst, der alle Browser bedienen will, packt heute oft **zweimal** (`cenc` und
    `cbcs`) oder nur `cbcs`.
- **Schlüssel-Identifikation**: Jede Spur (oder jedes Qualitätslevel, oder jede Periode) hat
  einen **Key ID (KID)**, 16 Byte, im Klartext in der `tenc`-Box des Init-Segments. Der KID
  sagt dem CDM, *welchen* Schlüssel es braucht, nicht den Schlüssel selbst.
- **`pssh`-Boxen** (Protection System Specific Header): Pro DRM-System eine Box mit einer
  System-ID (UUID: Widevine `edef8ba9-…`, PlayReady `9a04f079-…`, ClearKey `1077efec-…`)
  und systemspezifischen Daten (bei Widevine ein Protobuf mit KIDs, Content-ID, Provider).
  Das ist die „initData“, die später an EME geht. Dieselbe Info steht meist auch im
  DASH-Manifest (`<ContentProtection>`) oder in der HLS-Playlist (`#EXT-X-KEY` mit
  `KEYFORMAT`).
- **Key-Rotation**: Bei Live-Streams wechseln die Content Keys periodisch; neue `pssh` im
  Stream lösen neue Lizenzanfragen aus.
- **Schlüsselhierarchie** (typisch):
  - Content Key(s) pro Asset/Spur → verschlüsseln die Samples.
  - Lizenz → enthält Content Keys, verschlüsselt für genau ein CDM (Session Key), plus
    Policy.
  - Geräteschlüssel (Device/Client Private Key) → entschlüsselt die Lizenz. Lebt im CDM
    bzw. in der Hardware.
  - Root-of-Trust → Zertifikatskette, mit der der Lizenzserver das Gerät als echt erkennt.

---

## 5. Schicht B: Die Browser-API (EME)

**Encrypted Media Extensions** (W3C-Empfehlung seit 2017) ist die JavaScript-API, über die
eine Webseite ein DRM-System anspricht. EME ist bewusst so entworfen, dass die Seite **nichts
Geheimes** sieht: sie reicht Blobs durch. Der Ablauf (konzeptionell, ohne Code):

1. **Fähigkeiten abfragen.** Die Seite ruft `navigator.requestMediaKeySystemAccess` mit dem
   Namen des Key Systems (`com.widevine.alpha`, `com.microsoft.playready.recommendation`,
   `com.apple.fps`, `org.w3.clearkey`) und einer Liste gewünschter Konfigurationen
   (Codecs, Container, Robustheitsstufe wie `HW_SECURE_ALL` oder `SW_SECURE_CRYPTO`,
   persistente Lizenzen ja/nein). Der Browser antwortet mit der ersten Konfiguration, die er
   erfüllen kann, oder lehnt ab. **Hier entscheidet sich bereits**, ob der Dienst später 4K
   oder 720p ausliefert (siehe Abschnitt 10).
2. **MediaKeys erzeugen.** Aus dem Access-Objekt entsteht ein `MediaKeys`-Objekt (das ist der
   JavaScript-Griff zum CDM-Instanz). Optional lädt die Seite ein **Server-Zertifikat**
   ins CDM (`setServerCertificate`): damit verschlüsselt das CDM seine Geräteidentität in der
   Lizenzanfrage für den Lizenzserver, sodass der Dienst selbst (und Mithörer) sie nicht sehen
   („Privacy Mode“, bei Widevine üblich).
3. **An das Video binden.** `video.setMediaKeys(mediaKeys)`: ab jetzt weiß die Media-Pipeline,
   dass verschlüsselte Samples an dieses CDM gehen.
4. **`encrypted`-Event.** Sobald MSE (oder der Demuxer) ein Init-Segment mit `pssh` sieht,
   feuert das Video-Element ein `encrypted`-Event mit `initDataType` (`cenc`, `keyids`,
   `webm`) und `initData` (die pssh-Bytes). Die Seite darf die initData auch aus dem Manifest
   nehmen und früher starten („pre-fetching licenses“).
5. **Session erzeugen und Request bauen.** `mediaKeys.createSession()` (temporär oder
   persistent), dann `session.generateRequest(initDataType, initData)`. **Das CDM** baut
   daraus eine Lizenzanfrage: KIDs, Geräte-Zertifikat, Nonce, gewünschte Rechte, signiert mit
   dem Geräteschlüssel. Die Seite bekommt diese Anfrage im `message`-Event als
   undurchsichtigen `ArrayBuffer`.
6. **Lizenz holen.** Die Seite schickt den Blob per `fetch` an **ihren** Lizenzserver (URL,
   Auth-Header, Abo-Prüfung sind Sache des Dienstes; EME definiert das nicht). Der Server
   prüft Gerät + Abo + Policy und antwortet mit einem Lizenz-Blob.
7. **Lizenz einspielen.** `session.update(licenseResponse)`. Das CDM entschlüsselt die Lizenz
   mit dem Geräteschlüssel, extrahiert die Content Keys und die Policy (Ablauf, Mietfenster,
   HDCP-Anforderung, erlaubte Auflösung pro Robustheit).
8. **`keystatuseschange`.** Die Seite erfährt pro KID nur einen Status: `usable`, `expired`,
   `output-restricted` (z. B. HDCP fehlt), `internal-error`. Nie den Schlüssel.
9. **Abspielen.** MSE übergibt die verschlüsselten Samples, die Pipeline reicht sie ans CDM,
   das entschlüsselt (und ggf. dekodiert) und gibt Frames in den Renderpfad.
10. **Aufräumen.** `session.close()`, bei persistenten Sessions `session.remove()` (erzeugt
    eine signierte Quittung für den Server, dass der Offline-Schlüssel gelöscht wurde).

Wichtige Designentscheidungen in EME:

- **Keine Schlüssel in JS.** Selbst beim offenen `org.w3.clearkey` liefert die Seite den
  Schlüssel *hinein* (als JSON Web Key in `update`), bekommt ihn aber nicht aus dem CDM
  zurück.
- **Key System ist austauschbar.** Dieselbe Seite läuft mit Widevine in Chrome, PlayReady in
  Edge, FairPlay in Safari, weil die Seite nur Blobs transportiert.
- **Robustheit ist Teil des Vertrags.** Die Seite fordert eine Robustheit, der Browser
  garantiert sie oder lehnt ab. Das ist der Hebel, mit dem Dienste Software-DRM auf niedrige
  Auflösung beschränken.
- **Persistente Lizenzen** (Offline-Download) brauchen explizite Erlaubnis im Browser und ein
  „Persistent State“-Flag; der Nutzer kann sie unter Site-Daten löschen.

---

## 6. Schicht C: Das Content Decryption Module (CDM)

Das CDM ist das Stück **proprietäre Software** (oder Hardware-Treiber), das die eigentliche
Arbeit macht. EME ist offen; das CDM ist es nicht. Das war 2013–2017 die zentrale Kritik an
EME (EFF, FSF): Ein W3C-Standard, der ein Closed-Source-Binary zur Pflicht macht.

### Die drei relevanten Systeme

| CDM | Anbieter | Browser | Besonderheit |
|---|---|---|---|
| **Widevine** | Google | Chrome, Edge (als Zweit-CDM), Firefox, Opera, Brave, Android, Chromecast, viele Smart-TVs | Marktführer; drei Stufen L1/L2/L3. |
| **PlayReady** | Microsoft | Edge (Windows), Xbox, viele Smart-TVs, Set-Top-Boxen | Integriert in Windows Media Foundation; SL2000 (Software) / SL3000 (Hardware). |
| **FairPlay Streaming** | Apple | Safari (macOS/iOS), Apple TV | Nur HLS, nur `cbcs`, Hardware (Secure Enclave / T2 / Apple Silicon) auf allen aktuellen Geräten. |
| ClearKey | W3C-Standard | alle | Kein DRM: Schlüssel im Klartext, nur zum Testen und für Fälle ohne Schutzbedarf. |

### Wie das CDM in den Browser kommt (Beispiel Chrome/Widevine)

- Chrome liefert Widevine als **Komponente** aus, die unabhängig vom Browser aktualisiert
  wird (`chrome://components` → „Widevine Content Decryption Module“). Datei auf Windows:
  `widevinecdm.dll` im Nutzerprofil unter `WidevineCdm/<version>/_platform_specific/win_x64/`.
- Firefox lädt das Modul als **GMP** (Gecko Media Plugin) beim ersten Bedarf herunter
  (`about:support` → „Media“ zeigt es), sichtbar auch als Opt-in-Dialog.
- Chromium ohne Google-Branding (z. B. Ungoogled, manche Linux-Pakete) hat kein Widevine;
  Google lizenziert es nur an Partner. Deshalb funktioniert Netflix dort nicht.
- Die Schnittstelle zwischen Browser und CDM ist dokumentiert (Chromium: `media/cdm/api/
  content_decryption_module.h`, Versionen „CDM_10/11“). Sie beschreibt Methoden wie
  „Initialize“, „CreateSessionAndGenerateRequest“, „UpdateSession“, „Decrypt“,
  „DecryptAndDecodeFrame“, aber nicht, was im Modul passiert.

### Prozess- und Sandbox-Architektur

- Chrome lädt das CDM in einen **eigenen Utility-Prozess** („CDM Service“) mit strenger
  Sandbox (kein Netzwerk, kein Dateisystem außer dem Lizenz-Store). Grund: Schutz des
  Nutzers vor dem Binary (falls es Lücken hat) **und** Schutz des Binaries vor dem Nutzer
  (schwieriger, von anderen Prozessen aus hineinzuschauen; auf Windows zusätzlich
  „Protected Process“-Mechanismen).
- Zwei Betriebsarten:
  - **Decrypt-only**: CDM entschlüsselt die Samples und gibt **Klartext-Samples** an den
    normalen Browser-Decoder zurück. Das ist Widevine L3 (Software) in Chrome: Zwischen CDM
    und Decoder existiert der Klartext im Speicher des Browsers (wenn auch in einem
    Sandbox-Prozess).
  - **Decrypt-and-Decode**: CDM entschlüsselt **und** dekodiert selbst und gibt fertige
    Frames aus, idealerweise direkt in geschützten GPU-Speicher. Das ist L1 / Hardware-DRM:
    Klartext-Samples existieren nirgends außerhalb der Hardware.

---

## 7. Schicht D: Lizenzserver, Geräteidentität, Policy

### Geräteidentität

Jedes CDM hat eine Identität, die beim Hersteller provisioniert wurde:

- **Widevine**: eine „Keybox“ (bei Hardware: in der Fabrik in Fuses/Secure Storage
  gebrannt) oder ein OEM-Zertifikat, aus dem beim ersten Start per **Provisioning** gegen
  Googles Server ein **Gerätezertifikat** (RSA-2048-Schlüsselpaar + Zertifikatskette bis zur
  Widevine-Root) abgeleitet wird. Im Lizenzrequest steht die „Client ID“ (Zertifikat,
  Hersteller, Modell, Sicherheitsstufe, CDM-Version), signiert mit dem Geräteschlüssel.
- **PlayReady**: ähnlich, „Device Certificate“ aus einer Microsoft-Zertifikatskette, mit
  Angaben zu Security Level und Fähigkeiten.
- **FairPlay**: Apple-Geräte mit Secure Enclave; die Identität ist an die Hardware gebunden.

Die Identität ist das wertvollste Geheimnis im System. Wer den Geräteschlüssel hat, kann
sich gegenüber jedem Lizenzserver als dieses Gerät ausgeben und bekommt Content Keys,
die er dann mit gewöhnlichem AES anwenden kann. Das ist der Grund, warum die ganze Härte
der Obfuskation und der Hardware auf diesen einen Schlüssel konzentriert ist, und warum
„geleakte L3-Keys“ das klassische Schadensbild ist (siehe Abschnitt 12).

### Was der Lizenzserver prüft

1. Signatur und Zertifikatskette des Geräts (ist das ein echtes Widevine-Gerät?).
2. Steht das Gerät/Modell/die CDM-Version auf der **Widerrufsliste**?
3. Welche **Sicherheitsstufe** behauptet es, und passt die zur angeforderten Qualität?
4. Dienst-eigene Logik: Hat der Account ein Abo? Wie viele gleichzeitige Streams? Welches
   Land? (Diese Prüfung passiert im Dienst-Backend, das den Widevine-„License Proxy“ oder
   den eigenen Server davorschaltet.)

### Was in der Lizenz steht (Policy)

- Content Keys (pro KID), verschlüsselt für genau diese Session.
- Gültigkeit: Ablaufzeit, Mietfenster („48 h ab erstem Abspielen“), Erneuerungsintervall
  (Streams holen alle paar Minuten eine „Renewal“, damit der Server Sessions zählen kann).
- **Output-Regeln pro Schlüssel**: Mindest-HDCP-Version (keine / 1.4 / 2.2), ob analoge
  Ausgabe erlaubt ist, ob die Auflösung begrenzt werden muss, wenn HDCP fehlt
  (`output-restricted` in EME).
- Erforderliche Sicherheitsstufe pro Schlüssel: z. B. „SD-Key: L3 reicht; HD-Key: L1
  nötig“. Damit kann ein Dienst in **einer** Lizenz mehrere Qualitätsstufen ausliefern und
  das CDM verweigert selbst, was es nicht darf.
- Bei Widevine ist das Format ein Protobuf („License“ mit „KeyContainer“s und „Policy“);
  bei PlayReady XML („XMR“-Binärformat), bei FairPlay ein CKC (Content Key Context).

---

## 8. Schicht E: Robustheitsstufen (L1/L2/L3, SL2000/SL3000)

### Widevine

| Stufe | Wo läuft was | Typische Geräte | Wofür reicht es |
|---|---|---|---|
| **L1** | Entschlüsselung **und** Dekodierung in der TEE (ARM TrustZone / herstellereigenes „OEMCrypto“), Frames über sicheren Pfad zur GPU. | Android-Flaggschiffe, Chromecast, Smart-TVs, Chrome auf Windows mit „Hardware-secure decryption“ über Media Foundation + unterstützte GPU/Intel-CPU | HD, 4K, HDR (je nach Dienst). |
| **L2** | Entschlüsselung in der TEE, Dekodierung außerhalb. | Selten (ältere Geräte). | Meist wie L3 behandelt. |
| **L3** | Alles in Software, geschützt nur durch Obfuskation (Whitebox). | Desktop-Browser (Standard), Android ohne TEE-Integration, gerootete Geräte, Emulatoren | SD / 720p, manche Dienste 1080p. |

Die Stufe ist **Teil der Geräteidentität** und wird vom Hersteller bei der Zertifizierung
festgelegt. Ein Gerät kann sich nicht selbst zu L1 erklären; der Lizenzserver sieht die Stufe
im Zertifikat. Ein Android-Handy, das gerootet oder mit entsperrtem Bootloader läuft, fällt
oft von L1 auf L3 zurück, weil die TEE die Vertrauenskette als gebrochen meldet.

### PlayReady

- **SL2000**: Software, aber mit Anforderungen an Obfuskation und Betriebssystem-Schutz.
- **SL3000**: Hardware („Hardware DRM“ in Windows: Media Foundation + Protected Media Path +
  GPU-Unterstützung). Edge auf Windows mit passender Intel-/AMD-/NVIDIA-Hardware → Netflix
  4K. Das ist der Grund, warum Netflix 4K im Browser lange **nur** in Edge (und Safari) ging.

### FairPlay

Apple unterscheidet keine Stufen nach außen; alle aktuellen Geräte sind hardware-gebunden.
Safari auf Macs mit T2/Apple Silicon bekommt 4K, ältere Intel-Macs ohne T2 nicht.

### Warum Desktop lange L3 war

Auf dem PC gibt es keine standardisierte TEE wie TrustZone, die Hardwarevielfalt ist groß,
und Nutzer haben Admin-Rechte. Erst mit Protected Media Path (Windows) + GPU-Verschlüsselung
(Intel PAVP, AMD/NVIDIA-Pendants) wurde Hardware-DRM auf dem PC praktikabel, zuerst über
PlayReady (Microsoft kontrolliert OS + Browser), später auch Widevine über denselben
Media-Foundation-Unterbau. Linux-Desktops haben keine solche Kette → dauerhaft L3.

---

## 9. Schicht F: Ausgabeschutz (Secure Video Path, HDCP)

Selbst wenn Schlüssel und Entschlüsselung sicher sind: irgendwann muss ein Bild auf den
Bildschirm. Der Ausgabeschutz soll verhindern, dass man *dort* abgreift.

### Secure Video Path / Protected Media Path

- Die dekodierten Frames liegen in **geschütztem GPU-Speicher**, den CPU-Prozesse nicht
  lesen können (Hardware-Enforcement). Der Compositor darf diese Oberflächen nur mit dem
  Display verbinden, nicht in normale Texturen kopieren.
- Windows: „Protected Media Path“ (seit Vista), „Protected Environment“, GPU-Treiber mit
  „Protected Audio/Video Path“ (PAVP bei Intel). macOS: ähnliches über IOSurface-Schutz und
  die Secure Enclave. Android: „Secure Buffers“ aus dem TEE direkt an den Display-Controller.
- **Das ist der Grund für den schwarzen Bildschirm** in OBS/Screenshots bei Edge+Netflix,
  Safari+Apple TV+ oder Chrome mit Hardware-DRM: Die Capture-API bekommt für geschützte
  Oberflächen Schwarz. Bei Chrome im reinen L3-Modus (Software-Decode in den normalen
  Renderpfad) klappt eine Bildschirmaufnahme dagegen oft, und man bekommt eben die L3-Qualität
  (720p). Das illustriert das Prinzip: Der Dienst gibt nur so viel heraus, wie die Kette
  schützt.

### HDCP (High-bandwidth Digital Content Protection)

- Verschlüsselung auf dem **Kabel** (HDMI/DisplayPort) zwischen GPU und Monitor. Der Monitor
  authentifiziert sich mit einem Zertifikat; ohne HDCP-fähigen Monitor gibt die Lizenz keinen
  HD-Schlüssel frei (`output-restricted`).
- HDCP 1.x ist seit 2010 gebrochen (Master Key geleakt), HDCP 2.2/2.3 gilt als deutlich
  stärker; deshalb verlangen 4K-Inhalte 2.2+.
- „HDCP-Stripper“ (HDMI-Splitter, die HDCP entfernen) existieren und werden
  genau deshalb rechtlich als Umgehungsgeräte eingestuft.

### Die analoge Lücke

Am Ende leuchtet ein Bildschirm, und eine Kamera kann ihn filmen. Das ist die
**akzeptierte** Grenze von DRM: Der Aufwand ist hoch, die Qualität schlecht, und forensische
Wasserzeichen (unsichtbare, pro Session unterschiedliche Muster im Bild) erlauben, eine
solche Kopie dem Abo zuzuordnen. DRM will diese Lücke nicht schließen, sondern sie so teuer
wie möglich machen und nachvollziehbar.

---

## 10. Warum Chrome oft nur 720p bekommt

Zusammengesetzt aus den Schichten oben:

1. Chrome (Standardkonfiguration) meldet in `requestMediaKeySystemAccess` nur
   Software-Robustheit (`SW_SECURE_DECODE`/`SW_SECURE_CRYPTO`), kein `HW_SECURE_*`.
2. Der Dienst fragt die zurückgegebene Konfiguration ab und wählt ein Manifest, das nur
   bis 720p (oder 1080p) geht, **oder** liefert ein volles Manifest, dessen Lizenz die
   HD-Keys mit „nur für L1“ markiert, sodass das CDM sie verweigert.
3. Zusätzlich prüft die Lizenz HDCP; fehlt es, bleibt es bei SD.

Deshalb: Netflix in Chrome meist 720p (mit L1-Hardware-Kette inzwischen 1080p/4K), in Edge
mit SL3000 4K, Prime Video in Firefox/Chrome L3 oft nur 480p/720p, Disney+ 720p im Browser
ohne Hardware-DRM. Es ist keine technische Beschränkung des Codecs, sondern reine Policy
der Lizenz, die auf dem Vertrauensniveau des Geräts beruht.

---

## 11. Whitebox-Kryptografie: wie L3 ohne Hardware auskommt

L3 muss ein Geheimnis (den Geräteschlüssel) in einem Programm verstecken, das der Angreifer
vollständig besitzt, debuggen und patchen kann. Das Werkzeug dafür heißt
**Whitebox-Kryptografie**:

- Die AES-/RSA-Operationen werden so umgeschrieben, dass der Schlüssel **nie als Wert im
  Speicher** steht, sondern in riesige, zufällig „kodierte“ Lookup-Tabellen eingebacken ist.
  Jede Runde der Chiffre wird zu Tabellenzugriffen, und zwischen den Runden liegen zufällige
  bijektive Kodierungen, sodass Zwischenwerte nicht den Standard-AES-Zwischenwerten
  entsprechen.
- Dazu kommen klassische Software-Schutzmaßnahmen: Control-Flow-Flattening, Anti-Debugging,
  Integritätsprüfungen des eigenen Codes, Virtualisierungs-Obfuskation (eigener Bytecode-
  Interpreter), Prüfung auf Hook-Frameworks und Emulatoren, „Trusted Time“ gegen
  Uhrmanipulation.
- Akademisch gilt Whitebox-AES seit ~2004 als gebrochen (BGE-Angriff, später Differential
  Computation Analysis und Differential Fault Analysis, die mit Techniken aus der
  Hardware-Seitenkanalanalyse funktionieren). Praktisch bedeutet das: Jede Whitebox-
  Implementierung hat ein **Ablaufdatum**. Deshalb:
  - Widevine liefert alle paar Monate neue L3-CDM-Versionen mit neuer Obfuskation aus.
  - Alte Versionen werden serverseitig **widerrufen** (Lizenzserver lehnen sie ab) → Browser
    erzwingen das Komponenten-Update.
  - Der Schaden eines L3-Bruchs ist auf L3-Qualität begrenzt (720p). Die Architektur rechnet
    damit, dass L3 fällt.

Das ist der Grund, warum Hardware (TEE) der eigentliche Schutz ist und L3 nur „gut genug für
SD“: Software kann ihr eigenes Geheimnis nicht dauerhaft vor dem Besitzer des Rechners
schützen.

---

## 12. Wo DRM in der Praxis gebrochen wurde (und was daraus folgte)

Öffentlich dokumentierte Fälle, die das Modell illustrieren:

- **HDCP 1.x Master Key (2010)**: Veröffentlicht, danach HDCP 2.x mit anderem
  Kryptodesign. Lehre: Ein globaler Schlüssel ist ein Single Point of Failure → alle
  neueren Systeme haben Gerätezertifikate und Widerruf.
- **Widevine L3 per Differential Fault Analysis (2019, David Buchanan)**: Demonstration, dass
  der Whitebox-Schlüssel aus dem Chrome-CDM extrahierbar ist. Google antwortete mit neuer
  Obfuskation und Widerruf der Version. Lehre: L3 ist Zeitgewinn, kein Schutz.
- **Android-L3-Keys („CDMs“) im Umlauf**: Regelmäßig tauchen Gerätezertifikate von
  L3-Android-Geräten auf (aus Emulatoren oder gerooteten Geräten extrahiert). Sie
  funktionieren so lange, bis Google sie widerruft; die Dienste beschränken L3 zusätzlich
  per Policy auf niedrige Auflösung. Open-Source-Bibliotheken, die das Widevine-
  **Protokoll** nachbauen (Lizenzrequest formatieren, Lizenz parsen), sind für sich allein
  nutzlos: Ohne gültiges Gerätezertifikat gibt kein Server einen Schlüssel heraus. Das
  Zertifikat ist der geschützte Teil, nicht das Protokoll.
- **Widevine L1 auf bestimmten Android-SoCs (2020–2022)**: Schwachstellen in TEE-
  Implementierungen (Qualcomm, MediaTek) erlaubten in Einzelfällen das Auslesen der
  OEMCrypto-Schlüssel. Folge: Firmware-Updates, Widerruf betroffener Modelle, zeitweise
  Rückstufung ganzer Gerätefamilien auf L3. Lehre: Auch Hardware ist nur so gut wie ihre
  Firmware, aber der Schaden bleibt auf Modellebene begrenzt.
- **PlayReady SL3000 / 4K-Leaks**: Vereinzelt 4K-Kopien von Streaming-Diensten im Umlauf,
  Herkunft vermutlich kompromittierte Set-Top-Boxen oder Smart-TV-Plattformen mit
  Hardware-DRM. Die Dienste reagieren mit forensischen Wasserzeichen und Account-Sperren.
- **Analoge Lücke und HDMI-Capture**: Geräte, die HDCP entfernen, gibt es; sie sind in der
  EU und den USA als Umgehungswerkzeuge verboten, Verkauf und Besitz zu Umgehungszwecken
  sind strafbar.

Gemeinsames Muster: Der Bruch trifft eine Stufe, das System **grenzt ein, widerruft,
rotiert** und läuft weiter. Nie fiel das Gesamtsystem.

---

## 13. Was man „machen müsste“: die Angriffsflächen und warum jede schwer ist

Dieser Abschnitt beschreibt konzeptionell, **wo** ein Angreifer ansetzen könnte, damit die
Architektur verständlich wird. Er ist keine Anleitung; jede der Flächen ist in AT/DE/EU
rechtlich untersagt (Abschnitt 14) und technisch jenseits eines Hobbyprojekts.

| Fläche | Idee | Warum es schwer ist / was dagegen gebaut wurde |
|---|---|---|
| **1. Klartext nach dem CDM abgreifen** (Decrypt-only, L3) | Im Sandbox-Prozess liegen nach dem Decrypt Klartext-Samples, bevor sie zum Decoder gehen. | Prozess-Sandbox, Protected-Process-Flags, Anti-Debugging im CDM, Integritätsprüfungen des Browsers. Und: nur L3-Qualität (720p), weil HD-Keys gar nicht erst ausgegeben werden. Bei L1 existiert diese Stelle nicht. |
| **2. Frames nach dem Decoder abgreifen** (Bildschirmaufnahme, GPU-Hook) | Dekodierte Frames in GPU-Texturen lesen. | Geschützte GPU-Oberflächen (Hardware-enforced), Compositor liefert Schwarz an Capture-APIs. Bei L3-Software-Decode funktioniert es, wieder nur in L3-Qualität, dazu Re-Encode-Verlust. |
| **3. Geräteschlüssel aus dem Software-CDM extrahieren** (Whitebox-Angriff) | Mit DFA/DCA den eingebetteten Schlüssel rekonstruieren, dann selbst Lizenzen holen und CENC per AES entschlüsseln. | Starke, ständig wechselnde Obfuskation; Versionen werden widerrufen; Ergebnis ist ein L3-Zertifikat → nur SD/720p-Keys. Forschungsaufwand im Bereich von Wochen bis Monaten pro Version. |
| **4. Geräteschlüssel aus der TEE extrahieren** (L1) | Firmware-Lücken, Fault-Injection (Spannungs-/Takt-Glitching), Seitenkanäle, Debug-Ports. | Hardware-Angriffe mit Laborausstattung; pro Chip/Firmware individuell; nach Bekanntwerden Widerruf des Modells. Zertifikat ist an Gerätemodell gebunden, forensisches Wasserzeichen identifiziert Account. |
| **5. Lizenzserver täuschen** | Replay, Downgrade auf schwächere Robustheit, Manipulation der Client-ID. | Signaturen mit Geräteschlüssel, Nonces, Server-Zertifikat verschlüsselt Client-ID, Robustheit steht im signierten Zertifikat. Ohne (3) oder (4) keine gültige Signatur. |
| **6. Ausgabe nach HDCP abgreifen** | HDMI-Capture hinter einem HDCP-Stripper. | Geräte sind illegal; HDCP 2.2+ bisher nicht öffentlich gebrochen; Wasserzeichen; Qualität ist die der Ausgabe, Re-Encode nötig. |
| **7. Analoge Lücke** | Kamera auf Bildschirm. | Legal unproblematischer, aber Qualität miserabel, Wasserzeichen bleiben erhalten. |
| **8. Vor der Verschlüsselung** | Insider beim Dienst, kompromittierte Packaging-Pipeline. | Organisatorische Sicherheit, Zugriffskontrolle, Wasserzeichen in Pre-Release-Material (die „Screener“-Leaks, die man aus den Nachrichten kennt). |

Was man daraus für die eigene App mitnimmt: Der einzige Ort, an dem **legal und zuverlässig**
Klartext zu haben ist, liegt **vor** EME: bei Inhalten, die den DRM-Weg gar nicht gehen.
Dort sitzt der MSE-Hook aus dem Konzept. Sobald `requestMediaKeySystemAccess` aufgerufen
wird, ist die Antwort für das Tool: anzeigen, dass DRM aktiv ist, und aufhören.

---

## 14. Rechtliche Lage (AT / DE / EU / US)

Keine Rechtsberatung; Paragraphen als Einstieg zum Nachlesen.

### EU-Rahmen

- **Richtlinie 2001/29/EG (InfoSoc), Art. 6**: Mitgliedstaaten müssen „angemessenen
  Rechtsschutz gegen die Umgehung wirksamer technischer Maßnahmen“ vorsehen, **und** gegen
  Herstellung, Einfuhr, Verbreitung, Verkauf, Vermietung, Werbung und den gewerblichen Besitz
  von Umgehungsmitteln.
- „Wirksam“ heißt nach der Rechtsprechung (u. a. EuGH C-355/12 *Nintendo/PC Box*; BGH
  I ZR 124/11 *Videospiel-Konsolen*): Die Maßnahme muss das Ziel im normalen Betrieb
  erreichen, nicht unknackbar sein. Dass etwas mit einem Tool trivial zu umgehen ist, macht
  es nicht „unwirksam“.

### Österreich (UrhG)

- **§ 90c UrhG**: Schutz technischer Maßnahmen. Verbot der Umgehung wirksamer technischer
  Maßnahmen sowie von Herstellung/Vertrieb/Besitz zu kommerziellen Zwecken von
  Umgehungsmitteln. Zivilrechtliche Ansprüche (Unterlassung, Beseitigung, Schadenersatz).
- **§ 91 UrhG**: Strafbestimmung; vorsätzliche Eingriffe, bei gewerbsmäßiger Begehung
  höhere Strafdrohung.
- **§ 42 UrhG**: Vervielfältigung zum eigenen/privaten Gebrauch. Erlaubt, aber nach
  herrschender Lesart **kein Anspruch auf Umgehung** von Schutzmaßnahmen, um die Privatkopie
  zu ermöglichen (§ 90c kennt keine entsprechende Ausnahme für Privatkopien).

### Deutschland (UrhG)

- **§ 95a UrhG**: Verbot der Umgehung wirksamer technischer Maßnahmen (Abs. 1) und von
  Herstellung, Einfuhr, Verbreitung, Verkauf, Vermietung, Werbung, gewerblichem Besitz von
  Umgehungsmitteln (Abs. 3).
- **§ 108b UrhG**: Strafvorschrift (Freiheitsstrafe bis 1 Jahr oder Geldstrafe; bei
  gewerblichem Handeln bis 3 Jahre). **Ausnahme**: Umgehung ausschließlich zum eigenen
  privaten Gebrauch ist nach § 108b Abs. 1 nicht strafbar, bleibt aber nach § 95a
  **rechtswidrig** (zivilrechtliche Ansprüche).
- **§ 53 UrhG**: Privatkopie; § 95a geht vor, d. h. keine Privatkopie durch Umgehung.

### USA

- **DMCA § 1201**: Umgehungsverbot und Verbot von Umgehungswerkzeugen. Alle drei Jahre
  Ausnahmen durch das Copyright Office (z. B. für Bildung, Barrierefreiheit, Reparatur),
  aber keine allgemeine Privatkopie-Ausnahme für Streaming-DRM.

### Was das praktisch heißt

- **Lernen, lesen, verstehen, analysieren**: erlaubt. Das Studium von Spezifikationen,
  Chromium-Quellcode, Forschungspapern und eigener Teststreams ist legal.
- **Ein Tool bauen, das Widevine/PlayReady/FairPlay umgeht**: verboten (Herstellung eines
  Umgehungsmittels), unabhängig davon, ob man es nur selbst benutzt.
- **Ein Tool bauen, das DRM-freie Streams speichert**: Vervielfältigung ohne Umgehung →
  Privatkopie-Regeln, Nutzungsbedingungen der Seite beachten. Das ist der Rahmen des
  Konzepts in [01-konzept-video-capture.md](01-konzept-video-capture.md).
- **Grauzone HLS-AES-128 mit offenem Schlüssel**: Ob eine „wirksame“ Maßnahme vorliegt, ist
  nicht höchstrichterlich entschieden; angesichts der großzügigen Auslegung von „wirksam“
  ist Vorsicht geboten.

---

## 15. Legal lernen: Hands-on mit ClearKey und eigenem Material

Alles unten läuft mit eigenem Material und offen spezifizierten Werkzeugen; es wird nichts
umgangen.

### 15.1 Eigenen CENC-Stream bauen und mit ClearKey abspielen

1. **Material**: ein eigenes MP4 (Bildschirmaufnahme, Testbild von ffmpeg erzeugt).
2. **Packen und verschlüsseln** mit **Shaka Packager** (Open Source, Google): erzeugt
   DASH-Manifest + fMP4-Segmente, verschlüsselt mit einem selbst gewählten KID/Key im
   `cenc`- oder `cbcs`-Schema, und schreibt `pssh`-Boxen für ClearKey (und auf Wunsch
   Widevine-„Test“-pssh). Alternativ `ffmpeg` mit `-encryption_scheme cenc-aes-ctr`.
3. **Ansehen, was entstanden ist**: Mit `mp4dump` (Bento4) oder `MP4Box -info` (GPAC) das
   Init-Segment öffnen: `tenc`-Box (KID, Default-IV-Größe), `pssh`-Box(en), `sinf`/`schm`
   (Schema `cenc`/`cbcs`), in den Media-Segmenten die `senc`/`saiz`/`saio`-Boxen mit
   Subsample-Tabellen (welche Bytes verschlüsselt sind). Das macht Abschnitt 4 greifbar.
4. **Abspielen** mit **Shaka Player** oder **dash.js** in einer lokalen HTML-Seite, Key
   System `org.w3.clearkey`, Schlüssel als JSON Web Key konfiguriert. In den DevTools die
   EME-Ereignisse beobachten: `encrypted`, `message`, `keystatuseschange`. Damit ist
   Abschnitt 5 einmal komplett durchlebt.
5. **Gegenprobe**: Dieselben Segmente mit dem eigenen MSE-Hook aus dem Konzept abgreifen →
   es kommt Chiffrat heraus (`mdat` ist Rauschen, `moof` lesbar). Mit `mp4decrypt`
   (Bento4) und dem **eigenen** Key wieder entschlüsseln → identisch zum Original. Das
   zeigt, dass CENC nur die Samples betrifft.

### 15.2 EME im Browser beobachten

- `chrome://media-internals` zeigt pro Player die Pipeline-Ereignisse, inklusive Key-System,
  Robustheit und Key-Status.
- `chrome://components` → Widevine-Version; `about:support` in Firefox → GMP-Status.
- Auf der Shaka-Player-Demo-Seite gibt es Testinhalte mit Widevine-Lizenzserver (Googles
  UAT-Proxy). Dort kann man mit der Konfiguration (`robustness`) spielen und sehen, wie
  `requestMediaKeySystemAccess` reagiert, ohne irgendetwas zu umgehen.
- DevTools → Netzwerk: Lizenzrequests sind POSTs mit `application/octet-stream`, man sieht
  Größe und Timing, nicht den Inhalt (Protobuf, verschlüsselte Teile).

### 15.3 Lesen

- Chromium-Quellcode: `media/cdm/`, `media/base/cdm_*`, `third_party/widevine/cdm/`
  (nur die öffentlichen Header), `content/browser/media/cdm_*`. Dort steht, wie der Browser
  das CDM lädt, in welchen Prozess, und welche Schnittstelle er spricht.
- Firefox: `dom/media/eme/`, `dom/media/gmp/` (Gecko Media Plugins).
- Shaka-Player-Dokumentation („DRM“-Tutorial) erklärt die praktische Seite aus Sicht eines
  Dienstes: Lizenzserver-URLs, Header, Robustheit, persistente Lizenzen.

### 15.4 Verwandte Themen zum Weiterlernen

- Forensische Wasserzeichen (A/B-Watermarking in Segmenten: zwei Varianten jedes Segments,
  pro Session unterschiedliche Folge → Kopie identifiziert Account).
- TEE-Architektur allgemein (ARM TrustZone, GlobalPlatform TEE API), unabhängig von DRM
  relevant für Payment, Biometrie, Schlüsselspeicher.
- Whitebox-Kryptografie-Papers (Chow et al. 2002, BGE 2004, DCA 2016) als Lektüre, wie man
  Kryptografie unter „Angreifer besitzt das Gerät“ denkt und warum es scheitert.

---

## 16. Glossar

| Begriff | Bedeutung |
|---|---|
| **CDM** | Content Decryption Module: proprietäres Modul, das Lizenzen verarbeitet und Samples entschlüsselt. |
| **CENC** | Common Encryption (ISO/IEC 23001-7): Standard, wie MP4-Samples verschlüsselt werden, systemunabhängig. |
| **`cenc` / `cbcs`** | Die zwei CENC-Schemata: AES-CTR bzw. AES-CBC mit Pattern. |
| **EME** | Encrypted Media Extensions: W3C-JavaScript-API für DRM im Browser. |
| **Key System** | Kennung eines DRM-Systems in EME (`com.widevine.alpha`, …). |
| **KID** | Key ID: 16-Byte-Kennung eines Content Keys, im Klartext in der Datei. |
| **pssh** | Protection System Specific Header: Box mit DRM-spezifischen Initialisierungsdaten. |
| **initData** | Die Bytes, die EME aus `pssh` (oder Manifest) an das CDM gibt. |
| **License / Lizenz** | Vom Lizenzserver signiertes Paket mit Content Keys und Policy, für ein CDM verschlüsselt. |
| **Policy** | Regeln in der Lizenz: Ablauf, HDCP, Auflösung pro Robustheit. |
| **Robustness** | Angeforderte/garantierte Sicherheitsstufe (`SW_SECURE_CRYPTO` … `HW_SECURE_ALL`). |
| **L1 / L2 / L3** | Widevine-Sicherheitsstufen (Hardware / gemischt / Software). |
| **SL2000 / SL3000** | PlayReady-Sicherheitsstufen (Software / Hardware). |
| **TEE** | Trusted Execution Environment: isolierter Prozessormodus (TrustZone) mit eigenem OS. |
| **OEMCrypto** | Widevines Hardware-Schnittstelle, die Gerätehersteller in der TEE implementieren. |
| **Provisioning** | Erstmaliges Ableiten eines Gerätezertifikats aus der Fabrik-Keybox. |
| **Secure Video Path / PMP** | Geschützter Weg dekodierter Frames bis zum Display, für CPU nicht lesbar. |
| **HDCP** | Verschlüsselung auf dem Display-Kabel. |
| **ClearKey** | EME-Key-System ohne Geheimnis; Schlüssel kommt von der Seite. Nur zum Testen. |
| **Whitebox-Krypto** | Technik, Schlüssel in Code/Tabellen zu verstecken; Basis von L3. |
| **Widerruf (Revocation)** | Server lehnt bestimmte Gerätezertifikate oder CDM-Versionen ab. |
| **Analoge Lücke** | Die Unmöglichkeit, das Abfilmen eines Bildschirms zu verhindern. |

---

## 17. Quellen zum Weiterlesen

Alles öffentlich zugänglich; Stand der URLs Oktober 2026, bei Bedarf nach Titel suchen.

- W3C: *Encrypted Media Extensions* (Recommendation) – https://www.w3.org/TR/encrypted-media/
- W3C: *Media Source Extensions* – https://www.w3.org/TR/media-source-2/
- ISO/IEC 23001-7 *Common encryption in ISO base media file format files* (kostenpflichtig;
  die Struktur ist in den Shaka-Packager- und Bento4-Dokus gut zusammengefasst)
- Google: *Widevine DRM Architecture Overview* (öffentliches PDF auf widevine.com)
- Microsoft: *PlayReady Documentation* – https://learn.microsoft.com/playready/
- Apple: *FairPlay Streaming* – https://developer.apple.com/streaming/fps/
- MovieLabs: *Enhanced Content Protection* Specification – https://movielabs.com/
- Chromium Source: `media/cdm/api/content_decryption_module.h`
- Shaka Player: *DRM Tutorial* – https://shaka-player-demo.appspot.com/docs/api/tutorial-drm-config.html
- Shaka Packager – https://shaka-project.github.io/shaka-packager/
- Bento4 (`mp4dump`, `mp4decrypt`, `mp4encrypt`) – https://www.bento4.com/
- Mozilla Hacks: *Firefox and the Encrypted Media Extensions* (Hintergrund zur GMP-Architektur)
- EFF: *Encrypted Media Extensions* (Kritik und Geschichte der Standardisierung)
- Chow, Eisen, Johnson, van Oorschot: *White-Box Cryptography and an AES Implementation* (2002)
- Bos, Hubain, Michiels, Teuwen: *Differential Computation Analysis* (CHES 2016)
- Gesetzestexte: RIS (ris.bka.gv.at) für §§ 42, 90c, 91 öUrhG; gesetze-im-internet.de für
  §§ 53, 95a, 108b dUrhG; EUR-Lex für 2001/29/EG
