extends Control

signal exit_requested

const CHAPTER_NAMES := ["The Awakening", "The Forgotten Village", "The Hidden Cave", "The Secret Laboratory", "The Truth"]
const FOREST_SKY := preload("res://scripts/world/forest_atmosphere.gd")
const FOREST_TREE := preload("res://scripts/world/forest_prop.gd")
const FOREST_GROUND := preload("res://scripts/world/forest_ground.gd")
const FIREFLIES := preload("res://scripts/world/forest_fireflies.gd")
const CHAPTER_THUMBNAIL := preload("res://scripts/ui/chapter_thumbnail.gd")

var _page: Control
var _buttons: Dictionary = {}
var _button_tweens: Dictionary = {}

func _ready() -> void:
	JourneyAudio.play_menu_music()
	_build_forest()
	_build_layout()
	_refresh_continue_button()

func _build_forest() -> void:
	# Reuse the game's hand-drawn forest layers as a quiet, animated title backdrop.
	var forest := Node2D.new()
	forest.name = "ForestBackdrop"
	forest.z_index = -10
	add_child(forest)
	var art := Node2D.new()
	art.scale = Vector2(size.x / 3600.0, size.y / 720.0)
	forest.add_child(art)
	var sky := FOREST_SKY.new()
	sky.world_width = 3600
	art.add_child(sky)
	for index in 15:
		var tree := FOREST_TREE.new()
		tree.position = Vector2(140 + index * 250, 660)
		tree.tree_height = 190.0 + float((index * 47) % 120)
		tree.tree_width = 125.0 + float((index * 23) % 55)
		tree.z_index = -1 if index % 2 == 0 else 1
		art.add_child(tree)
	var floor_art := FOREST_GROUND.new()
	floor_art.position = Vector2(1800, 690)
	floor_art.ground_width = 3600
	art.add_child(floor_art)
	var glimmers := FIREFLIES.new()
	glimmers.position = Vector2(0, 55)
	art.add_child(glimmers)
	forest.set_meta("art", art)
	resized.connect(_resize_forest.bind(forest))
	_resize_forest(forest)
	var shade := ColorRect.new()
	shade.name = "AtmosphereOverlay"
	shade.color = Color("081512", 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = -1
	add_child(shade)

func _resize_forest(forest: Node2D) -> void:
	if is_instance_valid(forest) and forest.has_meta("art"):
		(forest.get_meta("art") as Node2D).scale = Vector2(size.x / 3600.0, size.y / 720.0)

func _build_layout() -> void:
	var header := VBoxContainer.new()
	header.name = "TitleHeader"
	header.anchor_left = 0.12
	header.anchor_right = 0.88
	header.anchor_top = 0.045
	header.anchor_bottom = 0.26
	header.add_theme_constant_override("separation", 0)
	add_child(header)
	var emblem := Label.new()
	emblem.text = "✦   A STORY OF MEMORY AND MYSTERY   ✦"
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.add_theme_font_size_override("font_size", 17)
	emblem.add_theme_color_override("font_color", Color("e4cd91"))
	header.add_child(emblem)
	var brand_row := HBoxContainer.new()
	brand_row.name = "GameTitleBranding"
	brand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_row.add_theme_constant_override("separation", 14)
	brand_row.custom_minimum_size = Vector2(0, 92)
	header.add_child(brand_row)
	var logo := TextureRect.new()
	logo.name = "OfficialGameLogo"
	logo.texture = load("res://assets/branding/official_logo.png")
	logo.custom_minimum_size = Vector2(88, 88)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_row.add_child(logo)
	var title := Label.new()
	title.name = "GameTitle"
	title.text = "THE LOST JOURNEY\nOF GR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("f4e5bd"))
	title.add_theme_color_override("font_shadow_color", Color("08100e", 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 5)
	brand_row.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Every path leaves a trace."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("e0d6ba", 0.95))
	header.add_child(subtitle)

	var panel := PanelContainer.new()
	panel.name = "MainMenuPanel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.59
	panel.anchor_bottom = 0.59
	panel.offset_left = -235
	panel.offset_right = 235
	panel.offset_top = -193
	panel.offset_bottom = 193
	panel.add_theme_stylebox_override("panel", _panel_style(Color("10211e", 0.9), Color("c1a66d", 0.92), 22, 2))
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	var section := Label.new()
	section.text = "CHOOSE YOUR PATH"
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_theme_font_size_override("font_size", 16)
	section.add_theme_color_override("font_color", Color("dec68d"))
	content.add_child(section)
	_add_menu_button(content, "new_game", "New Game", _on_new_game)
	_add_menu_button(content, "continue", "Continue", _on_continue)
	_add_menu_button(content, "chapters", "Chapter Selection", _open_chapters)
	_add_menu_button(content, "settings", "Settings", _open_settings)
	_add_menu_button(content, "exit", "Exit", _on_exit)
	var footer := Label.new()
	footer.text = "A quiet forest. A journey waiting to be found."
	footer.anchor_left = 0.08
	footer.anchor_right = 0.92
	footer.anchor_top = 0.94
	footer.anchor_bottom = 0.99
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("e0d6ba", 0.78))
	add_child(footer)

func _add_menu_button(parent: VBoxContainer, key: String, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = key.capitalize() + "Button"
	button.text = label.to_upper()
	button.custom_minimum_size = Vector2(390, 55)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("f4eddb"))
	button.add_theme_color_override("font_hover_color", Color("fff1c6"))
	button.add_theme_color_override("font_pressed_color", Color("f5d99a"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("263b34", 0.96), Color("74866b", 0.9), 13, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("3b5847", 0.99), Color("e0c17d"), 13, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("1e302c"), Color("e0c17d"), 13, 2))
	button.add_theme_stylebox_override("focus", _panel_style(Color("324b3e"), Color("d5bb80"), 13, 2))
	button.mouse_entered.connect(_animate_button.bind(button, true))
	button.mouse_exited.connect(_animate_button.bind(button, false))
	button.button_down.connect(_press_button.bind(button))
	button.button_up.connect(_release_button.bind(button))
	button.resized.connect(func(): button.pivot_offset = button.size * 0.5)
	button.pressed.connect(_play_button_sound)
	button.pressed.connect(action)
	parent.add_child(button)
	_buttons[key] = button
	return button

func _animate_button(button: Button, hovering: bool) -> void:
	_tween_button(button, Vector2(1.025, 1.025) if hovering else Vector2.ONE, 0.14)

func _press_button(button: Button) -> void:
	_tween_button(button, Vector2(0.975, 0.975), 0.06)

func _release_button(button: Button) -> void:
	_tween_button(button, Vector2(1.025, 1.025) if button.is_hovered() else Vector2.ONE, 0.11)

func _tween_button(button: Button, target: Vector2, duration: float) -> void:
	var id := button.get_instance_id()
	if _button_tweens.has(id) and is_instance_valid(_button_tweens[id]):
		_button_tweens[id].kill()
	var tween := create_tween()
	_button_tweens[id] = tween
	tween.tween_property(button, "scale", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color("050b09", 0.62)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 4)
	return style

func _refresh_continue_button() -> void:
	var button: Button = _buttons.get("continue")
	if button:
		var chapter := clampi(JourneyProgress.current_chapter, 1, CHAPTER_NAMES.size())
		button.text = "CONTINUE   ·   %s" % CHAPTER_NAMES[chapter - 1].to_upper()

func _launch_chapter(chapter_id: int) -> void:
	if chapter_id < 1 or chapter_id > JourneyProgress.unlocked_chapter:
		return
	JourneyProgress.begin_chapter(chapter_id)
	JourneyAudio.play_chapter_music(chapter_id)
	JourneyProgress.skip_chapter_title = true
	get_tree().change_scene_to_file(JourneyProgress.chapter_scene(chapter_id))

func _on_new_game() -> void:
	if JourneyProgress.has_existing_progress():
		_show_modal("START A NEW JOURNEY?", "This replaces your current chapter, clues, and puzzles. Your existing progress will be backed up.")
		var stack := _page.get_meta("stack") as VBoxContainer
		var confirm := _make_modal_button("RESET PROGRESS AND START")
		confirm.name = "ConfirmNewGameButton"
		confirm.pressed.connect(_confirm_new_game)
		stack.add_child(confirm)
		var cancel := _make_modal_button("KEEP CURRENT PROGRESS")
		cancel.name = "CancelNewGameButton"
		cancel.pressed.connect(_close_modal)
		stack.add_child(cancel)
		return
	_confirm_new_game()

func _confirm_new_game() -> void:
	JourneyProgress.reset_progress()
	_launch_chapter(1)

func _on_continue() -> void:
	_launch_chapter(clampi(JourneyProgress.current_chapter, 1, CHAPTER_NAMES.size()))

func _open_chapters() -> void:
	if is_instance_valid(_page):
		_page.queue_free()
	_page = Control.new()
	_page.name = "ChapterSelectionScreen"
	_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page)
	var shade := ColorRect.new()
	shade.color = Color("07110f", 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_page.add_child(shade)
	var frame := PanelContainer.new()
	frame.name = "ChapterSelectionFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 24
	frame.offset_top = 18
	frame.offset_right = -24
	frame.offset_bottom = -18
	frame.add_theme_stylebox_override("panel", _panel_style(Color("10211e", 0.97), Color("c1a66d", 0.96), 22, 2))
	_page.add_child(frame)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	frame.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 60
	header.add_theme_constant_override("separation", 14)
	content.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 1)
	header.add_child(title_stack)
	var heading := Label.new()
	heading.name = "ChapterSelectionTitle"
	heading.text = "CHOOSE YOUR CHAPTER"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("f4e5bd"))
	title_stack.add_child(heading)
	var subheading := Label.new()
	subheading.text = "Explore the story in order, or revisit a completed chapter."
	subheading.add_theme_font_size_override("font_size", 14)
	subheading.add_theme_color_override("font_color", Color("d0c7ad"))
	title_stack.add_child(subheading)
	var progress := Label.new()
	progress.name = "ChapterProgressSummary"
	progress.text = "%d / 5 COMPLETED   ·   UNLOCKED THROUGH CHAPTER %d" % [JourneyProgress.completed_chapters.size(), JourneyProgress.unlocked_chapter]
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 13)
	progress.add_theme_color_override("font_color", Color("dec68d"))
	header.add_child(progress)
	_page.resized.connect(_resize_chapter_selection.bind(progress))
	var scroller := ScrollContainer.new()
	scroller.name = "ChapterCardsScroll"
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroller)
	var row := HBoxContainer.new()
	row.name = "ChapterCards"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	scroller.add_child(row)
	for index in CHAPTER_NAMES.size():
		row.add_child(_make_chapter_card(index + 1))
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.custom_minimum_size.y = 48
	content.add_child(footer)
	var back := _make_modal_button("BACK TO MAIN MENU")
	back.name = "ChapterSelectionBackButton"
	back.custom_minimum_size = Vector2(240, 46)
	back.pressed.connect(_close_modal)
	footer.add_child(back)
	_resize_chapter_selection(progress)

