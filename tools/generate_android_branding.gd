extends SceneTree

const SOURCE := "res://assets/branding/official_logo.png"
const OUTPUT := "res://assets/branding/android"

func _initialize() -> void:
	var logo := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if logo.is_empty():
		push_error("Unable to load the supplied THE LOST JOURNEY logo: " + SOURCE)
		quit(1)
		return
	logo.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var classic := logo.duplicate()
	classic.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	classic.save_png(OUTPUT + "/launcher_main_192.png")
	_create_adaptive_background()
	_create_adaptive_foreground(logo)
	_create_monochrome_compass()
	_create_splash(logo)
	_create_system_branding(logo)
	print("Generated Android branding from supplied logo (%dx%d)." % [logo.get_width(), logo.get_height()])
	quit(0)

func _create_adaptive_background() -> void:
	var image := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	for y in 432:
		var blend := float(y) / 431.0
		var color := Color("54287d").lerp(Color("f58a43"), clampf(blend * 1.5, 0.0, 1.0))
		if blend > 0.66:
			color = Color("f58a43").lerp(Color("ffcc57"), (blend - 0.66) / 0.34)
		for x in 432:
			image.set_pixel(x, y, color)
	image.save_png(OUTPUT + "/adaptive_background_432.png")

func _create_adaptive_foreground(source: Image) -> void:
	# Android's adaptive-icon safe zone is a centered 264 px circle on a 432 px canvas.
	# Crop only the decorative outer corners; the complete source logo remains on the title screen.
	var image := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var artwork := source.duplicate()
	artwork.resize(300, 300, Image.INTERPOLATE_LANCZOS)
	var center := Vector2(216, 216)
	var safe_radius_squared := 132.0 * 132.0
	for y in 432:
		for x in 432:
			if Vector2(x + 0.5, y + 0.5).distance_squared_to(center) <= safe_radius_squared:
				var local_x := x - 66
				var local_y := y - 66
				if local_x >= 0 and local_x < 300 and local_y >= 0 and local_y < 300:
					image.set_pixel(x, y, artwork.get_pixel(local_x, local_y))
	image.save_png(OUTPUT + "/adaptive_foreground_432.png")

func _create_monochrome_compass() -> void:
	var image := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var points := PackedVector2Array()
	for index in 16:
		var angle := -PI / 2.0 + float(index) * PI / 8.0
		var radius := 116.0 if index % 2 == 0 else 27.0
		points.append(Vector2(216, 216) + Vector2(cos(angle), sin(angle)) * radius)
	for y in range(100, 333):
		for x in range(100, 333):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), points):
				image.set_pixel(x, y, Color.WHITE)
	image.save_png(OUTPUT + "/adaptive_monochrome_432.png")

func _create_splash(source: Image) -> void:
	var image := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	for y in 720:
		var blend := float(y) / 719.0
		var color := Color("261943").lerp(Color("49306d"), blend)
		for x in 1280:
			image.set_pixel(x, y, color)
	var logo := source.duplicate()
	logo.resize(500, 500, Image.INTERPOLATE_LANCZOS)
	image.blit_rect(logo, Rect2i(Vector2i.ZERO, Vector2i(500, 500)), Vector2i(390, 110))
	image.save_png("res://assets/branding/splash_logo.png")

func _create_system_branding(source: Image) -> void:
	var image := Image.create(600, 180, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var logo := source.duplicate()
	logo.resize(170, 170, Image.INTERPOLATE_LANCZOS)
	image.blit_rect(logo, Rect2i(Vector2i.ZERO, Vector2i(170, 170)), Vector2i(215, 5))
	image.save_png(OUTPUT + "/splash_branding.png")
