---@diagnostic disable: undefined-global
describe("neo-tree performance", function()
  local controller

  before_each(function()
    controller = require("config.neotree.open.window.controller")
    require("config.neotree.state.windows").reset()
  end)

  it("opens in < 10ms avg (cached)", function()
    local opener = controller.make_opener("left")
    local times = {}

    -- First open (uncached)
    opener()
    vim.wait(200)
    opener() -- close

    -- Measure cached opens
    for i = 1, 20 do
      local start = vim.loop.hrtime()
      opener()
      vim.wait(50)
      opener() -- close
      times[i] = (vim.loop.hrtime() - start) / 1e6
      vim.wait(50)
    end

    local sum = 0
    for _, t in ipairs(times) do
      sum = sum + t
    end
    local avg = sum / #times

    assert.is_true(avg < 10, string.format("avg=%0.2fms", avg))
  end)

  it("switch < 60ms", function()
    local left = controller.make_opener("left")
    local right = controller.make_opener("right")

    left()
    vim.wait(200)

    local start = vim.loop.hrtime()
    right()
    vim.wait(300)
    local duration = (vim.loop.hrtime() - start) / 1e6

    assert.is_true(duration < 60, string.format("switch=%0.2fms", duration))
  end)
end)