func _resize_chapter_selection(progress: Label) -> void:
	if is_instance_valid(progress):
		progress.visible = size.x >= 1020.0

func _make_chapter_card(chapter_id: int) -> PanelContainer:
	var completed := JourneyProgress.completed_chapters.has(chapter_id)
	var unlocked := chapter_id <= JourneyProgress.unlocked_chapter
	var card := PanelContainer.new()
	card.name = "ChapterCard%02d" % chapter_id
	card.custom_minimum_size = Vector2(210, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var edge := Color("bfa66e") if completed else Color("8b9675") if unlocked else Color("4c5a52")
	card.add_theme_stylebox_override("panel", _panel_style(Color("1c2c28", 0.98), edge, 16, 2))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	card.add_child(stack)
	var thumbnail := Control.new()
	thumbnail.name = "ChapterThumbnail%02d" % chapter_id
	thumbnail.set_script(CHAPTER_THUMBNAIL)
	thumbnail.set("chapter_index", chapter_id)
	thumbnail.queue_redraw()
	thumbnail.custom_minimum_size = Vector2(0, clampf(size.y * 0.27, 145.0, 190.0))
	thumbnail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thumbnail.clip_contents = true
	stack.add_child(thumbnail)
	if not unlocked:
		var lock_shade := ColorRect.new()
		lock_shade.name = "LockedThumbnailShade"
		lock_shade.color = Color("091310", 0.48)
		lock_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumbnail.add_child(lock_shade)
		var lock_mark := Label.new()
		lock_mark.text = "LOCKED"
		lock_mark.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock_mark.offset_left = -48
		lock_mark.offset_right = 48
		lock_mark.offset_top = -17
		lock_mark.offset_bottom = 17
		lock_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_mark.add_theme_font_size_override("font_size", 14)
		lock_mark.add_theme_color_override("font_color", Color("ead8ad"))
		lock_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumbnail.add_child(lock_mark)
	var chapter_label := Label.new()
	chapter_label.text = "CHAPTER %02d" % chapter_id
	chapter_label.add_theme_font_size_override("font_size", 12)
	chapter_label.add_theme_color_override("font_color", Color("d4b978"))
	stack.add_child(chapter_label)
	var name := Label.new()
	name.name = "ChapterName%02d" % chapter_id
	name.text = CHAPTER_NAMES[chapter_id - 1]
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size.y = 44
	name.add_theme_font_size_override("font_size", 19)
	name.add_theme_color_override("font_color", Color("f0e5c8") if unlocked else Color("b4b5a8"))
	stack.add_child(name)
	var summaries := [
		"Wake in a forest and follow the first clues.",
		"Search empty homes for a letter and its secret.",
		"Follow crystal light through the underground.",
		"Explore sealed rooms and uncover hidden records.",
		"Bring the memories together and find the truth."
	]
	var summary := Label.new()
	summary.text = summaries[chapter_id - 1]
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.add_theme_font_size_override("font_size", 13)
	summary.add_theme_color_override("font_color", Color("c9c5b4", 0.92))
	stack.add_child(summary)
	var state := Label.new()
	state.name = "ChapterStatus%02d" % chapter_id
	state.text = "✦  COMPLETED" if completed else "●  CURRENT CHAPTER" if chapter_id == JourneyProgress.current_chapter else "●  AVAILABLE" if unlocked else "◈  LOCKED"
	state.add_theme_font_size_override("font_size", 12)
	state.add_theme_color_override("font_color", Color("e5c77e") if completed else Color("a9c78f") if unlocked else Color("8f9a91"))
	stack.add_child(state)
	var select := Button.new()
	select.name = "SelectChapter%02dButton" % chapter_id
	select.text = "REPLAY CHAPTER" if completed else "CONTINUE" if chapter_id == JourneyProgress.current_chapter else "PLAY CHAPTER" if unlocked else "LOCKED"
	select.disabled = not unlocked
	select.custom_minimum_size.y = 44
	select.add_theme_font_size_override("font_size", 13)
	select.add_theme_color_override("font_color", Color("f5ecd5"))
	select.add_theme_stylebox_override("normal", _panel_style(Color("354d40"), Color("a5a77b"), 11, 1))
	select.add_theme_stylebox_override("hover", _panel_style(Color("49674e"), Color("efd18b"), 11, 2))
	select.add_theme_stylebox_override("pressed", _panel_style(Color("283a33"), Color("efd18b"), 11, 2))
	select.add_theme_stylebox_override("disabled", _panel_style(Color("29332f"), Color("505d55"), 11, 1))
	select.pressed.connect(_play_button_sound)
	select.pressed.connect(_launch_chapter.bind(chapter_id))
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(select)
	return card

func _open_settings() -> void:
	_show_modal("SETTINGS", "Set music and sound effects independently.")
	var stack := _page.get_meta("stack") as VBoxContainer
	_add_volume_control(stack, "Music", JourneyProgress.music_volume, JourneyProgress.set_music_volume)
	_add_volume_control(stack, "Sound Effects", JourneyProgress.sfx_volume, JourneyProgress.set_sfx_volume)
	_add_modal_close(stack)

func _add_volume_control(stack: VBoxContainer, label_text: String, current: float, setter: Callable) -> void:
	var label := Label.new()
	label.text = "%s  ·  %d%%" % [label_text.to_upper(), roundi(current * 100.0)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("e8d5a7"))
	stack.add_child(label)
	var slider := HSlider.new()
	slider.name = label_text.replace(" ", "") + "VolumeSlider"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(360, 36)
	slider.value = current
	slider.value_changed.connect(func(value: float):
		setter.call(value)
		label.text = "%s  ·  %d%%" % [label_text.to_upper(), roundi(value * 100.0)]
	)
	stack.add_child(slider)

func _play_button_sound() -> void:
	JourneyAudio.play_sfx("button_click")

func _show_modal(title_text: String, detail: String) -> void:
	if is_instance_valid(_page):
		_page.queue_free()
	_page = PanelContainer.new()
	_page.name = "MenuDialog"
	_page.anchor_left = 0.5
	_page.anchor_right = 0.5
	_page.anchor_top = 0.54
	_page.anchor_bottom = 0.54
	_page.offset_left = -280
	_page.offset_right = 280
	_page.offset_top = -250
	_page.offset_bottom = 250
	_page.add_theme_stylebox_override("panel", _panel_style(Color("11221f", 0.99), Color("d0b576"), 20, 2))
	add_child(_page)
	var stack := VBoxContainer.new()
	stack.name = "DialogContent"
	stack.add_theme_constant_override("separation", 12)
	_page.add_child(stack)
	var heading := Label.new()
	heading.text = title_text
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", Color("f3e5c0"))
	stack.add_child(heading)
	var description := Label.new()
	description.text = detail
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color("d2c8ad"))
	stack.add_child(description)
	_page.set_meta("stack", stack)

func _make_modal_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(0, 43)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("f4eddb"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("2a4138"), Color("829174"), 11, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("3c5a47"), Color("e0c17d"), 11, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("1c302a"), Color("e0c17d"), 11, 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("202c29", 0.82), Color("57635b", 0.7), 11, 1))
	button.pressed.connect(_play_button_sound)
	return button

func _add_modal_close(parent: Control) -> void:
	var close := _make_modal_button("BACK TO MAIN MENU")
	close.name = "BackButton"
	close.pressed.connect(_close_modal)
	parent.add_child(close)

func _close_modal() -> void:
	if is_instance_valid(_page):
		_page.queue_free()
	_page = null
	
func _on_exit() -> void:
	exit_requested.emit()
	JourneyProgress.save_now()
	get_tree().quit()
