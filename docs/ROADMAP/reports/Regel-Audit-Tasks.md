# Regel-Audit — Hand-off tasks for the remaining work

**Date:** 2026-09-19
**Companion to:** [`Regel-Audit-Gesamtstatus.md`](Regel-Audit-Gesamtstatus.md)
(the source of every number and repo list below — as of 2026-09-19 this is the
single consolidated report; it replaced three separate documents this file
originally pointed at), and
[`Roadmap-Aufwand-Nutzen.md`](Roadmap-Aufwand-Nutzen.md) §8.

**What this is:** paste-ready prompts for the fleet-wide `rules.nvim` audit's
remaining work. Status as of 2026-09-19, corrected after cross-checking with
the peer session actually running this campaign:

| Work item | Status |
|---|---|
| `LUA-01` (21 repos) | **Done, 21/21**, including three follow-up fixes from the adversarial verify. Task R3 below is struck |
| `ERR-11` follow-up (6 repos held back earlier) | **In progress** — a live peer session is running it right now |
| `ERR-50` (24 repos) | Not started as its own round. **A live peer session intends to pick this up next**, using its own established prompt pattern rather than the one below — see the note under Task R1 |
| `ERR-22` (22 repos) | Same as `ERR-50` — see Task R2 |
| 313 uncosted rules | Not started, needs a scoping decision first — Task R4 |

---

## Read this before pasting anything

**A live parallel session is running this campaign right now.**
`ListAgents` on 2026-09-19 showed *"Nvim Plugins durchgehen und rules
anwenden"*, running 6+ hours, `busy`. Confirmed directly with that session:
it is presently mid-`ERR-11`-follow-up (six agents running against the
repos an earlier round had to skip), and its own stated plan is `ERR-50`/
`ERR-22` next, over the same repo lists Tasks R1/R2 below use — with its own
prompt pattern, not this file's. It also confirmed `LUA-01` finished at
21/21 (not the 15-remaining state this file originally recorded).

**Do not paste Task R1 or R2 without checking `ListAgents` first.** If that
session (or its successor) is still working `ERR-50`/`ERR-22`, these two
tasks are redundant — kept in this file as a reference pattern in case a
*different* session ever needs to pick the same work up, not as something
to run in parallel with an already-running sweep on the same repos.

**The lesson every completed sweep in this campaign has already paid for,
repeated once more so it isn't relearned a third time:** the repo lists below
are from the 2026-09-18 audit. The `ERR-11` sweep found **10 of 24 checked
repos already clean** — from other work landing in between, not from
anything in that sweep. Every prompt below opens by telling the next session
to audit each repo fresh, not trust the list as a live status.

---

## Task R1 — `ERR-50` sweep: validate config keys before merge

