extends Node

@onready var gold_label = $CanvasLayer/VBoxContainer/GoldLabel
@onready var item_label = $CanvasLayer/VBoxContainer/ItemLabel
@onready var result_label = $CanvasLayer/VBoxContainer/ResultLabel

func _ready():
	randomize()
	update_ui()

func update_ui():
	gold_label.text = "Gold: " + str(Global.gold)
	item_label.text = "Item Power: " + str(Global.item_power)

func _on_roll_upgrade_button_pressed():
	pay_gold()
	update_ui()

func steal_item():
	Global.item_power = 0
	result_label.text = "💀 NPC STOLE YOUR ITEM"

func curse_item():
	Global.item_power -= 2
	result_label.text = "😬 CURSED! -2 power"

func buff_item():
	Global.item_power += 3
	result_label.text = "🎉 BUFFED! +3 power"

func check_upgrade_roll():
	var roll = randi_range(1, 20)

	var center = 10
	var margin = 2   # range around center that causes steal

	if roll >= center - margin and roll <= center + margin:
		steal_item()
		result_label.text = "💀 STEAL! (center roll)"
	elif roll < center - margin:
		curse_item()
		result_label.text = "😬 CURSE!"
	else:
		buff_item()
		result_label.text = "🎉 BUFF!"

	result_label.text += "\n🎲 Roll: " + str(roll)

func pay_gold():
	if Global.gold >= 10:
		Global.gold -= 10
		check_upgrade_roll()
	else:
		result_label.text = "Insufficient Gold, you need 10 Gold to upgrade!"

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
