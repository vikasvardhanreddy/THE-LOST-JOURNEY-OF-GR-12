extends CharacterBody2D
class_name ForestPlayer

signal clue_count_changed(count: int)
signal stats_changed(health: int, max_health: int, coins: int)
signal died

const SPEED := 280.0
const RUN_MULTIPLIER := 1.55
const JUMP_VELOCITY := -560.0
const GRAVITY := 1500.0
const SPRITE_CELL := Vector2i(192, 192)
const SPRITE_SCALE := 0.4
const FRAME_PATHS := {
	"idle": ["idle"],
	"walk": ["walk_1", "walk_2", "walk_3"],
	"run": ["run_1", "run_2"],
	"jump": ["jump"],
	"attack": ["run_1", "attack", "run_2"],
	"hurt": ["hurt"],
	"die": ["die"]
}

@export var max_health := 4
var health := 4
var clues_found := 0
var controls_enabled := true
var coins := 0
var is_dead := false
var _facing := 1.0
var _idle_time := 0.0
var _attack_time := 0.0
var _hurt_time := 0.0
var _invulnerability_time := 0.0
var _contact_cooldown := 0.0
var _death_time := 0.0
var _active_animation := ""
var _sprite: AnimatedSprite2D
var _attack_hit_targets: Array[int] = []
var _checkpoint_timer := 0.0
var _footstep_timer := 0.0

func _ready() -> void:
	add_to_group("players")
	max_health = JourneyProgress.player_max_health
	health = clampi(JourneyProgress.player_health, 1, max_health)
	coins = JourneyProgress.coins
	_register_action("move_left", [KEY_A, KEY_LEFT])
	_register_action("move_right", [KEY_D, KEY_RIGHT])
	_register_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_register_action("interact", [KEY_E, KEY_ENTER])
	_register_action("run", [KEY_SHIFT])
	_register_action("attack", [KEY_F, KEY_J])
	_register_action("pause_game", [KEY_ESCAPE])
	_register_action("inventory", [KEY_I, KEY_B])
	_create_animated_sprite()
	_emit_stats()

func _register_action(action: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _create_animated_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "HeroSprite"
	_sprite.position = Vector2(0, -37)
	_sprite.scale = Vector2.ONE * SPRITE_SCALE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in FRAME_PATHS:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, animation_name in ["idle", "walk", "run"])
		frames.set_animation_speed(animation_name, 9.0 if animation_name == "walk" else 12.0 if animation_name in ["run", "attack"] else 1.0)
		for frame_name in FRAME_PATHS[animation_name]:
			var texture := load("res://assets/characters/sprites/%s.png" % frame_name) as Texture2D
			if texture:
				frames.add_frame(animation_name, texture)
	_sprite.sprite_frames = frames
	_sprite.animation = "idle"
	_sprite.play()
	add_child(_sprite)

func _physics_process(delta: float) -> void:
	if controls_enabled and not is_dead:
		_checkpoint_timer += delta
		if _checkpoint_timer >= 5.0:
			_checkpoint_timer = 0.0
			JourneyProgress.set_player_checkpoint(JourneyProgress.current_chapter, position)
	if is_dead:
		_death_time += delta
		if _death_time >= 1.5:
			is_dead = false
			_death_time = 0.0
			died.emit()
		return
	_attack_time = maxf(0.0, _attack_time - delta)
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_invulnerability_time = maxf(0.0, _invulnerability_time - delta)
	_contact_cooldown = maxf(0.0, _contact_cooldown - delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	var axis := Input.get_axis("move_left", "move_right") if controls_enabled else 0.0
	if controls_enabled:
		var sprinting := Input.is_action_pressed("run") and absf(axis) > 0.01
		velocity.x = axis * SPEED * (RUN_MULTIPLIER if sprinting else 1.0)
		if axis != 0.0:
			_facing = signf(axis)
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		if Input.is_action_just_pressed("attack"):
			_start_attack()
		if Input.is_action_just_pressed("interact"):
			_interact_nearby()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 5.0 * delta)
	move_and_slide()
	if controls_enabled and is_on_floor() and absf(velocity.x) > 20.0:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			JourneyAudio.play_sfx("footstep", 0.48)
			_footstep_timer = 0.38 if absf(velocity.x) <= SPEED * 1.1 else 0.27
	else:
		_footstep_timer = minf(_footstep_timer, 0.08)
	if controls_enabled:
		_collect_nearby_coins()
		_check_enemy_contact()
	_idle_time += delta
	_update_animation()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		JourneyProgress.set_player_checkpoint(JourneyProgress.current_chapter, position)

