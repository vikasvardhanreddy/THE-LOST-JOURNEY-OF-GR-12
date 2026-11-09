extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/chapter_hud.tscn")
const PROP_SCRIPT := preload("res://scripts/world/forest_prop.gd")
const CLUE_SCRIPT := preload("res://scripts/world/clue.gd")
const PUZZLE_SCRIPT := preload("res://scripts/world/forest_puzzle.gd")
const GROUND_SCRIPT := preload("res://scripts/world/forest_ground.gd")
const DETAIL_SCRIPT := preload("res://scripts/world/forest_detail.gd")
const ATMOSPHERE_SCRIPT := preload("res://scripts/world/forest_atmosphere.gd")
const FIREFLIES_SCRIPT := preload("res://scripts/world/forest_fireflies.gd")
const ARCH_SCRIPT := preload("res://scripts/world/forest_arch.gd")
const COIN_SCRIPT := preload("res://scripts/world/forest_coin.gd")
const ENEMY_SCRIPT := preload("res://scripts/world/forest_enemy.gd")

var player: ForestPlayer
var hud: ChapterHUD
var puzzle: ForestPuzzle
var arch: Node2D

func _ready() -> void:
	if JourneyProgress.current_chapter > 1:
		get_tree().change_scene_to_file(JourneyProgress.chapter_scene(JourneyProgress.current_chapter))
		return
	JourneyProgress.begin_chapter(1)
	JourneyAudio.play_chapter_music(1)
	_build_forest()
	player = PLAYER_SCENE.instantiate()
	player.position = JourneyProgress.get_player_checkpoint(1, Vector2(100, 560))
	add_child(player)
	player.clue_count_changed.connect(_on_clue_count_changed)
	player.stats_changed.connect(_on_stats_changed)
	player.died.connect(_on_player_died)
	JourneyProgress.update_player_state(player.health, player.max_health, player.coins)
	JourneyProgress.set_player_checkpoint(1, player.position)
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	hud.configure_chapter(1, "The Awakening", "Mysterious Forest")
	hud.update_stats(player.health, player.max_health, player.coins)
	player.controls_enabled = false
	hud.start_requested.connect(_on_start_requested)
	hud.dialogue_finished.connect(_on_dialogue_finished)
	hud.puzzle_answered.connect(_on_puzzle_answered)
	if puzzle.solved:
		JourneyProgress.skip_chapter_title = false
		JourneyProgress.complete_chapter(1)
		hud.show_completion("The arch is open. Your trail continues toward the forgotten village.")
	elif JourneyProgress.skip_chapter_title:
		JourneyProgress.skip_chapter_title = false
		hud.begin_chapter_intro()

func _on_start_requested() -> void:
	player.controls_enabled = false
	hud.show_dialogue(["...Where am I?", "The forest is quiet. I should look for clues and find a way out."])

