extends Node2D

@export_range(2, 5) var chapter_style := 2
@export var world_width := 2900.0

func _draw() -> void:
	var palettes := [
		[Color("1c3030"), Color("435347"), Color("b6a46b")],
		[Color("222c32"), Color("4c4540"), Color("bd9b68")],
		[Color("101f2c"), Color("263e4b"), Color("75d6cc")],
		[Color("20252a"), Color("4b4234"), Color("e3b96f")],
		[Color("171e35"), Color("415366"), Color("c4d8ab")]
	]
	var palette: Array = palettes[clampi(chapter_style - 1, 0, palettes.size() - 1)]
	for band in 15:
		var ratio := band / 15.0
		draw_rect(Rect2(Vector2(-300, -250 + band * 62), Vector2(world_width, 63)), palette[0].lerp(palette[1], ratio))
	match chapter_style:
		1: _draw_forest_ruins(palette[2])
		2: _draw_village(palette[2])
		3: _draw_cave(palette[2])
		4: _draw_laboratory(palette[2])
		5: _draw_memory_realm(palette[2])
	_draw_foreground_haze(palette[2])

func _draw_forest_ruins(light: Color) -> void:
	# A distant ruin and floating crags carry the fantasy journey beyond the trees.
	draw_colored_polygon(PackedVector2Array([Vector2(570, 470), Vector2(970, 314), Vector2(1220, 365), Vector2(1500, 258), Vector2(1870, 408), Vector2(2250, 302), Vector2(2600, 465)]), Color("607765", 0.38))
	draw_colored_polygon(PackedVector2Array([Vector2(1040, 302), Vector2(1210, 266), Vector2(1360, 288), Vector2(1312, 328), Vector2(1084, 332)]), Color("435a53", 0.8))
	# An old castle keeps its broken towers above the ridge line.
	var stone := Color("465753", 0.75)
	var shade := Color("2b4140", 0.82)
	draw_rect(Rect2(Vector2(1570, 176), Vector2(250, 168)), stone)
	draw_rect(Rect2(Vector2(1600, 136), Vector2(52, 207)), shade)
	draw_rect(Rect2(Vector2(1722, 97), Vector2(64, 246)), stone)
	draw_rect(Rect2(Vector2(1839, 153), Vector2(50, 190)), shade)
	for tower in [Vector2(1590, 136), Vector2(1716, 96), Vector2(1833, 153)]:
		var roof := PackedVector2Array([
			tower + Vector2(-8, 4), tower + Vector2(24, -45),
			tower + Vector2(56, 4), tower + Vector2(48, 12), tower + Vector2(0, 12)
		])
		draw_colored_polygon(roof, Color("65736b", 0.84))
	for row in 3:
		for window in 7:
			var window_at := Vector2(1592 + window * 32, 208 + row * 38)
			draw_rect(Rect2(window_at, Vector2(7, 15)), Color("e2c17b", 0.62) if (window + row) % 4 == 0 else Color("273536", 0.7))
	draw_arc(Vector2(1760, 340), 42, PI, TAU, 18, Color("c1ad7c", 0.68), 6, true)
	# Small sky islands repeat the destination motif seen in the character sheet.
	for island in [Vector2(780, 215), Vector2(2180, 185)]:
		var island_shape := PackedVector2Array([
			island + Vector2(-56, 0), island + Vector2(-27, -17), island + Vector2(12, -14),
			island + Vector2(54, -2), island + Vector2(25, 18), island + Vector2(5, 48), island + Vector2(-13, 19)
		])
		draw_colored_polygon(island_shape, Color("40534b", 0.82))
		draw_line(island + Vector2(-42, -4), island + Vector2(44, -4), light.darkened(0.2), 3.0, true)

