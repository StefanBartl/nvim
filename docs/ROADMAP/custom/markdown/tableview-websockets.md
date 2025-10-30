# Detailliertes Architektur-Dokument: Bidirektionale Markdown-Preview

## Projektstruktur

```
lua/markdown-preview-sync/
├── init.lua                          # Plugin-Entrypoint
├── config.lua                        # Konfiguration & Setup
├── health.lua                        # :checkhealth Integration
│
├── types/
│   └── init.lua                      # Zentrale Type-Definitionen
│
├── core/
│   ├── sync_engine.lua               # Synchronisations-Logik
│   ├── position_mapper.lua           # Markdown ↔ HTML Mapping
│   └── buffer_watcher.lua            # Buffer-Change-Detection
│
├── server/
│   ├── websocket_server.lua          # WebSocket-Server (vim.loop)
│   ├── http_server.lua               # Statische Dateien
│   └── protocol.lua                  # Nachrichtenformat
│
├── ui/
│   ├── preview_window.lua            # Browser-Launch-Logik
│   └── status_display.lua            # Statusline-Integration
│
├── utils/
│   ├── async.lua                     # Async-Helpers (debounce, etc.)
│   ├── platform.lua                  # Cross-Platform-Utilities
│   └── logger.lua                    # Debug-Logging
│
└── web/                              # Frontend-Dateien
    ├── index.html                    # Preview-Template
    ├── script.js                     # Client-JS
    └── style.css                     # Styling
```

---

## 1. Type-Definitionen (`types/init.lua`)

```lua
---@module 'markdown-preview-sync.types'
---@brief Central type definitions for the markdown-preview-sync plugin.
---@description
--- This module defines all custom types, aliases, and data structures used
--- throughout the plugin. It serves as a single source of truth for type
--- annotations and should be referenced by all other modules.

---@alias SyncDirection
---| "nvim_to_browser"  # Cursor movement in Neovim triggers browser scroll
---| "browser_to_nvim"  # Browser scroll/click triggers Neovim cursor movement

---@alias ConnectionState
---| "disconnected"  # No active WebSocket connection
---| "connecting"    # Handshake in progress
---| "connected"     # Active bidirectional communication
---| "error"         # Connection failed, awaiting reconnect

---@alias MessageType
---| "scroll_to_line"      # Request to scroll to specific line
---| "cursor_moved"        # Notify cursor position changed
---| "buffer_updated"      # Buffer content changed, re-render needed
---| "ping"                # Heartbeat keepalive
---| "pong"                # Heartbeat response
---| "sync_state"          # Full state sync after reconnect

---@class PreviewConfig
---@field port integer Port for WebSocket server (0 = auto-assign)
---@field host string Bind address ("127.0.0.1" for local-only)
---@field browser string|nil Browser command (nil = system default)
---@field auto_start boolean Start preview on entering markdown buffer
---@field auto_close boolean Stop server when last markdown buffer closes
---@field debounce_ms integer Debounce delay for scroll events (ms)
---@field sync_cursor boolean Enable Neovim → Browser sync
---@field sync_scroll boolean Enable Browser → Neovim sync
---@field log_level "debug"|"info"|"warn"|"error" Logging verbosity

---@class LineMapping
---@field markdown_line integer Line number in Neovim buffer (1-indexed)
---@field html_id string CSS selector for corresponding HTML element
---@field element_type string Type of HTML element (h1, p, li, etc.)
---@field nesting_level integer Depth in document structure (0 = root)

---@class SyncState
---@field last_nvim_line integer|nil Last cursor position sent to browser
---@field last_browser_offset integer|nil Last scroll position from browser
---@field ignore_next_nvim boolean Flag to prevent scroll loop
---@field ignore_next_browser boolean Flag to prevent scroll loop
---@field pending_sync boolean Debounce timer active

---@class ServerState
---@field ws_server uv_tcp_t|nil WebSocket server handle
---@field http_server uv_tcp_t|nil HTTP server handle
---@field active_clients table<uv_tcp_t, boolean> Connected WebSocket clients
---@field port integer Actual port (after auto-assignment)
---@field connection_state ConnectionState Current connection status

---@class ProtocolMessage
---@field type MessageType Message category
---@field data table Message payload (type-specific)
---@field timestamp integer Unix timestamp (ms)
---@field source "nvim"|"browser" Origin of the message

---@class BufferMetadata
---@field bufnr integer Buffer handle
---@field filepath string Absolute path to markdown file
---@field last_modified integer Timestamp of last change
---@field line_count integer Current number of lines
---@field mapping_cache LineMapping[] Cached line mappings
```

