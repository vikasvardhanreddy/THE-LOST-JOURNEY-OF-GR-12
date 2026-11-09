extends Node2D

@export var ground_width := 2900.0

func _draw() -> void:
	var width := ground_width
	draw_rect(Rect2(Vector2(-width * 0.5, -60), Vector2(width, 120)), Color("263a34"))
	draw_rect(Rect2(Vector2(-width * 0.5, -60), Vector2(width, 10)), Color("6d8250"))
	draw_rect(Rect2(Vector2(-width * 0.5, -50), Vector2(width, 4)), Color("9b985e", 0.52))
	var rng := RandomNumberGenerator.new()
	rng.seed = 381947
	for i in 200:
		var x := rng.randf_range(-width * 0.5, width * 0.5)
		var y := rng.randf_range(-43, 57)
		var length := rng.randf_range(3.0, 12.0)
		var color := Color("526244", 0.72) if i % 2 == 0 else Color("192e2b", 0.75)
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(-3, 3), y - length), color, 1.0, true)
		if i % 6 == 0:
			_draw_ellipse(Vector2(x, y + 5), Vector2(rng.randf_range(3, 7), rng.randf_range(2, 4)), Color("81775e", 0.52))
	for x in [-1200, -760, -260, 180, 560, 980, 1390, 1790, 2180, 2580, 3060]:
		var tuft_y := -51.0
		for blade in 5:
			var dx := float(blade - 2) * 5.0
			draw_line(Vector2(x + dx, tuft_y + 3), Vector2(x + dx - 3 + blade, tuft_y - 8 - (blade % 3) * 3), Color("8d9a58"), 2.0, true)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
