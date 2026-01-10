# Roadmap für das `neotree`-Modul

## Bugs

---

## Allgemein

1. Modularisieren des `config/neotree`-Folders
2. Neotree soll rechts öffnen, dann spar ich mir code und dort ist auch mehr platz
3. neotree: open neotree soll sich die position merken auf der ich das letzt mal ihn zugeamdht habe, wenn ich  ihn das nö ächste mal aufrufe unf J oder R eingebe, dann reveal, ansonsten nicht
4. keymap setzt das cwd den ordner in der die file ist. kann auch ein M-CR sein oder ähnlich
5. [Neotree]() mappings so schreiben, dass auch nvimtree/netrw möglich wäre
    . DAs bedeutet auch, dass alle lib funktionen inerhalb der filtree filesystem ist, danmit keine dependencies entstehen
    I. Die meisten helper sollten eigenltich als commands implementiert werden

---

## Ideas

1. Unified Error Handling: Alle Fehler über zentrales Modul loggen
2. Async Operations: Lange Copy-Operations async machen
3. Progress Feedback: Bei großen File-Listen Progress anzeigen
4. Configuration: Notification-Level konfigurierbar machen
5. Testing: Unit-Tests für alle betroffenen Funktionen (könnte man gleich Neotest testen)

---

## neue Mappings

--
