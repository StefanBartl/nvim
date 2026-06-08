Hier ist die Übersicht aller externen Tools, Bibliotheken und CLI-Programme, die du je nach gewünschtem Backend oder Renderer für das Modul `pdfport` auf deinem System installieren musst.

Multi-OS-Umfeld (Windows, WSL mit Ubuntu/Arch und nativen Ubuntu/Arch-Systemen), müssen wir die Installationen trennen

---

## Globale Installations-Tabelle nach Betriebssystem

| Kategorie / Komponente | Ubuntu (Nativ / WSL) | Arch Linux (Nativ / WSL) | Windows (Host) | Funktion im Modul `pdfport` |
| --- | --- | --- | --- | --- |
| **Basis-Backend** (`pdftotext`) | `sudo apt install poppler-utils` | `sudo pacman -S poppler` | *(Bereits in `C:\tools` hinterlegt)* | **Essentiell.** Schnelle Text-Extraktion. |
| **Python-Backends** (`pdfplumber`, `marker`, `docling`) | `pip install pdfplumber marker-pdf docling` | `pip install pdfplumber marker-pdf docling` | `pip install pdfplumber marker-pdf docling` | Extraktion von Tabellen, Markdown-Konvertierung und OCR. |
| **Lokales KI-Backend** (`ollama`) | `curl -fsSL https://ollama.com/install.sh | sh` | `sudo pacman -S ollama` | *(Läuft als Windows-Dienst)* | Nutzt lokale Vision-Modelle (z.B. `llava`) für gescannte PDFs. |
| **Cloud KI-Backend** (`claude`) | `sudo apt install curl` | `sudo pacman -S curl` | *(Standardmäßig aktiv)* | Schickt PDFs an Anthropic. Benötigt `curl` und `$ANTHROPIC_API_KEY`. |
| **Bild-Renderer** (`mode = "terminal"`) | `sudo apt install chafa` | `sudo pacman -S chafa` | `scoop install chafa` | **Beste Wahl.** Erzeugt PDF-Bildvorschauen als Terminal-Grafik. |
| **Echter Bild-Renderer** (Optional) | `sudo apt install ueberzugpp` | `yay -S ueberzugpp` | *Nicht unterstützt* | Erzeugt echte Bild-Overlays im Terminal. |

---

## Spezielle Optimierungen für dein Setup

### 1. Der WSL-Ollama-Brücken-Tipp

Wenn du in **WSL (Ubuntu oder Arch)** arbeitest, musst du dort *keinen* eigenen Ollama-Server starten, wenn dieser bereits auf deinem Windows-Host läuft. Du kannst OpenCode und `pdfport` in der `setup()`-Funktion von Neovim einfach auf die IP deines Windows-Hosts verweisen lassen:

```lua
ollama_host = "http://localhost:11434", -- WSL2 leitet localhost meist automatisch an Windows weiter

```

### 2. Arch Linux Python-Besonderheit (PEP 668)

Unter nativem Arch Linux (und manchmal neueren Ubuntu-Versionen) blockiert `pip install` globale Installationen außerhalb von virtuellen Umgebungen (`externally-managed-environment`). Nutze dort für die Python-Backends entweder ein `venv` für Neovim, oder installiere sie mit dem Flag `--break-system-packages`:

```bash
pip install pdfplumber marker-pdf docling --break-system-packages

```

*Alternativ auf Arch:* Viele Python-Pakete gibt es auch direkt im **AUR** (z. B. über `yay -S python-pdfplumber`).

### 3. Der ultimative Schnelltest

Egal auf welchem System du gerade Neovim startest, tippe nach der Installation einfach Folgendes ein, um zu sehen, was noch fehlt:

```vim
:checkhealth pdfport

```
