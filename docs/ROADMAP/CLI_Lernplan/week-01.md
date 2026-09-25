# Woche 01 — grep – Grundlagen

*Monat 1 · Woche 1*

⬅ (Start) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 02 ➡](./week-02.md)

---

## Einfache Suche

| Linux | PowerShell |
| --- | --- |
| `grep "pattern" file.txt` | `Select-String -Pattern "pattern" -Path file.txt` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

## Case-insensitive (-i)

| Linux | PowerShell |
| --- | --- |
| `grep -i "pattern" file.txt` | `Select-String ist standardmäßig case-insensitive; -CaseSensitive erzwingt Groß-/Kleinschreibung` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

## Invertiert (-v)

| Linux | PowerShell |
| --- | --- |
| `grep -v "pattern" file.txt` | `Select-String -Pattern "pattern" -Path file.txt -NotMatch` |

**Wiederholungen:**
- [ ] Durchlauf 1
- [ ] Durchlauf 2
- [ ] Durchlauf 3

---

## Woche abgeschlossen
- [ ] Alle Themen dieser Woche mindestens 1x durchlaufen

⬅ (Start) · [Lernplan-Konzept](../LONG_RUN/learn-cli.nvim.md) · [Woche 02 ➡](./week-02.md)
