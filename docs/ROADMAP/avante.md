
   Error  21:28:32 msg_show.lua_error    Lua callback: ...Data/Local/nvim-data/lazy/avante.nvim/lua/avante/llm.lua:283: Make sure to build avante (missing avante_templates)
stack traceback:
	[C]: in function 'error'
	...ata/Local/nvim-data/lazy/avante.nvim/lua/avante/path.lua:293: in function 'get_templates_dir'
	...Data/Local/nvim-data/lazy/avante.nvim/lua/avante/llm.lua:283: in function 'generate_prompts'
	...Data/Local/nvim-data/lazy/avante.nvim/lua/avante/llm.lua:479: in function 'calculate_tokens'
	.../Local/nvim-data/lazy/avante.nvim/lua/avante/sidebar.lua:2775: in function 'get_generate_prompts_options'
	.../Local/nvim-data/lazy/avante.nvim/lua/avante/sidebar.lua:3043: in function 'initialize_token_count'
	.../Local/nvim-data/lazy/avante.nvim/lua/avante/sidebar.lua:2556: in function 'show_input_hint'
	...ocal/nvim-data/lazy/avante.nvim/ftplugin/AvanteInput.lua:62: in function <...ocal/nvim-data/lazy/avante.nvim/ftplugin/AvanteInput.lua:62>





Das ist einer der Punkte, bei denen Avante noch etwas eingeschränkt ist.

Es gibt grundsätzlich drei Möglichkeiten.

# Möglichkeit 1: Provider in der Konfiguration ändern

Die einfachste Variante ist:

```lua
provider = "claude"
```

ändern zu

```lua
provider = "ollama"
```

oder

```lua
provider = "gemini"
```

oder

```lua
provider = "openai"
```

und anschließend

```vim
:Lazy reload avante.nvim
```

oder Neovim neu starten.

Das ist die offizielle Vorgehensweise.

Nachteil:

* Neustart bzw. Reload notwendig.

---

# Möglichkeit 2: Provider zur Laufzeit umschalten

Da `provider` letztlich nur eine Lua-Variable ist, kann man sie auch zur Laufzeit ändern.

Beispielsweise:

```lua
require("avante.config").provider = "ollama"
```

oder

```lua
require("avante.config").provider = "claude"
```

Allerdings übernehmen derzeit nicht alle Komponenten diese Änderung zuverlässig, weshalb diese Methode je nach Avante-Version nicht vollständig funktioniert.

---

# Möglichkeit 3 (meine Empfehlung): Eigener User Command

Da ohnehin eine modulare AI-Infrastruktur entsteht, würde ich einen kleinen Wrapper schreiben.

Beispielsweise:

```vim
:AI Claude
:AI Ollama
:AI Gemini
:AI OpenAI
```

oder

```vim
:AISwitch
```

mit Picker.

Intern würde das lediglich

```lua
Config.provider = "claude"
```

setzen und ggf. benötigte Provider initialisieren.

---

# Noch besser: Modell ebenfalls umschalten

Nicht nur den Provider wechseln, sondern auch das Modell.

Beispielsweise:

```text
Claude
    Sonnet 4
    Opus 4

OpenAI
    GPT-5
    GPT-5 Mini

Gemini
    Gemini 2.5 Pro
    Gemini 2.5 Flash

Ollama
    qwen3-coder
    gemma3
    devstral
    deepseek
```

Dann genügt:

```vim
:AIModel
```

und es erscheint beispielsweise ein `mini.pick`- oder `snacks.nvim`-Picker.

```
Select model

> Claude Sonnet 4
  Claude Opus 4

  GPT-5
  GPT-5 Mini

  Gemini 2.5 Pro
  Gemini 2.5 Flash

  Ollama qwen3-coder
  Ollama Gemma 3
  Ollama Devstral
```

Nach der Auswahl würden intern etwa folgende Werte gesetzt:

```lua
provider = "ollama"

providers.ollama.model = "qwen3-coder:30b"
```

oder

```lua
provider = "claude"

providers.claude.model = "claude-sonnet-4"
```

---

# Was ich für Deine Konfiguration bauen würde

Da Du bereits eine eigene AI-Struktur anlegst, würde ich den Provider **nicht** direkt in `avante.lua` verwalten.

Stattdessen würde ich eine zentrale Konfiguration einführen, etwa:

```text
plugins/
    ai/
        general.lua
        providers.lua
        models.lua
        commands.lua
        picker.lua
        avante.lua
```

Dabei hätten die Module folgende Aufgaben:

| Modul           | Aufgabe                                                               |
| --------------- | --------------------------------------------------------------------- |
| `general.lua`   | Aktueller Provider, aktuelles Modell und globale AI-Einstellungen     |
| `providers.lua` | Definitionen für Claude, OpenAI, Gemini, Ollama usw.                  |
| `models.lua`    | Alle verfügbaren Modelle mit Metadaten (Name, Provider, Beschreibung) |
| `commands.lua`  | User Commands wie `:AIProvider`, `:AIModel`, `:AIReload`              |
| `picker.lua`    | `mini.pick`- oder `snacks.nvim`-Auswahlfenster                        |
| `avante.lua`    | Erzeugt die Avante-Konfiguration aus den obigen Modulen               |

Dann könnte der Workflow beispielsweise so aussehen:

```vim
:AIProvider
```

```
Claude
OpenAI
Gemini
Ollama
```

oder direkt:

```vim
:AIModel
```

```
Claude Sonnet 4
Claude Opus 4
GPT-5
GPT-5 Mini
Gemini 2.5 Pro
Gemini 2.5 Flash
Qwen3-Coder
Gemma 3
DeepSeek
Devstral
```

Die Auswahl würde den aktiven Provider und das Modell umschalten, die Änderung persistent speichern (z. B. in einer kleinen JSON- oder Lua-Datei) und Avante anschließend automatisch neu konfigurieren. So müsste beim täglichen Arbeiten nie wieder die Konfiguration von Hand angepasst werden. Für eine umfangreiche Neovim-Konfiguration ist das meiner Ansicht nach die komfortabelste und am besten wartbare Lösung.
