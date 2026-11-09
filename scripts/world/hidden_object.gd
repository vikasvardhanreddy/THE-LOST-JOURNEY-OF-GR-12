extends "res://scripts/world/clue.gd"

func _draw() -> void:
	var bob := sin(_time * 1.5) * 1.0
	var center := Vector2(0, -8 + bob)
	draw_circle(center, 24.0, Color("65c9ba", 0.10))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-22, 9), center + Vector2(-15, -7), center + Vector2(-5, -14), center + Vector2(5, -9), center + Vector2(12, -16), center + Vector2(22, -3), center + Vector2(20, 12), center + Vector2(-20, 13)]), Color("465655"))
	draw_polyline(PackedVector2Array([center + Vector2(-22, 9), center + Vector2(-15, -7), center + Vector2(-5, -14), center + Vector2(5, -9), center + Vector2(12, -16), center + Vector2(22, -3), center + Vector2(20, 12)]), Color("82908a"), 2.0, true)
	# A narrow crack exposes a reflective fragment just inside the rock.
	draw_colored_polygon(PackedVector2Array([center + Vector2(-3, 8), center + Vector2(0, -4), center + Vector2(5, 4), center + Vector2(3, 9)]), Color("a4eee0", 0.92))
	draw_circle(center + Vector2(2, 2), 9.0, Color("6bd6c7", 0.08))
