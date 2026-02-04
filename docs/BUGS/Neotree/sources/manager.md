

---@class neotree.SourceData
---@field name string
---@field state_by_tab table<integer, neotree.State>
---@field state_by_win table<integer, neotree.State>
---@field subscriptions table
---@field module neotree.Source?

---@param source_name string
---@return neotree.SourceData
local get_source_data = function(source_name)
end

---@class neotree.State.Window : neotree.Config.Window
---@field win_width integer
---@field last_user_width integer

---@alias neotree.State.CurrentPosition "top"|"bottom"|"left"|"right"|"current"|"float"

---@alias neotree.Internal.SortFieldProvider fun(node: NuiTree.Node):any

---@alias neotree.Config.SortFunction fun(a: NuiTree.Node, b: NuiTree.Node):boolean?

---@class neotree.State : neotree.Config.Source
---@field name string
---@field tabid integer
---@field id integer
---@field bufnr integer?
---@field dirty boolean
---@field position neotree.State.Position
---@field git_base_by_worktree table<string,string?>?
---@field sort table
---@field clipboard neotree.clipboard.Contents
---@field current_position neotree.State.CurrentPosition?
---@field disposed boolean?
---@field winid integer?
---@field path string?
---@field tree NuiTree?
---@field components table<string, neotree.Component>
---private-ish
---@field orig_tree NuiTree?
---@field _ready boolean?
---@field loading boolean?
---window
---@field window neotree.State.Window?
---@field win_width integer?
---@field longest_width_exact integer?
---@field longest_node integer?
---extras
---@field bind_to_cwd boolean?
---@field opened_buffers neotree.utils.OpenedBuffers?
---@field diagnostics_lookup neotree.utils.DiagnosticLookup?
---@field cwd_target neotree.Config.Filesystem.CwdTarget?
---@field sort_field_provider fun(node: NuiTree.Node):any
---@field explicitly_opened_nodes table<string, boolean?>?
---@field filtered_items neotree.Config.Filesystem.FilteredItems?
---@field skip_marker_at_level table<integer, boolean?>?
---@field group_empty_dirs boolean?
---optional mapping args
---@field fallback string?
---@field config table?
---internal
---@field default_expanded_nodes NuiTree.Node[]?
---@field force_open_folders string[]?
---@field enable_source_selector boolean?
---@field follow_current_file neotree.Config.Filesystem.FollowCurrentFile?
---lsp
---@field lsp_winid number?
---@field lsp_bufnr number?
---search
---@field search_pattern string?
---@field use_fzy boolean?
---@field fzy_sort_result_scores table<string, integer?>?
---@field fuzzy_finder_mode "directory"|boolean?
---@field open_folders_before_search table?
---sort
---@field sort_function_override neotree.Config.SortFunction?
---keymaps
---@field resolved_mappings table<string, neotree.State.ResolvedMapping?>?
---@field commands table<string, neotree.TreeCommand?>?

---@class (exact) neotree.StateWithTree : neotree.State
---@field tree NuiTree
---@field _in_pre_render boolean?

---@param tabid integer
---@param sd table
---@param winid integer?
---@return neotree.State
local function create_state(tabid, sd, winid)
end

M._get_all_states = function()
  return all_states
end

---@param source_name string?
---@param action fun(state: neotree.State)
M._for_each_state = function(source_name, action)
end

---For use in tests only, completely resets the state of all sources.
---This closes all windows as well since they would be broken by this action.
M._clear_state = function()
end

---@param source_name string
---@param config neotree.Config.Source
M.set_default_config = function(source_name, config)
end

--TODO: we need to track state per window when working with netwrw style "current"
--position. How do we know which one to return when this is called?
---@param source_name string
---@param tabid integer?
---@param winid integer?
---@return neotree.State
M.get_state = function(source_name, tabid, winid)
end

---Modifies an existing state. Does not currently create a new one if one does not exist.
---@param source_name string
---@param tabid integer?
---@param winid integer?
---@param override table
---@return neotree.State new_state
M._change_state = function(source_name, tabid, winid, override)
end