func _draw_village(light: Color) -> void:
	# Empty roofs and timber frames form the recognizable abandoned settlement skyline.
	for i in 6:
		var x := 90.0 + i * 470.0
		var width := 260.0 + float(i % 2) * 75.0
		var roof_y := 230.0 + float((i * 41) % 85)
		draw_colored_polygon(PackedVector2Array([Vector2(x, 530), Vector2(x + 12, roof_y + 45), Vector2(x + width * 0.5, roof_y - 25), Vector2(x + width, roof_y + 45), Vector2(x + width + 14, 530)]), Color("312f2d"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 18, roof_y + 48), Vector2(x + width * 0.5, roof_y - 37), Vector2(x + width + 18, roof_y + 48), Vector2(x + width + 5, roof_y + 63), Vector2(x + width * 0.5, roof_y - 17), Vector2(x - 5, roof_y + 63)]), Color("57453b"))
		for window in 2:
			var wx := x + 45 + window * (width - 90)
			draw_rect(Rect2(Vector2(wx, roof_y + 115), Vector2(34, 54)), Color("171e20"))
			draw_line(Vector2(wx + 17, roof_y + 115), Vector2(wx + 17, roof_y + 169), Color("8f7858", 0.55), 2.0)
		# A few broken fence lengths and bent posts.
		if i % 2 == 0:
			var fence_x := x + width + 30
			for post in 4:
				draw_line(Vector2(fence_x + post * 24, 570), Vector2(fence_x + post * 24 - 2, 520 + (post % 2) * 7), Color("79634b"), 4.0, true)
			draw_line(Vector2(fence_x, 536), Vector2(fence_x + 70, 542), Color("927451"), 3.0, true)
	# Silent well at the center of the village.
	draw_rect(Rect2(Vector2(1230, 528), Vector2(146, 18)), Color("6d6250"))
	draw_rect(Rect2(Vector2(1240, 546), Vector2(126, 46)), Color("484a45"))
	draw_arc(Vector2(1303, 541), 57.0, PI, TAU, 24, Color("99917a"), 8.0, true)
	draw_line(Vector2(1250, 521), Vector2(1266, 445), Color("5c4938"), 8.0, true)
	draw_line(Vector2(1356, 521), Vector2(1340, 445), Color("5c4938"), 8.0, true)
	draw_line(Vector2(1266, 445), Vector2(1340, 445), Color("806849"), 7.0, true)

func _draw_cave(glow: Color) -> void:
	# Craggy ceiling teeth and a mineral seam frame the underground path.
	for i in 24:
		var x := -30.0 + i * 126.0
		var tip_y := 130.0 + float((i * 79) % 180)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 42, -180), Vector2(x + 48, -180), Vector2(x + 26, tip_y), Vector2(x + 5, tip_y + 25), Vector2(x - 10, tip_y - 14)]), Color("14232a"))
	for crystal in 13:
		var x := 90.0 + crystal * 218.0
		var height := 38.0 + float((crystal * 47) % 60)
		var tint := Color("51b5aa", 0.6) if crystal % 3 == 0 else Color("648eaa", 0.58)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 10, 576), Vector2(x - 6, 576 - height * 0.72), Vector2(x, 576 - height), Vector2(x + 11, 576), Vector2(x + 2, 565)]), tint)
		draw_line(Vector2(x, 570 - height * 0.8), Vector2(x + 1, 570), Color("b1ece0", 0.6), 2.0, true)
		draw_circle(Vector2(x, 565 - height * 0.65), height * 0.36, Color("67d7c6", 0.035))
	# Broken ledges suggest a deeper route below the traversable tunnel.
	for i in 7:
		var x := i * 430.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 590), Vector2(x + 105, 575), Vector2(x + 192, 586), Vector2(x + 222, 620), Vector2(x, 620)]), Color("303f42"))

