# `cascade.nvim`
`C-y` soll incrementedn^

1. `autolist` features?
2. keymaps

## Aut renumbering

`C-s` hat ein renumbering ausgelöst:

```markdown
1. Klicken Sie auf der Agenten-Maschine mit der rechten Maustaste auf die Datei **`ToscaDistributionAgent.exe`** und wählen Sie **Als Administrator ausführen** aus dem Kontextmenü.
*Standardmäßig befindet sich diese Datei im Verzeichnis `%TRICENTIS_DEX_AGENT_HOME%` (`C:\Program Files (x86)\TRICENTIS\Tosca Testsuite\DistributedExecution\`).*
1. Klicken Sie mit der rechten Maustaste auf das Agenten-Symbol in der Windows-Taskleiste und wählen Sie **Configure Agent** aus dem Kontextmenü.
*Dies öffnet das Fenster „ToscaDistributionAgent Configuration“.*
1. Klicken Sie im Konfigurationsfenster des Agenten auf den Reiter **Connect to server**.
2. Geben Sie im Reiter **Connect to server** die Adresse des DEX Servers ein:
`http://<Tosca Server Gateway IP-Adresse oder Hostname>:<Gateway-Port>`
*Wenn Sie eine IPv6-Adresse verwenden, muss die Serveradresse die IP-Adresse anstelle des Hostnamens enthalten.*
5. Wenn die Verbindung zum DEX Server erfolgreich ist, zeigt das Konfigurationsfenster des Agenten ein grünes Häkchen neben dem Eingabefeld für die Serveradresse an.
*Wenn das Fenster ein rotes X anzeigt, überprüfen Sie den Link, indem Sie ihn in einen Internetbrowser kopieren.*
6. Klicken Sie auf **Save**.
7. Wenn Sie den Tosca Server mit einer HTTPS-Bindung verwenden, authentifizieren Sie den Agenten. Gehen Sie dazu auf den Reiter **Connect to server**, wählen Sie **HTTPS** und füllen Sie die folgenden Einstellungen aus:
```

... das nicht passt.
Vorsvhlag: Könnte man es nicht it indenting heransziehen um abzurenzen?

```markdown
1. Klicken Sie auf der Agenten-Maschine mit der rechten Maustaste auf die Datei **`ToscaDistributionAgent.exe`** und wählen Sie **Als Administrator ausführen** aus dem Kontextmenü.
*Standardmäßig befindet sich diese Datei im Verzeichnis `%TRICENTIS_DEX_AGENT_HOME%` (`C:\Program Files (x86)\TRICENTIS\Tosca Testsuite\DistributedExecution\`).*
1. Klicken Sie mit der rechten Maustaste auf das Agenten-Symbol in der Windows-Taskleiste und wählen Sie **Configure Agent** aus dem Kontextmenü.
  *Dies öffnet das Fenster „ToscaDistributionAgent Configuration“.*
1. Klicken Sie im Konfigurationsfenster des Agenten auf den Reiter **Connect to server**.
2. Geben Sie im Reiter **Connect to server** die Adresse des DEX Servers ein:
`http://<Tosca Server Gateway IP-Adresse oder Hostname>:<Gateway-Port>`
  *Wenn Sie eine IPv6-Adresse verwenden, muss die Serveradresse die IP-Adresse anstelle des Hostnamens enthalten.*
5. Wenn die Verbindung zum DEX Server erfolgreich ist, zeigt das Konfigurationsfenster des Agenten ein grünes Häkchen neben dem Eingabefeld für die Serveradresse an.
  *Wenn das Fenster ein rotes X anzeigt, überprüfen Sie den Link, indem Sie ihn in einen Internetbrowser kopieren.*
6. Klicken Sie auf **Save**.
7. Wenn Sie den Tosca Server mit einer HTTPS-Bindung verwenden, authentifizieren Sie den Agenten. Gehen Sie dazu auf den Reiter **Connect to server**, wählen Sie **HTTPS** und füllen Sie die folgenden Einstellungen aus:
```

hir sind zeilen unter nden punkten indentet und daher sagen wir: diese zeile bricht nicht die numemrierung und löst eine neue aus, sondern sie geört einfach zum punkt oberhalb, aoso:

```markdown
1. Klicken Sie auf der Agenten-Maschine mit der rechten Maustaste auf die Datei **`ToscaDistributionAgent.exe`** und wählen Sie **Als Administrator ausführen** aus dem Kontextmenü.
  *Standardmäßig befindet sich diese Datei im Verzeichnis `%TRICENTIS_DEX_AGENT_HOME%` (`C:\Program Files (x86)\TRICENTIS\Tosca Testsuite\DistributedExecution\`).*
2. Klicken Sie mit der rechten Maustaste auf das Agenten-Symbol in der Windows-Taskleiste und wählen Sie **Configure Agent** aus dem Kontextmenü.
  *Dies öffnet das Fenster „ToscaDistributionAgent Configuration“.*
3. Klicken Sie im Konfigurationsfenster des Agenten auf den Reiter **Connect to server**.
4. Geben Sie im Reiter **Connect to server** die Adresse des DEX Servers ein:
  `http://<Tosca Server Gateway IP-Adresse oder Hostname>:<Gateway-Port>`
  *Wenn Sie eine IPv6-Adresse verwenden, muss die Serveradresse die IP-Adresse anstelle des Hostnamens enthalten.*
5. Wenn die Verbindung zum DEX Server erfolgreich ist, zeigt das Konfigurationsfenster des Agenten ein grünes Häkchen neben dem Eingabefeld für die Serveradresse an.
  *Wenn das Fenster ein rotes X anzeigt, überprüfen Sie den Link, indem Sie ihn in einen Internetbrowser kopieren.*
6. Klicken Sie auf **Save**.
7. Wenn Sie den Tosca Server mit einer HTTPS-Bindung verwenden, authentifizieren Sie den Agenten. Gehen Sie dazu auf den Reiter **Connect to server**, wählen Sie **HTTPS** und füllen Sie die folgenden Einstellungen aus:
```

Was ist aber mit leerzeilen? wie gehen wir damit um ? 1 Leerzeile ok, ab 2 leerzeilen neues renumbering? oder so oau die art?

---

