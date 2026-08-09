# `typepilot.nvim` — Konzept (AI-Provider-Abstraktion)

Angelegt 2026-08-08 aus `E:/repos/Notes/MyPlugin-Notes/nvim-typepilot/typepilot.md`.

---

## Idee

Eine dünne Provider-Abstraktion für AI-Vervollständigung/-Vorschläge in Neovim.
Nicht die AI selbst, sondern nur die Schnittstelle:

```
lua/typepilot/
  init.lua       -- Aktivierung, Provider umschalten
  config.lua     -- API-Keys, Default-Provider
  provider/
    copilot.lua
    chatgpt.lua
    ollama.lua
```

Jeder Provider stellt dasselbe Trio bereit:

```lua
return {
  name = "chatgpt",
  setup = function(cfg) end,      -- API-Key, evtl. Proxy
  suggest = function(context) end -- ruft die AI auf
}
```

UI-Oberfläche: `:TypePilotSuggest`, `:TypePilotUse <provider>`, `:TypePilotInfo`
(aktiver Provider + Key-Status).

Ausdrücklich **nicht** hexagonal aufgebaut — die Notiz verwirft das selbst als
Overkill, und das ist richtig: es gibt kein Domänenmodell, nur Ein- und Ausgabe.

---

## Statuslage und Grundsatzfrage

**Kein Repo unter `E:/repos/`.** Es gibt aber `loomAI` — bevor hier irgendetwas
entsteht, ist zu klären, ob das nicht bereits derselbe Platz ist.

- [x] Geklärt für den Provider-Abstraktions-Teil, siehe
      [ai.nvim.md](./ai.nvim.md) § "Wichtigster Befund zuerst: loomAI
      existiert bereits" (2026-08-08): `loomAI` ist ein eigenständiges
      C++-Multi-Agenten-Framework (Podman-Sandbox, Model Router, Dashboard),
      kein Neovim-Plugin, und aktuell nur ein simulierter SSE-Server ohne
      echten Model-Client. Für eine reine Frage-Antwort/Streaming-Provider-
      Abstraktion für Neovim-Plugins ist das der falsche Platz — dafür ist
      `ai.nvim.md` entstanden. `loomAI` bleibt zuständig für alles, was nach
      autonomem Multi-Step-Agent/Sandbox/Tool-Use riecht.
- [ ] Prüfen, was `loomAI` abdeckt und ob eine Provider-Abstraktion dort
      hingehört statt in ein neues Plugin. (Für Vervollständigung/Copilot-
      artige Vorschläge — `typepilot`s eigentliches Thema — noch offen, s.o.
      nur der allgemeine Provider-Teil ist geklärt.)
- [ ] Zweite Frage: Braucht es das überhaupt? Es gibt fertige Plugins für alle
      genannten Provider. Der Eigenbau lohnt nur, wenn der eigene Workflow etwas
      verlangt, was die nicht können.

**Aufwand (Klärung):** Quick Win
**Nutzen:** hoch — kann das ganze Projekt erledigen.

---

## Was am Konzept übernehmenswert ist, unabhängig vom Plugin

Der eigentliche Wert der Notiz ist die Datenschutz-Position:

> Keine zentrale Key-Verwaltung, keine Speicherung von Keys durch das Plugin.
> Der Key kommt aus der Umgebung (`os.getenv("OPENAI_API_KEY")`), alles bleibt
> lokal beim Nutzer.

- [ ] Diese Regel gilt für **jedes** eigene Plugin, das je einen API-Key
      anfasst — heute schon relevant für `reposcope.nvim` (`GITHUB_TOKEN`) und
      `github_stats.nvim`. Als gemeinsame Regel in `All/Checklists.md`
      festhalten, nicht pro Plugin neu entscheiden.

Konkret dazu passt ein bereits gemachter Befund aus den reposcope-Notizen:
`uv.spawn()`/`vim.system()` erben die Shell-Umgebung **nicht**, ein per
`gh auth login` im Keyring liegender Login ist für Subprozesse unsichtbar. Wer
Keys aus der Umgebung liest, muss sie beim Spawn explizit über `env`
weiterreichen. Siehe `00_MISC.md`.

**Aufwand:** Quick Win
**Nutzen:** hoch — verhindert, dass dieselbe Frage bei jedem AI-/API-Plugin
neu und womöglich anders beantwortet wird.

---

## Falls doch gebaut

- [ ] `suggest(context)` muss asynchron sein — das steht im Entwurf nicht drin
      und ist die wichtigste Auslassung. Ein synchroner Netzwerkaufruf beim
      Tippen friert Neovim ein.
- [ ] Timeout und Abbruch pro Anfrage, sonst hängt ein toter Provider die
      Vervollständigung auf.
- [ ] `:checkhealth typepilot`: welcher Provider aktiv, Key vorhanden ja/nein
      (**nie den Key selbst ausgeben**), Erreichbarkeit.
- [ ] Provider-Registrierung von aussen erlauben, damit ein eigener Provider
      keinen Fork braucht.

**Aufwand:** Mittel (Kern mit zwei Providern), Lang (mit allen dreien + UI)
**Nutzen:** offen — hängt vollständig an der Klärung oben.
