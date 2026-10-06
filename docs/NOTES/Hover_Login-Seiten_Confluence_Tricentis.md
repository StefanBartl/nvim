# hover.nvim: Confluence und andere Tricentis-Seiten im Hover

Stand: 2026-10-06. Persönliche Notiz, deshalb deutsch. Die allgemeine,
englische Erklärung steht im Plugin-Repo:
`hover.nvim/docs/WORKFLOW-LOGIN-PAGES.md` (dazu `docs/FEATURES/PINS.md` und
`docs/FEATURES/AUTH.md` für die Begründungen).

## Das Problem in einem Satz

Der Hover ist **absichtlich anonym**: `curl` schickt keine Cookies, und der
Browser für Screenshots (`links.shot`) startet mit einem Wegwerf-Profil. Eine
Seite hinter SSO liefert deshalb immer das Login-Formular, egal wie gut gerendert
wird. Dein eingeloggter Chrome hilft nicht, weil seine Cookies nicht
weitergegeben werden (Chrome verschlüsselt sie an die App, und sie an einen
Browser zu geben, der fremde Seiten ausführt, wäre ein Leck).

## Die drei Wege

| Weg | Wofür | Aufwand |
| --- | --- | --- |
| **Pin** (`links.pins`) | eine **Seite**, deren Aussehen du kennst: du speicherst sie einmal als PDF/PNG, der Hover zeigt die Datei | klein, kein Token |
| **Auth** (`links.auth`) | ein **Dokument** (PDF-Export, Anhang): der Hover lädt es mit deinem Token | Token + 3 Schalter |
| **`<CR>`** auf dem Float | die echte Seite, in deinem Browser mit deiner Sitzung | nichts |

**Wichtig, damit keine falsche Erwartung entsteht:** Eine normale
Confluence-Seite (`/wiki/spaces/…/pages/…`) ist eine JavaScript-App. Auch mit
Token bekommt der Hover dieselbe App zurück, nicht den Seiteninhalt. Der Token
hilft nur bei Links, die direkt ein PDF liefern. Für „die Seite, wie sie
aussieht“ gibt es nur den Pin.

## Dein Tenant: `tricentis.atlassian.net`

Aus deinen WKDBook-Notizen: Confluence und Jira laufen auf **demselben Host**.

| Pfad | Was es ist |
| --- | --- |
| `/wiki/...` | Confluence |
| `/browse/ABC-123`, `/jira/...` | Jira |

Ein Atlassian-API-Token gehört zu deinem **Konto**, nicht zu einem Produkt. Eine
Regel mit dem Host deckt also Confluence **und** Jira ab.

### 1. Token ablegen (einmalig, Windows)

Den Token hast du schon erzeugt. Nicht in eine Datei im Repo und nicht in den
Chat. In PowerShell:

```powershell
setx CONFLUENCE_TOKEN "<dein-token>"
```

Danach **Terminal und Neovim neu starten**. Eine laufende Sitzung behält ihre
alte Umgebung, das ist der häufigste Grund für „sendet nichts“.

Hygiene:

- Die nvim-Config ist ein Git-Repo. In die Config gehört nur der **Name**
  `CONFLUENCE_TOKEN`, nie der Wert.
- Ist der Token einmal irgendwo gelandet, wo er nicht hingehört: unter
  <https://id.atlassian.com/manage-profile/security/api-tokens> widerrufen und
  neu erzeugen.
- Der Token darf dort ein Ablaufdatum haben. Läuft er ab, kommt `HTTP 401` im
  Float. Dann neu erzeugen und `setx` wiederholen.

### 2. Zuerst von Hand prüfen, ob der Export mit Token geht

Bevor irgendetwas im Plugin konfiguriert wird. Das trennt „Token/Rechte falsch“
von „Plugin falsch“. In PowerShell (`curl.exe`, nicht `curl`, sonst greift der
PowerShell-Alias):

```powershell
curl.exe -sS -o NUL -w "%{http_code} %{content_type}\n" -u "DEINE-ATLASSIAN-MAIL:$env:CONFLUENCE_TOKEN" "https://tricentis.atlassian.net/wiki/spaces/flyingpdf/pdfpageexport.action?pageId=SEITEN-ID"
```

- `DEINE-ATLASSIAN-MAIL` ist die E-Mail deines **Atlassian-Kontos** (die, mit der
  du dich bei Tricentis einloggst), nicht automatisch deine private.
