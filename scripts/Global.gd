extends Node

var gold = 0
var item_power = 10

# Equipped items per slot - null betekent leeg
var equipped_items: Dictionary = {
	"hat": null,
	"shirt": null,
	"weapon": null,
	"boots": null,
}

# Alle beschikbare items per categorie
var item_pool = {
	"hat": [
		{ "id": "hat_basic", "name": "Worn Cap", "category": "hat", "power_bonus": 1, "texture": "res://assets/items/hat_basic.png" },
		{ "id": "hat_wizard", "name": "Wizard Hat", "category": "hat", "power_bonus": 3, "texture": "res://assets/items/hat_wizard.png" },
		{ "id": "hat_crown", "name": "Iron Crown", "category": "hat", "power_bonus": 5, "texture": "res://assets/items/hat_crown.png" },
	],
	"shirt": [
		{ "id": "shirt_rags", "name": "Rags", "category": "shirt", "power_bonus": 1, "texture": "res://assets/items/shirt_rags.png" },
		{ "id": "shirt_leather", "name": "Leather Vest", "category": "shirt", "power_bonus": 3, "texture": "res://assets/items/shirt_leather.png" },
		{ "id": "shirt_chainmail", "name": "Chainmail", "category": "shirt", "power_bonus": 5, "texture": "res://assets/items/shirt_chainmail.png" },
	],
	"weapon": [
		{ "id": "weapon_stick", "name": "Stick", "category": "weapon", "power_bonus": 2, "texture": "res://assets/items/weapon_stick.png" },
		{ "id": "weapon_sword", "name": "Iron Sword", "category": "weapon", "power_bonus": 5, "texture": "res://assets/items/weapon_sword.png" },
		{ "id": "weapon_axe", "name": "Battle Axe", "category": "weapon", "power_bonus": 8, "texture": "res://assets/items/weapon_axe.png" },
	],
	"boots": [
		{ "id": "boots_sandals", "name": "Sandals", "category": "boots", "power_bonus": 1, "texture": "res://assets/items/boots_sandals.png" },
		{ "id": "boots_leather", "name": "Leather Boots", "category": "boots", "power_bonus": 2, "texture": "res://assets/items/boots_leather.png" },
		{ "id": "boots_iron", "name": "Iron Boots", "category": "boots", "power_bonus": 4, "texture": "res://assets/items/boots_iron.png" },
	],
}

func get_random_item() -> Dictionary:
	var categories = item_pool.keys()
	var category = categories[randi() % categories.size()]
	var pool = item_pool[category]
	return pool[randi() % pool.size()].duplicate()

# Equip een item - geeft het verdrongen item terug (of {} als slot leeg was)
func equip_item(item: Dictionary) -> Dictionary:
	var category = item["category"]
	var old_item = equipped_items[category]
	equipped_items[category] = item
	recalculate_item_power()
	if old_item != null:
		return old_item
	return {}

func recalculate_item_power() -> void:
	item_power = 0
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item != null:
			item_power += item["power_bonus"]

# Verwijder een item uit een slot (bv. na steal)
func remove_item(category: String) -> void:
	equipped_items[category] = null
	recalculate_item_power()

# Geeft lijst van alle momenteel gedragen items terug
func get_owned_items() -> Array:
	var owned = []
	for slot in equipped_items:
		if equipped_items[slot] != null:
			owned.append(equipped_items[slot])
	return owned
