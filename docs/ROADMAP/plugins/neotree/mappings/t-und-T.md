Ideen / Verbesserungspunkte für die Implementierung:

* **Konfigurierbare Ignore-Liste**

  * Separate Tabelle `ignored_dirs` für Ordnernamen wie `.git`, `node_modules` oder `dist`.
  * Einfach erweiterbar ohne Anpassung der Traversierungslogik.

* **Ignore-Check beim Traversieren**

  * Prüft jeden Unterordner gegen `ignored_dirs` und überspringt ihn, wenn match.
  * Nutzt eine kleine Utility-Funktion `is_ignored_dir(name)`.

* **Ausnahme für explizit ausgewählte Node**

  * Wenn das Mapping direkt auf einer Node ausgeführt wird, die auf der Ignore-Liste steht, wird diese Node trotzdem kopiert.
  * Verhindert, dass bewusste Aktionen vom Ignore-Filter blockiert werden.

* **Stack-basierte Traversierung**

  * Schon implementiert, vermeidet zu tiefe Rekursion.
  * Kann optional noch verbessert werden, um z. B. **Symlinks** oder **Fehler bei Berechtigungen** konsistenter zu behandeln.

* **Optionale Wildcards / Fallunempfindlichkeit**

  * Ignored-Namen könnten später unterstützt werden wie `node_*` oder `.git*`.
  * Erleichtert flexiblere Ausschlüsse ohne explizite Namensauflistung.

* **Relative vs. Absolute Pfade**

  * Bereits bestehende Optionen `relative_to_cwd` sollten weiterhin korrekt funktionieren.
  * Prüfen, dass Ignore-Filter keine relativen Pfade falsch behandelt.

* **Logging / Debug**

  * Debug-Notifies nur auf `DEBUG`-Level, keine Unterbrechung bei Permission-Fehlern.
  * Optional kann man Warnungen für ignorierte Nodes hinzufügen, falls gewünscht.

* **Unit-Test / Simulation**

  * Später kann eine kleine Test-Funktion prüfen, ob `collect_files_recursive` korrekt ignorierte Ordner überspringt, ohne die explizit ausgewählte Node zu blockieren.

---