func _build_forest() -> void:
	# Atmospheric sky and distant ridges drift slowly behind the playable layer.
	var far_layer := Parallax2D.new()
	far_layer.scroll_scale = Vector2(0.18, 0.12)
	far_layer.repeat_size = Vector2(0, 0)
	far_layer.add_child(ATMOSPHERE_SCRIPT.new())
	add_child(far_layer)
	var color_grade := CanvasModulate.new()
	color_grade.color = Color("c3d1b8")
	add_child(color_grade)
	for x in [-220, 130, 500, 850, 1220, 1570, 1940, 2290, 2680]:
		var tree := PROP_SCRIPT.new()
		tree.position = Vector2(x, 560)
		tree.tree_height = 145.0 + float(posmod(x, 3)) * 18.0
		tree.tree_width = 98.0 + float(posmod(x, 2)) * 15.0
		tree.depth = -1.0
		add_child(tree)
	for x in [-80, 260, 610, 1010, 1400, 1780, 2160, 2640]:
		var tree := PROP_SCRIPT.new()
		tree.position = Vector2(x, 560)
		tree.tree_height = 205.0 + float(posmod(x, 3)) * 28.0
		tree.tree_width = 130.0 + float(posmod(x, 2)) * 26.0
		add_child(tree)
	_add_ground(-120, 2900, 620)
	for index in 16:
		var detail := DETAIL_SCRIPT.new()
		detail.position = Vector2(40 + index * 185, 566)
		detail.variant = index % 4
		detail.size_scale = 0.75 + float(index % 3) * 0.2
		add_child(detail)
	_add_platform(430, 580, 90)
	_add_platform(740, 490, 110)
	_add_platform(1040, 570, 90)
	_add_platform(1400, 500, 110)
	_add_platform(1720, 590, 100)
	_add_platform(2030, 520, 100)
	_add_clue(Vector2(480, 520), "Bark rubbing", "First mark: the rising sun starts above the path.", "forest_bark_rubbing")
	_add_clue(Vector2(1090, 525), "Stone carving", "Second mark: the trail dips below the roots.", "forest_stone_carving")
	_add_clue(Vector2(1800, 530), "Torn page", "Last mark: return upward. Read the three marks in order.", "forest_torn_page")
	for index in 7:
		var coin = COIN_SCRIPT.new()
		coin.position = Vector2(300 + index * 345, 535 if index % 2 == 0 else 490)
		add_child(coin)
	for x in [930.0, 1660.0, 2150.0]:
		var enemy = ENEMY_SCRIPT.new()
		enemy.position = Vector2(x, 620)
		enemy.patrol_distance = 52.0
		add_child(enemy)
	arch = ARCH_SCRIPT.new()
	arch.position = Vector2(2460, 620)
	add_child(arch)
	var fireflies := FIREFLIES_SCRIPT.new()
	fireflies.z_index = 2
	add_child(fireflies)
	puzzle = PUZZLE_SCRIPT.new()
	puzzle.position = Vector2(2330, 620)
	puzzle.puzzle_title = "THE STONE ARCH"
	puzzle.puzzle_hint = "The three marks show a path. Read them from left to right."
	puzzle.required_item_ids = ["forest_bark_rubbing", "forest_stone_carving", "forest_torn_page"]
	add_child(puzzle)
	_add_hazard(630, 610, 60, 20)
	_add_hazard(1260, 610, 70, 20)
	_add_hazard(1940, 610, 80, 20)
func _add_ground(x: float, width: float, top: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x + width * 0.5, top + 60)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 120)
	shape.shape = rectangle
	body.add_child(shape)
	var visual := Node2D.new()
	visual.set_script(GROUND_SCRIPT)
	visual.ground_width = width
	body.add_child(visual)
	add_child(body)

func _add_platform(x: float, top: float, width: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, top + 10)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 20)
	shape.shape = rectangle
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-width/2, -10), Vector2(width/2, -10), Vector2(width/2, 10), Vector2(-width/2, 10)])
	visual.color = Color("806342")
	body.add_child(visual)
	add_child(body)

func _add_hazard(x: float, y: float, width: float, height: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y + height / 2)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape.shape = rect
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(-width/2, -height/2), Vector2(0, -height/2-10), Vector2(width/2, -height/2), Vector2(width/2, height/2), Vector2(-width/2, height/2)])
	visual.color = Color("694e43")
	body.add_child(visual)
	add_child(body)

func _add_clue(at: Vector2, title: String, body: String, item_id: String) -> void:
	var clue := CLUE_SCRIPT.new()
	clue.position = at
	clue.clue_title = title
	clue.clue_text = body
	clue.item_id = item_id
	clue.motif = get_tree().get_nodes_in_group("chapter_clue").size()
	add_child(clue)

func clue_found(title: String, body: String) -> void:
	hud.show_note(title, body)
	player.controls_enabled = false

func show_dialogue(lines: Array[String]) -> void:
	player.controls_enabled = false
	hud.show_dialogue(lines)

func show_puzzle(title: String, hint: String, options: Array[String], correct_index: int) -> void:
	player.controls_enabled = false
	hud.show_puzzle(title, hint, options, correct_index)

func _on_clue_count_changed(count: int) -> void:
	hud.update_clue_count(count)

func _on_stats_changed(health: int, max_health: int, coins: int) -> void:
	if hud:
		hud.update_stats(health, max_health, coins)
	JourneyProgress.update_player_state(health, max_health, coins)
	JourneyProgress.set_player_checkpoint(1, player.position)

func _on_player_died() -> void:
	if hud:
		hud.show_game_over()

func _on_dialogue_finished() -> void:
	if puzzle.solved:
		JourneyProgress.complete_chapter(1)
		hud.show_completion("The arch opens. Beyond it lies the abandoned village—and a letter addressed to Elias.")
	else:
		player.controls_enabled = true

func _on_puzzle_answered(correct: bool) -> void:
	if correct:
		puzzle.solve()
		arch.set_open(true)
		JourneyAudio.play_sfx("door")
		hud.show_dialogue(["The marks match. The stone arch opens with a low rumble.", "I found a way beyond the forest."])
	else:
		hud.show_dialogue(["Nothing happens. The order must be wrong.", "I should check the three clues again."])

