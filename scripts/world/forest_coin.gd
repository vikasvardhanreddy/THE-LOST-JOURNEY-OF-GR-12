extends Node2D
class_name ForestCoin

var _time := 0.0

func _ready() -> void:
	add_to_group("coins")

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func collect(player: ForestPlayer) -> void:
	if not is_inside_tree():
		return
	player.add_coin()
	JourneyAudio.play_sfx("item_pickup", 0.72)
	queue_free()

func _draw() -> void:
	var bob := sin(_time * 3.0) * 4.0
	var center := Vector2(0, -18 + bob)
	draw_circle(center, 18, Color("ffdf72", 0.14))
	draw_circle(center, 11, Color("9e5c23"))
	draw_circle(center, 8, Color("ffce49"))
	draw_arc(center, 5, -PI * 0.7, PI * 0.7, 12, Color("fff1a2"), 2.0, true)
	draw_circle(center + Vector2(-3, -3), 2, Color("fff7cc"))
	for index in 3:
		var angle := _time * 0.7 + float(index) * TAU / 3.0
		var sparkle := center + Vector2(cos(angle), sin(angle)) * 16.0
		draw_circle(sparkle, 1.5, Color("fff1a1", 0.8))
