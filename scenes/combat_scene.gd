extends Node

var enemy_level = 1
var player_hp = 100
var enemy_hp = 50
var enemy_item: Dictionary = {}  # Het item dat de huidige enemy draagt

@onready var player_hp_bar = $CanvasLayer/PlayerHP
@onready var enemy_hp_bar = $CanvasLayer/EnemyHP
@onready var dice_label = $CanvasLayer/DiceLabel
@onready var result_label = $"CanvasLayer/Control(UI)/VBoxContainer/ResultLabel"
@onready var enemy_label = $"CanvasLayer/Control(UI)/VBoxContainer/EnemyLabel"
@onready var gold_label = $"CanvasLayer/Control(UI)/VBoxContainer/GoldLabel"
@onready var loot_dialog = $"CanvasLayer/Control(UI)/VBoxContainer/LootDialog"  # AcceptDialog of Window
@onready var inventory_list = $CanvasLayer/InventoryPanel/InventoryList
# Grab the visual node for the enemy
@onready var enemy_visual = $CanvasLayer/Enemy 
@onready var background_visual = $CanvasLayer/Background
@onready var loot_icon = $"CanvasLayer/Control(UI)/VBoxContainer/LootDialog/TextureRect"

# Create a list of the file paths to your new sprites.
var enemy_sprites = [
	"res://sprites/images/enemy-fighter-a.png", 
	"res://sprites/images/enemy-fighter-b.png", 
	"res://sprites/images/enemy-mage-a.png", 
	"res://sprites/images/enemy-mage-b.png", 
	"res://sprites/images/enemy-skeleton-a.png", 
	"res://sprites/images/enemy-skeleton-b.png"
]

func _ready():
	randomize()
	
	# --- TUTORIAL LOGICA START ---
	if SaveData.combat_tutorial_done == false:
		$Tutorial.show()
		$Tutorial.tutorial_finished.connect(_on_combat_tutorial_finished)
	else:
		$Tutorial.hide()
	# --- TUTORIAL LOGICA EIND ---
	
	player_hp = 100
	enemy_level = 1
	spawn_enemy()
	update_ui()
	update_inventory_ui()

# Deze functie wordt aangeroepen als de tutorial klaar is
func _on_combat_tutorial_finished():
	SaveData.combat_tutorial_done = true
	print("Combat tutorial voltooid en opgeslagen in SaveData.")

func spawn_enemy():
	enemy_hp = 40 + enemy_level * 10
	enemy_hp_bar.max_value = enemy_hp
	enemy_hp_bar.value = enemy_hp
	
	# Geef de enemy een random item
	enemy_item = Global.get_random_item()
	
	enemy_label.text = "Enemy Lvl " + str(enemy_level) + " [" + enemy_item["name"] + "]"
	
	var random_index = randi() % enemy_sprites.size()
	var chosen_sprite_path = enemy_sprites[random_index]
	enemy_visual.texture = load(chosen_sprite_path)
	

func update_ui():
	player_hp_bar.value = player_hp
	enemy_hp_bar.value = enemy_hp
	gold_label.text = "Gold: " + str(Global.gold)

func _on_roll_button_pressed():
	if player_hp <= 0:
		return
	
	# 1. Disable the button so they can't spam it during the animation
	$"CanvasLayer/Control(UI)/VBoxContainer/RollButton".disabled = true
	
	# 2. Player rolls and deals damage
	var roll = randi_range(1, 20)
	var final_roll = roll + Global.item_power
	dice_label.text = "🎲 " + str(roll) + " + " + str(Global.item_power) + " = " + str(final_roll)
	
	enemy_hp -= final_roll
	result_label.text = "You dealt " + str(final_roll) + " damage!"
	update_ui() # Updates enemy HP bar instantly
	
	# 3. Check if enemy died BEFORE they can counter-attack
	if enemy_hp <= 0:
		check_combat()
		$"CanvasLayer/Control(UI)/VBoxContainer/RollButton".disabled = false
		return
		
	# 4. Wait a moment to build suspense!
	await get_tree().create_timer(0.8).timeout
	
	# 5. Enemy attacks back
	var enemy_damage = randi_range(5, 15) + enemy_level
	player_hp -= enemy_damage
	result_label.text = "Enemy strikes back! Took " + str(enemy_damage) + " damage."
	update_ui() # Updates player HP bar
	
	# 6. Check final combat state and re-enable button
	check_combat()
	$"CanvasLayer/Control(UI)/VBoxContainer/RollButton".disabled = false

func check_combat():
	if enemy_hp <= 0 and player_hp <= 0:
		double_ko()
	elif enemy_hp <= 0:
		win()
	elif player_hp <= 0:
		lose()

func double_ko():
	result_label.text = "💥 BOTH DIED!"
	$"CanvasLayer/Control(UI)/VBoxContainer/UpgradeDialog".popup_centered()

func win():
	var reward = 10 + enemy_level * 5
	Global.gold += reward
	result_label.text = "YOU WIN! +" + str(reward) + " gold"
	show_loot_dialog()

func show_loot_dialog():
	var category = enemy_item["category"]
	var current = Global.equipped_items[category]

	var dialog_text = "Enemy dropped: %s (+%d Power)\n\n\n\n" % [
		enemy_item["name"],
		enemy_item["power_bonus"]
	]

	if current != null:
		dialog_text += "Equipped: %s (+%d Power)\n" % [
			current["name"],
			current["power_bonus"]
		]
		dialog_text += "Replacing it will discard your current item."
	else:
		dialog_text += "Your %s slot is empty." % category.capitalize()

	loot_icon.texture = load(enemy_item["texture"])
	loot_icon.visible = true

	loot_dialog.dialog_text = dialog_text
	loot_dialog.popup_centered()

func _on_loot_dialog_confirmed():
	var dropped = Global.equip_item(enemy_item)
	if not dropped.is_empty():
		result_label.text = "Picked up " + enemy_item["name"] + "! Dropped " + dropped["name"] + "."
	else:
		result_label.text = "Picked up " + enemy_item["name"] + "!"
		
	update_inventory_ui()
	enemy_level += 1
	spawn_enemy()

func _on_loot_dialog_canceled():
	result_label.text = "Left the item on the ground."
	enemy_level += 1
	spawn_enemy()

func lose():
	result_label.text = "YOU LOST!"
	$"CanvasLayer/Control(UI)/VBoxContainer/UpgradeDialog".popup_centered()

func reset_combat():
	player_hp = 100
	player_hp_bar.max_value = player_hp
	enemy_level = 1
	spawn_enemy()
	update_ui()

func _on_confirmation_dialog_canceled():
	reset_combat()

func _on_confirmation_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/UpgradeScene.tscn")

func update_inventory_ui():
	for child in inventory_list.get_children():
		child.queue_free()
		
	var title_label = Label.new()
	title_label.text = "--- EQUIPPED ---"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color.BLACK)
	inventory_list.add_child(title_label)
	
	for slot in Global.equipped_items.keys():
		var item = Global.equipped_items[slot]
		var slot_label = Label.new()
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if item != null:
			slot_label.text = slot.capitalize() + ": " + item["name"] + " (+" + str(item["power_bonus"]) + ")"
			slot_label.add_theme_color_override("font_color", Color.BLACK)
		else:
			slot_label.text = slot.capitalize() + ": Empty"
			slot_label.add_theme_color_override("font_color", Color.hex(0x333333)) 
			
		inventory_list.add_child(slot_label)
