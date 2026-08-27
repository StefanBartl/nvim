Ausgeführt 2 Befehle

Ich gehe die 32 Memoisierungs-Kandidaten aus dem Report durch, prüfe pro Funktion den tatsächlichen Code (viele mit "Kandidat"-Label sind in Wahrheit Seiteneffekt-Funktionen — Notify, Fenster öffnen, Cache-Build — die man nicht memoisieren darf), und memoisiere nur die echten. Start mit filetree.nvim, dem größten Signal.

Ausgeführt 17 Befehle

Kein sicherer Kandidat bisher gefunden — die Signale waren alle Fehlalarme (schon memoisiert, bereits O(1), oder zeitabhängig/seiteneffektbehaftet). Jetzt documentation.nvim, das im PC-Datensatz (41 Sessions) viel stärkere Signale zeigt als im Workstation-Datensatz (nur 2 Sessions):

Ausgeführt 4 Befehle

Kein Kandidat aus den 32 Memoisierungs-Treffern hält der Prüfung stand — Bericht dazu, dann weiter mit TO_CHECK_FEATURES.

Memoisierung: Ergebnis der Prüfung

Ich habe alle 32 vom Report markierten Kandidaten gegen den tatsächlichen Code geprüft, nicht blind übernommen. Ergebnis: keiner hält. Drei Gründe, alle im Rohdatensatz nachvollziehbar:

Der Report hat einen echten Fehlalarm-Mechanismus: Bei Tabellen-Argumenten zeichnet runtime-analysis.telemetry nur <table:map> auf statt des Inhalts — das macht "100% identisches Argument" bei jeder Funktion mit Tabellen-Parameter trivial wahr, unabhängig vom tatsächlichen Inhalt. Betraf u.a. documentation.nvims check.declared_param_names (33.843 Aufrufe, angeblich "100%") — real bekommt die Funktion bei jedem Aufruf eine andere Funktionsinfo aus dem Codebase-Scan.
Zeit-/zustandsabhängige Funktionen: gopath.nvims cache.needs_refresh hängt von os.time() ab — Memoisieren würde die Staleness-Prüfung selbst kaputt machen. markdown.nvims scope.op_enabled hat ein explizites toggle()/set_enabled() direkt daneben — ein Memo-Cache würde den Toggle stumm brechen. lsp.nvims completion.register.applies hängt von vim.bo.filetype ab, das der Fingerprint gar nicht erfasst.
Bereits erledigt oder bereits billig: cascade.nvims unordered_class ist schon handgerollt gecacht. filetree.nvims feature() ist schon ein reiner Tabellen-Lookup — ein Memo-Cache davor wäre selbst der teurere Schritt. features.load/.require rufen require() auf, das Lua intern schon cached.

Die restlichen literalen Treffer (refs.pathutil.same, util.path.parent, config.get) sind entweder zu selten (~200–800 Aufrufe über Wochen) um den Aufwand zu rechtfertigen, oder bergen ein reales Korrektheitsrisiko (pathutil ist Teil der Datei-Move-Referenz-Umschreibung — ein falsch gecachtes Ergebnis dort wäre stille Datenkorruption, nicht nur Performance).

Kein Code geändert, nichts zu committen — Memoisieren auf Verdacht wäre hier schlechter als nichts tun. Separater Fund am Rande: runtime-analysis.nvims eigene "candidate for memoization"-Heuristik hat den Tabellen-Fehlalarm-Bug — sag Bescheid, falls das gefixt werden soll.
