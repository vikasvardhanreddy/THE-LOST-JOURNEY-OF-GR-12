extends "res://scripts/world/adventure_chapter.gd"

func _init() -> void:
	chapter_id = 5
	chapter_title = "The Truth"
	place_name = "The memory echo"
	intro_lines = ["The archive opens onto a quiet landscape made from fragments of memory.", "Mara's voice is close now. I remember the name Elias—and the night the village disappeared."]
	clue_specs = [
		{"id": "truth_mara_recording", "title": "Mara's final recording", "body": "Elias, if you hear this, you shut down the core. The pulse took your memory, but all the villagers made it out safely. I went north with them. I will wait for you by the coast. Please don't blame yourself for choosing their lives.", "position": Vector2(520, 570)},
		{"id": "truth_shutdown_log", "title": "Final shutdown log", "body": "The last entry is in Elias's handwriting: 'Held the lever through the surge. Mara has the evacuation group. Seal the lattice. Keep them safe.' The shutdown was his choice, not an accident that left the village trapped.", "position": Vector2(1300, 570)},
		{"id": "truth_memory_locket", "title": "The memory locket", "body": "Inside is a tiny picture of Elias and Mara at the forest arch. On the back: 'When the echo ends, keep the record and let the core sleep.' The journey began with the promise he made to her.", "position": Vector2(2070, 570)}
	]
	puzzle_title = "THE LAST CHOICE"
	puzzle_hint = "The locket and log describe the safe shutdown. Choose the action that protects the living and preserves the truth."
	puzzle_options = ["Restart the core and erase the archive", "Seal the core and keep the archive", "Keep the core running and leave the memory sealed"]
	correct_answer_index = 1
	required_item_ids = ["truth_mara_recording", "truth_shutdown_log", "truth_memory_locket"]
	success_lines = ["The core falls silent. The memory record remains intact.", "I am Elias Vale. I tried to save the village, and Mara helped me finish what I started."]
	completion_text = "The truth returns: you are Elias Vale, the engineer who held the shutdown lever while Mara led the villagers to safety. The surge took your recent memory, not your life. Mara and the others survived and went north. Her last message is simple: she is waiting by the coast.\n\nAt dawn, Elias leaves the sleeping core behind and follows the road home. THE LOST JOURNEY is complete."
