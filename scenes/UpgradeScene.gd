extends Node

@onready var gold_label = $CanvasLayer/VBoxContainer/GoldLabel
@onready var item_label = $CanvasLayer/VBoxContainer/ItemLabel
@onready var result_label = $CanvasLayer/VBoxContainer/ResultLabel
@onready var roll_button = $CanvasLayer/VBoxContainer/RollUpgradeButton
@onready var item_choice_container = $CanvasLayer/VBoxContainer/ItemChoiceContainer

# 1. Grab references to the background images
@onready var man_default = $CanvasLayer/background/manDefault
@onready var frame_close = $CanvasLayer/background/frameClose

# Animation variables
var drop_distance = 450.0
var closed_y: float
var open_y: float

# Het item dat de speler heeft gekozen om te upgraden
var selected_item: Dictionary = {}

func _ready():
	randomize()
	
	closed_y = frame_close.position.y
	open_y = closed_y - drop_distance
	frame_close.position.y = open_y
	frame_close.visible = true
	
	item_choice_container.visible = false
	update_ui()
	
	# Toon de item keuze meteen bij het openen van de scene
	# FALSE means "this is the initial load, not right after a roll"
	show_item_selection(false)

func update_ui():
	gold_label.text = "Gold: " + str(Global.gold)
	# Toon de totale item power
	item_label.text = "Item Power: " + str(Global.item_power)

# Added is_after_roll parameter so we don't overwrite the result text instantly
func show_item_selection(is_after_roll: bool = false):
	# Verwijder oude knoppen als die er al zijn
	for child in item_choice_container.get_children():
		child.queue_free()
	
	var owned = Global.get_owned_items()
	
	if owned.is_empty():
		# Speler heeft geen items, roll button uitschakelen
		if is_after_roll:
			result_label.text += "\n(No items left to upgrade!)"
		else:
			result_label.text = "You have no items to upgrade!"
			result_label.add_theme_color_override("font_color", Color.WHITE)
		roll_button.disabled = true
		return
	
	# Maak een knop per owned item
	for item in owned:
		var btn = Button.new()
		btn.text = item["name"] + "\n(+" + str(item["power_bonus"]) + " power) [" + item["category"] + "]"
		btn.custom_minimum_size = Vector2(160, 60)
		btn.pressed.connect(_on_item_button_pressed.bind(item))
		item_choice_container.add_child(btn)
	
	item_choice_container.visible = true
	
	# THE FIX: ONLY RESET TEXT IF WE ARE NOT COMING DIRECTLY FROM A ROLL
	if not is_after_roll:
		result_label.text = "Choose an item to risk!"
		result_label.add_theme_color_override("font_color", Color.WHITE) 
	
	# Roll button staat uit totdat speler een item kiest
	roll_button.disabled = true

func _on_item_button_pressed(item: Dictionary):
	selected_item = item
	result_label.text = "Selected: " + item["name"] + "\nPress Roll to risk it!"
	
	# Reset the color back to white when selecting a new item
	result_label.add_theme_color_override("font_color", Color.WHITE) 
	
	roll_button.disabled = false

func _on_roll_upgrade_button_pressed():
	if Global.gold >= 10 and not selected_item.is_empty():
		roll_button.disabled = true
		# Verstop de item keuze tijdens de animatie
		item_choice_container.visible = false
		Global.gold -= 10
		update_ui()
		result_label.text = "Upgrading " + selected_item["name"] + "..."
		
		# --- ANIMATION SEQUENCE START ---
		
		# 1. Close the screen (Fall down)
		var tween_down = create_tween()
		tween_down.tween_property(frame_close, "position:y", closed_y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await tween_down.finished
		
		# 2. Wait for 2 seconds
		await get_tree().create_timer(2.0).timeout
		
		# 3. Calculate the outcome AND change the image behind the closed screen
		var final_result = calculate_upgrade_roll() 
		
		# 4. Open the screen (Go back up)
		var tween_up = create_tween()
		tween_up.tween_property(frame_close, "position:y", open_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween_up.finished
		
		# 5. Show the final text, apply the color, and update UI
		result_label.text = final_result["text"]
		result_label.add_theme_color_override("font_color", final_result["color"])
		update_ui()
		
		# TRUE means "we just rolled, build the buttons but DO NOT overwrite my result text"
		show_item_selection(true)
		
		# --- ANIMATION SEQUENCE END ---
		
	elif selected_item.is_empty():
		result_label.text = "Select an item first!"
	else:
		result_label.text = "Insufficient Gold, you need 10 Gold to upgrade!"

# Returns a dictionary so we can pass back both text AND color
func calculate_upgrade_roll() -> Dictionary:
	var roll = randi_range(0, 20)
	var outcome = {"text": "", "color": Color.WHITE}
	
	if roll >= 8 and roll <= 12:
		# The Steal Zone
		Global.remove_item(selected_item["category"])
		selected_item = {}
		outcome["text"] = "YOUR ITEM HAS BEEN STOLEN!"
		outcome["color"] = Color.RED
		
	elif roll < 8:
		# The Curse Zone
		var curse_amount = roll - 8
		selected_item["power_bonus"] += curse_amount
		Global.equipped_items[selected_item["category"]] = selected_item
		Global.recalculate_item_power()
		outcome["text"] = "YOUR ITEM HAS BEEN CURSED WITH [" + str(curse_amount) + " POWER]"
		outcome["color"] = Color.RED
		
	elif roll > 12:
		# The Buff Zone
		var buff_amount = roll - 12
		selected_item["power_bonus"] += buff_amount
		Global.equipped_items[selected_item["category"]] = selected_item
		Global.recalculate_item_power()
		outcome["text"] = "YOUR ITEM HAS BEEN BUFFED WITH [+" + str(buff_amount) + " POWER]"
		outcome["color"] = Color.GREEN
	
	outcome["text"] += "\n(Rolled a " + str(roll) + ")"
	return outcome

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/CombatScene.tscn")
