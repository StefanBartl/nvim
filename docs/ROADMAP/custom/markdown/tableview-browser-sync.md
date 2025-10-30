
Live-Update im Browser ist machbar. Es gibt mehrere Komplexitätsstufen; die zwei pragmatischsten, zuverlässigen und einfach umsetzbaren Varianten sind

1. Minimal & schnell: HTML mit einfachem JavaScript-Polling einer kleinen Timestamp-Datei; ein sehr einfacher HTTP-Server dient als Datei-Host.
2. Robust / "echtes" Live-Reload: WebSocket- oder Server-Sent-Events (SSE) basierter Live-Reload (benötigt kleinen Server: Node / Python / Lua), sehr flüssig, aber aufwändiger.

Ich empfehle Variante 1 als default: sie ist simpel, benötigt nur einen statischen HTTP-Server (z. B. `python -m http.server`) und funktioniert ohne zusätzliche Browser-Extensions. Unten ist ein vollständiges Beispiel (Neovim-Lua + HTML) — direkt einbaubar in dein TableView-Browser-View-Flow.

---

Variante (empfohlen): Polling + timestamp (leichter, zuverlässig)

Konzept

* Beim Erzeugen der HTML-Datei wird zusätzlich eine kleine Datei `__table_ts__.txt` mit aktuellem Timestamp in demselben Temp-Ordner geschrieben.
* Die erzeugte HTML-Datei enthält ein kleines JS-Snippet, das alle N Sekunden die Timestamp-Datei anfragt; wenn sich der Wert ändert, macht es `location.reload()`.
* Ein HTTP-Server (z. B. `python3 -m http.server 8000 --directory <tmpdir>`) dient als Host. Den Server kann man mit `vim.fn.jobstart` aus Neovim starten (detached).
* In Neovim registriert man `BufWritePost` (oder nur für Markdown-Tables) einen Callback, der die HTML/Timestamp neu erzeugt — Browser lädt dann automatisch nach der nächsten Polling-Runde neu.

Vorteile

* Einfach, keine zusätzliche Abhängigkeit im Browser.
* Kein WebSocket-Server nötig.
* Schnelle Implementierung und robust in unterschiedlichen Umgebungen.

Nachteile

* Polling-Delay (z. B. 1–2s).
* Voller Seitennachladen (reload), nicht feingranulares DOM-Patching.

Code — HTML-Template (JS polling eingebettet)

```html
<!-- snippet embedded into the HTML you already generate -->
<script>
  // Poll every 1500ms for changes to the timestamp file.
  (function pollTimestamp() {
    var url = "./__table_ts__.txt"; // same dir as HTML
    var last = null;
    function check() {
      fetch(url, {cache: "no-store"}).then(function(resp){
        if (!resp.ok) return;
        return resp.text();
      }).then(function(text){
        if (!text) return;
        if (last && last !== text.trim()) {
          // changed -> reload
          location.reload();
        }
        last = text.trim();
      }).catch(function(){ /* ignore network errors */ });
    }
    // initial check (and then repeated)
    check();
    setInterval(check, 1500);
  })();
</script>
```

Neovim/Lua: Generator + server management + autocmd

