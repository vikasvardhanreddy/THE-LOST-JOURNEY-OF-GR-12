extends Node2D

@export_range(2, 5) var chapter_style := 2
@export var ground_width := 2900.0

func _draw() -> void:
	var colors := [Color("263a34"), Color("403b35"), Color("293a40"), Color("333534"), Color("293842")]
	var accents := [Color("6d8250"), Color("9b805a"), Color("4d9a95"), Color("bd985e"), Color("91aaa0")]
	var base: Color = colors[clampi(chapter_style - 1, 0, colors.size() - 1)]
	var edge: Color = accents[clampi(chapter_style - 1, 0, accents.size() - 1)]
	draw_rect(Rect2(Vector2(-ground_width * 0.5, -60), Vector2(ground_width, 120)), base)
	draw_rect(Rect2(Vector2(-ground_width * 0.5, -60), Vector2(ground_width, 10)), edge)
	var rng := RandomNumberGenerator.new()
	rng.seed = chapter_style * 44993
	for i in 145:
		var x := rng.randf_range(-ground_width * 0.5, ground_width * 0.5)
		var y := rng.randf_range(-42.0, 55.0)
		var color := edge if i % 4 == 0 else base.darkened(0.18)
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(-3.0, 3.0), y - rng.randf_range(3.0, 13.0)), Color(color, 0.64), 1.0, true)
