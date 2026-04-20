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
# Grab the visual node for the enemy
@onready var enemy_visual = $CanvasLayer/Enemy 

# Create a list of the file paths to your new sprites.
# Note: I filled in what I could see from the screenshot. 
# Make sure to right-click your files, select "Copy Path", and paste the exact names here!
var enemy_sprites = [
	"res://sprites/Carlos.avi.webp",
	"res://sprites/Carlos_the_Stickman.webp",
	"res://sprites/GAJARDO_THE_STICKMAN_EXE_ORIGINAL_TURN_SPRITE_TRANS.webp", # Replace with exact path
	"res://sprites/GAJARDO_THE_STICKMAN_SPRITE_2_TRANS.webp"
]

func _ready():
	randomize()
	player_hp = 100
	enemy_level = 1
	spawn_enemy()
	update_ui()

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
		
	# 4. Wait a moment to build suspense! (0.8 to 1 second is usually the sweet spot)
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
	# Bij double KO geen loot, gewoon upgrade dialog
	$"CanvasLayer/Control(UI)/VBoxContainer/UpgradeDialog".popup_centered()

func win():
	var reward = 10 + enemy_level * 5
	Global.gold += reward
	result_label.text = "YOU WIN! +" + str(reward) + " gold"
	
	# Toon loot popup zodat speler kan kiezen om item op te pakken
	show_loot_dialog()

func show_loot_dialog():
	# Bouw de loot dialog tekst op
	var category = enemy_item["category"]
	var current = Global.equipped_items[category]
	
	var dialog_text = "Enemy dropped: " + enemy_item["name"] + " (+" + str(enemy_item["power_bonus"]) + " power)\n"
	
	if current != null:
		# Speler heeft al een item in dat slot
		dialog_text += "You have: " + current["name"] + " (+" + str(current["power_bonus"]) + " power)\n"
		dialog_text += "Taking this will drop your current " + category + "!"
	else:
		dialog_text += "Slot: " + category + " (currently empty)"
	
	loot_dialog.dialog_text = dialog_text
	loot_dialog.popup_centered()

func _on_loot_dialog_confirmed():
	# Speler kiest om het item op te pakken
	var dropped = Global.equip_item(enemy_item)
	if not dropped.is_empty():
		result_label.text = "Picked up " + enemy_item["name"] + "! Dropped " + dropped["name"] + "."
	else:
		result_label.text = "Picked up " + enemy_item["name"] + "!"
	
	# Ga door naar volgende enemy
	enemy_level += 1
	spawn_enemy()

func _on_loot_dialog_canceled():
	# Speler laat item liggen
	result_label.text = "Left the item on the ground. "
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
