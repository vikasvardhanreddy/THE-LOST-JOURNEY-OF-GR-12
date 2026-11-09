extends SceneTree

const CHAPTERS := [
	"res://scenes/chapters/chapter_01_forest.tscn",
	"res://scenes/chapters/chapter_02_village.tscn",
	"res://scenes/chapters/chapter_03_cave.tscn",
	"res://scenes/chapters/chapter_04_laboratory.tscn",
	"res://scenes/chapters/chapter_05_truth.tscn"
]
var _exit_requested_seen := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var progress := root.get_node("JourneyProgress")
	progress.storage_enabled = false
	if int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) != 0:
		_fail("Project mobile orientation is not Landscape")
		return
	var android_preset := ConfigFile.new()
	if android_preset.load("res://export_presets.cfg") != OK:
		_fail("Android export preset could not be loaded")
		return
	if android_preset.get_value("preset.0.options", "package/unique_name", "") != "com.mygamestudio.thelostjourney":
		_fail("Android application ID is incorrect")
		return
	if int(android_preset.get_value("preset.0.options", "screen/orientation", -1)) != 0:
		_fail("Android export preset does not use Landscape orientation")
		return
	progress.reset_progress()
	progress.storage_enabled = false
	progress.unlocked_chapter = 5
	for index in CHAPTERS.size():
		progress.current_chapter = index + 1
		progress.completed_puzzles.clear()
		var inventory_script := load("res://scripts/systems/journey_inventory.gd")
		progress.inventory = inventory_script.new()
		if ResourceLoader.load(CHAPTERS[index]) == null:
			_fail("Chapter %d scene resource failed to load" % (index + 1))
			return
		var err := change_scene_to_file(CHAPTERS[index])
		if err != OK:
			_fail("Chapter %d could not be opened: %s" % [index + 1, error_string(err)])
			return
		await process_frame
		await process_frame
		var chapter := current_scene
		if chapter == null or chapter.scene_file_path != CHAPTERS[index]:
			_fail("Chapter %d did not become the active scene" % (index + 1))
			return
		var players := get_nodes_in_group("players")
		var player: Node = players[0] if not players.is_empty() else null
		var hud := chapter.find_child("ChapterHUD", true, false)
		var puzzle: Node
		for candidate in get_nodes_in_group("interactable"):
			if candidate.get_script() != null and candidate.get_script().resource_path.ends_with("forest_puzzle.gd"):
				puzzle = candidate
				break
		if player == null or hud == null or puzzle == null:
			_fail("Chapter %d is missing its player, HUD, or puzzle" % (index + 1))
			return
		if chapter.find_children("*", "StaticBody2D", true, false).is_empty():
			_fail("Chapter %d has no ground collision body" % (index + 1))
			return
		if index == 0:
			player.controls_enabled = true
			player.position = Vector2(150, 560)
			await create_timer(0.6).timeout
			if not player.is_on_floor():
				_fail("Player did not collide with the chapter floor")
				return
			var starting_x: float = player.position.x
			Input.action_press("move_right")
			await create_timer(0.25).timeout
			Input.action_release("move_right")
			if player.position.x <= starting_x + 10.0:
				_fail("Player did not move when the right action was pressed")
				return
			if player._active_animation not in ["walk", "idle"]:
				_fail("Player did not enter a valid movement animation")
				return
			Input.action_press("run")
			Input.action_press("move_right")
			await create_timer(0.18).timeout
			Input.action_release("move_right")
			Input.action_release("run")
			if player._active_animation != "run":
				_fail("Run action did not trigger the run animation")
				return
			Input.action_press("jump")
			await create_timer(0.1).timeout
			Input.action_release("jump")
			if player.velocity.y >= 0.0:
				_fail("Jump action did not apply upward velocity (floor=%s y=%s controls=%s)" % [player.is_on_floor(), player.position.y, player.controls_enabled])
				return
			if player._active_animation != "jump":
				_fail("Jump did not trigger the jump animation")
				return
			await create_timer(0.5).timeout
			Input.action_press("attack")
			await create_timer(0.08).timeout
			Input.action_release("attack")
			if player._active_animation != "attack":
				_fail("Attack did not trigger the attack animation")
				return
			player.take_damage(1, player.global_position + Vector2(30, 0))
			if player._active_animation != "hurt":
				_fail("Damage did not trigger the hurt animation")
				return
			await create_timer(0.95).timeout
			player.health = 1
			player.take_damage(1, player.global_position + Vector2(30, 0))
			if player._active_animation != "die":
				_fail("Lethal damage did not trigger the die animation")
				return
			var sprite := player.find_child("HeroSprite", true, false) as AnimatedSprite2D
			for animation in ["idle", "walk", "run", "jump", "attack", "hurt", "die"]:
				if sprite.sprite_frames.get_frame_count(animation) == 0:
					_fail("Character animation has no frames: %s" % animation)
					return
			player.is_dead = false
			player.health = 4
			player.controls_enabled = true
			var dialogue_lines: Array[String] = ["Quality check dialogue"]
			hud.show_dialogue(dialogue_lines)
			if not hud._dialogue_open or not hud._dialogue_label.text.contains("Quality check"):
				_fail("Dialogue did not display its text")
				return
			progress.add_inventory_item("qa_clue", "QA clue", "Saved inventory clue")
			hud._open_inventory()
			if hud.find_child("InventoryItem_qa_clue", true, false) == null:
				_fail("Collected clue did not appear in inventory")
				return
			hud._close_inventory()
			player.position = Vector2(150, 620)
			player.velocity = Vector2.ZERO
			await create_timer(0.5).timeout
			if not player.is_on_floor():
				_fail("Player did not collide with the chapter floor")
				return
			var temp_save := "res://.quality_check_save.json"
			if FileAccess.file_exists(temp_save):
				_fail("Refusing to overwrite an existing temporary quality-check save")
				return
			var old_path: String = progress.save_path
			progress.save_path = temp_save
			progress.storage_enabled = true
			progress.music_volume = 0.37
			progress.sfx_volume = 0.61
			progress.complete_puzzle("qa_puzzle")
			var loaded: Node = (load("res://scripts/systems/journey_progress.gd") as GDScript).new()
			loaded.save_path = temp_save
			loaded._load()
			progress.storage_enabled = false
			progress.save_path = old_path
			if not loaded.has_item("qa_clue") or not loaded.has_completed_puzzle("qa_puzzle") or not is_equal_approx(loaded.music_volume, 0.37) or not is_equal_approx(loaded.sfx_volume, 0.61):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_save))
				_fail("Inventory item did not survive save and reload")
				return
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_save))
			loaded.free()
		# Feed each chapter's required clues through the actual collectible objects.
		for clue in chapter.get_tree().get_nodes_in_group("chapter_clue"):
			clue.interact(player)
		for item_id in puzzle.required_item_ids:
			if not progress.has_item(item_id):
				_fail("Chapter %d required clue was not collectable: %s" % [index + 1, item_id])
				return
		puzzle.interact(player)
		if not hud._dialogue_open and hud._answer_index != puzzle.correct_answer_index:
			_fail("Chapter %d puzzle did not open after collecting its clues" % (index + 1))
			return
		chapter._on_puzzle_answered(true)
		if not puzzle.solved:
			_fail("Chapter %d puzzle did not complete" % (index + 1))
			return
		print("Chapter %d passed: scene, player, HUD, collision geometry, clues, puzzle flow." % (index + 1))
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	var official_logo := menu.find_child("OfficialGameLogo", true, false) as TextureRect
	if official_logo == null or official_logo.texture == null:
		_fail("Main menu did not load the supplied official logo")
		return
	for key in ["new_game", "continue", "chapters", "settings", "exit"]:
		if not menu._buttons.has(key):
			_fail("Main menu is missing its %s action" % key)
			return
	menu._buttons["new_game"].pressed.emit()
	await process_frame
	if menu.find_child("ConfirmNewGameButton", true, false) == null or menu.find_child("CancelNewGameButton", true, false) == null:
		_fail("New Game did not ask before replacing saved progress")
		return
	menu.find_child("CancelNewGameButton", true, false).pressed.emit()
	progress.current_chapter = 3
	menu._buttons["continue"].pressed.emit()
	await process_frame
	await process_frame
	if current_scene == null or current_scene.scene_file_path != CHAPTERS[2]:
		_fail("Continue did not open the saved current chapter")
		return
	_exit_requested_seen = false
	menu.exit_requested.connect(_mark_exit_requested)
	menu._buttons["exit"].pressed.emit()
	if not _exit_requested_seen:
		_fail("Exit button did not emit its exit action")
		return
	menu.queue_free()
	print("Main menu passed: all five actions exist, New Game confirms before reset, Continue routes to saved chapter, Exit action fires.")
	print("Quality check smoke test passed: all chapter scenes, first-chapter movement/jump/collision/dialogue/inventory/save-load, and all five puzzle completion flows.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _mark_exit_requested() -> void:
	_exit_requested_seen = true
