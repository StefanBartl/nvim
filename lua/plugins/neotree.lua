-- Plugin: Neo-tree
-- https://github.com/rafi/vim-config
-- TODO: Functions für keymaps in separate files so nvimtree also can uses thems
return {

	-----------------------------------------------------------------------------
	-- File explorer written in Lua
	'neo-tree.nvim',
	branch = 'v3.x',
	dependencies = { 'MunifTanjim/nui.nvim' },
	lazy = false,
	-- stylua: ignore
	keys = {
		{ '<localleader>e', '<leader>fe', desc = 'Explorer Tree (Root Dir)', remap = true },
		{ '<localleader>E', '<leader>fE', desc = 'Explorer Tree (cwd)',      remap = true },
		{
			'<localleader>a',
			function()
				require('neo-tree.command').execute({ reveal = true, dir = LazyVim.root() })
			end,
			desc = 'Reveal in Explorer',
		},
		{
			'<localleader>A',
			function()
				require('neo-tree.command').execute({ reveal = true, dir = vim.uv.cwd() })
			end,
			desc = 'Reveal in Explorer (cwd)',
		},
	},
	-- See: https://github.com/nvim-neo-tree/neo-tree.nvim
	opts = {
		enable_git_status = has_git,
		close_if_last_window = true,
		popup_border_style = 'rounded',
		sort_case_insensitive = true,

		source_selector = {
			winbar = false,
			show_scrolled_off_parent_node = true,
			padding = { left = 1, right = 0 },
			sources = {
				{ source = 'filesystem', display_name = '  Files' }, --      
				{ source = 'buffers', display_name = '  Buffers' }, --      
				{ source = 'git_status', display_name = ' 󰊢 Git' }, -- 󰊢      
			},
		},

		event_handlers = {
			-- Close neo-tree when opening a file.
			{
				event = 'file_opened',
				handler = function()
					require('neo-tree').close_all()
				end,
			},
		},

		default_component_configs = {
			indent = {
				with_expanders = false,
			},
			icon = {
				folder_empty = '',
				folder_empty_open = '',
				default = '',
			},
			modified = {
				symbol = '•',
			},
			name = {
				trailing_slash = true,
				highlight_opened_files = true,
				use_git_status_colors = false,
			},
			git_status = {
				symbols = {
					-- Change type
					added = 'A',
					deleted = 'D',
					modified = 'M',
					renamed = 'R',
					-- Status type
					untracked = 'U',
					ignored = 'I',
					unstaged = '',
					staged = 'S',
					conflict = 'C',
				},
			},
		},

    window = {
      width = 30,
      mappings = {
        -- basic
        ['q'] = 'close_window',
        ['?'] = 'noop',
        ['g?'] = 'show_help',
        ['<leader>'] = 'noop',

        -- clear filter, preview and search highlight
        ['<Esc>'] = function(state)
          require('neo-tree.sources.filesystem').reset_search(state, true)
          require('neo-tree.sources.filesystem.lib.filter_external').cancel()
          require('neo-tree.sources.common.preview').hide()
          vim.cmd([[ nohlsearch ]])
        end,

        -- open/close
        ['<2-LeftMouse>'] = 'open',
        ['<CR>'] = 'open_with_window_picker',
        ['l'] = function(state)
          local node = state.tree:get_node()
          if node.type == 'directory' or (node:has_children() and not node:is_expanded()) then
            state.commands.toggle_node(state)
          else
            state.commands.open(state)
          end
        end,
        ['h'] = 'close_node',
        ['C'] = 'close_node',
        ['z'] = 'close_all_nodes',
        ['<C-r>'] = 'refresh',

        -- splits/tabs
        ['s']  = 'noop',
        ['sv'] = 'open_split',
        ['sg'] = 'open_vsplit',
        ['st'] = 'open_tabnew',

        -- source switching (behalte nur <S-Tab>; <Tab> wird Preview)
        ['<S-Tab>'] = 'prev_source',
        -- ['<Tab>']   = 'next_source', -- entfernt

        -- file ops via neo-tree clipboard
        ['c'] = 'copy_to_clipboard',
        ['x'] = 'cut_to_clipboard',
        ['p'] = 'paste_from_clipboard',
        ['r'] = 'rename',

        -- create/delete
        ['dd'] = 'delete',
        ['a']  = { 'add', nowait = true, config = { show_path = 'relative' } },
        ['N']  = { 'add_directory', config = { show_path = 'relative' } },
        -- ['m']  = { 'move', config = { show_path = 'relative' } }, -- optional, falls weiter gewünscht

        -- preview: Tab toggelt Vorschau (floating), K = einmalige Vorschau (floating)
        ['<Tab>'] = { 'toggle_preview', config = { use_float = true } },
        ['K']     = { 'preview',        config = { use_float = true } },

        -- eigene Helfer: Pfade in die System-Clipboard (+)
        ['[a'] = {
          function(state)
            -- copy absolute path
            local node = state.tree:get_node()
            local path = node and (node.path or node:get_id()) or ""
            if path == "" then
              vim.notify("no path", vim.log.levels.WARN)
              return
            end
            vim.fn.setreg("+", path, "c")
            vim.notify(("copied: %s"):format(path), vim.log.levels.INFO)
          end,
          desc = "Copy absolute path (+)",
        },

        ['{ab'] = {
          function(state)
            -- copy base (directory) path
            local node = state.tree:get_node()
            local path = node and (node.path or node:get_id()) or ""
            if path == "" then
              vim.notify("no path", vim.log.levels.WARN)
              return
            end
            local base = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
            vim.fn.setreg("+", base, "c")
            vim.notify(("copied: %s"):format(base), vim.log.levels.INFO)
          end,
          desc = "Copy base (dir) path (+)",
        },

        -- bestehende Custom-Commands aus deiner Config
        ['w'] = function(state)
          local normal = state.window.width
          local large = normal * 1.9
          local small = math.floor(normal / 1.6)
          local cur_width = state.win_width
          local new_width = normal
          if cur_width > normal then
            new_width = small
          elseif cur_width == normal then
            new_width = large
          end
          vim.cmd(new_width .. ' wincmd |')
        end,

        ['Y'] = {
          function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg('+', path, 'c')
          end,
          desc = 'Copy Path to Clipboard',
        },

        ['O'] = {
          function(state)
            require('lazy.util').open(state.tree:get_node().path, { system = true })
          end,
          desc = 'Open with System Application',
        },


  -- Neo-tree mapping: open selected node in Windows Explorer (Windows-only)
-- Place this inside opts.window.mappings (replace your current ["M"] mapping).

-- Replace your ["M"] mapping with this Windows-only variant.
-- It handles both files (Explorer selects the file) and directories.
-- If "explorer.exe /select,<path>" fails (exit!=0), it falls back to
-- "cmd.exe /C start" which at least opens the containing folder.

["M"] = {
  ---@param state table
  function(state)
    if not (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) then
      vim.notify("Open in Explorer: Windows only", vim.log.levels.WARN)
      return
    end

    --- resolve node path
    ---@type any
    local node = state.tree:get_node()
    local raw = node and (node.path or node:get_id()) or ""
    if raw == "" then
      vim.notify("Open in Explorer: no path under cursor", vim.log.levels.WARN)
      return
    end

    --- normalize to absolute Windows path (backslashes)
    local function to_winpath(p)
      p = vim.fn.fnamemodify(p, ":p")
      p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
      p = p:gsub("/", "\\")
      return p
    end

    local abs = to_winpath(raw)
    local is_dir = (vim.fn.isdirectory(abs) == 1)
    local target_dir = is_dir and abs or to_winpath(vim.fn.fnamemodify(abs, ":h"))

    --- build primary + fallback commands
    --- primary: explorer.exe (with selection for files)
    --- fallback: cmd.exe /C start "" <dir>
    local primary
    if is_dir then
      primary = { "explorer.exe", target_dir }
    else
      primary = { "explorer.exe", "/select," .. abs }
    end
    local fallback = { "cmd.exe", "/C", "start", "", target_dir }

    --- run primary, and if it returns non-zero, run fallback
    local function run_primary_then_fallback()
      if vim.system then
        vim.system(primary, { text = true }, function(obj)
          if obj.code ~= 0 then
            -- try fallback without complaining first
            vim.system(fallback, { detach = true }, function(_)
              -- if fallback also fails, then notify
              -- (cmd.exe with 'start' usually returns 0 even if Explorer is busy)
            end)
          end
        end)
      else
        -- Neovim < 0.10
        local code = vim.fn.jobstart(primary, { detach = false })
        -- jobstart returns pid or <=0 on failure; we cannot get exit code reliably here.
        -- Always attempt the fallback if primary couldn't be started.
        if code <= 0 then
          vim.fn.jobstart(fallback, { detach = true })
        end
      end
    end

    run_primary_then_fallback()
  end,
  desc = "Open in Explorer (Windows)",
},

    ['+'] = {
      function(state)
        -- resolve to directory
        local node = state.tree:get_node()
        local path = node and (node.path or node:get_id()) or ""
        if path == "" then
          vim.notify("no path under cursor", vim.log.levels.WARN)
          return
        end
        local dir = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")

        -- change Neovim’s global cwd
        local ok, err = pcall(vim.api.nvim_set_current_dir, dir)
        if not ok then
          vim.notify(("cd failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
          return
        end

        -- retarget Neo-tree to that directory (reveal current context)
        local ok_cmd, _ = pcall(require, "neo-tree.command")
        if ok_cmd then
          require("neo-tree.command").execute({ source = "filesystem", dir = dir, reveal = true })
        end

        vim.notify(("cwd → %s"):format(dir), vim.log.levels.INFO)
      end,
      desc = "Set Neovim cwd to node and focus Neo-tree there",
    },


    -- in opts.window.mappings (Neo-tree)
    -- "-" moves the project root (Neovim-cwd) up one level and focuses Neo-tree on it

    ["-"] = {
      ---@param state table  -- neo-tree window state
      function(state)
        -- 1) Determine the "current root" baseline:
        --    Prefer Neo-tree's own root (state.path). If not available, fall back
        --    to the directory of the node under the cursor.
        ---@type string|nil
        local current_root = state.path
        if not current_root or current_root == "" then
          local node = state.tree:get_node()
          local path = node and (node.path or node:get_id()) or ""
          if path == "" then
            vim.notify("no path under cursor", vim.log.levels.WARN)
            return
          end
          current_root = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
        end

        -- 2) Compute parent directory (one level up)
        local parent = vim.fn.fnamemodify(current_root, ":h")

        -- Guard: if we're already at a filesystem root, :h returns the same path
        if parent == current_root or parent == "" then
          vim.notify("already at top-level directory", vim.log.levels.WARN)
          return
        end

        -- 3) Change Neovim's cwd to the parent
        local ok, err = pcall(vim.api.nvim_set_current_dir, parent)
        if not ok then
          vim.notify(("cd failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
          return
        end

        -- 4) Reopen Neo-tree at the new root and reveal context
        local ok_cmd, cmd = pcall(require, "neo-tree.command")
        if ok_cmd and cmd then
          cmd.execute({ source = "filesystem", dir = parent, reveal = true })
        end

        vim.notify(("cwd → %s"):format(parent), vim.log.levels.INFO)
      end,
      desc = "Up one level: set cwd to parent and focus Neo-tree there",
    }





      },
    },

		filesystem = {
			bind_to_cwd = false,
			follow_current_file = { enabled = false },
			find_by_full_path_words = true,
			group_empty_dirs = true,
			use_libuv_file_watcher = has_git,
			window = {
				mappings = {
					['d'] = 'noop',
					['/'] = 'noop',
					['f'] = 'filter_on_submit',
					['F'] = 'fuzzy_finder',
					['<C-c>'] = 'clear_filter',

				},
			},

			filtered_items = {
				hide_dotfiles = false,
				hide_gitignored = false,
				hide_by_name = {
					'.git',
					'.hg',
					'.svc',
					'.DS_Store',
					'thumbs.db',
					'.sass-cache',
					'node_modules',
					'.pytest_cache',
					'.mypy_cache',
					'__pycache__',
					'.stfolder',
					'.stversions',
				},
				never_show_by_pattern = {
					'vite.config.js.timestamp-*',
				},
			},
		},
		buffers = {
			window = {
				mappings = {
					['dd'] = 'buffer_delete',
				},
			},
		},
		git_status = {
			window = {
				mappings = {
					['d'] = 'noop',
					['dd'] = 'delete',
				},
			},
		},
		document_symbols = {
			follow_cursor = true,
			window = {
				mappings = {
					['/'] = 'noop',
					['F'] = 'filter',
				},
			},
		},
	},
}
