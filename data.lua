data:extend({
	{
		type = "smoke-with-trigger",
		name = "teleported-smoke",
		flags = {"not-on-map"},
		show_when_smoke_off = true,
		animation = {
			width = 152,
			height = 120,
			line_length = 5,
			frame_count = 60,
			animation_speed = 0.25,
			filename = "__base__/graphics/entity/smoke/smoke.png"
		},
		affected_by_wind = false,
		color = { r = 0.54, g = 0.17, b = 0.89 },
		duration = 120,
		fade_away_duration = 60,
	}
})