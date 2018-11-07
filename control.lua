require("scripts/utility")
require("scripts/track")
require("scripts/train")
require("scripts/train_jumper")

script.on_event(defines.events.on_tick, function() TrainJumper.Manager() end)