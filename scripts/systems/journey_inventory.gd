extends RefCounted
class_name JourneyInventory

var _items: Dictionary = {}

func add_item(item_id: String, title: String, description: String, icon_key := "") -> bool:
	if item_id.is_empty() or _items.has(item_id):
		return false
	_items[item_id] = {
		"title": title,
		"description": description,
		"icon": icon_key if not icon_key.is_empty() else _icon_for_item(item_id)
	}
	return true

func _icon_for_item(item_id: String) -> String:
	var key := item_id.to_lower()
	if "letter" in key or "page" in key or "note" in key or "report" in key or "log" in key or "memo" in key or "ledger" in key:
		return "document"
	if "crystal" in key or "prism" in key or "shard" in key or "memory" in key:
		return "crystal"
	return "clue"

func has_item(item_id: String) -> bool:
	return _items.has(item_id)

func get_item(item_id: String) -> Dictionary:
	return _items.get(item_id, {})

func get_item_count() -> int:
	return _items.size()

func get_all_items() -> Dictionary:
	return _items.duplicate(true)

func load_items(items: Dictionary) -> void:
	_items = items.duplicate(true)

