extends Node2D

@export var variant := 0
@export var size_scale := 1.0

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(position.x) * 113.0) + variant * 97531
	var leaf := Color("617c4b") if variant % 2 == 0 else Color("8b8052")
	var stem := Color("526342")
	if variant % 3 == 0:
		# Fern fronds.
		for side in [-1.0, 1.0]:
			draw_line(Vector2.ZERO, Vector2(side * 21, -28) * size_scale, stem, 2.0, true)
			for frond in 4:
				var t := (frond + 1) / 5.0
				var base := Vector2(side * 21 * t, -28 * t) * size_scale
				draw_line(base, base + Vector2(-side * 10, -7) * size_scale, leaf, 3.0, true)
				draw_line(base, base + Vector2(side * 9, -8) * size_scale, leaf, 3.0, true)
	else:
		# Wild flowers among low grasses.
		for blade in 4:
			var x := rng.randf_range(-12, 12) * size_scale
			var height := rng.randf_range(12, 27) * size_scale
			draw_line(Vector2(x, 0), Vector2(x + rng.randf_range(-6, 6), -height), stem, 1.5, true)
			if blade % 2 == 0:
				draw_circle(Vector2(x, -height), 2.6 * size_scale, Color("d7b877"))
				for petal in 5:
					var a := TAU * petal / 5.0
					draw_circle(Vector2(x, -height) + Vector2(cos(a), sin(a)) * 3.1 * size_scale, 1.8 * size_scale, Color("d9d2a2"))
			else:
				_draw_ellipse(Vector2(x + 3, -height * 0.48), Vector2(4, 2) * size_scale, leaf)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 12:
		var angle := TAU * i / 12.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
