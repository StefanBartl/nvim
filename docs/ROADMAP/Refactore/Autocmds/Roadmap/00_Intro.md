# Roadmap: Event-zentriertes Refactoring für ~110 Autocmds

## Table of content

- [Roadmap: Event-zentriertes Refactoring für ~110 Autocmds](#roadmap-event-zentriertes-refactoring-fr-110-autocmds)
  - [Executive Summary](#executive-summary)
  - [Analyse der aktuellen Situation](#analyse-der-aktuellen-situation)
    - [Event-Verteilung (Top 10)](#event-verteilung-top-10)
    - [Problemzonen (identifiziert)](#problemzonen-identifiziert)
      - [🔴 **Hot Path (CRITICAL)**](#hot-path-critical)
      - [🟠 **Frequent Events (HIGH)**](#frequent-events-high)
      - [🟡 **Write Path (MEDIUM)**](#write-path-medium)
  - [Risiken & Mitigationen](#risiken-mitigationen)
  - [Success Metrics](#success-metrics)
  - [Fazit](#fazit)

---

## Executive Summary

**Scope:** 110 autocmd-Registrierungen über 98 Event-Instanzen
**Ziel:** Event-zentrierte Dispatch-Architektur mit deduplizierten Bufferzugriffen
**Erwarteter Performance-Gewinn:** 15–40% in Hot-Path-Events (`CursorMoved`, `BufEnter`)
**Primäre Goodies:** Wartbarkeit ↑, Debugbarkeit ↑, Startup-Zeit ↓, Speicher ↓

---

## Analyse der aktuellen Situation

### Event-Verteilung (Top 10)

| Event           | Count | Kritikalität | Refactoring-Priorität |
|-----------------|-------|--------------|----------------------|
| `FileType`      | 17    | Medium       | **P2**               |
| `BufEnter`      | 11    | **HIGH**     | **P1**               |
| `BufWritePre`   | 7     | Medium       | **P2**               |
| `VimEnter`      | 6     | Low          | P3                   |
| `BufWinEnter`   | 6     | **HIGH**     | **P1**               |
| `ColorScheme`   | 6     | Low          | P3                   |
| `CursorMoved`   | 5     | **CRITICAL** | **P0**               |
| `VimLeavePre`   | 5     | Low          | P3                   |
| `BufDelete`     | 4     | Medium       | P2                   |
| `WinClosed`     | 3     | Medium       | P2                   |

### Problemzonen (identifiziert)

#### 🔴 **Hot Path (CRITICAL)**
- `CursorMoved` (5×): Redundante Zugriffe auf `nvim_buf_get_lines`, `nvim_win_get_cursor`
- `CursorMovedI` (1×): Git line diff + cword occurrences → potenziell doppelte Arbeit

#### 🟠 **Frequent Events (HIGH)**
- `BufEnter` (11×):
  - Mehrfache `nvim_buf_get_name`-Calls
  - Unkoordinierte Filetype-Checks
  - Neo-tree sync + Dashboard logic + Markdown keymaps
- `BufWinEnter` (6×):
  - Conflict markers, debug views, Snacks dashboard
  - Keine Koordination zwischen Subsystemen

#### 🟡 **Write Path (MEDIUM)**
- `BufWritePre` (7×):
  - Auto-mkdir, trim trailing/blank, ESLint/Prettier, formatter
  - **Problem:** Sequenzielle Ausführung ohne Priorisierung
  - **Risiko:** Race Conditions bei parallelen Formattern

---

## Risiken & Mitigationen

| Risiko | Wahrscheinlichkeit | Impact | Mitigation |
|--------|-------------------|--------|-----------|
| Context-Cache veraltet | Medium | High | `TextChanged` invalidiert automatisch |
| Handler-Fehler blockiert alle | Low | Critical | `pcall` pro Handler + Error-Logging |
| Race Condition bei Writern | Medium | Medium | Priorisierte Pipeline + User-Config |
| Startup-Zeit erhöht | Low | Medium | Lazy Handler Loading |

---

## Success Metrics

| Metrik | Baseline | Ziel | Messung |
|--------|----------|------|---------|
| `CursorMoved` Latenz | 0.67ms | <0.50ms | `:AutocmdStats` |
| `BufEnter` Latenz | 0.80ms | <0.55ms | `:AutocmdStats` |
| Cache Hit Rate | N/A | >80% | `cache.stats.ratio` |
| Startup Zeit (`:Lazy profile`) | X ms | X-10% | `vim.uv.hrtime()` |
| Speicherverbrauch | Y MB | Y-5% | `:lua collectgarbage("count")` |

---

## Fazit

**Aufwand:** ~8 Wochen (1–2h/Tag)
**Performance-Gewinn:** 15–40% (je nach Event-Typ)
**Wartbarkeit:** Signifikant verbessert
**Debugbarkeit:** Zentrale Logs, klare Hierarchie
**Risk:** Low (schrittweise Migration, A/B-Tests)

**Empfehlung:** Start mit Phase 0 + 1 (Hot Path). ROI bereits nach 2 Wochen messbar.


