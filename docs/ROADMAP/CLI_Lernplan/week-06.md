# Woche 06 — find -size, -maxdepth

*Monat 2 · Woche 6*

[⬅ Woche 05](./week-05.md) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 07 ➡](./week-07.md)

---

## Dateigröße (-size)

| Linux | PowerShell |
| --- | --- |
| `find . -size +50M` | `Get-ChildItem | Where-Object { $_.Length -gt 50MB }` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

## Suchtiefe (-maxdepth)

| Linux | PowerShell |
| --- | --- |
| `find . -maxdepth 2` | `Get-ChildItem -Depth 2` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

---

## Woche abgeschlossen
- [ ] Alle Themen dieser Woche mindestens 1x durchlaufen

[⬅ Woche 05](./week-05.md) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 07 ➡](./week-07.md)
