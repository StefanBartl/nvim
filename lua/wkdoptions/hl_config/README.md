# wkdoptions.hl_config

Visual/UX feature orchestrator. Delegates to specialized feature modules
(breadcrumbs, cword_occurrences, path_cache, ...) and uses centralized state
management (`core/state`: feature flags, window-local mode cache,
namespace/augroup registry).
