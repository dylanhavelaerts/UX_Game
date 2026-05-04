extends CanvasLayer

signal tutorial_finished

var current_chat_index = 0
@onready var chat_container = $ColorRect/Tut1/TextureRect2
@onready var chats = chat_container.get_children()

func _ready():
	# Zorg dat de tutorial zichtbaar is en begin bij het eerste bericht
	show()
	_update_visibility()

func _input(event):
	# Ga naar de volgende chat bij een klik of spatie/enter
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		_advance_tutorial()

func _advance_tutorial():
	current_chat_index += 1
	
	# Als we voorbij het laatste bericht zijn, sluiten we de tutorial
	if current_chat_index >= chats.size():
		_finish()
	else:
		_update_visibility()

func _update_visibility():
	# Zet alle berichtjes uit, behalve de huidige
	for i in range(chats.size()):
		chats[i].visible = (i == current_chat_index)

func _finish():
	emit_signal("tutorial_finished")
	queue_free() # Verwijder de tutorial uit de scene