```lua
-- English comments inside code (per project rules)

local api = vim.api
local uv = vim.loop
local parser = require("custom.markdown.tableview.parser")
local build_html = require("custom.markdown.tableview.views.browser") -- your generator function

-- Ensure HTTP server serving the tmpdir is running. Uses python's http.server.
local function ensure_http_server(tmpdir, port)
  port = port or 8000
  -- naive check: try to connect, otherwise spawn
  local sock = uv.new_tcp()
  local ok, _ = pcall(function() sock:connect("127.0.0.1", port) end)
  if ok then
    sock:shutdown(); sock:close()
    return port
  end

  -- spawn a python http.server (detached). Adjust python binary if needed.
  -- Note: replace 'python3' with 'python' on some systems.
  local cmd = { "python3", "-m", "http.server", tostring(port), "--bind", "127.0.0.1", "--directory", tmpdir }
  vim.fn.jobstart(cmd, { detach = true })
  return port
end

-- Write HTML + timestamp to tmpdir and open browser (or re-use existing browser URL)
local function write_preview_and_timestamp(bufnr, tmpbase)
  bufnr = bufnr or api.nvim_get_current_buf()
  tmpbase = tmpbase or (vim.fn.tempname() .. "_tableview")
  local tmpdir = vim.fn.fnamemodify(tmpbase, ":h")
  if tmpdir == "" or tmpdir == "." then tmpdir = vim.loop.os_tmpdir() end

  -- chosen HTML filename
  local html_file = tmpdir .. "/tableview_preview.html"
  local ts_file = tmpdir .. "/__table_ts__.txt"

  -- build chosen table HTML content (your existing build_html returns full HTML)
  local cur_line = api.nvim_win_get_cursor(0)[1]
  local tables = parser.get_tables(bufnr)
  local chosen = nil
  for _, t in ipairs(tables) do
    if t.start_line <= cur_line and cur_line <= (t.end_line or t.start_line) then
      chosen = t; break
    end
  end
  if not chosen then
    vim.notify("[TableView] No table under cursor for preview", vim.log.levels.INFO)
    return
  end

  -- build html (use the existing browser view builder and ensure it includes the JS snippet)
  local headers = {}
  for _, c in ipairs(chosen.header.cells or {}) do table.insert(headers, c.content or "") end
  local source = string.format("col %d; %s", chosen.start_line or 0, table.concat(headers, ", "))
  local html = build_html(chosen, source) -- returns full HTML string (should include polling JS)

  -- write files
  local fh = io.open(html_file, "w")
  if not fh then
    vim.notify("[TableView] Failed to open preview HTML for writing", vim.log.levels.ERROR)
    return
  end
  fh:write(html); fh:close()

  local tsfh = io.open(ts_file, "w")
  if tsfh then
    tsfh:write(tostring(os.time())); tsfh:close()
  end

  -- ensure http server and open browser
  local port = ensure_http_server(tmpdir, 8000)
  local url = string.format("http://127.0.0.1:%d/%s", port, vim.fn.fnamemodify(html_file, ":t"))
  -- open browser (non-blocking)
  local sys = vim.loop.os_uname().sysname or ""
  if sys:match("Windows") or sys:match("windows") then
    vim.fn.jobstart({ "cmd", "/C", "start", "", url }, { detach = true })
  elseif sys == "Darwin" then
    vim.fn.jobstart({ "open", url }, { detach = true })
  else
    vim.fn.jobstart({ "xdg-open", url }, { detach = true })
  end

  -- return paths in case caller wants them
  return { html = html_file, ts = ts_file, url = url, tmpdir = tmpdir }
end

-- Autocmd: regenerate preview on BufWritePost for markdown buffers (or only current buffer)
local function setup_live_preview_autocmd()
  local aug = api.nvim_create_augroup("CustomTableViewLivePreview", { clear = true })
  api.nvim_create_autocmd("BufWritePost", {
    group = aug,
    pattern = { "*.md", "*.markdown", "*.mdx" },
    callback = function(ev)
      -- Option: only update if the written buffer contains tables; simple and cheap check:
      local tbls = parser.get_tables(ev.buf)
      if #tbls == 0 then return end
      -- write preview (uses cursor position of current window to pick table; for better UX, you might store last opened table index)
      write_preview_and_timestamp(ev.buf)
    end,
    desc = "Regenerate TableView browser preview on file save",
  })
end

-- usage: call write_preview_and_timestamp() once to open preview, and then autocmd will update it on saves
-- setup_live_preview_autocmd()
```

Anmerkungen / Hinweise / Edge-Cases

* `python -m http.server` ist die einfachste Option; wenn bereits ein Port belegt ist, muss man Port-Management einbauen (z. B. suche freien Port).
* Polling-Interval in HTML (hier 1.5s) kann angepasst werden; kleiner → höherer Load.
* Für flüssigere UX (kein Full-Page-Reload) wäre WebSocket/SSE-basierte Lösung nötig: dann sendet Neovim/JobStart eine Nachricht an Server, der an Browser pusht — dafür ist aber ein Node/Python/luvit-WebSocket-Server nötig.
* Wenn mehrere Previews gleichzeitig möglich sein sollen, benutze eindeutige tmpdir/filenames pro Neovim-Buffer (z. B. include bufnr in filename).
* Security: serving tmp dir via `http.server` auf 127.0.0.1 ist recht sicher lokal; Port sichtbar für lokale Nutzer.

---

Wenn gewünscht, kann ich:

* das obige in ein konkretes, fertig einbindbares Lua-Modul (z. B. `tableview.live_preview`) umsetzen, inklusive Start/Stop-Funktionen für den HTTP-Server und `:TableViewOpenLive`-Usercommand; oder
* die robustere WebSocket-SSE-Variante implementieren (Benötigt kleine Node/Python-Skript-Vorlage).

Welche Variante bevorzugt werden soll — die einfache Polling-Version (schnell fertig) oder die WebSocket-Variante (flüssiger, mehr Aufwand)?

---
