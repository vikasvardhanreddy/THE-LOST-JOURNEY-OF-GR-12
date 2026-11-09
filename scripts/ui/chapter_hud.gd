extends CanvasLayer
class_name ChapterHUD

signal dialogue_finished
signal puzzle_answered(correct: bool)
signal start_requested

var _lines: Array[String] = []
var _line_index := 0
var _dialogue_open := false
var _main_menu_open := true
var _pause_open := false
var _inventory_open := false
var _root: Control
var _dialogue_box: PanelContainer
var _dialogue_label: Label
var _clue_label: Label
var _overlay: ColorRect
var _health_label: Label
var _health_bar: ProgressBar
var _coin_label: Label
var _inventory_button: Button
var _pause_button: Button
var _stats_panel: PanelContainer
var _touch_controls: Dictionary = {}
var _touch_layout_queued := false
var _chapter_number := 1
var _chapter_title := "THE AWAKENING"
var _chapter_place := "FOREST"
var _final_chapter := false
var _answer_index := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	JourneyProgress.inventory_changed.connect(refresh_inventory)
	show_main_menu()

func configure_chapter(number: int, title: String, place: String, is_final := false) -> void:
	_chapter_number = number
	_chapter_title = title
	_chapter_place = place
	_final_chapter = is_final
	var chapter_label := _root.find_child("ChapterTitle", true, false) as Label
	if chapter_label:
		chapter_label.text = "CHAPTER %d   /   %s" % [number, place.to_upper()]

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	# Compact chapter header with a small parchment icon and a pause control.
	var header := PanelContainer.new()
	header.position = Vector2(24, 20)
	header.add_theme_stylebox_override("panel", _panel_style(Color("182c2b", 0.86), Color("a2a67b", 0.7), 14, 1))
	_root.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 12)
	header.add_child(header_row)
	var chapter_mark := Label.new()
	chapter_mark.text = "✦"
	chapter_mark.add_theme_color_override("font_color", Color("e2c486"))
	header_row.add_child(chapter_mark)
	var chapter_title := Label.new()
	chapter_title.name = "ChapterTitle"
	chapter_title.text = "THE AWAKENING   /   FOREST"
	chapter_title.add_theme_font_size_override("font_size", 18)
	chapter_title.add_theme_color_override("font_color", Color("f3ead0"))
	header_row.add_child(chapter_title)
	_clue_label = Label.new()
	_clue_label.position = Vector2(28, 72)
	_clue_label.text = "CLUES   0 / 3"
	_clue_label.add_theme_font_size_override("font_size", 17)
	_clue_label.add_theme_color_override("font_color", Color("e0c68e"))
	_root.add_child(_clue_label)
	var stats := PanelContainer.new()
	_stats_panel = stats
	stats.anchor_left = 1.0
	stats.anchor_right = 1.0
	stats.offset_left = -555
	stats.offset_right = -160
	stats.position.y = 20
	stats.custom_minimum_size = Vector2(395, 48)
	stats.add_theme_stylebox_override("panel", _panel_style(Color("182c2b", 0.9), Color("a2a67b", 0.7), 14, 1))
	_root.add_child(stats)
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	stats.add_child(stats_row)
	_health_label = Label.new()
	_health_label.text = "♥ 4 / 4"
	_health_label.add_theme_font_size_override("font_size", 18)
	_health_label.add_theme_color_override("font_color", Color("ff7772"))
	stats_row.add_child(_health_label)
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(92, 14)
	_health_bar.min_value = 0
	_health_bar.max_value = 4
	_health_bar.value = 4
	_health_bar.show_percentage = false
	var health_track := StyleBoxFlat.new()
	health_track.bg_color = Color("241e21")
	health_track.set_corner_radius_all(7)
	_health_bar.add_theme_stylebox_override("background", health_track)
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color("e84b50")
	health_fill.set_corner_radius_all(7)
	_health_bar.add_theme_stylebox_override("fill", health_fill)
	stats_row.add_child(_health_bar)
	_coin_label = Label.new()
	_coin_label.text = "◉ 000"
	_coin_label.add_theme_font_size_override("font_size", 18)
	_coin_label.add_theme_color_override("font_color", Color("f5d576"))
	stats_row.add_child(_coin_label)
	_pause_button = _make_button("Ⅱ", Vector2(1, 0), Vector2(-70, 20), Vector2(52, 52))
	_pause_button.name = "PauseButton"
	_pause_button.tooltip_text = "Pause (Esc)"
	_pause_button.add_theme_font_size_override("font_size", 20)
	_pause_button.pressed.connect(show_pause_menu)
	_root.add_child(_pause_button)
	_inventory_button = _make_button("BAG  0", Vector2(1, 0), Vector2(-158, 20), Vector2(76, 56))
	_inventory_button.name = "InventoryButton"
	_inventory_button.tooltip_text = "Inventory (I / B)"
	_inventory_button.add_theme_font_size_override("font_size", 12)
	_inventory_button.pressed.connect(_toggle_inventory)
	_root.add_child(_inventory_button)
	refresh_inventory()
	# Keyboard hint stays away from the touch targets; mobile controls are labeled.
	var control_hint := Label.new()
	control_hint.text = "A / D Move    Shift Run    Space Jump    F Attack    E Interact    I / B Inventory    Esc Pause"
	control_hint.anchor_top = 1.0
	control_hint.anchor_bottom = 1.0
	control_hint.anchor_left = 0.5
	control_hint.anchor_right = 0.5
	control_hint.offset_left = -250
	control_hint.offset_top = -192
	control_hint.offset_right = 250
	control_hint.offset_bottom = -170
	control_hint.add_theme_font_size_override("font_size", 15)
	control_hint.add_theme_color_override("font_color", Color("d5d1b8", 0.82))
	_root.add_child(control_hint)
	_add_action_touch("◀", "move_left")
	_add_action_touch("▶", "move_right")
	_add_action_touch("HIT", "attack")
	_add_action_touch("RUN", "run")
	_add_action_touch("JUMP", "jump")
	_add_action_touch("USE", "interact")
	# Dialogue panel: speaker token, story text, and a clear continue prompt.
	_dialogue_box = PanelContainer.new()
	_dialogue_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_box.offset_left = 150
	_dialogue_box.offset_right = -150
	_dialogue_box.offset_top = -170
	_dialogue_box.offset_bottom = -20
	_dialogue_box.add_theme_stylebox_override("panel", _panel_style(Color("172522", 0.96), Color("c2ab78"), 18, 2))
	_dialogue_box.visible = false
	_root.add_child(_dialogue_box)
	var dialogue_row := HBoxContainer.new()
	dialogue_row.add_theme_constant_override("separation", 20)
	_dialogue_box.add_child(dialogue_row)
	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(68, 68)
	portrait.add_theme_stylebox_override("panel", _panel_style(Color("405b50"), Color("c2ab78", 0.75), 34, 1))
	dialogue_row.add_child(portrait)
	var portrait_mark := Label.new()
	portrait_mark.text = "✦"
	portrait_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_mark.add_theme_font_size_override("font_size", 30)
	portrait_mark.add_theme_color_override("font_color", Color("ead19b"))
	portrait.add_child(portrait_mark)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 8)
	dialogue_row.add_child(text_column)
	var speaker := Label.new()
	speaker.text = "THE TRAVELLER"
	speaker.add_theme_font_size_override("font_size", 14)
	speaker.add_theme_color_override("font_color", Color("d8bd82"))
	text_column.add_child(speaker)
	_dialogue_label = Label.new()
	_dialogue_label.add_theme_font_size_override("font_size", 21)
	_dialogue_label.add_theme_color_override("font_color", Color("f4efdf"))
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(_dialogue_label)
	var continue_hint := Label.new()
	continue_hint.text = "E / ENTER     CONTINUE"
	continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_hint.add_theme_font_size_override("font_size", 13)
	continue_hint.add_theme_color_override("font_color", Color("cbbb93", 0.85))
	text_column.add_child(continue_hint)
	_overlay = ColorRect.new()
	# Modal buttons must remain interactive while gameplay is paused.
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.color = Color("0b1717", 0.78)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_overlay)
	_root.resized.connect(_queue_touch_layout)
	_queue_touch_layout()

