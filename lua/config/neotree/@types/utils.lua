---@module 'config.neotree.@types.utils'

---@class Cfg.NeoTree.Utils
---@field init Cfg.NeoTree.Utils.Module
---@field node Cfg.NeoTree.Utils.Node
---@field buffer Cfg.NeoTree.Utils.Buffer
---@field path Cfg.NeoTree.Utils.Path
---@field platform Cfg.NeoTree.Utils.Platform
---@field tree Cfg.NeoTree.Utils.Tree
---@field selective_callback_guard Cfg.NeoTree.Utils.SelectiveCallbackGuard

--- Unified utilities for Neo-tree configuration.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.Module
---@field safe_hide_preview fun(): boolean
---@field get_current_position fun(): string|nil
---@field is_neotree_open fun(): boolean

--- Utility functions for working with Neo-tree nodes.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.Node
---@field get_current fun(state: Cfg.NeoTree.State): Cfg.NeoTree.Node|nil
---@field get_path fun(node: Cfg.NeoTree.Node|nil): (string, boolean)
---@field collect_nodes fun(state: Cfg.NeoTree.State): Cfg.NeoTree.Node[]
---@field extract_paths fun(nodes: table[]): (string[], string[])
---@field get_line_number fun(bufnr: integer, node_id: integer|string): integer|nil

--- Buffer validation and context utilities with caching.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.Buffer
---@field is_valid_file_buffer fun(bufnr: integer|nil): boolean
---@field invalidate_cache fun(bufnr: integer): nil
---@field clear_cache fun(): nil
---@field get_buffer_context fun(bufnr: integer|nil): {buf: integer, file: string, dir: string}|nil
---@field find_last_normal_buffer fun(exclude_win: integer|nil): (integer|nil, integer|nil)
---@field close_related_buffers fun(path: string): nil

--- Unified path operations: normalize, escape, convert, transform.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.Path
---@field normalize fun(path: string|nil): string
---@field to_absolute fun(path: string): string
---@field to_unix_path fun(path: string): string
---@field to_win_path fun(path: string): string
---@field get_parent fun(path: string): string
---@field ensure_dir fun(path: string): string
---@field to_relative fun(path: string, base: string|nil): string
---@field from_node fun(node: table, mode: "absolute"|"relative"|"base_absolute"|"base_relative", opts?: {base_dir?: string}): (string|nil, string|nil)
---@field escape_shell_arg fun(path: string): string
---@field quote_if_needed fun(path: string): string

--- Platform detection utilities.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.Platform
---@field is_windows fun(): boolean
---@field is_wsl fun(): boolean
---@field is_macos fun(): boolean
---@field is_unix fun(): boolean
---@field has_executable fun(name: string): boolean
---@field get_cwd fun(): string

--- Selectively disable problematic Neo-tree callbacks.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.SelectiveCallbackGuard
---@field disable_events fun(event_names: string[]|nil): boolean
---@field enable_events fun(use_safe_wrapper: boolean|nil): boolean
---@field with_events_disabled fun(fn: function, restore_delay_ms: integer|nil, events_to_disable: string[]|nil): (boolean, any)
---@field get_disabled_events fun(): string[]
---@field is_disabled fun(): boolean

--- Recursive tree traversal for file/folder collection.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.Tree
---@field collect_recursive fun(root_path: string, collect_type: "files"|"folders"): string[]
---@field collect_files fun(root_path: string): string[]
---@field collect_folders fun(root_path: string): string[]
---@field collect_for_node fun(state: Cfg.NeoTree.State, collect_type: "files"|"folders"): (string[], string)

return {}
