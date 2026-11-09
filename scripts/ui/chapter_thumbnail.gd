extends Control
## Small, original vector landscape thumbnails for the chapter select cards.

var chapter_index := 1

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / 240.0, size.y / 180.0))
	match chapter_index:
		1: _draw_forest()
		2: _draw_village()
		3: _draw_cave()
		4: _draw_laboratory()
		5: _draw_truth()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _polygon(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)

func _draw_forest() -> void:
	draw_rect(Rect2(0, 0, 240, 180), Color("516d6b"))
	draw_circle(Vector2(174, 39), 24, Color("e6bd7a", 0.84))
	_polygon(PackedVector2Array([Vector2(0, 102), Vector2(37, 61), Vector2(72, 100), Vector2(112, 49), Vector2(164, 105), Vector2(204, 65), Vector2(240, 108), Vector2(240, 180), Vector2(0, 180)]), Color("405a55"))
	for x in [18, 58, 206]:
		draw_rect(Rect2(x, 44, 12, 136), Color("493d32"))
		_polygon(PackedVector2Array([Vector2(x - 39, 73), Vector2(x + 6, 5), Vector2(x + 53, 73)]), Color("203c36"))
		_polygon(PackedVector2Array([Vector2(x - 34, 101), Vector2(x + 6, 38), Vector2(x + 48, 101)]), Color("2a493c"))
	draw_rect(Rect2(0, 154, 240, 26), Color("33473a"))
	for point in [Vector2(79, 128), Vector2(138, 103), Vector2(186, 139), Vector2(105, 156)]:
		draw_circle(point, 2.2, Color("f0dc9b", 0.9))

func _draw_village() -> void:
	draw_rect(Rect2(0, 0, 240, 180), Color("b9755e"))
	draw_circle(Vector2(178, 42), 28, Color("f6cf86"))
	_polygon(PackedVector2Array([Vector2(0, 116), Vector2(48, 76), Vector2(102, 120), Vector2(157, 79), Vector2(240, 120), Vector2(240, 180), Vector2(0, 180)]), Color("66594d"))
	# A quiet cluster of timber cottages against a warm dusk sky.
	for house in [[24, 95, 60], [111, 81, 72], [185, 103, 48]]:
		var x: float = house[0]
		var y: float = house[1]
		var width: float = house[2]
		draw_rect(Rect2(x, y, width, 55), Color("6b493a"))
		_polygon(PackedVector2Array([Vector2(x - 8, y + 3), Vector2(x + width * 0.5, y - 27), Vector2(x + width + 8, y + 3)]), Color("46343a"))
		draw_rect(Rect2(x + width * 0.62, y + 22, 12, 18), Color("edbb70", 0.88))
	_polygon(PackedVector2Array([Vector2(85, 180), Vector2(133, 130), Vector2(164, 130), Vector2(214, 180)]), Color("b39169"))
	draw_rect(Rect2(0, 162, 240, 18), Color("3c4738"))

func _draw_cave() -> void:
	draw_rect(Rect2(0, 0, 240, 180), Color("1d343c"))
	draw_rect(Rect2(10, 14, 220, 154), Color("29464b"))
	for index in 7:
		var x := float(index * 39 - 10)
		var length := float(35 + (index * 17) % 36)
		_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 33, 0), Vector2(x + 18, length)]), Color("15272e"))
		_polygon(PackedVector2Array([Vector2(x + 6, 180), Vector2(x + 30, 180), Vector2(x + 18, 180 - length * 0.78)]), Color("172b31"))
	for crystal in [[55, 146, 45], [120, 151, 69], [190, 145, 54]]:
		var x: float = crystal[0]
		var y: float = crystal[1]
		var h: float = crystal[2]
		draw_circle(Vector2(x, y - h * 0.45), h * 0.48, Color("5ecfc5", 0.12))
		_polygon(PackedVector2Array([Vector2(x - 13, y), Vector2(x - 8, y - h * 0.68), Vector2(x, y - h), Vector2(x + 11, y), Vector2(x, y - 8)]), Color("65c9c0"))
		_polygon(PackedVector2Array([Vector2(x, y - 8), Vector2(x, y - h), Vector2(x + 11, y)]), Color("b4f1de", 0.72))
	draw_rect(Rect2(0, 164, 240, 16), Color("14262c"))

func _draw_laboratory() -> void:
	draw_rect(Rect2(0, 0, 240, 180), Color("293e49"))
	draw_rect(Rect2(16, 18, 208, 142), Color("364b52"))
	draw_rect(Rect2(30, 34, 79, 54), Color("182e37"))
	draw_rect(Rect2(37, 41, 65, 40), Color("67ad9d", 0.86))
	for line in 4:
		draw_line(Vector2(44, 49 + line * 8), Vector2(95 - line * 6, 49 + line * 8), Color("d3d0a2", 0.72), 2.0)
	draw_rect(Rect2(129, 31, 67, 91), Color("202f37"))
	draw_rect(Rect2(138, 40, 49, 61), Color("516f70"))
	for light in 3:
		draw_circle(Vector2(145 + light * 16, 113), 4, [Color("7ed8c5"), Color("e0c477"), Color("df7665")][light])
	draw_line(Vector2(0, 149), Vector2(240, 149), Color("8d9a88"), 3.0)
	draw_rect(Rect2(0, 153, 240, 27), Color("202f35"))
	for x in [32, 208]:
		draw_rect(Rect2(x, 98, 8, 51), Color("46595a"))

func _draw_truth() -> void:
	draw_rect(Rect2(0, 0, 240, 180), Color("8b5b87"))
	draw_rect(Rect2(0, 48, 240, 60), Color("dd926e"))
	draw_circle(Vector2(120, 94), 29, Color("ffd27e"))
	_polygon(PackedVector2Array([Vector2(0, 126), Vector2(35, 79), Vector2(79, 133), Vector2(125, 73), Vector2(176, 131), Vector2(213, 83), Vector2(240, 123), Vector2(240, 180), Vector2(0, 180)]), Color("514d76"))
	# Small castle silhouette, bridge, and final trail.
	draw_rect(Rect2(147, 89, 57, 45), Color("343653"))
	draw_rect(Rect2(157, 69, 15, 65), Color("343653"))
	draw_rect(Rect2(183, 59, 13, 75), Color("343653"))
	_polygon(PackedVector2Array([Vector2(154, 70), Vector2(164, 52), Vector2(175, 70)]), Color("343653"))
	_polygon(PackedVector2Array([Vector2(181, 60), Vector2(189, 41), Vector2(198, 60)]), Color("343653"))
	for window in [Vector2(163, 94), Vector2(185, 91), Vector2(175, 110)]:
		draw_rect(Rect2(window, Vector2(4, 8)), Color("f0c57e"))
	draw_line(Vector2(0, 150), Vector2(147, 150), Color("c49b78"), 5.0)
	draw_rect(Rect2(0, 160, 240, 20), Color("31394d"))
