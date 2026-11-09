extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in [&"move_left", &"move_right", &"jump", &"interact", &"run", &"attack"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var hud: Node = (load("res://scenes/ui/chapter_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud.begin_chapter_intro()
	await process_frame
	var left := hud.find_child("Touch_move_left", true, false) as TouchScreenButton
	var right := hud.find_child("Touch_move_right", true, false) as TouchScreenButton
	var jump := hud.find_child("Touch_jump", true, false) as TouchScreenButton
	var interact := hud.find_child("Touch_interact", true, false) as TouchScreenButton
	var run := hud.find_child("Touch_run", true, false) as TouchScreenButton
	var attack := hud.find_child("Touch_attack", true, false) as TouchScreenButton
	if left == null or right == null or jump == null or interact == null or run == null or attack == null:
		push_error("A required mobile touch target was not created")
		quit(1)
		return
	var viewport_size := get_root().get_viewport().get_visible_rect().size
	var window_size := Vector2(get_root().get_window().size)
	var input_scale := window_size / viewport_size
	var left_point := (left.get_global_transform_with_canvas() * Vector2.ZERO) * input_scale
	var jump_point := (jump.get_global_transform_with_canvas() * Vector2.ZERO) * input_scale
	_parse_touch(left_point, 0, true)
	_parse_touch(jump_point, 1, true)
	await process_frame
	if not Input.is_action_pressed("move_left") or not Input.is_action_pressed("jump"):
		push_error("Simultaneous left movement and jump touch was not received")
		quit(1)
		return
	_parse_touch(left_point, 0, false)
	await process_frame
	if Input.is_action_pressed("move_left") or not Input.is_action_pressed("jump"):
		push_error("Releasing one finger incorrectly released the other action")
		quit(1)
		return
	_parse_touch(jump_point, 1, false)
	var right_point := (right.get_global_transform_with_canvas() * Vector2.ZERO) * input_scale
	var interact_point := (interact.get_global_transform_with_canvas() * Vector2.ZERO) * input_scale
	_parse_touch(right_point, 2, true)
	_parse_touch(interact_point, 3, true)
	await process_frame
	if not Input.is_action_pressed("move_right") or not Input.is_action_pressed("interact"):
		push_error("Right movement and interact touch targets did not register")
		quit(1)
		return
	_parse_touch(right_point, 2, false)
	_parse_touch(interact_point, 3, false)
	var run_point := (run.get_global_transform_with_canvas() * Vector2.ZERO) * input_scale
	var attack_point := (attack.get_global_transform_with_canvas() * Vector2.ZERO) * input_scale
	_parse_touch(run_point, 6, true)
	_parse_touch(attack_point, 7, true)
	await process_frame
	if not Input.is_action_pressed("run") or not Input.is_action_pressed("attack"):
		push_error("Run and attack touch controls did not register simultaneously")
		quit(1)
		return
	_parse_touch(run_point, 6, false)
	_parse_touch(attack_point, 7, false)
	var inventory := hud.find_child("InventoryButton", true, false) as Button
	var inventory_point := (inventory.get_global_transform_with_canvas() * (inventory.size * 0.5)) * input_scale
	_parse_touch(inventory_point, 4, true)
	await process_frame
	_parse_touch(inventory_point, 4, false)
	await process_frame
	if not hud._inventory_open:
		push_error("Inventory button did not open the inventory panel")
		quit(1)
		return
	var close_inventory := hud.find_child("InventoryCloseButton", true, false) as Button
	await process_frame
	await process_frame
	var close_point := (close_inventory.get_global_transform_with_canvas() * (close_inventory.size * 0.5)) * input_scale
	_parse_touch(close_point, 5, true)
	await process_frame
	_parse_touch(close_point, 5, false)
	await process_frame
	if hud._inventory_open:
		push_error("Inventory close touch did not close the inventory panel")
		quit(1)
		return
	var root_control := hud._root as Control
	root_control.size = Vector2(900, 540)
	hud._layout_touch_controls()
	for action in [&"move_left", &"move_right", &"jump", &"interact"]:
		var touch: TouchScreenButton = hud._touch_controls[action]["touch"]
		if touch.position.x < 32 or touch.position.x > 868 or touch.position.y < 32 or touch.position.y > 508:
			push_error("Responsive touch layout placed %s outside its screen margins" % action)
			quit(1)
			return
	var player_script := load("res://scripts/player/forest_player.gd") as GDScript
	for action in [&"move_left", &"move_right", &"jump", &"interact", &"run", &"attack"]:
		InputMap.erase_action(action)
	var player: Node = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	root.add_child(player)
	await process_frame
	var keyboard_jump := InputMap.action_get_events("jump")
	if keyboard_jump.is_empty() or player_script == null:
		push_error("Desktop keyboard bindings were not registered")
		quit(1)
		return
	print("Mobile controls smoke test passed: movement, run, attack, jump, interact, inventory open/close, responsive layout, simultaneous touch, and keyboard bindings.")
	hud.queue_free()
	player.queue_free()
	await process_frame
	quit(0)

func _parse_touch(point: Vector2, finger: int, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)
