# Diagnostics → RULES: die Ableitung

**Abschluss des Roadmap-Punkts „Diagnostics"** (Abschnitt *Letze Task* in
[`Diagnostics.md`](./Diagnostics.md)). Dies ist der Übergabe-Report: **was**
aus 14 Durchgängen als Regel übriggeblieben ist, **wo** es jetzt steht, und
was bewusst *keine* Regel geworden ist.

Der Inhalt selbst steht **nicht** hier. Er steht in der kanonischen
Regelsammlung, weil er dort gebraucht wird — beim Schreiben von Code in
irgendeinem Repo, nicht beim Planen in dieser Roadmap:

> `E:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\`

Diese Datei ist die Quittung dafür und altert; die Regeln dort tun es nicht.

---

## Table of content

- [Was abgeleitet wurde](#was-abgeleitet-wurde)
- [Wo es steht](#wo-es-steht)
- [Die Entscheidung zur Ablage](#die-entscheidung-zur-ablage)
- [Was bewusst keine Regel geworden ist](#was-bewusst-keine-regel-geworden-ist)
- [Was dabei an der Sammlung selbst falsch war](#was-dabei-an-der-sammlung-selbst-falsch-war)
- [Der Kern in fünf Sätzen](#der-kern-in-fünf-sätzen)

---

## Was abgeleitet wurde

**34 Regeln** (`LLS-01` … `LLS-43`, in Blöcken nummeriert) und **11
Gate-Punkte** (`NEW-36` … `NEW-46`). Jede Regel hat mindestens einen konkreten
Fall aus den 14 Durchgängen hinter sich — das ist die Reihenfolge, die
`Checklists/WORKFLOW.md § F` verlangt: erst der Fall, dann die Regel.

| Block | Was | Anzahl |
| ----- | --- | ------ |
| `LLS-01` … `LLS-08` | **Messgrundlage** — ohne die ist jede Zahl wertlos | 8 |
| `LLS-10` … `LLS-17` | **Annotationen, die parsen** — die acht Formen, die zweistellige Zahlen tragen | 8 |
| `LLS-20` … `LLS-29` | **Typen fremder Herkunft** — Name statt Gestalt, Stand-ins, `vim.*`-Signaturen | 10 |
| `LLS-30` … `LLS-33` | **Verengung und stille Fehler** | 4 |
| `LLS-40` … `LLS-43` | **Unterdrücken** — wann es richtig ist und wie es notiert wird | 4 |
| `NEW-36` … `NEW-46` | **Projektstart** — `.luarc.json`, `TESTS/`, Test-Runner, Nullmessung, `stylua.toml` | 11 |

Dazu vier Zeilen in `gates/REVIEW.md § 8` (Tooling), von denen drei neu sind
und eine eine **falsche** Zeile ersetzt — dazu unten.

---

## Wo es steht

| Datei | Rolle |
| ----- | ----- |
| `Checklists/luals/README.md` | **Dossier** (deskriptiv): Messgrundlage, die vier Ursachenfamilien, die echten Fehler, die der Prüfer gefunden hat, der Test-Runner, die Arbeitsreihenfolge |
| `Checklists/luals/DIAGNOSEN.md` | **Nachschlagetabelle** für den Alltag: Diagnose-Code → wahrscheinlichste Ursachen (nach Häufigkeit) → Griff → Regel-ID |
| `Checklists/regeln/LUA_NVIM.md § LuaLS-Diagnosen` | **Die Regeln**, `LLS-01` … `LLS-43` |
| `Checklists/gates/NEW_PROJECT.md § 3` | **Projektstart**, `NEW-36` … `NEW-46` |
| `Checklists/gates/REVIEW.md § 8` | **Vor jedem Merge**: keine neuen Diagnosen, Unterdrückung begründet, `.luarc.json` korrekt |
| `Checklists/README.md`, `WORKFLOW.md` | Einordnung: was `luals/` ist, wann man es aufschlägt, das Präfix `LLS-` |

Primärquelle bleibt [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) —
jeder Durchgang einzeln, mit `file:line`. Das Dossier ist die Destillation,
nicht der Ersatz.

---

## Die Entscheidung zur Ablage

Vorgeschlagen war ein Ordner `Checklists/luals/`, in dem „allgemein ein Report"
liegt. Das ist so umgesetzt — mit **einer** Abweichung, und die folgt aus dem
Grundsatz der Sammlung selbst (`Checklists/README.md`): *„Jede Regel steht
genau einmal."*

Die Sammlung ist nach **Fragen** geschnitten, nicht nach Themen:
`regeln/` = *Was gilt?*, `gates/` = *Bin ich fertig?*, `belege/` = *Woher kommt
die Regel?*. Ein Ordner, der nach einem **Werkzeug** benannt ist, beantwortet
keine dieser Fragen — läge das Regelwerk dort, gäbe es Regeln an zwei Orten,
und `WORKFLOW.md` hätte keinen Einstiegspunkt dafür.

Deshalb die Aufteilung:

- **`luals/` ist deskriptiv** und beantwortet die Frage, die keine der drei
  Schichten stellt: *wie verhält sich das Werkzeug?* Damit steht es neben
  `nachschlagen/`, nicht neben `regeln/`. Es ist in `README.md` und
  `WORKFLOW.md` als solches eingetragen.
- **Die Regeln stehen in `regeln/`** mit stabilen IDs, wie jede andere Regel —
  referenzierbar aus einem Review-Kommentar, und (laut `KONZEPT.md § 6.1`) die
  Voraussetzung dafür, dass das geplante `rules.nvim` je Befunde auf Regeln
  abbilden kann.
- **Das Dossier wiederholt die Regeln nicht**, es begründet sie; die Regeln
  verweisen zurück. Das ist genau die *Beleg-Kante* aus `KONZEPT.md § 6.2`.

Neues Präfix `LLS-`, weil die Regeln inhaltlich nicht unter `LUA-` passen und
die Nummernkreise kollidiert wären — derselbe Grund, aus dem seinerzeit `TS-`
und `DEP-` dazugekommen sind (`KONZEPT.md § 9`).

---

## Was bewusst keine Regel geworden ist

`WORKFLOW.md § F` sagt: was keinen konkreten Fall hat, ist eine Meinung. Drei
Dinge aus den Durchgängen sind deshalb **nicht** in die Sammlung gewandert:

- **Die Adapter-Designfrage aus filetree** (deklarierte Fähigkeiten, die kein
  Backend implementiert, und fünf Features, die darauf warten). Das ist eine
  Produktentscheidung an einem konkreten Repo.
- **Die drei Aggregator-Strategien von lib.nvim**, die sich nicht decken.
  Dasselbe.
- **Die neun roten Tests in sandbox.nvim.** Ein Bestand, keine Regel.

Alle drei stehen weiter unter *Offen* in [`Diagnostics.md`](./Diagnostics.md).

---

## Was dabei an der Sammlung selbst falsch war

Beim Einsortieren fiel eine Zeile auf, die das Gegenteil dessen verlangte, was
die Erhebung ergeben hat:

> `gates/REVIEW.md § 8`: *„Lua LS Settings — `diagnostics.globals=vim`;
> `workspace.library`; Hints an"*

`workspace.library` in der `.luarc.json` **ersetzt** die Library-Injektion des
LSP-Setups. Wer dieser Zeile folgte, schaltete die Typprüfung für sein ganzes
Repo praktisch ab — das war in **7 von 31** Repos passiert und der teuerste
Einzelfehler der ganzen Reihe. Und `diagnostics.globals=vim` ist genau dann
nötig, wenn `$VIMRUNTIME/lua` **fehlt**; liegt es in der Library, ist `vim`
typisiert statt `any`, und der Eintrag verschenkt das.

Die Zeile ist ersetzt (`LLS-01`, `LLS-03`, `NEW-36` … `NEW-38`). Zwei weitere
Lücken sind dabei geschlossen worden: `NEW_PROJECT.md` hatte **keinen
einzigen** Punkt zu `TESTS/` — der Verzeichnisbaum kannte das Verzeichnis
nicht — und `REVIEW.md` verwies für „Formatter/Linter" auf einen
`NEW_PROJECT`-Abschnitt, in dem `stylua` gar nicht vorkam.

---

## Der Kern in fünf Sätzen

Wenn von der ganzen Erhebung fünf Sätze übrig bleiben sollen, dann diese:

1. **Eine Häufung gleichartiger Befunde ist fast nie eine Häufung von
   Fehlern.** Sie ist eine falsche Messgrundlage oder *ein* Fehler mit vielen
   Symptomen — eine einzige Annotationszeile hat 28 Befunde getragen.
2. **Vor der ersten Zahl die `.luarc.json` lesen.** Ein eigenes
   `workspace.library` macht die Messung wertlos, und zwar in beide
   Richtungen: Phantombefunde *und* Dateibereiche, die nie geprüft wurden.
3. **LuaLS entscheidet Zuweisbarkeit über den Namen, nie über die Gestalt.**
   Daraus folgt fast alles zum Umgang mit fremden Typen — inklusive der
   Tatsache, dass ein `---@cast` quer über zwei unverwandte Klassen selbst
   gemeldet wird.
4. **Ein `pcall` um einen Aufruf, dessen Argumente der Prüfer bemängelt, ist
   nie kosmetisch.** Die Absicherung ist genau das, was den Bruch unsichtbar
   hält.
5. **Ein `undefined-field` verdeckt jede Prüfung, die dahinter läge.** Ein Feld
   zu deklarieren ist nicht das Ende der Arbeit an einer Zeile, sondern ihr
   Anfang.

Und der Satz, der den Aufwand rechtfertigt: **in elf von vierzehn Durchgängen
steckte mindestens ein echter Fehler**, den keine Testsuite gefunden hatte —
weil er entweder nie lief oder in einem `pcall` stumm scheiterte.
