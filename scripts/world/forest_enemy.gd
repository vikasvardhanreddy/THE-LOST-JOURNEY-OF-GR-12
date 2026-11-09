extends CharacterBody2D
class_name ForestEnemy

@export var patrol_distance := 72.0
@export var patrol_speed := 52.0
var _origin_x := 0.0
var _direction := 1.0
var _time := 0.0
var _defeated := false

func _ready() -> void:
	_origin_x = global_position.x
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 12
	capsule.height = 34
	collision.shape = capsule
	collision.position = Vector2(0, -17)
	add_child(collision)

func _physics_process(delta: float) -> void:
	if _defeated:
		return
	_time += delta
	if not is_on_floor():
		velocity.y += 1500.0 * delta
	if global_position.x > _origin_x + patrol_distance:
		_direction = -1.0
	elif global_position.x < _origin_x - patrol_distance:
		_direction = 1.0
	velocity.x = _direction * patrol_speed
	move_and_slide()
	queue_redraw()

func take_hit() -> void:
	if _defeated:
		return
	_defeated = true
	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player) and player is ForestPlayer and player.global_position.distance_to(global_position) < 100.0:
			player.add_coin(3)
	queue_free()

func _draw() -> void:
	var bob := sin(_time * 4.2) * 2.2
	var shell := Color("3b4948")
	draw_circle(Vector2(0, -18 + bob), 16, Color("162120", 0.35))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, -7 + bob), Vector2(-16, -20 + bob), Vector2(-10, -34 + bob),
		Vector2(0, -40 + bob), Vector2(12, -33 + bob), Vector2(15, -18 + bob),
		Vector2(10, -7 + bob)
	]), shell)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -30 + bob), Vector2(-6, -42 + bob), Vector2(-1, -32 + bob)]), Color("61756a"))
	draw_colored_polygon(PackedVector2Array([Vector2(4, -33 + bob), Vector2(13, -42 + bob), Vector2(11, -29 + bob)]), Color("61756a"))
	draw_circle(Vector2(6, -25 + bob), 2.0, Color("eb9b64"))
	draw_circle(Vector2(6, -25 + bob), 0.9, Color("fff0c2"))
	draw_line(Vector2(-8, -8), Vector2(-11, 0), Color("252d2d"), 4.0, true)
	draw_line(Vector2(7, -8), Vector2(10, 0), Color("252d2d"), 4.0, true)
