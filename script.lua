local reactor = peripheral.find("fusionReactorLogicAdapter")
if not reactor then error("No fusion reactor logic adapter found.") end

local Reactivity = 0
local Efficiency = 0

function getDiff(eff)
  x = 100*((22/( eff + 10))-0.2)
  return x
end

function adjust(delta)
  reactor.adjustReactivity(delta)
  Reactivity = Reactivity+delta
  os.sleep(5)
  Efficiency=reactor.getEfficiency()
end

reactor.adjustReactivity(-100)
os.sleep(5)

while true do
  if reactor.getEfficiency() < 90 then
    delta = getDiff(reactor.getEfficiency())
    temp = Reactivity + delta
    temp2 = Reactivity - delta
    local ad;
    if temp < 0 or temp > 100 then
      ad = -1 * delta
      adjust(ad)
    else if temp2 < 0 or temp2 > 100 then
      ad = delta
      adjust(ad)
    else
      eff = reactor.getEfficiency()
      ad = delta
      adjust(ad)
      if eff > Efficiency then
        ad = -2 * delta
        adjust(ad)
      end
    end
  end
end
end
