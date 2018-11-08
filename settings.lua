data:extend({
	{
		name = "train-avoid-mode",
		type = "string-setting",
		default_value = "Preemtive",
		allowed_values = {"Preemtive", "Reactive Only", "None"},
		setting_type = "runtime-global",
		order = "1001"
	}
})