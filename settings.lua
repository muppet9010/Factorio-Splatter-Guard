data:extend(
    {
        {
            name = "train-avoid-mode",
            type = "string-setting",
            default_value = "Preemptive",
            allowed_values = {"Preemptive", "Reactive Only", "None"},
            setting_type = "runtime-global",
            order = "1001"
        }
    }
)
