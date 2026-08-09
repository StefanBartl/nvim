# Checklist — verschoben

Diese Datei enthält keine Checklisten mehr. Kanonische Fassung liegt im `Notes`-Repo:

- [`REVIEW.md`](https://github.com/StefanBartl/Notes/blob/master/MyNotes/Checklists/Lua/REVIEW.md) —
  Schnell-Check + Detailprüfung + Anti-Pattern-Check, vor jedem Merge
- [`RELEASE.md`](https://github.com/StefanBartl/Notes/blob/master/MyNotes/Checklists/Lua/RELEASE.md) —
  Publish-Gate vor Veröffentlichung
- [`PERFORMANCE.md`](https://github.com/StefanBartl/Notes/blob/master/MyNotes/Checklists/Lua/PERFORMANCE.md) —
  Spickzettel für Hotpaths
- [`NEW_PROJECT.md`](https://github.com/StefanBartl/Notes/blob/master/MyNotes/Checklists/Lua/NEW_PROJECT.md) —
  einmalig beim Anlegen eines neuen Projekts
- [`Referenzen/`](https://github.com/StefanBartl/Notes/tree/master/MyNotes/Checklists/Lua/Referenzen) —
  Nachschlagewerk: Sortieralgorithmen, Datenstrukturen, Komplexität, Bitoperationen — jeweils
  Theorie (`*-Ref.md`) und Prüfliste (`*-Check.md`) getrennt
- [`README.md`](https://github.com/StefanBartl/Notes/blob/master/MyNotes/Checklists/Lua/README.md) —
  Übersicht, welche Datei wann gilt

Lokaler Pfad: `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\`

Grund: Die 776 Zeilen dieser Datei mischten Alltags-Checks (Schnell-Check, PR-Review) mit
~420 Zeilen Nachschlagewerk (Algorithmen, Datenstrukturen, Bitops, Komplexität), das nie vor
einem Merge abgehakt wird. Die Trennung macht `REVIEW.md` tatsächlich benutzbar (~150 statt
776 Zeilen), ohne Substanz zu verlieren — sie steht jetzt in `Referenzen/`.