---

## 2. Konfiguration (`config.lua`)

```lua
---@module 'markdown-preview-sync.config'
---@brief Configuration management for markdown-preview-sync.
---@description
--- Handles user-provided configuration, merges with defaults, validates
--- settings, and provides a unified interface for accessing options.
--- Follows the pattern from your Arch&Coding-Regeln.md (Kap. 5).

local M = {}

-- Utilities
local notify = require("markdown-preview-sync.utils.logger").notify
local platform = require("markdown-preview-sync.utils.platform")

---@type PreviewConfig
local defaults = {
  port = 0, -- Auto-assign
  host = "127.0.0.1",
  browser = nil, -- System default
  auto_start = false,
  auto_close = true,
  debounce_ms = 200,
  sync_cursor = true,
  sync_scroll = true,
  log_level = "info",
}

---@type PreviewConfig
M.options = vim.deepcopy(defaults)

--- Validates configuration values and sanitizes input.
---@param opts table User-provided config
---@return boolean success
---@return string|nil error_message
local function validate_config(opts)
  if opts.port and (opts.port < 0 or opts.port > 65535) then
    return false, "Port must be between 0 and 65535"
  end

  if opts.debounce_ms and opts.debounce_ms < 0 then
    return false, "debounce_ms must be non-negative"
  end

  if opts.log_level then
    local valid_levels = {debug = true, info = true, warn = true, error = true}
    if not valid_levels[opts.log_level] then
      return false, "log_level must be one of: debug, info, warn, error"
    end
  end

  return true
end

--- Merges user config with defaults and applies to M.options.
---@param opts PreviewConfig|nil User configuration
---@return boolean success
function M.setup(opts)
  opts = opts or {}

  local ok, err = validate_config(opts)
  if not ok then
    notify("Config validation failed: " .. err, vim.log.levels.ERROR)
    return false
  end

  M.options = vim.tbl_deep_extend("force", defaults, opts)

  -- Platform-specific overrides
  if not M.options.browser then
    M.options.browser = platform.get_default_browser()
  end

  return true
end

--- Retrieves a specific config option with fallback.
---@param key string Option name
---@return any
function M.get(key)
  return M.options[key]
end

--- Updates a config option at runtime.
---@param key string Option name
---@param value any New value
function M.set(key, value)
  if defaults[key] == nil then
    notify("Unknown config key: " .. key, vim.log.levels.WARN)
    return
  end
  M.options[key] = value
end

return M
```

---

## 3. Synchronisations-Engine (`core/sync_engine.lua`)

