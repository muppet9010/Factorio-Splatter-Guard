local TrainJumper = require("scripts/train_jumper")


local function UpdatedTrainAvoidSetting()
	global.Mod.Settings.trainAvoidMode = settings.global["train-avoid-mode"].value
	TrainJumper.SetTrainAvoidEvents()
end


local function UpdateSetting(settingName)
	if settingName == "train-avoid-mode" or settingName == nil then
		UpdatedTrainAvoidSetting()
	end
end


local function CreateGlobals()
	if global.Mod == nil then global.Mod = {} end
	if global.Mod.Settings == nil then global.Mod.Settings = {} end
    if global.Mod.State == nil then global.Mod.State = {} end
end


local function MigrateGlobals()
	if global.ModSettings ~= nil then
		global.Mod.Settings = global.ModSettings
		global.ModSettings = nil
	end
end


local function OnStartup()
	CreateGlobals()
	MigrateGlobals()
	TrainJumper.PopulateStateDefaults()
	UpdateSetting(nil)
end


local function OnLoad()
	TrainJumper.SetTrainAvoidEvents()
end


local function OnSettingChanged(event)
	UpdateSetting(event.setting)
end


script.on_init(OnStartup)
script.on_load(OnLoad)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)
script.on_configuration_changed(OnStartup)