func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color("07100f", 0.35)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style

func _make_button(text_value: String, anchor: Vector2, offset: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.anchor_left = anchor.x
	button.anchor_right = anchor.x
	button.anchor_top = anchor.y
	button.anchor_bottom = anchor.y
	button.offset_left = offset.x
	button.offset_top = offset.y
	button.offset_right = offset.x + size.x
	button.offset_bottom = offset.y + size.y
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("f3edda"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("263c36", 0.85), Color("9a9f78", 0.75), 16, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("405c4e", 0.96), Color("d2bb82"), 16, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("182a28", 0.98), Color("d2bb82"), 16, 2))
	button.pressed.connect(_play_button_sound)
	return button

func _add_action_touch(text_value: String, action: StringName) -> void:
	# TouchScreenButton tracks independent finger IDs for simultaneous actions.
	var touch := TouchScreenButton.new()
	touch.name = "Touch_%s" % action
	touch.action = action
	touch.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	var hit_shape := CircleShape2D.new()
	touch.shape = hit_shape
	touch.pressed.connect(_play_button_sound)
	touch.pressed.connect(_on_touch_pressed.bind(action))
	touch.released.connect(_on_touch_released.bind(action))
	_root.add_child(touch)
	var visual := PanelContainer.new()
	visual.name = "TouchVisual_%s" % action
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_theme_stylebox_override("panel", _panel_style(Color("263c36", 0.76), Color("c3ad7c", 0.9), 22, 2))
	_root.add_child(visual)
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 18 if text_value.length() < 4 else 15)
	label.add_theme_color_override("font_color", Color("f3edda"))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.add_child(label)
	_touch_controls[action] = {"touch": touch, "visual": visual, "label": label, "shape": hit_shape}
	_queue_touch_layout()

