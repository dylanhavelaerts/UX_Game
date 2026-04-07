extends Node

var gold = 0
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
	spawn_enemy()
	update_ui()

func spawn_enemy():
	enemy_hp = 40 + enemy_level * 10
	enemy_label.text = "Enemy Lvl " + str(enemy_level)

func update_ui():
	player_hp_bar.value = player_hp
	enemy_hp_bar.value = enemy_hp
	gold_label.text = "Gold: " + str(gold)

func _on_roll_button_pressed():
	var roll = randi_range(1, 20)
	var final_roll = roll + Global.item_power
	
	dice_label.text = "🎲 " + str(roll)

	# Player attacks enemy
	enemy_hp -= final_roll

	# Enemy attacks back
	player_hp -= randi_range(5, 15)

	check_combat()

	update_ui()

func check_combat():
	if enemy_hp <= 0:
		win()
	elif player_hp <= 0:
		lose()

func win():
	var reward = 10 + enemy_level * 5
	gold += reward
	
	result_label.text = "YOU WIN! +" + str(reward) + " gold"

	enemy_level += 1
	spawn_enemy()
	enemy_hp = 40 + enemy_level * 10

func lose():
	result_label.text = "YOU LOST! Resetting..."

	player_hp = 100
	enemy_level = 1
	spawn_enemy()
