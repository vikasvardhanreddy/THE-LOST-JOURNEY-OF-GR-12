extends SceneTree

const SOURCE := "res://assets/characters/character_design_reference.png"
const OUTPUT := "res://assets/characters/sprites/"

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null or source.is_empty():
		printerr("Could not load reference sheet")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var regions := {
		"idle": Rect2i(660, 582, 105, 190),
		"walk_1": Rect2i(779, 582, 104, 190),
		"walk_2": Rect2i(893, 582, 104, 190),
		"walk_3": Rect2i(1003, 582, 105, 190),
		"run_1": Rect2i(1114, 582, 105, 190),
		"run_2": Rect2i(1244, 582, 110, 190),
		"jump": Rect2i(655, 830, 165, 180),
		"attack": Rect2i(822, 830, 210, 180),
		"hurt": Rect2i(1063, 830, 155, 180),
		"die": Rect2i(1220, 919, 156, 87)
	}
	print("Reference image size: ", source.get_size())
	for key in regions:
		var region: Rect2i = regions[key]
		if region.end.x > source.get_width() or region.end.y > source.get_height():
			printerr("Crop outside image: ", key)
			continue
		var frame := source.get_region(region)
		frame.convert(Image.FORMAT_RGBA8)
		_remove_blue_panel(frame)
		var used := frame.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0:
			printerr("Empty crop after transparency: ", key)
			continue
		var trimmed := frame.get_region(used)
		var cell := Image.create(192, 192, false, Image.FORMAT_RGBA8)
		var destination := Vector2i((192 - trimmed.get_width()) / 2, 188 - trimmed.get_height())
		cell.blit_rect(trimmed, Rect2i(Vector2i.ZERO, trimmed.get_size()), destination)
		var output_path: String = OUTPUT + key + ".png"
		var result := cell.save_png(ProjectSettings.globalize_path(output_path))
		print(key, " crop=", used.size, " cell=", cell.get_size(), " saved=", result)
	quit()

func _remove_blue_panel(frame: Image) -> void:
	var width := frame.get_width()
	var height := frame.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in width:
		_enqueue_if_panel(frame, x, 0, visited, queue)
		_enqueue_if_panel(frame, x, height - 1, visited, queue)
	for y in height:
		_enqueue_if_panel(frame, 0, y, visited, queue)
		_enqueue_if_panel(frame, width - 1, y, visited, queue)
	var cursor := 0
	while cursor < queue.size():
		var point: Vector2i = queue[cursor]
		cursor += 1
		frame.set_pixel(point.x, point.y, Color(0, 0, 0, 0))
		for neighbor in [Vector2i(point.x - 1, point.y), Vector2i(point.x + 1, point.y), Vector2i(point.x, point.y - 1), Vector2i(point.x, point.y + 1)]:
			if neighbor.x < 0 or neighbor.x >= width or neighbor.y < 0 or neighbor.y >= height:
				continue
			_enqueue_if_panel(frame, neighbor.x, neighbor.y, visited, queue)

func _enqueue_if_panel(frame: Image, x: int, y: int, visited: PackedByteArray, queue: Array[Vector2i]) -> void:
	var index := y * frame.get_width() + x
	if visited[index] != 0:
		return
	var color := frame.get_pixel(x, y)
	# Only the blue-tinted panel connected to the crop edges is removed.
	if color.b <= color.r * 1.2 or color.b <= color.g * 1.08:
		return
	visited[index] = 1
	queue.append(Vector2i(x, y))
