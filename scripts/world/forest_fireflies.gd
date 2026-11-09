extends Node2D

const COUNT := 14
var _time := 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	for i in COUNT:
		var base := Vector2(-120.0 + i * 218.0, 150.0 + float((i * 83) % 390))
		var drift := Vector2(sin(_time * 0.35 + i * 1.7) * 28.0, cos(_time * 0.6 + i) * 15.0)
		var pulse := (sin(_time * 2.0 + i * 2.1) + 1.0) * 0.5
		var point := base + drift
		var alpha := 0.12 + pulse * 0.33
		draw_circle(point, 7.0, Color("d9d697", alpha * 0.12))
		draw_circle(point, 2.0, Color("f2e8a7", alpha))