- `SEITEN-ID` ist die Zahl in der Seiten-URL: `…/pages/`**`123456789`**`/Titel`.
- `200 application/pdf` (oder ein Redirect, der dort endet): der Hover kann das
  auch.
- `401` oder `403`: falsche Mail, abgelaufener Token oder fehlende Berechtigung.
  Das ist dann kein Plugin-Problem.
- Hinweis: Dieser Export-Pfad ist **von mir nicht gegen euer Confluence getestet**.
  Geht er nicht, ist der Pin trotzdem der sichere Weg.

### 3. Config

Gehört in den bestehenden `require("hover").setup({ ... })`-Aufruf in
`lua/plugins/personal/specs/navigate.lua` (Spec `StefanBartl/hover.nvim`, ab
Zeile ~234). Nur den `links`-Block ergänzen/erweitern:

```lua
links = {
  web = true,
  fetch = true,                 -- ohne fetch tut auth nichts
  pdf = { enabled = true },     -- zeigt ein PDF-Dokument als erste Seite
  auth = {
    { match = "tricentis.atlassian.net",
      user = "DEINE-ATLASSIAN-MAIL",
      token_env = "CONFLUENCE_TOKEN" },
  },
  pins = {
    -- siehe unten
  },
},
```

Danach `:checkhealth hover`: es zeigt pro Regel, ob die Variable gesetzt ist
(den Wert nie), und meldet übersprungene Regeln.

Regeln, die das Plugin erzwingt (Absicht, damit ein Fehler **nichts** schickt
statt zu viel):

- `match` darf im **Host-Teil kein `*`** haben. `*.atlassian.net` wird abgelehnt,
  sonst bekäme jeder Atlassian-Tenant deinen Token, auch der eines Angreifers.
  Der Pfad-Teil darf `*` haben (`tricentis.atlassian.net/wiki/*`).
- Nur `https`, Redirects nur auf `https`.
- Der Token geht per stdin an curl, nicht in die Prozessliste.
- Gilt **nicht** für `links.shot` (Browser).

### 4. Eine Seite pinnen (der Weg für „die Seite, wie sie aussieht“)

1. Seite eingeloggt im Browser öffnen.
2. `Strg+P` → Ziel „Als PDF speichern“. Oder Screenshot der ganzen Seite:
   DevTools `Strg+Umschalt+P` → „Capture full size screenshot“.
3. Datei **außerhalb jedes Repos** ablegen, z. B. `C:\Users\bartl\hover-pins\`.
   Das PDF enthält Firmeninhalt. Nicht ins WKDBook-Repo und nicht in die
   nvim-Config legen, sonst landet es im Git.
4. Pin eintragen:

```lua
pins = {
  -- Confluence-Seite, mit und ohne Titel am Ende der URL
  { match = "tricentis.atlassian.net/wiki/spaces/*/pages/123456789*",
    show = "~/hover-pins/mein-thema.pdf" },
  -- Jira-Ticket
  { match = "tricentis.atlassian.net/browse/ABC-123",
    show = "~/hover-pins/ABC-123.png" },
},
```

Das Glob-Muster:

- `*` ist der einzige Platzhalter und trifft alles, auch `/`.
- Ohne `/` im Muster wird nur der **Host** verglichen, mit `/` Host + Pfad + Query.
- `?` ist ein normales Fragezeichen (so beginnt eine Query).
- Schema, `#fragment` und Groß/Klein sind egal.
- **Der erste Treffer gewinnt.** Spezifisches vor Allgemeinem eintragen.
- Eine relative `show`-Angabe gilt relativ zur nvim-Config, nicht zum Dokument.

Verhalten im Alltag:

- PDF: `<C-Down>`/`<C-Up>` blättert, `>` zoomt, `F` Vollbild.
- Der Pin funktioniert auch mit `links.web = false`.
- Ein Pin **aktualisiert sich nicht**. Ändert sich die Seite, neue Datei machen.
- Fehlt die Datei, steht „pinned file not found“, nicht die Login-Seite.
- `<CR>` auf dem Float öffnet die **echte URL** im Browser, nicht die Datei.
- `:Hover why` sagt „pinned: …“, wenn ein Pin das Gezeigte ist.

## Andere Tricentis-Seiten

Aus den Hosts in deinem WKDBook. Ob eine Seite öffentlich ist, siehst du in
10 Sekunden: `curl.exe -sSI https://HOST/` – `200` ohne Redirect auf eine
Login-Seite heißt öffentlich.