---Returns the state for the current buffer, assuming it is a neo-tree buffer.
---@param winid number? The window id to use, if nil, the current window is used.
---@return neotree.State? state The state for the current buffer, if it's a neo-tree buffer.
M.get_state_for_window = function(winid)
end

---Get the path to reveal in the file tree.
---@param include_terminals boolean?
---@return string? path
M.get_path_to_reveal = function(include_terminals)
end

---@param source_name string
M.subscribe = function(source_name, event)
end

---@param source_name string
M.unsubscribe = function(source_name, event)
end

---@param source_name string
M.unsubscribe_all = function(source_name)
end

---@param source_name string
M.close = function(source_name, at_position)
end

M.close_all = function(at_position)
end

M.close_all_except = function(except_source_name)
end

---Redraws the tree with updated diagnostics without scanning the filesystem again.
---@param source_name string
---@param args table<string, neotree.utils.DiagnosticCounts?>
M.diagnostics_changed = function(source_name, args)
end

---Called by autocmds when the cwd dir is changed. This will change the root.
---@param source_name string
M.dir_changed = function(source_name)
end
--
---Redraws the tree with updated git_status without scanning the filesystem again.
---@param source_name string
---@param args neotree.event.args.GIT_STATUS_CHANGED
M.git_status_changed = function(source_name, args)
end

---@param state neotree.State
local get_params_for_cwd = function(state)
end

---@param state neotree.State
---@return string
M.get_cwd = function(state)
end

---@param state neotree.State
M.set_cwd = function(state)
end

---@param state neotree.State
local dispose_state = function(state)
end

---@param source_name string
---@param tabid integer
M.dispose = function(source_name, tabid)
end

---@param tabid integer
M.dispose_tab = function(tabid)
end

M.dispose_invalid_tabs = function()
end

---@param winid number
M.dispose_window = function(winid)
end

---@param source_name string
M.float = function(source_name)
end

---Focus the window, opening it if it is not already open.
---@param source_name string Source name.
---@param path_to_reveal string|nil Node to focus after the items are loaded.
---@param callback function|nil Callback to call after the items are loaded.
M.focus = function(source_name, path_to_reveal, callback)
end

---Redraws the tree with updated modified markers without scanning the filesystem again.
M.opened_buffers_changed = function(source_name, args)
end

---Navigate to the given path.
---@param state_or_source_name neotree.State|string The state or source name to navigate.
---@param path string? Path to navigate to. If empty, will navigate to the cwd.
---@param path_to_reveal string? Node to focus after the items are loaded.
---@param callback function? Callback to call after the items are loaded.
---@param async boolean? Whether to load the items asynchronously, may not be respected by all sources.
M.navigate = function(state_or_source_name, path, path_to_reveal, callback, async)
end

---Redraws the tree without scanning the filesystem again. Use this after
-- making changes to the nodes that would affect how their components are
-- rendered.
M.redraw = function(source_name)
end

---Refreshes the tree by scanning the filesystem again.
---@param source_name string
---@param callback function?
M.refresh = function(source_name, callback)
end

--- @deprecated
--- To be removed in 4.0. Use:
--- ```lua
--- require("neo-tree.command").execute({ source_name = source_name, action = "focus", reveal = true })` instead
--- ```
M.reveal_current_file = function(source_name, callback, force_cwd)
end

---@deprecated
--- To be removed in 4.0. Use:
--- ```lua
--- require("neo-tree.command").execute({ source_name = source_name, action = "focus", reveal = true, position = "current" }
--- ```
--- instead.
M.reveal_in_split = function(source_name, callback)
end
---Opens the tree and displays the current path or cwd, without focusing it.
-show = function(source_name)
end

M.show_in_split = function(source_name, callback)
end

-@param source_name string
-@param module neotree.Source
validate_source = function(source_name, module)

---Configures the plugin, should be called before the plugin is used.
---@param source_name string Name of the source.
---@param config neotree.Config.Source Configuration table containing merged configuration for the source.
---@param global_config neotree.Config.Base Global configuration table, shared between all sources.
---@param module neotree.Source Module containing the source's code.
M.setup = function(source_name, config, global_config, module)date_source