func _queue_touch_layout() -> void:
	if not _touch_layout_queued:
		_touch_layout_queued = true
		call_deferred("_layout_touch_controls")

func _layout_touch_controls() -> void:
	_touch_layout_queued = false
	if not is_instance_valid(_root) or _root.size.x <= 0.0 or _root.size.y <= 0.0:
		return
	var viewport_size := _root.size
	var diameter := clampf(viewport_size.y * 0.12, 64.0, 88.0)
	var gap := clampf(diameter * 0.14, 9.0, 14.0)
	var margin := clampf(diameter * 0.30, 18.0, 28.0)
	var bottom_y := viewport_size.y - margin - diameter * 0.5
	var positions := {
		&"move_left": Vector2(margin + diameter * 0.5, bottom_y),
		&"move_right": Vector2(margin + diameter * 1.5 + gap, bottom_y)
	}
	var right_actions: Array[StringName] = [&"run", &"attack", &"jump", &"interact"]
	for index in right_actions.size():
		var from_right := margin + diameter * 0.5 + float(right_actions.size() - 1 - index) * (diameter + gap)
		positions[right_actions[index]] = Vector2(viewport_size.x - from_right, bottom_y)
	for action in _touch_controls:
		var control: Dictionary = _touch_controls[action]
		var center: Vector2 = positions[action]
		(control["touch"] as TouchScreenButton).position = center
		(control["visual"] as Control).position = center - Vector2.ONE * diameter * 0.5
		(control["visual"] as Control).size = Vector2.ONE * diameter
		(control["shape"] as CircleShape2D).radius = diameter * 0.5
	if _inventory_button:
		_inventory_button.offset_left = -158
		_inventory_button.offset_right = -82
	if _pause_button:
		_pause_button.offset_left = -70
		_pause_button.offset_right = -18
	if _stats_panel:
		_stats_panel.visible = viewport_size.x >= 900.0
	var keyboard_hint := _root.find_child("KeyboardControlHint", true, false) as Label
	if keyboard_hint:
		keyboard_hint.visible = not OS.has_feature("mobile")
	_update_touch_visibility()

