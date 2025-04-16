local reactor = peripheral.find("fusionReactorLogicAdapter")
if not reactor then error("No fusion reactor logic adapter found.") end

-- Configuration
local maxReactivity = 100
local minReactivity = 0
local tolerance = 0.01
local adjustRate = 1
local minMove = 0.001
local checkInterval = 10        -- Seconds between passive efficiency checks
local efficiencyDropThresh = 0.2 -- If current efficiency drops by this much, we re-tune
local phi = (math.sqrt(5) - 1) / 2

-- State
local currentReactivity = 0
local bestReactivity = 0
local bestEfficiency = 0
local cache = {}

-- Movement functions
local function moveBy(delta)
  if math.abs(delta) < minMove then return end
  reactor.adjustReactivity(delta)
  sleep(math.max(math.abs(delta) / adjustRate, 0.05))
  currentReactivity = currentReactivity + delta
end

local function moveTo(target)
  moveBy(target - currentReactivity)
end

local function probe(x)
  x = tonumber(string.format("%.4f", x))
  if cache[x] then return cache[x] end
  moveTo(x)
  local eff = reactor.getEfficiency()
  cache[x] = eff
  return eff
end

-- Golden-section search
local function goldenSearch()
  cache = {}  -- Clear old cache
  local a, b = minReactivity, maxReactivity
  local c = b - phi * (b - a)
  local d = a + phi * (b - a)
  local fC = probe(c)
  local fD = probe(d)

  while (b - a) > tolerance do
    if fC < fD then
      a, c, fC = c, d, fD
      d = a + phi * (b - a)
      fD = probe(d)
    else
      b, d, fD = d, c, fC
      c = b - phi * (b - a)
      fC = probe(c)
    end
  end

  local best = (a + b) / 2
  moveTo(best)
  bestEfficiency = reactor.getEfficiency()
  bestReactivity = best
  print(string.format("Tuned to %.4f%% => Efficiency %.4f", best, bestEfficiency))
end

-- Initial zero calibration
reactor.adjustReactivity(-maxReactivity)
sleep(maxReactivity / adjustRate)
currentReactivity = 0
cache[0] = reactor.getEfficiency()
print(string.format("Startup: Reactivity 0.0000 => Efficiency %.4f", cache[0]))

-- Main loop
goldenSearch()
while true do
  sleep(checkInterval)
  local eff = reactor.getEfficiency()
  if eff + efficiencyDropThresh < bestEfficiency then
    print(string.format("Efficiency dropped: %.4f → %.4f. Retuning...", bestEfficiency, eff))
    goldenSearch()
  else
    print(string.format("Stable: %.4f%% => Efficiency %.4f", currentReactivity, eff))
  end
end
