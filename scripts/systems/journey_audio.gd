extends Node
## Persistent audio routing and chapter music for the whole game.

const MUSIC_PATHS := {
	0: "res://assets/audio/music/menu_theme.wav",
	1: "res://assets/audio/music/chapter_01_forest.wav",
	2: "res://assets/audio/music/chapter_02_village.wav",
	3: "res://assets/audio/music/chapter_03_cave.wav",
	4: "res://assets/audio/music/chapter_04_laboratory.wav",
	5: "res://assets/audio/music/chapter_05_truth.wav"
}
const SFX_PATHS := {
	"footstep": "res://assets/audio/sfx/footstep.wav",
	"button_click": "res://assets/audio/sfx/button_click.wav",
	"item_pickup": "res://assets/audio/sfx/item_pickup.wav",
	"puzzle_complete": "res://assets/audio/sfx/puzzle_complete.wav",
	"door": "res://assets/audio/sfx/door.wav",
	"interaction": "res://assets/audio/sfx/interaction.wav"
}

var music_volume := 0.65
var sfx_volume := 0.9
var _music_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _active_track := -1
var _crossfade: Tween
var _sfx_cursor := 0
var _sounds: Dictionary = {}

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % i
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_music_players.append(player)
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)
	for key in SFX_PATHS:
		_sounds[key] = load(SFX_PATHS[key])
	_apply_levels()
	play_menu_music()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus_name)
	AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")

func _apply_levels() -> void:
	for pair in [["Music", music_volume], ["SFX", sfx_volume]]:
		var bus := AudioServer.get_bus_index(pair[0])
		if bus >= 0:
			var level: float = pair[1]
			AudioServer.set_bus_mute(bus, level <= 0.001)
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(level, 0.001)))

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_levels()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_levels()

func play_menu_music() -> void:
	_play_music(0)

func play_chapter_music(chapter_id: int) -> void:
	if chapter_id >= 1 and chapter_id <= 5:
		_play_music(chapter_id)

func _play_music(track_id: int) -> void:
	if _active_track == track_id and _music_players[_active_music].playing:
		return
	var resource := load(MUSIC_PATHS[track_id]) as AudioStreamWAV
	if resource == null:
		push_warning("Missing background music for track %d" % track_id)
		return
	resource.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var next_index := 1 - _active_music
	var next_player := _music_players[next_index]
	next_player.stop()
	next_player.stream = resource
	next_player.volume_db = -36.0
	next_player.play()
	if _crossfade and _crossfade.is_running():
		_crossfade.kill()
	var old_player := _music_players[_active_music]
	_crossfade = create_tween().set_parallel(true)
	_crossfade.tween_property(next_player, "volume_db", 0.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if old_player.playing:
		_crossfade.tween_property(old_player, "volume_db", -60.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_crossfade.chain().tween_callback(old_player.stop)
	_active_music = next_index
	_active_track = track_id

func play_sfx(key: String, volume_scale := 1.0) -> void:
	if not _sounds.has(key):
		return
	var player := _sfx_players[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_players.size()
	player.stream = _sounds[key]
	player.volume_db = linear_to_db(maxf(clampf(volume_scale, 0.0, 1.0), 0.001))
	player.play()