func _on_touch_pressed(action: StringName) -> void:
	var visual := _touch_controls[action]["visual"] as PanelContainer
	visual.add_theme_stylebox_override("panel", _panel_style(Color("526847", 0.92), Color("f0d38d"), 22, 3))

func _on_touch_released(action: StringName) -> void:
	var visual := _touch_controls[action]["visual"] as PanelContainer
	visual.add_theme_stylebox_override("panel", _panel_style(Color("263c36", 0.76), Color("c3ad7c", 0.9), 22, 2))

func _update_touch_visibility() -> void:
	if not is_instance_valid(_overlay):
		return
	var controls_visible := not _main_menu_open and not _dialogue_open and not _pause_open and not _inventory_open and not _overlay.visible
	for action in _touch_controls:
		var control: Dictionary = _touch_controls[action]
		(control["touch"] as TouchScreenButton).visible = controls_visible
		(control["visual"] as Control).visible = controls_visible
		if not controls_visible:
			if InputMap.has_action(action):
				Input.action_release(action)
			_on_touch_released(action)

func update_clue_count(count: int) -> void:
	_clue_label.text = "CLUES   %d / 3" % count

func update_stats(health: int, max_health: int, coins: int) -> void:
	if _health_label:
		_health_label.text = "♥".repeat(health) + "♡".repeat(max_health - health)
	if _health_bar:
		_health_bar.max_value = max_health
		_health_bar.value = health
	if _coin_label:
		_coin_label.text = "◉ %03d" % coins

func show_main_menu() -> void:
	_main_menu_open = true
	_pause_open = false
	_overlay.visible = true
	var box := _build_modal("THE LOST JOURNEY", "CHAPTER %d  ·  %s\n%s" % [_chapter_number, _chapter_title.to_upper(), _chapter_place])
	var start := _modal_button("Continue journey")
	start.pressed.connect(_on_start_pressed)
	box.add_child(start)
	var footer := Label.new()
	footer.text = "A story of clues, memory, and the path home"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("c5bea6", 0.82))
	box.add_child(footer)
	_update_touch_visibility()

func show_pause_menu() -> void:
	if _main_menu_open or _dialogue_open or _pause_open:
		return
	_pause_open = true
	_overlay.visible = true
	get_tree().paused = true
	var box := _build_modal("PAUSED", "The forest can wait. Take a breath.")
	var resume := _modal_button("Continue exploring")
	resume.pressed.connect(_resume_game)
	box.add_child(resume)
	var settings := _modal_button("Audio settings")
	settings.pressed.connect(_open_pause_audio_settings)
	box.add_child(settings)
	var return_button := _modal_button("Return to title")
	return_button.pressed.connect(_return_to_chapter_title)
	box.add_child(return_button)
	_update_touch_visibility()

func _toggle_inventory() -> void:
	if _main_menu_open or _dialogue_open or _pause_open:
		return
	if _inventory_open:
		_close_inventory()
	else:
		_open_inventory()

