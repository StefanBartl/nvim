# Diagnostics -- Erledigt

Aus `docs/ROADMAP/personal/All/Diagnostics.md` herausgenommene Punkte, sobald
sie abgeschlossen sind. Neueste zuerst. Der Report dort bleibt die Quelle fuer
alles, was noch offen ist.

**Der Abschnitt direkt unten -- „Wiederkehrende Muster“ -- ist die
Zusammenfassung ueber alle Durchgaenge hinweg:** was sich wiederholt hat, an
welcher Signatur man es erkennt, und welcher Griff sich bewaehrt hat. Er ist
als Checkliste fuer den naechsten Durchgang gedacht und als Vorlage fuer die
RULES-Dateien; die Einzelheiten stehen jeweils beim Repo darunter.

---

## Table of content

  - [Wiederkehrende Muster -- die Ableitung fuer RULES](#wiederkehrende-muster-die-ableitung-fuer-rules)
    - [A. Echte Fehler, die der Pruefer gefunden hat](#a-echte-fehler-die-der-pruefer-gefunden-hat)
    - [B. Die Messgrundlage -- bevor irgendetwas gezaehlt wird](#b-die-messgrundlage-bevor-irgendetwas-gezaehlt-wird)
    - [C. Annotationsformen, die etwas verschlucken](#c-annotationsformen-die-etwas-verschlucken)
    - [D. Griffe, die nichts loesen](#d-griffe-die-nichts-loesen)
    - [E. Wann Unterdruecken richtig ist](#e-wann-unterdruecken-richtig-ist)
    - [F. Was Neovim schon fuehrt](#f-was-neovim-schon-fuehrt)
    - [G. Der Test-Runner](#g-der-test-runner)
    - [H. Arbeitsreihenfolge, die sich bewaehrt hat](#h-arbeitsreihenfolge-die-sich-bewaehrt-hat)

  - [2026-09-02](#2026-09-02)
    - [Die Achter-Runde -- die letzten acht Plugins, 50 auf 0](#die-achter-runde-die-letzten-acht-plugins-50-auf-0)
      - [Ein Alias auf eine `vim.*`-Funktion kann nil-behaftet zurueckkommen](#ein-alias-auf-eine-vim-funktion-kann-nil-behaftet-zurueckkommen)
      - [migrate.nvim: Cluster L zum achten Mal -- und diesmal faellt die Zahl](#migratenvim-cluster-l-zum-achten-mal-und-diesmal-faellt-die-zahl)
      - [dap.nvim: der Test-Runner, vierter Fall -- und eine zweite Fehlerart](#dapnvim-der-test-runner-vierter-fall-und-eine-zweite-fehlerart)
      - [color_my_ascii.nvim: ein Argument, das still verfiel -- und ein Fix, der den Befund verschob](#color_my_asciinvim-ein-argument-das-still-verfiel-und-ein-fix-der-den-befund-verschob)
      - [Der Rest, nach Familien](#der-rest-nach-familien-1)
      - [Cluster E ist damit leer -- bis auf die Config](#cluster-e-ist-damit-leer-bis-auf-die-config)
    - [Die Dreier-Runde -- pickers, insights und recommender, 73 auf 0](#die-dreier-runde-pickers-insights-und-recommender-73-auf-0)
      - [Vorab: die zwei billigen Pruefungen, dreimal umsonst](#vorab-die-zwei-billigen-pruefungen-dreimal-umsonst)
      - [pickers: `fun(T)` ist keine Signatur -- elf Befunde aus drei Zeilen](#pickers-funt-ist-keine-signatur-elf-befunde-aus-drei-zeilen)
      - [insights: dieselbe Familie, Form B -- und drei Namen fuer eine Gestalt](#insights-dieselbe-familie-form-b-und-drei-namen-fuer-eine-gestalt)
      - [recommender: ein Testfall, der nie gelaufen ist](#recommender-ein-testfall-der-nie-gelaufen-ist)
      - [Was der Nachher-Lauf noch gezeigt hat: ein Cast endet an der naechsten Zuweisung](#was-der-nachher-lauf-noch-gezeigt-hat-ein-cast-endet-an-der-naechsten-zuweisung)
    - [markdown.nvim -- 30 auf 0, ein Timer ohne Antwort und ein Cast, der selbst gemeldet wird](#markdownnvim-30-auf-0-ein-timer-ohne-antwort-und-ein-cast-der-selbst-gemeldet-wird)
      - [`.luarc.json` und `health.lua`: diesmal beide sauber](#luarcjson-und-healthlua-diesmal-beide-sauber)
      - [A1 zum vierten Mal: der Debounce-Timer der Live-Referenzen](#a1-zum-vierten-mal-der-debounce-timer-der-live-referenzen)
      - [Die Nutzlast dieses Plugins auf dem Typ eines fremden](#die-nutzlast-dieses-plugins-auf-dem-typ-eines-fremden)
      - [Ein `---@cast` zwischen zwei Klassen wird selbst gemeldet](#ein-cast-zwischen-zwei-klassen-wird-selbst-gemeldet)
      - [Der Rest, nach Familien](#der-rest-nach-familien)
    - [diff.nvim -- 31 auf 0, ein Typname, den es nicht gibt, und `vim.diff`](#diffnvim-31-auf-0-ein-typname-den-es-nicht-gibt-und-vimdiff)
      - [Sieben Befunde an einem Namen](#sieben-befunde-an-einem-namen)
      - [`vim.diff` ist deprecated, und `:checkhealth` log darueber](#vimdiff-ist-deprecated-und-checkhealth-log-darueber)
      - [Eine Gestalt, zweimal ausgeschrieben, in einem Feld verschieden](#eine-gestalt-zweimal-ausgeschrieben-in-einem-feld-verschieden)
    - [cascade.nvim -- 32 auf 0, ein abgeschnittener Doc-Block und fuenf vergessene Werte](#cascadenvim-32-auf-0-ein-abgeschnittener-doc-block-und-fuenf-vergessene-werte)
      - [Ein Doc-Block, den eine neue Variable abgeschnitten hat](#ein-doc-block-den-eine-neue-variable-abgeschnitten-hat)
      - [Fuenfmal: N Rueckgabewerte, ein Guard, eine Cast-Liste](#fuenfmal-n-rueckgabewerte-ein-guard-eine-cast-liste)
      - [Und ein Fehler in der Messung, der hierher gehoert](#und-ein-fehler-in-der-messung-der-hierher-gehoert)
    - [replacer.nvim -- 32 auf 0, ein toter Typ, eine tote API und ein Aufruf, der seit 0.11 wirft](#replacernvim-32-auf-0-ein-toter-typ-eine-tote-api-und-ein-aufruf-der-seit-011-wirft)
      - [Zwoelf Befunde aus einem Typ, den es nicht gibt](#zwoelf-befunde-aus-einem-typ-den-es-nicht-gibt)
      - [Und die beiden Funktionen ruft niemand](#und-die-beiden-funktionen-ruft-niemand)
      - [`vim.str_utfindex` hat in 0.11 die Signatur getauscht, und `:ReplaceDebug` merkt es](#vimstr_utfindex-hat-in-011-die-signatur-getauscht-und-replacedebug-merkt-es)
      - [Ein Feld, das drei Geschwister hat und selbst fehlte](#ein-feld-das-drei-geschwister-hat-und-selbst-fehlte)
      - [Der Rest -- sieben kleine Ursachen](#der-rest-sieben-kleine-ursachen)
    - [github_stats.nvim -- 31 auf 0, und ein Test-Runner, den die anderen kopieren sollten](#github_statsnvim-31-auf-0-und-ein-test-runner-den-die-anderen-kopieren-sollten)
      - [Zwei Boolean-Helfer, die keine Type-Guards sind](#zwei-boolean-helfer-die-keine-type-guards-sind)
      - [`vim.uv.new_timer()` -- das dritte Repo in Folge](#vimuvnew_timer-das-dritte-repo-in-folge)
      - [Eine Option, die es gibt, aber in keinem Typ steht](#eine-option-die-es-gibt-aber-in-keinem-typ-steht)
      - [Eine Klasse, die genau dafuer da war und zurueckgefallen ist](#eine-klasse-die-genau-dafuer-da-war-und-zurueckgefallen-ist)
      - [Der Rest](#der-rest)
      - [Der Test-Runner: der erste, der es richtig macht](#der-test-runner-der-erste-der-es-richtig-macht)
    - [lsp.nvim -- 35 auf 0, und drei Waechter, die nie etwas ausgeschlossen haben](#lspnvim-35-auf-0-und-drei-waechter-die-nie-etwas-ausgeschlossen-haben)
      - [`supports_method("textDocumentSync/openClose")` -- die Wache, die immer Ja sagt](#supports_methodtextdocumentsyncopenclose-die-wache-die-immer-ja-sagt)
      - [`win_id`, wo Neovim `winnr` liest](#win_id-wo-neovim-winnr-liest)
      - [`publishDiagnosticsProvider` -- eine Capability, die es nicht gibt](#publishdiagnosticsprovider-eine-capability-die-es-nicht-gibt)
      - [Offen-Punkt 6, beantwortet: `LspMod.*` beschreibt nichts, was Neovim nicht fuehrt](#offen-punkt-6-beantwortet-lspmod-beschreibt-nichts-was-neovim-nicht-fuehrt)
      - [Offen-Punkt 5, nachgemessen: der Zustand existiert nicht mehr](#offen-punkt-5-nachgemessen-der-zustand-existiert-nicht-mehr)
      - [`vim.health.info` -- das sechste Repo in Folge](#vimhealthinfo-das-sechste-repo-in-folge)
      - [Der Rest -- neun kleine Ursachen](#der-rest-neun-kleine-ursachen)
      - [Nachtrag: der Runner haengt nicht „unter Windows“, er haengt ohne zwei Env-Variablen](#nachtrag-der-runner-haengt-nicht-unter-windows-er-haengt-ohne-zwei-env-variablen)
    - [language.nvim -- 34 auf 0, und die siebte `.luarc.json`, die ihre Library wegwarf](#languagenvim-34-auf-0-und-die-siebte-luarcjson-die-ihre-library-wegwarf)
      - [Sechs waren gar keine Befunde, sondern die Messung](#sechs-waren-gar-keine-befunde-sondern-die-messung)
      - [Cluster E, vier Stellen, und warum `vim.cmd` kein `function` ist](#cluster-e-vier-stellen-und-warum-vimcmd-kein-function-ist)
      - [Acht ungeprueft benutzte Timer -- derselbe Fund wie in mdview](#acht-ungeprueft-benutzte-timer-derselbe-fund-wie-in-mdview)
      - [`region_bounds`: alles oder nichts, in vier Optionals geschrieben](#region_bounds-alles-oder-nichts-in-vier-optionals-geschrieben)
      - [Form A, das dritte Mal -- und ein Parameter, der dabei auffiel](#form-a-das-dritte-mal-und-ein-parameter-der-dabei-auffiel)
      - [Der Rest -- fuenf kleine Ursachen](#der-rest-fuenf-kleine-ursachen)
      - [Drei `deprecated`, die keine Schuld sind](#drei-deprecated-die-keine-schuld-sind)
      - [Ein Nebenbefund, der eine Entscheidung braucht](#ein-nebenbefund-der-eine-entscheidung-braucht)
  - [2026-09-01](#2026-09-01)
    - [images.nvim -- 37 auf 0, und ein `compare`, das ohne ImageMagick geworfen haette](#imagesnvim-37-auf-0-und-ein-compare-das-ohne-imagemagick-geworfen-haette)
      - [Zwei Zahlen, die nie verglichen werden konnten](#zwei-zahlen-die-nie-verglichen-werden-konnten)
      - [`Dims` und `MaybeDims` -- ein Unterschied, den der Code schon machte](#dims-und-maybedims-ein-unterschied-den-der-code-schon-machte)
      - [Drei Advice-Zeilen, die kein `:checkhealth` je gezeigt hat](#drei-advice-zeilen-die-kein-checkhealth-je-gezeigt-hat)
      - [Drei Doc-Bloecke, verdoppelt beim Nachruesten eines Parameters](#drei-doc-bloecke-verdoppelt-beim-nachruesten-eines-parameters)
      - [Ein `@return` mit einem Komma](#ein-return-mit-einem-komma)
      - [Der Rest -- vier kleine Ursachen](#der-rest-vier-kleine-ursachen)
      - [Die Tests: neun Doubles unterdrueckt, sieben `assert` gesetzt](#die-tests-neun-doubles-unterdrueckt-sieben-assert-gesetzt)
    - [sandbox.nvim -- 39 auf 0, und Ports, die ihre eigenen Parameter nicht fanden](#sandboxnvim-39-auf-0-und-ports-die-ihre-eigenen-parameter-nicht-fanden)
      - [Ein `runtime.path`, der auf ein Verzeichnis zeigt, das es nicht gibt](#ein-runtimepath-der-auf-ein-verzeichnis-zeigt-das-es-nicht-gibt)
      - [Fuenf Ports, die ihre eigenen Parameter nicht fanden](#fuenf-ports-die-ihre-eigenen-parameter-nicht-fanden)
      - [Fuenf verirrte Doc-Bloecke -- das fuenfte Repo](#fuenf-verirrte-doc-bloecke-das-fuenfte-repo)
      - [Eine Klasse, die halb so viel deklariert, wie der Port kann](#eine-klasse-die-halb-so-viel-deklariert-wie-der-port-kann)
      - [Die Completion-Quellen reichten `nil` weiter](#die-completion-quellen-reichten-nil-weiter)
      - [Ein Bug, den die Typen gefunden haben](#ein-bug-den-die-typen-gefunden-haben)
      - [Nachtrag: neun rote Tests, und ein Runner, der es nicht merkt](#nachtrag-neun-rote-tests-und-ein-runner-der-es-nicht-merkt)
    - [mdview.nvim -- 44 auf 0, und ein `assert`, das seinen Wert verschluckt hat](#mdviewnvim-44-auf-0-und-ein-assert-das-seinen-wert-verschluckt-hat)
      - [Der Prozess-Zustand war dreimal beschrieben, zweimal falsch](#der-prozess-zustand-war-dreimal-beschrieben-zweimal-falsch)
      - [Alle zehn `need-check-nil` waren zwei ungeprüfte libuv-Aufrufe](#alle-zehn-need-check-nil-waren-zwei-ungeprfte-libuv-aufrufe)
      - [Wieder zwei verirrte Doc-Bloecke](#wieder-zwei-verirrte-doc-bloecke)
      - [Drei Signaturen, die ihre eigene Funktion falsch beschrieben](#drei-signaturen-die-ihre-eigene-funktion-falsch-beschrieben)
      - [Der Fund, der nicht in der Zaehlung steht](#der-fund-der-nicht-in-der-zaehlung-steht)
      - [Der Rest](#der-rest)
    - [Der Gesamtlauf auf der korrigierten Messgrundlage -- 1254 auf 570](#der-gesamtlauf-auf-der-korrigierten-messgrundlage-1254-auf-570)
      - [sandbox.nvim: 40 -> 64 -> 39, und ein Stub, der ein Repo lahmlegte](#sandboxnvim-40-64-39-und-ein-stub-der-ein-repo-lahmlegte)
    - [spotlight.nvim -- 37 auf 0, nachdem die Messung erst einmal stimmte](#spotlightnvim-37-auf-0-nachdem-die-messung-erst-einmal-stimmte)
      - [Dreizehn Befunde waren eine Zeile in der `.luarc.json`](#dreizehn-befunde-waren-eine-zeile-in-der-luarcjson)
      - [Und 346 waren die Messung selbst](#und-346-waren-die-messung-selbst)
      - [Die Ursache im Werkzeug, und was sie nicht war](#die-ursache-im-werkzeug-und-was-sie-nicht-war)
      - [Was danach an echtem Code uebrig war](#was-danach-an-echtem-code-uebrig-war)
      - [Die Tests: acht Invarianten benannt, zehn Absichten unterdrueckt](#die-tests-acht-invarianten-benannt-zehn-absichten-unterdrueckt)
      - [Nachtrag: filetree.nvim steht nicht mehr auf Null](#nachtrag-filetreenvim-steht-nicht-mehr-auf-null)
    - [open.nvim -- 48 auf 0, und ein Spec, das unbrauchbar haette scheitern koennen](#opennvim-48-auf-0-und-ein-spec-das-unbrauchbar-haette-scheitern-koennen)
      - [Ein `table`, das zwoelf Schluessel verschwieg](#ein-table-das-zwoelf-schluessel-verschwieg)
      - [Zwei Felder gerettet, siebenundzwanzig nicht](#zwei-felder-gerettet-siebenundzwanzig-nicht-und-das-war-die-interessante-haelfte)
      - [Die sechs in `lua/`](#die-sechs-in-lua)
      - [Nebenher: der Querschnittsposten ist vermessen](#nebenher-der-querschnittsposten-ist-vermessen)
    - [pdfport.nvim -- 61 auf 0, und der Notifier, den niemand sehen konnte](#pdfportnvim-61-auf-0-und-der-notifier-den-niemand-sehen-konnte)
      - [Achtundzwanzig Befunde waren eine Zeile](#achtundzwanzig-befunde-waren-eine-zeile)
      - [Acht weitere: dasselbe, andersherum](#acht-weitere-dasselbe-andersherum)
      - [Und acht: zwei Doc-Bloecke uebereinander](#und-acht-zwei-doc-bloecke-uebereinander)
      - [Der Rest -- fuenf kleine Ursachen](#der-rest-fuenf-kleine-ursachen)
      - [Der Befund, der erst beim dritten Lauf kam](#der-befund-der-erst-beim-dritten-lauf-kam)
    - [neotree-fs-refactor.nvim -- ausserhalb des Umfangs, versehentlich bearbeitet](#neotree-fs-refactornvim-ausserhalb-des-umfangs-versehentlich-bearbeitet)
    - [Die Sechser-Runde -- fuenf Repos, 126 auf 0](#die-sechser-runde-fuenf-repos-126-auf-0)
      - [fileops: zwei Tastenkuerzel, die nichts gesagt haben](#fileops-zwei-tastenkuerzel-die-nichts-gesagt-haben)
      - [gopath: ein Ergebnis, das gelogen hat](#gopath-ein-ergebnis-das-gelogen-hat)
      - [buffer-ctx: eine API, die seit 0.11 anders heisst](#buffer-ctx-eine-api-die-seit-011-anders-heisst)
      - [Der Rest, und was sich wiederholt](#der-rest-und-was-sich-wiederholt)
    - [runtime-analysis.nvim -- 109 auf 0, und die Hinweise, die niemand sah](#runtime-analysisnvim-109-auf-0-und-die-hinweise-die-niemand-sah)
      - [Derselbe Fehler wie in documentation.nvim](#derselbe-fehler-wie-in-documentationnvim)
      - [`uv_tcp_t` ist kein Typ](#uv_tcp_t-ist-kein-typ)
      - [Zwei Zeilen, die nie geschrieben wurden](#zwei-zeilen-die-nie-geschrieben-wurden)
      - [Der Rest -- zehn kleine Ursachen](#der-rest-zehn-kleine-ursachen)
    - [filetree.nvim -- 80 auf 0, und vier Dinge, die nie liefen](#filetreenvim-80-auf-0-und-vier-dinge-die-nie-liefen)
      - [Der Einstieg war der vorgeschlagene, und er trug 24](#der-einstieg-war-der-vorgeschlagene-und-er-trug-24)
      - [Vier Stellen, die nie gelaufen sein koennen](#vier-stellen-die-nie-gelaufen-sein-koennen)
      - [Cluster E, filetree.nvims ganzer Anteil](#cluster-e-filetreenvims-ganzer-anteil)
      - [Der Rest -- neun kleine Ursachen](#der-rest-neun-kleine-ursachen)
      - [Zweimal die Regel angewandt, die es dafuer gibt](#zweimal-die-regel-angewandt-die-es-dafuer-gibt)
      - [Unterdrueckt, mit Begruendung](#unterdrueckt-mit-begruendung)
      - [Was uebrig ist](#was-uebrig-ist)
    - [filetree.nvim -- 161 auf 80, und fuenf Features, die nie rendern](#filetreenvim-161-auf-80-und-fuenf-features-die-nie-rendern)
      - [`get_node_at_line` ruft niemand auf, weil es niemand hat](#get_node_at_line-ruft-niemand-auf-weil-es-niemand-hat)
      - [Ein Wort: `get_root` gegen `get_root_path`](#ein-wort-get_root-gegen-get_root_path)
      - [Deklariert, nicht implementiert -- und das steht jetzt da](#deklariert-nicht-implementiert-und-das-steht-jetzt-da)
      - [Der Rest](#der-rest)
      - [Was uebrig ist: dieselbe Form wie in lsp.nvim](#was-uebrig-ist-dieselbe-form-wie-in-lspnvim)
    - [lsp.nvim -- 172 auf 35, und die Typen, die es hier nie gab](#lspnvim-172-auf-35-und-die-typen-die-es-hier-nie-gab)
      - [Ein echter Fehler: `:LspLuaLsReload` hat den Server nie benachrichtigt](#ein-echter-fehler-lsplualsreload-hat-den-server-nie-benachrichtigt)
      - [Die drei Typdateien](#die-drei-typdateien)
      - [`LspNvim.Config` sagte das eine und deklarierte das andere](#lspnvimconfig-sagte-das-eine-und-deklarierte-das-andere)
      - [Eine Vermutung, die beim Hinsehen gefallen ist](#eine-vermutung-die-beim-hinsehen-gefallen-ist)
      - [Der Rest](#der-rest-1)
      - [Was uebrig ist: 35, und sie sind einzeln](#was-uebrig-ist-35-und-sie-sind-einzeln)
    - [Die Messgrundlage, zweiter Teil -- luassert, und 180 Befunde, die keinem Repo gehoerten](#die-messgrundlage-zweiter-teil-luassert-und-180-befunde-die-keinem-repo-gehoerten)
      - [Die Hypothese, die die Messung widerlegt hat](#die-hypothese-die-die-messung-widerlegt-hat)
      - [Was es wirklich war: `relatedInformation` fragen statt raten](#was-es-wirklich-war-relatedinformation-fragen-statt-raten)
      - [Der Schluessel war da, er kam nur nirgends an](#der-schluessel-war-da-er-kam-nur-nirgends-an)
      - [Gemessen](#gemessen)
      - [Die +36 sind der eigentliche Ertrag](#die-36-sind-der-eigentliche-ertrag)
      - [Was daraus offen bleibt](#was-daraus-offen-bleibt)
  - [2026-08-31](#2026-08-31)
    - [lib.nvim fertig -- der zweite vertikale Durchgang](#libnvim-fertig-der-zweite-vertikale-durchgang)
      - [Zwei echte Fehler](#zwei-echte-fehler)
      - [Zwei Annotationen, die etwas anderes beschrieben als der Code tut](#zwei-annotationen-die-etwas-anderes-beschrieben-als-der-code-tut)
      - [Das Muster, das ein Drittel erklaert: der Guard sitzt auf dem Feld](#das-muster-das-ein-drittel-erklaert-der-guard-sitzt-auf-dem-feld)
      - [Rueckgaben, die es ganz oder gar nicht gibt](#rueckgaben-die-es-ganz-oder-gar-nicht-gibt)
      - [libuv antwortet mit nil, statt zu werfen](#libuv-antwortet-mit-nil-statt-zu-werfen)
      - [Cluster E, lib.nvims Anteil](#cluster-e-libnvims-anteil)
      - [Typen, die etwas anderes beschrieben haben](#typen-die-etwas-anderes-beschrieben-haben)
      - [Zwei Namen, die der nvim-Config gehoeren](#zwei-namen-die-der-nvim-config-gehoeren)
      - [Die Klammer, die eine Signatur rettet](#die-klammer-die-eine-signatur-rettet)
      - [Unterdrueckt, mit der Begruendung daneben](#unterdrueckt-mit-der-begruendung-daneben)
      - [Was offen bleibt: eine Zeile, und sie gehoert nach lsp.nvim](#was-offen-bleibt-eine-zeile-und-sie-gehoert-nach-lspnvim)
      - [Gemessen](#gemessen-1)
    - [Sechs Repos pruefen wieder gegen Neovims Typen](#sechs-repos-pruefen-wieder-gegen-neovims-typen)
      - [Die Zahl steigt, und das ist der Zweck](#die-zahl-steigt-und-das-ist-der-zweck)
      - [Eine Hypothese, die die Messung widerlegt hat](#eine-hypothese-die-die-messung-widerlegt-hat)
      - [Nebenbefund: das Werkzeug dumpt die falsche Funktion](#nebenbefund-das-werkzeug-dumpt-die-falsche-funktion)
    - [Cluster F: `inject-field` in lib.nvim -- und die `missing-fields`-Reste daneben](#cluster-f-inject-field-in-libnvim-und-die-missing-fields-reste-daneben)
      - [Die Zombie-Klassen, und was sie verdeckt haben](#die-zombie-klassen-und-was-sie-verdeckt-haben)
      - [Die Annotation stand nur auf der falschen Zeile](#die-annotation-stand-nur-auf-der-falschen-zeile)
      - [Ein Typ, der nicht bloss zu frueh, sondern falsch war](#ein-typ-der-nicht-bloss-zu-frueh-sondern-falsch-war)
      - [Neun Schluessel, die es nur unter einer Strategie gibt](#neun-schluessel-die-es-nur-unter-einer-strategie-gibt)
      - [Der Alias, der eine echte Luecke zugedeckt hat](#der-alias-der-eine-echte-luecke-zugedeckt-hat)
      - [Gemessen](#gemessen-2)
    - [documentation.nvim: die restlichen 155 -- der erste vertikale Durchgang](#documentationnvim-die-restlichen-155-der-erste-vertikale-durchgang)
      - [Das Muster, das die Haelfte erklaert: der Guard sitzt auf einem Feld](#das-muster-das-die-haelfte-erklaert-der-guard-sitzt-auf-einem-feld)
      - [Die Kinder eines Treesitter-Knotens](#die-kinder-eines-treesitter-knotens)
      - [Ein echter Fehler: zwoelf Advice-Listen, die nie jemand gesehen hat](#ein-echter-fehler-zwoelf-advice-listen-die-nie-jemand-gesehen-hat)
      - [Zwei verwaiste Doc-Bloecke](#zwei-verwaiste-doc-bloecke)
      - [Annotationen, die schlicht falsch waren](#annotationen-die-schlicht-falsch-waren)
      - [Der Overload, der die Zahl verschlechtert hat](#der-overload-der-die-zahl-verschlechtert-hat)
      - [Unterdrueckt, mit der Begruendung daneben](#unterdrueckt-mit-der-begruendung-daneben-1)
      - [Gemessen](#gemessen-3)
    - [Cluster D: `userdata` statt `TSNode` -- documentation.nvim](#cluster-d-userdata-statt-tsnode-documentationnvim)
      - [Warum `userdata` der teuerste Annotationsfehler ist](#warum-userdata-der-teuerste-annotationsfehler-ist)
      - [Was gemacht wurde -- 154 Annotationen in 18 Dateien](#was-gemacht-wurde-154-annotationen-in-18-dateien)
      - [Zwei Nachbarn derselben Klasse](#zwei-nachbarn-derselben-klasse)
      - [Ergebnis: 383 -> 155](#ergebnis-383-155)
      - [Was von den `undefined-field` uebrig ist](#was-von-den-undefined-field-uebrig-ist)
    - [Cluster B: `need-check-nil` in Tests -- unterdrueckt, nicht auszementiert](#cluster-b-need-check-nil-in-tests-unterdrueckt-nicht-auszementiert)
      - [Der Befund, der die Umsetzung geaendert hat](#der-befund-der-die-umsetzung-geaendert-hat)
      - [Was gemacht wurde -- 19 Repos, 93 Dateien](#was-gemacht-wurde-19-repos-93-dateien)
      - [Ergebnis: 3204 -> 2289](#ergebnis-3204-2289)
      - [Gegenprobe mit dem festen Harness](#gegenprobe-mit-dem-festen-harness)
      - [Zwei Sachen, die beim Messen aufgefallen sind](#zwei-sachen-die-beim-messen-aufgefallen-sind)
      - [Die Messumgebung liegt jetzt fest im Repo](#die-messumgebung-liegt-jetzt-fest-im-repo)
    - [Cluster A: der `assert`-Typ -- und warum der erste Anlauf ins Leere lief](#cluster-a-der-assert-typ-und-warum-der-erste-anlauf-ins-leere-lief)
      - [Die Ursache, jetzt gemessen statt vermutet](#die-ursache-jetzt-gemessen-statt-vermutet)
      - [Die zweite Ursache: der Workspace als seine eigene Library](#die-zweite-ursache-der-workspace-als-seine-eigene-library)
      - [Was gemacht wurde](#was-gemacht-wurde)
      - [Ergebnis: 6344 -> 3204](#ergebnis-6344-3204)
      - [Was absichtlich unangetastet blieb](#was-absichtlich-unangetastet-blieb)
      - [Wie gemessen wurde](#wie-gemessen-wurde)
  - [2026-08-29](#2026-08-29)
    - [Cluster C: `missing-fields` -- 518 auf 21, ueber alle 31 Plugins plus Config](#cluster-c-missing-fields-518-auf-21-ueber-alle-31-plugins-plus-config)
      - [Der Fix war nicht ueberall derselbe -- und das liess sich nur messen](#der-fix-war-nicht-ueberall-derselbe-und-das-liess-sich-nur-messen)
      - [Was dabei an echten Fehlern herausfiel](#was-dabei-an-echten-fehlern-herausfiel)
      - [Was Pflicht blieb, und warum](#was-pflicht-blieb-und-warum)
      - [Unterdrueckt, mit Begruendung im Code](#unterdrueckt-mit-begruendung-im-code)
      - [Werkzeug](#werkzeug)
    - [`lib.nvim.ui.list` -- eine Listen-Senke statt vierzehn](#libnvimuilist-eine-listen-senke-statt-vierzehn)
    - [mdview.nvim formatiert jetzt wie die anderen 30 Repos](#mdviewnvim-formatiert-jetzt-wie-die-anderen-30-repos)
    - [open.nvim: uebrig gebliebener Claude-Worktree abgeraeumt](#opennvim-uebrig-gebliebener-claude-worktree-abgeraeumt)

---

## Wiederkehrende Muster -- die Ableitung fuer RULES

**Was das hier ist.** Dreizehn vertikale Durchgaenge haben dieselben Ursachen
mehrfach zutage gefoerdert. Dieser Abschnitt sammelt sie -- nach Haeufigkeit,
mit der **Signatur, an der man sie erkennt**, und mit dem Griff, der sich
bewaehrt hat. Gedacht als Checkliste fuer den naechsten Durchgang und als
Vorlage fuer die RULES-Dateien in
`WKDBooks/Development/wkdbook-Lua/Checklists`.

Die Details und die Begruendungen stehen jeweils beim Repo weiter unten; hier
steht nur, was sich wiederholt hat.

---

### A. Echte Fehler, die der Pruefer gefunden hat

Nach Haeufigkeit. Diese vier Familien haben in jedem Durchgang mindestens
einen echten Bug ergeben -- in zehn Durchgaengen ohne Ausnahme.

#### A1. `vim.uv.new_timer()` ungeprueft -- 22 Stellen, vier Repos in Folge

**Signatur:** `need-check-nil` unmittelbar nach `vim.uv.new_timer()`, oft
zusammen mit einem `cast-local-type`, wenn das Ziel-Local schon als
`uv.uv_timer_t` typisiert war.

```lua
local timer = vim.uv.new_timer()   -- uv_timer_t|nil
timer:start(...)                   -- wirft, wenn nil
```

Verteilung bisher: mdview 10, language 8, github_stats 3, markdown 1.

**Der Griff ist nicht der Punkt, die Frage ist es.** Nicht *"wie bekomme ich
den Befund weg"*, sondern **was die Funktion ohne Timer tun soll**. In
github_stats waren das drei verschiedene Antworten in einer Datei:

| Stelle | ohne Timer |
|---|---|
| Fetch-Zyklus | startet nicht (der einmalige `defer_fn` davor lief schon) |
| Auto-Refresh | entfaellt; die Refresh-Tasten funktionieren weiter |
| Render-Debounce | **sofort rendern** -- nicht zurueckkehren, sonst faellt das Bild aus |

Der Debounce-Fall ist der lehrreiche: die naheliegende Antwort (`return`) ist
dort die falsche. In markdown.nvim kam er zum zweiten Mal vor -- der Timer
entprellt die Live-Referenzpruefung, und ein `return` haette die Ansicht fuer
den Rest der Sitzung stillgelegt, ohne das je zu sagen.

**Nebenregel:** wenn das Ziel-Local aus einer Tabelle nicht-optionaler Timer
kommt, gehoert der optionale Rueckgabewert in ein **eigenes** Local --
`local fresh = vim.uv.new_timer(); if not fresh then return end; t = fresh` --
sonst wandert der Befund von `need-check-nil` nach `cast-local-type`.

#### A2. Eine Bedingung, die gar nichts prueft

**Signatur:** ein `param-type-mismatch` oder `undefined-field` **an einer
Bedingung**. Das sieht nach Annotationspflege aus und ist es oft nicht.

Drei Faelle, alle in lsp.nvim, alle in taeglich laufendem Code:

1. `client:supports_method("textDocumentSync/openClose")` -- kein
   Methodenname, sondern ein Capability-Pfad. Neovims `supports_method` endet
   mit `return required_capability == nil`, kommentiert mit *"if we don't know
   about the method, assume that the client supports it"*. Fuer einen
   erfundenen Namen ist die Antwort **immer `true`**: die Wache sah aus wie
   eine Pruefung und war eine Zusicherung.
2. `caps.publishDiagnosticsProvider` -- diese Capability gibt es im LSP nicht.
   Push-Diagnostics haben ueberhaupt keine. Der Zweig war immer `nil`.
3. `win_id` an `vim.diagnostic.setloclist`, das `winnr` liest -- die
   dokumentierte Option fiel still durch.

**Regel:** wo ein Typfehler an einer Bedingung steht, erst fragen, **was sie
im Ernstfall zurueckgibt**, dann den Typ glattziehen. Ein `supports_method`
mit einem Namen, den Neovim nicht kennt, ist stumm wahr.

#### A3. Ein `---@return boolean`-Helfer ueber einem optionalen Argument

**Signatur:** mehrere `need-check-nil` **nach** einem `if helper(x) then`, alle
auf demselben `x`.

```lua
---@param state State?
---@return boolean
local function has_selection(state) ... end

if has_selection(s) then
  show_detail(s.repos[s.current_index])   -- s ist hier immer noch State?
end
```

Neun der zehn `need-check-nil` in github_stats gingen darauf zurueck. **Eine
Funktion, die `boolean` zurueckgibt, verengt nichts** -- der Beweis bleibt in
ihr, der Aufrufer indiziert weiter einen optionalen Wert. Das ist kein
Prueferartefakt: faellt die Vorbedingung eines Tages weg, wirft genau die
Zeile nach dem `if`.

**Griff:** den **Wert** zurueckgeben statt der Antwort
(`has_selection` -> `selected_repo`). Die Aufrufstellen werden dabei kuerzer,
nicht laenger. Wo der Helfer in mehreren Bedeutungen gebraucht wird, reicht
`if x and helper(x) then`.

#### A4. Aufrufe, die nie funktioniert haben koennen

**Signatur:** `undefined-field` in `lua/`, besonders in Haeufung.

Diese Regel hat in filetree (fuenf Features, die nie etwas rendern), in der
Sechser-Runde (`make_result` mit `path = nil` neben `exists = true`) und in
github_stats (eine Option, die es gibt und die in keinem Typ steht) jedes Mal
etwas ergeben. **Bei einem Repo mit zweistelligem `undefined-field` lohnt der
Durchgang allein deswegen.**

Dahinter stecken drei verschiedene Ursachen, die im Report gleich aussehen:

1. **Der Zugriff ist falsch** -- ein Name, den es nicht gibt (filetree:
   `get_root` statt `get_root_path`; lsp.nvim: `publishDiagnosticsProvider`).
2. **Der Typ fehlt** -- der Zugriff stimmt, die Klasse existiert nicht. In
   replacer trug ein einziges undefiniertes `RP_HighlightConfig` **zwoelf**
   Befunde, in language waren es sieben aus `Lib.Keymap.*` (dort, weil die
   Library-Injektion fehlte, siehe B1).
3. **Der Typ heisst anders** -- in diff.nvim stand `Diff.Config`, wo
   `DiffNvim.Config` gemeint war: ein `undefined-doc-name`, drei
   `undefined-field` auf Feldern, die es sehr wohl gibt, und ein
   `param-type-mismatch` beim korrekten Aufrufer. **Sieben Befunde an einer
   Zeile.**
4. **Die Umkehrung: der Code wird nie gerufen.** In replacer standen die zwei
   Funktionen hinter dem fehlenden Typ ohne einen einzigen Aufrufer da -- der
   Kommentar nennt eine Telescope-Anbindung, die nie entstanden ist.

5. **Der Traeger gehoert einem anderen Repo.** Ein Konsument haengt seine
   eigene Nutzlast an die Struktur einer Bibliothek -- markdown.nvim setzt
   `subcmd` auf jeden Argument-Slot, den es bei lib.nvims composer registriert,
   und liest es im `complete`-Callback zurueck. Der fremde Typ kennt das Feld
   nicht, und **das ist richtig so**: es ist nicht seine Sache.

   **Griff:** die abgeleitete Klasse im eigenen Repo, plus ein `---@cast` an
   der Lesestelle.

   ```lua
   ---@class Mkdn.SubargSpec : Lib.UserCmd.Composer.ArgSpec
   ---@field subcmd string
   ```

   Nicht die Bibliotheksklasse aufbohren: die Erweiterung gehoert dorthin, wo
   die Nutzlast entsteht.

6. **In `TESTS/`: ein Fall, der sich selbst ueberspringt.** In recommender
   pruefte `config_spec` den Deep-Merge gegen `DEFAULTS.float` -- einen
   Schluessel, den es nie gab. Die eigene Wache (`if type(...) == "table"`)
   hat den ganzen Block uebersprungen, still, und er sah wie Abdeckung aus.
   Fuenf `undefined-field` aus einem Fall, der nie gelaufen ist.

   **Daraus:** `undefined-field` in `TESTS/` ist nicht automatisch
   Testrauschen. Wo es auf eine Option oder ein Fixture-Feld zeigt, das es
   nicht gibt, steht dahinter oft ein Fall, der nichts prueft.

**Bei Fall 4 nicht loeschen.** Ob die Funktion gebraucht wird, ist eine
Produktentscheidung; der Durchgang schreibt eine Notiz an die Stelle und
meldet den Fund.

#### A5. Eine Cast-Liste anstelle eines Guards wird unvollstaendig

**Signatur:** eine Funktion liefert N Werte oder keinen, der Guard prueft
einen davon, und der Rest wird per `---@cast` nachgezogen.

```lua
local s, e, found, idx, shape = resolve(ctx, opts)
if not found then return false end
---@cast e integer
---@cast idx integer     -- und `s`?
```

Fuenf solche Stellen in cascade, dazu je eine in language, lsp.nvim und
replacer. **Eine Cast-Liste ist eine Aufzaehlung, und Aufzaehlungen werden
unvollstaendig** -- in cascade fehlte an zwei Stellen `s`, an einer `e0`, an
einer `text`, an einer `scol`/`ecol`.

**Griff, nach Vorzug:**

1. **Den Guard alle Werte pruefen lassen** -- `if not s0 or not e0 then`.
   Dann kann nichts vergessen werden.
2. **Die Gestalt zu einer Tabelle machen**, wenn es wirklich
   alles-oder-nichts ist (C3). `if span then` verengt alles auf einmal.
3. Casts nur dort, wo der Aufrufer den Beweis wirklich nicht selbst fuehren
   kann -- und dann vollzaehlig.

Anmerkung aus dem cascade-Durchgang: **diese Familie findet man selten
vollstaendig beim ersten Durchgang.** Vier Stellen zu sehen und die fuenfte zu
uebersehen ist derselbe Fehlermodus wie der, den man repariert.

---

### B. Die Messgrundlage -- bevor irgendetwas gezaehlt wird

#### B1. `.luarc.json` liest man zuerst -- Cluster L, sieben Repos

**Signatur:** die Datei nennt `workspace.library`.

Eine `.luarc.json` **ersetzt** `workspace.library` komplett, sie ergaenzt
nicht. Wer den Schluessel setzt, wirft die Injektion aus lsp.nvim weg -- und
damit jeden Plugin-Typ. In language kostete das sechs Befunde, die gar keine
waren, sondern die Messung (`Lib.Keymap.Action` galt als undefiniert, und die
vier Feldzugriffe darauf gleich mit).

Betroffen waren: `buffer-ctx`, `emojis`, `fileops`, `gopath`, `lib`,
`sessions`, `language`, `migrate`. `github_stats` hatte es als einziges selbst
erledigt.

**Die Richtung der Summe sagt nichts darueber, ob die Korrektur richtig war.**
Ueber die sechs Repos der M-Runde stieg sie (356 -> 411), in migrate fiel sie
(4 -> 2): dort waren drei der vier Befunde Phantome fehlender Typen, und dafuer
wurde eine Stelle sichtbar, die vorher niemand geprueft hatte.

**Der Zuwachs ist der Zweck.** Nach der Korrektur faellt ein Teil weg (Typen
loesen auf) und ein Teil kommt **dazu** -- an Stellen, die vorher niemand
geprueft hat. Ueber die sechs Repos aus Cluster L stieg die Summe von 356 auf
411, und das war richtig so.

Weiter zu pruefen: `runtime.path` (bei sandbox zeigte er auf ein Verzeichnis,
das es nur unter Windows gibt) und `workspace.ignoreDir`.

#### B2. Ein Nachher-Lauf beweist keine Null

Bei pdfport tauchte ein Befund in einer **unveraenderten** Datei erst im
dritten Lauf auf. In lsp.nvim zeigte der zweite Lauf einen `cast-local-type`,
den der erste nicht hatte; in language waren es zwei.

Der Vergleich sagt zuverlaessig, ob etwas **schlechter** wurde. Eine `0` beim
ersten Versuch kann dagegen heissen, dass ein Befund noch nicht an der Reihe
war. **Bei einem Ergebnis von 0 also zweimal messen.**

**Und der zweite Lauf muss nachweislich fertig sein.** Im cascade-Durchgang
lief `compare.py` gegen ein Pass-Verzeichnis, das noch geschrieben wurde, und
meldete still 0 -- der Commit trug daraufhin faelschlich „in zwei Laeufen
bestaetigt“, und der uebersehene Befund kam erst im Lauf danach zum
Vorschein. Wer die Scans im Hintergrund faehrt, wartet auf die Zeile
`pass '<name>' -> ...`, nicht darauf, dass das Verzeichnis existiert.

---

### C. Annotationsformen, die etwas verschlucken

Drei verschiedene Faelle, dieselbe Ursache: **LuaLS liest eine inline
geschriebene Funktionssignatur nicht so geklammert, wie sie dasteht.**

#### C1. Form A -- `fun(...): T` im Inline-Tabellentyp frisst das naechste Feld

```lua
---@field custom { cmd: fun(a: string): string[], parse: fun(out: string): string[] }|nil
--                                              ^ ab hier verschluckt
```

Der Rueckgabetyp nimmt das Komma und alles danach mit. In pdfport trug **eine
solche Zeile 28 Befunde** (alle Aufrufstellen von `warn`/`error`/`debug` lasen
sich als undefiniert), in language einen (`parse`).

**Griff:** eine benannte Klasse. Nebenbei faellt dabei auf, was die Inline-Form
verdeckt hat -- in language war `cmd` mit zwei Parametern deklariert und wurde
mit drei gerufen.

#### C2. Ein Funktionstyp in einer Union zieht das `|nil` in den Rueckgabetyp

```lua
---@type (fun(): Entry[])|nil     -- gelesen als: fun(): Entry[]|nil
```

Die Klammern helfen nicht. Der Wert erfuellt danach weder `pcall`s Parameter
noch seine eigene Zuweisung.

**Griff:** den **ganzen Funktionstyp** benennen, nicht nur seinen Rueckgabetyp:
`---@alias Reader fun(): Entry[]` und dann `---@type Reader|nil`.

#### C3. Eine Mehrfachrueckgabe, die alles-oder-nichts ist

```lua
---@return integer?, integer?, integer?, integer?
local sr, sc, er, ec = region_bounds(...)
if sr then ... end   -- verengt genau einen von vieren
```

Sechs Befunde aus zwei Zeilen in language. Vier unabhaengige Optionals sind
die falsche Aussage, wenn die Funktion entweder alle vier liefert oder `nil`.
**Mit einer Annotation nicht zu reparieren** -- die Gestalt muss eine Tabelle
werden, dann verengt `if span then` alles auf einmal.

#### C4. Das `value, err`-Idiom traegt seine Zusage nicht im Typ

```lua
---@return T|nil, string|nil
local x, err = f()
if not x then
  notify.error(err)   -- err ist hier `string|nil`
end
```

Vier Stellen in replacer, zwei in language. Der Aufrufer weiss, dass `err`
gesetzt ist, wenn `x` fehlt; der Pruefer sieht zwei unabhaengige Optionals.

**Griff:** `err or "<konkreter Text>"`. Das ist nicht nur
Prueferberuhigung -- faellt der Fehlerpfad wirklich einmal ohne Nachricht an,
meldet die alte Fassung **gar nichts**.

Verwandt: `string.find` gibt beide Bounds zurueck oder keine, und ein Guard
auf nur `s` laesst `e` optional (replacer, `debug.lua`).

#### C6. `fun(T)` ohne Parameternamen parst nicht

```lua
---@param callback fun(string|nil)          -- parst nicht
---@param callback fun(choice: string|nil)  -- parst
```

**Signatur:** `luadoc-miss-symbol` (*"`)` expected"*) auf einer
`@param`-Zeile -- und darunter eine Traube `need-check-nil` oder
`param-type-mismatch` an jeder Stelle, die den Callback benutzt.

Ein `fun(...)`-Typ braucht benannte Parameter. Ohne Namen liest LuaLS den
Typnamen als Parameternamen und bleibt am `|` haengen; der Callback-Typ ist
damit kaputt, und alles daran haengende ebenso. In pickers trugen **drei
solche Zeilen elf Befunde**, davon sechs `need-check-nil` in einer einzigen
Datei.

Damit sind es drei Formen derselben Familie -- A (der Inline-Tabellentyp),
B (die nachgestellten Woerter am `@return`) und C6 (der namenlose
`fun`-Parameter). Alle drei sehen im Bericht nach Kleinkram aus und tragen
zweistellige Zahlen.

#### C5. Weitere Formen, je einmal gesehen

- **Form B:** `---@return <typ>  <wort>,` ohne Namen -- die nachgestellten
  Woerter werden als weitere Rueckgabewerte gelesen (pdfport: acht Befunde;
  insights: **drei Zeilen, sechzehn Befunde**, darunter zwei
  `redundant-return-value` bei Aufrufern, die korrekt annotiert waren).
- **Verirrte Doc-Bloecke** -- sechs Repos in Folge, je fuenf bis acht Befunde
  aus einer Ursache. Signatur: `undefined-doc-param` und
  `duplicate-doc-param`. In images dreimal derselbe Griff: ein nachgeruesteter
  Parameter, dessen Doc-Block **angehaengt statt bearbeitet** wurde.

---

### D. Griffe, die nichts loesen

#### D1. `---@type X` auf einem Local verschiebt den Befund auf die Zuweisung

Zwei Stellen in lsp.nvims `config/init.lua` trugen genau diesen
Reparaturversuch **samt erklaerendem Kommentar**. Die Deklaration ist nicht das
Problem, die Zuweisung der Union ist es.

**Griff:** `---@cast` auf den Wert. Der Cast *behauptet*, was an dieser Stelle
gilt; `---@type` *deklariert*, was die Variable sein soll -- und stolpert dann
ueber das, was zugewiesen wird.

#### D4. `---@cast` quer ueber zwei unverwandte Klassen wird selbst gemeldet

**Signatur:** `cast-type-mismatch` auf der Cast-Zeile, die gerade eingefuegt
wurde, um einen `param-type-mismatch` zu beseitigen.

`---@cast` funktioniert **entlang einer Linie** -- `-nil`, Ober- nach
Untertyp -- nicht quer ueber zwei unabhaengige Klassen. Das ist F1 von der
anderen Seite: LuaLS entscheidet ueber den Namen, und wo es die Zuweisung
verweigert, verweigert es auch die Behauptung.

Gesehen an `nvim_get_hl` -> `nvim_set_hl` in markdown.nvim: dieselbe Tabelle,
von der Lese- und der Schreibseite gesehen (`get_hl_info` markiert jedes
Attribut `true?`, weil es nur die gesetzten meldet; `highlight` nimmt
`boolean?`, weil es sie auch loeschen kann).

**Griff: die Zieltabelle bauen statt casten.**

```lua
local hl = vim.tbl_extend("force", {}, base, { underline = want, undercurl = false })
vim.api.nvim_set_hl(0, group, hl)
```

`vim.tbl_extend` gibt `table` zurueck, und ein `table` erfuellt jede Klasse.
Die gebaute Fassung ist ausserdem die ehrlichere: sie sagt, welche der beiden
Seiten gemeint ist, behaelt jedes Attribut des Colorschemes und braucht keine
Feldliste, die veralten kann.

#### D5. Ein `---@cast` endet an der naechsten Zuweisung

**Signatur:** derselbe Befund taucht ein paar Zeilen unter einem frisch
gesetzten Cast wieder auf -- meist in einer Testdatei, die ein Local pro Fall
zurueckstellt.

```lua
---@cast captured table
...
captured = nil        -- ab hier gilt der Cast nicht mehr
cmd.handle({ ... })
check("...", captured.find.hidden == false)   -- undefined-field
```

Ein Cast behauptet etwas ueber den **aktuellen** Wert, nicht ueber die
Variable. Jede Zuweisung hebt ihn auf. Derselbe Fehlermodus wie die
unvollstaendige Cast-Liste in A5, nur zeitlich statt ueber die Werte verteilt:
die erste Stelle sieht man, die zweite sieht genauso aus.

**Griff:** pro Abschnitt zwischen zwei Zuweisungen einen eigenen Cast -- oder,
wo es geht, das Local nicht zuruecksetzen, sondern pro Fall ein neues nehmen.

#### D2. Ein Fix, der die Warnung nur weiterschiebt

In language haette der erste Timer-Fix den Befund von `timer` auf
`opts.timeout_ms` verschoben, weil der zweite `if` ausserhalb der Pruefung des
ersten stand. **Wenn eine Aenderung anderswo neue Befunde erzeugt, ist sie
unfertig.**

In color_my_ascii ist genau das passiert und erst der naechste Lauf hat es
gezeigt: der Befund auf `ts_parser:parse()[1]:root()` sah nach dem *Baum* aus,
war aber auch der **Parser** -- `get_parser` antwortet mit nil, wenn die
Grammatik fehlt. Und der richtige Griff hing daran, was der Aufrufer mit dem
Ergebnis macht: er prueft `markdown_available()` und faengt den Aufruf mit
`pcall` ab, um auf den heuristischen Scanner zurueckzufallen. Eine leere Liste
haette *"diese Datei hat keine Fences"* gesagt statt *"Treesitter kann hier
nicht"*, also `assert`.

#### D3. `pcall(vim.cmd, ...)` -- und nicht nur `vim.cmd`

**Signatur:** `Cannot assign 'table' to parameter 'fun(...any):...unknown'`.

`vim.cmd` ist eine Tabelle mit `__call`-Metamethode, kein `function`; die
Metamethode rettet das im Typsystem nicht. **`vim.lsp.config` und
`lib.nvim.bindings.keymap` sind dieselbe Gestalt** -- wer nach dem Cluster
sucht, sucht nach der Meldung, nicht nach `vim.cmd`. Jedes Modul, das sich
als aufrufbare Tabelle exportiert, faellt hierunter.

**Griff: die Closure-Form**, nicht `vim.cmd.<name>`. In images tauscht ein
Spec `vim.cmd` selbst und liest den Kommandonamen aus dem ersten Argument --
die Unterkommando-Form haette den Test still blind gemacht.

---

### E. Wann Unterdruecken richtig ist

Nur wo der Befund **sachlich falsch** ist oder das Verhalten **Absicht** --
und dann mit einem Satz, der sagt warum. Was sich in neun Durchgaengen als
diese Kategorie herausgestellt hat:

- **Test-Doubles ueber typisierter `vim.*`- oder Modul-Oberflaeche**
  (`duplicate-set-field`). Am images-Durchgang entschieden: faellt vertikal
  an, braucht keinen eigenen horizontalen Lauf. Kostet pro Repo Minuten.
- **Absichtlich ungueltige Testeingaben** -- `add_session(nil)`,
  `setup_all(nil, ...)`. Der Testname sagt meist schon warum
  (*"returns nothing without a shared table"*).
- **Bewusste Griffe in fremde private Felder** -- lsp.nvims Patch von
  `vim.treesitter.highlighter._on_win`. Drei Befunde, die alle dasselbe Wahre
  sagen: ein `---@cast` auf ein untypisiertes Handle sagt die Absicht einmal,
  statt sie dreimal zu unterdruecken.
- **Offene String-Enums des Protokolls** -- `source.organizeImports.astro` ist
  ein gueltiger CodeActionKind, Neovims Meta listet nur die Standard-Kinds.

#### `deprecated` ist nicht automatisch eine Schuld

**Erst die Mindestversion im README lesen, dann entscheiden.** In language
waren alle drei bewusste Fallbacks (README: Neovim `>= 0.9`, und
`vim.diagnostic.jump` gibt es erst ab 0.11). In lsp.nvim (README: 0.11+) waren
zwei which-key-v2-Fallbacks und **nur einer** echt migrierbar.

---

### F. Was Neovim schon fuehrt

#### F1. LuaLS entscheidet Zuweisbarkeit ueber den **Namen**, nicht die Gestalt

Zweimal dieselbe Lehre: bei `Images.Scale.Dims` und bei lsp.nvims `LspMod.*`.
Ein Parallelname mit identischen Feldern ist deshalb nicht gratis -- er kann
**niemals** aus dem Original zugewiesen werden. lsp.nvim fuehrte sechs solche
Klassen; Neovim hat jede davon, und praeziser (`offset_encoding` als
`'utf-8'|'utf-16'|'utf-32'` statt `string|nil`).

**Vor einer eigenen `@class` fuer etwas, das Neovim beschreibt, erst dort
nachsehen:** `vim.lsp.Client`, `lsp.ServerCapabilities`,
`lsp.TextDocumentIdentifier`, `lsp.Position`, `lsp.Range`,
`lsp.CodeActionParams`, `lsp.VersionedTextDocumentIdentifier`.

#### F5. Ein Alias auf eine `vim.*`-Funktion kann nil-behaftet zurueckkommen

**Signatur:** `need-check-nil` an einer Aufrufstelle, deren Ziel ein
Modulkopf-Local ist -- `local set_km = vim.keymap.set` und dergleichen.

Der Wert ist nie nil, und isolierte Reproduktionen bleiben sauber; im
Workspace steht der Befund trotzdem. Ein explizites `---@type` auf der
Alias-Zeile beseitigt ihn:

```lua
---@type fun(mode: string|string[], lhs: string, rhs: string|function, opts?: table)
local set_km = vim.keymap.set
```

**Das trifft ein Idiom, das viele dieser Repos benutzen** -- `vim.*`-Funktionen
am Modulkopf in Locals ziehen, aus Performancegruenden. Wer das tut, typisiert
den Alias mit; sonst zahlt jede Aufrufstelle dafuer, und die Meldung steht
dort, wo der Fehler nicht ist. In reposcope waren es zwei Aufrufstellen aus
einer Zeile.

#### F2. `vim.health.info` und `.ok` nehmen **kein** zweites Argument

Sechs Repos in Folge haben ihnen eine Advice-Liste gegeben, die sie wegwerfen.
`health.error` und `health.warn` nehmen eine, `info` und `ok` nicht.

**Der Befund heisst `redundant-parameter` und klingt nach Stil; er ist ein
fehlendes Feature** -- die Hinweise hat kein `:checkhealth` je gezeigt. In
einer `health.lua` ist `redundant-parameter` nie Stil.

**Und umgekehrt: ein `deprecated` im Code heisst, dass `health.lua` dieselbe
Frage neu beantworten muss.** In diff.nvim prueft der Health-Check
`type(vim.diff) == "function"`, waehrend der Code auf `vim.text.diff`
umgestellt wurde -- das haette `:checkhealth` irgendwann *"vim.diff is
missing"* melden lassen fuer ein Neovim, auf dem alles funktioniert. Die
beiden Stellen gehoeren zusammen geprueft.

#### F3. Eine geaenderte Signatur meldet sich als `param-type-mismatch`

Nicht jede API-Aenderung in Neovim ist als `deprecated` markiert. Manche
**tauschen die Bedeutung eines Arguments**, und der einzige Hinweis ist ein
Typfehler an einer Stelle, die jahrelang funktioniert hat.

`vim.str_utfindex(str, index)` bis 0.10, `vim.str_utfindex(str, encoding,
index, strict)` seit 0.11 -- der alte Aufruf uebergibt seinen Index dort, wo
jetzt die Kodierung erwartet wird, und wirft. In replacer war das
`:ReplaceDebug`, gemeldet als
`Cannot assign 'integer' to parameter '"utf-16"|"utf-32"|"utf-8"'`.

**Signatur:** ein `param-type-mismatch` gegen eine String-Union an einem
`vim.*`-Aufruf. Gegenprobe: nachsehen, wie **Neovim die Funktion selbst
ruft** -- `grep` im Runtime-Verzeichnis ist schneller als die Doku.

Bei breiter Versionsspanne im README ist die Antwort eine **Probe**, keine
Migration (`pcall` auf die neue Form, Rueckfall auf die alte) -- siehe auch
die `deprecated`-Regel in Abschnitt E.

#### F4. `os.date("*t")` liefert eine Tabelle, deren Felder LuaLS aufweitet

`---@cast parts osdate` reicht **nicht**: dieselbe Klasse beschreibt auch die
String-Form des Aufrufs, deshalb sind ihre Felder `integer|string`. Der Cast
muss die Felder benennen, die dieser Aufruf wirklich liefert.

---

### G. Der Test-Runner

Drei Repos, dasselbe Loch an derselben Stelle -- **ein Runner, der fehlende
Voraussetzungen nicht meldet**:

| Repo | Verhalten ohne Harness |
|---|---|
| neotree-fs-refactor | *"All tests passed"*, Exit-Code **0** |
| lsp.nvim | **wartet stumm** -- sieben Minuten ohne ein Byte Ausgabe |
| dap.nvim | ohne `PLENARY_PATH` **stumm**, ohne `LIB_NVIM_PATH` **vier rote Tests** |
| **github_stats.nvim** | Meldung mit drei Fundorten, Exit-Code **1** |

**dap.nvim hat die dritte Fehlerart gezeigt, und sie ist die teuerste:** vier
Faelle scheitern mit `module 'lib.nvim.notify' not found`, was aussieht wie ein
Defekt im Code. Wer gerade etwas geaendert hat, sucht erst bei sich.

Beide Fehlerfaelle sehen fuer den Aufrufer aus wie *"die Tests laufen gerade"*.
Das ist kein Windows-Problem, wie es lange in Offen-Punkt 13 stand: in lsp.nvim
war die Ursache, dass `TESTS/minimal_init.lua` plenary ausschliesslich ueber
`$PLENARY_PATH` sucht -- eine Variable, die nur CI setzt.

**Die Vorlage ist `github_stats.nvim/scripts/test.sh` mit
`scripts/minimal_init.lua`:**

1. **drei Fundorte mit Fallback** -- `$PLENARY_DIR`, `.deps/`, daneben;
2. **eine Fehlermeldung, die alle drei nennt** --
   *"Set PLENARY_DIR, or clone it to .deps/plenary.nvim, or place it beside
   this repo"*;
3. **ein Exit-Code, der nicht luegt.**

Fuer neue Repos ist das der Massstab, nicht eine allgemeine Formulierung.

---

### H. Arbeitsreihenfolge, die sich bewaehrt hat

1. **`.luarc.json` lesen** (B1) -- vor jeder Zahl.
2. **Vorher-Scan**, ein Repo (`scan.sh before <repo>`).
3. **Nach verirrten Doc-Bloecken suchen** (C4) -- die billigste Haeufung.
4. **`health.lua` pruefen** (F2) -- ein Blick, sechs Repos in Folge ein Treffer.
5. **`undefined-field` in `lua/` zuerst** (A4) -- dort liegen die echten Bugs.
6. **`need-check-nil` gruppieren** -- meist ein bis zwei Ursachen (A1, A3).
7. **`TESTS/` zuletzt** -- Doubles und absichtlich ungueltige Eingaben (E),
   das ist Minutenarbeit und sagt nichts ueber den Code.
8. **Zweimal nachmessen** (B2), Testsuite, ein Commit pro Repo, direkt gepusht.

Die Schritte 1, 3 und 4 kosten zusammen wenige Minuten und gehen auch dann
nicht ins Leere, wenn sie nichts finden: in markdown.nvim waren `.luarc.json`,
`health.lua` und die Doc-Bloecke allesamt sauber, und danach war klar, dass die
dreissig Befunde tatsaechlich dreissig einzelne sind und keine Messfrage.

---

## 2026-09-02

---

### Der Messfehler, den ein Worktree erzeugt -- und `mkcfg.py`s `drop_own`

*(war: Diagnostics-Report Abschnitt 0, „Nicht von Claude entschieden")*

Die Worktree-Frage stand seit dem Erstscan als Aufraeumthema im Report. Sie
war keins. Sie war ein Messfehler, und er war gross genug, den letzten
Durchgang unmoeglich zu machen.

**Der Befund.** Die nvim-Config meldete **872** statt der 120 aus jedem
frueheren Lauf -- 674 `duplicate-doc-field` und 81 `duplicate-doc-alias`
davon, also 755 Kollisionen.

**Die Ursache.** lsp.nvims `build_library()` nimmt jedes `@types`-Verzeichnis,
das es findet, in `workspace.library` auf. Fuer ein Plugin ist das der Zweck.
Fuer die Config zeigen diese Pfade auf `C:/Users/bartl/AppData/Local/nvim/...`
-- den **Haupt-Checkout**. Laeuft der Scan aus einem Worktree, ist der
Workspace ein *anderes* Verzeichnis mit denselben Dateien. Jede Klasse und
jeder Alias existiert dann zweimal, und LuaLS meldet jede einzelne davon.

Aus dem Haupt-Checkout heraus faellt das nie auf: dort sind Workspace und
Library dasselbe Verzeichnis, und LuaLS zaehlt nichts doppelt.

**Der Griff.** `mkcfg.py` filtert `workspace.library` jetzt gegen die eigenen
Baeume des Workspace (`drop_own`): `root` selbst, und -- wenn `root` unter
`<tree>/.claude/worktrees/<name>` liegt -- auch `<tree>`. Eine Library ist
fremder Code; lua_ls sagt in seiner eigenen Doku, man solle den Workspace
nicht als Library setzen.

**Gegengeprueft, in beide Richtungen:**

- die Config misst danach wieder **exakt 120** -- die Zahl aus `base0901`,
  `base0902` und `igafter2`, also aus Laeufen, die aus dem Haupt-Checkout
  kamen;
- `filetree.nvim`, `pdfport.nvim` bleiben auf 0, `lib.nvim` meldete die eine
  neue Stelle aus dem Hover-Modul. Der Fix ist fuer Plugins neutral.

**Was daraus fuer `## letze-task` folgt** -- das ist der eigentliche Ertrag:

- **Eine Messgrundlage muss man gegen einen bekannten Wert pruefen, nicht nur
  gegen sich selbst.** Der Vergleich Vorher/Nachher haette hier nie etwas
  gemerkt: beide Laeufe waeren aus demselben Worktree gekommen und beide
  haetten 872 gesagt. Aufgefallen ist es nur, weil im Report eine Zahl aus
  einer *anderen* Umgebung stand. **Historische Zahlen aufheben ist Teil des
  Werkzeugs, nicht Dokumentation daneben.**
- **„Der Workspace ist nicht seine eigene Library" ist eine Regel, kein
  Sonderfall.** Sie greift ueberall dort, wo dieselben Dateien ueber zwei
  Pfade erreichbar sind: Worktrees, Symlinks, eine zweite Checkout-Kopie,
  ein `build/stage`-Verzeichnis.
- **Der Zaehler `duplicate-doc-*` ist ein Umgebungs-Kanarienvogel.** Er
  entsteht fast nie aus echtem Code. Steht er zweistellig, ist mit hoher
  Wahrscheinlichkeit die Messung falsch und nicht der Quelltext -- dieselbe
  Signatur wie bei lsp.nvims 180 im August und bei
  `neotree-fs-refactor.nvim`s `Luassert` gegen plenarys.

---

### Die nvim-Config, erste Haelfte -- 120 auf 39

*(unterbrochen; der Rest steht im Report unter „Wiedereinstieg")*

`worse: nothing`. Die grossen Posten sind weg, und es waren durchweg
Wiederholungen aus den Plugin-Durchgaengen -- was fuer die letzte Task das
Wichtigste ist: **die Config hatte keine eigenen Muster.**

- **`clock.utc_captures` (18).** Drei Aufrufer bauten je sechs `tonumber()`
  aus `%d+`-Captures und gaben sie an `clock.utc`, das `integer` will.
  `tonumber` antwortet `number|nil` fuer *jeden* String -- aber ein Capture,
  das bereits gematcht hat, kann nicht fehlschlagen. Ein Helfer sagt das
  einmal, statt es dreimal offenzulassen. Dieselbe Familie noch zweimal bei
  `os.time` (`assert(tonumber(...))`).
- **`os.date` -> `tostring` (10).** Zum dritten Mal nach runtime-analysis und
  markdown: `os.date(fmt)` ist `string|osdate`, nur `"*t"` liefert die
  Tabelle.
- **`Cfg.Harpoon.List` (8).** Ein handgeschriebener Stand-in fuer harpoons
  `HarpoonList` fuehrte drei Member, waehrend der Code sieben ruft
  (`remove_at`, `prepend`, `_length`, ...). **Ein Stand-in, der weglaesst, was
  seine Aufrufer benutzen, meldet den Aufrufer als falsch, nicht sich selbst
  als unvollstaendig** -- das ist die verallgemeinerbare Lehre.
- **`Lib.UserCmd.Composer.RouteSpec` (5).** Den Typ gibt es nicht; lib.nvim
  veroeffentlicht `Lib.UserCmd.Composer.Route`. Ein Name, fuenf Befunde.
- **`drift.lua`s `repo`-Local (10).** `local repo_ran = repo_info ~= nil and
  ...` -- ein **Boolean ueber** einen Wert traegt dessen Verengung nicht. Der
  verengte Wert selbst muss gebunden werden. Dieselbe Form wie in gopaths
  `:GopathDebug` und open.nvims `got`.
- **F5 auf `local system = vim.system` (6).** Der typisierte Alias, in zwei
  Dateien.
- **Beide Annotationsformen aus dem Querschnittspunkt (7).** Genau dort, wo
  die Suche am 2026-09-01 sie vorhergesagt hatte: Form A zweimal in
  `snacks/picker/init.lua` (ein `fun(): table` im Tabellentyp verschluckt
  `get_input_keys` und `get_actions`), Form B dreimal
  (`epoch, the most recent occurrence` -- `the` wird als zweiter
  Rueckgabetyp gelesen). **Die Vorhersage hat gehalten**, was den Wert einer
  gemusterten Suche gegenueber dem Wiederfinden pro Repo belegt.

---


---

### Die Achter-Runde -- die letzten acht Plugins, 50 auf 0

*(war: Diagnostics-Report Abschnitt 0, "die acht kleinen Repos in einem Zug")*

**50 -> 0** (reposcope 9, color_my_ascii 8, debugging 8, dap 7, filetree 6,
cmdlog 4, migrate 4, runtime-analysis 4), in zwei weiteren Laeufen bestaetigt,
`worse: nothing`. Jede Suite gruen, `stylua --check` sauber, luacheck
unveraendert. Acht Commits: `6c70fca`, `dbceedf`, `e64b275`, `55003bc`,
`c0e195d`, `609d73e`, `a7c7ae7`, `d23fa09`.

**Damit stehen einunddreissig der 32 Workspaces auf Null.** Offen ist nur noch
die nvim-Config.

Die dritte Runde dieser Form (nach der Sechser- und der Dreier-Runde) und die
mit dem groessten Streuungsgrad: acht Repos, zwoelf Ursachen, kaum
Wiederholung -- und trotzdem war der Zuschnitt richtig, weil der Overhead pro
Repo (Scan, Suite, Commit) bei vier bis neun Befunden der groessere Posten ist.

---

#### Ein Alias auf eine `vim.*`-Funktion kann nil-behaftet zurueckkommen

Der Fund, der am laengsten gedauert hat, und der einzige, den ich beim Lesen
nicht erklaeren konnte.

```lua
local set_km = vim.keymap.set   -- Modulkopf
...
set_km(modes, lhs, rhs, map_opts)   -- need-check-nil
```

`vim.keymap.set` ist nie nil. **Vier isolierte Reproduktionen blieben sauber**
-- mit den echten Annotationen der Funktion, mit der globalen Funktionsform,
mit derselben Aufrufform, mit denselben Parametertypen. Im Workspace blieb der
Befund an beiden Aufrufstellen stehen.

Ein explizites `---@type` auf der Alias-Zeile hat beide beseitigt:

```lua
---@type fun(mode: string|string[], lhs: string, rhs: string|function, opts?: table)
local set_km = vim.keymap.set
```

**Das trifft ein Idiom, das mehrere dieser Repos benutzen**: `vim.*`-Funktionen
am Modulkopf in Locals ziehen, aus Performancegruenden. Wer das tut, sollte den
Alias typisieren -- sonst zahlt jede Aufrufstelle dafuer, und die Meldung steht
dann dort, wo der Fehler nicht ist. Neuer Musterpunkt F5.

---

#### migrate.nvim: Cluster L zum achten Mal -- und diesmal faellt die Zahl

`.luarc.json` deklarierte `workspace.library` und warf damit die Injektion weg.
Anders als bei den sechs Repos der M-Runde und bei language.nvim ist die Zahl
danach **gesunken**, nicht gestiegen: **4 -> 2**.

| | vorher (falsche Grundlage) | nachher |
|---|---|---|
| `Lib.Keymap.Action` / `.Registered` | 2 Befunde | weg -- die Typen sind jetzt sichtbar |
| `LogLevelString` | 1 Befund | weg |
| `pcall(vim.cmd, ...)` | 1 | 1 |
| `ensure_buffer` gibt den Fehler-Slot zurueck | -- | **neu sichtbar** |

Beide Richtungen gehoeren zusammen: ein Teil faellt weg, weil Typen aufloesen,
ein Teil kommt dazu, weil Stellen geprueft werden, die vorher niemand
angesehen hat. **Die Richtung der Summe sagt nichts darueber, ob die Korrektur
richtig war.**

---

#### dap.nvim: der Test-Runner, vierter Fall -- und eine zweite Fehlerart

`TESTS/minimal_init.lua` sucht plenary **und** lib.nvim ueber Umgebungsvariablen,
die nur CI setzt. Ohne sie:

| fehlt | Verhalten |
|---|---|
| `PLENARY_PATH` | **wartet stumm** -- kein Byte Ausgabe (wie lsp.nvim) |
| `LIB_NVIM_PATH` | **vier rote Tests**, `module 'lib.nvim.notify' not found` |

Die zweite ist die gefaehrlichere und in der Tabelle in Abschnitt G bisher
nicht vertreten: der Lauf sieht aus wie ein echter Defekt im Code. Ich habe
zuerst geprueft, ob meine eigene Aenderung ihn verursacht hat -- genau die
Minuten, die ein Runner mit einer Meldung spart.

Mit beiden Variablen: 25 Faelle, 0 Fehler.

---

#### color_my_ascii.nvim: ein Argument, das still verfiel -- und ein Fix, der den Befund verschob

**`:Fence export` hat sein zweites Argument verloren.** Die Subkommando-Tabelle
deklariert `fun(argv, ctx)`, der export-Eintrag reichte beides an `export.run`
weiter, das eines nimmt. Lua nimmt das hin; `redundant-parameter` ist die
einzige Stelle, die es sagt. Die zwei Eintraege direkt darunter (`yank`,
`open`) machen es schon richtig.

Und ein Lehrstueck zu D2: der Befund auf `ts_parser:parse()[1]:root()` schien
der Baum zu sein, also habe ich den Baum geprueft -- und der naechste Lauf
zeigte denselben Befund eine Zeile hoeher, auf dem **Parser**.
`vim.treesitter.get_parser` antwortet mit nil, wenn die Grammatik fehlt.

Die Antwort war dann nicht "leere Liste zurueckgeben": der Aufrufer prueft
`markdown_available()` und wickelt den Aufruf in ein `pcall`, um auf den
heuristischen Scanner zurueckzufallen. Ein leeres Ergebnis haette gesagt *"diese
Datei hat keine Fences"* statt *"Treesitter kann hier nicht"* -- also `assert`,
damit der Rueckfall greift. **Der richtige Griff haengt daran, was der Aufrufer
mit dem Ergebnis macht.**

---

#### Der Rest, nach Familien

- **cmdlog: C2**, drei Befunde aus einer Zeile.
  `---@return (fun(...): string[])|nil` wird als `fun(...): string[]|nil`
  gelesen -- die Klammern binden nicht so, wie sie aussehen. Der ganze
  Funktionstyp heisst jetzt `Cmdlog.ShellHistoryParser`.
- **debugging: `cmd.buffer`.** `nvim_get_autocmds` antwortet mit **beidem**,
  `buf` und `buffer`; in Neovims Meta steht nur `buf`. Empirisch geprueft, nicht
  aus der Doku gelesen.
- **debugging: `Dbg.Tools.ProcTraceOpts`** war eine zweite Klasse fuer eine
  Gestalt, die lib.nvim schon beschreibt -- und Klassen sind ueber den Namen
  zuweisbar (F1), eine Parallelklasse kann der Funktion, fuer die sie
  geschrieben wurde, nie uebergeben werden. Jetzt ein `@alias`.
- **debugging: `vim.fn.termopen`** ist deprecated, die Nachfolge
  (`jobstart({ term = true })`) gibt es erst ab 0.11, das README nennt 0.9+ --
  bewusster Rueckfall, unterdrueckt mit dieser Begruendung (Regel E).
- **reposcope: `"clos"` war kein Tippfehler.** Die Meldung haengt `ing` an,
  `"close"` haette *closeing* ergeben. Hier war die **Annotation** falsch.
- **reposcope: `return x:gsub(...)`** aus einer Funktion, die einen Wert
  verspricht -- `gsub` gibt String *und* Ersetzungszahl zurueck. Geklammert.
- **reposcope: `nvim_get_hl` -> `nvim_set_hl`**, dieselbe Zwei-Klassen-Runde
  wie in markdown.nvim; die Schreibtabelle wird gebaut statt mutiert (D4).
- **dap: zwei Anfragen, die keine Provider sind.** `'auto'` und `'none'` sind
  das, was der Benutzer *fragen* darf; gespeichert wird nur eines der zwei
  echten. Drei Befunde daraus.
- **dap: drei Re-Exporte mit `@param`** -- Annotationen, die eine
  Parameterliste brauchen, die eine Zuweisung nicht hat.
- **filetree: sechsmal `vim.notify`**, fuenf Test-Doubles und **eine
  Produktionsstelle**: `watcher_quarantine` ersetzt `vim.notify`, um die
  EPERM-Zeilen der Datei-Watcher zu schlucken, haelt das Original und stellt es
  zurueck. Beides ist der Zweck des Codes, beides mit dem Satz daneben
  unterdrueckt.
- **runtime-analysis: vier Doubles**, gleiche Behandlung.

---

#### Cluster E ist damit leer -- bis auf die Config

Nach migrate und color_my_ascii steht in den 31 Plugins kein
`pcall(vim.cmd, ...)` mehr. Was die Suche noch findet, ist durchweg die
**Feldform** (`pcall(vim.cmd.edit, ...)`, `vim.cmd.helptags`, `vim.cmd.cd`) --
und die ist eine echte Funktion, also kein Befund. Die einzige verbliebene
Stelle der Tabellenform liegt in `nvim/lua/config/menu/custom_menu/init.lua`.

---

### Die Dreier-Runde -- pickers, insights und recommender, 73 auf 0

*(war: Diagnostics-Report Abschnitt 0, "pickers.nvim / insights.nvim" und der
Rest der kleinen Repos)*

**73 -> 0** (pickers 32, insights 29, recommender 12), in zwei weiteren
Laeufen bestaetigt, `worse: nothing`. Jede Suite gruen: 297 Faelle in pickers,
`INSIGHTS_TESTS_OK`, `RECOMMENDER_TESTS_OK`. `stylua --check` sauber, luacheck
0/0 in allen dreien. Commits: `9fa84de`, `786225e`, `5af81d5`.

Drei Repos in einem Zug, wie die Sechser-Runde -- und wieder hat sich der
Zuschnitt ausgezahlt: **zwei der drei hatten dieselbe Ursachenfamilie**
(eine Annotation, die nicht parst und alles unter sich mitnimmt), nur in zwei
verschiedenen Formen. Der Denkanteil fiel einmal an.

---

#### Vorab: die zwei billigen Pruefungen, dreimal umsonst

`.luarc.json` setzt in keinem der drei `workspace.library` (Cluster L trifft
nicht zu), und keine der `info`/`ok`-Stellen in den drei `health.lua`
uebergibt eine Advice-Liste (F2 bleibt zum zweiten Mal in Folge aus). Das
kostet zusammen zwei Minuten und ist die Voraussetzung dafuer, den Zahlen zu
glauben -- siehe den Nachtrag zu H.

---

#### pickers: `fun(T)` ist keine Signatur -- elf Befunde aus drei Zeilen

```lua
---@param callback fun(string|nil)          -- parst nicht
---@param callback fun(choice: string|nil)  -- parst
```

Ein `fun(...)`-Typ braucht **benannte** Parameter. Ohne Namen liest LuaLS den
Typnamen als Parameter*namen* und bleibt am `|` haengen -- gemeldet als
`luadoc-miss-symbol` (*"`)` expected"*). Der Callback-Typ ist damit kaputt, und
alles, was an ihm haengt, ebenso:

| Datei | Folgebefunde |
|---|---|
| `ui/dir_nav_picker.lua` | **6 `need-check-nil`** an jedem `callback(...)` |
| `ui/action_picker.lua` | 1 `param-type-mismatch` an `vim.ui.select` |
| `ui/scope_picker.lua` | 1 `param-type-mismatch` an `vim.ui.select` |

**Drei Zeilen, elf Befunde.** Dieselbe Rechnung wie Form A in pdfport (28 aus
einer Zeile) und Form B in insights (16 aus dreien) -- nur eine dritte Form.

Dazu ein verirrter Doc-Block: die zwei `@param` von `M.get` standen zwanzig
Zeilen hoeher ueber `M.is_windows()`, das keine nimmt. Sechstes Repo in Folge
mit dieser Ursache.

---

#### insights: dieselbe Familie, Form B -- und drei Namen fuer eine Gestalt

```lua
---@return table[], string|nil   entries, status_message
```

Die nachgestellten Woerter sind keine Beschreibung: LuaLS liest sie als
**dritten** Rueckgabewert vom Typ `status_message`, den es nicht gibt. Drei
solche Zeilen trugen sechzehn Befunde -- drei `undefined-doc-name`, sechs
`missing-return-value` (*"at least 3 required"*), vier `return-type-mismatch`
fuer eine #3, die nie zurueckkam, und zwei `redundant-return-value` **bei
korrekt annotierten Aufrufern**.

Beim Aufschreiben der richtigen Form fiel der eigentliche Riss auf: **die drei
Lua-Scanner geben dieselbe Gestalt zurueck und nennen sie verschieden.**

| Modul | deklariert | setzt |
|---|---|---|
| `symbols/ts_lua.lua` | `file: string\|nil` | `file = nil` (legt in Lua **keinen** Schluessel an) |
| `symbols/ts_lua_strings.lua` | `filename`, `func_type` | beide |
| `symbols/ts_lua_tables.lua` | `filename`, `func_type` | beide |

Gelesen wird ueberall `filename` -- vom Stempel in `symbols/init.lua` bis zur
Anzeige in `symbols/open.lua`. `file` liest und schreibt niemand. Jetzt einmal
als `Insights.Symbols.Match` ausgeschrieben und von allen dreien benutzt; das
tote `file = nil` ist weg, und `func_type` steht als das optionale Feld da, das
es ist (der Picker zeigt `?` fuer den Scanner, der es nicht setzt).

**Das ist der Griff aus C1 -- eine benannte Klasse -- und der Nebeneffekt ist
wieder der eigentliche Gewinn:** die Inline-Form hat den Namensunterschied
zwischen drei Geschwistermodulen verdeckt.

---

#### recommender: ein Testfall, der nie gelaufen ist

Fuenf der zwoelf Befunde waren `undefined-field` in **einer** Testdatei:

```lua
if type(DEFAULTS.float) == "table" then    -- gibt es nicht
  local sub = next(DEFAULTS.float)
  ...
```

`config_spec` prueft, dass ein Deep-Merge die Geschwister des gesetzten
Schluessels behaelt -- gegen `DEFAULTS.float`, einen Schluessel, den diese
Config nie hatte. Der Fall hat sich mit seiner eigenen Wache uebersprungen,
lief nie, und sah im Bericht wie Abdeckung aus. Er zeigt jetzt auf
`custom_aliases`, die verschachtelte Tabelle, um die es geht, und laeuft.

**Daraus die Regel:** `undefined-field` in `TESTS/` ist nicht automatisch
Testrauschen. Wo es auf eine Konfigurationsoption oder ein Fixture-Feld zeigt,
das es nicht gibt, steht dahinter oft ein Fall, der sich selbst ueberspringt.

Dazu ein Analyzer, den die eigene Signatur nicht kannte: `get_analyzer`
akzeptierte vier Namen, `ANALYZER_NAMES` -- die Liste, gegen die die
Kommandozeile validiert -- fuehrt fuenf. `perf` hat ein eigenes Modul, eine
eigene Health-Zeile und einen Eintrag im oeffentlichen Config-Typ; nur diese
eine Annotation hatte nie von ihm gehoert.

Und `pcall(lib_map, ...)`: `lib.nvim.bindings.keymap` exportiert sich als
aufrufbare Tabelle, nicht als Funktion -- **dieselbe Gestalt wie
`pcall(vim.cmd, ...)`**, dieselbe Closure-Form als Griff. Wer nach Cluster E
sucht, sucht nach der Meldung, nicht nach `vim.cmd`.

---

#### Was der Nachher-Lauf noch gezeigt hat: ein Cast endet an der naechsten Zuweisung

Der erste Nachher-Lauf stand bei 1 statt 0, und zwar in einer Datei, die ich
gerade bearbeitet hatte. `TESTS/pickers_spec.lua` faengt die Optionen eines
Doubles in einem Local, prueft sie, **setzt das Local dann auf `nil` zurueck**
und fuellt es fuer den naechsten Fall neu:

```lua
check("...", captured and captured.find and captured.find.hidden == true)
---@cast captured table          -- gilt ab hier
...
captured = nil                   -- und hier ist es wieder vorbei
cmd.handle({ ... })
check("...", captured.find.hidden == false)   -- undefined-field
```

**Eine Zuweisung hebt die Einengung auf** -- ein `---@cast` gilt bis dahin und
keine Zeile weiter. Das ist derselbe Fehlermodus wie die unvollstaendige
Cast-Liste in A5, nur zeitlich statt ueber die Werte verteilt: man sieht die
erste Stelle, repariert sie, und uebersieht die zweite, weil sie gleich
aussieht.

---

### markdown.nvim -- 30 auf 0, ein Timer ohne Antwort und ein Cast, der selbst gemeldet wird

*(war: Diagnostics-Report Abschnitt 0, "markdown.nvim")*

**30 -> 0**, in zwei Laeufen bestaetigt, `worse: nothing`. Alle 26
Spec-Dateien gruen (`MARKDOWN_TESTS_OK`), `stylua --check .` sauber, luacheck
unveraendert (fuenf Bestandswarnungen, alle in Zeilen, die dieser Durchgang
nicht angefasst hat). Ein Commit, `689cafc`.

Die Verteilung war die guenstigste der Reihe: **zwanzig der dreissig lagen in
`TESTS/`** und waren Minutenarbeit (Doubles, Casts hinter Zusicherungen, die
der Test schon ausspricht). Die zehn in `lua/` hatten sechs Ursachen, zwei
davon lehrreich.

---

#### `.luarc.json` und `health.lua`: diesmal beide sauber

Die zwei ersten Schritte der Reihenfolge (H) haben hier nichts ergeben, und
das ist die Meldung wert: markdown.nvim setzt `workspace.library` **nicht**
(Cluster L trifft nicht zu, die Messgrundlage stimmt ab dem ersten Lauf), und
keine der 18 `info`/`ok`-Stellen in `health.lua` uebergibt eine Advice-Liste
(F2, das erste Repo seit sechs ohne diesen Fund). Auch keine verirrten
Doc-Bloecke -- weder `undefined-doc-param` noch `duplicate-doc-param` im
Bericht.

**Zwei Minuten Pruefung, drei Ursachen ausgeschlossen.** Genau dafuer steht
die Reihenfolge da.

---

#### A1 zum vierten Mal: der Debounce-Timer der Live-Referenzen

```lua
local timer = uv.new_timer()   -- uv_timer_t|nil
st.timer = timer
timer:start(delay, 0, function() ... end)
```

`core/refs.lua` haelt die Referenzen einer Datei beim Tippen nach und
entprellt den Abgleich. Die Frage ist nach A1 nie, wie der Befund weggeht,
sondern **was die Funktion ohne Timer tun soll** -- und hier war die
naheliegende Antwort wieder die falsche: ein `return` haette die Live-Ansicht
fuer den Rest der Sitzung stillgelegt, ohne das je zu sagen. Sie gleicht jetzt
**einmal sofort** ab, scheduled, so wie es der entprellte Pfad auch tut.

Verteilung damit: mdview 10, language 8, github_stats 3, markdown 1.

---

#### Die Nutzlast dieses Plugins auf dem Typ eines fremden

Das einzige `undefined-field` in `lua/`:

```lua
args[i] = { name = "a" .. i, type = "MARKDOWN_SUBARG", optional = true, subcmd = name }
...
complete = function(arg_lead, spec, cmd_line)
  if not line or line == "" then line = "Markdown " .. spec.subcmd .. " " .. arg_lead end
```

markdown.nvim haengt beim Registrieren ein eigenes Feld an jeden
Argument-Slot und liest es im `complete`-Callback des Typs wieder aus -- um
eine Kommandozeile zu synthetisieren, wenn es keine zu lesen gibt (ein
direkter Aufruf im Test). Composers `Lib.UserCmd.Composer.ArgSpec` kennt
`subcmd` nicht, und das ist richtig so: es ist die Nutzlast des Konsumenten,
nicht Teil der Bibliothek.

**Das ist A4 Fall 2 in einer Variante, die eigens genannt gehoert:** der Typ
fehlt nicht, weil jemand ihn vergessen hat, sondern weil der Traeger einem
anderen Repo gehoert. Der Griff ist die abgeleitete Klasse im eigenen Repo:

```lua
---@class Mkdn.SubargSpec : Lib.UserCmd.Composer.ArgSpec
---@field subcmd string
```

und ein `---@cast spec Mkdn.SubargSpec` an der Lesestelle. Damit steht die
Erweiterung dort, wo sie hingehoert, und lib.nvim muss nichts von ihr wissen.

---

#### Ein `---@cast` zwischen zwei Klassen wird selbst gemeldet

Der interessanteste Fund, und er kam erst im **Nachher**-Lauf.

`hl_options/hl_groups/link.lua` liest eine Highlight-Gruppe, streicht die
Unterstreichung und schreibt sie zurueck:

```lua
local base = vim.api.nvim_get_hl(0, { name = base_name, link = false })
base.underline = want_underline
base.undercurl = false
vim.api.nvim_set_hl(0, group, base)
```

Zwei Befunde: `nvim_get_hl` antwortet mit `vim.api.keyset.get_hl_info`,
`nvim_set_hl` nimmt `vim.api.keyset.highlight`. Es ist dieselbe Tabelle, von
der Lese- und von der Schreibseite gesehen -- die Leseseite markiert jedes
Attribut als `true?`, weil sie nur die **gesetzten** meldet; die Schreibseite
nimmt `boolean?`, weil sie sie auch loeschen kann. Der Round-Trip
get -> set ist Neovims dokumentiertes Idiom.

Der naheliegende Griff war ein `---@cast base vim.api.keyset.highlight`.
**Der Cast wurde selbst gemeldet:**

```
cast-type-mismatch: Cannot convert `vim.api.keyset.get_hl_info`
                    to `vim.api.keyset.highlight`
```

Das ist F1 von der anderen Seite: LuaLS entscheidet Zuweisbarkeit ueber den
**Namen**, und weil die zwei Klassen nicht verwandt sind, verweigert es auch
die Behauptung. **Ein `---@cast` ist kein Universalschluessel** -- er
funktioniert entlang einer Vererbungslinie (`-nil`, Ober- nach Untertyp), nicht
quer ueber zwei unabhaengige Klassen.

Der Griff ist, die Schreibtabelle zu **bauen statt zu mutieren**:

```lua
local hl = vim.tbl_extend("force", {}, base, {
  underline = want_underline,
  undercurl = false,
})
vim.api.nvim_set_hl(0, group, hl)
```

`vim.tbl_extend` gibt `table` zurueck, und ein `table` erfuellt jede Klasse.
Das ist keine Umgehung, sondern die ehrlichere Fassung: sie sagt, welche der
beiden Seiten hier gemeint ist, behaelt jedes Attribut, das das Colorscheme
gesetzt hat, und braucht keine Feldliste, die veralten kann.

---

#### Der Rest, nach Familien

- **`pcall(vim.cmd, ...)` sechsmal** (D3) -- drei in `lua/`
  (`commands/mdtable.lua`), drei in `TESTS/`. Cluster E steht damit auf fuenf.
- **Ein Bereich, den Neovim gefuellt hat**: `ctx.line1`/`ctx.line2` sind
  optional typisiert, weil ein Aufruf ohne `-range` beide nicht traegt. Im
  Range-Zweig sind sie da -- `assert` statt eines erfundenen Rueckfalls.
- **`vim.fn.getreg("+")`** ist `string|string[]`, aber die Listenform braucht
  das dritte Argument. Ein `---@cast reg string` mit genau diesem Satz daneben.
- **In `TESTS/`**: sechs Doubles ueber `vim.ui.open`/`.select` (unterdrueckt,
  mit Begruendung -- E), vier `---@cast` dort, wo der Fall selbst schon
  `ok(x ~= nil, ...)` sagt, zwei `assert` dort, wo nichts prueft, und ein
  fehlender zweiter `@return` an einem Helfer, der zwei Werte liefert.

---

### diff.nvim -- 31 auf 0, ein Typname, den es nicht gibt, und `vim.diff`

*(war: Diagnostics-Report Abschnitt 0, "diff.nvim")*

**31 -> 0**, in zwei Laeufen bestaetigt. `stylua --check` sauber, alle Specs
gruen (`DIFF_NVIM_TESTS_OK`). `worse: nothing`.

---

#### Sieben Befunde an einem Namen

`bindings/keymaps.lua` annotiert `register_shortcuts` mit `---@param cfg
Diff.Config`. Der Typ heisst `DiffNvim.Config`. Ein Buchstabendreher an einer
einzigen Zeile, und der Report zeigt:

- 1 `undefined-doc-name` (`Diff.Config`),
- 3 `undefined-field` auf `keymaps`, `commands` und `features` -- Felder, die
  es sehr wohl gibt, nur eben auf dem Typ, der hier nicht steht,
- 1 `param-type-mismatch` beim Aufrufer in `bindings/init.lua`, der korrekt
  `DiffNvim.Config` uebergibt.

Dazu zwei `duplicate-doc-param`: unmittelbar darueber klebte der **aeltere
Doc-Block derselben Funktion**, beim Umschreiben stehen geblieben. Sein
`---@return nil` war ausserdem falsch -- `register_shortcuts` gibt die
Registrierungen zurueck.

**Das ist die dritte Variante des `undefined-field`-Musters** (siehe A4): nicht
der Zugriff ist falsch und nicht der Typ fehlt, sondern der Typ heisst anders.
Alle drei sehen im Report identisch aus.

---

#### `vim.diff` ist deprecated, und `:checkhealth` log darueber

`vim.diff` ist zugunsten von `vim.text.diff` (0.11+) veraltet, und es ist die
zentrale Funktion dieses Plugins -- drei Aufrufstellen in `render.lua`. Das
README nennt **Neovim 0.9+**, wo nur der alte Name existiert.

Statt dreimal zu unterdruecken loest `render.lua` die Funktion jetzt **einmal**
auf, und die Begruendung sitzt an der Auflösung statt an den Aufrufen:

```lua
---@diagnostic disable-next-line: deprecated
local diff_fn = (vim.text and vim.text.diff) or vim.diff
```

Der interessantere Teil steckte in `health.lua`. Es fragte:

```lua
if type(vim.diff) == "function" then
  vim.health.ok("vim.diff is available")
else
  vim.health.error("vim.diff is missing — ... will fail")
end
```

Auf einem Neovim, das den Nachfolger laengst hat und den alten Namen
irgendwann fallen laesst, haette `:checkhealth` **"vim.diff is missing"**
gemeldet, waehrend das Plugin einwandfrei funktioniert -- oder umgekehrt ein
`ok` fuer einen Namen, den das Plugin gar nicht mehr benutzt. Der Check fragt
jetzt nach demselben Paar wie der Code und sagt auch, welchen der beiden Namen
er gefunden hat.

**Merksatz fuer die RULES:** ein `deprecated` an einer Stelle heisst, dass
`health.lua` dieselbe Frage neu beantworten muss. Die beiden gehoeren
zusammen geprueft.

---

#### Eine Gestalt, zweimal ausgeschrieben, in einem Feld verschieden

```lua
-- M.stat:
---@param list_opts? { list: ("off"|"qf"|"loc")?, mode: ..., target: ... }
-- M.push_stat_list:
---@param list_opts  { list: "qf"|"loc",          mode: ..., target: ... }
```

Der Unterschied ist genau das, was der Guard des Aufrufers herstellt
(`list_opts.list == "qf" or ... == "loc"`) -- und eine `or`-Kette von
Gleichheitstests verengt eine String-Union nicht (dasselbe wie in lsp.nvims
`output.apply`). Als `DiffNvim.StatList.Opts` und
`DiffNvim.StatList.Wanted : ...Opts` benannt: die zweite Klasse **ist** die
Aussage, die der Guard trifft.

---

#### Der Rest

- **Elf `duplicate-set-field`** -- Test-Doubles ueber `vim.notify`,
  `vim.fn.executable` und `diff_core.execute`, unterdrueckt mit Begruendung.
- **Vier `render.inline()`-Aufrufe in den Specs** holen ihren Puffer jetzt mit
  einem `assert` ab. Beim ersten Durchgang hatte ich drei davon erwischt und
  `buf_utf` uebersehen -- der zweite Lauf hat es gezeigt, was genau der Grund
  fuer die Regel "zweimal messen" ist.
- **Zwei absichtlich entartete Testeingaben** (`{ key = { "", 42 } }`,
  `parse_args(nil)`), beide mit einem Kommentar, der schon vorher dastand.

---

### cascade.nvim -- 32 auf 0, ein abgeschnittener Doc-Block und fuenf vergessene Werte

*(war: Diagnostics-Report Abschnitt 0, "cascade.nvim")*

**32 -> 0**, in zwei Laeufen bestaetigt. `stylua --check` sauber, alle Specs
gruen (`CASCADE_TESTS_OK`). `worse: nothing`.

Angekuendigt als der **billigste und flachste** Posten -- 14 der 32 sind
`duplicate-set-field`, elf davon in einer Datei. Das stimmte fuer diese 14
(Minutenarbeit, unterdrueckt mit Begruendung). Die anderen 18 waren nicht
flach.

---

#### Ein Doc-Block, den eine neue Variable abgeschnitten hat

```lua
---@param dir integer
---@param number_key string # native key that increments/decrements numbers.
---@param own_key string # the key this action is bound to.
---@return fun()
--- Count for the cycle keys, captured the same way as ...
---@type integer
local pending_cycle_count = 1
```

Die vier Zeilen gehoeren zu `cycle_word_work`, das dreissig Zeilen weiter
unten steht. Jemand hat `pending_cycle_count` **zwischen** den Doc-Block und
seine Funktion gesetzt -- seither beschrieben drei `@param`-Zeilen ein
Integer-Local, und die Funktion stand undokumentiert da.

Das ist die sechste Variante derselben Familie (verirrte Doc-Bloecke, sieben
Repos), und diesmal ist die Ursache besonders klar zu benennen: **nicht der
Block ist gewandert, sondern etwas hat sich dazwischengesetzt.**
`undefined-doc-param` ist die Signatur.

---

#### Fuenfmal: N Rueckgabewerte, ein Guard, eine Cast-Liste

Der ergiebigste Fund, und er hat mich selbst erwischt.

```lua
local s, e, found, idx, shape = resolve(ctx, opts)
if not found then
  return false
end
---@cast e integer
---@cast idx integer      -- und `s`?
```

`resolve` liefert fuenf Werte oder keinen. Der Guard prueft **einen** davon,
und der Autor hat die uebrigen per `---@cast` nachgezogen -- zwei von drei.
Dasselbe an vier weiteren Stellen:

| Stelle | geprueft | gecastet | vergessen |
|---|---|---|---|
| `word_cycle.cycle` | `found` | `e`, `idx` | `s` |
| `word_cycle.cycle_pick` | `found` | `e` | `s` |
| `init.lua` (date) | `s0` | -- | `e0` |
| `init.lua` (token) | `s` | `e` | `text` |
| `util/lib.keep_chars` | `row` | -- | `scol`, `ecol` |

**Eine Cast-Liste anstelle eines Guards hat einen eingebauten Fehlermodus:
sie ist eine Aufzaehlung, und Aufzaehlungen werden unvollstaendig.** Wo der
Guard selbst alle Werte prueft (`if not s0 or not e0 then`), kann nichts
vergessen werden.

Ich bin in denselben Fehler gelaufen: vier Stellen gefunden, die fuenfte
uebersehen, und der erste Nachher-Lauf sah sauber aus. Erst der zweite hat sie
gezeigt -- siehe unten.

---

#### Und ein Fehler in der Messung, der hierher gehoert

Der cascade-Commit `ed1c231` behauptet "in zwei Laeufen bestaetigt", und das
stimmte nicht: der zweite `compare.py`-Aufruf lief gegen eine Scan-Ausgabe,
die noch geschrieben wurde, und meldete deshalb 0. Der Befund kam erst im
naechsten Lauf zum Vorschein und ist mit `2e66c29` nachgereicht.

**Die Lehre ist nicht "zweimal messen"** -- das stand schon in den Regeln --
**sondern: der zweite Lauf muss nachweislich fertig sein.** Ein `compare.py`
gegen ein halb geschriebenes Pass-Verzeichnis meldet still zu wenig. Wer die
Laeufe im Hintergrund faehrt, wartet auf den `pass '<name>' -> ...`-Satz,
nicht auf das Verzeichnis.

---

#### Der Rest

- **Drei `missing-return`** aus einer Signatur, die mehr verspricht als
  gebraucht wird: `keep_lines` ist generisch ueber den Rueckgabewert seines
  Callbacks (`---@param fn fun(...): T`, `---@return T`), und **kein einziger
  Aufrufer nutzt ihn** -- alle drei rufen es fuer die Wirkung. Ein `T?` laesst
  den Callback enden, ohne einen Wert zu schulden.
- **Zwei Optionen, die es gibt und die in keinem Typ standen**:
  `keymaps.globals` und `keymaps.list`, beide in DEFAULTS mit einem
  sechszeiligen Kommentar erklaert, beide in `CascadeKeymapOpts` nicht
  vorhanden. Derselbe Fund wie `dashboard.menu` in github_stats -- **das
  dritte Repo in Folge.**
- **`vim.treesitter.get_parser` kann nil liefern**, und der nil-Fall endete
  bisher als gefangener Fehler im umschliessenden `pcall` statt als sauberes
  `false`.
- **`vim.is_callable(x)` ist kein Type-Guard** -- dieselbe Familie wie die
  boolean-Helfer in github_stats, nur mit einer eingebauten Funktion. Und das
  Ziel war wieder eine `__call`-Tabelle, die `pcall` nicht erfuellt.

---

### replacer.nvim -- 32 auf 0, ein toter Typ, eine tote API und ein Aufruf, der seit 0.11 wirft

*(war: Diagnostics-Report Abschnitt 0, "replacer.nvim")*

**32 -> 0**, in zwei Laeufen bestaetigt. `stylua --check` sauber, alle
Smoke-Suiten gruen (feature 155, surround 26, async_utf8 7, je 0 failed).
`worse: nothing`.

Der Einstieg war die Vorhersage aus dem Report -- **elf `undefined-field`**,
und die Regel hatte in filetree, in der Sechser-Runde und in github_stats
jedes Mal etwas ergeben. Hier waren es zwei getrennte Funde, und der zweite
kam von woanders.

---

#### Zwoelf Befunde aus einem Typ, den es nicht gibt

`pickers/utils.lua` annotiert zwei Funktionen mit `---@param cfg
RP_HighlightConfig`. **Diese Klasse ist nirgends definiert** -- und weil der
Typ unbekannt ist, ist jeder Feldzugriff darauf undefiniert: `enabled`,
`old_bg`, `old_fg`, `underline`, `strikethrough`, `new_fg`, `ansi_old_bg`,
`ansi_new_fg`. Zwei `undefined-doc-name` plus zehn `undefined-field`, **zwoelf
der 32 Befunde aus einer fehlenden Klasse.**

Dasselbe Muster wie `Lib.Keymap.Action` in language, nur mit anderer Ursache:
dort war der Typ da und die Library-Injektion weg, hier ist die Injektion in
Ordnung und der Typ existiert schlicht nicht.

Die Klasse ist jetzt in `types/pickers.lua` definiert, mit den Feldern, die
die beiden Leser tatsaechlich lesen, und jedes als optional -- beide haben
Fallbacks (`ansi_snippets` auf `"41"`/`"32"`, das Gruppen-Setup auf `false`).

---

#### Und die beiden Funktionen ruft niemand

Beim Aufschreiben der Felder fiel das hier auf. Der Doc-Kommentar sagt:

```lua
--- This acts as small API that telescope's ensure_highlight_groups will call.
```

Es gibt kein `ensure_highlight_groups` im Repo. `setup_highlight_groups` und
`ansi_snippets` haben **keinen einzigen Aufrufer**, und die Highlight-Gruppen,
die sie definieren (`ReplacerOld`, `ReplacerNew`,
`ReplacerOldStrikethrough`), werden nirgends sonst referenziert. Die
Telescope-Anbindung, fuer die das geschrieben wurde, ist nie entstanden.

**Nicht geloescht**, sondern als Notiz an die Funktion geschrieben: ob das
Preview hervorgehoben werden soll, ist eine Produktentscheidung und kein
Diagnose-Befund. Der Fund gehoert dem Repo-Besitzer, nicht diesem Durchgang.

Das ist die Umkehrung der A4-Familie: nicht ein Aufruf, der nie funktionieren
konnte, sondern eine Funktion, die nie gerufen wurde. **Beide sehen im Report
gleich aus** -- `undefined-field` in `lua/`.

---

#### `vim.str_utfindex` hat in 0.11 die Signatur getauscht, und `:ReplaceDebug` merkt es

`debug.lua`s `analyze_line` -- erreichbar ueber `:ReplaceDebug`, das
`replacer.debug.register_command()` registriert -- rechnet Byte- in
Zeichenpositionen um:

```lua
vim.str_utfindex(line, s - 1) or -1,
vim.str_utfindex(line, e) or -1,
```

Bis Neovim 0.10 war das zweite Argument der Byte-Index. **Seit 0.11 ist es die
Kodierung**, und Neovim ruft es selbst so:

```lua
col = vim.str_utfindex(line, position_encoding, col, false)
```

Auf jedem aktuellen Build wird `s - 1` also als Kodierung gelesen, und der
Aufruf wirft. Der Pruefer meldete das als zwei `param-type-mismatch`
(`Cannot assign 'integer' to parameter '"utf-16"|"utf-32"|"utf-8"'`) -- die
Sorte Befund, die nach Annotationspflege aussieht und keine ist.

Das README nennt **Neovim 0.9+**, also reicht es nicht, auf die neue Form
umzustellen. Ein `char_index`-Helfer probiert jetzt erst die aktuelle Form und
faellt auf die alte zurueck; das `or -1` des Originals ist als Rueckgabewert
erhalten.

**Fuer die RULES-Ableitung:** das ist derselbe Mechanismus wie
`vim.diagnostic.jump` vs `goto_next` und `vim.lsp.get_log_path`, nur ohne
`deprecated`-Markierung. Eine geaenderte Signatur meldet sich als
`param-type-mismatch` an einer Stelle, die jahrelang funktioniert hat -- und
in einem Repo mit breiter Versionsspanne ist die Antwort eine Probe, keine
Migration.

---

#### Ein Feld, das drei Geschwister hat und selbst fehlte

`init.lua` setzt vier interne Felder auf die aufgeloeste Config:

```lua
cfg._line_range = request.line_range
cfg._old_len = ...
cfg._changed_only = ...
cfg._also_rename_file = ...
```

`RP_Config` deklariert **drei** davon. `_line_range` fehlte -- ein
`inject-field` beim Schreiben in `init.lua`, ein `undefined-field` beim Lesen
in `rg.lua`. Zwei Befunde, ein vergessenes Feld beim Nachruesten.

Das laesst sich als Regel schreiben: **wo eine Klasse interne `_`-Felder
fuehrt, sind es entweder alle oder keins.** Drei von vier ist die Signatur
eines Nachtrags, der einmal vergessen wurde.

---

#### Der Rest -- sieben kleine Ursachen

- **Das `value, err`-Idiom**, viermal (`batch` 2, `root`, `surround`):
  `local x, err = f()` mit `---@return T|nil, string|nil`, dann
  `if not x then notify.error(err)`. Der Aufrufer weiss, dass `err` gesetzt
  ist, der Pruefer nicht. Die Fassung mit `err or "<konkreter Text>"` behebt
  nicht nur den Befund -- sie meldet auch dann etwas, wenn der Fehlerpfad
  wirklich einmal ohne Nachricht erreicht wird.
- **`string.find` gibt beide Bounds oder keine**, aber der Guard prueft nur
  `s`. Derselbe Kopf wie die Mehrfachrueckgabe in language (C3): nur der
  erste Wert wird verengt.
- **`pcall` auf eine `__call`-Tabelle** -- diesmal
  `lib.nvim.bindings.keymap`, nach `vim.cmd` und `vim.lsp.config` die dritte.
  Die Meldung ist immer dieselbe:
  `Cannot assign 'table' to parameter 'fun(...any):...unknown'`.
- **Eine `or`-Kette von Gleichheitstests verengt keine String-Union**
  (`pick_picker`), wie schon in lsp.nvims `output.apply`. Ein `---@cast` auf
  das, was der Zweig gerade bewiesen hat.
- **`#(src or {})` bewacht die Schleifengrenze, nicht die Lesezugriffe
  darin.** Der Fallback gehoert in ein Local, dann gilt er fuer beides.
- **Zwei optionale Config-Felder ohne Endpunkt der Fallback-Kette**
  (`default_scope`, `Defaults.keymaps`) -- dasselbe wie in github_stats'
  `Dashboard.Resolved`. Wo die Kette bei DEFAULTS endet, muss DEFAULTS' Typ
  sie schliessen, sonst braucht sie ein letztes `or`.
- **Ein Testaufruf mit einem Argument zu viel**: `check(name, cond, extra)`
  bekam vier. Das vierte fiel still weg, also zeigte eine fehlgeschlagene
  Zaehler-Zusicherung nur den einen Wert und nie den, gegen den verglichen
  wird. Beide stehen jetzt in einem `extra`.

---

### github_stats.nvim -- 31 auf 0, und ein Test-Runner, den die anderen kopieren sollten

*(war: Diagnostics-Report Abschnitt 0, "github_stats.nvim")*

**31 -> 0**, in zwei Laeufen bestaetigt. `stylua --check` sauber, alle 9 Specs
gruen (108 Faelle). `worse: nothing`.

Der Report fuehrte 33; gemessen waren es **31**. Die Differenz sind die beiden
Commits, die seit dem Gesamtlauf hier gelandet sind (`b4ace17` hat
`workspace.library` aus der `.luarc.json` genommen, `66487dc` die
`need-check-nil` pro Testdatei unterdrueckt). Das Repo hatte Cluster L also
**schon selbst erledigt** -- als einziges der bisher durchgegangenen.

---

#### Zwei Boolean-Helfer, die keine Type-Guards sind

Zehn der 31 waren `need-check-nil`, und neun davon gehen auf zwei Funktionen
derselben Bauart zurueck:

```lua
---@param state GHStats.DashboardState?
---@return boolean
local function has_selection(state)
  return state ~= nil and state.current_index >= 1 and state.current_index <= #state.repos
end
```

Der Aufrufer schreibt dann das Naheliegende:

```lua
local s = dashboard_state.get_state()
if has_selection(s) then
  show_detail(s.repos[s.current_index])   -- s ist hier immer noch `State?`
end
```

**Eine Funktion, die `boolean` zurueckgibt, verengt nichts.** Der Beweis, den
sie fuehrt, bleibt in ihr; der Aufrufer indiziert weiter einen optionalen Wert.
Das ist kein Prueferartefakt: faellt die Vorbedingung eines Tages weg, wirft
genau diese Zeile.

`has_selection` ist deshalb `selected_repo` geworden -- es gibt zurueck, was
die Aufrufer eigentlich wollten:

```lua
---@return string|nil
local function selected_repo(state)
  if state == nil or state.current_index < 1 or state.current_index > #state.repos then
    return nil
  end
  return state.repos[state.current_index]
end
```

Vier Befunde weg, und die Aufrufstellen wurden kuerzer statt laenger. Der
zweite Fall (`has_days` in `dashboard/render.lua`) wird an drei Stellen und in
zwei verschiedenen Bedeutungen gebraucht, deshalb dort der kleinere Griff:
`if stats_clones and has_days(stats_clones) then` -- die Bedingung sagt jetzt,
was sie prueft.

**Fuer die RULES-Ableitung:** ein `---@return boolean`-Helfer ueber einem
optionalen Argument ist ein wiederkehrendes Muster mit einem eingebauten
Folgefehler. Wo die Aufrufer nach dem `if` auf das Argument zugreifen, gehoert
der Wert zurueckgegeben, nicht die Antwort.

---

#### `vim.uv.new_timer()` -- das dritte Repo in Folge

Drei weitere ungeprueft benutzte Timer, nach mdview (zehn Befunde) und
language (acht):

| Datei | ohne Timer |
|---|---|
| `background.lua` | der wiederkehrende Fetch-Zyklus startet nicht -- der einmalige `defer_fn` davor ist schon gelaufen |
| `dashboard/init.lua` (Debounce) | kein Debounce, also **sofort** rendern statt das Bild fallenzulassen |
| `dashboard/init.lua` (Auto-Refresh) | kein Auto-Refresh; die Refresh-Tasten funktionieren weiter |

Die dritte Spalte ist der eigentliche Punkt. `new_timer()` liefert
`uv_timer_t|nil`, und die Frage ist nie "wie mache ich den Prueferbefund weg",
sondern **was die Funktion ohne Timer tun soll**. Dreimal drei verschiedene
Antworten, und beim Debounce ist die richtige nicht "zurueckkehren", sondern
"jetzt rendern".

**Das ist inzwischen der haeufigste echte Befund der ganzen Reihe** -- 21
Stellen in drei Repos, immer dieselbe Ursache.

---

#### Eine Option, die es gibt, aber in keinem Typ steht

`integrations/menu.lua:31` las `cfg.dashboard.menu` und bekam einen
`undefined-field`. Die Option existiert: `DEFAULTS` setzt
`dashboard.menu = { enable = true }`, mit einem drei Zeilen langen Kommentar
darueber, was sie tut. Nur deklariert hat sie nie jemand --
`GHStats.DashboardConfig` kennt zehn Felder und dieses nicht.

Kein Laufzeitfehler, aber die Option war fuer jeden unsichtbar, der die Typen
liest statt die Defaults. Jetzt als `GHStats.DashboardMenuConfig` deklariert,
mit dem Kommentar, der schon in DEFAULTS stand.

---

#### Eine Klasse, die genau dafuer da war und zurueckgefallen ist

Nachdem die `menu`-Luecke zu war, tauchten in `dashboard/state.lua` zwei
Befunde auf, die vorher nicht sichtbar waren:

```lua
sort_by = dashboard_cfg.sort_by or DEFAULTS.dashboard.sort_by,
time_range = dashboard_cfg.time_range or DEFAULTS.dashboard.time_range,
```

`DEFAULTS.dashboard` ist als `GHStats.Dashboard.Resolved` typisiert, und diese
Klasse existiert genau fuer diesen Fall -- ihr eigener Doc-Kommentar sagt:
*"die zwei Felder, die das Dashboard ohne Fallback liest, sind nach dem Merge
garantiert"*. Sie fuehrte `enabled` und `refresh_interval_seconds`.

Inzwischen sind es vier. Eine `or`-Kette, die bei DEFAULTS endet, ist nur so
gut wie DEFAULTS' Deklaration: steht dort `sort_by?`, ist die Kette offen --
und `GHStats.DashboardState` verlangt beide Felder non-optional. Die Klasse ist
um die zwei nachgezogen worden, samt einem Satz, der sagt, wann ein Feld
hierhergehoert.

---

#### Der Rest

- **`os.date("!*t", ts)`** liefert eine Tabelle, aber LuaLS' `osdate` beschreibt
  auch die String-Form desselben Aufrufs und weitet seine Felder deshalb auf
  `integer|string`. Ein `---@cast` auf `osdate` reicht darum **nicht** --
  `math.min(parts.day, ...)` beanstandet danach immer noch den String-Ast. Der
  Cast muss die drei Zahlen benennen, die dieser Aufruf wirklich liefert.
- **Acht `get_buf()` in `dashboard_render_spec`** trugen neun Befunde: der
  Handle ist `integer?`, und jeder Fall liest direkt danach Zeilen daraus.
  Jeder holt ihn sich jetzt mit einem `assert` ab, das beim Bruch die
  Vorbedingung benennt (`dashboard.open() must have created a buffer`) statt
  zwei Zeilen spaeter mit "index a nil value" zu scheitern -- derselbe Griff
  wie in open.nvims `usrcmds_spec`.
- **`PATHS` in `config/init.lua`** wird mit drei `nil` initialisiert und erst
  in `setup()` gefuellt; drei Leser mussten deshalb `string|nil` weiterreichen.
  Die Gestalt ist jetzt deklariert, und `ensure_config_exists` sagt seine
  Vorbedingung mit einem `assert`, statt sie anzunehmen.
- **Fuenf `duplicate-set-field`** sind Test-Doubles ueber `config.get`,
  `config.get_repos` und `analytics.query_metric` -- unterdrueckt mit
  Begruendung, wie in images entschieden. Dazu ein Helfer, der absichtlich
  auch Strings als Intervall annimmt, weil die Faelle darunter genau das
  pruefen.

---

#### Der Test-Runner: der erste, der es richtig macht

Nach zwei Repos mit kaputten Runnern -- neotree-fs-refactor meldet Erfolg ohne
geladenen Harness, lsp.nvim wartet stumm ohne `PLENARY_PATH` -- ist
`scripts/test.sh` hier die Gegenprobe. Ohne plenary:

```
scripts/minimal_init.lua: plenary.nvim not found.
  Set PLENARY_DIR, or clone it to .deps/plenary.nvim, or place it beside this repo.
```

**Exit-Code 1.** Das ist der Unterschied, um den es in Offen-Punkt 13 geht: die
Meldung sagt, was fehlt *und* wie man es behebt, und der Lauf scheitert, statt
gruen zu melden oder zu haengen. Dazu sucht `minimal_init.lua` selbst an drei
Orten (`$PLENARY_DIR`, `.deps/`, daneben), statt sich auf eine Env-Variable zu
verlassen, die nur CI setzt.

**Diese Datei ist die Vorlage fuer die RULES-Ableitung**, nicht irgendeine
allgemeine Formulierung: drei Fundorte mit Fallback, eine Fehlermeldung, die
alle drei nennt, und ein Exit-Code, der nicht luegt.

---

### lsp.nvim -- 35 auf 0, und drei Waechter, die nie etwas ausgeschlossen haben

*(war: Diagnostics-Report Abschnitt 0, "lsp.nvim vertikal" -- der Rest des
dritten Durchgangs V3, 172 -> 35)*

**35 -> 0**, in zwei Laeufen bestaetigt. `stylua --check` sauber.
`worse: nothing`.

Der Posten war als der flachste der verbliebenen angekuendigt -- 35 Befunde,
groesste Regel `param-type-mismatch` 12, danach nur Siebener und kleiner, keine
Haeufung, die sich auf eine Zeile zurueckfuehren liesse. Das hat gestimmt und
war trotzdem der ergiebigste Durchgang seit filetree: **drei der Befunde waren
Bedingungen, die nie etwas ausgeschlossen haben**, und alle drei in Code, der
taeglich laeuft.

---

#### `supports_method("textDocumentSync/openClose")` -- die Wache, die immer Ja sagt

`lsp.core.workspace_diagnostics` ist das Modul, das `<leader>wq` ueberhaupt
erst etwas zu zeigen gibt: es schickt `textDocument/didOpen` fuer jede Datei
des Workspace, damit der Server auch das diagnostiziert, was gerade in keinem
Puffer offen ist. Davor stand:

```lua
if not client:supports_method("textDocumentSync/openClose") then
  return
end
```

`textDocumentSync/openClose` ist **keine LSP-Methode**. Es ist ein
Capability-Pfad -- `server_capabilities.textDocumentSync.openClose`. Der
Prueferbefund war ein `param-type-mismatch` gegen die Union der 77 echten
Methodennamen, und das klingt nach Annotationspflege.

Der Blick in Neovims `Client:supports_method` sagt, was der Aufruf wirklich
tut. Die letzte Zeile der Funktion:

```lua
-- if we don't know about the method, assume that the client supports it.
-- This needs to be at the end, so that dynamic_capabilities are checked first
return required_capability == nil
```

Fuer einen erfundenen Namen ist `required_capability` nil, also ist die Antwort
**`true`**. Die Wache hat nie einen Server ausgeschlossen -- auch keinen, der
`openClose` gar nicht anbietet. Sie sah aus wie eine Pruefung und war eine
Zusicherung.

Der Fix ist exakt, weil Neovim die Zuordnung selbst fuehrt:

```lua
['textDocument/didOpen'] = { 'textDocumentSync', 'openClose' },
```

`client:supports_method("textDocument/didOpen")` prueft also genau die
Capability, die die alte Zeile prueft*en wollte* -- und ist zugleich die
Notification, die die Funktion tatsaechlich sendet.

**Die Lehre ist nicht "Tippfehler".** Ein `supports_method` mit einem Namen,
den Neovim nicht kennt, ist stumm wahr. Wer eine Capability meint, muss den
Methodennamen nehmen, den Neovim darauf abbildet -- oder die Capability direkt
lesen.

---

#### `win_id`, wo Neovim `winnr` liest

`lsp.diagnostics.loclist.to_loc` baut seine Optionen so:

```lua
local locopts = {
  open = (opts.open ~= false),
  win_id = opts.win_id or 0,
  bufnr = opts.bufnr,
  ...
```

Neovims `vim.diagnostic.setloclist` liest `opts.winnr`. `win_id` faellt still
durch. Und `bufnr` ebenso, aus einem anderen Grund -- fuer eine Location-Liste
leitet `set_list` den Puffer aus dem Fenster ab:

```lua
local winnr = opts.winnr or 0
local bufnr
if loclist then
  bufnr = api.nvim_win_get_buf(winnr)
end
```

Sichtbar war davon bisher nichts, weil die einzige Aufrufstelle
`win_id = 0` uebergibt und Neovims Vorgabe ebenfalls 0 ist. Die dokumentierte
Option war trotzdem tot: ein Aufrufer mit einer anderen Fenster-ID haette sie
stillschweigend verloren.

Dazu kommt der Kompatibilitaetspfad darueber, der auf 0.10 zeigt, waehrend das
README **Neovim 0.11+** verlangt. Er ist nicht angefasst worden -- er ist
tot, aber sein Entfernen ist eine Verhaltensentscheidung und kein
Diagnose-Befund.

---

#### `publishDiagnosticsProvider` -- eine Capability, die es nicht gibt

`:LspDoctor` warnt, wenn mehrere Server dieselbe Aufgabe beanspruchen:

```lua
if caps.diagnosticProvider or caps.publishDiagnosticsProvider then
```

`publishDiagnosticsProvider` kommt in Neovims gesamtem Protokoll-Meta **null
Mal** vor. Es gibt sie im LSP nicht: Push-Diagnostics
(`textDocument/publishDiagnostics`) haben ueberhaupt keine Capability, ein
Server sendet sie einfach. Der zweite Zweig war immer `nil`.

Der Fund ist unangenehmer als die anderen beiden, weil er sich nicht
"reparieren" laesst -- der `or` ist raus, aber die Erkennung sieht weiterhin
nur Pull-Diagnostics. Das steht jetzt als Kommentar an der Zeile, damit der
naechste Leser nicht dasselbe Feld noch einmal erfindet.

Sichtbar wurde er ueberhaupt erst durch den Punkt unten: solange
`LspMod.Client.Capabilities` danebenlag, war `publishDiagnosticsProvider` ein
deklariertes Feld -- der Report hat die Erfindung mitgetragen.

---

#### Offen-Punkt 6, beantwortet: `LspMod.*` beschreibt nichts, was Neovim nicht fuehrt

Die offene Frage war, "ob `LspMod.*` noch etwas beschreibt, das Neovim nicht
fuehrt". Feld fuer Feld nachgesehen, lautet die Antwort **nein**:

| `LspMod.*` | Neovim | |
|---|---|---|
| `LspMod.Client` | `vim.lsp.Client` | jedes der neun Felder, dazu `request`/`supports_method` als Methoden |
| `LspMod.Client.Capabilities` | `lsp.ServerCapabilities` | die vollstaendige Menge statt der elf, die wir zufaellig benutzen |
| `LspMod.TextDocumentIdentifier` | `lsp.TextDocumentIdentifier` | identisch |
| `LspMod.Position` / `LspMod.Range` | `lsp.Position` / `lsp.Range` | identisch |
| `LspMod.CodeAction.Params` | `lsp.CodeActionParams` | identisch |

Neovims Fassungen sind dabei praeziser, nicht nur gleichwertig:
`offset_encoding` ist dort `'utf-8'|'utf-16'|'utf-32'` statt `string|nil`,
`workspace_folders` ist `lsp.WorkspaceFolder[]` statt einer Inline-Tabelle.

Und die Kosten des Parallelnamens sind keine Geschmacksfrage. **LuaLS
entscheidet Klassenzuweisbarkeit ueber den Namen, nicht ueber die Gestalt** --
dieselbe Lehre wie bei `Images.Scale.Dims`. Ein `LspMod.Client` kann deshalb
niemals aus einem `vim.lsp.Client` zugewiesen werden, so deckungsgleich die
Felder auch sind. Genau daran ist `languages/webdev/typescript.lua` dreimal
haengengeblieben.

Nebenbefund beim Aufraeumen: `integrations/inc_rename/setup.lua` fuehrte eine
Klasse namens `LspVersionedLspMod.TextDocumentIdentifier` -- die Narbe eines
Suchen-und-Ersetzens, das `TextDocumentIdentifier` durch
`LspMod.TextDocumentIdentifier` getauscht und dabei das `LspVersioned`-Praefix
stehen gelassen hat. Neovim hat den Typ als
`lsp.VersionedTextDocumentIdentifier`.

---

#### Offen-Punkt 5, nachgemessen: der Zustand existiert nicht mehr

Der Punkt sagt, `luassert`s Assertionen in lib.nvim seien aufzuweiten, weil
lsp.nvim zusaetzlich `are.equal` (237-mal), `are.same` (97) und `is_string`
benutzt. Nachgezaehlt stimmen die Zahlen aufs Wort -- 237 und 97, davon 102
Aufrufe **mit** Failure-Message, also genau die Form, die laut der
Typdatei `redundant-parameter` ausloest.

Sie loest keinen aus. Im gemessenen Lauf steht `redundant-parameter` auf
**eins**, und das ist `health.lua`. Der Zustand, den der Punkt beschreibt, ist
seit der Injektions-Korrektur (`${3rd}/luassert` in der Library, Erledigt-Punkt
M) nicht mehr da. **Der Punkt ist gegenstandslos, nicht offen** -- und die
Aufweitung haette die Zahlen keines Repos veraendert.

---

#### `vim.health.info` -- das sechste Repo in Folge

```lua
health.info(("project override: %s"):format(layers.project), {
  "Merged over your setup() options. Allowed keys: servers, diagnostics, ...",
})
```

`vim.health.info` nimmt ein Argument. Die Liste der erlaubten Keys eines
Projekt-Overrides -- die einzige Stelle, an der sie dem Benutzer je gezeigt
wurde -- hat kein `:checkhealth` je ausgegeben.

Damit ist es das **sechste** Repo mit demselben Fund, nach documentation,
runtime-analysis, images und zweien aus der Sechser-Runde. Die Einstiegsregel
im Report ist entsprechend zu lesen: `redundant-parameter` in einer
`health.lua` ist nie Stil.

---

#### Der Rest -- neun kleine Ursachen

- **Zwei `pcall` auf eine `__call`-Tabelle.** `vim.lsp.config` ist dieselbe
  Gestalt wie `vim.cmd`: eine Tabelle mit Metamethode, die `pcall`s
  `fun(...any):...unknown` nicht erfuellt. Closure-Form, wie in Cluster E.
- **`---@type table` auf einem Local verschiebt den Befund nur.** Zwei Stellen
  in `config/init.lua` trugen genau diesen Reparaturversuch samt Kommentar:
  die Deklaration ist nicht das Problem, die *Zuweisung* der Union ist es. Ein
  `---@cast` auf den Wert behauptet, was gilt, statt es zu deklarieren.
- **`make_range_params` liefert keine CodeActionParams.** `lightbulb` liess
  sich eine Range-Anfrage bauen und haengte `context` daran -- ein Feld, das
  die Gestalt nicht hat. Jetzt als `lsp.CodeActionParams` zusammengesetzt.
- **Ein `deprecated` war echt.** `vim.lsp.get_log_path()` ist bei 0.11+
  ersetzbar durch `vim.lsp.log.get_filename()`, auf das es ohnehin
  weiterleitet. Die beiden anderen sind which-key v2s `register`, erreichbar
  nur, wenn v3s `add` fehlt -- also Absicht, unterdrueckt mit Begruendung.
- **Ein bewusster Griff in fremde private Felder** (`trouble`s Patch von
  `vim.treesitter.highlighter._on_win`/`_on_line`) trug drei Befunde, die alle
  dasselbe Wahre sagen. Ein `---@cast` auf ein untypisiertes Handle sagt die
  Absicht einmal, statt sie dreimal zu unterdruecken.
- **Zwei Narrowing-Verluste**: eine Bedingung, deren Beweis in einer Variablen
  steckt, die der Pruefer nicht in den Zweig traegt; und ein Feld, das nach
  seinem eigenen `type()`-Test noch zweimal frisch gelesen wird.
- **`(string|{name: string})[]` in einem `fun()`-Rueckgabetyp** wird als
  Union `string | {name:string}[]` gelesen, und diese Gestalt erfuellt
  `pcall`s Parameter nicht. Ein benannter Alias macht das Array eindeutig --
  derselbe Griff wie `Language.Translate.Span` in language.nvim.
- **Ein `CodeActionKind`, den Neovims Meta nicht kennt** (`source.organizeImports.astro`).
  Das Protokoll definiert CodeActionKind als offenes String-Enum; der Befund
  ist sachlich falsch, unterdrueckt mit Begruendung.
- **Die Tests**: drei Handler-Fakes waren ein Feld zu kurz (`lsp.HandlerContext`
  verlangt `method`) -- ergaenzt statt unterdrueckt, der Fake ist damit naeher
  an dem, was der Wrapper in Produktion bekommt. Zwei Faelle uebergeben
  absichtlich `nil` und heissen auch so ("returns nothing without a shared
  table"). Ein `stub(name, nil)` ist die dokumentierte Art, ein fehlendes
  Modul zu simulieren -- die Signatur sagt das jetzt.

---

#### Nachtrag: der Runner haengt nicht "unter Windows", er haengt ohne zwei Env-Variablen

Der CI-Befehl des Repos hat headless **kein einziges Byte** ausgegeben und
musste nach sieben Minuten abgebrochen werden -- scheinbar dieselbe Falle wie
in Offen-Punkt 13 und in sandbox (Offen-Punkt 1c). Diesmal ist die Ursache
gefunden, und sie ist konkreter als "haengt unter Windows".

`TESTS/minimal_init.lua` loest plenary und lib.nvim ueber Umgebungsvariablen
auf, statt Pfade fest zu verdrahten:

```lua
prepend_env("PLENARY_PATH")
prepend_env("LIB_NVIM_PATH")
vim.cmd("runtime plugin/plenary.vim")
```

Sind die nicht gesetzt -- und lokal ist das der Normalfall, die Workflow-Datei
setzt sie --, liegt plenary nicht auf dem `runtimepath`, `runtime
plugin/plenary.vim` laedt nichts, und `PlenaryBustedFile` existiert als
Kommando nicht. **Headless nvim meldet das nicht, es wartet.**

Mit gesetzten Variablen laeuft alles:

```bash
PLENARY_PATH=.../lazy/plenary.nvim LIB_NVIM_PATH=E:/repos/lib.nvim \
  nvim --headless --noplugin -u TESTS/minimal_init.lua \
       -c "PlenaryBustedFile TESTS/lsp/<spec>.lua" </dev/null
```

**23 Specs, 372 Faelle, 0 Fehler, 0 Errors.** Gegengeprueft, dass das Haengen
Bestand ist und nicht aus diesem Durchgang stammt: auf dem unveraenderten
`9b8a6e6` haengt derselbe Aufruf genauso.

Das aendert den Charakter von Offen-Punkt 13. Der gemeinsame Nenner der drei
Repos ist nicht das Betriebssystem, sondern **ein Runner, der fehlende
Voraussetzungen nicht meldet**: in neotree-fs-refactor meldet er faelschlich
Erfolg, hier wartet er stumm. Beides ist dieselbe Luecke an derselben Stelle,
und beide Male sieht das Ergebnis aus wie "die Tests laufen gerade".

---

### language.nvim -- 34 auf 0, und die siebte `.luarc.json`, die ihre Library wegwarf

*(war: Diagnostics-Report Abschnitt 0, "language.nvim vertikal")*

**34 -> 28 -> 0**, in zwei Laeufen bestaetigt. Commit `afe629d`,
`stylua --check` sauber, alle vier Specs gruen. `worse: nothing`.

Der vorgeschlagene Einstieg war "32 der 34 liegen in `lua/`" -- der hoechste
Anteil an ausgeliefertem Code unter den verbliebenen Repos. Das hat gestimmt,
aber der erste Befund lag vor allen anderen und stand nicht auf der Liste.

---

#### Sechs waren gar keine Befunde, sondern die Messung

Die zweite der drei stehenden Einstiegsregeln -- **dann die `.luarc.json`
lesen** -- hat hier den ganzen Durchgang umsortiert. Sie enthielt:

```json
"workspace": {
  "library": ["$VIMRUNTIME/lua", "${3rd}/luv/library"],
  "checkThirdParty": false
}
```

Das ist Cluster L zum **siebten** Mal, nach `buffer-ctx`, `emojis`, `fileops`,
`gopath`, `lib` und `sessions`. Eine `.luarc.json` ersetzt `workspace.library`
komplett statt zu ergaenzen, also kam von der Injektion aus lsp.nvim nichts an:
LuaLS sah hier **kein einziges Plugin**, lib.nvim eingeschlossen. Sichtbar
wurde das an sieben Befunden, die alle dieselbe Ursache hatten --
`Lib.Keymap.Action` und `Lib.Keymap.Registered` galten als undefinierte Typen
(drei `undefined-doc-name`), und die vier Feldzugriffe auf eine so
"undefinierte" Registrierung gleich mit (`bound`, `lhs`, `mode`, `lhs`).

Beide Typen existieren und sind vollstaendig beschrieben, in
`lib.nvim/lua/lib/nvim/bindings/keymap/@types/init.lua`. Es hat sie nur nie
jemand gelesen.

Nach dem Entfernen des Schluessels: **34 -> 28**. Der Rueckgang ist nicht die
ganze Geschichte -- `translate/history.lua` kam als Stelle **dazu**, die vorher
gar nicht geprueft werden konnte. Das ist derselbe Effekt wie bei den sechs
Repos in Cluster L, wo die Summe unterm Strich sogar stieg (356 -> 411): sechs
Befunde fallen weg, weil Typen auflösen, einer kommt an einer Stelle dazu, die
vorher niemand geprueft hat.

---

#### Cluster E, vier Stellen, und warum `vim.cmd` kein `function` ist

Vier `param-type-mismatch` mit demselben Wortlaut --
`Cannot assign 'table' to parameter 'fun(...any):...unknown'` -- waren
`pcall(vim.cmd, ...)`. `vim.cmd` ist eine Tabelle mit `__call`-Metamethode,
kein `function`; `pcall` verlangt eine Funktion, und die Metamethode rettet das
im Typsystem nicht.

Umgestellt auf die Closure-Form, wie es der Report vorgibt:

```lua
pcall(function()
  vim.cmd("silent spellgood! " .. w)
end)
```

**Nicht** auf `vim.cmd.spellgood(...)`: der Report notiert aus dem
images-Durchgang, dass ein Spec dort `vim.cmd` selbst tauscht und den
Kommandonamen aus dem ersten Argument liest -- die Unterkommando-Form haette
den Test still blind gemacht. Hier gegengeprueft: `TESTS/` in language.nvim
fasst `vim.cmd` nicht an, aber die Closure-Form ist die, die in beiden Faellen
richtig bleibt.

Damit ist **Cluster E in language.nvim leer**; offen bleiben elf, davon sechs
in markdown.nvim.

---

#### Acht ungeprueft benutzte Timer -- derselbe Fund wie in mdview

`vim.uv.new_timer()` gibt `uv_timer_t|nil` zurueck. An vier Stellen wurde der
Rueckgabewert direkt indiziert:

| Datei | was ohne Timer passiert waere |
|---|---|
| `spell/live.lua` | `t:stop()` auf `nil` -- der Debounce-Pfad wirft |
| `spell/providers/cspell_server.lua` | `timer:start(...)` wirft, und die Closure haette `timer:stop()` auf `nil` gerufen |
| `util/job/init.lua` (zweimal) | `timer:start(...)` wirft, einmal im `vim.system`-Pfad, einmal im `jobstart`-Fallback |

Der Fall ist selten (Erschoepfung der libuv-Handles), aber der Unterschied ist
der zwischen "kein Timeout" und "Absturz beim Aufsetzen". Behandelt wurde er
jeweils so, dass die Funktion ohne Timer **weiterarbeitet**: der Job laeuft und
meldet, nur ohne Timeout-Wache; der Debounce kehrt zurueck statt zu werfen.

In `util/job` kam dabei die Regel *kein Fix, der eine Warnung nur verschiebt*
zum Tragen. Der erste Versuch --

```lua
if opts.timeout_ms and opts.timeout_ms > 0 then
  timer = vim.uv.new_timer()
end
if timer then
  timer:start(opts.timeout_ms, 0, ...)   -- opts.timeout_ms ist hier wieder `integer|nil`
```

-- haette den Befund von `timer` auf `opts.timeout_ms` verschoben, weil der
zweite `if` ausserhalb der Pruefung des ersten steht. Die Fassung, die bleibt,
zieht die Zahl in ein Local und schachtelt die Timer-Pruefung hinein.

---

#### `region_bounds`: alles oder nichts, in vier Optionals geschrieben

Sechs der 34 lagen auf zwei Zeilen in `translate/motion.lua`, und beide sahen
so aus:

```lua
local sr, sc, er, ec = region_bounds(p1, p2, "v")
if sr then
  translate_region(bufnr, sr, sc, er, ec)   -- sc, er, ec: `integer?`
```

Die Funktion gibt entweder alle vier Werte zurueck oder `nil`, aber deklariert
war `---@return integer?, integer?, integer?, integer?` -- vier voneinander
unabhaengige Optionals. `if sr then` verengt genau einen davon; die anderen
drei bleiben fuer den Pruefer `nil`, und `translate_region` will vier `integer`.
Drei Befunde pro Aufrufstelle, zweimal.

Das laesst sich nicht mit einer Annotation reparieren, weil die Aussage falsch
ist: die vier Werte sind eine Gestalt, kein Quartett. Also sind sie jetzt eine:

```lua
---@class Language.Translate.Span
---@field sr integer  # start row, 0-based
---@field sc integer  # start col, 0-based byte
---@field er integer  # end row, 0-based
---@field ec integer  # end col, 0-based byte, exclusive
```

`if span then` verengt danach alles auf einmal. **Eine Mehrfachrueckgabe, die
alles-oder-nichts ist, ist im Typsystem nicht ausdrueckbar** -- die Tabelle ist
nicht Geschmack, sondern die einzige Form, in der die Zusage stehen kann.

---

#### Form A, das dritte Mal -- und ein Parameter, der dabei auffiel

Offen-Punkt 3 nennt fuenf Stellen mit zwei Annotationsformen, die reihenweise
Befunde erzeugen. Zwei davon lagen hier, in
`config/@types/init.lua` Zeile 96 und 196:

```lua
---@field custom { cmd: fun(text: string[], target: string): string[], parse: fun(out: string): string[] }|nil
```

**Form A**: ein `fun(...): T` in einem Inline-Tabellentyp verschluckt alles,
was danach kommt. Der Rueckgabetyp frisst das Komma und das naechste Feld --
`parse` existierte fuer LuaLS nicht, und `translate/providers/custom.lua:50`
las sich als `undefined-field`. Derselbe Mechanismus, der in pdfport 28 Befunde
aus einer Zeile getragen hat.

Die Loesung stand im selben Repo, fuenfundsiebzig Zeilen weiter oben: die
Spell-Seite hat fuer genau dieselbe Gestalt eine benannte Klasse
(`LanguageSpellCustomProviderCfg`). Die Translate-Seite hat jetzt auch eine.

Beim Aufschreiben fiel der zweite Fehler in derselben Zeile auf: `cmd` war mit
**zwei** Parametern deklariert (`text, target`) und wird mit **drei** gerufen
(`custom.cmd(lines, target, source)`) -- so steht es auch im Modulkopf von
`providers/custom.lua`. Kein Befund, weil die Signatur ohnehin nie gelesen
wurde; ein Benutzer, der sich auf die Doku verlaesst, haette `source` nicht
gefunden.

Offen-Punkt 3 hat damit noch drei Stellen, alle drei in der nvim-Config.

---

#### Der Rest -- fuenf kleine Ursachen

- **`history.save()` las den Ring als Upvalue.** Seine Vorbedingung -- "der
  Ring ist geladen" -- war nirgends aufgeschrieben; beide Aufrufer erfuellen
  sie, aber der Pruefer sieht das nicht ueber Funktionsgrenzen. Nimmt ihn jetzt
  als Parameter, damit steht die Abhaengigkeit in der Signatur.
- **`win_valid` gab `nil` statt `false`.** `win and api.nvim_win_is_valid(win)`
  ist fuer ein nil-Fenster `nil`, und `M.is_open()` verspricht `boolean`.
  Der zweite Lauf hat gezeigt, dass es hier zwei Stellen waren: der Body **und**
  die eigene `@return boolean|nil`-Annotation der Hilfsfunktion.
- **`output.apply`** prueft vier Layout-Werte in einer `or`-Kette; LuaLS
  verengt eine String-Union daran nicht. Ein `---@cast` auf die vier, die der
  Zweig gerade bewiesen hat.
- **`usrcmds`**: `is_dir_path` beweist, dass `scope.path` ein String ist, aber
  der Beweis steckt in einer Variablen, die der Pruefer nicht in den Zweig
  traegt.
- **Zwei Testeingaben sind absichtlich typfremd** -- `add_session(nil)` (die
  Begruendung stand schon als Kommentar daneben) und ein `changed`-Wert, der
  per Konstruktion nicht zur Option passt. Unterdrueckt mit je einem Satz.

---

#### Drei `deprecated`, die keine Schuld sind

`vim.diagnostic.goto_next`/`goto_prev` und `vim.lsp.get_active_clients` sind
deprecated -- und stehen hier ausschliesslich als Fallback:

```lua
local ok = pcall(function()
  vim.diagnostic.jump({ count = count, ... })
end)
if not ok then
  local step = count > 0 and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
```

Das README nennt **Neovim >= 0.9**, `vim.diagnostic.jump` gibt es ab 0.11.
Der veraltete Name ist der Zweck der Zeile. Unterdrueckt mit Begruendung, nach
der Regel: nur wo der Befund sachlich falsch ist oder das Verhalten Absicht ist.

Das ist ein Muster, das noch oefter kommen wird, solange die Repos 0.9
unterstuetzen. `deprecated` steht im Gesamtlauf auf 23; ein Teil davon duerfte
aus demselben Grund dort stehen und will nicht "repariert", sondern begruendet
werden.

---

#### Ein Nebenbefund, der eine Entscheidung braucht

`spell/providers/cspell_server.lua:292`:

```lua
timer:start(cfg.scan_debounce_ms and 6000 or 6000, 0, function()
```

Beide Zweige sind `6000`. Der Ausdruck sieht aus, als haenge das Timeout an der
Konfiguration, und tut es nicht -- `scan_debounce_ms` (Vorgabe 400) hat hier
keine Wirkung. Kein LuaLS-Befund, deshalb nicht angefasst: ob daraus
`cfg.scan_debounce_ms or 6000` werden soll oder eine schlichte Konstante, ist
eine Verhaltensfrage. Ein Debounce von 400 ms und ein Server-Timeout von 6 s
sind verschiedene Dinge; die Konstante ist vermutlich richtig und der
Ausdruck ein Rest.

---

## 2026-09-01

---

### images.nvim -- 37 auf 0, und ein `compare`, das ohne ImageMagick geworfen haette

*(war: Diagnostics-Report Abschnitt 0, "images.nvim vertikal")*

**37 -> 0**, in zwei Laeufen bestaetigt. Commit `c3e415c`, `stylua --check`
sauber, alle 23 Specs gruen. `worse: nothing`.

Der Einstieg war der vorgeschlagene und er hat gehalten: **zuerst nach
verirrten Doc-Bloecken suchen** brachte acht Befunde aus drei Stellen, das
sechste Repo in Folge mit dieser Familie. Die `.luarc.json` dagegen war diesmal
in Ordnung -- sie nennt `workspace.library` nicht mehr (seit `8a5f819`) und
`workspace.ignoreDir` gar nicht, also kam die Injektion an. Das ist relevant,
weil unter `images.nvim/.claude/worktrees/` eine volle Kopie des Repos liegt:
ohne die injizierten 124 Muster waere das dieselbe Selbstkollision gewesen, die
in lsp.nvim 180 Befunde getragen hat.

---

#### Zwei Zahlen, die nie verglichen werden konnten

`images.scale.compute` und `images.scale.fit_cells` beschreiben beide einen
Rueckfall fuer Bilder, deren Masse sich nicht lesen liessen -- und bewachten
ihn beide so:

```lua
if not (a and b and a.width > 0 and a.height > 0 and b.width > 0 and b.height > 0) then
  return { a = 1, b = 1 }
end
```

`images.info.collect` fuellt `width`/`height` nur, wenn ImageMagick installiert
ist. Ohne es ist `a.width` also `nil`, und `nil > 0` ist in Lua kein `false`,
sondern ein Fehler. Der Rueckfall, den der Kommentar darueber verspricht, war
genau der Fall, in dem die Zeile wirft.

Erreichbar war das ueber `:Image compare`: `compare.on_compare` reicht die
beiden Ergebnisse von `info.collect` ungeprueft weiter, mit einem Kommentar
daneben, der die Erwartung ausspricht -- *"missing dimensions -> scale.compute
falls back to 1/1"*. `zen` und `redact` pruefen vorher und kamen deshalb nie
dort an; `compare` auf einer Maschine ohne `magick` schon.

Beide Wachen fragen jetzt nach dem Wert, bevor sie ihn vergleichen. Gefunden
hat das nicht ein Test, sondern der Typ: der Prueferbefund lautete
`Images.Info` passt nicht auf `Images.Scale.Dims`, und der Grund dafuer war
genau dieser Unterschied.

---

#### `Dims` und `MaybeDims` -- ein Unterschied, den der Code schon machte

Fuenf der 37 Befunde hingen daran, dass eine Klasse zwei verschiedene Dinge
beschrieb. `Images.Scale.Dims` deklarierte `width`/`height` als `integer`;
`images.info.collect` liefert sie als `integer|nil`. Drei Verbraucher, zwei
Anspruechen:

- `compute` und `fit_cells` kommen ohne die Masse aus -- steht in ihrem eigenen
  Kopf.
- `cell_box_to_pixels` teilt durch beide und braucht sie wirklich.

Aufgeteilt statt weggeschrieben: `Images.Scale.MaybeDims` (das Paar, wie
`collect` es liefert) und `Images.Scale.Dims : Images.Scale.MaybeDims` (beide
bekannt). `Images.Info` erbt die erste. In `images.redact` wird einmal
verengt -- an der Stelle, die ohnehin prueft --, statt die `Info` zu speichern
und spaeter zu hoffen.

**Eine Sache dabei ist es wert, notiert zu werden:** der erste Versuch hatte
`MaybeDims` nur als eigene Klasse angelegt, ohne Vererbung, und der
Nachher-Lauf stand auf 1 statt 0 -- `Images.Scale.Dims` passte nicht auf
`Images.Scale.MaybeDims`. **LuaLS entscheidet Klassenzuweisbarkeit ueber den
Namen, nicht ueber die Gestalt.** Zwei Klassen mit identischen Feldern sind
fuer den Pruefer nicht dieselbe; die Beziehung muss mit `: Basis` dastehen.

---

#### Drei Advice-Zeilen, die kein `:checkhealth` je gezeigt hat

Derselbe echte Fehler wie in documentation.nvim, runtime-analysis.nvim, mdview
und pdfport: `vim.health.info` nimmt eine Nachricht und sonst nichts. `warn`
und `error` nehmen Hinweise als Varargs, `info` nicht.

```lua
vim.health.info("`tesseract` not found — …", {
  "winget install UB-Mannheim.TesseractOCR  (Windows)",
  "apt install tesseract-ocr  /  brew install tesseract",
  "installed somewhere unusual? set `ocr.bin` to its path",
})
```

Das sind die drei nuetzlichsten Zeilen der ganzen Datei, und sie standen nie in
einem `:checkhealth`. Derselbe lokale Shim wie in den anderen Repos rendert sie
jetzt in die Nachricht. **Das ist der fuenfte Fund dieser Art** -- der Posten
ist damit kein Zufall mehr, sondern ein Muster, das in die RULES-Ableitung am
Ende gehoert.

---

#### Drei Doc-Bloecke, verdoppelt beim Nachruesten eines Parameters

`force_ask` ist spaeter dazugekommen, und an drei Stellen wurde der Doc-Block
nicht bearbeitet, sondern ein zweiter dahintergehaengt:

```lua
---@param name string|nil a file name already given — skips any name prompt
---@return nil
---@param name string|nil
---@param force_ask boolean|nil  # prompt for a name even when `ask_filename` is off
```

Acht `duplicate-doc-param` aus drei Ursachen (`images.paste`, `paste.M.run`,
`paste.capture_with_optional_name`). Die zweite Kopie war jedesmal die
aermere -- in `capture_with_optional_name` stand `capture` dort als blankes
`function` statt als `fun(out: string, cb: fun(ok: boolean, err: string|nil))`,
also hat der Nachtrag die Signatur des Callbacks mitgenommen.

Nebenbefund derselben Familie: zweimal stand `---@return` vor `---@param`.
Kein Befund, aber dieselbe Handschrift; mitgezogen.

---

#### Ein `@return` mit einem Komma

Form B aus Offen-Punkt 3, hier zum ersten Mal ausserhalb der genannten Liste:

```lua
---@return table|nil snacks.picker, if installed
```

LuaLS liest das als **zwei** Rueckgabewerte. `if` wurde fuer einen Typnamen
gehalten (`undefined-doc-name`), und `snacks_picker` schien einen zweiten Wert
zu schulden, den es nicht zurueckgibt (`missing-return-value`). Zwei Befunde
aus einem Komma. Die Beschreibung steht jetzt hinter einem `#`.

---

#### Der Rest -- vier kleine Ursachen

- **Zwei `pcall(vim.cmd, ...)`** (Cluster E, der ganze Anteil dieses Repos) sind
  Closures. Hier ausdruecklich *nicht* `vim.cmd.redraw`: `terminal_draw_spec`
  tauscht `vim.cmd` selbst und liest den Kommandonamen aus dem ersten Argument
  -- die Unterkommando-Form haette den Test still blind gemacht.
- **`convert.valid_geometry`** prueft `type(spec) ~= "string"` in seiner ersten
  Zeile und `tostring`t den Wert in der Fehlermeldung. Nur die Annotation
  behauptete einen String; der Test uebergibt `nil` und erwartet `false`.
- **`debug.border_of`** liest `cfg.border` jetzt ueber ein Local. `border` ist
  eine Union aus den Preset-Namen und einer Segmentliste, und
  `type(...) ~= "table"` verengt ein Local, kein Feld.
- **`calibrate`** ruft `vim.keymap.set` direkt, wie der Rest des Repos. Das
  lokale Alias `local map = vim.keymap.set` war die einzige Stelle, an der der
  Pruefer `need-check-nil` meldete -- `debug.lua` ruft dieselbe Funktion zweimal
  direkt und ohne Befund.

---

#### Die Tests: neun Doubles unterdrueckt, sieben `assert` gesetzt

Sechzehn der 37 lagen in `TESTS/`, und sie zerfallen sauber in zwei Haelften.

**Neun `duplicate-set-field`** sind Doubles: `images.terminal.draw` viermal in
`anchor_spec`, `vim.api.nvim_ui_send` dreimal, `calibration.path` zweimal (der
Sandbox-Pfad, damit kein Lauf die echte Kalibrierung des Entwicklers liest).
Jeweils fuer die Dauer eines Falls getauscht und direkt danach zurueckgesetzt
-- unterdrueckt mit der Begruendung daneben, wie in open.nvim und filetree.nvim.
Dazu die eine im Quellcode: der Recorder in `images.debug` ueberschreibt
`terminal.draw` absichtlich und legt das Original vorher auf dem Modul ab.

**Sieben `param-type-mismatch`**, davon sechs Werte, die mit `H.ok` geprueft
und danach trotzdem benutzt wurden -- `convert.to_png` gibt `string|nil`,
`vim.uv.cwd()` gibt `string|nil`, die IDAT-Suche in `testcard_spec` findet
vielleicht nichts. `assert` an sieben Stellen (vier in `convert_spec`, eine in
`browse_spec`, zwei in `testcard_spec`), so wie `convert_spec` es an anderen
schon tat: es benennt die Zeile, die gebrochen ist, statt fuenf Zeilen spaeter
mit "arithmetic on a nil value" zu scheitern. Dieselbe Bewegung wie in
open.nvims `usrcmds_spec`. Der siebte Befund war `valid_geometry(nil)` -- eine
absichtlich ungueltige Eingabe, die jetzt in der Signatur der Funktion steht
statt im Spec unterdrueckt zu werden.

---

### sandbox.nvim -- 39 auf 0, und Ports, die ihre eigenen Parameter nicht fanden

*(war: Diagnostics-Report Abschnitt 0, "sandbox.nvim vertikal")*

**39 -> 0**, in zwei Laeufen bestaetigt. Commit `9bc3d12`, `stylua --check`
sauber. Zu den Tests siehe unten -- sie sind der eigentliche Nachtrag dieses
Durchgangs.

---

#### Ein `runtime.path`, der auf ein Verzeichnis zeigt, das es nicht gibt

```json
"runtime.path": ["lua/?.lua", "lua/?/init.lua", "tests/?.lua"]
```

Das Verzeichnis heisst `TESTS/`; `git ls-files` fuehrt 16 Dateien darunter und
keine einzige unter `tests/`. Auf Windows ist das folgenlos, weil das
Dateisystem die Schreibweise ignoriert -- auf Arch/Ubuntu loest `require` in
den Specs damit nicht auf. Der Fund kostet keinen Befund und stand trotzdem am
Anfang des Durchgangs, weil er sonst nur auf der anderen Maschine auffaellt.

---

#### Fuenf Ports, die ihre eigenen Parameter nicht fanden

```lua
--- @param on_line fun(line: string)
--- @param on_exit? fun(code: integer|nil)
follow_logs = function(id, _on_line, _on_exit)
  error(id .. ": follow_logs not implemented.")
end,
```

`core/ports/container_engine.lua` ist die Schnittstellendefinition: lauter
Stubs, die `error()` werfen, damit ein Adapter merkt, was er nicht
implementiert hat. Der Unterstrich sollte "hier ungenutzt" sagen -- und liess
dabei jede Annotation daneben ins Leere greifen. Fuenfmal
`undefined-doc-param`, in `follow_logs`, `pull_image`, `push_image` und
`login_registry`.

Die Port-Datei *ist* die Doku dieser Schnittstelle. Ihre Parameter tragen
jetzt die Namen, die sie dokumentiert.

---

#### Fuenf verirrte Doc-Bloecke -- das fuenfte Repo

```lua
--- @param images table[]
local notify = require("sandbox.notify")
local list_actions = require("sandbox.ui.list_actions")
return function(images)
```

In allen vier `*_list_view*`-Dateien steht der `@param` **vor** den
`require`-Zeilen und haengt sich damit an `local notify = …` statt an die
Funktion drei Zeilen tiefer. In `list_view.lua` war es sogar eine Dublette --
die richtige Annotation stand bereits ueber `return function(containers, all)`.

Nach documentation, pdfport, spotlight und mdview ist das der fuenfte
Durchgang mit demselben Muster. Es lohnt sich, danach zu suchen, bevor man die
Einzelbefunde liest: `undefined-doc-param` und `duplicate-doc-param` sind
seine Signatur.

---

#### Eine Klasse, die halb so viel deklariert, wie der Port kann

`WslEngine` in `lua/@types/wsl.lua` fuehrte vier Felder --
`list_distros`, `start_distro`, `stop_distro`, `exec_in_distro`. Der Port
`core/ports/wsl_engine.lua` implementiert neun. Die fuenf fehlenden
(`set_default_distro`, `set_version_distro`, `export_distro`, `import_distro`,
`shutdown_all`) werden von je einem Use Case aufgerufen -- das waren die fuenf
`undefined-field`. Nachgetragen, mit den Signaturen aus dem Port.

---

#### Die Completion-Quellen reichten `nil` weiter

Fuenfmal dieselbe Form:

```lua
local names = cached_names("containers", function()
  local core = require("sandbox")
  return require("…list_containers")(core.get_engine())
end, …)
```

`cached_names` will ein `fun(): table[]`. `get_engine()` ist aber `table|nil`,
und der Use Case gibt `table[]|nil, string|nil` zurueck. Vier
`param-type-mismatch` und sechs `return-type-mismatch` aus einer Form.

Fuer eine Completion-Quelle bedeuten beide Faelle dasselbe -- keine
Kandidaten --, und das steht jetzt auch so da: Engine pruefen, Ergebnis auf
`{}` normalisieren.

---

#### Ein Bug, den die Typen gefunden haben

```lua
local list = type(existing.default) == "table" and existing.default or { existing.default }
list[#list + 1] = k.lhs
```

`actions_from` fasst Eintraege mit gleichem `desc` zu **einer** Aktion mit
mehreren Standardtasten zusammen -- „jede Liste bindet `<CR>` und `i` auf
inspect, das ist eine Sache, die ein Nutzer verschieben will, nicht zwei". Nur
ist `lhs` selbst `string|string[]`: hat einer der Eintraege bereits mehrere
Tasten, landete das ganze Array **als ein Element** in der Liste statt sie zu
erweitern.

Der Typ-Befund lautete `assign-type-mismatch`; der Fehler dahinter ist eine
verschachtelte Tastenliste, die niemand so gemeint hat.

**Zweimal dabei gelernt, was LuaLS nicht einengt:**

* `local x = type(v) == "table" and v or { v }` -- der `and`/`or`-Ausdruck
  bleibt `string|table`. Erst ein `if` verengt.
* Ein Guard auf einem **Feld** (`type(k.lhs) == "table"`, dann `ipairs(k.lhs)`)
  verengt nur den geprueften Ausdruck; die zweite Lesung ist eine neue. Das ist
  dasselbe Muster, das in documentation.nvim die Haelfte des Durchgangs
  ausmachte -- an eine Lokale binden, dann pruefen.

---

#### Der Rest

Ein `uv.new_timer()` ohne Guard in `list_actions.lua` -- **heute der dritte**
nach spotlight und mdview. `nvim_buf_add_highlight` -> `vim.hl.range`, seit
dem Erstscan in Abschnitt 5 gelistet. `command_tail`s `nil` in die Signatur
geschrieben, weil „kein Kommando" die Antwort ist, auf die die Aufrufer
reagieren. Und die beiden `inspect_container`-Adapter, deren async-Pfad
`return` ohne Wert macht.

---

#### Nachtrag: neun rote Tests, und ein Runner, der es nicht merkt

Der erste Testlauf meldete **17 bestanden, 0 fehlgeschlagen** und war eine
Falschmeldung: `PlenaryBustedDirectory` hat headless unter Windows **2 von 13**
Spec-Dateien abgearbeitet und sich dann sauber beendet. Genau die Falle, die
im Report unter Offen-Punkt 13 fuer `neotree-fs-refactor` steht -- nur liegt
sandbox im Umfang.

Einzeln gefahren (`PlenaryBustedFile` pro Datei): **86 bestanden, 9
fehlgeschlagen** -- `init_spec` 4, `project_config_spec` 4, `run_argv_spec` 1.

Gegengeprueft in einem Worktree auf `94193cd`, also dem Stand vor diesem
Durchgang: **dieselben neun, gleiche Namen, gleiche Zahlen.** Es ist Bestand.
Als eigener Punkt im Report notiert, zusammen mit dem Runner -- ein Lauf, der
elf Dateien ueberspringt und Erfolg meldet, ist das groessere Problem von
beiden.

---

### mdview.nvim -- 44 auf 0, und ein `assert`, das seinen Wert verschluckt hat

*(war: Diagnostics-Report Abschnitt 0, "mdview.nvim vertikal")*

**44 -> 0**, in zwei Laeufen bestaetigt. Commit `53e02c9`, 88 Tests gruen,
`stylua --check` sauber.

Der erste Griff war wieder die `.luarc.json`: sie fuehrte
`"workspace.library": ["$VIMRUNTIME"]` -- ohne `/lua`, ohne luv, ohne die
Plugin-Typen -- und ersetzte damit die Injektion. mdview `require`t lib.nvim an
46 Stellen. Das kostete hier allerdings nur zwei Befunde, nicht dreizehn wie
bei spotlight; die Zeile ist ein Handgriff, kein Cluster.

---

#### Der Prozess-Zustand war dreimal beschrieben, zweimal falsch

`state.lua` haelt den laufenden Relay-Prozess. Sein Typ stand an drei Stellen:

| Ort | sagt | ist |
|---|---|---|
| `types/core.lua` `mdview.core.state.runner.proc` | `integer\|nil` | ein `SpawnedProcess` |
| `types/init.lua` `mdview.runner` | `proc table\|nil`, `handle userdata\|nil` | von nirgends referenziert |
| `types/adapter.lua` `SpawnedProcess` | richtig -- bis auf `handle userdata` | |

`runner.lua:187` legt dort `{ handle, pid, stdout, stderr, cwd }` ab, und
`state.lua` liest `proc.handle` wieder heraus. Der Kommentar daneben sagt es
sogar ausdruecklich ("the handle lives in `M.runner.proc`, see M.set_proc") --
die Annotation eine Datei weiter sagte etwas anderes.

`mdview.runner` ist geloescht: eine dritte Beschreibung desselben Zustands,
die niemand referenziert, ist keine Dokumentation, sondern eine Falle.

Und `SpawnedProcess.handle` trug `userdata`. Das ist Cluster D in klein:
`userdata` hat keine Methoden, also fand `proc.handle:is_closing()` nichts.
Jetzt `uv.uv_process_t` und `uv.uv_pipe_t` -- **mit** dem `uv.`-Praefix, das
lib.nvim seit Cluster D verwendet; ohne Praefix meldet LuaLS
`undefined-doc-name`, was der erste Anlauf prompt gezeigt hat.

---

#### Alle zehn `need-check-nil` waren zwei ungeprüfte libuv-Aufrufe

```lua
local stdout = uv.new_pipe(false)
local stderr = uv.new_pipe(false)
```

Beide sind `uv_pipe_t|nil`, und `start_server` benutzt sie danach an sechs
Stellen -- `pcall(stdout.close, stdout)`, `stdout:read_start(...)`,
`stderr:read_start(...)`. Ohne Guard wird aus einer erschoepften Handle-Tabelle
ein "index a nil value" statt des sauberen `nil`-Returns, den dieselbe Funktion
fuer jeden anderen Fehlerfall liefert. Der Guard folgt jetzt derselben
Konvention wie die Pruefungen darunter: loggen, `nil` zurueckgeben, den
Aufrufer melden lassen.

Dazu zwei `uv.new_timer()` ohne Guard, in `inbound_poll` und `live_push`.
Beide Male ist die Antwort dieselbe wie in spotlight: das Feature ist die
Annehmlichkeit, der Callback der Vertrag.

---

#### Wieder zwei verirrte Doc-Bloecke

Das **vierte** Repo mit diesem Muster nach documentation, pdfport und
spotlight.

In `inbound_poll.lua` klebten `---@param key` und `---@param href` an
`is_absolute(p)`, die keinen der beiden Parameter hat -- `handle_nav(key,
href)` steht vierzig Zeilen tiefer und fuehrt sie selbst. Ersatzlos weg.

In `standalone.lua` stand die ganze Prosa zu `supports_watch` ueber der
Cache-Tabelle `watch_support_cache`, mitsamt `---@param bin string` und
`---@return boolean`. Das `@return` stammt aus der Zeit vor dem Umbau auf
`vim.system()` -- der Text daneben beschreibt den Umbau ("It used to run
through vim.fn.system()"), waehrend die Annotation den alten Rueckgabewert
weiterfuehrte. Die Funktion antwortet laengst per Callback.

---

#### Drei Signaturen, die ihre eigene Funktion falsch beschrieben

```lua
---@param path string
---@return string|nil
function M.path(path)
  if not path then
    return nil
  end
```

`normalize.path` und `normalize.path_for_url` deklarierten beide `path string`
und pruefen in der Zeile darunter auf genau das Gegenteil. Derselbe Fall wie
`sets.save` in spotlight und `harness.contains` -- inzwischen ein eigenes
kleines Muster: **eine Signatur, die den Guard direkt unter ihr nicht kennt.**

Dazu `parse_start_args`, das `file, cwd, port` zurueckgibt und zwei davon
annotiert hatte.

---

#### Der Fund, der nicht in der Zaehlung steht

`TESTS/nvim/harness.lua` ersetzt das **globale** `assert` durch eine Tabelle
mit luassert-aehnlicher Oberflaeche:

```lua
__call = function(_, cond, msg)
  if not cond then
    error(msg or "assert failed", 2)
  end
end,
```

Kein `return`. Lua's eigenes `assert` gibt seine Argumente zurueck -- deshalb
schreibt man ueberhaupt `local x = assert(f(), "…")`. Hier band dasselbe
Muster still `nil`.

Aufgefallen ist es, weil genau diese Schreibweise der Fix fuer dreizehn
`param-type-mismatch` war: die Specs binden ihren Fixture-Key mit
`normalize.path(...)`, das `string|nil` liefert. Nach dem `assert` fielen
16 Tests um -- nicht wegen der Aenderung, sondern weil der Harness das
`assert` unbrauchbar machte.

Zwei Dinge daran sind ueber diesen Durchgang hinaus interessant. Erstens
ersetzt der Harness das *globale* `assert`, also sieht auch der Code unter Test
diese Version -- ein `assert(x, ...)` im Produktivcode, dessen Rueckgabewert
gebraucht wird, waere waehrend der Tests still nil geworden. Zweitens: die
Nachbildung gibt jetzt **alle** Argumente zurueck, wie das Original, und genau
das hat vier weitere Tests gekippt --
`vim.json.decode(assert(json, "…"))` expandiert dann zu
`decode(json, "…")`, und `decode`s zweites Argument ist ein Options-Table. Die
Bindung steht deshalb auf einer eigenen Zeile. Das ist kein Sonderfall dieses
Harness, sondern gilt fuer Lua's `assert` genauso.

---

#### Der Rest

`assert.is._true(true)` in `TESTS/lua/smoke_spec.lua` -> `assert.is_true`.
`_true` ist luasserts maskierte Schreibweise fuer das reservierte Wort und
zur Laufzeit dieselbe Assertion; das Typ-Meta in lib.nvim kennt nur die
geläufige Form (siehe Offen-Punkt „luasserts Assertionen aufweiten").

Ein `pcall(vim.cmd, ...)` aus Cluster E in `usrcmds/diagnose.lua`. Vier
Test-Doubles (`ws.send_content`, `ws.send_markdown`, `ws.send_scroll`,
`vim.fn.jobstart`) unterdrueckt. Und `experimental.any_file` -- ein bewusst
weitergefuehrter Alias, dessen Feld beim Umzug ans Top-Level aus der Klasse
fiel -- ist als deprecated wieder deklariert, statt den Zugriff zu
unterdruecken.

---

### Der Gesamtlauf auf der korrigierten Messgrundlage -- 1254 auf 570

*(Folge des spotlight-Durchgangs; kein eigener Roadmap-Punkt)*

Nach der Werkzeug-Korrektur (`dump_library.lua` traegt `<plugin>/lua` statt
der Repo-Wurzel) einmal ueber alle 33 Workspaces, gegen den Lauf vom
2026-09-01 gestellt.

**1254 -> 570.** Davon sind **93 gearbeitet** (spotlight 49, mdview 44); die
uebrigen **591 waren Phantome**, die das Werkzeug selbst erzeugt hatte.

| Repo | 01.09. | 02.09. | was das war |
|---|---:|---:|---|
| filetree.nvim | 161 | **6** | stand in der Tabelle auf 0 -- fortgeschrieben, nicht gemessen |
| lsp.nvim | 172 | 35 | die Tabelle sagte 35; der Rohlauf sagte 172 |
| runtime-analysis.nvim | 109 | **4** | dito, Tabelle 0 |
| gopath / open / pdfport | 67 / 48 / 61 | **0** | dito |
| fileops / emojis / sessions | 35 / 13 / 6 | **0** | dito |
| sandbox.nvim | 40 | 64 | **schlechter** -- siehe unten |
| **Summe** | **1254** | **570** | |

Der Befund dahinter ist unangenehm und gehoert festgehalten: **die
Stand-Tabelle im Report war seit dem 01.09. fortgeschrieben, der Rohlauf
darunter sagte etwas anderes.** Elf Repos standen dort auf Null, waehrend
`base0901` fuer sie zusammen 500 Befunde fuehrte -- allesamt Phantome aus den
fremden `TESTS/`-Verzeichnissen, die als Library mitliefen. Die Durchgaenge
selbst waren richtig (jeder hat sein Repo einzeln vor und nach gemessen und
auf 0 gebracht); nur der Gesamtstand daneben war es nicht.

Ab hier ist die Tabelle in Abschnitt 0 wieder gemessen.

---

#### sandbox.nvim: 40 -> 64 -> 39, und ein Stub, der ein Repo lahmlegte

Das einzige Repo, das der Lauf als *worse* meldete. 24 neue
`redundant-parameter`, alle in dieser Form:

```
TESTS/minimal_init.lua:22  This function expects a maximum of 0 argument(s)
                           but instead it is receiving 1.
```

Die Zeile ist `vim.cmd("runtime plugin/plenary.vim")`. Die Ursache steht in
einer ganz anderen Datei:

```lua
-- exec_workdir_spec.lua, before_each
vim.cmd = function() end
```

Ein Test-Double, das den Split und den Terminal-Modus des Adapters wegnimmt --
beides nicht Gegenstand des Tests, und als Absicht auch kommentiert. **LuaLS
traegt die Signatur eines solchen Stubs aber in den ganzen Workspace.** Eine
nullary `vim.cmd` liess damit alle 24 echten `vim.cmd("…")`-Aufrufe des Repos
melden, in `lua/` wie in `TESTS/`. `function(...)` genuegt.

Warum erst jetzt: solange fremde Repo-Wurzeln in der Library lagen, gewann
irgendeine andere `vim.cmd`-Definition. Der Befund ist aelter als die
Korrektur, die ihn sichtbar gemacht hat. Commit `94193cd`, 12 Tests der
beruehrten Datei gruen -- **39**, also unter dem Ausgangswert.

Das ist die dritte Ausgabe desselben Themas an einem Tag: ein Stub oder eine
Signatur, die enger ist als das, was sie ersetzt, und die dann anderswo Schaden
anrichtet -- nach `harness.contains` in spotlight und dem `assert` in mdviews
Harness.

---

### spotlight.nvim -- 37 auf 0, nachdem die Messung erst einmal stimmte

*(war: Diagnostics-Report Abschnitt 0, "spotlight.nvim vertikal")*

Der Report nannte 49. Gemessen wurden am Ende **37 -> 0** -- und die Differenz
ist die eigentliche Geschichte dieses Durchgangs.

Commit `f0d0287`, 453 Tests gruen, `stylua --check` sauber, Null in zwei
Laeufen bestaetigt.

---

#### Dreizehn Befunde waren eine Zeile in der `.luarc.json`

`Lib.Keymap.Registered`, `Lib.Keymap.Spec`, `Lib.UserCmd.Composer.RangeInfo`,
`Lib.ContextMenu.Item` -- der Scan meldete alle vier als undefiniert, und der
Report hatte den letzten schon als „ein lib.nvim-Typ, den es unter dem Namen
nicht gibt" notiert. Es gibt sie alle vier:

```
lib.nvim/lua/lib/nvim/bindings/keymap/@types/init.lua:58   Lib.Keymap.Spec
lib.nvim/lua/lib/nvim/bindings/keymap/@types/init.lua:71   Lib.Keymap.Registered
lib.nvim/lua/lib/nvim/bindings/usercmd/composer/@types/init.lua:99
lib.nvim/lua/lib/nvim/contextmenu/@types/init.lua:6        Lib.ContextMenu.Item
```

spotlights `.luarc.json` setzte `workspace.library` auf `$VIMRUNTIME/lua` und
`${3rd}/luv/library` -- und weil eine `.luarc.json` jeden Schluessel, den sie
nennt, **ersetzt**, war lib.nvim damit draussen. Cluster A hat genau das
schon in 20 Repos abgeraeumt, und die Sechser-Runde in sechs weiteren; hier
fiel es durchs Raster, weil `$VIMRUNTIME` ja drinstand.

Die acht `undefined-field` auf `range`, `line1`, `line2`, `col1`, `col2`
hingen direkt daran: ohne `RangeInfo` ist der Parameter untypisiert und seine
Felder unbekannt.

---

#### Und 346 waren die Messung selbst

Nach dem Entfernen der Zeile sprang der Scan von 49 auf **386**. Fast alles
davon `param-type-mismatch` in Testdateien, in dieser Form:

```
TESTS/commands_spec.lua:31  Cannot assign `integer` to parameter `string|nil`
```

spotlights Specs machen `local t = require("harness")`, und `TESTS/run.lua`
setzt dafuer `package.path`. LuaLS kennt diesen Weg nicht und loest ueber
Suffix-Matching auf -- mit **21** Dateien namens `TESTS/harness.lua` in den
Repos. Es griff die falsche, deren `H.eq(a, b, msg)` einen `string|nil` als
dritten Parameter hat, wo spotlights `M.eq(name, got, want)` `any` nimmt.

**Die Gegenprobe im laufenden Server** hat das entschieden -- die Regel aus
Abschnitt 1, hier zum ersten Mal zwingend:

| Datei | `vim.diagnostic.get` | Scan vorher | Scan nachher |
|---|---:|---:|---:|
| `ui/list.lua` | 8 | 8 | 8 |
| `bindings/usrcmds.lua` | **1** | 9 | 1 |
| `TESTS/commands_spec.lua` | **0** | 0 | 37 |

Der Editor kennt weder die neun noch die siebenunddreissig. Die
`.luarc.json`-Aenderung ist also richtig, und die 346 sind ein Artefakt des
Werkzeugs.

---

#### Die Ursache im Werkzeug, und was sie nicht war

`dump_library.lua` uebernimmt aus `build_library(root)` jeden
`runtimepath`-Eintrag **als Repo-Wurzel** -- `E:/repos/lib.nvim`,
`E:/repos/insights.nvim`, und damit deren `TESTS/`. Der Editor bekommt diese
Wurzeln nie: sein Attach-Pfad nutzt `build_runtime_library()` mit drei
Pfaden, und die Plugin-Typen zieht lazydev nach -- als `<plugin>/lua`, nicht
als Wurzel.

Genau das tut der Dump jetzt auch: liegt unter einem Eintrag ein `lua/`, wird
dieses eingetragen statt der Wurzel. spotlights Library schrumpft damit von
38 auf 37 Eintraege, und die 346 Phantome verschwinden.

**Eine Hypothese davor war falsch und ist es wert, notiert zu werden.**
Zuerst schien der Fehler ein anderer: `find_type_dirs(root)` sammelt auch die
`@types/`-Verzeichnisse des gemessenen Workspace ein -- bei lib.nvim 110 von
146 Eintraegen --, also muesste LuaLS jede `@class` darin zweimal sehen und
gegen sich selbst melden. Ein Filter dafuer, ein zweiter vollstaendiger Lauf:
**Regel fuer Regel dieselben 411**. LuaLS indiziert einen Pfad im Workspace
ohnehin als Workspace-Datei; die Library-Nennung aendert daran nichts. Der
Filter kam wieder raus.

Der Nebenbefund aus dem Report (Offen-Punkt 8, „das Werkzeug dumpt die falsche
Funktion") ist damit von kosmetisch zu blockierend geworden und erledigt.

---

#### Was danach an echtem Code uebrig war

**Ein Doc-Block, vierzig Zeilen zu weit oben.** `ui/list.lua` dokumentiert
`M.open` -- der Block klebte am Kommentar von `M.filter`, und `M.open` selbst
hatte gar keinen. Zwei `---@param mode` uebereinander, ein `---@param filter`,
den `M.filter` nicht kennt, und ein `---@return nil`, das damit `M.filter`s
**Rueckgabewert #1** wurde. Deshalb meldete `items = M.filter(items, filter)`
darunter `cast-local-type` und die Zeile danach `param-type-mismatch`. Sieben
Befunde, ein verschobener Block.

Dieselbe Klasse Fehler wie die zwei verwaisten Doc-Bloecke in
documentation.nvim und die zwei uebereinander in pdfport -- inzwischen der
dritte Fund dieser Art.

**Zwei Signaturen, die ihre eigene Funktion falsch beschrieben.**

`TESTS/harness.lua` deklarierte `contains(name, haystack: string, needle)`,
obwohl der Rumpf `type(haystack) == "string"` prueft und sonst die Assertion
fehlschlagen laesst. Genau dafuer rufen die Specs sie auf: mit einem `err`,
das `string|nil` ist und dessen Gesetztsein die Assertion pruefen soll. Eine
Assertion, die ihren Pruefgegenstand nicht annehmen darf, ist keine.

`sets.save` deklarierte `name string` und antwortet eine Zeile spaeter
`false, "a set needs a name"` auf alles, was kein String ist.

**Eine Einengung, die ein Swap zunichtemacht.** In `bindings/usrcmds.lua`
pruefen zwei `type(...)`-Guards `r.col1`/`r.col2` -- und danach stellt
`scol, ecol = ecol, scol` das deklarierte `integer?` der Locals wieder her.
Die geprueften Werte gehen jetzt in frische Locals, dann darf getauscht
werden.

**Ein fehlbarer Aufruf ohne Guard.** `uv.new_timer()` kann nil liefern.
Debouncing ist in diesem Fallback die Annehmlichkeit, das Ausfuehren der
Funktion der Vertrag -- ohne Timer laeuft der Callback jetzt sofort statt
verschluckt zu werden.

**`try_require` liefert `table|function|nil`.** `mod.save` abzufragen engt
nichts ein: eine Funktion antwortet dort einfach nil. `persist` und `sets`
fragen jetzt nach der Tabelle, die ihre Annotation verspricht -- was auch die
ehrlichere Pruefung ist.

---

#### Die Tests: acht Invarianten benannt, zehn Absichten unterdrueckt

Acht `param-type-mismatch` waren `Spotlight.Item|nil` an einem
`Spotlight.Item`-Parameter, an Stellen, an denen der Test das Item zwei Zeilen
vorher selbst angelegt hat. Dort steht jetzt `assert(..., "…")`: das benennt
die Invariante und macht aus einem stillen nil-Index einen Fehlschlag mit
Namen.

Die uebrigen zehn sind absichtlich ungueltige Eingaben -- `swatch = 42`,
`count_scope = "bogus"`, `locked = "yes"`, ein Store-Literal, das auf sechs
Arten kaputt ist. Sie sind unterdrueckt, jede mit einem Satz Begruendung.

**Zwei Dinge dabei, die beim naechsten Mal Zeit sparen:**
`---@diagnostic disable-next-line` deckt genau eine Zeile -- bei einem
mehrzeiligen Tabellenliteral liegt der Befund auf einer der Innenzeilen und
bleibt stehen. Dort gehoert ein `disable`/`enable`-Paar hin. Und ein `disable`
ohne `enable` gilt bis zum Dateiende und verdeckt still den ganzen Rest.

---

#### Nachtrag: filetree.nvim steht nicht mehr auf Null

Der Kontrolllauf nach der Werkzeugkorrektur ueber vier fertige Repos:
documentation, open und pdfport bleiben bei 0, **filetree zeigt 6** --
durchweg `duplicate-set-field` auf `vim.notify`, fuenf in Testdateien und
einer in `features/infra/watcher_quarantine/init.lua:76`. Der letzte ist ein
bewusster Monkey-Patch mit Wiederherstellung (EPERM-Rauschen der
File-Watcher), also derselbe Fall wie ein Test-Double: eine Unterdrueckung
mit Begruendung, kein Umbau.

---

### open.nvim -- 48 auf 0, und ein Spec, das unbrauchbar haette scheitern koennen

*(war: Diagnostics-Report Abschnitt 0, „Vorschlag naechster Schritt" und Offen-Punkt 1)*

Der achte vertikale Durchgang. **48 -> 0**, `worse: nothing`, alle sechs Specs
gruen, stylua sauber, durch zwei Laeufe bestaetigt.

Ungewoehnliche Verteilung fuer diese Reihe: **42 der 48 lagen in `TESTS/`**,
nur 6 in `lua/`. Beide Haelften liefen auf dasselbe hinaus -- einen Typ, der
weniger beschrieb, als der Code tut.

---

#### Ein `table`, das zwoelf Schluessel verschwieg

`viewer.run` nahm `---@param opts table`. Es liest zwoelf Schluessel aus dieser
Tabelle, und `bindings/usrcmds.lua` baut jeden einzelnen aus der geparsten
Kommandozeile -- `table` sagte davon nichts. Die Gestalt heisst jetzt
`OpenNvim.Viewer.RunOpts` und steht bei den `OpenNvim.Viewer.*`-Typen, die
ohnehin schon da waren; dazu `OpenNvim.Viewer.CollectOpts` fuer die Teilmenge,
die `M.collect` nimmt.

Das ist die vollstaendige Oberflaeche von `:Open viewer` und seinen
Wrapper-Kommandos -- zum ersten Mal aufgeschrieben.

---

#### Zwei Felder gerettet, siebenundzwanzig nicht -- und das war die interessante Haelfte

Der Typ reparierte die ersten beiden Feldzugriffe in `usrcmds_spec` und keinen
der 27 danach. Der Grund:

```lua
    got = nil
    vim.cmd("Open viewer urls")
    H.eq(got.kind, "urls", ...)   -- got ist hier `nil`, fuer den Pruefer
```

Das Zuruecksetzen ist **Absicht** -- es beweist, dass das naechste Kommando
wirklich neu dispatcht hat. Fuer LuaLS ist ein zurueckgesetztes Local danach
aber `nil`, und jeder Feldzugriff darauf ein undefiniertes Feld.

Das Zuruecksetzen bleibt also, und jeder Fall holt sich seinen Fang jetzt ab:

```lua
    got = nil
    vim.cmd("Open viewer urls")
    got = assert(got, ":Open viewer urls did not reach viewer.run")
```

Das ist genau das, was der Kopfkommentar der Datei ohnehin verlangt („when
something here comes back nil, this file must crash and name it"). **Vorher
scheiterte ein Kommando, das nicht mehr zu `viewer.run` routet, drei Zeilen
spaeter mit „index a nil value" und ohne einen Hinweis darauf, welcher Fall
kaputt ist.** Zehn Stellen in `usrcmds_spec`, eine in `viewer_spec`.

---

#### Die sechs in `lua/`

- Vier `notify.error(err)` reichen den zweiten Rueckgabewert von
  `run_detached` durch, also ein `string?`. Jeder hat jetzt eine
  Ersatznachricht -- was der Leser auch statt eines leeren Fehler-Popups
  bekommt.
- Ein `pcall(vim.cmd, ...)` ist eine Closure (Cluster E; der ganze Anteil
  dieses Repos).
- `keywords.lua` wies demselben Local erst einen getrimmten String und dann
  nil zu; der getrimmte Wert bekommt ein eigenes.

Unterdrueckt, mit Begruendung: elf Test-Doubles ueber drei Spec-Dateien, jedes
fuer die Dauer eines Falls getauscht und direkt danach zurueckgesetzt; und
`vim.system`s Stelligkeit in `features_spec`, wo die mitgelieferte Meta zwei
Parameter deklariert und die Funktion zur Laufzeit drei nimmt (nachgemessen) --
ein getreues Double liest sich damit als eines zu viel.

---

#### Nebenher: der Querschnittsposten ist vermessen

Offen-Punkt 2 („die zwei Annotationsformen, die still zweistellig kosten")
war bis hierher eine Vermutung ohne Zahl. Eine Suche ueber alle 31 Plugins
plus die Config, auf **das** gemustert, was den Parser wirklich bricht:

- **Form A** -- ein `fun(...): T` im Tabellentyp, auf das **noch ein Feld
  folgt**: **4 Stellen**. `language.nvim/config/@types/init.lua` zweimal
  (`custom = { cmd: fun(...): string[], parse: fun(...): string[] }`, wo
  `parse` verschwindet) und `nvim/lua/config/snacks/picker/init.lua`
  zweimal. Ein `fun(...)` als **letzter** Eintrag ist harmlos, ein
  geklammertes `(fun(...): T)` ueberall -- beide zaehlen nicht mit.
- **Form B** -- `@return <typ>  <wort>,` ohne Namen: **1 Stelle**,
  `nvim/lua/bindings/usrcmds/case/extract/doclinks.lua:25`.

Also fuenf Stellen in zwei Workspaces, nicht der grosse Posten, nach dem es
nach drei Wiederholungen aussah. Sie fallen beim jeweiligen Repo an; der
Punkt ist damit von „unbekannt gross" auf „benannt" geschrumpft.

---

### pdfport.nvim -- 61 auf 0, und der Notifier, den niemand sehen konnte

*(war: Diagnostics-Report Abschnitt 0, „Vorschlag naechster Schritt" und Offen-Punkt 1)*

Der siebte vertikale Durchgang. **61 -> 0**, `worse: nothing`, alle sieben
Specs gruen, stylua sauber. Bestaetigt durch **zwei** Laeufe, weil ein Befund
in `marker.lua` erst beim dritten Scan auftauchte -- dazu unten.

---

#### Achtundzwanzig Befunde waren eine Zeile

`util.notify.create` deklarierte seinen Rueckgabewert als Inline-Tabellentyp:

```lua
---@return { info: fun(msg: string): nil, warn: fun(msg: string): nil, error: ..., debug: ... }
```

Innerhalb eines Tabellenliterals verschluckt ein `fun(...): nil` **alles nach
seinem Rueckgabetyp**. LuaLS sah also nur `info`; `warn`, `error` und `debug`
lasen sich danach an **jeder** ihrer 28 Aufrufstellen als undefiniert -- ueber
sieben Dateien verteilt, weshalb es wie ein Streuproblem aussah und keins war.
Jetzt eine benannte `PdfPort.Notifier`-Klasse.

Dieselbe Falle wie fileops.nvims `on_before_delete?: fun(path: string):
boolean|nil` am Tag zuvor. Es ist damit das zweite Repo, in dem eine einzige
nicht parsende Annotation zweistellig viele Befunde erzeugt hat -- der
Posten lohnt eine eigene Suche ueber die restlichen Repos.

---

#### Acht weitere: dasselbe, andersherum

```lua
---@return string|nil  pdf_path, or nil if cursor is not on a PDF
```

Ohne Namen liest LuaLS `pdf_path,` als den Namen und `or` als **zweiten
Rueckgabetyp**. `M.current_pdf_path` musste damit zwei Werte liefern, und alle
acht `return`-Zeilen in `integrations/init.lua` „fehlte" einer. Dieselbe Form
wie gopaths `---@return GopathResult|nil, string|nil` und fileops'
`---@return string[]  Absolute, canonicalized paths.` -- dreimal an drei Tagen,
immer dieselbe Ursache: **eine `@return`-Zeile, die als zwei gelesen wird.**

---

#### Und acht: zwei Doc-Bloecke uebereinander

Ein Merge-Ueberbleibsel in `M.open`, in `core/dispatcher.lua` **und** in
`init.lua`. Der erste Block trug das typisierte `opts` und die Prosa zu
`on_error`, der zweite ergaenzte `on_done` und weitete `opts` wieder auf
`table`. Jetzt je ein Block, mit beiden Haelften. Dasselbe Muster wie in
emojis' `search.M.run`.

---

#### Der Rest -- fuenf kleine Ursachen

- **`dispatch()` las `opts.path` viermal neu.** `ExtractOpts.path` ist
  optional, `OpenOpts.path` nicht -- also war jede Lesestelle vielleicht-nil,
  obwohl das `assert` am Funktionsanfang die Frage laengst beantwortet hatte.
  Einmal gebunden.
- **Die `system`- und `terminal`-Zweige** reichen `opts` an einen Renderer
  weiter, der `RenderOpts` will. Diese Zweige *sind* die `OpenOpts`-Haelfte der
  Union; das steht jetzt als `---@cast` da -- dieselbe Begruendung, die die
  `--[[@as PdfPort.OpenOpts]]`-Casts zwanzig Zeilen weiter unten schon tragen.
- **`vim.tbl_deep_extend`** typisiert seinen Rueckgabewert als Union seiner
  Argumente. Das `---@type` auf der Bindung wurde deshalb gegen
  `PdfPort.Config|PdfPort.CreateOpts|nil` geprueft, statt das Ergebnis zu
  beschreiben. Ein `---@cast` **nach** dem Aufruf, in composer und dispatcher.
- **`pages` in ollama und tesseract**: bar deklariert, von drei Zweigen
  gefuellt und dann in einer Closure gelesen, die von dieser Verengung nichts
  mitbekommt -- und `opts.pages` wurde direkt hineingeschrieben, was die
  Feldpruefung ebenfalls nicht mittraegt. Der Vorgabewert ist jetzt der
  Initialisierer, das Feld geht ueber ein lokales.
- **`uv.fs_realpath`** hat eine asynchrone Ueberladung, die ein Request-Handle
  liefert; sein Typ ist `string|uv.uv_fs_t`. markers blosser Wahrheitstest
  liess die Handle-Haelfte in `tmp_dir` landen.

---

#### Der Befund, der erst beim dritten Lauf kam

Die `marker.lua`-Stelle stand weder im Vorher-Lauf noch in den ersten beiden
Nachher-Laeufen, obwohl die Datei die ganze Zeit unveraendert war. Sie tauchte
erst auf, als ollama und tesseract sauber wurden.

Praktisch heisst das: **ein einzelner Nachher-Lauf beweist keine Null.** Der
Vergleich sagt zwar zuverlaessig, ob etwas *schlechter* geworden ist, aber
„0" beim ersten Versuch kann heissen, dass ein Befund noch nicht an der Reihe
war. Hier wurde deshalb zweimal gemessen, und beide Laeufe sagen 0. Fuer die
naechsten Durchgaenge gilt dasselbe.

---

Unterdrueckt, mit Begruendung: sechs absichtlich falsch getypte Werte in den
Specs (ein nil-Seitenbereich, zwei `available`-Felder, die keine Funktion
sind, drei Renderer-Modi ausserhalb des Alias), wo das Zurueckweisen statt
Werfen genau das ist, was geprueft wird.

---

### neotree-fs-refactor.nvim -- ausserhalb des Umfangs, versehentlich bearbeitet

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 12)*

> **Dieses Repo gehoert nicht dazu.** Es steht nicht auf der Plugin-Liste in
> Abschnitt 0 des Reports; es hat nur eine `.luarc.json` und wurde deshalb vom
> Scan als Workspace gefuehrt. Der Durchgang unten ist gemacht und gepusht,
> zaehlt aber gegen keine Summe -- und der Offen-Punkt, der ihn ausgeloest hat,
> haette gar nicht dort stehen duerfen. Die Liste in Abschnitt 0 steht seit
> dem 2026-09-01 da, damit das nicht wieder passiert.

Das Repo setzte weiterhin `workspace.library` selbst -- `${3rd}/luv/library`
und `$VIMRUNTIME/lua`, sonst nichts. Der Schluessel **ersetzt** die Injektion
von lsp.nvim, er ergaenzt sie nicht, also war hier jeder Plugin-Typ und auch
luassert unsichtbar. Die 0, die der Report fuer dieses Repo fuehrte, hiess
„nichts wurde geprueft", nicht „nichts ist kaputt". Dieselbe Korrektur wie bei
den sechs Repos im August; dieses war das uebrig gebliebene.

Auf der korrigierten Grundlage: **4**, und beide Ursachen sind Namenskollisionen.

- `LogLevel` kollidiert mit dem Alias, den lib.nvims notify-Modul
  veroeffentlicht -- eine andere Sache (eine Zahl oder ein String, nicht diese
  vier Werte). Namespaced wie die uebrigen Typen des Repos.
- `tests/@types.lua` deklariert eine eigene `Luassert`-Klasse. plenary.nvim
  liefert eine oeffentliche mit denselben drei Container-Feldern, die Kopie ist
  also eine Dopplung und keine Ergaenzung. Sie heisst jetzt wie das, was sie
  ist: ein privater Platzhalter.

**4 -> 0**, `worse: nothing`. Beides sind Annotationen -- ausserhalb von
Kommentaren hat sich nichts geaendert, und das Plugin laedt unveraendert.

Zwei Nebenbefunde, die dabei aufgefallen sind und nicht angefasst wurden:

- **`stylua` ohne `stylua.toml`.** 30 der 32 Repos haben eine;
  `neotree-fs-refactor.nvim` und `learn-cli.nvim` nicht. Ohne Konfiguration
  formatiert stylua mit **Tabs**, die Dateien beider Repos sind aber
  zweispaltig eingerueckt -- ein `stylua .` dort schreibt also das ganze Repo
  um. Beim ersten Versuch genau das passiert und wieder verworfen.
- **`tests/run_tests.sh` meldet „All tests passed" auch dann**, wenn
  `plenary.test_harness` gar nicht geladen werden konnte: nvim beendet sich
  mit 0, und `set -e` sieht keinen Fehler. Die Suite lief hier deshalb nicht --
  `PlenaryBustedDirectory` startet Kind-Prozesse und haengt auf dieser
  Windows-Maschine headless. Nichts in dem Commit ist zur Laufzeit erreichbar,
  darum wurde er trotzdem gemacht.

---

### Die Sechser-Runde -- fuenf Repos, 126 auf 0

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 3)*

`buffer-ctx` (5), `sessions` (6), `emojis` (13), `fileops` (35) und `gopath`
(67): die Repos, deren `.luarc.json` im August die Messgrundlage bekam und die
danach nie durchgegangen wurden. **126 -> 0** ueber alle fuenf,
`worse: nothing`, jede Suite gruen, stylua sauber. Fuenf Commits, einer pro
Repo.

Ein Muster zieht sich durch: **die interessanten Befunde sind Aufrufe, die nie
funktioniert haben koennen** -- dieselbe Familie wie `get_node_at_line` und
`node.line` in filetree.nvim.

---

#### fileops: zwei Tastenkuerzel, die nichts gesagt haben

`<leader>fR` (bulk rename) reichte das Paar `(renamed, err)` von
`bulk.execute` an `notify.report(ok, msg)` weiter. Die Zahl ging als `ok`
hinein, `nil` als Nachricht -- und `report` gibt nichts aus, wenn die Nachricht
nil ist. Das Kuerzel meldete also weder „12 Dateien umbenannt" noch, woran es
gescheitert war; der `:File bulk`-Pfad direkt daneben meldete beides. Jetzt
mit demselben Wortlaut.

Das lockinfo-Kuerzel rief `ops.file.diagnose_lock()` ohne Argumente.
`diagnose_lock` ist asynchron und nimmt den Callback als **erstes, notwendiges**
Argument -- die Taste warf also, statt etwas zu melden. Sie geht jetzt ueber
den oeffentlichen Einstiegspunkt, der den notify-Callback mitbringt.

Und `cfg.bulk` ist kein Konfigurationsabschnitt und war nie einer: beide
Lesestellen im bulk-Kuerzel ergaben immer `{}`. Genau das steht jetzt da, damit
es nicht mehr aussieht wie eine Einstellung, die jemand setzen koennte.

Dazu zwei Annotationen, die nicht geparst haben -- und alles, was darunter
stand:

- `on_before_delete?: fun(path: string): boolean|nil` **innerhalb** eines
  Tabellen-Typs verschluckt den Rest des Literals. LuaLS bleibt bei
  „`}` expected" stehen, und `refresh_explorers`, `git_aware`,
  `git_warn_only`, `git_cmd` und `retry` lesen sich danach als undefinierte
  Felder. Klammern drumherum.
- `---@return string[]  Absolute, canonicalized paths.` liest die Beschreibung
  als zweiten Rueckgabetyp, also musste `list_files` zwei Werte liefern. Der
  Rueckgabewert hat jetzt einen Namen, damit die Prosa Prosa bleibt.

---

#### gopath: ein Ergebnis, das gelogen hat

`make_result` versprach eine Tabelle fuer einen `path`, den `pick_best` bei
leerer Liste als nil beantwortet. Es baute sie trotzdem: `path = nil` neben
`exists = true` -- ein Ergebnis, das behauptet, an nirgendwo liege eine Datei.
Es gibt jetzt nil zurueck, wofuer jeder Aufrufer ohnehin einen Zweig hat. Sechs
Befunde, eine echte Luege.

Zwei Annotationen trugen den groessten Teil des Rests. `---@return
GopathResult|nil, string|nil  result, error` **in einer Zeile** sind fuer LuaLS
nicht zwei Rueckgabewerte -- es las drei, also fehlte elf `return a, b`-Zeilen
in `resolve.lua` je einer, und `error` las sich als undefinierter Typ. Und
`GopathResolveOpts` war zweimal deklariert, einmal in `resolve.lua` und einmal
in `@types/resolvers.lua`.

`providers.treesitter.node_at_cursor` gab `userdata|nil` zurueck -- genau der
Befund, den documentation.nvims eigener Durchgang hatte. Der Typ heisst
`TSNode`, und ohne ihn hatte `node:type()` keine Methode zum Auflaesen.

---

#### buffer-ctx: eine API, die seit 0.11 anders heisst

`get_char_at_pos` rief `vim.str_utfindex` und `vim.str_byteindex` in der
Zwei-Argument-Form von vor 0.11. Seit 0.11 nehmen beide an zweiter Stelle eine
**Kodierung** -- der Byte-Offset landete also dort, wo `"utf-8"` hingehoert.
`vim.str_utf_end` beantwortet die eigentliche Frage (wie viele Bytes bis zum
Ende der Sequenz, zu der dieses Byte gehoert) in einem Aufruf, ab 0.9, ohne
Kodierungsargument. Der `if not char_idx`-Guard, den es ersetzt, war tot:
`str_utfindex` wirft bei einem Index ausserhalb des Strings, statt nil zu
liefern.

---

#### Der Rest, und was sich wiederholt

- **Cluster E, dritte bis fuenfte Wiederholung:** 4 in sessions, 16 in fileops,
  2 in gopath, 1 in emojis (dort lib.nvims Keymap-Modul, eine aufrufbare
  Tabelle -- fuer den Typpruefer kein `function`, auch wenn
  `vim.is_callable` ja sagt).
- **Zwei gestapelte Doc-Bloecke** in `emojis.search.M.run`, ein
  Merge-Ueberbleibsel: `action` und `extra_globs` zweimal deklariert,
  `no_ignore` unter der zweiten Kopie.
- **`AST.parse` gibt `(root, src)` zurueck**, und zwei gopath-Aufrufer prueften
  nur `root` -- elf Aufrufe reichten danach eine Vielleicht-nil-Quelle weiter.
- **Feldverengung traegt nicht in eine frische Lesestelle:**
  `:GopathDebug` pruefte `info.cache_info` und las es danach in ein lokales;
  dreizehn Zeilen lasen sich deshalb als vielleicht-nil. Erst das lokale, dann
  die Pruefung darauf.
- **`LogLevel`** kollidiert auch in gopath mit lib.nvims Alias. Namespaced.

Unterdrueckt, mit Begruendung: `vim.lsp.get_active_clients` in gopaths
health.lua (der Pfad vor 0.10, nur erreichbar wenn `get_clients` fehlt), fuenf
Test-Doubles, und vier absichtlich ungueltige Eingaben, bei denen das
Zurueckweisen genau das ist, was geprueft wird.

---

### runtime-analysis.nvim -- 109 auf 0, und die Hinweise, die niemand sah

*(war: Diagnostics-Report Abschnitt 0, „Vorschlag naechster Schritt" und Offen-Punkt 2)*

Der sechste vertikale Durchgang. **109 -> 0**, `worse: nothing`, alle 25 Specs
gruen, stylua sauber. Das groesste Repo, das seit dem Erstscan unangetastet
war -- und es waren vier Posten mit je einer Ursache statt hundert Einzelfaelle.

---

#### Derselbe Fehler wie in documentation.nvim

`vim.health.info` nimmt eine Nachricht und sonst nichts; `warn` und `error`
sind die, die Hinweise nehmen. Vier `h_info(msg, { ... })`-Aufrufe hier gaben
ein zweites Argument mit, das `:checkhealth` fallen liess: mdviews
Fallback-Notiz, pdfports zwei und die von lib.nvim.progress. Derselbe Wrapper
wie in documentation.nvims `editor/health.lua`, aus demselben Grund.

---

#### `uv_tcp_t` ist kein Typ

Er heisst `uv.uv_tcp_t`. Fuenf Test-Helper annotierten ein Server-Handle mit
dem Namen, der nicht aufloest -- und deshalb las sich jedes `server:close()`
danach als undefiniertes Feld. **Fuenfzehn `close`-Befunde und zehn
Annotationsbefunde waren ein falsches Praefix.** Die Handles selbst sind jetzt
`assert(uv.new_tcp())`: `new_tcp` kann nil liefern, und ein nil-Handle fiel
vorher erst zwei Zeilen spaeter bei `bind` auf.

---

#### Zwei Zeilen, die nie geschrieben wurden

`_cache_opts` und `_snapshot_retention` werden auf jede Telemetrie-Instanz
gesetzt und aus drei Dateien gelesen, und `RA.Telemetry.Instance` deklarierte
keins von beiden. Zwoelf Befunde, ein fehlendes Zeilenpaar.

---

#### Der Rest -- zehn kleine Ursachen

- **Zehn `notify.error(err)`** reichen den zweiten Rueckgabewert eines
  fehlgeschlagenen Aufrufs durch, also ein `string?`. Jeder hat jetzt eine
  Ersatznachricht -- was der Leser auch statt eines leeren Fehler-Popups
  bekommt.
- **`runner`s `(ok, resp)`-Vertrag** -- `resp` ist die Fehlermeldung, wenn
  `ok` falsch ist, und die Antwort, wenn es wahr ist -- stand an zwei Stellen
  in Prosa da und ist jetzt an beiden ein `---@cast`.
- **`flamegraph.svg`** liest `order`, `roots` und `total_ms` und sonst nichts,
  nimmt also `RA.Telemetry.Startup.Drawable` (aus `Startup.Report`
  herausgeloest, das jetzt davon erbt). Ein Aufrufer muss `running` und
  `modules` nicht mehr faelschen fuer eine Funktion, die nie hinsieht.
- **`provenance.inspect`** gab ein zwoelfteiliges Inline-Tabellenliteral
  zurueck, das von `RA.Provenance.Info` abgedriftet war -- `proc_trace` stand
  auf dem Wert und in keinem von beiden.
- **`usage.mode_key`** versprach `string` und lieferte `string|string[]`;
  `record_command` und der Keymap-Wrapper riefen ueber Handles, die ausserhalb
  einer laufenden Sitzung nil sind.
- **`os.date(...)`** ist `string|osdate`; zwei Snapshot-Namen sagen, welches.
- **`inspect`** baut einen Report, indem es `module_id` an einen gelaufenen
  Knoten haengt -- was der Report *ist*: ein `---@cast` statt eines injizierten
  Feldes.
- **`_G.require`** wird vom Startup-Recorder absichtlich ersetzt; das ist der
  ganze Mechanismus, und es ist mit der Begruendung unterdrueckt.
- **Zwei `M.x = local_fn`-Exporte** trugen `---@param`-Zeilen, die an einer
  Zuweisung an nichts andocken. Jetzt `---@type fun(...)`.
- **`export()`s `.pdf`-Zweig** braucht den Callback, den sein eigener Doc-Text
  als notwendig bezeichnet.

Unterdrueckt, mit Begruendung: vier absichtlich ungueltige Eingaben in den
Specs (ein nil-Namespace, eine Nicht-Tabelle als Kandidatenliste, eine nil
Modul-Id, ein Stil ausserhalb des Alias). Zwei Test-Fixtures nehmen `...`, weil
die Aufrufe darunter ihnen Argumente uebergeben.

---

### filetree.nvim -- 80 auf 0, und vier Dinge, die nie liefen

*(war: Diagnostics-Report Abschnitt 0, „Vorschlag naechster Schritt" und Offen-Punkt 1)*

Der fuenfte vertikale Durchgang, und der letzte Rest des Repos. **80 -> 0**,
`worse: nothing`, alle fuenf Suiten gruen (19 + 252 + 15 + 122 + 54 Checks,
0 failed), stylua sauber. Damit ist filetree.nvim das dritte Repo auf Null --
nach documentation.nvim und lib.nvim, und diesmal ohne Sternchen.

---

#### Der Einstieg war der vorgeschlagene, und er trug 24

`FiletreeConfig` markierte alle vierzehn Felder optional, obwohl `setup()`
neun davon aus `config.DEFAULTS` normalisiert. Jeder Leser hinter `setup()`
pruefte damit noch einmal, was `setup()` bereits garantiert hatte. Der Split
ist derselbe wie bei `LspNvim.Config` einen Tag zuvor:

- `FiletreeConfig` -- die **aufgeloeste** Gestalt, wie `config.get()` sie
  zurueckgibt: die neun aus DEFAULTS als Pflichtfelder, die fuenf, die
  niemand fuellt (`keymaps`, `adapter_keymaps`, `command`, `autocmds`,
  `confirmations`), bleiben optional. Das ist die ehrliche Zeile: nicht
  „alles da", sondern „genau das, was DEFAULTS traegt".
- `FiletreeOpts` -- die partielle Gestalt, die ein Aufrufer uebergibt.

Dasselbe fuer `FiletreeCwdModeConfig`/`FiletreeCwdModeOpts`. Dort war die
Wirkung am sichtbarsten: `indicator` als optional zu fuehren machte
`_cfg.indicator` an **fuenf** Stellen innerhalb einer einzigen Funktion
(`badge_text`) zu einem Vielleicht-nil.

Ein Nebenbefund des Splits: `config.get()` gab vor `setup()` `{}` zurueck,
obwohl jedes Feature-Modul es liest, als stuenden die Defaults. Es startet
jetzt auf einer Kopie von DEFAULTS.

Und ein Fehler, den der Split erst erzeugt und dann sichtbar gemacht hat:
`FiletreeCwdModeConfig` liess sich nicht mehr an ein `FiletreeCwdModeOpts?`
zuweisen. Die aufgeloeste Klasse erbt jetzt von der partiellen, was auch die
richtige Aussage ist -- ein aufgeloester Wert *ist* ein zulaessiger Eingabewert.

---

#### Vier Stellen, die nie gelaufen sein koennen

Dieselbe Familie wie `get_node_at_line` im vierten Durchgang: nicht
Annotationen, die hinterherhinken, sondern Code, der auf etwas zeigt, das es
nicht gibt.

- **`find_files`** bewachte sein Reveal mit `_adapter.reveal`. `reveal` ist
  kein Adapter-Member und war nie eines -- die Bedingung war immer falsch.
  `reveal_on_open` steht standardmaessig auf `true` und hat nie etwas
  aufgedeckt. Die Faehigkeit heisst `open_reveal`, und jedes Backend im Repo
  hat sie.
- **`live_search`** las `node.line`. Das Feld heisst `line_number`. Der Guard
  davor (`if not node.path or not node.line then goto continue end`) griff
  also fuer **jeden** Knoten: die Overlay-Suche hat nie etwas hervorgehoben
  und nie etwas abgedunkelt.
- **`preview`s snacks-Backend** rief `snacks.image.open()`. Die Funktion gibt
  es in snacks.nvim nicht (`supports`, `supports_file`, `hover`, `setup` --
  kein `open`). Der Aufruf lief in einem `pcall`, warf bei jedem Bild und fiel
  durch. snacks.image zeichnet einen Bildpuffer, wenn einer angezeigt wird;
  `supports()` ist die oeffentliche Frage danach, und die Datei zu oeffnen ist
  das, was snacks zustaendig macht.
- **`refs`' Provider-Klasse** deklarierte weder `lsp_exempt` noch
  `delete_target` -- die beiden Felder, die der markdown- und der lua-Provider
  setzen und die `refs` liest. Hier war nur die Deklaration unvollstaendig,
  der Code stimmte.

---

#### Cluster E, filetree.nvims ganzer Anteil

Fuenfzehn `pcall(vim.cmd, ...)` sind jetzt Closures. `vim.cmd` ist eine
aufrufbare Tabelle, kein `function` -- dieselbe Form wie in lib.nvim (10) und
lsp.nvim (4). Damit sind von den urspruenglich 60 noch 31 offen, verteilt auf
die uebrigen Repos.

---

#### Der Rest -- neun kleine Ursachen

- **Zehn Debounce-Handles** werden vor `.call()` geprueft. Sie werden in
  `setup()` gebaut; die Aufrufer sind Autocmd-Callbacks, die es ohne `setup()`
  nicht gaebe -- eine Invariante, die LuaLS nicht sehen kann und die ohne
  `setup()` ein echter Laufzeitfehler waere.
- **Fuenf `pcall(require, ...)`-Ergebnisse** pruefen jetzt den Wert statt des
  Flags. Dasselbe Muster wie in lib.nvim, lsp.nvim und im vierten Durchgang,
  hier zum vierten Mal.
- **`FiletreeRootFinder`** war in `cwd_sync` und `path_copy` zweimal von Hand
  deklariert -- eine Kopie von lib.nvims `Lib.Fs.FindRoot`, die inzwischen
  existiert. Beide Kopien sind weg, beide `cast-local-type` damit auch.
- **`_badge` und `_float`**: beide werden im „Fenster hat gewechselt"-Zweig
  gesetzt und danach beschrieben. Ein gescheitertes `attach` verlaesst den
  Zweig aber ohne Segment, also ist die Pruefung danach richtig und nicht nur
  ruhigstellend.
- **`termopen()`** ist seit 0.11 veraltet; `jobstart(cmd, { term = true })`
  tut dasselbe. Der README verspricht 0.8, also steht der alte Aufruf hinter
  einem `has("nvim-0.11")` -- und nur dort unterdrueckt, wo die Veraltung der
  Punkt ist.
- **`pdf_open`s fuenf Keymap-Felder** sagen jetzt `string|false`, weil genau
  das drinsteht: `false` ist im Keymap-Registry die Abschaltung, nicht ein
  falscher Typ. Die Klasse war falsch, nicht der Code.
- **`tree_integrity`** liest nuis internen Knoten-Speicher. nui liefert keine
  Annotationen, also traegt der Speicher jetzt eine eigene Klasse
  (`FiletreeNuiNodeStore`) mit den zwei Feldern, die dieses Feature begeht --
  statt als nacktes `table` gelesen zu werden, an dem `root_ids` dann
  undefiniert ist.
- **Zwei `gsub`-Rueckgaben** in Klammern (`gsub` liefert `(str, count)`), ein
  `@return string|nil`, wo `nil` rein und `nil` raus geht, und zwei Guards
  (`python`s `rest`, `ts_js`' `e`), die ihren zweiten Rueckgabewert nicht
  mitgeprueft haben.

---

#### Zweimal die Regel angewandt, die es dafuer gibt

„Kein Fix, der eine Warnung nur verschiebt": der erste Nachher-Lauf stand bei
8 statt 0. Beides waren eigene Verschiebungen -- ein `---@type string?` auf
`dst` in `move`, das sieben neue `param-type-mismatch` erzeugte (jetzt ein
`skip`-Flag statt `dst = nil`), und eine Enum-Verengung in
`create_from_template`, die LuaLS ueber `==` nicht mitgeht (jetzt ein
`---@cast`). Der zweite Lauf stand bei 0.

---

#### Unterdrueckt, mit Begruendung

Eine Stelle: ein absichtlich ungueltiger Scope in `TESTS/cwd_mode.lua`, wo das
Zurueckweisen genau das ist, was geprueft wird. Die fuenf Test-Doubles geben
stattdessen den Boolean zurueck, den ihre Annotation verspricht -- das ist
kein Zugestaendnis an den Linter, sondern die Signatur, die der echte Adapter
auch hat.

---

#### Was uebrig ist

Nichts in diesem Repo. Was aus dem vierten Durchgang stehen blieb, bleibt
stehen: `get_node_at_line` und die drei anderen Adapter-Faehigkeiten sind
deklariert, von keinem Backend implementiert, und fuenf Features warten
darauf. Das ist eine Designfrage und kein Diagnose-Befund -- Offen-Punkt 4 im
Report.

---

### filetree.nvim -- 161 auf 80, und fuenf Features, die nie rendern

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

Der vierte vertikale Durchgang. **161 -> 80**, `worse: nothing`, alle fuenf
Suiten gruen (19 + 252 + 15 + 122 + 54 Checks, 0 failed), stylua sauber.

`undefined-field` war mit 60 der groesste Einzelposten der ganzen Verteilung --
und es war kein Annotationsproblem.

---

#### `get_node_at_line` ruft niemand auf, weil es niemand hat

Fuenf Feature-Module rufen `_adapter.get_node_at_line`. **Kein einziger der
fuenf Adapter implementiert es.** Alle fuenf haben dieselbe Form:

```lua
vim.api.nvim_buf_clear_namespace(bufnr, _ns, 0, -1)
if not _adapter.get_node_at_line then return end   -- immer wahr
```

Also: Namespace leeren, zurueckkehren. Betroffen sind `git_status`,
`lsp_diagnostics`, `copy_move`, `search.filter` und `ui.size_info` -- Git-
Zeichen, Diagnose-Marker und Dateigroessen erscheinen **nie** im Baum. Dreissig
der sechzig Befunde waren dieser eine Aufruf.

Dieselbe Geschichte im selben Feature-Bereich: `org.session` fragt nach
`get_expanded_paths` und `expand_paths`, beide nirgends implementiert -- eine
Session speichert und stellt also keinen Expansionszustand wieder her.

---

#### Ein Wort: `get_root` gegen `get_root_path`

`org.session` schrieb

```lua
local root = _adapter.get_root and _adapter.get_root() or nil
```

Jeder Adapter schreibt die Methode `get_root_path`, und hat das immer getan.
Der kurze Name war also nil, der `and`/`or`-Ausdruck fiel auf `nil` zurueck,
und **jede gespeicherte Session hat `root = nil` aufgezeichnet**. Behoben.

---

#### Deklariert, nicht implementiert -- und das steht jetzt da

Die vier Faehigkeiten (`get_node_at_line`, `get_expanded_paths`,
`expand_paths`, dazu `install_reveal_guard`, das immerhin der neo-tree-Adapter
hat) stehen jetzt im Optional-Abschnitt von `FiletreeAdapter`, mit einem
Vermerk im Kopf: kein Backend hat sie, der aufrufende Code ist geschrieben und
wartet.

**Sie zu implementieren ist ein Feature, kein Diagnose-Fix.** Fuenf Adapter um
eine Zeilen-zu-Knoten-Abbildung zu erweitern ist eine Designfrage (neo-tree
und nvim-tree haben interne Zeilenindizes, oil und netrw parsen ihren eigenen
Puffer), keine Aufraeumarbeit. Das gehoert entschieden, nicht nebenbei
erledigt -- siehe den offenen Punkt im Report.

---

#### Der Rest

- `features.load()` gibt `(ok, mod|nil)` zurueck, und `tree_reset` pruefte
  `ok`, bevor es ein Feld von `mod` las. Der Guard muss auf dem Wert sitzen,
  der danach gelesen wird -- dasselbe Muster wie in lib.nvim und lsp.nvim, hier
  zum dritten Mal.
- Die zwanzig `duplicate-set-field` sind ausnahmslos Test-Doubles: eine
  Stdlib-Funktion, ein `package.loaded`-Eintrag oder eine Plattform-Probe wird
  fuer die Dauer eines Falls ersetzt und direkt danach zurueckgesetzt.
  Unterdrueckt pro Zeile, mit der Begruendung als Kopf-Notiz in jeder der drei
  Dateien statt zwanzigmal wiederholt.
- `file_watcher`s Debounce-Handle ist bis `setup()` nil und wurde ungeprueft
  gelesen. `tree_integrity` laeuft ueber nuis eigenes `root_ids`, das
  upstream keine Annotation traegt.

---

#### Was uebrig ist: dieselbe Form wie in lsp.nvim

80 Befunde, davon `need-check-nil` 33 und `param-type-mismatch` 21. Der
Hauptteil hat eine Ursache, und es ist die, die lsp.nvim gerade hinter sich
hat: `FiletreeCwdModeConfig` und seine Geschwister markieren jedes Feld
optional, obwohl `setup()` sie normalisiert. `cwd_mode` (8) und `config/init`
(5) lesen also garantierte Werte als vielleicht-nil.

Derselbe Split wie bei `LspNvim.Config`: eine aufgeloeste Klasse mit
Pflichtfeldern, eine partielle fuer den Aufrufer. Das ist der naechste Schritt
in diesem Repo.

---

### lsp.nvim -- 172 auf 35, und die Typen, die es hier nie gab

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

Der dritte vertikale Durchgang. **172 -> 35**, `worse: nothing`, Suite gruen
(395 Assertions, 0 Failed, 0 Errors), stylua sauber.

Die interessante Haelfte waren Annotationen, die auf Typen zeigten, die es in
diesem Repo nicht gibt. Sie loesten trotzdem auf -- gegen eine Kopie eines
aelteren lsp.nvim, die in einem git-Worktree unter `.claude/` der nvim-Config
lag und auf dem Library-Pfad jedes Workspace stand. `lsp/languages/**` und
`lsp/formatter` wurden also gegen eine Version ihrer selbst geprueft. Mit der
Kopie draussen (siehe den Eintrag darueber) kamen sie als
`undefined-doc-name` heraus.

---

#### Ein echter Fehler: `:LspLuaLsReload` hat den Server nie benachrichtigt

`servers/lua_ls/reload.lua` rief

```lua
client.notify("workspace/didChangeConfiguration", { settings = ... })
```

`notify` ist eine **Methode** -- `Client:notify(method, params)`. Der
Methodenname ging also als `self` hinein, die Params als `method`, und der
Aufruf ist jedes Mal innerhalb von `Client:notify` gescheitert: die
Settings-Tabelle wurde aktualisiert, der Server nie informiert. Zwei Dateien
weiter macht `core/workspace_diagnostics.lua` es zweimal richtig, einmal als
`client:notify(...)` und einmal als `client.notify(client, ...)`.

Gemeldet war das als `missing-parameter` -- "diese Funktion braucht 3
Argumente, bekommt 2". Dritte Regel in dieser Arbeit, die von aussen wie
Kosmetik aussieht und einen kaputten Codepfad verdeckt hat.

---

#### Die drei Typdateien

**`lsp/languages/@types`** deklariert die fuenf
`ConfiguredLangs.Literal.*`-Unions und die zehn `*.Module`-Namen. Alle zehn
Sprachmodule exportieren genau `enable()`, also sind es Aliase auf eine
`ConfiguredLangs.Module` statt zehn Kopien derselben Form. Die Literal-Unions
bleiben literal, weil `enable_all()` aus jedem Eintrag einen `require`-Pfad
baut: ein Tippfehler dort ist ein Modul, das still nie laedt.

**`lsp/formatter/@types`** deklariert `FormatterOptions`, `FormatterState` und
`FormatterApi` -- abgelesen an dem, was `build()` tatsaechlich annimmt,
behaelt und zurueckgibt.

**`@types/vim_lsp.lua` ist geloescht.** Sie deklarierte sieben
`vim.lsp.*`-Klassen als "missing from Neovim's builtin types"; Neovim 0.12
fuehrt alle sieben, also war jedes Feld darin ein Duplikat des echten. Dazu
machten ihre `---@class vim.lsp` und `---@class vim.lsp.buf` die Modultabellen
wieder auf. 30 `duplicate-doc-field`.

---

#### `LspNvim.Config` sagte das eine und deklarierte das andere

Der Klassenkommentar liest sich als "jedes Feld unten ist garantiert vorhanden
und gueltig" -- darunter zwanzig Felder mit `?`. Dasselbe Muster wie
`Composer.DocsOpts` in lib.nvim, nur groesser.

Getrennt: `LspNvim.Config` ist die aufgeloeste Form mit Pflichtfeldern,
`LspNvim.Opts` die partielle, die die beiden `setup()`-Eingaenge nehmen.
`LspNvim.Tools`/`LspNvim.Tool` und `LspNvim.Workspace` tun dasselbe fuer die
zwei verschachtelten Tabellen, die `normalize_switch` beziehungsweise
`normalize_workspace` garantieren und deren Leser sich darauf verlassen.

Und `completion` steht seit dem 2026-08-23 in `DEFAULTS.lua` und stand in
keiner einzigen Klasse -- daher las sich `cfg.completion` an beiden
Aufrufstellen als undefiniertes Feld. Jetzt `LspNvim.CompletionOpts`.

---

#### Eine Vermutung, die beim Hinsehen gefallen ist

Die dreizehn `redundant-parameter` in `TESTS/lsp/completion_spec.lua` sahen
nach der luassert-Luecke aus, die lib.nvims `@types/luassert.lua` beschreibt --
es waren aber gar keine. `with_temp_state` ist als `---@param fn fun()`
annotiert und ruft seinen Callback mit `pcall(fn, fresh, store)`. Ein Blick in
die Funktion statt in die Regel hat das in einer Minute geklaert.

(Die luassert-Luecke gibt es trotzdem: lib.nvim weitet acht Assertion-Namen
auf, lsp.nvim benutzt zusaetzlich `are.equal` 237-mal, `are.same` 97-mal und
`is_string`. Nach der luassert-Zeile in der Injektion fielen davon nur fuenf
`redundant-parameter` weg. Das gehoert nach lib.nvim und steht als
Offen-Punkt.)

---

#### Der Rest

- `has_eslint`/`has_prettier` nehmen laut ihrer eigenen ersten Zeile ein
  `nil`-Root entgegen; die Annotation sagte `string`.
- `usage.load()` gibt die Tabelle jetzt zurueck, statt sie nur in ein Upvalue
  zu schreiben, das kein Aufrufer als gefuellt sehen kann.
- Acht `@param`-Namen hatten den Unterstrich-Praefix des echten Parameters
  nicht mitbekommen (`err` gegen `_err`).
- Vier `pcall(vim.cmd, ...)` sind Closures (Cluster E, lsp.nvims Anteil).
- `handlers.lua` bindet die Payload vor dem Guard statt danach.

Unterdrueckt, mit der Begruendung daneben: acht Stdlib-Doubles in den Specs
(jeweils direkt danach zurueckgesetzt), drei absichtlich kaputte Config-Werte
in `smoke.lua`, und der Zwei-Argument-Zweig von `setloclist`, den zur Laufzeit
ohnehin eine Probe absichert.

---

#### Was uebrig ist: 35, und sie sind einzeln

Keine Regel mehr ueber 12. `param-type-mismatch` 12, `assign-type-mismatch` 7,
je 3 `missing-fields`, `deprecated`, `inject-field`, je 2 `need-check-nil`,
`invisible`, `return-type-mismatch`, 1 `redundant-parameter`.

Zwei Posten lohnen eine eigene Entscheidung:

- **`LspMod.Client` / `LspMod.TextDocumentIdentifier`** in
  `@types/subsystem.lua` sind Parallel-Deklarationen zu Neovims
  `vim.lsp.Client` und `lsp.TextDocumentIdentifier`. Solange `vim_lsp.lua`
  danebenlag, ist das nicht aufgefallen; jetzt kollidieren sie in
  `languages/webdev/typescript.lua` dreimal. Die Frage ist nicht, wie man die
  drei wegannotiert, sondern ob `LspMod.*` ueberhaupt noch etwas beschreibt,
  das Neovim nicht selbst fuehrt.
- **`integrations/trouble.lua`** greift auf
  `vim.treesitter.highlighter._on_win` zu -- privates Upstream-Feld, im Report
  seit dem Erstscan als "bekannt riskant, aber bewusst; gehoert dokumentiert
  statt behoben" vermerkt. Die zwei `invisible` und ein `inject-field` gehoeren
  dorthin.

---

### Die Messgrundlage, zweiter Teil -- luassert, und 180 Befunde, die keinem Repo gehoerten

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

Angefangen als Ein-Zeilen-Punkt: `${3rd}/luassert/library` fehlte in
`lsp.nvim`s `build_library.lua`, und deshalb blieb in lib.nvim genau ein
`undefined-doc-name` stehen. Die Zeile ist drin, lib.nvim steht auf **0**, und
lsp.nvim verlor dabei 12 Befunde.

Beim Nachmessen des Rests fiel dann etwas Groesseres auf.

---

#### Die Hypothese, die die Messung widerlegt hat

Zuerst sah es aus wie ein Wiedergaenger von `bb66d37`: `build_library` haengt
ueber `find_type_dirs(root)` und zwei weitere Abschnitte die **eigenen
`@types`-Pfade des Workspace** an die Library -- in lsp.nvims Fall sieben
Eintraege. Ein Workspace, der seine eigene Library ist, wird zweimal gelesen;
genau das hat `bb66d37` fuer die runtimepath-Eintraege behoben und dabei 1085
der 1222 Warnungen der Config erklaert.

Der Ausschluss wurde also verallgemeinert (kein Pfad unterhalb von `root`), die
Library schrumpfte von 44 auf 37 Eintraege -- und die Messung ergab **exakt
null Aenderung**. LuaLS dedupliziert einen Library-Pfad, der innerhalb des
Workspace liegt, offenbar von sich aus. Die Aenderung wurde zurueckgenommen:
was nichts bewirkt, gehoert nicht ins Repo, und wer die Idee spaeter wieder
hat, findet hier, dass sie geprueft ist.

---

#### Was es wirklich war: `relatedInformation` fragen statt raten

Der naechste Schritt war, LuaLS selbst zu fragen, wo die *zweite* Definition
liegt. Die JSON-Ausgabe von `--check` fuehrt sie mit:

```
"message": "Duplicate defined fields `ensure_installing`.",
"relatedInformation": [{ "location": { "uri":
  "file:///c%3A/Users/bartl/AppData/Local/nvim/.claude/worktrees/
   filetree-statusline-modes-c96cc9/lua/lsp/%40types/init.lua" }}]
```

Die nvim-Config haelt **elf git-Worktrees** unter `.claude/worktrees/`, jeder
eine volle Kopie von ihr. Der Config-Root ist fuer jedes Repo ein
Library-Eintrag. Und einer dieser Worktrees stammt aus der Zeit **vor** der
Extraktion von lsp.nvim und traegt noch ein vollstaendiges `lua/lsp/**`.

lua_ls las also eine aeltere Kopie von lsp.nvim neben der echten, und jedes
`@class` darin kollidierte mit sich selbst. Ausgezaehlt ueber alle Befunde mit
`relatedInformation` in einen `.claude`-Worktree:

| Repo | Befunde | davon aus einem `.claude`-Worktree |
|---|---:|---:|
| lsp.nvim | 359 | **180** |
| nvim-config | 128 | 3 |
| lib.nvim | 0 | 0 |

157 `duplicate-doc-field` und 23 `duplicate-set-field`. Die Haelfte des Repos.

---

#### Der Schluessel war da, er kam nur nirgends an

`.claude` steht seit jeher in lib.nvims gemeinsamer Ignore-Liste
(`lib.nvim.fs.ignore.list`), und `lsp.servers.lua_ls.ignore.as_luals_patterns()`
macht daraus 124 Muster fuer `workspace.ignoreDir`. Zwei Stellen haben das
ausgehebelt:

1. **Die Messreihe hat `ignoreDir` nie gesetzt.** `mkcfg.py` modellierte von
   der Injektion nur `library`, `runtime.version`, `diagnostics.globals` und
   `checkThirdParty`. Der Kommentar dort sagte, die uebrigen Defaults wuerden
   von den Repos ohnehin ueberschrieben -- was bei `ignoreDir` gerade der
   Befund ist und nicht die Entwarnung.
2. **`.luarc.json` ersetzt auch diesen Schluessel.** Dieselbe Falle wie bei
   `workspace.library` in Cluster A, nur eine Ebene weiter. lsp.nvims
   `.luarc.json` nannte drei Eintraege -- `.git`, `.deps`, `docs/map` -- und
   warf damit alle 124 weg. Zwei der drei Verzeichnisse existieren in dem Repo
   nicht einmal.

Behoben: `dump_library.lua` holt die Musterliste jetzt genauso aus dem
laufenden nvim wie die Library (`DUMP ignoreDir 124 patterns`), `mkcfg.py`
setzt sie, und lsp.nvims `.luarc.json` nennt den Schluessel nicht mehr.

---

#### Gemessen

| Schritt | lsp.nvim | lib.nvim |
|---|---:|---:|
| Ausgangsstand | 371 | 1 |
| `${3rd}/luassert` | 359 | **0** |
| Workspace-Ausschluss (verworfen) | 359 | 0 |
| `ignoreDir` injiziert | **172** | 0 |

`worse: nothing` in jedem Schritt. lsp.nvims Suite gruen (0 Failed, 0 Errors),
stylua sauber.

Nach Regel, im letzten Schritt:

| Regel | Delta | |
|---|---:|---|
| `duplicate-doc-field` | **-143** | 173 -> 30 |
| `redundant-parameter` | -28 | 43 -> 15 |
| `undefined-field` | -26 | 29 -> 3 |
| `duplicate-set-field` | -21 | 29 -> 8 |
| `duplicate-doc-alias` | -5 | 5 -> 0 |
| `undefined-doc-name` | **+19** | 0 -> 19 |
| `assign-type-mismatch` | +8 | 13 -> 21 |
| `param-type-mismatch` | +5 | 27 -> 32 |
| `inject-field`, `need-check-nil` | +4 | |

---

#### Die +36 sind der eigentliche Ertrag

Wie bei der Library-Korrektur im August ist der Zuwachs kein Rueckschritt --
nur diesmal noch deutlicher, weil die verdeckten Befunde benannt sind:

- `Lsp.Languages.ConfiguredLangs.Go.Module`, `.Lua.Module`, `.C.Module`,
  `.Zig.Module`, `.CSharp.Module`, `.Dart.Module`, `.Java.Module`,
  `.Webdev.Astro.Module` und `.Literal.App`
- `FormatterApi`, `FormatterOptions`, `FormatterState`

Diese Typen werden in lsp.nvim referenziert und sind dort **nirgends
definiert**. Sie loesten die ganze Zeit gegen die veraltete Kopie im Worktree
auf -- also gegen einen Stand von vor der Extraktion, der noch nicht einmal
mehr der Wahrheit entsprechen muss. Das ist der Grund, aus dem sich der
Umweg gelohnt hat: nicht die 180, die verschwinden, sondern die 36, die
sichtbar werden.

---

#### Was daraus offen bleibt

Elf Repos und die Config nennen `workspace.ignoreDir` in ihrer `.luarc.json`
und werfen damit dieselben 124 Muster weg: `cmdlog`, `dap`, `debugging`,
`diff`, `filetree`, `neotree-fs-refactor`, `open`, `pdfport`, `recommender`,
`sandbox`. Was das dort kostet, ist ungemessen -- es gehoert vor den naechsten
Gesamtlauf.

Die elf Worktrees selbst bleiben stehen. Mit dem injizierten `ignoreDir` sind
sie fuer LuaLS unsichtbar, das Problem ist entschaerft; ob die veralteten
aufgeraeumt werden, ist eine Frage an den Autor und keine Messfrage. Eine
Session lief waehrend dieser Arbeit selbst in einem davon.

Und eine Korrektur am Report: Abschnitt 1 behauptete, LuaLS indiziere
Punkt-Verzeichnisse nicht, `.claude/` bleibe also aussen vor -- "im Scan-Log
verifiziert". Das gilt fuer den *Workspace*, nicht fuer die *Library*. Der
Satz steht dort jetzt richtig.

---

## 2026-08-31

---

### lib.nvim fertig -- der zweite vertikale Durchgang

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

**273 -> 1.** Ein Repo, ein Commit
([`197a7c7`](https://github.com/StefanBartl/lib.nvim/commit/197a7c7)), 92
Dateien. Anders als bei Cluster F gab es hier keine eine Ursache -- gut zwanzig
kleine, und zwei davon waren echte Fehler.

| Regel | vorher | nachher |
|---|---:|---:|
| `param-type-mismatch` | 108 | 7 |
| `need-check-nil` | 47 | 2 |
| `undefined-field` | 34 | 0 |
| `assign-type-mismatch` | 26 | 0 |
| `redundant-return-value` | 14 | 1 |
| `duplicate-doc-field` | 13 | 0 |
| `undefined-doc-name` | 11 | 1 |
| `return-type-mismatch` | 11 | 2 |
| Rest (12 Regeln) | 9 | 0 |
| **gesamt** | **273** | **1** |

Die Nachher-Spalte ist die Messung *vor* der letzten Korrekturrunde: sie zaehlt
noch die sieben `param-type-mismatch` und den Rest, die der Bestaetigungslauf
danach auf 1 gebracht hat. `worse: nothing` in beiden Laeufen. Suite gruen (42
Specs), stylua sauber.

---

#### Zwei echte Fehler

**`getbufinfo()` liefert kein `filetype` -- und hat das nie getan.**
`buf_win_tab/buffer_utils.lua`s `count_real_listed_buffers` las `b.filetype`
von den Eintraegen, die diese Funktion zurueckgibt. Vim dokumentiert dort
`bufnr`, `changed`, `hidden`, `lastused`, `listed`, `lnum`, `linecount`,
`loaded`, `name`, `signs`, `variables`, `windows` -- kein `filetype`. `ft` war
also immer `""`, und `DEFAULT_EXCLUDE_FILETYPES` mit seinen neun Eintraegen
(neo-tree, quickfix, TelescopePrompt, help, ...) hat **nie einen Buffer
ausgeschlossen**. Die Funktion lieferte damit dasselbe wie
`count_listed_buffers` direkt daneben. `list_listed_buffers_info` meldete aus
demselben Grund fuer jeden Buffer `filetype = ""`.

Der Befund war ein `undefined-field` auf `b.filetype` -- zwei Zeilen, die
LuaLS seit dem Erstscan gemeldet hat. Behoben wird er, indem beide Stellen die
Option am Buffer lesen, so wie `get_buffer_info` nebenan es die ganze Zeit
schon tut.

**Jede Seite eines PDFs teilte sich einen Hover-Cache-Slot.**
`hover/preview/media.lua`s `page_key` war als `page_key(path)` deklariert und
definiert, wurde aber als `page_key(target.path, page)` aufgerufen -- Lua wirft
das zweite Argument still weg. Der Schluessel war `path .. NUL .. mtime`, fuer
jede Seite derselbe. Folge: Seite 2 rendern speicherte ihr PNG unter Seite 1s
Schluessel und `os.remove`te dabei Seite 1s Datei, und ein spaeterer Hover auf
Seite 1 bekam Seite 2s Bild geliefert.

Der Befund war ein `redundant-parameter` -- eine einzelne Zeile, die aussieht
wie Kosmetik.

---

#### Zwei Annotationen, die etwas anderes beschrieben als der Code tut

`hover/registry.lua` deklarierte `contribution.sources` als **eine** Funktion.
`register()` iteriert das Feld seit jeher mit `ipairs`, und jeder Aufrufer
uebergibt eine Liste -- inklusive vier Faellen in `hover_registry_spec`, die
genau deshalb als `assign-type-mismatch` gemeldet wurden. Die Tests hatten
recht, die Annotation nicht.

Der `ArgType`-Alias des Composers fuehrte `WINDOW` nicht, obwohl `argtypes` den
Typ neben den acht anderen registriert -- und war eine geschlossene Union,
obwohl `composer.register_type(name, def)` oeffentliche API ist: kein
selbstregistrierter Typname konnte sie je erfuellen. Jetzt
`Lib.UserCmd.Composer.ArgTypeBuiltin|string`, mit `WINDOW` in der Liste.

---

#### Das Muster, das ein Drittel erklaert: der Guard sitzt auf dem Feld

Dasselbe wie bei documentation.nvim, nur an anderen Stellen. `parse.dispatch`
prueft `node.route` und liest das Feld drei Aufrufe spaeter erneut in `route`
-- acht `param-type-mismatch` und drei `need-check-nil` aus dieser einen Form.
Dazu `autocmd.docs` (`r.pattern`), `usercmd.create` (`opts.complete`),
`reveal_in_fm` (`opts.command`), `lua_ls.insert.module_annotation`
(`opts.row`).

Bei `proc_trace` ist es nicht einmal pedantisch: die Funktion prueft
`vim.system` und **ersetzt es wenige Zeilen weiter unten selbst**. Der
Re-Read greift dort tatsaechlich auf etwas anderes zu als der Test.

---

#### Rueckgaben, die es ganz oder gar nicht gibt

`selection.chars()` gibt drei Werte zurueck oder keinen, `parse_kv_token` zwei
oder keinen, `vim.ui.select` ein Item mit seinem Index oder nichts,
`parse_raw_response` eine Antwort oder einen Fehler. Zehn Befunde; die
Bedingung prueft jetzt jeweils den Wert statt seinen Partner.

Zwei davon sind eine Spur mehr als Formsache: in `curl` steht die Kopplung
"`err` ist genau dann gesetzt, wenn `response` nil ist" nur in Prosa, nicht in
den zwei Rueckgabe-Slots. Statt ein `nil` als Fehlermeldung weiterzureichen,
haben die vier Aufrufstellen jetzt einen gemeinsamen Fallback-Text.

---

#### libuv antwortet mit nil, statt zu werfen

`uv.new_pipe()` / `uv.new_timer()` sind `|nil` typisiert -- libuv gibt kein
Handle mehr aus, wenn keines mehr zu haben ist -- und wurden ungeprueft
benutzt: in `spawn_capture`, `spawn_stream`, `wait_until`, beiden Debouncern
und drei `ui.kit`-Oberflaechen. 15 `need-check-nil`.

Jede Stelle hat jetzt eine Antwort darauf, und zwar die, die zum Ort passt:

- `spawn_capture`/`spawn_stream` melden es wie einen fehlgeschlagenen Spawn
  -- derselbe Ergebnis-Shape, ein anderer Text. Nebenbei fiel auf, dass
  `spawn_capture`s frueher Ausstieg bei `not handle` seine beiden Pipes offen
  liess; der gemeinsame `fail()` schliesst sie.
- `wait_until` meldet es wie einen erschoepften Poll.
- Die Debouncer rufen die Funktion **undebounced** auf. Den Debounce zu
  verlieren ist schlecht, den Aufruf zu verlieren waere schlimmer.
- Ein Timeout-Timer, den es nicht gibt, heisst schlicht: kein Timeout. Einen
  laufenden Prozess zu killen, weil libuv keine Handles mehr hatte, waere das
  schlechtere von beiden Ergebnissen.

---

#### Cluster E, lib.nvims Anteil

Die zehn `pcall(vim.cmd, "...")` in diesem Repo sind
`pcall(function() vim.cmd(...) end)`, wie im Report vorgeschlagen. Sieben in
`lua/`, drei in `TESTS/`. Der Rest der 60 liegt in anderen Repos und bleibt
offen.

---

#### Typen, die etwas anderes beschrieben haben

- **`Lib.Notify.Notifier`**: alle fuenf Felder optional, obwohl `create()`
  jedes einzelne setzt. Deshalb brauchte `notify().info(...)` in `deps.view`
  an sieben Stellen eine nil-Pruefung. Und `Lib.Notify.Safe` behauptete,
  `create_safe` gebe einen `Notifier` zurueck -- es ist ein `Safe.Notifier`.
- **`Lib.Deps.View.ToolUiState`** war zweimal deklariert, in `@types` und
  noch einmal in `view.lua`. Fuenf `duplicate-doc-field` pro Kopie.
- **`Lib.Cache.SaveOpts`** war eine leere Unterklasse von `Lib.Cache.Opts` --
  nominal also nicht dasselbe, weshalb ein Aufrufer mit dem Basistyp sie nicht
  uebergeben konnte. `deps.first_run` reicht genau eine Options-Tabelle an
  `load` *und* `save` weiter. Jetzt ein Alias.
- **`Composer.DocsOpts`** machte zwei Jobs: die partielle Ueberschreibung, die
  ein Aufrufer `setup()` gibt, und die aufgeloesten Defaults, die
  `registry.docs` haelt. Getrennt in `DocsOpts` und `DocsDefaults`.
- **`Lib.Deps.ManagerOpts`** ersetzt das fuenfmal ausgeschriebene
  `{ manager?: Lib.Deps.Manager }`. LuaLS normalisiert einen Inline-Tabellentyp
  an einer Deklaration anders als an einer Aufrufstelle -- dieselbe
  Schreibweise passte irgendwann nicht mehr auf sich selbst.
- **`Lib.System.ProcTrace.Saved`** ersetzt `table<string, function>` auf einer
  Tabelle, die auch das offene Log-Handle haelt. Und `uv_hrtime` war ein
  Typname, den es nie gegeben hat; `uv.hrtime()` gibt eine Zahl zurueck.
- **Tabpage-Handles** in `tabs_utils` waren `userdata`. Sie sind Integer, in
  beiden Richtungen der API -- dieselbe Klasse Fehler wie Cluster D, nur fuenf
  Befunde statt 154.
- **`Lib.Frecency`** wurde von der `Lib`-Fassade referenziert und war nirgends
  deklariert. **`Lib.Logger.Instance`** fehlten `level` und `file`, die
  `:checkhealth` von einer Instanz liest. **`Route.run`** und `Spec.default`
  waren als "gibt nichts zurueck" deklariert, obwohl `dispatch` genau das
  zurueckgibt, was sie liefern.
- Ein `@param`/`@return`-Paar stand auf `M.is_ike = M.is_like` -- einer
  schlichten Zuweisung ohne Funktion, an die es binden koennte.

---

#### Zwei Namen, die der nvim-Config gehoeren

`LogLevel`/`LogLevelNumber` und `AutoCmds.General.MD.GotoFile.Cfg` deklariert
die Config des Autors ebenfalls global, und zwei globale Deklarationen eines
Namens sind in **beiden** Dateien ein `duplicate-doc-alias` beziehungsweise
`duplicate-doc-field`. Diese Library nennt ihre jetzt `Lib.Notify.LogLevel*`
und `Lib.Fs.Open.Url.SystemOpener.Cfg`.

Damit ist der Kandidat aus Abschnitt 5 des Reports ("einmal in lib.nvim
definieren, ueberall referenzieren") von der anderen Seite geloest: nicht
gemeinsam definieren, sondern getrennt benennen. Was lib.nvim gehoert, heisst
`Lib.*`; was die Config global braucht, behaelt seinen Namen.

---

#### Die Klammer, die eine Signatur rettet

Ein inneres `fun(): X` frisst in einer Signatur alles, was danach kommt:

```lua
---@field create fun(cmd: string|fun(): string, exclude_filetypes?: string[], lhs?: string): function
```

LuaLS liest das als "innere Funktion gibt `string` und `exclude_filetypes`
zurueck" und scheitert dann an der schliessenden Klammer -- `luadoc-miss-symbol`
plus zwei `undefined-doc-name` auf Parameternamen, die es als Typen liest. Die
Annotation existiert danach gar nicht.

Vier Vorkommen: `resize_guarded`, `cross`, `cross.fs.mutate` -- und
`Lib.AutoCmd.create`, wo es beim Fix erst entstanden ist. Dort hat es `create`
still auf zwei Parameter reduziert, was vier `redundant-parameter` im
Dispatcher ausgeloest hat, der die Funktion mit dreien aufruft. Der
Zwischenscan hat das gefangen; Klammern drum, weg.

Das ist die Lehre daraus: ein Fix in einer `@types`-Datei kann eine Signatur
kaputtmachen, ohne dass die Datei selbst einen Befund bekommt.

---

#### Unterdrueckt, mit der Begruendung daneben

`nvim_buf_get_option` und `vim.tbl_islist` sind Kompatibilitaetszweige, deren
ganzer Sinn ihre Veraltetheit ist -- beide laufen nur, wenn der moderne Weg
davor schon gescheitert ist. `proc_trace`, das `vim.system` und
`vim.fn.jobstart` ersetzt, *ist* Monkey-Patching; das war schon im Report
(Abschnitt 5, `duplicate-set-field`) so vermutet.

In den Specs: sieben absichtlich ungueltige Argumente (ein unbekannter
chdir-Scope, ein Nicht-Tabellen-Submenu, ein malformter Frecency-Eintrag, eine
Nicht-Funktion als Sink, zwei unbekannte Format-Styles, ein nicht-numerisches
Buffer-Handle) und zwei `vim.notify`-Doubles.

Und eine in `docs/EXAMPLES/composer-flags-and-kv.lua`: `require("diff")` meint
diff.nvim, loest innerhalb *dieses* Workspace aber auf `lib.lua.diff` auf. Fuer
einen Leser mit installiertem diff.nvim ist die Zeile richtig.

---

#### Was offen bleibt: eine Zeile, und sie gehoert nach lsp.nvim

Der eine verbliebene Befund ist `undefined-doc-name` auf `luassert` in
`lua/lib/@types/luassert.lua:83`. Die Datei sagt selbst, warum: der Typ loest
nur auf, wo `${3rd}/luassert/library` auf dem Library-Pfad liegt, und
`lsp.nvim`s `build_library.lua` haengt `${3rd}/busted/library` und
`${3rd}/luv/library` an -- luassert nicht.

Aus lib.nvim ist das nicht zu schliessen. Eine eigene `workspace.library` in
der `.luarc.json` waere genau der Fehler, den `dd40880` einen Tag vorher
behoben hat: die Liste **ersetzt** die Injektion, statt sie zu ergaenzen. Der
Fix ist eine Zeile in lsp.nvim und wirkt auf alle 31 Repos mit Testsuite --
deshalb steht er dort und nicht hier.

---

#### Gemessen

```
scripts/luals-scan/scan.sh before lib.nvim
# ... 92 Dateien ...
scripts/luals-scan/scan.sh after lib.nvim
python scripts/luals-scan/compare.py before after
```

Drei Laeufe statt zwei: einer nach dem `lua/`-Durchgang (273 -> 91, `worse:
nothing`), einer nach `TESTS/` (273 -> 8), einer nach der Korrektur der vier
`redundant-parameter`, die der zweite aufgedeckt hatte (273 -> 1). Der
Zwischenlauf hat sich bezahlt gemacht: ohne ihn waere die kaputte
`create`-Signatur mit committet worden.

---

### Sechs Repos pruefen wieder gegen Neovims Typen

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

`buffer-ctx`, `emojis`, `fileops`, `gopath`, `lib` und `sessions` nannten in
ihrer `.luarc.json` ein eigenes `workspace.library` -- und weil eine
`.luarc.json` jeden Schluessel, den sie nennt, **ersetzt** statt ihn zu
ergaenzen, warf das die Liste weg, die `lsp.nvim` mitschickt:

```json
"diagnostics.globals": ["vim"],
"workspace.library": ["${3rd}/luv/library"]
```

Uebrig blieb luv. Kein `$VIMRUNTIME/lua`, keine Plugin-Typen, kein lib.nvim.
`vim` war in diesen sechs Repos ein deklariertes Global vom Typ `any`:
`vim.fn.expand(...)` gab `any` zurueck, `vim.api.*` wurde nicht geprueft, und
`vim.SystemCompleted` existierte nicht -- obwohl Neovim 0.12 die Klasse in
`$VIMRUNTIME/lua/vim/_core/system.lua` fuehrt. Die niedrige Warnungszahl kam
daher, dass nicht geprueft wurde.

Das ist derselbe Mechanismus wie Cluster A, und dort wurde die Zeile schon aus
20 `.luarc.json` entfernt -- **aber nur dort, wo die Messung sofort eine
Verbesserung zeigte**. Genau deshalb blieben diese sechs zurueck: bei ihnen
stieg die Zahl. Ohne die Zeile sind ihre `.luarc.json` jetzt identisch zu
documentation.nvim, dem Repo, das auf 0 steht.

---

#### Die Zahl steigt, und das ist der Zweck

| Repo | vorher | nachher |
|---|---:|---:|
| lib.nvim | 244 | 273 |
| gopath.nvim | 67 | 67 |
| fileops.nvim | 20 | 35 |
| sessions.nvim | 8 | 15 |
| emojis.nvim | 13 | 13 |
| buffer-ctx.nvim | 4 | 8 |
| **Summe** | **356** | **411** |

Nach Regel, und daran liest sich, was passiert ist:

| Regel | Delta | warum |
|---|---:|---|
| `undefined-doc-name` | **-37** | `vim.SystemCompleted` / `vim.SystemObj` loesen auf |
| `undefined-field` | **-23** | dito, auf `vim.*`-Feldern |
| `param-type-mismatch` | +57 | typisierte `vim.fn.*`-Rueckgaben, meist `\|nil` |
| `need-check-nil` | +28 | dieselbe Ursache, andere Regel |
| `assign-type-mismatch` | +11 | |
| `deprecated` | +5 | veraltete Neovim-APIs, vorher unsichtbar |
| Rest | +14 | `duplicate-*`, `cast-*`, `return-type-mismatch` |

60 Befunde verschwinden, 119 kommen dazu. Die neuen liegen ausnahmslos an
Stellen, die vorher **niemand** geprueft hat.

Die fuenf `deprecated` sind der beste Beleg dafuer, dass hier nichts kaputt
gemacht, sondern etwas wieder sichtbar wurde: `nvim_buf_get_option` in
`lib.nvim/buf_win_tab/get_option/init.lua:24` steht seit dem Erstscan vom
29.08. in Abschnitt 5 des Reports -- und war in der gesamten laufenden
Messreihe unsichtbar.

Und ein Beispiel aus fileops.nvim, das zeigt, dass es nicht nur um `vim.*`
geht: `bindings/keymaps.lua:110` reicht `bulk.execute(...)` direkt in
`notify.report(...)` weiter und uebergibt dabei ein `integer` an einen
`boolean`-Parameter. Sichtbar erst jetzt -- lib.nvim war vorher gar nicht in
fileops' Library.

---

#### Eine Hypothese, die die Messung widerlegt hat

Der erste Nachher-Lauf brachte drei `duplicate-doc-alias` und drei zusaetzliche
`duplicate-doc-field` mit, und die Vermutung lag nahe: `build_library` sammelt
ueber `find_type_dirs(root)` die `@types/`-Verzeichnisse **des gemessenen
Workspace** ein -- bei lib.nvim 110 von 146 Eintraegen -- also liest LuaLS
diese Dateien zweimal und meldet jede `@class` gegen sich selbst. Das waere
Cluster As zweite Ursache eine Ebene tiefer gewesen.

Ein Filter im Dump, ein zweiter kompletter Lauf: **exakt dieselben 411**, Regel
fuer Regel. Die Hypothese ist falsch -- LuaLS indiziert einen Pfad, der im
Workspace liegt, ohnehin als Workspace-Datei, und die Library-Nennung aendert
daran nichts. Der Filter ist deshalb wieder draussen; eine Aenderung ohne
messbare Wirkung gehoert nicht ins Werkzeug.

Die `duplicate-doc-field` in `lib.nvim/deps/` sind stattdessen echt:
`view.lua:49` und `@types/init.lua:99` deklarieren beide
`Lib.Deps.View.ToolUiState`. Dasselbe in gopath zwischen
`@types/resolvers.lua` und `resolve.lua`.

---

#### Nebenbefund: das Werkzeug dumpt die falsche Funktion

Beim Nachsehen ist aufgefallen, dass `scripts/luals-scan/dump_library.lua`
`build_library(root)` aufruft -- 37 bis 146 Eintraege --, waehrend der
Attach-Pfad des Editors `library_profiles.build_runtime_library()` benutzt und
damit **drei**: `${3rd}/luv/library`, `${3rd}/busted/library`,
`$VIMRUNTIME/lua`. `build_library` erreicht den laufenden Server nur ueber
`:LuaLsReloadLibrary` von Hand; lsp.nvims eigener Kommentar in
`lua_ls/init.lua` haelt fest, dass die fruehere Verdrahtung ueber
`on_new_config` toter Code war.

Der Unterschied ist nicht folgenlos: das Werkzeug ersetzt damit faktisch
lazydev, das im Editor die Plugin-Typen bei Bedarf nachzieht. Das ist eine
brauchbare Annaeherung -- aber der README von `luals-scan` beschreibt sie als
das, was der Editor tut, und das stimmt so nicht. Steht als offener Punkt im
Report.

---

### Cluster F: `inject-field` in lib.nvim -- und die `missing-fields`-Reste daneben

*(war: Diagnostics-Report Abschnitt 0, Offen-Punkt 1)*

Beide Regeln, 108 und 22, hingen an **einer** Schreibweise:

```lua
---@type LibStringsCore
local S = {}

function S.trim(s) ... end   -- 21x: "Fields cannot be injected into
                             --       the reference of `LibStringsCore`"
```

`---@type` sagt „diese Tabelle *ist* bereits jene Klasse“. Alles, was danach
hineingeschrieben wird, ist fuer LuaLS eine Injektion in eine geschlossene
Referenz -- und das leere Literal davor eine Klasse, der ihre Felder fehlen.
Dieselbe Zeile erzeugt also je nach Klasse `inject-field` oder
`missing-fields`; welche von beiden, haengt nur daran, ob die Klasse Felder
deklariert.

**381 -> 244**, ein Commit (`e42235d`). Keine andere Regel hat sich
verschlechtert, Suite gruen, `stylua --check` sauber.

---

#### Die Zombie-Klassen, und was sie verdeckt haben

`lua/lib/lua/tables/@types/init.lua` endete so:

```lua
return {}

---@class LibTablesSafe

---@class TablesSet

---@class LibTablesFn
```

Acht leere Klassendeklarationen, hinter dem `return`, ueber zwei Dateien
(`tables` und `strings`) -- und genau auf die zeigten die acht
Implementierungen. Die echten, gefuellten Klassen lagen daneben:
`Lib.Tables.Core`, `Lib.Strings.Core` und so weiter, je eine Datei pro Modul.

Die Annotation trug damit **keine** Typinformation. Sie schaltete nur die
Ableitung ab, die ohne sie das Richtige getan haette -- und produzierte 99 der
108 `inject-field`.

**Der teure Teil stand woanders.** `lua/lib/@types/all_functions.lua`, die
Beschreibung von `require("lib")`, routete vier Namespaces durch dieselben
Leichen:

```lua
---@field array TablesArray      -- leer
---@field core LibTablesCore     -- leer
---@field dict TablesDict        -- leer
---@field functional LibTablesFn -- leer
```

`lib.core.deep_copy(...)` bot im Editor also gar nichts an: keine Completion,
keine Signatur, keine Pruefung. Vier von rund dreissig Namespaces der
Hauptfassade, still.

Die Fassade nennt jetzt die echten Klassen. Vorher gegengeprueft, Feld fuer
Feld, ueber alle acht Paare: `---@field`-Liste und
`function M.<name>`-Definitionen sind deckungsgleich, in beide Richtungen. Die
Umstellung kostet also keine Zeile Dokumentation. Der tote Block ist weg, die
Implementierungen annotieren nicht mehr -- so, wie es `case.lua`, `wrap.lua`,
`links.lua` und `distance.lua` in demselben Verzeichnis schon immer gemacht
haben.

---

#### Die Annotation stand nur auf der falschen Zeile

Fuer die Module, deren Klasse echt gefuellt ist, lag der Fix bereits im Repo
vor -- `cache/init.lua` und `store/init.lua` schreiben ihn hin:

```lua
local M = {}
M.disk = require("lib.nvim.cache.disk")
M.memory = require("lib.nvim.cache.memory")

---@type Lib.Cache
return M
```

Am `return` ist die Tabelle vollstaendig, dort prueft LuaLS sie gegen die
Klasse, und die Klasse bleibt erhalten. Elf weitere Module ziehen jetzt nach
(`dump`, `error`, `uuid`, `yaml`, `diff/lines`, `diff/myers`,
`numeral/roman`, `numeral/alpha`, `time/format`, `time/presets`,
`parser_policy`). `diff/init.lua` und `numeral/init.lua` bauen ihr Aggregat
stattdessen als ein Literal -- zwei `require`s, die ohnehin nebeneinander
standen.

Dieselbe Bewegung bei den drei lokalen Kontext-Tabellen: in
`buffer/context` und `window/context` steht die Klasse bereits am `---@return`
der Funktion, und die Methoden werden erst unter dem Literal angehaengt. Die
zweite Annotation auf dem Literal war schlicht zu frueh.

---

#### Ein Typ, der nicht bloss zu frueh, sondern falsch war

`bindings/autocmd/dispatcher/init.lua` fuehrt eine Liste jedes erzeugten
Dispatchers:

```lua
---@type Lib.Autocmd.Dispatcher.Entry[]
local live = {}
```

`Entry` ist aber, was `M.registry()` daraus **baut** -- mit `attached`, `mode`
und `handlers`. Was `live` haelt, ist die Rohregistrierung: `name`, `events`,
`group` und ein `handle`, von dem jene drei Felder erst zur Abfragezeit
gelesen werden. `handle` kennt `Entry` gar nicht.

Die Liste hat jetzt ihre eigene Klasse, `Lib.Autocmd.Dispatcher.LiveEntry`.
Das raeumt neben der `missing-fields` auch sechs `undefined-field` auf
`entry.handle` ab -- an sechs Stellen, an denen der Editor bisher auf einem
Feld, das es wirklich gibt, nichts anzubieten hatte.

---

#### Neun Schluessel, die es nur unter einer Strategie gibt

Die restlichen neun `inject-field` lagen in `strategies/lazy.lua` -- und die
waren kein Annotationsfehler, sondern ein Befund: `lazy` exportiert
`augroup`, `augroup_create_clear`, `unique`, `unique_by`, `is_unique` und drei
`json_*`, die `Lib` nicht kennt. Die **Standard**strategie (`metatable`)
registriert sie ebenfalls nicht; ihr `__index` wirft dort
`lib: unknown key '<name>'`.

Sie einfach auf `Lib` nachzutragen haette eine injizierte Warnung gegen eine
Phantom-Zusage getauscht: die Fassade haette unter der Voreinstellung etwas
versprochen, das nicht existiert. Sie stehen deshalb auf einer Unterklasse,
`---@class Lib.Strategy.Lazy : Lib`, die nur `lazy.lua` an seinem `return`
fuehrt. Wer die Strategie waehlt, bekommt die Typen; wer sie nicht waehlt,
bekommt keine Zusage.

`deps` war der eine Schluessel, den beide Strategien fuehren und nur die
Fassade nicht kannte -- der steht jetzt auf `Lib` selbst.

Das dahinterliegende Problem bleibt offen und ist im Report notiert: die drei
Strategien haben drei verschiedene Oberflaechen, `eager.lua` nennt `augroup`
sogar `autogroup`. Der Kommentar bei `noop`/`identity` in `metatable.lua`
beschreibt genau denselben Fall, einmal schon behoben.

---

#### Der Alias, der eine echte Luecke zugedeckt hat

Im geloeschten Zombie-Block stand, ganz am Ende, `---@alias K any`. Mit ihm
verschwanden fuenf `undefined-doc-name` -- die der erste Nachher-Lauf prompt
gemeldet hat, und ohne den waeren sie unbemerkt in die Zahl gewandert.

Vier davon sind eine bekannte Grenze von LuaLS: ein `---@type table<K, ...>`
*im Rumpf* einer Funktion loest deren Typparameter nicht auf. Da `K` durch den
Alias ohnehin `any` war, steht dort jetzt `any` -- gleiche Bedeutung, ehrlich
benannt; die Signatur typisiert weiter, und die sieht der Aufrufer.

Die fuenfte war ein echter Fehler:

```lua
---@generic T            -- K fehlt
---@param key fun(item:T):K
---@return table<K, T[]>
function M.group_by(list, key)
```

`count_by`, dreissig Zeilen darunter, macht es richtig (`---@generic T,K`).
`group_by` hat `K` nie deklariert -- die Zusage `table<K, T[]>` war seit jeher
`table<any, any[]>`, nur hat es niemand gesehen.

Und noch eine Unterdrueckung, die eine Zeile zu hoch sass: in
`TESTS/frecency_spec.lua` stand `---@diagnostic disable-next-line:
missing-fields` ueber `eq(`, waehrend der Befund auf dem `pcall`-Argument in
der Zeile darunter lag. Sie deckt jetzt die Zeile, die sie meinen sollte.

---

#### Gemessen

`scripts/luals-scan`, ein Lauf vor und einer nach der Aenderung, gleiche
Arbeitskopie.

| Regel | vorher | nachher |
|---|---:|---:|
| `inject-field` | 108 | **0** |
| `missing-fields` | 22 | **0** |
| `undefined-field` | 58 | 52 |
| `undefined-doc-name` | 35 | 34 |
| `assign-type-mismatch` | 27 | 26 |
| **lib.nvim gesamt** | **381** | **244** |

`compare.py` meldet `worse: nothing`. Was in lib.nvim bleibt, hat keine
gemeinsame Ursache mehr: `param-type-mismatch` 71, `undefined-field` 52
(davon 12 in `bindings/audit.lua`, alle aus einem Union-Rueckgabetyp:
`keymap.registered()` gibt `table<string, Registered[]>|Registered[]` zurueck,
je nach Argument, und in `pairs(buckets)` kann LuaLS dann nicht entscheiden,
welcher der beiden Zweige vorliegt), `undefined-doc-name` 34 -- **19 davon**
`vim.SystemCompleted` / `vim.SystemObj`, die Neovims Meta unter diesen Namen
nicht fuehrt.

---

### documentation.nvim: die restlichen 155 -- der erste vertikale Durchgang

*(war: Diagnostics-Report Abschnitt 0, "documentation.nvim zu Ende bringen")*

Nach Cluster D standen in dem Repo noch 155 Befunde, und sie hatten keine
gemeinsame Ursache mehr: dreizehn Regeln, verteilt ueber 44 Dateien. Genau
dafuer ist der vertikale Modus gedacht -- der Overhead (Scan davor, Scan
danach, Testsuite, Commit) faellt einmal an, nicht einmal pro Regel.

**155 -> 0.** Zwei Commits: `9f128bb` fuer den einen echten Fehler,
`9e81344` fuer den Rest.

---

#### Das Muster, das die Haelfte erklaert: der Guard sitzt auf einem Feld

```lua
if e.pin then
  local p = e.pin   -- p ist trotzdem `Pin?`
  go(st, { mode = p.mode, ... })
```

Die Pruefung engt nur den Ausdruck ein, den sie prueft. Die zweite Lesung
desselben Feldes ist fuer den Typpruefer ein neuer Ausdruck, und der ist wieder
nil-behaftet. An acht Stellen zuerst an eine Lokale gebunden und dann geprueft
-- in `browse/init.lua`, `browse/view.lua`, `core/docs.lua`,
`bindings/usrcmds/bindings.lua` und `mcp/tools.lua`.

Wo das Feld eine Invariante der Datenstruktur ist -- eine `kind="endpoint"`-Zeile
*hat* ihr `spec` --, steht jetzt ein `assert` statt eines erfundenen Fallbacks:
es benennt die Invariante und kracht, wenn sie je verletzt wird.

---

#### Die Kinder eines Treesitter-Knotens

`node:child(i)` ist `TSNode?`. Innerhalb von `0 .. child_count()-1` kann es
nicht nil sein, aber das weiss der Typpruefer nicht, und ein Guard, der nie
zuschlagen kann, waere gelogener Code. Die Index-Schleifen in
`core/lang/ecma.lua` laufen deshalb ueber `iter_children()`: liefert `TSNode`
ohne nil und besucht exakt dieselben Kinder.

**Und dann hat ein Gate des Repos zugeschlagen.** `TESTS/shim_contract_spec.lua`
verlangt, dass jede Treesitter-Methode, die `core/` aufruft, im Standalone-Shim
klassifiziert ist. Der erste Anlauf benutzte `named_children()` -- eine
Neovim-Bequemlichkeit, die die `lua-tree-sitter`-Bindung des Standalone-Builds
nicht hat. Im Editor waere das nie aufgefallen; der Build waere gescheitert.
Dort steht jetzt wieder `named_child(i)`, mit `assert` fuer die Index-Invariante.

---

#### Ein echter Fehler: zwoelf Advice-Listen, die nie jemand gesehen hat

`vim.health.info(msg)` nimmt eine Nachricht und sonst nichts -- anders als
`warn` und `error` hat es **keinen** Advice-Parameter. Zwoelf Aufrufe in
`editor/health.lua` haben trotzdem eine Liste mitgegeben:

```lua
h_info("lua-language-server not on PATH", {
  "Only :DocMap full needs it; a plain :DocMap never calls it.",
  "In Neovim: :Mason, then install lua-language-server.",
})
```

Lua nimmt das entgegen und wirft es weg. Keine dieser Zeilen stand je in einem
`:checkhealth`. LuaLS hat es als `redundant-parameter` gemeldet -- eine Meldung,
die wie eine Stilnote klingt und ein fehlendes Feature ist. Der lokale Shim
rendert die Hinweise jetzt in die Nachricht, in derselben Form, die
`vim.health` der Advice einer Warnung gibt.

---

#### Zwei verwaiste Doc-Bloecke

In `core/check.lua` und in `scripts/ci.lua` stand je ein Kommentarblock einer
frueheren Fassung ueber der falschen Funktion -- ohne Leerzeile dazwischen, also
verschmolzen mit dem naechsten. Folgen: `check_require_cycles` galt als
undokumentiert (seine Beschreibung klebte 350 Zeilen weiter oben an
`check_binding_conflicts`), und `puc_lua` schien drei Rueckgabewerte zu
deklarieren, weshalb die Meldung "Rueckgabewert #2 ist `string?`" sich auf die
Annotation der Vorgaengerversion bezog. Beide zusammengefuehrt.

---

#### Annotationen, die schlicht falsch waren

Jede davon eine Aussage ueber diesen Code, keine Typ-Kosmetik:

- `core/lang/ocaml.lua`: `doc_blocks` gibt zwei Tabellen zurueck, deklariert war
  eine -- beide Aufrufer benutzen beide.
- `editor/callhierarchy.lua`: `make_client` baut einen
  `vim.lsp.rpc.PublicClient` (die vier Methoden, die `vim.lsp.start` verlangt),
  deklariert war `Client`.
- `config.sources`: auf `Documentation.Opts` annotiert, obwohl der eigene Header
  sagt, dass **jeder** Konsument hier durchgeht. Der Browser reichte seine
  eigene Opts-Klasse hinein -- richtig, und trotzdem gemeldet.
- `Documentation.Browse.KeyAction` kannte `send_request` nicht: wer `gs` ueber
  `opts.keys` umbinden wollte, war fuer den Typ ein Fehler und fuer den Code
  nicht.
- `Documentation.Browse.Entry` deklarierte kein `spec`, obwohl jede
  `kind="endpoint"`-Zeile eines traegt.
- `Documentation.Config` deklarierte kein `git` -- den Host-Hook, den
  `core/api.lua` seit jeher aufruft und beide Hosts setzen.

---

#### Der Overload, der die Zahl verschlechtert hat

Fuenf `missing-return` kamen daher, dass die Haelfte der Scan-Stages nichts
zurueckgibt, `timing.measure`s `fun(): T` aber von jedem Rueckruf einen Wert
verlangt. Erster Versuch: die void-Form als `@overload` deklarieren. Gemessen:
**aus 5 Befunden wurden 13.** Mit der Ueberladung wird der Rueckgabewert *jedes*
`measure`-Aufrufs nil-behaftet, also war `ir` ploetzlich `Documentation.IR|nil`
und jede Weitergabe davon ein neuer Befund.

Genau der Fall, wegen dem vorher *und* nachher gemessen wird. Stattdessen
`timing.stage(t, name, fn)`: dieselbe Messung ohne Wert. Warum der Overload
nicht geht, steht jetzt in der Doku der Funktion -- sonst probiert es der
naechste noch einmal.

---

#### Unterdrueckt, mit der Begruendung daneben

Nur dort, wo der Befund die Absicht des Codes meldet:

- `scripts/bundle_manifest.lua` ersetzt `os.exit`, `scripts/mcp_server.lua`
  ersetzt `vim.notify` -- beides der Zweck der jeweiligen Datei.
- Test-Doubles, die pro Fall einen eigenen Stub ueber dasselbe Feld legen
  (`docmap_browse_spec`, `usrcmds_generate_all_spec`).
- Teil-Fixturen, die nur die Felder tragen, die die gepruefte Einheit liest
  (`call_path_spec`, `scopes_spec`).
- Aufrufe, die absichtlich `nil` oder `42` hineinreichen, weil die Abweisung
  das Testobjekt ist (`docmap_spec`, `tags_spec`, `check_policy_spec`).

Wo der Test selbst schon prueft (`ok(x ~= nil, ...)`), steht ein `---@cast`
statt einer Unterdrueckung: er sagt dem Typpruefer, was die Zeile darueber
bereits behauptet.

---

#### Gemessen

`155 -> 0`, mit `scripts/luals-scan` vor und nach jeder Runde. Gates vor dem
Commit: **96 Spec-Dateien gruen**, `stylua --check .` sauber, luacheck 0
Warnungen / 0 Fehler ueber 244 Dateien.

Der Zuschnitt der beiden Durchgaenge ist der Unterschied, den der Arbeitsmodus
in Abschnitt 0 beschreibt: Cluster D war **eine** Ursache, 154-mal angewendet;
diese Runde waren **dreizehn** Ursachen ueber 44 Dateien, jede einzeln zu lesen
und einzeln zu entscheiden. Die zweite Sorte laesst sich nicht horizontal
abarbeiten -- deshalb steht sie hinter dem Repo, nicht hinter der Regel.

---

### Cluster D: `userdata` statt `TSNode` -- documentation.nvim

*(war: Diagnostics-Report Abschnitt 4 D und Abschnitt 8, Punkt 2)*

Der erste vertikale Durchgang, und er faengt beim groessten Einzelposten der
ganzen Liste an: 237 `undefined-field` in einem Repo, davon 211 auf vier
Methodennamen -- `iter_children` 92, `start` 65, `end_` 28, `type` 26.

---

#### Warum `userdata` der teuerste Annotationsfehler ist

`---@param node userdata` sieht aus wie "ein Objekt, das die Sprache nicht
naeher beschreibt". LuaLS liest es strenger: `userdata` ist ein Typ **ohne
Felder**, also ist jeder Zugriff darauf ein Befund. Eine einzige Annotation,
ueber 17 Sprachmodule wiederholt, erzeugt so ein Vielfaches an Warnungen --
eine pro Aufrufstelle, nicht eine pro Deklaration.

Der Typ, der gemeint war, liegt die ganze Zeit im Runtime:
`$VIMRUNTIME/lua/vim/treesitter/_meta/tsnode.lua` deklariert `TSNode` mit genau
diesen Methoden. Es war also nichts nachzubauen und nichts zu unterdruecken,
sondern nur der richtige Name einzusetzen.

---

#### Was gemacht wurde -- 154 Annotationen in 18 Dateien

`userdata` -> `TSNode` in jeder `@param`/`@return`/`@type`-Zeile der 17
Sprachmodule und in `core/plugins.lua`. Prosa blieb unangetastet: in
`core/artifact.lua` und im Lua-Glossar steht das Wort als Fliesstext ueber Luas
`type()`, und dort ist es richtig.

Kein Zeichen Code geaendert, nur Annotationen.

---

#### Zwei Nachbarn derselben Klasse

Die Messung hat zwei weitere Stellen mitgezeigt, an denen `userdata` einen
vorhandenen Typ verdeckt hat:

- **`editor/serve.lua`** (11 Befunde): die Client-Handles kommen aus
  `uv.new_tcp()` und sind `uv.uv_tcp_t`. Die luv-Meta kennt `write`, `close`,
  `is_closing`, `read_start` und `read_stop`; `---@param client userdata` hat
  genau das weggeworfen, was der Server benutzt.
- **`standalone/treesitter.lua`** (2 Befunde): hier waere `TSNode` **falsch**.
  Die Datei uebersetzt `lua-tree-sitter` auf Neovims Oberflaeche, und die
  Knoten der Bindung tragen die Byte-Offsets der C-API (`start_byte`,
  `end_byte`) statt `start()`/`end_()` -- das ist eine der sechs Luecken, die
  die Datei ueberhaupt erst schliesst. Ihre Knoten haben deshalb eine eigene,
  benannte Klasse bekommen, mit dem Grund darueber, statt Neovims Typ
  aufgedrueckt zu bekommen.

Das ist der Unterschied zwischen "die Warnung ist weg" und "der Typ stimmt":
`TSNode` haette dort ebenfalls 2 Befunde beseitigt und dafuer eine Behauptung
aufgestellt, die beim naechsten Leser als Tatsache durchgeht.

---

#### Ergebnis: 383 -> 155

| Regel | vorher | nachher |
|---|---:|---:|
| `undefined-field` | 237 | **9** |
| `param-type-mismatch` | 47 | 47 |
| `need-check-nil` | 44 | 44 |
| `duplicate-set-field` | 13 | 13 |
| `redundant-parameter` | 13 | 13 |
| `assign-type-mismatch` | 8 | 8 |
| **gesamt** | **383** | **155** |

**Keine andere Regel hat sich um einen einzigen Zaehler bewegt.** Das war die
Frage, wegen der ueberhaupt vor *und* nach der Aenderung gemessen wird: ein
echter Typ kann anderswo neue Befunde ausloesen (ein `TSNode?`, das an ein
`TSNode` gereicht wird), und dann waere der Fix nur eine Verschiebung gewesen.

Gates vor dem Commit: 96 Spec-Dateien gruen, `stylua --check .` sauber,
luacheck 0 Warnungen / 0 Fehler ueber 135 Dateien. Ein Commit, `c98ea46`,
gepusht.

---

#### Was von den `undefined-field` uebrig ist

Neun, und sie haben eine andere Ursache -- fehlende Feld-Deklarationen, keine
falschen Typen:

- `Documentation.Browse.Entry` fuehrt kein `spec`, obwohl
  `kind="endpoint"`-Zeilen eines tragen: 2 in `lua/`, 4 im Spec dazu.
- `TESTS/mcp_spec.lua` greift auf `text`, `commits` und `last_commit` eines
  MCP-Ergebnisses zu, die der Typ nicht nennt.

Beides sind Ein-Zeilen-Nachtraege am jeweiligen `@class` und gehoeren in den
naechsten Durchgang durch dieses Repo, nicht zu Cluster D.

---

### Cluster B: `need-check-nil` in Tests -- unterdrueckt, nicht auszementiert

*(war: Diagnostics-Report Abschnitt 4 B und Abschnitt 8, Punkt 5)*

Der Report hatte die Wahl offen gelassen, weil sie keine Arbeit ist, sondern
eine Entscheidung: die 920 `need-check-nil` aus `TESTS/` und `scripts/`
entweder mit `assert(mod)` auszementieren, oder dort abschalten, wo der Befund
invertiert ist. Entschieden wurde das Abschalten.

Der Grund ist der Zweck der Dateien. Kommt in einem Test etwas als `nil`
zurueck -- ein `pcall(require, ...)`, ein Fixture-Read, ein uv-Handle --, dann
*soll* die Datei krachen und das `nil` benennen. Die Nil-Pruefung, die LuaLS
verlangt, wuerde genau den Fehlschlag verstecken, fuer dessen Meldung der Test
existiert. Ein `assert(mod)` davor waere 920-mal Code, der eine Pruefung
nachbaut, die der Test ohnehin ist.

---

#### Der Befund, der die Umsetzung geaendert hat

Geplant war eine `TESTS/.luarc.json` pro Repo: Verzeichnisebene statt
Dateiebene, 19 Eintraege statt 93. **Das geht nicht.** LuaLS liest
ausschliesslich die `.luarc.json` im Wurzelverzeichnis des Workspace; eine in
einem Unterverzeichnis wird nicht etwa daruebergelegt, sondern ignoriert.

Zweimal gegengeprueft, weil eine Verneinung sonst nur eine Vermutung bleibt:
einmal per `lua-language-server --check` mit einer probeweise angelegten
`TESTS/.luarc.json`, einmal gegen einen laufenden Server im Editor
(`runtime-analysis.nvim/TESTS/telemetry_spec.lua` -- 52 Befunde vorher wie
nachher).

Dateiebene ist damit die feinste Granularitaet, die der Server anbietet. Sie
erfuellt nebenbei die stehende Regel *"Unterdrueckung braucht eine Begruendung
im Code"* besser als der urspruengliche Plan: die Begruendung steht ueber dem
Code, den sie betrifft, statt in einer JSON-Datei ein Verzeichnis hoeher.

---

#### Was gemacht wurde -- 19 Repos, 93 Dateien

19 Repos, 93 Testdateien, je vier Zeilen am Dateikopf:

```lua
-- Test code: when something here comes back nil -- a `pcall(require, ...)`,
-- a fixture read, a uv handle -- this file must crash and name it. The nil
-- guards LuaLS asks for below would hide the very failure it exists to report.
---@diagnostic disable: need-check-nil
```

Verteilung der 93 Dateien: documentation 40, lib 11, markdown 8,
runtime-analysis 8, spotlight 7, filetree 3, open 3, diff 2, und je eine in
fileops, github_stats, gopath, images, lsp, mdview, pickers, replacer,
reposcope, sandbox, sessions.

**Kein Zeichen Code geaendert** -- ueber alle 19 Commits sind saemtliche
hinzugefuegten Zeilen Kommentarzeilen, geloescht wurde nichts. Ein Commit pro
Repo, alle auf `main` gepusht: diff `ca102cf`, documentation `430ed61`, fileops
`2e68761`, filetree `63b88f2`, github_stats `66487dc`, gopath `4aaad96`, images
`59395b4`, lib `a0232a0`, lsp `fde2de3`, markdown `fae1b92`, mdview `ec3c7a7`,
open `1d5ecde`, pickers `c9fd4fe`, replacer `deb279b`, reposcope `2bb7c69`,
runtime-analysis `5be8414`, sandbox `283af24`, sessions `9394c52`, spotlight
`01dca91`.

---

#### Ergebnis: 3204 -> 2289

Messreihe vom 31.08., dieselbe Config-Herstellung wie bei Cluster A.
Aufgefuehrt sind die Repos, fuer die beide Messungen vorliegen; die Summe geht
ueber alle 33 Workspaces.

| Repo | vorher | nachher |
|---|---:|---:|
| documentation.nvim | 732 | 383 |
| lib.nvim | 505 | 381 |
| lsp.nvim | 392 | 379 |
| runtime-analysis.nvim | 273 | 119 |
| filetree.nvim | 226 | 167 |
| nvim-config | 137 | 137 |
| **Summe (alle 33 Workspaces)** | **3204** | **2289** |

`need-check-nil` selbst: **1128 -> 208**, also genau die 920 aus `TESTS/` und
`scripts/`. Die 208 Reste liegen in `lua/` und sind echt -- dort wird ein
`string|nil` ungeprueft weitergereicht, das ist keine Testabsicht, sondern eine
offene Stelle. Nach Repo: documentation 44, filetree 43, lib 18, lsp 15,
gopath 14, nvim-config 11, github_stats 10, mdview 10, der Rest verteilt.

Die Rangfolge der Regeln danach: `undefined-field` 562,
`param-type-mismatch` 458, `need-check-nil` 208, `duplicate-doc-field` 192,
`duplicate-set-field` 160, `assign-type-mismatch` 135, `inject-field` 118,
`undefined-doc-name` 87, `redundant-parameter` 84.

---

#### Gegenprobe mit dem festen Harness

Dieselbe Messung ein zweites Mal, mit `scripts/luals-scan` statt der
Ad-hoc-Umgebung: **2285** statt 2289. Vier Zaehler ueber 33 Workspaces -- genau
das Rauschen, das unten beschrieben ist, und kein Repo, das sich anders
verhaelt als gemeldet. Repoweise identisch bis auf den Zaehler:
documentation 383, lib 381, lsp 379, filetree 167, runtime-analysis 119. Auch
`need-check-nil` kommt wieder auf 208, davon 197 in den 32 Plugin-Workspaces
und 11 in der Config -- und **kein einziger mehr in `TESTS/` oder `scripts/`**,
was die Unterdrueckung an genau der beabsichtigten Stelle bestaetigt.

Die Gegenprobe zeigt nebenbei, wo die zwei Repos gelandet sind, die aus der
100er-Tabelle in Abschnitt 0 des Reports gefallen sind: spotlight.nvim
105 -> 49, gopath.nvim 101 -> 67.

---

#### Zwei Sachen, die beim Messen aufgefallen sind

**Die Messung rauscht.** `param-type-mismatch` schwankt zwischen zwei Laeufen
ueber denselben unveraenderten Stand um einige Zaehler -- pdfport.nvim, in
dieser Runde nicht angefasst, kam einmal mit -7 und einmal mit +7 zurueck. Ein
Delta unter etwa 10 in einem einzelnen Repo ist ohne Gegenprobe nicht
belastbar, und zwar in beide Richtungen: ein Minus als Erfolg zu lesen waere
derselbe Fehler wie ein Plus als Regression.

**`diff.nvim/plugin/diff.lua` hat CRLF-Zeilenenden** und faellt deshalb bei
`stylua --check` durch. Nicht von dieser Arbeit verursacht -- die Datei wurde
hier nicht angefasst, die Zeilenenden stammen aus `4cb35d4` vom 2026-08-06.
Damit stimmt Abschnitt 6 des Reports nicht mehr, der stylua ueber alle 31 Repos
sauber meldet; der Punkt steht dort jetzt wieder offen.

---

#### Die Messumgebung liegt jetzt fest im Repo

Nach zwei weggeworfenen Ad-hoc-Varianten steht sie als
[`scripts/luals-scan/`](../../../../scripts/luals-scan/README.md) im
Config-Repo: `scan.sh <pass> [repo ...]`, dann
`compare.py <vorher> <nachher>`. Die injizierte `workspace.library` wird darin
nicht mehr nachmodelliert, sondern per `build_library(root)` aus einem
laufenden nvim geholt -- damit entfaellt die Frage, ob das Modell dem Editor
entspricht. `compare.py` markiert Deltas unterhalb der Rauschgrenze, statt sie
als Ergebnis zu melden.

Zwei Fallen, die je einen Anlauf gekostet haben und in der README stehen:
`pwd` antwortet in Git Bash mit `/c/Users/…`, was das Windows-`nvim` nicht
findet -- headless nvim wartet dann stumm bis zum Timeout, statt zu scheitern
(dieselbe Klasse Haenger wie ein fehlendes `PLENARY_PATH` in der lsp.nvim-Suite).
Und `| tail` oder `| grep` puffern die Ausgabe, wodurch ein laufender Scan wie
ein haengender aussieht.

Beim Nachmessen fuer diesen Eintrag kam eine dritte dazu: der volle Lauf ohne
Repo-Argumente bricht ab, wenn er aus einem Worktree gestartet wird -- die
Config landet im Dump unter dem Ordnernamen des Worktrees, `scan.sh` sucht
`nvim-config.json` und findet nichts. Aus dem Haupt-Checkout tritt das nicht
auf, deshalb war es beim Bauen nicht aufgefallen. Behoben am 2026-08-31 in
`8e3d7ef4`.

---

### Cluster A: der `assert`-Typ -- und warum der erste Anlauf ins Leere lief

*(war: Diagnostics-Report Abschnitt 4 A, Abschnitt 8 Punkt 1, und der
unverifizierte Nebenbefund aus Abschnitt 7)*

Am 30.08. lagen zwei Dinge vor: die Meta-Datei
`lib.nvim/lua/lib/@types/luassert.lua`, die den globalen `assert` als `luassert`
typisiert, und in vier `.luarc.json` die neue Zeile
`${3rd}/luassert/library`. Nachgemessen hat das zusammen so gut wie nichts
bewirkt:

| Repo | 2026-08-29 | nach den Commits vom 30.08. |
|---|---:|---:|
| lsp.nvim | 1333 | 1333 |
| sandbox.nvim | 223 | 223 |
| dap.nvim | 60 | 60 |
| lib.nvim | 505 | 505 |
| github_stats.nvim | 88 | **60** |

Nur github_stats.nvim hat reagiert -- als einziges der vier fuehrte seine
`.luarc.json` auch `${3rd}/busted/library`, und erst die Meta von busted
verdrahtet `assert` ueberhaupt mit luassert.

---

#### Die Ursache, jetzt gemessen statt vermutet

Der Nebenbefund vom 29.08. stimmt, und er ist groesser als dort geschaetzt:
**`.luarc.json` ersetzt `workspace.library` vollstaendig**, sie ergaenzt nicht.
Was `lsp.nvim` dem Server mitschickt, kommt nie an.

Nachweis im echten Editor, nicht im Modell: headless nvim, `lua_ls` an
`lsp.nvim/TESTS/lsp/config_spec.lua`. Der Client sendet
`${3rd}/busted/library` mit -- der Server meldet trotzdem
`Undefined global 'describe'` und `'it'`.

Betroffen waren **31 von 33 Workspaces**. Sie alle deklarierten eine eigene
Library-Liste aus ein bis sieben Eintraegen und warfen damit die
43 Eintraege weg, die `build_library.lua` zusammenstellt -- darunter busted,
`$VIMRUNTIME`, saemtliche Plugin-Typen und lib.nvim, also auch die Meta-Datei.
Die erreichte nur `nvim-config` und `runtime-analysis.nvim`, die keine eigene
Liste fuehren.

Bei sandbox.nvim standen in dieser Liste ausserdem vier
`$HOME/.local/share/nvim/lazy/…`-Pfade, die auf dieser Maschine ins Leere
zeigen.

---

#### Die zweite Ursache: der Workspace als seine eigene Library

`build_library.lua` haengte jeden `runtimepath`-Eintrag an. Die Dev-Repos liegen
auf dem `runtimepath`, also auch das Repo, das gerade offen ist. LuaLS liest
dessen Dateien dann zweimal, und jede `@class` darin meldet
`duplicate-doc-field` gegen sich selbst: **1085 der 1222 Warnungen der
nvim-Config** und 212 in runtime-analysis.nvim.

---

#### Was gemacht wurde

1. **`workspace.library` aus 20 `.luarc.json` entfernt** -- genau dort, wo die
   Messung eine Verbesserung zeigt. Jede Datei hat nur diesen einen Block
   verloren.
2. **`lsp.nvim/lua/lsp/servers/lua_ls/build_library.lua`**: der
   `runtimepath` wird gefiltert, der Workspace landet nicht mehr in seiner
   eigenen Library.

Die Meta-Datei aus dem ersten Anlauf bleibt unveraendert -- sie war nie das
Problem, sie kam nur nirgends an. Jetzt tut sie, wofuer sie gebaut wurde:
`assert.are.same(...)` loest auf, in lsp.nvim bleiben von 665
`undefined-field` noch 36, davon sieben echte (`has_no`, `are_not` -- Namen,
die die Meta-Datei noch nicht kennt).

---

#### Ergebnis: 6344 -> 3204

| Repo | vorher | nachher |
|---|---:|---:|
| lsp.nvim | 1333 | 392 |
| nvim-config | 1222 | 137 |
| documentation.nvim | 1048 | 732 |
| runtime-analysis.nvim | 485 | 273 |
| filetree.nvim | 312 | 226 |
| sandbox.nvim | 223 | 44 |
| images.nvim | 150 | 44 |
| open.nvim | 102 | 85 |
| markdown.nvim | 91 | 59 |
| pdfport.nvim | 72 | 62 |
| replacer.nvim | 71 | 60 |
| dap.nvim | 60 | 10 |
| github_stats.nvim | 60 | 52 |
| insights.nvim | 57 | 29 |
| diff.nvim | 50 | 48 |
| pickers.nvim | 43 | 27 |
| cascade.nvim | 38 | 32 |
| recommender.nvim | 23 | 12 |
| reposcope.nvim | 23 | 10 |
| color_my_ascii.nvim | 16 | 8 |
| debugging.nvim | 9 | 8 |
| cmdlog.nvim | 6 | 4 |
| **Summe (alle 33 Workspaces)** | **6344** | **3204** |

Nach Regel: `undefined-field` 1741 -> 562, `duplicate-doc-field` 1235 -> 192,
`undefined-global` 511 -> **0**, `undefined-doc-name` 328 -> 87,
`redundant-parameter` 252 -> 84.

---

#### Was absichtlich unangetastet blieb

Acht Repos wuerden durch den Fix **schlechter** -- ihre `.luarc.json` behaelt
ihre Library-Liste, und damit bleibt fuer sie auch Fix 2 wirkungslos:
spotlight (+340), mdview (+75), lib (+35), fileops (+15), sessions (+7),
buffer-ctx (+4), neotree-fs-refactor (+4), migrate (+1). Drei weitere aendern
sich gar nicht: emojis, gopath, language.

Dass lib.nvim dabei ist, ist die unangenehme Pointe: das Repo, das die
Meta-Datei traegt, sieht sie selbst nur, weil sie in seinem eigenen Workspace
liegt.

---

#### Wie gemessen wurde

`lua-language-server --check` pro Workspace, mit einer Config, die die
Injektion aus `build_library.lua` nachbaut und die `.luarc.json` des Repos
darueberlegt -- also genau die Reihenfolge, die auch der Editor herstellt. Zur
Kontrolle wurde die Modell-Library fuer lsp.nvim gegen die **echte**
43-Eintraege-Liste getauscht, die `build_library("E:/repos/lsp.nvim")` im
laufenden nvim zurueckgibt: identisches Ergebnis, 392.

Der Vorher-Lauf hat die Meta-Datei beiseitegelegt und die vier
`luassert`-Zeilen entfernt, statt in der Historie zu blaettern; die Datei kam
per `trap` zurueck, `git status` war danach sauber.

Zwei Sachen, an denen das Skript zuerst gescheitert ist, fuer den naechsten
Anlauf: Windows-Python schreibt die Index-Datei mit CRLF, und das CR haengt am
Pfad; und parallele `lua-language-server`-Instanzen brauchen je einen eigenen
`--metapath`, sonst kommt jeder Lauf leer zurueck.

---

## 2026-08-29

---

### Cluster C: `missing-fields` -- 518 auf 21, ueber alle 31 Plugins plus Config

*(war: Diagnostics-Report Abschnitt 4 C und Abschnitt 8, Punkt 3)*

Die `@class *.Config`-Klassen deklarierten ihre Felder als Pflicht, obwohl sie
zugleich der Typ dessen waren, was `setup()` entgegennimmt. Jeder partielle
Aufruf -- also die vorgesehene Nutzung -- galt damit als Fehler.

**Ergebnis: 518 -> 21.** Die 21 Reste liegen saemtlich in lib.nvim und sind die
Namespace-Aggregatoren (`---@type Lib` auf einer Tabelle, die per
`LIB.x = ...` gefuellt wird): dieselbe Ursache wie die 108 `inject-field`, und
dort aufzuraeumen, nicht hier.

| Repo | `missing-fields` | Diagnosen gesamt |
|---|---:|---|
| filetree | 90 -> 0 | 315 -> 226 |
| pickers | 78 -> 0 | 121 -> 43 |
| spotlight | 66 -> 0 | 156 -> 90 |
| lib | 37 -> 20 | 533 -> 516 |
| pdfport | 37 -> 0 | 106 -> 62 |
| documentation | 36 -> 0 | 753 -> 717 |
| lsp | 30 -> 0 | 464 -> 441 |
| nvim-config | 25 -> 0 | 185 -> 160 |
| open | 21 -> 0 | 106 -> 85 |
| diff | 14 -> 0 | 62 -> 48 |
| emojis | 14 -> 0 | 28 -> 13 |
| markdown | 12 -> 0 | 71 -> 59 |
| github_stats | 11 -> 0 | 120 -> 109 |
| debugging | 9 -> 0 | 17 -> 8 |
| gopath | 8 -> 0 | 108 -> 100 |
| images | 7 -> 0 | 45 -> 38 |
| language | 6 -> 0 | 40 -> 34 |
| sessions | 5 -> 0 | 23 -> 18 |
| cascade, recommender | 3 -> 0 | 35 -> 32, 15 -> 12 |
| insights, mdview | 2 -> 0 | 31 -> 29, 120 -> 118 |
| dap, runtime-analysis, color_my_ascii | 1 -> 0 | 33 -> 32, 270 -> 269, 20 -> 19 |
| **Summe** | **518 -> 21** | **3777 -> 3278** |

Ohne Befund und unangetastet: sandbox, fileops, buffer-ctx, replacer, migrate,
reposcope, cmdlog.

---

#### Der Fix war nicht ueberall derselbe -- und das liess sich nur messen

Der Report schlug einen Weg vor: Opts von Config trennen. Der billigere --
einfach alle Felder optional stellen -- funktioniert aber in der Mehrzahl der
Repos genauso gut und kostet keine zweite Klassenfamilie. Welcher der richtige
ist, haengt daran, **wie das Plugin seine aufgeloeste Config liest**, und das
sieht man dem Repo nicht an.

Gemessen, jeweils Felder-optional zuerst:

- **spotlight.nvim**: 66 Warnungen weg, *keine* neue. Grund: die Features lesen
  ueber `config.get("section")`-Accessoren, die ohnehin auf die Defaults
  zurueckfallen -- nie direkt in eine gemergte Tabelle hinein.
- **diff.nvim**: 14 weg, **19 neue `need-check-nil` und 2
  `param-type-mismatch`**. Grund: das ganze Plugin liest `cfg.diff.ctxlen` und
  Geschwister direkt.
- **emojis.nvim**: 14 weg, 15 neue. **insights.nvim**: 2 weg, 13 neue.
  **images.nvim**: 7 weg, 12 neue. **sessions.nvim**: 5 weg, 3 neue plus ein
  `return-type-mismatch`. **github_stats.nvim**: 11 weg, 5 neue.

In diesen sechs Repos wurde stattdessen gespalten: eine `*Opts`-Familie mit
lauter optionalen Feldern fuer die Eingabe, die `*Config`-Klassen bleiben
strikt fuer alles nach dem Merge. In den uebrigen 15 genuegte `?`.

**Die Lehre ist die Messung selbst.** Ohne den Vorher/Nachher-Vergleich ueber
*alle* Regeln haette man in sechs Repos 47 Warnungen gegen 54 neue getauscht
und es "erledigt" genannt.

---

#### Was dabei an echten Fehlern herausfiel

Kein einziger davon war der gesuchte Cluster -- alle sind Annotationen, die
etwas anderes behaupteten als der Code daneben tut:

- **`Language.Module.setup` ueberschrieb die eigene Signatur.**
  `language.nvim/@types/init.lua` deklariert `setup` ein zweites Mal als
  `@field setup fun(opts?: LanguageConfig)`, und **diese Deklaration gewinnt
  gegen das `@param` an der Funktion**. Die Umstellung auf `LanguageOpts` kam
  bei keinem Aufrufer an -- gemerkt nur, weil eine Probe *ausserhalb* des Repos
  weiter vier Warnungen zeigte. Wer eine `setup`-Signatur aendert, muss pruefen,
  ob die Modul-Klasse sie nochmal fuehrt (lib, lsp, replacer, reposcope tun das
  auch, dort mit unkritischem Typ).
- **`---@type X` auf einem Modul, das seine Methoden darunter definiert.**
  pdfports 16 Backends und Producer sind Tabellen-Literale mit den Datenfeldern,
  `available`/`extract` folgen als Funktionen. Gegen ein `@type` prueft LuaLS
  nur das Literal und meldet die Methoden als fehlend. `---@class
  PdfPort.Backend.Foo : PdfPort.Backend` macht die spaetere
  `function M.extract(...)` zur Definition des Klassenfeldes. Nebeneffekt:
  `param-type-mismatch` fiel dort von 16 auf 10, weil die Registry jetzt die
  echten Feldtypen sieht statt eines Literals, das sie fuer unvollstaendig hielt.
- **Eine aufgeloeste Config muss weiter als Eingabe taugen.** Nach dem Split
  lehnte LuaLS in images.nvim zwei Specs ab, die eine fertige Config zurueck an
  `setup()` reichen -- voellig legitim. Erst
  `---@class ImagesNvim.Config : ImagesNvim.Opts` macht die Beziehung wahr.
- **filetree `FiletreeBindSpec.rhs`** war Pflicht, obwohl eine Action
  *entweder* `rhs` *oder* per-Modus-`binds` mitbringt (marks' toggle).
- **documentation `IR.duplicates`** -- der eigene Doc-Kommentar sagt "Set by
  `scan_full`, so a bare `scan()` leaves it nil", die Annotation sagte Pflicht.
  Dazu `IR.tag_links` (wird von `tagfiles.lua` nachgestempelt, Leser schreiben
  `ir.tag_links or {}`) und `Node.calls_external` (von `core/calls.lua`).
- **lib.nvim `DirGuard.Opts.on_violation`** -- die Implementierung prueft
  `if opts.on_violation then`; **`Strategies.Registration.keys`** --
  `control.keys()` faellt ohne es auf `pairs()` zurueck, und der Kommentar
  darueber sagt das; **`RootResolverCfg.markers`** -- hat einen Default.
- **lib.nvim `Markdown.Table`**: `render()` verlangte `start_line`/`end_line`,
  liest sie aber nie. Eine im Speicher zusammengesetzte Tabelle hat keine
  Position -- danach zu fragen hiess, den Aufrufer um eine Luege zu bitten.
  Jetzt `Table.Content` (Inhalt) und `Table : Table.Content` (plus Position).
- **language `TranslateHistoryEntry.time`** -- `history.push` stempelt selbst
  (`entry.time = entry.time or os.time()`), alle vier Aufrufer verlassen sich
  darauf.
- **pickers `Smart.Item._rank`** -- wird von `score.rank` nachtraeglich gesetzt;
  ein unrangiertes Item ist ein legaler Zwischenzustand.
- **dap.nvim trug eine Unterdrueckung, die einen falschen Typ verdeckte.**
  `config.setup` hatte ein pauschales `---@diagnostic disable: missing-fields`
  ueber dem Merge. Mit der richtigen Annotation ist beides weg.
- **nvim-config `Lib.Case.BlueprintNode.body`** -- laut eigener Doku nur
  relevant, wenn `template` fehlt; ein `dir`-Knoten hat keines von beidem. Und
  `ui.open_node` nahm einen vollen Blueprint-Knoten, liest davon aber genau
  `key` und `path`; `open_summary` uebergibt entsprechend ein Paar, das gar kein
  Blueprint-Eintrag ist. Jetzt `Lib.Case.NodeRef`.

---

#### Was Pflicht blieb, und warum

Nicht jedes Feld gehoert optional. Belegt statt vermutet:

- **`Pickers.Collection.name` und `.dir`** -- `config.apply` verwirft jeden
  Eintrag ohne sie und sagt das auch ("name+dir required"). Der eine Test, der
  einen namenlosen Eintrag uebergibt, ist jetzt als absichtlich ungueltig
  markiert statt typkonform gemacht.
- **`GHStats`**: vier Felder in `SetupOptions` und zwei in `DashboardConfig`
  sind nach dem Merge garantiert -- deshalb `GHStats.Config` /
  `GHStats.Dashboard.Resolved` fuer `DEFAULTS` und `config.get()`, nicht
  einfach alles optional.
- **`OpenNvim`**: dasselbe umgekehrt entdeckt -- erst als die Felder optional
  waren, meldete die *nvim-Config* einen `param-type-mismatch`, weil sie
  `cfg.default_browser` direkt weiterreicht. `OpenNvim.Config.Resolved` fuer
  `config.get()` loest das an der richtigen Stelle.

---

#### Unterdrueckt, mit Begruendung im Code

Nur zwei Sorten, und beide stehen als Satz an der Stelle:

1. **Upstream-Metas, die zu viel verlangen.** luvs `uv.spawn` deklariert
   *jede* Option als Pflicht (cwd, env, uid, gid, verbatim, detached, hide) --
   lib.nvim, pdfport, mdview. Neovims `vim.api.keyset.command_info` als
   Optionstyp von `nvim_buf_get_commands` (markdown), `lsp.CodeActionContext`
   ohne `diagnostics` (lsp.nvim, java und astro), `vim.lsp.start.Opts` mit
   `cmd` (lsp.nvim, documentation).
2. **Test-Doubles und absichtlich ungueltige Eingaben.** Ein Stub implementiert,
   was der Test aufruft -- ein vollstaendiger `FiletreeAdapter` in einem Unit
   Test ist Rauschen, keine Abdeckung. Und wo ein Test prueft, dass ein
   kaputter Wert abgewiesen wird (spotlights malformed StoredItems, emojis'
   `mode = "nonsense"`, runtime-analysis' Kandidat ohne `fn`), ist die Warnung
   *korrekt* und der Test auch.

---

#### Werkzeug

Drei kleine Skripte, im Scratchpad, wiederverwendbar fuer die naechsten Cluster:

- `scan.sh <repo> <out.json>` -- LuaLS-Check eines Repos mit der Cross-Repo-
  Bibliothek aller *anderen* Repos, plus Kurzauswertung nach Regel.
- `optional.py <Klasse...>` -- macht `@field`-Eintraege der genannten Klassen
  optional, **aber nur die, die LuaLS ueberhaupt als Pflicht zaehlt**: ein Feld,
  dessen Typ schon `|nil` oder `?` traegt, bleibt unangetastet. Richtet die
  Typspalte danach neu aus.
- `mkopts.py <typesfile> <Klasse...> --write` -- erzeugt die `*Opts`-Spiegel-
  familie samt Umbiegen verschachtelter Typen.

**Zwei Fallen, die dabei Zeit gekostet haben:** ein Feld mit Typ `boolean?`
zaehlt fuer LuaLS *nicht* als Pflicht -- ein zusaetzliches `?` am Namen ist
Rauschen. Und `stylua --check` bricht unter Windows bei vielen Diffs mit
`fatal runtime error: I/O error` ab; Ausgabe in eine Datei umlenken.

---

### `lib.nvim.ui.list` -- eine Listen-Senke statt vierzehn

*(war: Diagnostics-Report Abschnitt 9, der delegierbare Teil des
`<leader>wq`-Roadmap-Punkts)*

Neues Modul `lib.nvim/lua/lib/nvim/ui/list/` (`set`, `qf`, `loc`), plus
Spec, README und API-Doku. Alle 20 Aufrufstellen in 12 Repos sind
umgestellt. Gegenprobe danach: in ganz `C:/repos` gibt es unter `lua/` noch
**genau eine** `setqflist`-Zeile, und die steht im Modul selbst.

**Der Report hat die falsche Vorlage benannt.** Er schlug vor, die
`wq`-Logik aus `lsp.nvim/lua/lsp/diagnostics/{quickfix,loclist}.lua` zu
heben. Beim Hinsehen war das die einzige Stelle, die *nicht* passt: die
arbeitet auf `vim.diagnostic.setqflist` -- andere API, eigene
Severity-Behandlung, und eine Signatur, die sich zwischen Neovim 0.10 und
0.11 geaendert hat (lsp.nvim traegt dafuer einen eigenen Arity-Sniffer).
Die anderen 20 Stellen bauen `vim.fn.setqflist`-Items aus eigenen Daten.
Gemeinsam ist ihnen nur der letzte Schritt -- und genau der ist gewandert.
lsp.nvim blieb unangetastet.

**Was die 20 Stellen unterschiedlich machten, ohne dass es jemand
entschieden haette:**

- **Stack-Semantik.** `setqflist(items, "r")` ersetzt die Liste, die der
  Nutzer gerade offen hat; `setqflist({}, " ", {...})` legt eine neue an und
  laesst `:colder` einen Weg zurueck. Fuenf Repos machten das eine, sieben
  das andere, und an keiner Aufrufstelle liest sich das wie eine
  Entscheidung. Jetzt ist `" "` der Default und `"r"` etwas, das ein Aufrufer
  anfordert -- richtig genau dann, wenn er *seine eigene* Liste aktualisiert
  (language.nvims Spell-Refresh, insights' Konflikt-Rescan).
- **Der Titel als zweiter Aufruf.** Die `"r"`-Form kann keinen Titel tragen.
  Deshalb steht in fuenf Repos direkt dahinter ein
  `setqflist({}, "a", { title = ... })` -- ein Append von nichts, nur um
  einen String anzuhaengen. Ein Aufruf macht jetzt beides.
- **Fokus.** `:copen` zieht den Cursor in die Liste. Nur spotlight.nvim gibt
  ihn bewusst zurueck (die gefilterten Zeilen will man *neben* dem Log
  lesen). Der Default bleibt deshalb `"list"` -- ein gemeinsames Modul, das
  elf Plugins still den Cursor woanders hinsetzt, waere schlimmer als die
  Uneinheitlichkeit.
- **Der leere Fall.** `open = "auto"` setzt die Liste trotzdem, oeffnet aber
  kein Fenster auf nichts. Das ist wichtig, weil "keine Treffer" sonst die
  Treffer von gestern stehen laesst, als waeren sie aktuell.
- **Der qf/loc-Zweig.** diff.nvim und replacer.nvim schrieben denselben
  if/else zweimal, obwohl es ein Flag ist. `loclist = <bool|winid>` macht
  daraus einen Wert.

**Nicht mitgewandert, bewusst:** spotlights `max_entries`-Trunkierung (der
Cap greift *waehrend* des Scans, nicht danach -- das muss im Scanner
bleiben) und Filtern/Formatieren/Navigieren.

**Aufwandsehrlichkeit:** Der Gewinn ist Konsistenz, nicht Zeilenzahl. Pro
Aufrufstelle fallen 2-5 Zeilen weg; documentation.nvim war mit 12 Stellen
das groesste Einzelstueck (58 rein, 67 raus). Der eigentliche Wert liegt
darin, dass Stack, Fokus und Leerfall jetzt an einer Stelle entschieden
werden.

Commits: lib.nvim `2fdfcb7`, dann je ein `refactor(qf)`-Commit in
insights, language, emojis, filetree, markdown, replacer, diff, debugging,
runtime-analysis, spotlight, documentation. Alle Test-Suites der
betroffenen Repos laufen gruen (filetree 394, spotlight 453, replacer 188,
lib.nvim vollstaendig).

---

### mdview.nvim formatiert jetzt wie die anderen 30 Repos

*(war: Diagnostics-Report Abschnitt 6, "Zwei Auffaelligkeiten am Rand", Punkt 1
und 2)*

`mdview.nvim/stylua.toml` stand als **einziges** der 31 Repos auf
`indent_type = "Tabs"` mit `indent_width = 4`; alle anderen fahren
`Spaces` / `2`. Umgestellt und das Repo einmal durchformatiert.

Interessant daran:

- **Der Diff ist gross, die Aenderung ist es nicht.** 89 Dateien, ~5600 Zeilen
  -- aber `git diff -w` schrumpft das auf 13 Dateien. Die 13 sind kein
  Sonderfall, sondern eine Folge: mit 2 statt 4 Spalten Einrueckung passen
  Aufrufe wieder in die 120-Spalten-Grenze, die stylua vorher umbrechen musste.
  Semantisch aendert sich nichts.
- **stylua fasst Kommentare nicht an.** Nach dem Lauf war noch genau eine Datei
  tab-eingerueckt: `lua/mdview/helper/normalize.lua`, drei Zeilen im
  `--[[ USAGE: ]]`-Block. Beispielcode in Kommentaren faellt durch jedes
  Formatter-Raster -- wer eine Repo-Konvention umstellt, muss die Kommentare
  separat pruefen (`grep -rlP '^\t' --include='*.lua'`).
- **`stylua --check` stirbt unter Windows an der eigenen Ausgabe.** Bei
  ~90 Diffs bricht der Prozess mit `fatal runtime error: I/O error: operation
  failed to complete synchronously` ab -- ein Pipe-Problem, kein Formatfehler.
  Ausgabe in eine Datei umlenken, dann laeuft es durch.
- Gegenprobe statt Vertrauen: alle 95 Lua-Dateien nach dem Lauf per
  `loadfile()` geprueft, 0 Fehler. `column_width = 120`, `quote_style` und
  `call_parentheses` blieben unveraendert -- angeglichen wurde nur die
  Einrueckung.

Commit: `140dcd2 style: switch stylua to spaces/2, matching the other 30 repos`.

Damit ist auch `docs/templates/usercmds.lua` erledigt, eine der vier
stylua-abweichenden Dateien aus dem Report. Offen bleiben drei:
`emojis.nvim/plugin/{emojis,emojis_autodoc}.lua` und
`gopath.nvim/scripts/ci/headless_tests.lua`.

---

### open.nvim: uebrig gebliebener Claude-Worktree abgeraeumt

*(war: Diagnostics-Report Abschnitt 7, Nebenbefunde, Punkt 1 und 3)*

`.claude/worktrees/cool-benz-a3f6a1` samt Branch `claude/cool-benz-a3f6a1`
hatte den Cleanup vom 2026-08-26 ueberlebt. Entfernt, zusammen mit
`feat/registry-driven-keymaps`.

Vor dem Loeschen geprueft, ob dort etwas liegt, das `main` nicht hat -- das war
der eigentliche Punkt:

- Arbeitsverzeichnis sauber, auch `--ignored` leer. Nichts Uncommittetes.
- Zwei Commits, die `main` nicht kennt, **beide inhaltlich ueberholt**:
  `854e5c6` legt eine `.gitattributes` mit `* text=auto eol=lf` an -- `main`
  traegt seit der repoweiten Line-Ending-Umstellung eine echte Obermenge davon
  (mit `binary`-Regeln). `05bf222` formatiert `check_office_open` in
  `lua/open/health.lua` -- `main` hat exakt dieselbe Formatierung bereits,
  `stylua --check lua/` steht dort auf 0.
- `feat/registry-driven-keymaps` war 0 Commits vor `main`, also vollstaendig
  gemergt.

Die Lehre fuer den naechsten Fund dieser Art: `git log main..<branch>` allein
sagt nur, *dass* etwas fehlt, nicht *ob es fehlt* -- `main` kann denselben
Inhalt ueber einen anderen Commit tragen. Erst der Blick in den Diff der
einzelnen Commits gegen den heutigen Stand entscheidet.

`.claude/` ist dort jetzt gitignored, damit der naechste Worktree nicht wieder
als untracked Repo-Inhalt auftaucht (wie es die nvim-Config schon macht).
Kein LSP-Effekt in beide Richtungen: LuaLS indiziert Punkt-Verzeichnisse
ohnehin nicht.

Commit: `8e235b3 chore: gitignore .claude/ and drop the leftover Claude worktree`.

---
