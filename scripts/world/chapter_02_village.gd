extends "res://scripts/world/adventure_chapter.gd"

func _init() -> void:
	chapter_id = 2
	chapter_title = "The Forgotten Village"
	place_name = "The empty village"
	intro_lines = ["The stone arch opens into a silent village.", "The letter in the forest was addressed to Elias. I need to find who left it."]
	clue_specs = [
		{"id": "village_mara_letter", "title": "Mara's letter", "body": "Elias, if you have found this, the arch led you home. The village is empty because the blue lights beneath the old well frightened everyone away. Do not follow them alone. The bell pattern is still the key: ring twice, pause once, ring three times. Find the lower passage. —Mara", "position": Vector2(520, 570)},
		{"id": "village_bell_rubbing", "title": "Bell tower rubbing", "body": "A charcoal rubbing shows two short strokes, one long pause, and three short strokes. The old well is marked beneath them.", "position": Vector2(1280, 570)},
		{"id": "village_well_chart", "title": "Well keeper's chart", "body": "The chart maps a dry maintenance shaft below the village well. It ends at a sealed passage leading into the hills.", "position": Vector2(1950, 570)}
	]
	puzzle_title = "THE VILLAGE BELL"
	puzzle_hint = "Mara's letter gives the bell sequence: two, pause, then three. Which pattern matches?"
	puzzle_options = ["2  ·  1  ·  3", "2  ·  3  ·  1", "3  ·  1  ·  2"]
	correct_answer_index = 0
	required_item_ids = ["village_mara_letter", "village_bell_rubbing", "village_well_chart"]
	success_lines = ["The bell rings twice, rests, then rings three times. A stone hatch slides open beneath the well.", "Mara's warning was right. There is a passage into the hills—and a blue light below."]
	completion_text = "Inside the dry well is a hidden tunnel. The way leads down toward the caves, where the blue lights begin."