func _open_inventory() -> void:
	_inventory_open = true
	get_tree().paused = true
	_overlay.visible = true
	for child in _overlay.get_children():
		child.queue_free()
	var panel := PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_top = -270
	panel.offset_right = 310
	panel.offset_bottom = 270
	panel.add_theme_stylebox_override("panel", _panel_style(Color("172624", 0.98), Color("c9ad75"), 20, 2))
	_overlay.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var heading := Label.new()
	heading.name = "InventoryHeading"
	heading.text = "FIELD INVENTORY"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("f3e6c5"))
	content.add_child(heading)
	var count := Label.new()
	count.name = "InventoryItemCount"
	count.text = "%d COLLECTED CLUE%s" % [JourneyProgress.inventory.get_item_count(), "" if JourneyProgress.inventory.get_item_count() == 1 else "S"]
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 14)
	count.add_theme_color_override("font_color", Color("d4bd8a"))
	content.add_child(count)
	var scroll := ScrollContainer.new()
	scroll.name = "InventoryScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 325)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var entries := VBoxContainer.new()
	entries.name = "InventoryEntries"
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 8)
	scroll.add_child(entries)
	var items := JourneyProgress.inventory.get_all_items()
	if items.is_empty():
		var empty := Label.new()
		empty.name = "InventoryEmptyMessage"
		empty.text = "No clues collected yet.\nExplore nearby and tap USE to inspect objects."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(0, 100)
		empty.add_theme_color_override("font_color", Color("d2c8ad"))
		entries.add_child(empty)
	else:
		for item_id in items:
			entries.add_child(_make_inventory_entry(String(item_id), items[item_id]))
	var close := _modal_button("CLOSE   ·   I / B / ESC")
	close.name = "InventoryCloseButton"
	close.custom_minimum_size = Vector2(300, 54)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(_close_inventory)
	content.add_child(close)
	_inventory_button.text = "BAG  %d" % JourneyProgress.inventory.get_item_count()
	_update_touch_visibility()

func _make_inventory_entry(item_id: String, item: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.name = "InventoryItem_" + item_id
	row.custom_minimum_size = Vector2(0, 84)
	row.add_theme_stylebox_override("panel", _panel_style(Color("263a34", 0.96), Color("7f8a6d", 0.8), 12, 1))
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	row.add_child(layout)
	var icon := PanelContainer.new()
	icon.name = "ItemIcon"
	icon.custom_minimum_size = Vector2(60, 60)
	icon.add_theme_stylebox_override("panel", _panel_style(Color("665a41"), Color("d0b77f"), 11, 1))
	layout.add_child(icon)
	var glyph := Label.new()
	var icon_key := String(item.get("icon", "clue"))
	glyph.text = "✉" if icon_key == "document" else "◇" if icon_key == "crystal" else "✦"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size", 28)
	glyph.add_theme_color_override("font_color", Color("f2d89a"))
	icon.add_child(glyph)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 4)
	layout.add_child(text)
	var title := Label.new()
	title.name = "ItemName"
	title.text = String(item.get("title", item_id))
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("f0dfb5"))
	text.add_child(title)
	var description := Label.new()
	description.name = "ItemDescription"
	description.text = String(item.get("description", "A clue from the journey."))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.add_theme_font_size_override("font_size", 14)
	description.add_theme_color_override("font_color", Color("d4d0bf"))
	text.add_child(description)
	return row

func refresh_inventory() -> void:
	if is_instance_valid(_inventory_button):
		_inventory_button.text = "BAG  %d" % JourneyProgress.inventory.get_item_count()
	if _inventory_open:
		_open_inventory()

func _close_inventory() -> void:
	_inventory_open = false
	_overlay.visible = false
	get_tree().paused = false
	_update_touch_visibility()

func _build_modal(title_text: String, subtitle_text: String) -> VBoxContainer:
	for child in _overlay.get_children():
		child.queue_free()
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_top = -210
	panel.offset_right = 260
	panel.offset_bottom = 210
	panel.add_theme_stylebox_override("panel", _panel_style(Color("172624", 0.97), Color("bda875"), 24, 2))
	_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var sigil := Label.new()
	sigil.text = "✦"
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.add_theme_font_size_override("font_size", 32)
	sigil.add_theme_color_override("font_color", Color("dec58e"))
	box.add_child(sigil)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("f3ead2"))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("d1c7aa"))
	box.add_child(subtitle)
	return box

func _modal_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(300, 50)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("f4efdf"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("405a4c"), Color("a7a77b"), 13, 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("567158"), Color("e0c686"), 13, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("2a403b"), Color("e0c686"), 13, 2))
	button.pressed.connect(_play_button_sound)
	return button

