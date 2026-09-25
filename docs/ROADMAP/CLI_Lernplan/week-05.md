# Woche 05 — find -mtime

*Monat 2 · Woche 5*

[⬅ Woche 04](./week-04.md) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 06 ➡](./week-06.md)

---

## Änderungsdatum (-mtime)

| Linux | PowerShell |
| --- | --- |
| `find . -mtime -3` | `Get-ChildItem | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-3) }` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

---

## Woche abgeschlossen
- [ ] Alle Themen dieser Woche mindestens 1x durchlaufen

[⬅ Woche 04](./week-04.md) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 06 ➡](./week-06.md)