```lua
---@module 'markdown-preview-sync.core.sync_engine'
---@brief Core synchronization logic with loop prevention.
---@description
--- Central orchestrator for bidirectional position sync. Implements
--- debouncing, ignore-flags, and state tracking to prevent infinite loops.
--- Follows pure function principles where possible (Arch&Coding-Regeln Kap. 2).

local M = {}

-- Dependencies
local config = require("markdown-preview-sync.config")
local logger = require("markdown-preview-sync.utils.logger")
local async = require("markdown-preview-sync.utils.async")

---@type SyncState
local state = {
  last_nvim_line = nil,
  last_browser_offset = nil,
  ignore_next_nvim = false,
  ignore_next_browser = false,
  pending_sync = false,
}

--- Debounced timer for Neovim cursor movements
local nvim_debounce_timer = nil

--- Debounced timer for browser scroll events
local browser_debounce_timer = nil

--- Resets all sync state (used after reconnect or buffer switch).
function M.reset_state()
  state.last_nvim_line = nil
  state.last_browser_offset = nil
  state.ignore_next_nvim = false
  state.ignore_next_browser = false
  state.pending_sync = false

  if nvim_debounce_timer then
    nvim_debounce_timer:stop()
    nvim_debounce_timer:close()
    nvim_debounce_timer = nil
  end

  if browser_debounce_timer then
    browser_debounce_timer:stop()
    browser_debounce_timer:close()
    browser_debounce_timer = nil
  end
end

--- Handles cursor movement in Neovim.
--- Debounces rapid movements and sends scroll command to browser.
---@param line integer Current cursor line (1-indexed)
---@param bufnr integer Buffer handle
function M.on_cursor_moved(line, bufnr)
  if not config.get("sync_cursor") then
    return
  end

  -- Check ignore flag (prevents loop)
  if state.ignore_next_nvim then
    state.ignore_next_nvim = false
    logger.debug("Ignoring cursor move (loop prevention)")
    return
  end

  -- Cancel existing timer
  if nvim_debounce_timer then
    nvim_debounce_timer:stop()
  end

  -- Create new debounced action
  nvim_debounce_timer = vim.loop.new_timer()
  nvim_debounce_timer:start(config.get("debounce_ms"), 0, vim.schedule_wrap(function()
    state.last_nvim_line = line

    -- Send to browser via WebSocket
    local ws = require("markdown-preview-sync.server.websocket_server")
    local ok, err = pcall(ws.broadcast, {
      type = "scroll_to_line",
      data = {line = line, bufnr = bufnr},
      timestamp = os.time() * 1000,
      source = "nvim",
    })

    if not ok then
      logger.error("Failed to send scroll command: " .. tostring(err))
    end
  end))
end

--- Handles scroll event from browser.
--- Calculates corresponding Neovim line and moves cursor.
---@param browser_offset integer Scroll position in pixels
---@param html_id string|nil ID of element at scroll position
function M.on_browser_scroll(browser_offset, html_id)
  if not config.get("sync_scroll") then
    return
  end

  -- Check ignore flag
  if state.ignore_next_browser then
    state.ignore_next_browser = false
    logger.debug("Ignoring browser scroll (loop prevention)")
    return
  end

  -- Cancel existing timer
  if browser_debounce_timer then
    browser_debounce_timer:stop()
  end

  browser_debounce_timer = vim.loop.new_timer()
  browser_debounce_timer:start(config.get("debounce_ms"), 0, vim.schedule_wrap(function()
    state.last_browser_offset = browser_offset

    -- Convert HTML element to markdown line
    local mapper = require("markdown-preview-sync.core.position_mapper")
    local line = mapper.html_to_markdown_line(html_id)

    if not line then
      logger.warn("Could not map HTML ID to markdown line: " .. tostring(html_id))
      return
    end

    -- Set ignore flag BEFORE moving cursor (prevents triggering on_cursor_moved)
    state.ignore_next_nvim = true

    -- Move cursor in Neovim
    local win = vim.api.nvim_get_current_win()
    local ok, err = pcall(vim.api.nvim_win_set_cursor, win, {line, 0})

    if not ok then
      logger.error("Failed to set cursor: " .. tostring(err))
      state.ignore_next_nvim = false -- Reset flag on error
    end
  end))
end

--- Creates a snapshot of current sync state for testing/debugging.
---@return SyncState
function M.get_state_snapshot()
  return vim.deepcopy(state)
end

--- Restores sync state from a snapshot (used in tests).
---@param snapshot SyncState
function M.restore_state(snapshot)
  state = vim.deepcopy(snapshot)
end

return M
```

---

## 4. Position-Mapper (`core/position_mapper.lua`)

