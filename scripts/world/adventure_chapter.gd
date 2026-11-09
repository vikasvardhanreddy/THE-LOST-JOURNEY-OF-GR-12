extends Node2D
class_name AdventureChapter

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/chapter_hud.tscn")
const CLUE_SCRIPT := preload("res://scripts/world/clue.gd")
const HIDDEN_SCRIPT := preload("res://scripts/world/hidden_object.gd")
const PUZZLE_SCRIPT := preload("res://scripts/world/forest_puzzle.gd")
const BACKDROP_SCRIPT := preload("res://scripts/world/chapter_backdrop.gd")
const GROUND_SCRIPT := preload("res://scripts/world/chapter_ground.gd")
const COIN_SCRIPT := preload("res://scripts/world/forest_coin.gd")
const ENEMY_SCRIPT := preload("res://scripts/world/forest_enemy.gd")
const PORTAL_SCRIPT := preload("res://scripts/world/final_portal.gd")

var chapter_id := 2
var chapter_title := "The Forgotten Village"
var place_name := "Abandoned Village"
var intro_lines: Array[String] = ["The village stands empty. A letter waits somewhere among the houses."]
var clue_specs: Array[Dictionary] = []
var puzzle_title := "OLD MECHANISM"
var puzzle_hint := "Examine the clues and choose the correct sequence."
var puzzle_options: Array[String] = ["First", "Second", "Third"]
var correct_answer_index := 0
var required_item_ids: Array[String] = []
var success_lines: Array[String] = ["The mechanism opens.", "A path forward is revealed."]
var completion_text := "A new path is open."
var player: ForestPlayer
var hud: ChapterHUD
var puzzle: ForestPuzzle
var exit_marker: Node2D
var ending_phase := 0

func _ready() -> void:
	if not JourneyProgress.begin_chapter(chapter_id):
		get_tree().change_scene_to_file(JourneyProgress.chapter_scene(JourneyProgress.current_chapter))
		return
	JourneyAudio.play_chapter_music(chapter_id)
	_build_area()
	player = PLAYER_SCENE.instantiate()
	player.position = JourneyProgress.get_player_checkpoint(chapter_id, Vector2(120, 560))
	add_child(player)
	player.clue_count_changed.connect(_on_clue_count_changed)
	player.stats_changed.connect(_on_stats_changed)
	player.died.connect(_on_player_died)
	JourneyProgress.update_player_state(player.health, player.max_health, player.coins)
	JourneyProgress.set_player_checkpoint(chapter_id, player.position)
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_chapter(chapter_id, chapter_title, place_name, chapter_id == 5)
	hud.update_stats(player.health, player.max_health, player.coins)
	player.controls_enabled = false
	hud.start_requested.connect(_on_start_requested)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.puzzle_answered.connect(_on_puzzle_answered)
	if puzzle.solved:
		JourneyProgress.skip_chapter_title = false
		if chapter_id == 5:
			ending_phase = 2
			exit_marker.set_open(true)
			hud.begin_chapter_intro()
		else:
			JourneyProgress.complete_chapter(chapter_id)
			hud.show_completion(completion_text)
	elif JourneyProgress.skip_chapter_title:
		JourneyProgress.skip_chapter_title = false
		hud.begin_chapter_intro()

func _build_area() -> void:
	var backdrop := BACKDROP_SCRIPT.new()
	backdrop.chapter_style = chapter_id
	add_child(backdrop)
	var tint := CanvasModulate.new()
	tint.color = [Color("c3d1b8"), Color("c6b7a0"), Color("a9c5c5"), Color("d0c1a1"), Color("bbc9c1")][chapter_id - 1]
	add_child(tint)
	_add_floor()
	_add_landmarks()
	for spec in clue_specs:
		_add_clue(spec)
	puzzle = PUZZLE_SCRIPT.new()
	puzzle.position = Vector2(2500, 620)
	puzzle.puzzle_title = puzzle_title
	puzzle.puzzle_hint = puzzle_hint
	puzzle.answer_options = puzzle_options
	puzzle.correct_answer_index = correct_answer_index
	puzzle.required_item_ids = required_item_ids
	add_child(puzzle)
	if chapter_id == 5:
		exit_marker = PORTAL_SCRIPT.new()
		exit_marker.position = Vector2(2700, 620)
		add_child(exit_marker)
	for index in 7:
		_add_coin(Vector2(360 + index * 360, 578 if index % 2 == 0 else 520))
	for index in 3:
		_add_enemy(Vector2(790 + index * 730, 620), 58.0)
	_add_platform(710, 565, 130)
	_add_platform(1460, 545, 150)
	_add_platform(2060, 580, 135)

func _add_floor() -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(1340, 680)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2920, 120)
	shape.shape = rectangle
	body.add_child(shape)
	var visual := Node2D.new()
	visual.set_script(GROUND_SCRIPT)
	visual.chapter_style = chapter_id
	visual.ground_width = 2920
	body.add_child(visual)
	add_child(body)

