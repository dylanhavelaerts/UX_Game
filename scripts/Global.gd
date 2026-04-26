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
		{
			"id": "hat_cap",
			"name": "Leather Cap",
			"category": "hat",
			"power_bonus": 1,
			"texture": "res://sprites/images/item-hat-a.png"
		},
		{
			"id": "hat_helmet",
			"name": "Iron Helmet",
			"category": "hat",
			"power_bonus": 4,
			"texture": "res://sprites/images/item-helmet-a.png"
		},
		{
			"id": "hat_great_helmet",
			"name": "Knight Helmet",
			"category": "hat",
			"power_bonus": 7,
			"texture": "res://sprites/images/item-helmet-b.png"
		}
	],

	"shirt": [
		{
			"id": "shirt_cape",
			"name": "Traveler's Cape",
			"category": "shirt",
			"power_bonus": 2,
			"texture": "res://sprites/images/item-cape-a.png"
		},
		{
			"id": "shirt_guardian_cape",
			"name": "Guardian Cape",
			"category": "shirt",
			"power_bonus": 5,
			"texture": "res://sprites/images/item-cape-b.png"
		}
	],

	"weapon": [
		{
			"id": "weapon_sword",
			"name": "Iron Sword",
			"category": "weapon",
			"power_bonus": 4,
			"texture": "res://sprites/images/item-sword-a.png"
		},
		{
			"id": "weapon_magic_sword",
			"name": "Enchanted Blade",
			"category": "weapon",
			"power_bonus": 7,
			"texture": "res://sprites/images/item-sword-b.png"
		},
		{
			"id": "weapon_shield",
			"name": "Knight Shield",
			"category": "weapon",
			"power_bonus": 5,
			"texture": "res://sprites/images/item-shield-a.png"
		},
		{
			"id": "weapon_tower_shield",
			"name": "Tower Shield",
			"category": "weapon",
			"power_bonus": 8,
			"texture": "res://sprites/images/item-shield-b.png"
		}
	],

	"boots": [
		{
			"id": "boots_leather",
			"name": "Leather Boots",
			"category": "boots",
			"power_bonus": 1,
			"texture": "res://sprites/images/item-boots-a.png"
		},
		{
			"id": "boots_steel",
			"name": "Steel Boots",
			"category": "boots",
			"power_bonus": 4,
			"texture": "res://sprites/images/item-boots-b.png"
		}
	]
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
