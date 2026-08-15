# wkdoptions.hl_config.path_cache

Buffer-local cache for repo root and repo-relative path. Tiny and
dependency-free; reduces repeated upward searches on every
`CursorMoved`/`WinScrolled` event when the winbar updates.