```lua
---@module 'markdown-preview-sync.core.position_mapper'
---@brief Bidirectional mapping between Markdown lines and HTML elements.
---@description
--- Maintains a mapping cache that correlates Neovim buffer lines with rendered
--- HTML element IDs. Handles complex cases like nested lists, code blocks, and
--- inline HTML. Uses weak tables for automatic memory management.

local M = {}

local logger = require("markdown-preview-sync.utils.logger")

--- Cache of line mappings per buffer
---@type table<integer, LineMapping[]>
local mapping_cache = setmetatable({}, {__mode = "k"}) -- Weak keys (buffer GC)

--- Builds the line mapping for a given buffer by parsing markdown.
--- This is called after rendering the HTML and should correlate each
--- markdown line with its corresponding HTML element ID.
---@param bufnr integer Buffer handle
---@param html_content string Rendered HTML with data-source-line attributes
---@return LineMapping[]
function M.build_mapping(bufnr, html_content)
  local mappings = {}

  -- Parse HTML and extract data-source-line attributes
  -- This is a simplified regex approach; production code should use a proper HTML parser
  for line_str, element_id in html_content:gmatch('data%-source%-line="(%d+)"[^>]*id="([^"]+)"') do
    local line = tonumber(line_str)
    if line then
      table.insert(mappings, {
        markdown_line = line,
        html_id = element_id,
        element_type = "unknown", -- Could be extracted from tag name
        nesting_level = 0, -- Could be calculated from DOM depth
      })
    end
  end

  -- Sort by line number for binary search later
  table.sort(mappings, function(a, b)
    return a.markdown_line < b.markdown_line
  end)

  mapping_cache[bufnr] = mappings
  logger.debug(string.format("Built mapping cache: %d entries for buffer %d", #mappings, bufnr))

  return mappings
end

--- Converts a markdown line number to the corresponding HTML element ID.
---@param line integer Markdown line (1-indexed)
---@param bufnr integer|nil Buffer handle (defaults to current)
---@return string|nil html_id
function M.markdown_line_to_html_id(line, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local mappings = mapping_cache[bufnr]
  if not mappings or #mappings == 0 then
    logger.warn("No mapping cache for buffer " .. bufnr)
    return nil
  end

  -- Binary search for exact match or closest line
  local left, right = 1, #mappings
  local best_match = nil

  while left <= right do
    local mid = math.floor((left + right) / 2)
    local mapping = mappings[mid]

    if mapping.markdown_line == line then
      return mapping.html_id
    elseif mapping.markdown_line < line then
      best_match = mapping -- Closest line below target
      left = mid + 1
    else
      right = mid - 1
    end
  end

  -- Return closest match if exact not found
  return best_match and best_match.html_id or nil
end

--- Converts an HTML element ID to the corresponding markdown line.
---@param html_id string Element ID from browser
---@param bufnr integer|nil Buffer handle
---@return integer|nil line
function M.html_to_markdown_line(html_id, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local mappings = mapping_cache[bufnr]
  if not mappings then
    return nil
  end

  -- Linear search (could be optimized with reverse index)
  for _, mapping in ipairs(mappings) do
    if mapping.html_id == html_id then
      return mapping.markdown_line
    end
  end

  logger.warn("No markdown line found for HTML ID: " .. html_id)
  return nil
end

--- Invalidates the mapping cache for a buffer (call after edits).
---@param bufnr integer
function M.invalidate_cache(bufnr)
  mapping_cache[bufnr] = nil
end

--- Returns all mappings for debugging.
---@param bufnr integer
---@return LineMapping[]|nil
function M.get_mappings(bufnr)
  return mapping_cache[bufnr]
end

return M
```

---

## 5. WebSocket-Server (`server/websocket_server.lua`)

