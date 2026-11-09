extends "res://scripts/world/adventure_chapter.gd"

func _init() -> void:
	chapter_id = 3
	chapter_title = "The Hidden Cave"
	place_name = "The crystal caves"
	intro_lines = ["The well tunnel descends into a cavern lit by blue-green crystals.", "The hum sounds almost like a voice. I should search the ledges and read the old markings."]
	clue_specs = [
		{"id": "cave_miner_ledger", "title": "Miner's ledger", "body": "A water-stained ledger: 'The stream-blue crystal first, the amber flame second, and the moon-white prism last. The sealed door listens to the order.'", "position": Vector2(490, 570)},
		{"id": "cave_echo_tablet", "title": "Echo tablet", "body": "Three channels are carved into the rock. Water flows first, fire next, then moonlight. A scratched note names a research station beyond the seal.", "position": Vector2(1220, 570)},
		{"id": "cave_hidden_prism", "title": "Hidden prism cache", "body": "Behind a loose slab is a small prism. Its colors match the ledger: blue, amber, white. On the back is stamped 'E. Vale — Resonance Project.'", "position": Vector2(1940, 570), "hidden": true}
	]
	puzzle_title = "THE CRYSTAL SEAL"
	puzzle_hint = "Align the three channels in the order described by the ledger and tablet."
	puzzle_options = ["Blue  ·  Amber  ·  White", "Amber  ·  Blue  ·  White", "White  ·  Blue  ·  Amber"]
	correct_answer_index = 0
	required_item_ids = ["cave_miner_ledger", "cave_echo_tablet", "cave_hidden_prism"]
	success_lines = ["The crystals answer in sequence. Blue, amber, white—the stone door opens.", "Beyond it is a metal lift marked RESONANCE LABORATORY. Elias Vale. That name feels familiar."]
	completion_text = "The cave seal is open. An old lift connects the crystal chambers to a hidden laboratory under the hills."
