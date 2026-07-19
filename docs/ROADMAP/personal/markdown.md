# `markdown.nvim`

## tableize

Soll leerzeichen als trenner akzeptier, also aus

header header2 header 3
ert
zwei zweier
  dreier

entsteht nach `:Markdown table tableize [options?]` hier als option "separator" einfphren, also `:Markdown table tableize " "` folgende table:

| header | header2 | header 3 |
| ------ | ------- | -------- |
| ert    |         |          |
| zwei   | zweier  |          |
|        |         | dreier   |   zwei leerzeich am beginn zeigen: gehrt in col 3

---