**Source:** `Regel-Audit-Gesamtstatus.md`, section `ERR-50`/`ERR-22`.
**Scope:** 24 repos. **Not started** as its own round.
**Pattern:** the same one `ERR-11` and the CI-fix round already validated —
one agent per repo, fresh audit first, then fix, then local verify (lint +
that repo's own test suite) and push, then a *second*, adversarial agent per
repo that checks the real `git show` diff, not the fix agent's prose summary.

> **Reference only as of 2026-09-19 — check `ListAgents` before pasting.**
> The peer session running the rules.nvim campaign has confirmed this is
> its own stated next step, with its own established prompt pattern. Paste
> this only if that session (or a successor) is not actively on `ERR-50`;
> otherwise use it to compare approaches or hand the work to a *different*
> session, not to run a second sweep over the same repos at the same time.

```
Aufgabe: ERR-50-Regel ("Config-Keys vor dem Merge validieren") über 24 Repos
fahren, nach demselben Muster wie der bereits abgeschlossene ERR-11-Sweep.

Hintergrund: E:/repos/WKDBooks/Development/wkdbook-myplugins/rules.nvim
(Regelkatalog: $REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists) —
Report: C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/reports/
Regel-Audit-Gesamtstatus.md, Abschnitt "ERR-50/ERR-22" (Teil 5).

Betroffene Repos laut Audit vom 2026-09-18 (Startliste, KEIN verlässlicher
Live-Stand — siehe unten): ai, buffer-ctx, cascade, casedesk, cmdlog,
color_my_ascii, dap, debugging, diff, emojis, fileops, filetree, gopath,
images, insights, lib, markdown, my, pdfport, pickers, recommender,
replacer, rules, sessions.

WICHTIG, bevor du anfängst:
1. Per ListAgents prüfen, ob eine parallele Session gerade in einem dieser
   Repos aktiv arbeitet (Stand 2026-09-19: eine Session mit dem Titel "Nvim
   Plugins durchgehen und rules anwenden" lief seit über 6 Stunden). Jedes
   Repo, in dem sie gerade schreibt, für DIESE Runde auslassen — sonst
   Merge-Konflikt-Risiko auf demselben Checkout.
2. Die Repo-Liste oben ist vom 2026-09-18 und wird seither laufend von
   mehreren Sessions verändert. Beim ERR-11-Sweep waren zum Zeitpunkt der
   eigentlichen Prüfung bereits 10 von 24 Repos sauber, ohne dass diese
   Runde etwas dafür getan hätte. Für jedes Repo also FRISCH prüfen, nicht
   die Liste blind übernehmen.

Vorgehen, EIN Agent pro Repo:
1. Frischer Audit gegen den aktuellen Code: wo wird ein Config-Wert beim
   Merge (typischerweise vim.tbl_deep_extend in config/init.lua) NICHT
   gegen einen gültigen Schlüsselsatz geprüft? Ein Tippfehler im
   Nutzer-Config (z.B. "flter" statt "filter") würde dann still ignoriert
   statt einen Fehler oder eine Warnung zu produzieren.
2. Falls ein echter Fund vorliegt: fixen. Die übliche Form ist eine
   validate()-Funktion, die die eingehenden Keys gegen DEFAULTS
   (oder ein explizites Schema) abgleicht und bei Unbekanntem warnt oder
   fehlschlägt — schau dir an, wie andere Plugins in dieser Flotte das
   bereits lösen (z.B. lib.nvim, falls vorhanden), bevor du ein neues
   Muster erfindest.
3. Lokal verifizieren: luacheck, stylua, die Test-Suite des jeweiligen
   Repos.
4. Committen und auf main pushen.
5. Falls KEIN echter Fund vorliegt (Regel bereits erfüllt oder Config hat
   gar keinen Merge-Schritt dieser Art): das ist ein valides Ergebnis, kein
   Fehlschlag — kurz dokumentieren, warum.

Danach EIN zweiter, adversarialer Agent pro Repo mit einem echten Fund: prüft
den tatsächlichen git show-Diff (nicht die Prosa-Zusammenfassung des ersten
Agenten) und insbesondere, ob der Fix wirklich validiert statt nur einen Test
weichzuklopfen. Rückmeldung: CONFIRMED oder Widerspruch mit Begründung.

Nach Abschluss: kurze Zusammenfassung wie beim ERR-11-Sweep — wie viele Repos
hatten einen echten Fund, wie viele waren bereits sauber, welche wurden
wegen paralleler Arbeit ausgeklammert. Diese Zusammenfassung in
Regel-Audit-Gesamtstatus.md nachtragen (ERR-50-Abschnitt aktualisieren,
nicht überschreiben).

Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. Kein
Claude-Co-Author in Commits. Pro Repo eigener Commit, direkt auf main
pushen. Bei Zweifel an einem Fund lieber fragen als raten.
```

---

## Task R2 — `ERR-22` sweep: degrade an invalid value to the default

**Source:** `Regel-Audit-Gesamtstatus.md`, section `ERR-50`/`ERR-22`.
**Scope:** 22 repos, overlapping heavily with `ERR-50`'s list, often the same
`config/init.lua`. **Not started.**

> **Reference only as of 2026-09-19 — same caveat as Task R1.** Check
> `ListAgents` before pasting; the same peer session is expected to reach
> this right after `ERR-50`.

```
Aufgabe: ERR-22-Regel ("ungültiger Wert degradiert auf den Default statt
durchzuschlagen") über 22 Repos fahren, nach demselben Muster wie
ERR-50 (siehe Schwester-Task) und der bereits abgeschlossene ERR-11-Sweep.

Hintergrund: E:/repos/WKDBooks/Development/wkdbook-myplugins/rules.nvim —
Report: C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/reports/
Regel-Audit-Gesamtstatus.md, Abschnitt "ERR-50/ERR-22".

Betroffene Repos laut Audit vom 2026-09-18 (Startliste, KEIN Live-Stand):
ai, cascade, casedesk, cmdlog, color_my_ascii, dap, diff, documentation,
emojis, fileops, filetree, gopath, insights, open, pickers, recommender,
replacer, reposcope, runtime-analysis, sandbox, spotlight, ui.

Wenn du diesen Task UND den ERR-50-Task in derselben Session bearbeitest:
NICHT gemischt, eine Gruppe nach der anderen — beide Regeln sitzen oft im
selben config/init.lua, aber sind unterschiedliche Urteilsmuster (ERR-50:
"ist der Key überhaupt bekannt", ERR-22: "was passiert bei einem bekannten
Key mit ungültigem Wert"). Ein Agent, der zwischen beiden wechselt, verliert
die Konsistenz seiner Entscheidungen — das ist eine explizite Lehre aus dem
bisherigen Audit.

WICHTIG, bevor du anfängst — dieselben zwei Punkte wie beim ERR-50-Task:
1. ListAgents prüfen, betroffene Repos einer aktiven parallelen Session
   auslassen.
2. Jedes Repo frisch prüfen, nicht die Liste von 2026-09-18 blind
   übernehmen (siehe ERR-11: fast die Hälfte der geprüften Repos war
   inzwischen schon sauber).

Vorgehen, EIN Agent pro Repo:
1. Frischer Audit: wo wird ein Config-Wert, der zwar der richtige TYP ist
   aber außerhalb des gültigen Wertebereichs liegt (z.B. ein Enum-Feld mit
   einem unbekannten String, eine negative Zahl wo nur positiv Sinn ergibt),
   ungeprüft durchgereicht statt auf den Default zurückzufallen? Der
   Unterschied zu ERR-50: hier ist der KEY bekannt, nur der WERT ist
   ungültig.
2. Fund fixen: die übliche Form ist eine Prüfung direkt nach dem Merge, die
   einen ungültigen Wert durch den DEFAULTS-Wert ersetzt und (per
   vim.notify/vim.health, je nachdem was das Repo schon nutzt) darauf
   hinweist — nicht stillschweigend, aber auch nicht hart abbrechend.
3. Lokal verifizieren (luacheck, stylua, Test-Suite), committen, pushen.
4. Kein Fund: kurz dokumentieren warum, das ist ein valides Ergebnis.

Danach EIN adversarialer Agent pro Repo mit echtem Fund, gegen den echten
Diff, wie bei ERR-50.

Nach Abschluss: Zusammenfassung in Regel-Audit-Gesamtstatus.md nachtragen
(ERR-22-Abschnitt).

Regeln: Antworte auf Deutsch, Code und Kommentare auf Englisch. Kein
Claude-Co-Author in Commits. Pro Repo eigener Commit, direkt auf main
pushen. Bei Zweifel an einem Fund lieber fragen als raten.
```

---

## Task R3 — `LUA-01` — **done, 21/21, struck 2026-09-19**

This file originally carried a prompt for "the remaining 15 repos". That
premise was wrong by the time it would have been pasted: `LUA-01` finished
at 21/21, including three follow-up fixes the adversarial verify pass
turned up, confirmed directly by the session that ran it. See
`Regel-Audit-Gesamtstatus.md`, section `LUA-01`, for the full record. Left
here as a note rather than deleted outright, so a reader who remembers this
file having an R3 does not go looking for a task that no longer applies.

---

## Task R4 — scope the 313 unchecked rules (a decision, not a blind sweep)

**This is deliberately not a "run it" task.** 313 of 421 rules — the
`recommended`/`nice-to-have` tier, plus the `critical` rules of the gate
families (`NEW`/`REL`) outside their automated part — have never been checked
against any repo. `PERF` alone has 64 rules, `LUA` 59, `UI` 41, each over 95%
unchecked. Running all of it blind, over 38 repos, is a campaign the size of
the entire original audit again, or larger — not something to hand off as one
paste-ready prompt without a decision about scope first.

```
Aufgabe: Entscheidungsvorlage für die 313 ungeprüften rules.nvim-Regeln
erarbeiten — NICHT die Regeln selbst prüfen.

Hintergrund: C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/reports/
Regel-Audit-Gesamtstatus.md, Abschnitt "Die 313 ungeprüften Regeln" (Teil 5)
— dieselbe Datei trägt in Teil 1 auch den vollen Katalog (421 Regeln, 13
Familien).

Bisher geprüft: die 76 `critical`-Regeln der laufend relevanten Familien
(ERR, LUA, SEC, XP, PERF, PRIN, UI, CMT, TS, LLS, DEP). Offen: die
`recommended`/`nice-to-have`-Stufe dieser Familien, plus die `critical`-
Regeln der Gate-Familien NEW/REL außerhalb ihres bereits automatisierten
Teils.

Deine Aufgabe ist NICHT, diese 313 Regeln zu prüfen. Sie ist, mir eine
Empfehlung zu liefern, WELCHE Teilmenge einen Sweep lohnt und WELCHE nicht,
mit Begründung:

1. Lies den Katalog (Checklists-Ordner unter
   $REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Checklists) und ordne die
   313 Regeln grob nach: automatisierbar (hat bereits einen check-Block in
   rules.nvim oder ließe sich leicht einen geben) vs. rein manuelles
   Urteilsvermögen (wie LLS, das laut Roadmap bewusst ein manueller
   Ursachen-Katalog ist, kein check).
2. Für die automatisierbaren: was würde es kosten, sie als check-Blöcke zu
   bauen? Das ist potenziell der bessere Hebel als ein Agent-Sweep — einmal
   gebaut, läuft die Prüfung für immer mechanisch statt bei jedem Audit neu
   von Hand.
3. Für PERF (64 Regeln) und UI (41 Regeln) insbesondere: eine grobe
   Einschätzung, wie viele der Regeln in DIESER Flotte überhaupt greifen
   (manche Performance-Regeln setzen z.B. Hot-Path-Code voraus, den nicht
   jedes Plugin hat) — eine Regel, die in keinem Repo je zutreffen kann,
   lohnt keinen Sweep.
4. Bring mir eine priorisierte Liste: welche Regelgruppe zuerst, mit
   grober Aufwandsschätzung in Sessions, BEVOR irgendein Sweep gestartet
   wird.

Das Ergebnis geht als eigener Abschnitt in
Regel-Audit-Gesamtstatus.md ("Empfehlung für die 313 ungeprüften Regeln"),
nicht als Code-Änderung.

Regeln: Antworte auf Deutsch. Kein Claude-Co-Author in Commits. Report
committen und auf main pushen.
```

---

## After R1/R2/R3 land

Per `Regel-Audit-Gesamtstatus.md`'s own recommendation: re-run `rules.nvim`'s
`check_family_json` over the fleet to confirm the finding count for the 76
automated `critical` rules has gone to zero. This only validates the
automated rules — `LUA-01`/`ERR-50`/`ERR-22` are manual-judgement rules with
no `check` block, so their own completion has to be tracked the way R1–R3
above already do it (per-repo, in `Regel-Audit-Gesamtstatus.md`), not
re-confirmed by the automated run.