```lua
---@module 'markdown-preview-sync.server.websocket_server'
---@brief WebSocket server implementation using vim.loop (libuv).
---@description
--- Handles WebSocket handshake, frame parsing, and bidirectional messaging.
--- Supports multiple concurrent clients (for future multi-window support).
--- Implements heartbeat mechanism for connection health checks.

local M = {}

local config = require("markdown-preview-sync.config")
local logger = require("markdown-preview-sync.utils.logger")
local protocol = require("markdown-preview-sync.server.protocol")

---@type ServerState
local state = {
  ws_server = nil,
  http_server = nil,
  active_clients = {},
  port = 0,
  connection_state = "disconnected",
}

--- Performs WebSocket handshake (RFC 6455).
---@param client uv_tcp_t Client socket
---@param request string HTTP request headers
---@return boolean success
local function perform_handshake(client, request)
  local key = request:match("Sec%-WebSocket%-Key: ([^\r\n]+)")
  if not key then
    logger.error("Invalid WebSocket handshake: missing Sec-WebSocket-Key")
    return false
  end

  -- Compute accept key
  local magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
  local accept = vim.fn.sha256(key .. magic)
  accept = vim.fn.base64encode(accept)

  local response = table.concat({
    "HTTP/1.1 101 Switching Protocols",
    "Upgrade: websocket",
    "Connection: Upgrade",
    "Sec-WebSocket-Accept: " .. accept,
    "\r\n",
  }, "\r\n")

  client:write(response)
  return true
end

--- Parses a WebSocket frame and extracts payload.
---@param data string Raw frame bytes
---@return string|nil payload
---@return boolean is_close_frame
local function parse_frame(data)
  if #data < 2 then
    return nil, false
  end

  local byte1 = data:byte(1)
  local byte2 = data:byte(2)

  local fin = bit.band(byte1, 0x80) ~= 0
  local opcode = bit.band(byte1, 0x0F)
  local masked = bit.band(byte2, 0x80) ~= 0
  local payload_len = bit.band(byte2, 0x7F)

  -- Handle close frame
  if opcode == 0x08 then
    return nil, true
  end

  -- Only support text frames (opcode 0x01) for now
  if opcode ~= 0x01 then
    return nil, false
  end

  -- Parse extended payload length
  local offset = 2
  if payload_len == 126 then
    payload_len = bit.bor(bit.lshift(data:byte(3), 8), data:byte(4))
    offset = 4
  elseif payload_len == 127 then
    -- 64-bit length not implemented (unlikely for our use case)
    logger.error("64-bit payload length not supported")
    return nil, false
  end

  -- Extract masking key (4 bytes)
  local mask = {}
  if masked then
    for i = 1, 4 do
      mask[i] = data:byte(offset + i)
    end
    offset = offset + 4
  end

  -- Extract and unmask payload
  local payload_bytes = {}
  for i = 1, payload_len do
    local byte = data:byte(offset + i)
    if masked then
      byte = bit.bxor(byte, mask[((i - 1) % 4) + 1])
    end
    table.insert(payload_bytes, string.char(byte))
  end

  return table.concat(payload_bytes), false
end

--- Sends a message to a specific client.
---@param client uv_tcp_t
---@param message ProtocolMessage
---@return boolean success
local function send_to_client(client, message)
  local payload = protocol.encode(message)

  -- Build WebSocket frame (simplified, no masking)
  local frame = {}
  table.insert(frame, string.char(0x81)) -- FIN + text frame

  local len = #payload
  if len < 126 then
    table.insert(frame, string.char(len))
  elseif len < 65536 then
    table.insert(frame, string.char(126))
    table.insert(frame, string.char(bit.rshift(len, 8)))
    table.insert(frame, string.char(bit.band(len, 0xFF)))
  else
    logger.error("Payload too large: " .. len)
    return false
  end

  table.insert(frame, payload)

  local ok, err = pcall(client.write, client, table.concat(frame))
  if not ok then
    logger.error("Failed to send message: " .. tostring(err))
    return false
  end

  return true
end

--- Broadcasts a message to all connected clients.
---@param message ProtocolMessage
function M.broadcast(message)
  for client, _ in pairs(state.active_clients) do
    send_to_client(client, message)
  end
end

--- Starts the WebSocket server.
---@return boolean success
---@return integer|nil port Actual port if auto-assigned
function M.start()
  if state.ws_server then
    logger.warn("Server already running")
    return false
  end

  local server = vim.loop.new_tcp()
  local port = config.get("port")
  local host = config.get("host")

  server:bind(host, port)
  server:listen(128, function(err)
    if err then
      logger.error("Listen error: " .. err)
      return
    end

    local client = vim.loop.new_tcp()
    server:accept(client)

    -- Read initial HTTP request
    client:read_start(function(read_err, chunk)
      if read_err then
        logger.error("Read error: " .. read_err)
        client:close()
        return
      end

      if not chunk then
        -- Connection closed
        state.active_clients[client] = nil
        logger.info("Client disconnected")
        return
      end

      -- Perform handshake on first message
      if not state.active_clients[client] then
        if perform_handshake(client, chunk) then
          state.active_clients[client] = true
          state.connection_state = "connected"
          logger.info("WebSocket client connected")

          -- Send initial sync state
          local sync_engine = require("markdown-preview-sync.core.sync_engine")
          send_to_client(client, {
            type = "sync_state",
            data = {bufnr = vim.api.nvim_get_current_buf()},
            timestamp = os.time() * 1000,
            source = "nvim",
          })
        else
          client:close()
        end
      else
        -- Parse WebSocket frame
        local payload, is_close = parse_frame(chunk)
        if is_close then
          client:close()
          state.active_clients[client] = nil
          return
        end

        if payload then
          -- Decode and handle message
          local message = protocol.decode(payload)
          if message then
            M.handle_message(message)
          end
        end
      end
    end)
  end)

  -- Get actual port if auto-assigned
  local addr = server:getsockname()
  state.port = addr.port
  state.ws_server = server
  state.connection_state = "connecting"

  logger.info(string.format("WebSocket server started on %s:%d", host, state.port))
  return true, state.port
end

--- Handles incoming messages from clients.
---@param message ProtocolMessage
function M.handle_message(message)
  local sync_engine = require("markdown-preview-sync.core.sync_engine")

  if message.type == "cursor_moved" then
    -- Browser reports scroll position
    sync_engine.on_browser_scroll(message.data.offset, message.data.html_id)

  elseif message.type == "pong" then
    -- Heartbeat response (nothing to do)
    logger.debug("Received pong")

  else
    logger.warn("Unknown message type: " .. message.type)
  end
end

--- Stops the WebSocket server and disconnects all clients.
function M.stop()
  if not state.ws_server then
    return
  end

  -- Close all client connections
  for client, _ in pairs(state.active_clients) do
    client:close()
  end
  state.active_clients = {}

  -- Close server
  state.ws_server:close()
  state.ws_server = nil
  state.connection_state = "disconnected"

  logger.info("WebSocket server stopped")
end

--- Returns current server state for debugging.
---@return ServerState
function M.get_state()
  return vim.deepcopy(state)
end

return M
```

