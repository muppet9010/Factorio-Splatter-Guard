require("scripts/utility")
require("scripts/track")
require("scripts/train")
require("scripts/train_jumper")




UpdateSetting = function(settingName)
	if settingName == "train-avoid-mode" or settingName == nil then
		UpdatedTrainAvoidSetting()
	end
end

UpdatedTrainAvoidSetting = function()
	ModSettings.trainAvoidMode = settings.global["train-avoid-mode"].value
	TrainJumper.SetTrainAvoidEvents()
end




CreateGlobals = function()
	if global.ModSettings == nil then global.ModSettings = {} end
end

ReferenceGlobals = function()
	ModSettings = global.ModSettings
end

OnStartup = function()
	CreateGlobals()
	ReferenceGlobals()
	UpdateSetting(nil)
	TrainJumper.SetTrainAvoidEvents()
end

OnLoad = function()
	ReferenceGlobals()
end

OnSettingChanged = function(event)
	UpdateSetting(event.setting)
end




script.on_init(OnStartup)
script.on_load(OnLoad)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)
script.on_configuration_changed(OnStartup)




Log = function(text)
	game.print(text)
	game.write_file("Extra_Biter_Control_logOutput.txt", tostring(text) .. "\r\n", true)
end