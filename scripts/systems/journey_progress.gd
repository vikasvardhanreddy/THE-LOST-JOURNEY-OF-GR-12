extends Node

signal inventory_changed

const InventoryScript = preload("res://scripts/systems/journey_inventory.gd")
const SAVE_PATH := "user://lost_journey_save.json"
const SAVE_VERSION := 2
const DEFAULT_HEALTH := 4
const DEFAULT_MAX_HEALTH := 4
const CHAPTER_SCENES := [
	"res://scenes/chapters/chapter_01_forest.tscn",
	"res://scenes/chapters/chapter_02_village.tscn",
	"res://scenes/chapters/chapter_03_cave.tscn",
	"res://scenes/chapters/chapter_04_laboratory.tscn",
	"res://scenes/chapters/chapter_05_truth.tscn"
]

var save_path := SAVE_PATH
var inventory: JourneyInventory = InventoryScript.new()
var unlocked_chapter := 1
var current_chapter := 1
var completed_chapters: Array[int] = []
var completed_puzzles: Array[String] = []
var coins := 0
var player_health := DEFAULT_HEALTH
var player_max_health := DEFAULT_MAX_HEALTH
var checkpoint_chapter := 0
var player_checkpoint := Vector2.ZERO
var music_volume := 0.65
var sfx_volume := 0.9
var has_saved_progress := false
var storage_enabled := true
var skip_chapter_title := false

func _ready() -> void:
	_load()
	_apply_audio_volumes()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_save()

func begin_chapter(chapter_id: int) -> bool:
	if chapter_id < 1 or chapter_id > CHAPTER_SCENES.size() or chapter_id > unlocked_chapter:
		return false
	if current_chapter == chapter_id:
		return true
	current_chapter = chapter_id
	checkpoint_chapter = 0
	player_checkpoint = Vector2.ZERO
	_save()
	return true

func chapter_scene(chapter_id: int) -> String:
	if chapter_id < 1 or chapter_id > CHAPTER_SCENES.size():
		return ""
	return CHAPTER_SCENES[chapter_id - 1]

func next_chapter_scene(chapter_id: int) -> String:
	return chapter_scene(mini(chapter_id + 1, CHAPTER_SCENES.size()))

func add_inventory_item(item_id: String, title: String, description: String, icon_key := "") -> bool:
	var added: bool = inventory.add_item(item_id, title, description, icon_key)
	if added:
		_save()
		inventory_changed.emit()
	return added

func has_item(item_id: String) -> bool:
	return inventory.has_item(item_id)

func complete_puzzle(puzzle_id: String) -> void:
	if puzzle_id.is_empty() or completed_puzzles.has(puzzle_id):
		return
	completed_puzzles.append(puzzle_id)
	completed_puzzles.sort()
	_save()

func has_completed_puzzle(puzzle_id: String) -> bool:
	return completed_puzzles.has(puzzle_id)

func update_player_state(health: int, max_health: int, coin_total: int) -> void:
	var clamped_max := clampi(max_health, 1, 20)
	var clamped_health := clampi(health, 0, clamped_max)
	var clamped_coins := maxi(0, coin_total)
	if player_health == clamped_health and player_max_health == clamped_max and coins == clamped_coins:
		return
	player_health = clamped_health
	player_max_health = clamped_max
	coins = clamped_coins
	_save()

func set_player_checkpoint(chapter_id: int, position: Vector2) -> void:
	if chapter_id < 1 or chapter_id > CHAPTER_SCENES.size():
		return
	if checkpoint_chapter == chapter_id and player_checkpoint.distance_squared_to(position) < 4.0:
		return
	checkpoint_chapter = chapter_id
	player_checkpoint = position
	_save()

func get_player_checkpoint(chapter_id: int, fallback: Vector2) -> Vector2:
	return player_checkpoint if checkpoint_chapter == chapter_id else fallback

func set_master_volume(value: float) -> void:
	set_music_volume(value)
	set_sfx_volume(value)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	JourneyAudio.set_music_volume(music_volume)
	_save()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	JourneyAudio.set_sfx_volume(sfx_volume)
	_save()

func has_existing_progress() -> bool:
	var unreadable_save_exists := not has_saved_progress and FileAccess.file_exists(save_path)
	return unreadable_save_exists or current_chapter > 1 or unlocked_chapter > 1 or checkpoint_chapter > 0 or not completed_chapters.is_empty() or not completed_puzzles.is_empty() or inventory.get_item_count() > 0 or coins > 0

func _apply_audio_volumes() -> void:
	JourneyAudio.set_music_volume(music_volume)
	JourneyAudio.set_sfx_volume(sfx_volume)

func complete_chapter(chapter_id: int) -> void:
	if chapter_id < 1 or chapter_id > CHAPTER_SCENES.size():
		return
	if not completed_chapters.has(chapter_id):
		completed_chapters.append(chapter_id)
	completed_chapters.sort()
	unlocked_chapter = maxi(unlocked_chapter, mini(chapter_id + 1, CHAPTER_SCENES.size()))
	current_chapter = mini(chapter_id + 1, CHAPTER_SCENES.size())
	_save()

