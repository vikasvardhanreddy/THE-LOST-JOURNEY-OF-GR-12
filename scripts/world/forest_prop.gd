extends Node2D

@export var tree_height := 230.0
@export var tree_width := 155.0
@export var depth := 0.0

func _draw() -> void:
	var shadow := Color("102522", 0.34)
	var trunk := Color("3f352f")
	var bark := Color("705342")
	var leaf_dark := Color("183d35")
	var leaf_mid := Color("245643")
	var leaf_light := Color("397657")
	var scale_y := tree_height / 230.0
	var scale_x := tree_width / 155.0
	# Spreading roots anchor the trunk into the forest floor.
	draw_colored_polygon(PackedVector2Array([Vector2(-15, 0), Vector2(-44, 7), Vector2(-34, -5), Vector2(-11, -13), Vector2(0, -7), Vector2(16, -14), Vector2(42, 2), Vector2(18, -3), Vector2(5, 8)]), trunk)
	# Tapered, gently leaning trunk and branching limbs.
	draw_colored_polygon(PackedVector2Array([Vector2(-17, 3), Vector2(-12, -105 * scale_y), Vector2(-24, -168 * scale_y), Vector2(-13, -163 * scale_y), Vector2(0, -112 * scale_y), Vector2(10, -171 * scale_y), Vector2(22, -193 * scale_y), Vector2(29, -190 * scale_y), Vector2(17, -158 * scale_y), Vector2(9, -95 * scale_y), Vector2(18, 4)]), trunk)
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -17), Vector2(-7, -101 * scale_y), Vector2(-1, -138 * scale_y), Vector2(2, -68 * scale_y), Vector2(8, -14)]), bark.darkened(0.18))
	draw_line(Vector2(-12, -35), Vector2(-10, -88 * scale_y), Color("987057"), 2.0, true)
	draw_line(Vector2(13, -30), Vector2(9, -74 * scale_y), Color("2b2b29"), 2.0, true)
	draw_line(Vector2(-17, -108 * scale_y), Vector2(-48 * scale_x, -150 * scale_y), trunk, 8.0, true)
	draw_line(Vector2(13, -141 * scale_y), Vector2(48 * scale_x, -189 * scale_y), trunk, 8.0, true)
	draw_line(Vector2(17, -96 * scale_y), Vector2(57 * scale_x, -130 * scale_y), trunk, 6.0, true)
	# Overlapping canopy masses make a layered, irregular silhouette.
	var centers := [Vector2(0, -207), Vector2(-39, -190), Vector2(39, -188), Vector2(-66, -158), Vector2(-23, -156), Vector2(23, -158), Vector2(69, -153), Vector2(-43, -220), Vector2(45, -216)]
	var radii := [61.0, 48.0, 52.0, 40.0, 48.0, 48.0, 39.0, 38.0, 39.0]
	for i in centers.size():
		var at: Vector2 = centers[i] * Vector2(scale_x, scale_y)
		var radius: float = radii[i] * scale_x
		draw_circle(at + Vector2(8, 9), radius * 1.05, shadow)
		draw_circle(at, radius, leaf_mid if i % 3 != 0 else leaf_dark)
		draw_circle(at + Vector2(-radius * 0.23, -radius * 0.24), radius * 0.58, leaf_light if i % 2 == 0 else leaf_mid)
	# Mossy flecks and fine twig tips.
	for i in 8:
		var fleck := Vector2(float((i * 37) % 91 - 45), float((i * 29) % 72 - 210)) * Vector2(scale_x, scale_y)
		draw_circle(fleck, 2.2 * scale_x, Color("8ba16a", 0.48))
	# A tiny hanging moss strand adds a storybook forest texture.
	if int(absf(position.x)) % 2 == 0:
		draw_line(Vector2(30 * scale_x, -182 * scale_y), Vector2(34 * scale_x, -162 * scale_y), Color("82a06a", 0.8), 2.0, true)
