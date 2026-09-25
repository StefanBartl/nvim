# Woche 02 — grep – Rekursiv, Zeilennummern, Kontext

*Monat 1 · Woche 2*

[⬅ Woche 01](./week-01.md) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 03 ➡](./week-03.md)

---

## Rekursiv (-r)

| Linux | PowerShell |
| --- | --- |
| `grep -r "pattern" .` | `Select-String -Pattern "pattern" -Path . -Recurse` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

## Zeilennummern (-n)

| Linux | PowerShell |
| --- | --- |
| `grep -n "pattern" file.txt` | `(LineNumber ist bei Select-String bereits Teil des MatchInfo-Objekts)` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

## Kontext (-C)

| Linux | PowerShell |
| --- | --- |
| `grep -C 2 "pattern" file.txt` | `Select-String -Pattern "pattern" -Path file.txt -Context 2` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

---

## Woche abgeschlossen
- [ ] Alle Themen dieser Woche mindestens 1x durchlaufen

[⬅ Woche 01](./week-01.md) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 03 ➡](./week-03.md)
