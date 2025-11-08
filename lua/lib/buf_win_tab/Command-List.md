# Übersicht über Commands im `debugging.buf_win_tab`-Modul

## Table of content

  - [ASCII-Übersicht](#ascii-bersicht)
  - [lib.buf_win_tab.buffer_utils](#libbuf_win_tabbuffer_utils)
  - [lib.buf_win_tab.windows_utils](#libbuf_win_tabwindows_utils)
  - [lib.buf_win_tab.tabs_utils](#libbuf_win_tabtabs_utils)
  - [lib.buf_win_tab.neotree](#libbuf_win_tabneotree)

---

## ASCII-Übersicht

buf_win_tab/
├─ buffer_utils
│  ├─ DEFAULT_EXCLUDE_FILETYPES : string[]
│  ├─ count_listed_buffers() -> integer
│  ├─ get_buffer_info(bufnr) -> table
│  ├─ count_real_listed_buffers(exclude_filetypes?: string[]) -> integer
│  ├─ list_all_buffers_info() -> table[]
│  ├─ list_listed_buffers_info() -> table[]
│  ├─ format_buffers_table(buftable: table[]) -> string
│  ├─ print_buffers_table(buftable: table[]) -> nil
│  ├─ collect_all_buffer_info() -> table
│  └─ print_summary() -> nil
│
├─ windows_utils
│  ├─ count_listed_buffers() -> integer
│  ├─ list_all_buffers_info() -> table[]
│  ├─ get_listed_buffer_ids() -> integer[]
│  ├─ get_buffers_grouped_by_filetype() -> table<string, integer[]>
│  ├─ get_current_buffer_info() -> table
│  ├─ get_tabpage_buffers(tabnr?: integer) -> integer[]
│  ├─ format_buffers_report() -> string
│  ├─ collect_all_state() -> table
│  └─ show_aggregated_state(silent?: boolean) -> string|nil
│
├─ tabs
│  ├─ list_tabs() -> TabInfo[]
│  ├─ format_tab_one_line(info: TabInfo) -> string
│  ├─ print_tabs(tabs?: TabInfo[]) -> nil
│  ├─ get_current_tab() -> TabInfo?
│  ├─ get_tab_by_number(tabnr: integer) -> TabInfo?
│  ├─ is_single_tab() -> boolean
│  └─ collect_report() -> table
│
└─ neotree
   ├─ find_neotree_window() -> number|nil
   ├─ open_neotree_and_focus(neotree_cmd?: string) -> boolean
   ├─ setup_autotree_on_last_close(opts?: table) -> nil
   ├─ only_nonfile_listed_buffers() -> boolean
   └─ open_neotree_if_last_buffer() -> boolean



## lib.buf_win_tab.buffer_utils

| Name                        | Signatur                                    | Beschreibung                                                                                               |
| --------------------------- | ------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `DEFAULT_EXCLUDE_FILETYPES` | `string[]`                                  | Standardliste von Filetypes/Buffer-Namen, die beim Zählen „echter“ Benutzer-Buffers ausgeschlossen werden. |
| `count_listed_buffers`      | `() -> integer`                             | Zählt alle gelisteten Buffer.                                                                              |
| `get_buffer_info`           | `() -> table`                               | Gibt Metadaten zu einem Buffer zurück.                                                                              |
| `count_real_listed_buffers` | `(exclude_filetypes?: string[]) -> integer` | Zählt gelistete Buffer unter Ausschluss von Plugin-/ephemeren Buffers.                                     |
| `list_all_buffers_info`     | `() -> table[]`                             | Gibt ein Array mit Metadaten für alle Buffer zurück.                                                       |
| `list_listed_buffers_info`  | `() -> table[]`                             | Gibt ein Array mit Metadaten für alle gelisteten Buffer zurück.                                            |
| `format_buffers_table`      | `(buftable: table[]) -> string`             | Formatiert eine Buffer-Tabelle in einen menschenlesbaren mehrzeiligen String.                              |
| `print_buffers_table`       | `(buftable: table[]) -> nil`                | Gibt eine Buffer-Tabelle in der Kommandozeile aus.                                                         |
| `collect_all_buffer_info`   | `() -> table`                               | Sammelt alle Buffer-Informationen, inklusive Counts und formatierter Listen.                               |
| `print_summary`             | `() -> nil`                                 | Gibt eine kompakte Zusammenfassung der aktuellen Buffer aus.                                               |

---

## lib.buf_win_tab.windows_utils

| Name                              | Signatur                         | Beschreibung                                                           |                                                        |
| --------------------------------- | -------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------ |
| `count_listed_buffers`            | `() -> integer`                  | Zählt alle gelisteten Buffer (Plattform-agnostisch).                   |                                                        |
| `list_all_buffers_info`           | `() -> table[]`                  | Gibt Metadaten für alle Buffer zurück, normalisiert.                   |                                                        |
| `get_listed_buffer_ids`           | `() -> integer[]`                | Gibt eine Liste aller gelisteten Buffer-IDs zurück.                    |                                                        |
| `get_buffers_grouped_by_filetype` | `() -> table<string, integer[]>` | Gruppiert Buffer-IDs nach Filetype.                                    |                                                        |
| `get_current_buffer_info`         | `() -> table`                    | Liefert Informationen über den aktuellen Buffer.                       |                                                        |
| `get_tabpage_buffers`             | `(tabnr?: integer) -> integer[]` | Gibt Buffer-IDs für ein Tabpage zurück (oder aktuelles Tab, wenn nil). |                                                        |
| `format_buffers_report`           | `() -> string`                   | Formatiert einen kompakten Bericht über alle Buffer.                   |                                                        |
| `collect_all_state`               | `() -> table`                    | Sammelt diverse Statusinformationen zu Buffern, Tabs, Plattform.       |                                                        |
| `show_aggregated_state`           | `(silent?: boolean) -> string    | nil`                                                                   | Gibt aggregierten Status aus, optional nur als String. |

---

## lib.buf_win_tab.tabs_utils

| Name                  | Signatur                       | Beschreibung                                                       |
| --------------------- | ------------------------------ | ------------------------------------------------------------------ |
| `list_tabs`           | `() -> TabInfo[]`              | Gibt eine Liste aller Tabpages mit Window- und Bufferinfos zurück. |
| `format_tab_one_line` | `(info: TabInfo) -> string`    | Formatiert ein TabInfo in eine kompakte Ein-Zeilen-Beschreibung.   |
| `print_tabs`          | `(tabs?: TabInfo[]) -> nil`    | Pretty-Print der Tabs via `vim.notify`.                            |
| `get_current_tab`     | `() -> TabInfo?`               | Liefert das TabInfo der aktuellen Tabpage.                         |
| `get_tab_by_number`   | `(tabnr: integer) -> TabInfo?` | Liefert das TabInfo für eine bestimmte Tabnummer.                  |
| `is_single_tab`       | `() -> boolean`                | Prüft, ob nur ein Tab geöffnet ist.                                |
| `collect_report`      | `() -> table`                  | Sammelt strukturierte Informationen über alle Tabs.                |

---

## lib.buf_win_tab.neotree

| Name                           | Signatur                            | Beschreibung                                                                    |                                                 |
| ------------------------------ | ----------------------------------- | ------------------------------------------------------------------------------- | ----------------------------------------------- |
| `find_neotree_window`          | `() -> number                       | nil`                                                                            | Sucht eine Neotree-Fenster-ID, falls vorhanden. |
| `open_neotree_and_focus`       | `(neotree_cmd?: string) -> boolean` | Führt ein Neotree-Kommando aus und fokussiert das Fenster.                      |                                                 |
| `setup_autotree_on_last_close` | `(opts?: table) -> nil`             | Autocommand, das Neotree öffnet, wenn letzte „echte“ Buffer geschlossen werden. |                                                 |
| `only_nonfile_listed_buffers`  | `() -> boolean`                     | Prüft, ob nur Non-File Buffer gelistet sind.                                    |                                                 |
| `open_neotree_if_last_buffer`  | `() -> boolean`                     | Öffnet Neotree, wenn letzter File-Buffer geschlossen wurde.                     |                                                 |

---

