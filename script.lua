local reactor = peripheral.find("fusionReactorLogicAdapter")
if not reactor then error("No fusion reactor logic adapter found.") end

local coarseStep = 1
local fineStep = 0.1
local microStep = 0.01
local searchRange = 5
local checkInterval = 3
local efficiencyDropThresh = 0.3
local maxReactivity = 100
local minReactivity = 0
local precisionMode = false

local currentReactivity = 0
local bestEfficiency = 0

local function moveTo(target)
  local delta = target - currentReactivity
  if math.abs(delta) < 0.0001 then return end
  reactor.adjustReactivity(delta)
  sleep(math.abs(delta))
  currentReactivity = target
end

local function probe(target)
  local original = currentReactivity
  moveTo(target)
  local eff = reactor.getEfficiency()
  moveTo(original)
  return target, eff
end

local function localSearch(center, stepSize)
  local bestReactivity = center
  local bestEff = reactor.getEfficiency()
  for offset = -searchRange, searchRange do
    local test = center + offset * stepSize
    if test >= minReactivity and test <= maxReactivity then
      local _, eff = probe(test)
      if eff > bestEff then
        bestEff = eff
        bestReactivity = test
      end
    end
  end
  return bestReactivity, bestEff
end

reactor.adjustReactivity(-100)
sleep(100)
currentReactivity = 0
bestEfficiency = reactor.getEfficiency()
print("Starting at 0%, Efficiency:", bestEfficiency)

while true do
  local step = precisionMode and fineStep or coarseStep
  local betterFound = false

  for _, dir in ipairs({-1, 1}) do
    local test = currentReactivity + dir * step
    if test >= minReactivity and test <= maxReactivity then
      moveTo(test)
      local eff = reactor.getEfficiency()
      if eff > bestEfficiency then
        bestEfficiency = eff
        betterFound = true
        print(string.format("Improved: %.2f%% => Efficiency %.3f", currentReactivity, bestEfficiency))
        break
      end
    end
  end

  if not betterFound then
    if not precisionMode then
      precisionMode = true
    else
      for _, dir in ipairs({-1, 1}) do
        local test = currentReactivity + dir * microStep
        if test >= minReactivity and test <= maxReactivity then
          moveTo(test)
          local eff = reactor.getEfficiency()
          if eff > bestEfficiency then
            bestEfficiency = eff
            betterFound = true
            print(string.format("Micro-adjusted to %.2f%% => Efficiency %.3f", currentReactivity, bestEfficiency))
            break
          end
        end
      end

      if not betterFound then
        sleep(checkInterval)
        local newEff = reactor.getEfficiency()
        if newEff + efficiencyDropThresh < bestEfficiency then
          print(string.format("Efficiency drop detected: %.3f -> %.3f", bestEfficiency, newEff))
          local bestReact, bestEff = localSearch(currentReactivity, coarseStep)
          moveTo(bestReact)
          bestEfficiency = reactor.getEfficiency()
          precisionMode = false
          print(string.format("Recentered to %.2f%% => Efficiency %.3f", currentReactivity, bestEfficiency))
          sleep(1)
        end
      end
    end
  end
end
