extends Node2D

@export var world_width := 3600.0

func _draw() -> void:
	var sky_top := Color("172c34")
	var sky_bottom := Color("52665a")
	for band in 18:
		var ratio := band / 18.0
		draw_rect(Rect2(Vector2(-600, -500 + band * 65), Vector2(world_width, 66)), sky_top.lerp(sky_bottom, ratio))
	# Dawn glow and broad, subtle rays through the canopy.
	for ring in 7:
		draw_circle(Vector2(920, 95), 42.0 + ring * 24.0, Color("dfc68a", 0.022 - ring * 0.002))
	for ray in 8:
		var start_x := 620.0 + ray * 94.0
		var spread := 45.0 + ray * 10.0
		draw_colored_polygon(PackedVector2Array([Vector2(start_x, -360), Vector2(start_x + 20, -360), Vector2(start_x + spread + 130, 568), Vector2(start_x - spread, 568)]), Color("ddce9a", 0.022))
	# Distant mountain line.
	for i in 12:
		var x := -450.0 + i * 360.0
		var peak := 175.0 + float((i * 7) % 5) * 43.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 570), Vector2(x + 140, peak), Vector2(x + 360, 570)]), Color("304b49", 0.75))
	# Low fog ribbons, softly broken so terrain remains readable.
	for ribbon in 5:
		var y := 450.0 + ribbon * 31.0
		for segment in 10:
			var x := -100.0 + segment * 370.0 + ((ribbon % 2) * 130.0)
			_draw_ellipse(Vector2(x, y + sin(segment + ribbon) * 9.0), Vector2(180, 22), Color("b9c8ac", 0.045))

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
