extends Node2D
class_name ForestClue

@export var clue_title := "Forest note"
@export_multiline var clue_text := "The marks point toward the old stone arch."
@export var motif := 0
@export var item_id := ""

var _time := 0.0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("chapter_clue")
	if not item_id.is_empty() and JourneyProgress.has_item(item_id):
		visible = false

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func interact(player: ForestPlayer) -> void:
	if not visible:
		return
	if not JourneyProgress.add_inventory_item(item_id, clue_title, clue_text):
		visible = false
		return
	JourneyAudio.play_sfx("item_pickup")
	visible = false
	player.add_clue()
	get_parent().clue_found(clue_title, clue_text)

func _draw() -> void:
	var bob := sin(_time * 1.8) * 3.0
	var center := Vector2(0, -12 + bob)
	var glow := Color("e8c47a", 0.10 + (sin(_time * 2.2) + 1.0) * 0.035)
	draw_circle(center, 31.0, glow)
	draw_circle(center, 22.0, Color("f2d38d", 0.12))
	# Small hovering page with a folded corner and warm edge.
	draw_colored_polygon(PackedVector2Array([center + Vector2(-12, -13), center + Vector2(8, -13), center + Vector2(13, -8), center + Vector2(11, 14), center + Vector2(-11, 14)]), Color("c6a979"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9, -11), center + Vector2(7, -11), center + Vector2(10, -7), center + Vector2(9, 11), center + Vector2(-9, 11)]), Color("f0dfb9"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(7, -11), center + Vector2(7, -6), center + Vector2(11, -7)]), Color("bd9d6b"))
	var ink := Color("75604a")
	draw_line(center + Vector2(-5, -4), center + Vector2(4, -4), ink, 1.4, true)
	draw_line(center + Vector2(-5, 0), center + Vector2(5, 0), ink, 1.4, true)
	draw_line(center + Vector2(-5, 4), center + Vector2(2, 4), ink, 1.4, true)
	# Clue marks are designed to read as a tiny illustrated motif.
	var mark_color: Color = [Color("b77645"), Color("4d8278"), Color("a96956")][motif % 3]
	if motif % 3 == 0:
		draw_circle(center + Vector2(0, 8), 2.0, mark_color)
		draw_arc(center + Vector2(0, 8), 4.0, PI, TAU, 12, mark_color, 1.5, true)
	elif motif % 3 == 1:
		draw_line(center + Vector2(-3, 9), center + Vector2(0, 4), mark_color, 1.7, true)
		draw_line(center + Vector2(0, 4), center + Vector2(3, 9), mark_color, 1.7, true)
	else:
		draw_circle(center + Vector2(0, 7), 2.8, mark_color)
	for star in 3:
		var angle := _time * 0.45 + star * TAU / 3.0
		var point := center + Vector2(cos(angle), sin(angle)) * 27.0
		draw_circle(point, 1.4, Color("ffe8ae", 0.72))

