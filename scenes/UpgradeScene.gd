extends Node

@onready var gold_label = $CanvasLayer/VBoxContainer/GoldLabel
@onready var item_label = $CanvasLayer/VBoxContainer/ItemLabel
@onready var result_label = $CanvasLayer/VBoxContainer/ResultLabel
@onready var roll_button = $CanvasLayer/VBoxContainer/RollUpgradeButton

# 1. Grab references to the background images
@onready var man_default = $CanvasLayer/background/manDefault
@onready var man_cursed = $CanvasLayer/background/manCursed
@onready var man_steal = $CanvasLayer/background/manSteal
@onready var frame_close = $CanvasLayer/background/frameClose

# Animation variables
var drop_distance = 450.0
var closed_y: float
var open_y: float

func _ready():
	randomize()
	
	closed_y = frame_close.position.y
	open_y = closed_y - drop_distance
	
	frame_close.position.y = open_y
	frame_close.visible = true 
	
	show_character("default")
	update_ui()

func update_ui():
	gold_label.text = "Gold: " + str(Global.gold)
	item_label.text = "Item Power: " + str(Global.item_power)

# Helper function to switch the background image
func show_character(type: String):
	man_default.visible = (type == "default")
	man_cursed.visible = (type == "curse")
	man_steal.visible = (type == "steal")

func _on_roll_upgrade_button_pressed():
	if Global.gold >= 10:
		roll_button.disabled = true # Prevent spam-clicking while animating
		Global.gold -= 10
		update_ui()
		result_label.text = "Upgrading..."
		
		# --- ANIMATION SEQUENCE START ---
		
		# 1. Close the screen (Fall down)
		var tween_down = create_tween()
		# set_trans(Tween.TRANS_BOUNCE) adds a nice heavy "thud" effect when it falls
		tween_down.tween_property(frame_close, "position:y", closed_y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await tween_down.finished
		
		# 2. Wait for 2 seconds
		await get_tree().create_timer(2.0).timeout
		
		# 3. Calculate the outcome AND change the image behind the closed screen
		var final_result_text = calculate_upgrade_roll()
		
		# 4. Open the screen (Go back up)
		var tween_up = create_tween()
		tween_up.tween_property(frame_close, "position:y", open_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween_up.finished
		
		# 5. Show the final text and re-enable button
		result_label.text = final_result_text
		update_ui()
		roll_button.disabled = false
		
		# --- ANIMATION SEQUENCE END ---
		
	else:
		result_label.text = "Insufficient Gold, you need 10 Gold to upgrade!"

# Refactored to return the text and calculate scaling buffs/curses
# Refactored to return the text and calculate scaling buffs/curses
func calculate_upgrade_roll() -> String:
	# I changed this to 0-20, since you mentioned rolling a 0 in your example!
	var roll = randi_range(0, 20) 
	var outcome_text = ""

	if roll >= 8 and roll <= 12:
		# The Steal Zone (8, 9, 10, 11, 12)
		Global.item_power = 0
		outcome_text = "STEAL!\n NPC STOLE YOUR ITEM"
		show_character("steal")
		
	elif roll < 8:
		# The Curse Zone (0 to 7)
		# We subtract 8 from the roll. 
		# Example: If roll is 5 -> 5 - 8 = -3. If roll is 0 -> 0 - 8 = -8.
		var curse_amount = roll - 8 
		
		# curse_amount is already a negative number here, so we just add it
		Global.item_power += curse_amount 
		outcome_text = "CURSE!\nCursed! " + str(curse_amount)
		show_character("curse")
		
	elif roll > 12:
		# The Buff Zone (13 to 20)
		# We subtract 12 from the roll.
		# Example: If roll is 20 -> 20 - 12 = 8. If roll is 15 -> 15 - 12 = 3.
		var buff_amount = roll - 12
		
		Global.item_power += buff_amount
		outcome_text = "BUFF!\nBuffed! +" + str(buff_amount)
		show_character("default") 

	outcome_text += "\nRoll: " + str(roll)
	return outcome_text

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
