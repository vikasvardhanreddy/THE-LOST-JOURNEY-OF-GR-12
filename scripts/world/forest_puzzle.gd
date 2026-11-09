extends Node2D
class_name ForestPuzzle

var solved := false
@export var puzzle_title := "THE STONE ARCH"
@export_multiline var puzzle_hint := "Read the forest marks left to right."
@export var answer_options: Array[String] = ["Up  ·  Down  ·  Up", "Down  ·  Up  ·  Down", "Up  ·  Up  ·  Down"]
@export var correct_answer_index := 0
@export var required_item_ids: Array[String] = []
@export var puzzle_id := ""

func _ready() -> void:
	add_to_group("interactable")
	if puzzle_id.is_empty():
		puzzle_id = "chapter_%02d_main" % JourneyProgress.current_chapter
	solved = JourneyProgress.has_completed_puzzle(puzzle_id)

func interact(player: ForestPlayer) -> void:
	if solved:
		return
	var missing: Array[String] = []
	for item_id in required_item_ids:
		if not JourneyProgress.has_item(item_id):
			missing.append(item_id)
	if not missing.is_empty():
		get_parent().show_dialogue(["The mechanism is missing a few key clues.", "Explore the area and inspect everything that may help."])
		return
	get_parent().show_puzzle(puzzle_title, puzzle_hint, answer_options, correct_answer_index)

func _draw() -> void:
	draw_rect(Rect2(Vector2(-38, -72), Vector2(76, 72)), Color("77766a"))
	draw_rect(Rect2(Vector2(-31, -66), Vector2(62, 61)), Color("343e38"))
	for i in 3:
		var color := Color("d9b96f") if solved else Color("c58a50")
		draw_circle(Vector2(-18 + i * 18, -40), 6, color)
		draw_circle(Vector2(-18 + i * 18, -18), 6, color)
	if solved:
		draw_line(Vector2(-19, -18), Vector2(0, -40), Color("f8e7ae"), 3.0)
		draw_line(Vector2(0, -40), Vector2(18, -18), Color("f8e7ae"), 3.0)

func solve() -> void:
	solved = true
	JourneyProgress.complete_puzzle(puzzle_id)
	JourneyAudio.play_sfx("puzzle_complete")
	queue_redraw()

