UI-bezogene offene Tasks (Status open, soweit nicht anders angegeben):

**appkit**
- `appkit/menuleiste-mit-abschnitten-trennlinien-und-nativer-optik` (neu)
- `appkit/hover-tooltip-komponente-fuer-buttons-badges-und-kennzahlen` (neu)
- Dazu steht in rules-desktop: `rules-desktop/appkit-ui-kit-stufe-2-palette-toast-konfliktzentrum-keymap`

**ALL**
- `ALL/logo-und-icon-serie-fuer-docmap-desktop-tasks-desktop-und-ru` (neu, `actor=pair`)

**tasks-desktop** (Area `tasks-desktop`)
- Neu von heute:
  - `tasks-desktop-menueleiste-umbauen-einstellungen-wird-optione`
  - `tasks-desktop-menue-projekt-mit-vault-abschnitt-setzen-neu-a`
  - `tasks-desktop-neues-menue-tasks-neuer-task-task-suchen`
  - `tasks-desktop-app-logo-statt-schriftzug-tasks-in-der-menuele`
  - `tasks-desktop-hover-erklaerungen-fuer-live-kritischer-pfad-u`
- Ansichten:
  - `tasks-app-ansichten-gruppieren-und-visualisieren` (prio 2, L) 🟡
  - `tasks-app-abhaengigkeits-ansicht-reihen-pfeile-drag-drop`
  - `tasks-app-kalender-und-zeitleisten-ansicht`
  - `tasks-desktop-verbindungen-gruppierung-netz-darstellung-rust`
  - `tasks-desktop-vaults-gemischte-ansichten-erledigt-und-verbin`
- Repo-Kacheln:
  - `tasks-desktop-repo-kacheln-eine-favoritenseite-mit-gruppen` (L)
  - `tasks-desktop-repo-kacheln-nativer-ordnerdialog-in-der-tauri`
  - `tasks-desktop-repo-kacheln-vorschlagsliste-der-ordner-unter`
  - `hand-pruefung-kacheln-der-uebersicht-und-filter-im-echten-ta`
- Erklärungen und Bedienung:
  - `tasks-desktop-erklaerungen-von-check-codes-graph-und-vault-a` (Erklärungen auch per Tastatur; überschneidet sich mit der Tooltip-Task)
  - `schreib-ui-optimistische-anzeige-statuswechsel-sofort-rollba` (parked)
- Hub-Panel:
  - `tasks-app-hub-panel`
  - `tasks-desktop-hub-panel-trusted-types-policy-bei-mehreren-sv`
- Tests im WebView2:
  - `tasks-desktop-browser-test-im-tauri-fenster-webview2-per-pla`
  - `tasks-desktop-smoke-tests-im-echten-webview2-ueber-tauri-dri`
- Review-Funde (können UI betreffen, nicht geprüft):
  - `review-funde-appkit-umbau-264d846-bis-0e80052`
  - `review-funde-massen-verschieben-2dc2d9c-3916367`
  - `review-funde-tests-und-filter-5bf5e7d-0f4d082-97423f0-4ca53e`

**rules-desktop**
- `ansichten-gruppieren-und-visualisieren` (prio 2, L)
- `appkit-ui-kit-stufe-2-palette-toast-konfliktzentrum-keymap`
- `tauri-huelle` (Tray und Installer, nur teilweise UI)

**docmap-desktop**
- `live-test-engine-panel-and-call-edge-popup`
- `live-test-traffic-surface`
- `macos-menu-bar-variant`
- `tasks-tab-evaluation` (blocked)

Die Liste ist ein Stichwortfilter über Titel und Status, die Auswahl ist also geschätzt. Der Filter lief nur über den Titel, nicht über den Inhalt. Es kann UI-Tasks geben, deren Titel kein Stichwort enthält. Die ganze Area `docmap-desktop` habe ich nicht durchgesehen.

Die neuen Menü-, Tooltip- und Logo-Tasks hängen an `appkit/menuleiste-…` und `appkit/hover-tooltip-…`. Damit würde ich anfangen.