---

## 6. Protokoll-Definition (`server/protocol.lua`)

```lua
---@module 'markdown-preview-sync.server.protocol'
---@brief Message serialization/deserialization for WebSocket communication.
---@description
--- Defines the wire format for messages exchanged between Neovim and browser.
--- Uses JSON for simplicity; could be upgraded to MessagePack for performance.

local M = {}

--- Encodes a ProtocolMessage to JSON string.
---@param message ProtocolMessage
---@return string json
function M.encode(message)
  -- Add timestamp if not present
  message.timestamp = message.timestamp or (os.time() * 1000)

  local ok, json = pcall(vim.json.encode, message)
  if not ok then
    error("Failed to encode message: " .. tostring(json))
  end

  return json
end

--- Decodes a JSON string to ProtocolMessage.
---@param json string
---@return ProtocolMessage|nil
function M.decode(json)
  local ok, message = pcall(vim.json.decode, json)
  if not ok then
    require("markdown-preview-sync.utils.logger").error("Failed to decode message: " .. tostring(message))
    return nil
  end

  -- Validate required fields
  if not message.type or not message.data then
    require("markdown-preview-sync.utils.logger").error("Invalid message format")
    return nil
  end

  return message
end

return M
```

---

## 7. Browser-Client (`web/script.js`)

```javascript
// WebSocket client for bidirectional sync with Neovim
class MarkdownPreviewSync {
  constructor() {
    this.ws = null;
    this.isScrolling = false;
    this.scrollTimeout = null;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 10;
    this.reconnectDelay = 1000; // Start with 1s

    this.connect();
    this.setupScrollListener();
  }

  connect() {
    const port = new URLSearchParams(window.location.search).get('port') || 8080;
    this.ws = new WebSocket(`ws://127.0.0.1:${port}`);

    this.ws.onopen = () => {
      console.log('WebSocket connected');
      this.reconnectAttempts = 0;
      this.reconnectDelay = 1000;
      this.updateStatus('connected');
    };

    this.ws.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        this.handleMessage(message);
      } catch (err) {
        console.error('Failed to parse message:', err);
      }
    };

    this.ws.onerror = (err) => {
      console.error('WebSocket error:', err);
      this.updateStatus('error');
    };

    this.ws.onclose = () => {
      console.log('WebSocket closed');
      this.updateStatus('disconnected');
      this.attemptReconnect();
    };
  }

  attemptReconnect() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnect attempts reached');
      return;
    }

    this.reconnectAttempts++;
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);
    setTimeout(() => this.connect(), delay);
  }

  handleMessage(message) {
    switch (message.type) {
      case 'scroll_to_line':
        this.scrollToLine(message.data.line);
        break;

      case 'buffer_updated':
        this.reloadContent(message.data.html);
        break;

      case 'ping':
        this.send({type: 'pong', data: {}, source: 'browser'});
        break;

      case 'sync_state':
        console.log('Received sync state:', message.data);
        break;

      default:
        console.warn('Unknown message type:', message.type);
    }
  }