func _update_animation() -> void:
	if not _sprite:
		return
	var animation := "idle"
	if is_dead:
		animation = "die"
	elif _hurt_time > 0.0:
		animation = "hurt"
	elif _attack_time > 0.0:
		animation = "attack"
	elif not is_on_floor():
		animation = "jump"
	elif absf(velocity.x) > SPEED * 1.1:
		animation = "run"
	elif absf(velocity.x) > 10.0:
		animation = "walk"
	if animation != _active_animation:
		_active_animation = animation
		_sprite.play(animation)
	_sprite.flip_h = _facing < 0.0
	_sprite.modulate = Color("ff7777") if animation == "hurt" and int(_idle_time * 20.0) % 2 == 0 else Color.WHITE
	_sprite.position.y = -37.0 + (sin(_idle_time * 2.6) * 1.2 if animation == "idle" else 0.0)
	if animation == "die":
		_sprite.modulate.a = clampf(1.0 - _death_time * 0.22, 0.62, 1.0)
	else:
		_sprite.modulate.a = 1.0

func _start_attack() -> void:
	if _attack_time > 0.08 or _hurt_time > 0.0:
		return
	_attack_time = 0.32
	_attack_hit_targets.clear()
	_update_animation()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() <= 82.0 and signf(offset.x) == _facing:
			if enemy.has_method("take_hit"):
				enemy.take_hit()
			_attack_hit_targets.append(enemy.get_instance_id())

func take_damage(amount: int, from_position: Vector2) -> void:
	if is_dead or _invulnerability_time > 0.0:
		return
	health = maxi(0, health - amount)
	_invulnerability_time = 0.9
	_hurt_time = 0.28
	velocity = Vector2(-signf(global_position.x - from_position.x) * 210.0, -180.0)
	_emit_stats()
	if health == 0:
		is_dead = true
		controls_enabled = false
		_death_time = 0.0
		_active_animation = ""
		_update_animation()
	else:
		_update_animation()

func restore_health(amount: int) -> void:
	health = mini(max_health, health + amount)
	_emit_stats()

func _collect_nearby_coins() -> void:
	for coin in get_tree().get_nodes_in_group("coins"):
		if is_instance_valid(coin) and coin is Node2D and global_position.distance_to(coin.global_position) < 25.0:
			if coin.has_method("collect"):
				coin.collect(self)

func _check_enemy_contact() -> void:
	if _contact_cooldown > 0.0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy is Node2D and global_position.distance_to(enemy.global_position) < 31.0:
			_contact_cooldown = 0.45
			take_damage(1, enemy.global_position)
			return

func add_coin(amount := 1) -> void:
	coins += amount
	JourneyProgress.add_coins(amount)
	_emit_stats()

func _emit_stats() -> void:
	stats_changed.emit(health, max_health, coins)

func _interact_nearby() -> void:
	var nearest: Node2D
	var nearest_distance := 88.0
	for item in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(item) or not item is Node2D:
			continue
		var distance := global_position.distance_to(item.global_position)
		if distance < nearest_distance:
			nearest = item
			nearest_distance = distance
	if nearest and nearest.has_method("interact"):
		JourneyAudio.play_sfx("interaction", 0.65)
		nearest.interact(self)

func add_clue() -> void:
	clues_found += 1
	clue_count_changed.emit(clues_found)

func _draw() -> void:
	if _attack_time > 0.0:
		var progress := 1.0 - _attack_time / 0.32
		var start_angle := -0.9 + progress * 0.25
		var finish_angle := 1.0 - progress * 0.25
		draw_arc(Vector2(24.0 * _facing, -35), 31.0, start_angle, finish_angle, 16, Color("b7efff", 0.92), 4.0, true)
