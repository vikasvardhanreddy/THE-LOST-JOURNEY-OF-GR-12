extends Node2D

var opened := false

func set_open(value: bool) -> void:
	opened = value
	queue_redraw()

func _draw() -> void:
	var stone := Color("777769")
	var light_stone := Color("969276")
	var shadow := Color("464b45")
	var opening := Color("b2c794", 0.18) if not opened else Color("d9dca5", 0.60)
	# Tall carved uprights, assembled from individually outlined blocks.
	for side in [-1.0, 1.0]:
		for row in 4:
			var y := -27.0 - row * 31.0
			var shift := float(row % 2) * 4.0
			var x: float = side * (43.0 + shift)
			var points := PackedVector2Array([Vector2(x - 19, y), Vector2(x + 17, y - 3), Vector2(x + 19, y + 26), Vector2(x - 18, y + 29)])
			draw_colored_polygon(points, stone if row % 2 == 0 else light_stone)
			draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), shadow, 2.0, true)
			draw_line(Vector2(x - 9, y + 6), Vector2(x + 8, y + 4), Color("c0b798", 0.45), 1.0, true)
	# Keystone and sloped crown stones create an old rounded doorway.
	for i in 5:
		var x: float = -44.0 + i * 22.0
		var y := -133.0 + absf(x) * 0.48
		var block := PackedVector2Array([Vector2(x - 12, y + 4), Vector2(x + 10, y - 2), Vector2(x + 14, y + 22), Vector2(x - 11, y + 26)])
		draw_colored_polygon(block, light_stone if i == 2 else stone)
		draw_polyline(PackedVector2Array([block[0], block[1], block[2], block[3], block[0]]), shadow, 2.0, true)
	# Faint runes, moss, and the doorway's soft dawn glow.
	draw_colored_polygon(PackedVector2Array([Vector2(-25, -18), Vector2(25, -18), Vector2(21, -105), Vector2(0, -127), Vector2(-21, -105)]), opening)
	for side in [-1.0, 1.0]:
		for rune in 3:
			var y := -43.0 - rune * 25.0
			draw_circle(Vector2(side * 43, y), 2.0, Color("d5c78e", 0.65))
		draw_line(Vector2(side * 50, -25), Vector2(side * 54, -12), Color("8e9d63", 0.8), 3.0, true)
	if opened:
		for ray in 5:
			var x: float = -20.0 + ray * 10.0
			draw_line(Vector2(x, -105), Vector2(x + 5, -23), Color("e5dba4", 0.38), 2.0, true)