func _add_landmarks() -> void:
	match chapter_id:
		2:
			_add_well(1300, 620)
			_add_bell_post(2330, 620)
		3:
			_add_crystal_cluster(420, 570)
			_add_crystal_cluster(1080, 570)
			_add_crystal_cluster(1740, 570)
			_add_tablet(2480, 620)
		4:
			_add_lab_console(500, 620, "ARCHIVE")
			_add_lab_console(1180, 620, "POWER")
			_add_lab_console(1860, 620, "CONTROL")
			_add_lab_door(720, 620)
			_add_lab_door(1410, 620)
			_add_lab_door(2100, 620)
		5:
			_add_memory_shard(420, 560)
			_add_memory_shard(1280, 560)
			_add_memory_shard(2050, 560)
			_add_tablet(2500, 620)

func _add_clue(spec: Dictionary) -> void:
	var clue = HIDDEN_SCRIPT.new() if spec.get("hidden", false) else CLUE_SCRIPT.new()
	clue.position = spec.get("position", Vector2(400, 570))
	clue.clue_title = spec.get("title", "Found note")
	clue.clue_text = spec.get("body", "A clue from the abandoned place.")
	clue.item_id = spec.get("id", "")
	clue.motif = get_tree().get_nodes_in_group("chapter_clue").size()
	add_child(clue)

func _add_platform(x: float, top: float, width: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, top + 10)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 20)
	shape.shape = rectangle
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-width / 2, -10), Vector2(width / 2, -10), Vector2(width / 2, 10), Vector2(-width / 2, 10)])
	visual.color = [Color("806342"), Color("73614c"), Color("52686b"), Color("6f5a3f"), Color("5b7180")][chapter_id - 1]
	body.add_child(visual)
	add_child(body)

func _add_coin(at: Vector2) -> void:
	var coin = COIN_SCRIPT.new()
	coin.position = at
	add_child(coin)

func _add_enemy(at: Vector2, patrol_distance: float) -> void:
	var enemy = ENEMY_SCRIPT.new()
	enemy.position = at
	enemy.patrol_distance = patrol_distance
	add_child(enemy)

func _add_well(x: float, y: float) -> void:
	var well := Node2D.new()
	well.position = Vector2(x, y)
	well.z_index = -1
	add_child(well)
	# Chunky stone ring and weathered wooden crossbar.
	var stones := Polygon2D.new()
	stones.polygon = PackedVector2Array([Vector2(-74, 0), Vector2(-62, -47), Vector2(-30, -61), Vector2(34, -61), Vector2(66, -44), Vector2(76, 0)])
	stones.color = Color("726b5c")
	well.add_child(stones)
	var dark := Polygon2D.new()
	dark.polygon = PackedVector2Array([Vector2(-48, -8), Vector2(-41, -39), Vector2(42, -39), Vector2(51, -8)])
	dark.color = Color("182626")
	well.add_child(dark)
	var post := Polygon2D.new()
	post.polygon = PackedVector2Array([Vector2(-57, -108), Vector2(-45, -108), Vector2(-40, -46), Vector2(-58, -46)])
	post.color = Color("624b37")
	well.add_child(post)
	var right_post := Polygon2D.new()
	right_post.polygon = PackedVector2Array([Vector2(45, -108), Vector2(57, -108), Vector2(58, -46), Vector2(40, -46)])
	right_post.color = Color("624b37")
	well.add_child(right_post)
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(-60, -114), Vector2(60, -114), Vector2(60, -102), Vector2(-60, -102)])
	beam.color = Color("8a6e4c")
	well.add_child(beam)

func _add_bell_post(x: float, y: float) -> void:
	var post := Polygon2D.new()
	post.position = Vector2(x, y)
	post.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(-6, -180), Vector2(7, -180), Vector2(10, 0)])
	post.color = Color("76563c")
	add_child(post)
	var bell := Polygon2D.new()
	bell.position = Vector2(x, y - 174)
	bell.polygon = PackedVector2Array([Vector2(-16, -5), Vector2(-10, -25), Vector2(10, -25), Vector2(16, -5), Vector2(11, 0), Vector2(-11, 0)])
	bell.color = Color("b79355")
	add_child(bell)

func _add_crystal_cluster(x: float, y: float) -> void:
	for i in 4:
		var crystal := Polygon2D.new()
		var offset := Vector2((i - 2) * 15, 0)
		var height := 46 + (i * 19) % 38
		crystal.position = Vector2(x, y) + offset
		crystal.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(-7, -height * 0.72), Vector2(0, -height), Vector2(10, 0), Vector2(2, -7)])
		crystal.color = [Color("63b5ac"), Color("738fb2"), Color("8ac9bf"), Color("5c8992")][i]
		add_child(crystal)

func _add_tablet(x: float, y: float) -> void:
	var slab := Polygon2D.new()
	slab.position = Vector2(x, y)
	slab.polygon = PackedVector2Array([Vector2(-45, 0), Vector2(-39, -104), Vector2(-25, -119), Vector2(31, -118), Vector2(44, -98), Vector2(40, 0)])
	slab.color = Color("566967") if chapter_id == 3 else Color("73705e")
	add_child(slab)
	for rune in 3:
		var line := Line2D.new()
		line.position = Vector2(x, y)
		line.points = PackedVector2Array([Vector2(-12, -85 + rune * 23), Vector2(10, -76 + rune * 23), Vector2(0, -63 + rune * 23)])
		line.width = 3.0
		line.default_color = Color("76c4b0") if chapter_id == 3 else Color("d5bf83")
		add_child(line)

