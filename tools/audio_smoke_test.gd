extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio := root.get_node_or_null("JourneyAudio")
	if audio == null:
		push_error("JourneyAudio autoload did not start")
		quit(1)
		return
	for chapter_id in range(1, 6):
		audio.play_chapter_music(chapter_id)
		await create_timer(0.05).timeout
		if audio._active_track != chapter_id:
			push_error("Chapter music did not switch to chapter %d" % chapter_id)
			quit(1)
			return
	for key in audio.SFX_PATHS:
		audio.play_sfx(key)
		await create_timer(0.03).timeout
	var progress := root.get_node("JourneyProgress")
	progress.storage_enabled = false
	progress.set_music_volume(0.35)
	progress.set_sfx_volume(0.72)
	if not is_equal_approx(progress.music_volume, 0.35) or not is_equal_approx(progress.sfx_volume, 0.72):
		push_error("Independent volume values did not apply")
		quit(1)
		return
	var menu: Node = (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	await process_frame
	var settings := menu.find_child("SettingsButton", true, false) as Button
	if settings == null:
		push_error("Main menu settings button is missing")
		quit(1)
		return
	settings.pressed.emit()
	await process_frame
	var music_slider := menu.find_child("MusicVolumeSlider", true, false) as HSlider
	var effects_slider := menu.find_child("SoundEffectsVolumeSlider", true, false) as HSlider
	if music_slider == null or effects_slider == null:
		push_error("Separate settings sliders are missing")
		quit(1)
		return
	music_slider.value = 0.25
	effects_slider.value = 0.8
	if not is_equal_approx(progress.music_volume, 0.25) or not is_equal_approx(progress.sfx_volume, 0.8):
		push_error("Settings sliders did not control their separate audio buses")
		quit(1)
		return
	var hud: Node = (load("res://scenes/ui/chapter_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud.begin_chapter_intro()
	hud.show_pause_menu()
	var pause_settings: Button
	for candidate in hud.find_children("*", "Button", true, false):
		if candidate.text == "Audio settings":
			pause_settings = candidate
			break
	if pause_settings == null:
		push_error("In-game audio settings button is missing")
		quit(1)
		return
	pause_settings.pressed.emit()
	await process_frame
	var pause_sliders := hud.find_children("*", "HSlider", true, false)
	var pause_music_slider: HSlider = pause_sliders[0] if not pause_sliders.is_empty() else null
	if pause_music_slider == null:
		push_error("In-game audio settings panel did not open")
		quit(1)
		return
	print("Audio smoke test passed: chapter tracks, effects, main menu and in-game audio controls.")
	menu.queue_free()
	hud.queue_free()
	await process_frame
	quit(0)
