extends Node

var enemy_level = 1

var player_hp = 100
var enemy_hp = 50

@onready var player_hp_bar = $CanvasLayer/PlayerHP
@onready var enemy_hp_bar = $CanvasLayer/EnemyHP
@onready var dice_label = $CanvasLayer/DiceLabel
@onready var result_label = $"CanvasLayer/Control(UI)/VBoxContainer/ResultLabel"
@onready var enemy_label =$"CanvasLayer/Control(UI)/VBoxContainer/EnemyLabel"
@onready var gold_label = $"CanvasLayer/Control(UI)/VBoxContainer/GoldLabel"

func _ready():
	randomize()
	player_hp = 100
	enemy_level = 1
	spawn_enemy()
	update_ui()

func spawn_enemy():
	enemy_hp = 40 + enemy_level * 10
	
	enemy_hp_bar.max_value = enemy_hp   # 🔥 THIS LINE FIXES IT
	enemy_hp_bar.value = enemy_hp		# make sure it's full
	
	enemy_label.text = "Enemy Lvl " + str(enemy_level)

func update_ui():
	player_hp_bar.value = player_hp
	enemy_hp_bar.value = enemy_hp
	gold_label.text = "Gold: " + str(Global.gold)

func _on_roll_button_pressed():
	if player_hp <= 0:
		return
	
	var roll = randi_range(1, 20)
	var final_roll = roll + Global.item_power
	
	dice_label.text = "🎲 " + str(roll) + " + " + str(Global.item_power) + " = " + str(final_roll)
	
	# Player attacks enemy
	enemy_hp -= final_roll

	# Enemy attacks back
	var enemy_damage = randi_range(5, 15) + enemy_level
	player_hp -= enemy_damage
	result_label.text = "You dealt " + str(final_roll) + " | Took " + str(enemy_damage) + " damage"
	
	check_combat()

	update_ui()
	
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
