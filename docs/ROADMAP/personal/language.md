# language.nvim

## `:TranslateReplace`

Funktioniert, aber es wäre super, wenn die aktueölle formatierung beachtet werden würden, also zb.:

```markdown
  Modify:
    - Was ist bisher passiert, welche steps hast du genau unternommen?
    - Provide scrrenshots direkt vom problem (genau dann wann es auftaucht)
```

Wenn ich hier nun in der  Zeile

```markdown
    - Was ist bisher passiert, welche steps hast du genau unternommen?
```

`'<,'>:TranslateReplace en` also die zeile markerte und dann das usrcmd ausführe, dann übersetze es korrekt, aber es seitzt die aufzählung an den beginn der zeile, also.:

```markdown
- Was ist bisher passiert, welche steps hast du genau unternommen?
```

Machbar?

---

