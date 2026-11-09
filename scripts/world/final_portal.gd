extends Node2D
class_name FinalPortal

var is_open := false
var _time := 0.0
var _activated := false

func _ready() -> void:
	add_to_group("interactable")

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _activated and _time >= 1.2:
		_activated = false
		get_parent().start_final_cinematic()

func set_open(value: bool) -> void:
	is_open = value
	queue_redraw()

func interact(player: ForestPlayer) -> void:
	if not is_open:
		get_parent().show_dialogue(["The portal is dark. I need to solve the final memory puzzle first."])
		return
	if _activated:
		return
	_activated = true
	_time = 0.0
	JourneyAudio.play_sfx("door")
	player.controls_enabled = false
	queue_redraw()

func _draw() -> void:
	var pulse := (sin(_time * 3.2) + 1.0) * 0.5
	var glow := 0.24 + pulse * 0.18
	if _activated:
		glow = minf(1.0, glow + _time * 0.55)
	draw_circle(Vector2(0, -80), 100, Color("ffbd62", glow * 0.12))
	draw_circle(Vector2(0, -80), 68, Color("6fd4dd", glow * 0.16))
	draw_rect(Rect2(-56, -131, 112, 131), Color("122936", 0.9))
	draw_arc(Vector2(0, -130), 58, PI, TAU, 32, Color("f0b765"), 12, true)
	draw_line(Vector2(-58, -130), Vector2(-58, 0), Color("827257"), 13, true)
	draw_line(Vector2(58, -130), Vector2(58, 0), Color("827257"), 13, true)
	draw_arc(Vector2(0, -130), 48, PI, TAU, 32, Color("ffdc81", glow + 0.15), 5, true)
	var portal_color := Color("f9ca77", glow) if is_open else Color("63757a", 0.7)
	draw_rect(Rect2(-42, -118, 84, 118), portal_color)
	draw_rect(Rect2(-34, -110, 68, 108), Color("6fd4dd", glow * 0.55))
	for index in 4:
		var angle := _time * 0.8 + float(index) * TAU / 4.0
		var point := Vector2(cos(angle) * 30.0, -66.0 + sin(angle) * 40.0)
		draw_circle(point, 2.2, Color("fff2bd", glow))
	if is_open:
		var font := ThemeDB.fallback_font
		if font:
			draw_string(font, Vector2(-46, -158), "E  ENTER", HORIZONTAL_ALIGNMENT_CENTER, 92, 14, Color("f2dfad"))
