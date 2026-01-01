# Debugging Module - Roadmap

This document outlines planned features, security improvements, performance optimizations, and future enhancements for the debugging module.

## Table of Contents

- [Priority Legend](#priority-legend)
- [Features](#features)
- [Security](#security)
- [Performance](#performance)
- [Usability](#usability)
- [Testing](#testing)
- [Documentation](#documentation)
- [Architecture](#architecture)

---

## Priority Legend

| Priority | Symbol | Description | Timeline |
|----------|--------|-------------|----------|
| **P0** | 🔴 | Critical - Required for production | Next release |
| **P1** | 🟡 | High - Important for users | 1-2 releases |
| **P2** | 🟢 | Medium - Nice to have | 2-3 releases |
| **P3** | ⚪ | Low - Future consideration | Backlog |

---

## Features

### Views Module

| Priority | Feature | Description | Effort | Status |
|----------|---------|-------------|--------|--------|
| 🟡 **P1** | Export formats | JSON, Markdown, Plain text export | 3h | Planned |
| 🟡 **P1** | Filter by level | Show only ERROR/WARN/INFO messages | 4h | Planned |
| 🟢 **P2** | Search in messages | Fuzzy search through message history | 5h | Planned |
| 🟢 **P2** | Diff messages | Compare two message snapshots | 4h | Planned |
| 🟢 **P2** | Message persistence | Save message history to SQLite | 8h | Planned |
| 🟢 **P2** | Message annotations | Add custom tags/notes to messages | 6h | Planned |
| ⚪ **P3** | Streaming mode | Live-update messages view | 10h | Backlog |
| ⚪ **P3** | Remote logging | Send messages to external server | 12h | Backlog |

### User Commands

| Priority | Feature | Description | Effort | Status |
|----------|---------|-------------|--------|--------|
| 🟡 **P1** | AutocmdReport | List/filter autocommands | 3h | Planned |
| 🟡 **P1** | KeymapReport | Show all active keymaps | 4h | Planned |
| 🟢 **P2** | HighlightReport | List highlight groups | 3h | Planned |
| 🟢 **P2** | OptionReport | Show all changed options | 4h | Planned |
| 🟢 **P2** | PluginReport | List loaded plugins with timings | 5h | Planned |
| 🟢 **P2** | LSPReport | Show LSP client status | 4h | Planned |
| ⚪ **P3** | DiagnosticReport | Aggregate diagnostic statistics | 6h | Backlog |

### Terminals

| Priority | Feature | Description | Effort | Status |
|----------|---------|-------------|--------|--------|
| 🟡 **P1** | File output | Save keylog to file | 2h | Planned |
| 🟡 **P1** | Replay mode | Replay captured keys | 6h | Planned |
| 🟢 **P2** | Filter keys | Ignore certain keys/patterns | 3h | Planned |
| 🟢 **P2** | Timing info | Log timestamps between keys | 2h | Planned |
| ⚪ **P3** | Multiple terminals | Track keys across terminals | 8h | Backlog |
| ⚪ **P3** | Terminal state | Capture full terminal state | 10h | Backlog |

### Vardump

| Priority | Feature | Description | Effort | Status |
|----------|---------|-------------|--------|--------|
| 🟢 **P2** | Max depth control | Limit recursion depth | 1h | Planned |
| 🟢 **P2** | Custom formatters | User-defined type formatters | 4h | Planned |
| 🟢 **P2** | Diff vardump | Compare two variable states | 5h | Planned |
| ⚪ **P3** | Watch variables | Monitor variable changes | 8h | Backlog |
| ⚪ **P3** | Export format | JSON/YAML export | 3h | Backlog |

### Markdown

| Priority | Feature | Description | Effort | Status |
|----------|---------|-------------|--------|--------|
| 🟡 **P1** | Auto-fix | Attempt automatic highlight fixes | 6h | Planned |
| 🟢 **P2** | Preset configs | Known-good configurations | 3h | Planned |
| ⚪ **P3** | Syntax tester | Test syntax rules interactively | 8h | Backlog |

---

## Security

### Data Protection

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🔴 **P0** | Sanitize file paths | Prevent path traversal attacks | 2h | Planned |
| 🔴 **P0** | Validate user input | All command args must be validated | 3h | Planned |
| 🟡 **P1** | Redact sensitive data | Auto-redact passwords in captures | 4h | Planned |
| 🟡 **P1** | Secure temp files | Use secure temp directories | 2h | Planned |
| 🟢 **P2** | Encryption option | Encrypt saved message logs | 8h | Planned |
| 🟢 **P2** | Permission checks | Verify file write permissions | 2h | Planned |

### Terminal Security

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🔴 **P0** | Password warning | Warn before logging passwords | 1h | Planned |
| 🟡 **P1** | Auto-pause | Pause logging during password prompts | 4h | Planned |
| 🟡 **P1** | Clear history | Command to clear logged data | 1h | Planned |
| 🟢 **P2** | Encrypted storage | Encrypt keylog files | 6h | Planned |

### API Security

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🔴 **P0** | Rate limiting | Prevent command spam | 3h | Planned |
| 🟡 **P1** | Input validation | Type-check all API inputs | 4h | Planned |
| 🟢 **P2** | Audit logging | Log security-sensitive operations | 5h | Planned |

---

## Performance

### Views Module

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | Debounce refresh | Aggregate rapid refresh requests | 2h | Planned |
| 🟡 **P1** | Lazy window creation | Only create windows when shown | 3h | Planned |
| 🟢 **P2** | Virtual text | Use virtual text for large outputs | 6h | Planned |
| 🟢 **P2** | Pagination | Paginate large message lists | 5h | Planned |
| ⚪ **P3** | Async capture | Non-blocking message capture | 8h | Backlog |

### User Commands

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | Cache reports | Cache report data for 1 second | 2h | Planned |
| 🟢 **P2** | Incremental updates | Only update changed data | 4h | Planned |
| 🟢 **P2** | Lazy formatting | Format output on-demand | 3h | Planned |

### Terminals

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | Buffer logs | Use ring buffer for keys | 2h | Planned |
| 🟢 **P2** | Batch notifications | Group notifications | 3h | Planned |

### General

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | Memoization | Cache expensive computations | 4h | Planned |
| 🟡 **P1** | Weak tables | Use weak references for caches | 2h | Planned |
| 🟢 **P2** | Profile startup | Measure and optimize startup time | 5h | Planned |
| 🟢 **P2** | Reduce allocations | Reuse tables where possible | 6h | Planned |

---

## Usability

### Keymaps

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | Keymap groups | Organize keymaps with which-key | 3h | Planned |
| 🟢 **P2** | Buffer-local maps | Context-sensitive keymaps | 2h | Planned |
| 🟢 **P2** | Visual mode maps | Extract selection to debug | 3h | Planned |

### UI/UX

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | Status line integration | Show debug state in statusline | 4h | Planned |
| 🟡 **P1** | Preview improvements | Better syntax highlighting | 3h | Planned |
| 🟢 **P2** | Floating windows | Use floats instead of splits | 5h | Planned |
| 🟢 **P2** | Window layouts | Predefined debug layouts | 6h | Planned |
| ⚪ **P3** | Dashboard | Central debug dashboard | 12h | Backlog |

### Autocommands

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟢 **P2** | Auto-capture errors | Capture on LSP errors | 4h | Planned |
| 🟢 **P2** | Smart refresh | Refresh based on event type | 3h | Planned |
| ⚪ **P3** | Event filtering | Filter which events trigger refresh | 5h | Backlog |

---

## Testing

### Unit Tests

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🔴 **P0** | Capture tests | Test message capture logic | 4h | Planned |
| 🔴 **P0** | Display tests | Test window management | 5h | Planned |
| 🟡 **P1** | Utils tests | Test all utility functions | 3h | Planned |
| 🟡 **P1** | Platform tests | Test clipboard on all platforms | 6h | Planned |

### Integration Tests

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | End-to-end flows | Test complete workflows | 8h | Planned |
| 🟢 **P2** | Edge cases | Test error conditions | 5h | Planned |
| 🟢 **P2** | Concurrency | Test async operations | 6h | Planned |

### Property Tests

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟢 **P2** | Invariants | Test module invariants | 6h | Planned |
| 🟢 **P2** | Fuzzing | Fuzz command inputs | 8h | Planned |

---

## Documentation

### Guides

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | Quick start guide | 5-minute getting started | 2h | Planned |
| 🟡 **P1** | Cookbook | Common recipes/patterns | 4h | Planned |
| 🟢 **P2** | Video tutorials | Screencast walkthroughs | 8h | Planned |
| 🟢 **P2** | Architecture doc | Deep-dive into design | 6h | Planned |

### API Docs

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | LuaCATS completion | Full annotations for all APIs | 6h | Planned |
| 🟢 **P2** | API reference | Generated API docs | 4h | Planned |
| 🟢 **P2** | Examples | Code examples for all functions | 5h | Planned |

### Help Files

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🔴 **P0** | Complete :h files | All modules documented | 8h | In Progress |
| 🟡 **P1** | Cross-references | Link related topics | 2h | Planned |
| 🟢 **P2** | Search tags | Comprehensive tag index | 3h | Planned |

---

## Architecture

### Refactoring

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟢 **P2** | Decouple display | Abstract window management | 8h | Planned |
| 🟢 **P2** | Plugin system | Allow third-party extensions | 10h | Planned |
| ⚪ **P3** | Event bus | Central event coordination | 12h | Backlog |

### Dependencies

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟡 **P1** | Remove lib dependencies | Make lib.buf_win_tab optional | 6h | Planned |
| 🟢 **P2** | Vendored dependencies | Include critical deps | 4h | Planned |
| ⚪ **P3** | Plugin manager integration | Support lazy.nvim, packer, etc. | 8h | Backlog |

### Extensibility

| Priority | Task | Description | Effort | Status |
|----------|------|-------------|--------|--------|
| 🟢 **P2** | Hook system | Allow custom hooks | 6h | Planned |
| 🟢 **P2** | Custom providers | User-defined data providers | 8h | Planned |
| ⚪ **P3** | Middleware | Transform/filter data pipeline | 10h | Backlog |

---

## Analysis Summary

### Module Health

| Module | Maturity | Test Coverage | Docs | Priority Areas |
|--------|----------|---------------|------|----------------|
| views | 🟡 Beta | 0% | ✅ Complete | Security, Tests |
| usercmds | 🟢 Stable | 0% | ✅ Complete | Tests, Features |
| terminals | 🟡 Beta | 0% | ✅ Complete | Security, File output |
| vardump | 🟢 Stable | 0% | ✅ Complete | Tests, Enhancements |
| nvim_options | 🟢 Stable | 0% | ✅ Complete | Tests |
| markdown | 🔴 Alpha | 0% | ✅ Complete | Stabilization |
| cursor | 🟡 Beta | 0% | ⚠️ Partial | Docs, Tests |
| autocmds | 🟡 Beta | 0% | ⚠️ Partial | Docs, Tests |

### Critical Gaps

1. **🔴 Zero test coverage** - All modules need tests
2. **🔴 Security validation** - Input validation missing
3. **🟡 Incomplete docs** - cursor, autocmds need :h files
4. **🟡 No CI/CD** - Need automated testing

### Recommended Next Steps

#### Immediate (Next Release)

1. Complete all :h files (cursor, autocmds)
2. Add input validation to all commands
3. Implement sanitize_file_paths()
4. Add basic unit tests for views module

#### Short-term (1-2 Releases)

1. Export formats for views
2. KeymapReport, AutocmdReport commands
3. File output for terminal keylogger
4. Property-based tests

#### Long-term (2-3 Releases)

1. Plugin system for extensions
2. SQLite message persistence
3. Dashboard UI
4. Remote logging

---

## Contributing

Want to help? Pick a task from the roadmap!

### How to Contribute

1. Check "Status" column for "Planned" items
2. Assign yourself in GitHub Issues
3. Follow [Arch&Coding-Regeln.md](../../docs/Arch&Coding-Regeln.md)
4. Submit PR with tests + docs

### High-Impact, Low-Effort Tasks

| Task | Priority | Effort | Impact |
|------|----------|--------|--------|
| Export formats | 🟡 P1 | 3h | High |
| Sanitize paths | 🔴 P0 | 2h | High |
| Debounce refresh | 🟡 P1 | 2h | Medium |
| KeymapReport | 🟡 P1 | 4h | High |
| File output (keylogger) | 🟡 P1 | 2h | Medium |

---

## License

MIT
