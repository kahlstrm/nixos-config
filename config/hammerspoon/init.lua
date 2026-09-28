hs.autoLaunch(false)
hs.automaticallyCheckForUpdates(false)

hs.window.setFrameCorrectness = false

hs.urlevent.bind("reload-config", function()
  hs.reload()
end)

if not hs.accessibilityState() then
  hs.accessibilityState(true)
end

local directions = {
  Left = "toWest",
  Right = "toEast",
  Up = "toNorth",
  Down = "toSouth",
}

for key, direction in pairs(directions) do
  hs.hotkey.bind({ "alt", "cmd" }, key, function()
    local window = hs.window.focusedWindow()
    if not window or window:isFullScreen() or not window:isStandard() then return end

    local screen = window:screen()
    if not screen then return end

    local target = screen[direction](screen)
    if target then
      local targetFrame = target:fromUnitRect(screen:toUnitRect(window:frame())):fit(target:frame())
      window:moveToScreen(target, false, true, 0)
      local movedFrame = window:frame()
      -- A cross-screen move can leave the window smaller than requested.
      -- Reapply the intended frame on the next event-loop cycle, unless it changed again.
      hs.timer.doAfter(0, function()
        if window:screen() == target and window:frame() == movedFrame then
          window:setFrame(targetFrame, 0)
        end
      end)
    end
  end)
end