func _add_lab_console(x: float, y: float, label: String) -> void:
	var cabinet := Polygon2D.new()
	cabinet.position = Vector2(x, y)
	cabinet.polygon = PackedVector2Array([Vector2(-40, 0), Vector2(-34, -95), Vector2(34, -95), Vector2(40, 0)])
	cabinet.color = Color("525c59")
	add_child(cabinet)
	var screen := Polygon2D.new()
	screen.position = Vector2(x, y - 72)
	screen.polygon = PackedVector2Array([Vector2(-25, -12), Vector2(25, -12), Vector2(25, 12), Vector2(-25, 12)])
	screen.color = Color("7eae99", 0.76)
	add_child(screen)
	var nameplate := Label.new()
	nameplate.text = label
	nameplate.position = Vector2(x - 55, y - 125)
	nameplate.add_theme_font_size_override("font_size", 12)
	nameplate.add_theme_color_override("font_color", Color("d1c18d"))
	add_child(nameplate)

func _add_lab_door(x: float, y: float) -> void:
	var door := Polygon2D.new()
	door.position = Vector2(x, y)
	door.polygon = PackedVector2Array([Vector2(-59, 0), Vector2(-59, -190), Vector2(59, -190), Vector2(59, 0)])
	door.color = Color("333c3d")
	add_child(door)
	var slit := Polygon2D.new()
	slit.position = Vector2(x, y - 105)
	slit.polygon = PackedVector2Array([Vector2(-31, -34), Vector2(31, -34), Vector2(31, 34), Vector2(-31, 34)])
	slit.color = Color("7c9689", 0.46)
	add_child(slit)

func _add_memory_shard(x: float, y: float) -> void:
	var shard := Polygon2D.new()
	shard.position = Vector2(x, y)
	shard.polygon = PackedVector2Array([Vector2(0, -42), Vector2(21, -13), Vector2(12, 22), Vector2(0, 35), Vector2(-12, 22), Vector2(-21, -13)])
	shard.color = Color("c8d9b7", 0.84)
	add_child(shard)
	var inner := Polygon2D.new()
	inner.position = Vector2(x, y)
	inner.polygon = PackedVector2Array([Vector2(0, -27), Vector2(9, -9), Vector2(5, 15), Vector2(0, 22), Vector2(-5, 15), Vector2(-9, -9)])
	inner.color = Color("e2e1b6", 0.75)
	add_child(inner)

func _on_start_requested() -> void:
	player.controls_enabled = false
	hud.show_dialogue(intro_lines)

func clue_found(title: String, body: String) -> void:
	player.controls_enabled = false
	hud.show_note(title, body)

func show_dialogue(lines: Array[String]) -> void:
	player.controls_enabled = false
	hud.show_dialogue(lines)

func show_puzzle(title: String, hint: String, options: Array[String], answer_index: int) -> void:
	player.controls_enabled = false
	hud.show_puzzle(title, hint, options, answer_index)

func _on_clue_count_changed(count: int) -> void:
	hud.update_clue_count(count)

func _on_stats_changed(health: int, max_health: int, coins: int) -> void:
	if hud:
		hud.update_stats(health, max_health, coins)
	JourneyProgress.update_player_state(health, max_health, coins)
	JourneyProgress.set_player_checkpoint(chapter_id, player.position)

func _on_player_died() -> void:
	if hud:
		hud.show_game_over()

func _on_dialogue_finished() -> void:
	if puzzle.solved:
		if chapter_id == 5:
			if ending_phase == 1:
				ending_phase = 2
				exit_marker.set_open(true)
				JourneyAudio.play_sfx("door")
				player.controls_enabled = true
				hud.show_objective("THE FINAL PORTAL IS OPEN  ·  REACH IT AND PRESS E")
			elif ending_phase == 2:
				player.controls_enabled = true
				hud.show_objective("THE FINAL PORTAL IS OPEN  ·  REACH IT AND PRESS E")
			return
		JourneyProgress.complete_chapter(chapter_id)
		hud.show_completion(completion_text)
	else:
		player.controls_enabled = true

func _on_puzzle_answered(correct: bool) -> void:
	if correct:
		puzzle.solve()
		if chapter_id == 5:
			ending_phase = 1
		else:
			JourneyAudio.play_sfx("door")
		hud.show_dialogue(success_lines)
	else:
		hud.show_dialogue(["The mechanism stays silent.", "I should reconsider the clues before trying again."])

func start_final_cinematic() -> void:
	if chapter_id != 5 or ending_phase != 2:
		return
	ending_phase = 3
	JourneyProgress.complete_chapter(chapter_id)
	player.controls_enabled = false
	hud.begin_finale_transition()
