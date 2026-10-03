-- TESTS/tasks/tasks_fsio_spec.lua -- tasks.fsio: atomic writes.

return function(H)
  local eq, ok = H.eq, H.ok
  local fsio = require("tasks.fsio")

  local dir = H.tmpdir()
  local target = dir .. "/sub/TASKS.md"

  --- Names in `d` that look like a leftover temp file.
  ---@param d string
  ---@return string[]
  local function temps(d)
    local out = {}
    for name in vim.fs.dir(d) do
      if name:find("tasks-tmp", 1, true) then
        out[#out + 1] = name
      end
    end
    return out
  end

  -- Creates the parent, writes the bytes as given, leaves no temp file.
  local wrote, werr = fsio.write_atomic(target, "one\r\ntwo")
  ok(wrote, "write failed: " .. tostring(werr))
  eq(H.read(target), "one\r\ntwo", "bytes written as given")
  eq(temps(dir .. "/sub"), {}, "no temp file left behind")

  -- A stale temp file under the old fixed name neither blocks nor is reused.
  H.write(target .. ".tasks-tmp", "stale")
  local again, aerr = fsio.write_atomic(target, "three")
  ok(again, "write beside a stale temp file failed: " .. tostring(aerr))
  eq(H.read(target), "three", "target replaced")
  eq(H.read(target .. ".tasks-tmp"), "stale", "the legacy fixed temp name is not touched")

  -- Two writes of different content in a row (one process) never mix.
  for i = 1, 20 do
    local body = ("round %d\n"):format(i)
    ok(fsio.write_atomic(target, body), "round " .. i)
    eq(H.read(target), body, "round " .. i .. " content")
  end
  vim.fn.delete(target .. ".tasks-tmp")
  eq(temps(dir .. "/sub"), {}, "still no temp file left behind")
end
