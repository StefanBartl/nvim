---@diagnostic disable: undefined-global
describe("neo-tree controller", function()
  local controller
  local state
  local semaphore

  before_each(function()
    controller = require("config.neotree.open.window.controller")
    state = require("config.neotree.state.windows")
    semaphore = require("config.neotree.open.window.controller.semaphore")

    state.reset()
    semaphore.force_release()
  end)

  describe("state machine", function()
    it("opens window on first call", function()
      local opener = controller.make_opener("left")
      opener()
      vim.wait(200)

      local s = controller.get_state()
      assert.equals("left", s.position)
      assert.is_true(s.open)
    end)

    it("closes on second call to same position", function()
      local opener = controller.make_opener("left")

      opener() -- open
      vim.wait(200)
      opener() -- close
      vim.wait(200)

      local s = controller.get_state()
      assert.is_false(s.open)
    end)

    it("switches between positions", function()
      local left = controller.make_opener("left")
      local right = controller.make_opener("right")

      left()
      vim.wait(200)
      right()
      vim.wait(300)

      local s = controller.get_state()
      assert.equals("right", s.position)
      assert.is_true(s.open)
    end)

    it("handles rapid keypresses", function()
      local opener = controller.make_opener("left")

      for _ = 1, 10 do
        opener()
        vim.wait(10)
      end

      vim.wait(500)

      -- Should end in consistent state
      local s = controller.get_state()
      assert.is_not_nil(s.position)
    end)
  end)

  describe("semaphore", function()
    it("blocks concurrent operations", function()
      local count = 0

      for _ = 1, 5 do
        vim.schedule(function()
          if semaphore.acquire() then
            count = count + 1
            vim.defer_fn(function()
              semaphore.release()
            end, 50)
          end
        end)
      end

      vim.wait(500)

      -- Only 1 should acquire at a time
      assert.equals(1, count)
    end)
  end)
end)
