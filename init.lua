print("5 sec to start")
tmr.alarm(0, 5000, 0, function()
  dofile("timer.lua")
end)