func _draw_laboratory(light: Color) -> void:
	# Four rooms with separate wall panels, door gaps, and old equipment windows.
	var room_titles := ["DECONTAMINATION", "ARCHIVE", "RESONANCE", "CORE CONTROL"]
	for room in 4:
		var left := 70.0 + room * 690.0
		var tint := Color("30373a") if room % 2 == 0 else Color("373735")
		draw_rect(Rect2(Vector2(left, 115), Vector2(650, 420)), tint)
		draw_rect(Rect2(Vector2(left + 20, 134), Vector2(610, 14)), Color("747165", 0.65))
		draw_rect(Rect2(Vector2(left + 22, 176), Vector2(208, 146)), Color("18252a"))
		draw_rect(Rect2(Vector2(left + 30, 184), Vector2(192, 130)), Color("56716b", 0.35))
		for mullion in 4:
			draw_line(Vector2(left + 30 + mullion * 48, 184), Vector2(left + 30 + mullion * 48, 314), Color("96a194", 0.44), 2.0)
		draw_rect(Rect2(Vector2(left + 20, 345), Vector2(235, 52)), Color("20282a"))
		for led in 5:
			draw_circle(Vector2(left + 48 + led * 38, 369), 4.0, light if led == room % 5 else Color("718274"))
		draw_rect(Rect2(Vector2(left + 470, 182), Vector2(120, 340)), Color("212627"))
		draw_rect(Rect2(Vector2(left + 486, 198), Vector2(88, 238)), Color("49514d"))
		for stripe in 3:
			draw_line(Vector2(left + 492, 222 + stripe * 70), Vector2(left + 567, 222 + stripe * 70), Color("b28a4d", 0.65), 3.0)
		draw_rect(Rect2(Vector2(left + 410, 130), Vector2(180, 30)), Color("554833"))
		draw_string(ThemeDB.fallback_font, Vector2(left + 420, 151), room_titles[room], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d8c593"))
	# Heavy partitions separate the rooms; the openings are left at floor level.
	for wall in 3:
		var x := 750.0 + wall * 690.0
		draw_rect(Rect2(Vector2(x, 110), Vector2(22, 366)), Color("171e20"))
		draw_rect(Rect2(Vector2(x - 5, 476), Vector2(32, 104)), Color("846745"))
	# Amber emergency lamps remain lit over the power corridor.
	for lamp in 12:
		var x := 125.0 + lamp * 214.0
		draw_circle(Vector2(x, 100), 10.0, Color("e5a44a", 0.12))
		draw_circle(Vector2(x, 100), 3.5, Color("e8c47a", 0.82))

func _draw_memory_realm(light: Color) -> void:
	# A quiet, impossible landscape formed from overlapping memory arches.
	for arch in 7:
		var x := 60.0 + arch * 460.0
		var height := 260.0 + float((arch * 67) % 115)
		draw_arc(Vector2(x, 570), height, PI, TAU, 36, Color("a7bac1", 0.14), 24.0, true)
		draw_colored_polygon(PackedVector2Array([Vector2(x - height + 12, 570), Vector2(x - height + 36, 570), Vector2(x - height + 36, 300), Vector2(x - height + 12, 300)]), Color("6c888b", 0.18))
	for star in 70:
		var x := float((star * 173) % int(world_width))
		var y := 60.0 + float((star * 67) % 390)
		var radius := 1.0 + float(star % 3) * 0.5
		draw_circle(Vector2(x, y), radius, Color("e4e9cf", 0.55))
	draw_circle(Vector2(1440, 195), 92.0, Color("d2dcae", 0.09))
	draw_circle(Vector2(1440, 195), 48.0, Color("e4e4ba", 0.48))
	# A thin reflective path leads toward the final memory console.
	draw_colored_polygon(PackedVector2Array([Vector2(1060, 620), Vector2(1250, 470), Vector2(1600, 470), Vector2(1800, 620)]), Color("9eb8aa", 0.15))

func _draw_foreground_haze(light: Color) -> void:
	for i in 11:
		var x := -100.0 + i * 290.0
		draw_circle(Vector2(x, 590 + (i % 3) * 22), 95.0, Color(light, 0.025))
