extends "res://scripts/world/adventure_chapter.gd"

func _init() -> void:
	chapter_id = 4
	chapter_title = "The Secret Laboratory"
	place_name = "The sealed research station"
	intro_lines = ["The lift rises into a buried laboratory divided into sealed rooms.", "The name on the console is mine: Elias Vale. I need to know what happened here."]
	clue_specs = [
		{"id": "lab_incident_report", "title": "Incident report", "body": "PROJECT RESONANCE — Lead engineer: Elias Vale. The crystal lattice could power the valley through the winter. During the final test, Elias increased the output beyond containment while trying to stabilize the failing lattice. The resulting pulse disabled the station and erased recent memory in everyone nearby.", "position": Vector2(470, 570)},
		{"id": "lab_evacuation_log", "title": "Evacuation log", "body": "Mara's report: all residents were guided through the west service tunnel before the second surge. No one was left in the village. I sealed the lower lift and stayed behind to preserve the shutdown instructions.", "position": Vector2(1200, 570)},
		{"id": "lab_shutdown_memo", "title": "Shutdown memo", "body": "Manual interlock: ARCHIVE first, POWER second, CONTROL last. The lead operator must hold the core steady while the lattice releases its charge. —Mara", "position": Vector2(1870, 570)}
	]
	puzzle_title = "CORE INTERLOCK"
	puzzle_hint = "The shutdown memo names the room sequence. Set the three interlocks in order."
	puzzle_options = ["ARCHIVE  →  POWER  →  CONTROL", "CONTROL  →  POWER  →  ARCHIVE", "POWER  →  ARCHIVE  →  CONTROL"]
	correct_answer_index = 0
	required_item_ids = ["lab_incident_report", "lab_evacuation_log", "lab_shutdown_memo"]
	success_lines = ["The archive unlocks. The power relays fall quiet, then the core control lights turn green.", "I remember the surge now. I was trying to save the village—and Mara left one final recording for me."]
	completion_text = "The laboratory shutdown is complete. The memory archive contains a final recording and a message meant for Elias alone."
