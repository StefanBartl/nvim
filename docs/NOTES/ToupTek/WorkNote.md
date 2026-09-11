**ToupCam (GCMOS01200KPB) – Windows Fix (Stand 2026)**

* **Das Symptom:** Kamera zeigt nur dauerhaft rote LED (Cypress-Chip hat keine Firmware geladen), Software (ToupLite/SharpCap) findet sie nicht, Code 39 im Geräte-Manager.
* **Die Ursache:** Das Windows-Sicherheitsupdate (Kernel Code Integrity / Driver Policy) blockiert den alten, nicht-WHCP-zertifizierten ToupTek-Kernel-Treiber (`toupcam.sys`).
* **Der Workaround:**
1. `.exe`-Installer mit **7-Zip** entpacken, um an die `.inf`-Datei zu kommen.
2. Im **Geräte-Manager** Treiber manuell auf die entpackte `.inf` verweisen (wird als GCMOS01200KPB erkannt).
3. Da Windows den alten Kernel-Treiber blockiert, globalen **Test-Modus** in der Admin-CMD erzwingen:
```cmd
bcdedit /set testsigning on

+ Speicherintegrität ausschalten (mosste man testen, ob das auch mit Speicherintegrät)
```


4. PC neu starten. Danach läuft die Kamera sofort in ToupLite und SharpCap.
