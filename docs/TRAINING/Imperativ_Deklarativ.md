# Die Eselsbrücke (Aufwand vs. Ergebnis)

* **IMPERATIV** = **IMPERIUM** / **IMPERATOR**
  * **Was macht der Imperator?** Er gibt Schritt für Schritt Befehle: *"Geh dahin, mache das, ändere diese Variable!"*
  * **Fokus:** **WIE** etwas gemacht wird.
  * **C++ Typisch:** Manuelle For-Schleifen, Zeiger-Arithmetik, Zustand Schritt für Schritt verändern.


* **DEKLARATIV** = **DEKLARATION** / **DEKLARIEREN**
  * **Was ist eine Deklaration?** Eine Aussage oder eine Bestellung am Restaurant-Tisch: *"Ich möchte ein Steak mit Pommes."* (Du sagst dem Koch nicht, wie er die Pfanne heizen soll).
  * **Fokus:** **WAS** das Ergebnis sein soll.
  * **Rust Typisch:** `.filter()`, `.map()`, `.collect()`, Pattern Matching.

---

## Dein 5-Minuten-Trainingsplan (Für 4–5 Tage)

Nimm dir jeden Tag 5 Minuten Zeit und geh diese **drei Schritte** durch:

### 1. Der 30-Sekunden-Self-Check (Jeden Tag zuerst)

Sag diesen Satz laut auf:

> *"Imperativ = Der Imperator befehlt das **WIE**. Deklarativ = Die Bestellung deklariert das **WAS**."*

### 2. Code-Übersetzung (Tag 1–3)

Schau dir dieses Standard-Problem an: **"Filtere alle geraden Zahlen aus einer Liste und verdopple sie."**

* **Imperativ (Das WIE schrittweise vorgeben):**
```cpp
// C++ Style:
std::vector<int> result;
for (int i = 0; i < numbers.size(); i++) {
    if (numbers[i] % 2 == 0) {
        result.push_back(numbers[i] * 2);
    }
}

```


*Warum imperativ?* Du erstellst Speicher, baust einen Schleifenzähler `i`, prüfst per `if` und fügst Werte manuell an.
* **Deklarativ (Das WAS als Kette beschreiben):**
```rust
// Rust Style:
let result: Vec<i32> = numbers.into_iter()
    .filter(|n| n % 2 == 0)
    .map(|n| n * 2)
    .collect();

```


*Warum deklarativ?* Du sagst nur: *Filtern nach X, Transformation mit Y, Einsammeln.* Keine Index-Variable, kein manueller Zustand.

### 3. Trockenübung (Tag 4–5)

Decke den Begriff ab und ordne diese Alltags-Analogien zu:

| Alltagssituation | Paradigma | Grund |
| --- | --- | --- |
| Ein Kochrezept mit 12 Einzelschritten | **Imperativ** | Beschreibt das schrittweise **WIE**. |
| Eine Navigations-App mit dem Befehl *"Schnellste Route nach Berlin"* | **Deklarativ** | Beschreibt das gewünschte Ziel (**WAS**). |
| Wegbeschreibung: *"Fahr 100m, bieg rechts ab, schalte in den 3. Gang"* | **Imperativ** | Manuelle Befehlskette. |
| SQL-Abfrage: `SELECT * FROM users WHERE age > 18` | **Deklarativ** | Du fragst nach Daten, sagst der DB aber nicht, wie sie suchen soll. |

---
