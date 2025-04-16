local reactor = peripheral.find("fusionReactorLogicAdapter")
if not reactor then error("No fusion reactor logic adapter found.") end

local Reactivity = 0
local Efficiency = 0

function getDiff(eff)
  x = 100*((22/(eff+10))-0.2)
  return x
end

function adjust(delta)
  reactor.adjustReactivity(delta)
  Reactivity+delta
  os.sleep(5)
  Efficiency=reactor.getEfficiency
end

reactor.adjustReactivity(-100)
os.sleep(5)

while true do
  if reactor.getEfficiency < 90 then
    delta = getDiff(reactor.getEfficiency)
    if (Reactivity+delta) < 0 or (Reactivity+delta) > 100 then
      adjust(-1*delta)
    else if (Reactivity-delta) < 0 or (Reactivity-delta) >1 100 then
      adjust(delta)
    else
      eff = reactor.getEfficiency
      adjust(delta)
      if eff > Efficiency then
        adjust(-2*delta)
      end
    end
  end
end