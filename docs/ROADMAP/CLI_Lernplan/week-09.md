# Woche 09 — Pipeline-Magie: find + grep kombiniert

*Monat 3 · Woche 9*

[⬅ Woche 08](./week-08.md) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 10 ➡](./week-10.md)

---

## find mit -exec grep

| Linux | PowerShell |
| --- | --- |
| `find . -name "*.log" -exec grep "Error" {} +` | `Get-ChildItem -Filter *.log -Recurse | Select-String "Error"` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

---

## Woche abgeschlossen
- [ ] Alle Themen dieser Woche mindestens 1x durchlaufen

[⬅ Woche 08](./week-08.md) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 10 ➡](./week-10.md)