func reset_progress() -> void:
	unlocked_chapter = 1
	current_chapter = 1
	completed_chapters.clear()
	completed_puzzles.clear()
	coins = 0
	player_health = DEFAULT_HEALTH
	player_max_health = DEFAULT_MAX_HEALTH
	checkpoint_chapter = 0
	player_checkpoint = Vector2.ZERO
	inventory = InventoryScript.new()
	has_saved_progress = false
	_save()
	inventory_changed.emit()

func add_coins(amount: int) -> void:
	coins = maxi(0, coins + amount)
	_save()

func _save(preserve_backup := false) -> void:
	if not storage_enabled:
		return
	var temp_path := save_path + ".tmp"
	var backup_path := save_path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to prepare journey save: %s" % error_string(FileAccess.get_open_error()))
		return
	var data := {
		"version": SAVE_VERSION,
		"unlocked_chapter": unlocked_chapter,
		"current_chapter": current_chapter,
		"completed_chapters": completed_chapters,
		"completed_puzzles": completed_puzzles,
		"coins": coins,
		"health": player_health,
		"max_health": player_max_health,
		"checkpoint_chapter": checkpoint_chapter,
		"player_position": [player_checkpoint.x, player_checkpoint.y],
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"master_volume": (music_volume + sfx_volume) * 0.5,
		"inventory": inventory.get_all_items()
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		push_warning("Unable to write journey save: %s" % error_string(write_error))
		return
	var absolute_temp := ProjectSettings.globalize_path(temp_path)
	var absolute_save := ProjectSettings.globalize_path(save_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if preserve_backup:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(absolute_save)
	elif FileAccess.file_exists(save_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(absolute_backup)
		var backup_error := DirAccess.rename_absolute(absolute_save, absolute_backup)
		if backup_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			push_warning("Unable to rotate the previous journey save: %s" % error_string(backup_error))
			return
	var save_error := DirAccess.rename_absolute(absolute_temp, absolute_save)
	if save_error != OK:
		if FileAccess.file_exists(backup_path) and not FileAccess.file_exists(save_path):
			DirAccess.rename_absolute(absolute_backup, absolute_save)
		push_warning("Unable to commit journey save: %s" % error_string(save_error))
		return
	has_saved_progress = true

func save_now() -> void:
	_save()

func _load() -> void:
	var data := _read_save(save_path)
	var recovered_backup := false
	if data.is_empty():
		var backup_path := save_path + ".bak"
		if FileAccess.file_exists(backup_path):
			data = _read_save(backup_path)
			recovered_backup = not data.is_empty()
	if data.is_empty():
		if FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak"):
			push_warning("Journey save is missing or corrupted. Starting with safe default progress.")
		return
	var version := int(data.get("version", 1))
	if version > SAVE_VERSION:
		push_warning("Journey save version is newer than this game. Starting with safe defaults.")
		return
	unlocked_chapter = clampi(int(data.get("unlocked_chapter", 1)), 1, CHAPTER_SCENES.size())
	current_chapter = clampi(int(data.get("current_chapter", 1)), 1, unlocked_chapter)
	coins = maxi(0, int(data.get("coins", 0)))
	player_max_health = clampi(int(data.get("max_health", DEFAULT_MAX_HEALTH)), 1, 20)
	player_health = clampi(int(data.get("health", player_max_health)), 1, player_max_health)
	checkpoint_chapter = clampi(int(data.get("checkpoint_chapter", 0)), 0, CHAPTER_SCENES.size())
	var saved_position: Variant = data.get("player_position", [0.0, 0.0])
	if saved_position is Array and saved_position.size() >= 2:
		player_checkpoint = Vector2(float(saved_position[0]), float(saved_position[1]))
	var legacy_volume := clampf(float(data.get("master_volume", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(data.get("music_volume", legacy_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx_volume", legacy_volume)), 0.0, 1.0)
	completed_chapters.clear()
	for value in data.get("completed_chapters", []):
		var chapter_id := int(value)
		if chapter_id >= 1 and chapter_id <= CHAPTER_SCENES.size() and not completed_chapters.has(chapter_id):
			completed_chapters.append(chapter_id)
	completed_puzzles.clear()
	for value in data.get("completed_puzzles", []):
		var puzzle_id := String(value)
		if not puzzle_id.is_empty() and not completed_puzzles.has(puzzle_id):
			completed_puzzles.append(puzzle_id)
	var saved_items: Variant = data.get("inventory", {})
	if saved_items is Dictionary:
		inventory.load_items(saved_items)
	has_saved_progress = true
	if recovered_backup:
		push_warning("The main save was unavailable; recovered the previous backup.")
		_save(true)

func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed: Variant = parser.data
	if parsed is Dictionary and (parsed.has("current_chapter") or parsed.has("inventory")):
		if int(parsed.get("version", 1)) > SAVE_VERSION:
			return {}
		return parsed
	return {}
