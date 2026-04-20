extends Node

var enemy_level = 1
var player_hp = 100
var enemy_hp = 50
var enemy_item: Dictionary = {}

var HitmarkScene = preload("res://scenes/Hitmark.tscn")

@onready var player_hp_bar = $CanvasLayer/PlayerHP
@onready var enemy_hp_bar = $CanvasLayer/EnemyHP
@onready var dice_label = $CanvasLayer/DiceLabel
@onready var result_label = $"CanvasLayer/Control(UI)/VBoxContainer/ResultLabel"
@onready var enemy_label = $"CanvasLayer/Control(UI)/VBoxContainer/EnemyLabel"
@onready var gold_label = $"CanvasLayer/Control(UI)/VBoxContainer/GoldLabel"
@onready var roll_button = $"CanvasLayer/Control(UI)/VBoxContainer/RollButton"
@onready var loot_dialog = $"CanvasLayer/Control(UI)/VBoxContainer/LootDialog"
@onready var upgrade_dialog = $"CanvasLayer/Control(UI)/VBoxContainer/UpgradeDialog"

@onready var enemy_node = $CanvasLayer/Enemy
@onready var player_node = $CanvasLayer/Player

func _ready():
	randomize()
	start_new_run()

# -------------------------
# CORE FLOW
# -------------------------

func start_new_run():
	clear_hitmarks()
	player_hp = 100
	enemy_level = 1
	spawn_enemy()
	update_ui()

func spawn_enemy():
	enemy_hp = 40 + enemy_level * 10
	
	enemy_hp_bar.max_value = enemy_hp
	enemy_hp_bar.value = enemy_hp
	
	enemy_item = Global.get_random_item()
	enemy_label.text = "Enemy Lvl " + str(enemy_level) + " [" + enemy_item["name"] + "]"

func update_ui():
	player_hp_bar.value = player_hp
	enemy_hp_bar.value = enemy_hp
	gold_label.text = "Gold: " + str(Global.gold)

# -------------------------
# COMBAT
# -------------------------

func _on_roll_button_pressed():
	if player_hp <= 0:
		return
	
	clear_hitmarks()
	roll_button.disabled = true
	
	var roll = randi_range(1, 20)
	var final_roll = roll + Global.item_power
	var is_crit = roll == 20
	
	if is_crit:
		final_roll *= 2
	
	await roll_dice_visual(roll, final_roll, is_crit)
	
	enemy_hp -= final_roll
	
	if is_crit:
		spawn_hitmark("CRIT! " + str(final_roll), enemy_node.global_position, Color.YELLOW, true)
	else:
		spawn_hitmark("-" + str(final_roll), enemy_node.global_position, Color.RED)
	
	result_label.text = "You dealt " + str(final_roll) + " damage!"
	update_ui()
	
	if enemy_hp <= 0:
		resolve_combat()
		roll_button.disabled = false
		return
	
	await get_tree().create_timer(0.6).timeout
	
	var enemy_damage = randi_range(5, 15) + enemy_level
	player_hp -= enemy_damage
	
	spawn_hitmark("-" + str(enemy_damage), player_node.global_position, Color.ORANGE)
	
	result_label.text = "Enemy hits for " + str(enemy_damage)
	update_ui()
	
	resolve_combat()
	roll_button.disabled = false

# -------------------------
# COMBAT RESOLUTION
# -------------------------

func resolve_combat():
	if enemy_hp <= 0 and player_hp <= 0:
		double_ko()
	elif enemy_hp <= 0:
		win()
	elif player_hp <= 0:
		lose()

func win():
	var reward = 10 + enemy_level * 5
	Global.gold += reward
	
	result_label.text = "YOU WIN! +" + str(reward) + " gold"
	show_loot_dialog()

func lose():
	result_label.text = "YOU LOST!"
	upgrade_dialog.popup_centered()

func double_ko():
	result_label.text = "💥 BOTH DIED!"
	upgrade_dialog.popup_centered()

# -------------------------
# LOOT
# -------------------------

func show_loot_dialog():
	var category = enemy_item["category"]
	var current = Global.equipped_items[category]
	
	var text = "Enemy dropped: " + enemy_item["name"] + " (+" + str(enemy_item["power_bonus"]) + ")\n"
	
	if current != null:
		text += "You have: " + current["name"] + " (+" + str(current["power_bonus"]) + ")\nSwap?"
	else:
		text += "Slot empty (" + category + ")"
	
	loot_dialog.dialog_text = text
	loot_dialog.popup_centered()

func _on_loot_dialog_confirmed():
	var dropped = Global.equip_item(enemy_item)
	
	if not dropped.is_empty():
		result_label.text = "Equipped " + enemy_item["name"] + ", dropped " + dropped["name"]
	else:
		result_label.text = "Equipped " + enemy_item["name"]
	
	enemy_item = {}
	next_enemy()

func _on_loot_dialog_canceled():
	result_label.text = "Ignored item"
	clear_hitmarks()
	next_enemy()

func next_enemy():
	clear_hitmarks()
	enemy_level += 1
	spawn_enemy()
	update_ui()

# -------------------------
# RESET / UPGRADE
# -------------------------

func reset_combat():
	start_new_run()

func _on_confirmation_dialog_canceled():
	reset_combat()

func _on_confirmation_dialog_confirmed():
	get_tree().change_scene_to_file("res://scenes/UpgradeScene.tscn")

# -------------------------
# VISUALS
# -------------------------

func spawn_hitmark(text, pos, color, is_big = false):
	var hitmark = HitmarkScene.instantiate()
	
	hitmark.text = text
	hitmark.modulate = color
	
	hitmark.position = pos + Vector2(
		randf_range(150, 260),
		randf_range(60, 140)
	)
	
	hitmark.scale = Vector2(3,3) if is_big else Vector2(2,2)
	
	hitmark.add_to_group("hitmarks")
	$CanvasLayer.add_child(hitmark)

func clear_hitmarks():
	for h in get_tree().get_nodes_in_group("hitmarks"):
		h.queue_free()

# -------------------------
# DICE
# -------------------------

func roll_dice_visual(roll, final_roll, is_crit):
	for i in range(8):
		dice_label.text = "🎲 " + str(randi_range(1, 20))
		await get_tree().create_timer(0.05).timeout
	
	if is_crit:
		dice_label.text = "🎲 CRIT! " + str(final_roll)
	else:
		dice_label.text = "🎲 " + str(roll) + " + " + str(Global.item_power) + " = " + str(final_roll)
