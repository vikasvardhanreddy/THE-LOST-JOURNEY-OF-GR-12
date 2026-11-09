extends Control

var _elapsed := 0.0

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func _draw() -> void:
	var viewport := get_viewport_rect().size
	_draw_cloud(Vector2(viewport.x * 0.55 + sin(_elapsed * 0.07) * 16.0, viewport.y * 0.16), 0.68)
	_draw_cloud(Vector2(viewport.x * 0.91 - fposmod(_elapsed * 8.0, viewport.x * 1.2), viewport.y * 0.28), 0.42)
	_draw_star(Vector2(viewport.x * 0.718, viewport.y * 0.088), 11.0 + sin(_elapsed * 4.0) * 2.0, Color("fff2a1", 0.88))
	for index in 8:
		var seed := float(index) * 73.7
		var x := fposmod(seed + _elapsed * (12.0 + float(index % 3) * 4.0), viewport.x)
		var y := fposmod(seed * 1.71 + _elapsed * (7.0 + float(index % 2) * 3.0), viewport.y)
		var leaf_color := Color("bddc4f", 0.72) if index % 2 == 0 else Color("f4a946", 0.72)
		_draw_leaf(Vector2(x, y), leaf_color, 0.65 + float(index % 3) * 0.15, sin(_elapsed + seed) * 0.5)
	for index in 13:
		var phase := _elapsed * 2.4 + float(index) * 1.77
		var point := Vector2(viewport.x * (0.53 + float(index % 5) * 0.082) + sin(phase) * 5.0, viewport.y * (0.09 + float(index % 4) * 0.065) + cos(phase * 0.7) * 5.0)
		var alpha := 0.22 + (sin(phase * 1.8) + 1.0) * 0.25
		draw_circle(point, 1.1 + (sin(phase) + 1.0) * 0.7, Color("fff3b5", alpha))

func _draw_cloud(center: Vector2, alpha: float) -> void:
	var cloud := Color("fff0d5", alpha * 0.12)
	draw_circle(center + Vector2(-12, 0), 8, cloud)
	draw_circle(center, 11, cloud)
	draw_circle(center + Vector2(13, 2), 7, cloud)
	draw_rect(Rect2(center + Vector2(-13, 0), Vector2(26, 7)), cloud)

func _draw_leaf(center: Vector2, color: Color, scale_value: float, rotation: float) -> void:
	var side := Vector2(cos(rotation), sin(rotation)) * 5.0 * scale_value
	var points := PackedVector2Array([
		center - side,
		center + Vector2(0, -4.0 * scale_value),
		center + side,
		center + Vector2(0, 4.0 * scale_value)
	])
	draw_colored_polygon(points, color)
	draw_line(center - side * 0.65, center + side * 0.65, Color("f5e497", 0.58), 1.0, true)

func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 10:
		var angle := -PI / 2.0 + float(index) * TAU / 10.0
		var distance := radius if index % 2 == 0 else radius * 0.43
		points.append(center + Vector2(cos(angle), sin(angle)) * distance)
	draw_colored_polygon(points, color)
