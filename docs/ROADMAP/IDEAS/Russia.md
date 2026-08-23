# ?

## Table of content

  - [intro](#intro)
  - [Rechtlicher Rahmen (kurz, aber wichtig)](#rechtlicher-rahmen-kurz-aber-wichtig)
  - [Warum „darf KI das meistens nicht"](#warum-darf-ki-das-meistens-nicht)
  - [Konzept-Überblick](#konzept-berblick)

---

## intro

Das ist ein völlig legitimes Vorhaben — solange du **ausschließlich gegen deine eigenen Geräte in einem isolierten Labornetz** testest. Genau dafür gibt es einen etablierten Bereich (autonome Red-Team-Agenten / AI-Pentesting). Ich arbeite dir gern ein Konzept aus. Kein fertiger Exploit-Code, aber die komplette Architektur mit bewährten Standard-Tools.

---

## Rechtlicher Rahmen (kurz, aber wichtig)

- **Nur eigene Geräte, physisch getrenntes/isoliertes Netz.** Sobald ein Paket dein Labor verlässt (Router, Nachbar-WLAN, Cloud), wird's schnell strafbar (§ 202a–c StGB in D / § 118a–c StGB in AT).
- Kein Zugriff aufs produktive Heimnetz. Eigenes VLAN oder eigener Switch.

---

## Warum „darf KI das meistens nicht"

Die großen Anbieter (auch ich) schreiben **keinen Malware- oder Exploit-Code**. Der Trick bei den funktionierenden Open-Source-Projekten ist: die KI **schreibt keine Exploits selbst**, sondern **orchestriert vorhandene, legale Pentest-Tools** (nmap, Metasploit, sqlmap …) und interpretiert deren Ausgaben. Das ist der gangbare Weg — und genau das machen die Projekte, die du mit „open claw" u. Ä. meinst.

---

## Konzept-Überblick

**1. Netz-Topologie**

```
[Attacker-Box: i5-12400F / RTX 5070]  ──┐
[Raspberry Pi 4B (Ziel)]              ──┤──  isolierter Switch/VLAN  (KEIN Uplink)
[Fujitsu Esprimo #1..n (Ziele)]       ──┘
```

Attacker-Maschine = dein starker PC (GPU für lokales LLM). Ziele = Pi + Esprimos, bewusst mit alten/verwundbaren Konfigurationen bespielt.

**2. AI-Orchestrierungs-Layer** — existierende Open-Source-Projekte, die genau dein Szenario abdecken:

- **HackingBuddyGPT** (akademisch, sehr sauber dokumentiert, LLM + Linux-Privesc/Netzwerk)
- **PentestGPT** (bekanntestes, geführtes Pentest-Reasoning)
- **Nebula** / **CAI (Cybersecurity AI framework)** — agentische Frameworks

Diese nehmen deinen Auftrag in natürlicher Sprache, planen Schritte, rufen Tools auf, lesen Ergebnisse, entscheiden weiter.

**3. Klassische Toolchain** (was die KI bedient): nmap, OpenVAS/Greenbone (Schwachstellen-Scan), Metasploit Framework, sqlmap, hydra, nuclei.

**4. LLM-Backend** — hier ist deine 12-GB-GPU relevant:

- Lokal (offline, keine Anbieter-Sperren): via **Ollama** z. B. Qwen 2.5 Coder 14B oder Llama 3.1 8B (quantisiert). Läuft auf 12 GB, aber Reasoning ist begrenzt.
- Für ernsthaftes agentisches Vorgehen sind Cloud-APIs deutlich stärker — die verweigern aber die Exploit-Ausführung. Kompromiss: **lokales Modell für die Angriffsschritte, starkes Modell nur für Planung/Report**.

**5. Agenten-Loop:** Auftrag → Recon (nmap) → Vuln-Scan (OpenVAS/nuclei) → Priorisierung → Exploit (Metasploit) → Post-Exploitation → Report.

**6. Guardrails:** Ziel-IP-Whitelist (Agent darf nur Lab-Range angreifen), kein Internet-Uplink, alles geloggt, „Kill-Switch".

---