func _play_button_sound() -> void:
	JourneyAudio.play_sfx("button_click")

func _open_pause_audio_settings() -> void:
	var box := _build_modal("AUDIO SETTINGS", "Music and sound effects")
	_add_audio_slider(box, "Music", JourneyProgress.music_volume, JourneyProgress.set_music_volume)
	_add_audio_slider(box, "Sound Effects", JourneyProgress.sfx_volume, JourneyProgress.set_sfx_volume)
	var back := _modal_button("Back to pause menu")
	back.pressed.connect(func():
		_pause_open = false
		show_pause_menu()
	)
	box.add_child(back)

func _add_audio_slider(parent: VBoxContainer, title: String, initial: float, setter: Callable) -> void:
	var label := Label.new()
	label.text = "%s  ·  %d%%" % [title, roundi(initial * 100.0)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("e8d5a7"))
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.custom_minimum_size = Vector2(300, 28)
	slider.value_changed.connect(func(value: float):
		setter.call(value)
		label.text = "%s  ·  %d%%" % [title, roundi(value * 100.0)]
	)
	parent.add_child(slider)

func _on_start_pressed() -> void:
	_overlay.visible = false
	_main_menu_open = false
	_update_touch_visibility()
	start_requested.emit()

func begin_chapter_intro() -> void:
	_on_start_pressed()

func _resume_game() -> void:
	_pause_open = false
	_overlay.visible = false
	get_tree().paused = false
	_update_touch_visibility()

func _return_to_title() -> void:
	get_tree().paused = false
	JourneyProgress.skip_chapter_title = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _return_to_chapter_title() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func show_dialogue(lines: Array[String]) -> void:
	_lines = lines
	_line_index = 0
	_dialogue_open = true
	_dialogue_box.visible = true
	_update_touch_visibility()
	_show_current_line()

func show_note(title: String, body: String) -> void:
	show_dialogue(["%s: %s" % [title, body], "The marks form a pattern. I should remember it."])

func show_objective(text_value: String) -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(340, 95)
	panel.custom_minimum_size = Vector2(600, 48)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(Color("182c2b", 0.92), Color("e2c486", 0.9), 14, 1))
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("f3dfab"))
	panel.add_child(label)
	_root.add_child(panel)
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.6)
	tween.tween_callback(panel.queue_free)

func _show_current_line() -> void:
	_dialogue_label.text = _lines[_line_index]

func show_puzzle(title_text: String, hint_text: String, options: Array[String], correct_index: int) -> void:
	_overlay.visible = true
	_update_touch_visibility()
	_answer_index = correct_index
	var box := _build_modal(title_text, hint_text)
	for index in options.size():
		var option := options[index]
		var button := _modal_button(option)
		button.pressed.connect(_on_answer_pressed.bind(index == _answer_index))
		box.add_child(button)

func _on_answer_pressed(correct: bool) -> void:
	_overlay.visible = false
	_update_touch_visibility()
	puzzle_answered.emit(correct)

func show_completion(ending_text: String) -> void:
	if _final_chapter:
		begin_finale_transition()
		return
	_overlay.visible = true
	_update_touch_visibility()
	var box := _build_modal("THE END" if _final_chapter else "CHAPTER %d COMPLETE" % _chapter_number, ending_text)
	var again := _modal_button("Replay ending" if _final_chapter else "Continue to Chapter %d" % (_chapter_number + 1))
	again.pressed.connect(func():
		get_tree().paused = false
		if _final_chapter:
			get_tree().reload_current_scene()
		else:
			JourneyProgress.skip_chapter_title = true
			get_tree().change_scene_to_file(JourneyProgress.chapter_scene(_chapter_number + 1))
	)
	box.add_child(again)

func show_game_over() -> void:
	get_tree().paused = false
	_overlay.visible = true
	var box := _build_modal("JOURNEY PAUSED", "Elias needs a moment to recover.")
	var retry := _modal_button("Try this journey again")
	retry.pressed.connect(func(): get_tree().reload_current_scene())
	box.add_child(retry)
	var menu := _modal_button("Main Menu")
	menu.pressed.connect(_return_to_title)
	box.add_child(menu)