| Host (aus deinen Notizen) | Was vermutlich | Empfehlung |
| --- | --- | --- |
| `docs.tricentis.com`, `documentation.tricentis.com` | Produktdokumentation | wahrscheinlich öffentlich: nur `links.fetch`, **kein** Auth. Mit `curl -sSI` prüfen |
| `learn.tricentis.com`, `academy.tricentis.com` | Schulung | ebenso prüfen; wenn Login: Pin |
| `support-hub.tricentis.com`, `support.tricentis.com` | Support-Portal mit SSO | keine statische Token-API. **Pin**, oder `<CR>` |
| `*.my.tricentis.com`, `*.my-sap.tricentis.com` (Kunden-Tenants, z. B. palfinger) | Produktinstanzen | **keine** Auth-Regel mit Wildcard (Kunden-Tenants gehören anderen). Pin, oder `<CR>` |
| `horizon.tricentis.com` | Web-App | JavaScript-App hinter Login. **Pin** |
| `tricentisgmbh.sharepoint.com`, `…-my.sharepoint.com` | SharePoint/Microsoft 365 | OAuth-Token mit kurzer Laufzeit, kein fester Wert für eine Umgebungsvariable. **Pin** |
| `tricentiscsm*.service-now.com` | ServiceNow | mit SSO kein Token-Zugang. **Pin**. (`auth` kann technisch Basic mit Benutzer + Passwort, nur sinnvoll mit einem eigens dafür angelegten Integrationsbenutzer, nicht mit deinem Konto) |
| `tricentis.slack.com` | Slack | nicht sinnvoll |

**Merkregel:** `auth` nur für einen Host, bei dem du selbst einen statischen
API-Token erzeugen kannst und der Link direkt ein Dokument liefert. Für alles
andere ist der Pin die Antwort, und `<CR>` ist immer als Ausweg da.

Willst du für einen zweiten Host einen Token, kommt eine zweite Regel mit
**eigener Variable** dazu (`token_env = "ANDERER_TOKEN"`), nie derselbe Token für
mehrere Dienste.

## Wenn es nicht geht

Immer von der Position zur Installation arbeiten:

| Symptom | Prüfen | Meist |
| --- | --- | --- |
| Auf der URL passiert nichts | `:Hover why` | `links.web` aus und kein Pin passt. Ein Pin macht die URL findbar, eine ungepinnte bleibt abgelehnt |
| Pin wird ignoriert | `:lua print(require("hover.pins").matches("https://URL", "muster"))` | Muster: mit `/` = Host+Pfad, ohne `/` = nur Host. Erster Treffer gewinnt |
| „pinned file not found“ | `:checkhealth hover` | Datei verschoben. Health listet jeden Pin mit fehlender Datei |
| Auth sendet nichts | `:checkhealth hover` | Variable in **diesem** Neovim nicht gesetzt (nach `setx` neu starten), oder Regel wegen Wildcard im Host übersprungen |
| Immer noch Login-Formular | der `curl.exe`-Test oben | Die URL ist eine Seite, kein Dokument. Pin |
| `HTTP 401` im Float | der `curl.exe`-Test oben | falsche Mail, abgelaufener oder widerrufener Token |

## Was nicht gebaut ist (und warum)

- **Cookies aus deinem Browser übernehmen:** Chrome verschlüsselt sie an die App,
  das Profil ist gesperrt, und ein Browser, der Seitenskripte ausführt, ist der
  falsche Empfänger.
- **Login im Hover durchführen:** das Float ist ein Bild und nimmt keine Eingabe
  an. SSO/MFA braucht einen echten Browser.
- **Eigenes dauerhaftes Browser-Profil mit einmaligem Login (`:Hover login`):**
  grundsätzlich möglich, nicht gebaut. Kosten: die Sitzung läuft ab, und der
  private Seiteninhalt landet im Cache. Wenn dir Pins zu mühsam werden, ist das
  der nächste Schritt.
- **Automatisch aus einer Seiten-URL die PDF-Export-URL ableiten:** erst sinnvoll,
  wenn der `curl.exe`-Test oben für euer Confluence `200 application/pdf` liefert.

## Commits (Plugin, Stand dieser Notiz)

- `de23de6` feat(pins) – Links als eigene Datei zeigen
- `12d9843` feat(auth) – Fetch und PDF-Download an benannte Hosts authentifizieren
