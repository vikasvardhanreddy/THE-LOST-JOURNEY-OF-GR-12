extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var progress := root.get_node("JourneyProgress")
	progress.storage_enabled = false
	const temporary_save := "res://.chapter_selection_smoke_save.json"
	if FileAccess.file_exists(temporary_save):
		_fail("Refusing to overwrite an existing chapter-selection test save")
		return
	progress.unlocked_chapter = 1
	progress.current_chapter = 1
	progress.completed_chapters.clear()
	progress.complete_chapter(1)
	if progress.unlocked_chapter != 2 or not progress.completed_chapters.has(1):
		_fail("Completing chapter 1 did not unlock chapter 2")
		return
	progress.complete_chapter(2)
	if progress.unlocked_chapter != 3 or not progress.completed_chapters.has(2):
		_fail("Completing chapter 2 did not unlock chapter 3")
		return
	var previous_save_path: String = progress.save_path
	progress.save_path = temporary_save
	progress.storage_enabled = true
	progress.save_now()
	var reloaded: Node = (load("res://scripts/systems/journey_progress.gd") as GDScript).new()
	reloaded.save_path = temporary_save
	reloaded._load()
	progress.storage_enabled = false
	progress.save_path = previous_save_path
	if reloaded.unlocked_chapter != 3 or not reloaded.completed_chapters.has(1) or not reloaded.completed_chapters.has(2):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_save))
		_fail("Saved chapter unlock/completion progress did not load")
		return
	reloaded.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_save))
	var expected_scenes := [
		"res://scenes/chapters/chapter_01_forest.tscn",
		"res://scenes/chapters/chapter_02_village.tscn",
		"res://scenes/chapters/chapter_03_cave.tscn",
		"res://scenes/chapters/chapter_04_laboratory.tscn",
		"res://scenes/chapters/chapter_05_truth.tscn"
	]
	for chapter_id in range(1, 6):
		if progress.chapter_scene(chapter_id) != expected_scenes[chapter_id - 1]:
			_fail("Chapter %d points to the wrong scene" % chapter_id)
			return
	var menu: Node = (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	menu._open_chapters()
	await process_frame
	for chapter_id in range(1, 6):
		if menu.find_child("ChapterCard%02d" % chapter_id, true, false) == null or menu.find_child("ChapterThumbnail%02d" % chapter_id, true, false) == null:
			_fail("Chapter %d card or thumbnail is missing" % chapter_id)
			return
	var done_status := menu.find_child("ChapterStatus01", true, false) as Label
	var next_status := menu.find_child("ChapterStatus02", true, false) as Label
	var chapter_3_button := menu.find_child("SelectChapter03Button", true, false) as Button
	var chapter_4_button := menu.find_child("SelectChapter04Button", true, false) as Button
	if done_status == null or not done_status.text.contains("COMPLETED") or next_status == null or not next_status.text.contains("COMPLETED"):
		_fail("Completed chapters are not marked on the selection screen")
		return
	if chapter_3_button == null or chapter_3_button.disabled or chapter_4_button == null or not chapter_4_button.disabled:
		_fail("Unlocked and locked chapter buttons do not match saved progress")
		return
	chapter_3_button.pressed.emit()
	await process_frame
	await process_frame
	if current_scene == null or current_scene.scene_file_path != expected_scenes[2]:
		_fail("Selecting chapter 3 did not open its matching game scene")
		return
	menu.queue_free()
	await process_frame
	print("Chapter selection test passed: completion unlocks, locked states, five thumbnails, and chapter scene routing.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