func begin_finale_transition() -> void:
	if _final_chapter == false:
		return
	var fade := ColorRect.new()
	fade.name = "FinalPortalFade"
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.75)
	tween.tween_interval(0.28)
	tween.tween_callback(_build_finale_screen)
	tween.tween_property(fade, "color:a", 0.0, 0.7)
	tween.tween_callback(fade.queue_free)

func _build_finale_screen() -> void:
	_overlay.visible = true
	_overlay.color = Color(0, 0, 0, 0)
	for child in _overlay.get_children():
		child.queue_free()
	var background := TextureRect.new()
	background.name = "EndingReferenceArtwork"
	background.texture = load("res://assets/backgrounds/ending/game_complete_reference.png") as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(background)
	var breathe := create_tween().set_loops()
	background.pivot_offset = Vector2(640, 360)
	breathe.tween_property(background, "scale", Vector2(1.006, 1.006), 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(background, "scale", Vector2.ONE, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var ambience := Control.new()
	ambience.set_script(load("res://scripts/ui/ending_ambience.gd"))
	ambience.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ambience.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(ambience)
	var menu_button := _ending_hotspot("Main Menu", 0.806)
	menu_button.pressed.connect(_return_to_title)
	_overlay.add_child(menu_button)
	var replay_button := _ending_hotspot("Play Again", 0.918)
	replay_button.pressed.connect(_play_again)
	_overlay.add_child(replay_button)
	for button in [menu_button, replay_button]:
		_overlay.move_child(button, _overlay.get_child_count() - 1)

func _ending_hotspot(label: String, center_y: float) -> Button:
	var button := Button.new()
	button.name = label.replace(" ", "")
	button.text = ""
	button.tooltip_text = label
	button.focus_mode = Control.FOCUS_ALL
	button.anchor_left = 0.77
	button.anchor_right = 0.77
	button.anchor_top = center_y
	button.anchor_bottom = center_y
	button.offset_left = -180
	button.offset_right = 180
	button.offset_top = -34
	button.offset_bottom = 34
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("ffdc6b", 0.12)
	hover.set_border_width_all(3)
	hover.border_color = Color("fff0a0", 0.9)
	hover.set_corner_radius_all(18)
	button.add_theme_stylebox_override("hover", hover)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color("ffdc6b", 0.1)
	focus.set_border_width_all(3)
	focus.border_color = Color("fff0a0", 0.9)
	focus.set_corner_radius_all(18)
	button.add_theme_stylebox_override("focus", focus)
	return button

func _play_again() -> void:
	get_tree().paused = false
	JourneyProgress.reset_progress()
	JourneyProgress.skip_chapter_title = true
	get_tree().change_scene_to_file(JourneyProgress.chapter_scene(1))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if _inventory_open and (event.keycode in [KEY_I, KEY_B, KEY_ESCAPE] or event.is_action_pressed("ui_cancel")):
		_close_inventory()
		get_viewport().set_input_as_handled()
	elif not _main_menu_open and not _dialogue_open and not _pause_open and (event.keycode in [KEY_I, KEY_B]):
		_toggle_inventory()
		get_viewport().set_input_as_handled()
	elif _main_menu_open and event.is_action_pressed("ui_accept"):
		_on_start_pressed()
		get_viewport().set_input_as_handled()
	elif _dialogue_open and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		_line_index += 1
		if _line_index >= _lines.size():
			_dialogue_open = false
			_dialogue_box.visible = false
			dialogue_finished.emit()
		else:
			_show_current_line()
		get_viewport().set_input_as_handled()
	elif not _main_menu_open and not _dialogue_open and (event.keycode == KEY_ESCAPE or event.is_action_pressed("pause_game")):
		if _pause_open:
			_resume_game()
		else:
			show_pause_menu()
		get_viewport().set_input_as_handled()
