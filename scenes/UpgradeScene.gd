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
	var roll = randi_range(1, 20)

	if roll <= 6:
		steal_item()
	elif roll <= 13:
		curse_item()
	else:
		buff_item()

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

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
