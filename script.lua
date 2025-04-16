local reactor = peripheral.find("fusionReactorLogicAdapter")
if not reactor then error("No fusion reactor logic adapter found.") end

-- Config
local minEfficiency = 0.85      -- Absolute threshold
local step = 0.1
local minStep = 0.01
local adjustRate = 1
local idleCheckInterval = 10

-- State
local currentReactivity = 0

-- Helpers
local function moveBy(delta)
  if math.abs(delta) < minStep then return end
  reactor.adjustReactivity(delta)
  sleep(math.max(math.abs(delta) / adjustRate, 0.05))
  currentReactivity = currentReactivity + delta
end

local function probeDelta(delta)
  moveBy(delta)
  return reactor.getEfficiency()
end

local function refineTowardPeak(direction)
  local lastEff = reactor.getEfficiency()
  while true do
    local eff = probeDelta(step * direction)
    if eff > lastEff then
      lastEff = eff
    else
      moveBy(-step * direction)  -- backtrack one step
      print(string.format("Peaked at %.4f => Efficiency %.4f", currentReactivity, lastEff))
      break
    end
  end
end

-- Zero the reactor
reactor.adjustReactivity(-100)
sleep(100 / adjustRate)
currentReactivity = 0
print(string.format("Reset: Reactivity 0%% => Efficiency %.4f", reactor.getEfficiency()))

-- Main loop
while true do
  sleep(idleCheckInterval)
  local eff = reactor.getEfficiency()
  if eff < minEfficiency then
    print(string.format("Low efficiency: %.4f < %.2f → Adjusting...", eff, minEfficiency))

    local upEff = probeDelta(step)
    if upEff < eff then
      moveBy(-step)  -- Restore
      refineTowardPeak(-1)
    else
      refineTowardPeak(1)
    end
  end
end
