extends CanvasLayer

signal tutorial_finished

# We'll use a simple "Stage" and "Chat" counter
var current_tut = 1 # 1 for Tut1, 2 for Tut2
var current_chat = 1

@onready var tut1 = $ColorRect/Tut1
@onready var tut2 = $ColorRect/Tut2

func _ready():
	# Start by hiding everything and only showing Tut1, Chat 1
	tut1.show()
	tut2.hide()
	_update_chat_visibility()

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		advance_tutorial()

func advance_tutorial():
	current_chat += 1
	
	if current_tut == 1:
		if current_chat > 3: # Tut1 has 3 chats
			# Move to Tut2
			current_tut = 2
			current_chat = 1
			tut1.hide()
			tut2.show()
	
	elif current_tut == 2:
		if current_chat > 2: # Tut2 has 2 chats
			# Finish the tutorial
			finish()
			return
			
	_update_chat_visibility()

func _update_chat_visibility():
	if current_tut == 1:
		# Path: Tut1 -> TextureRect2 -> c1, c2, c3
		var bubble = tut1.get_node("TextureRect2")
		bubble.get_node("c1").visible = (current_chat == 1)
		bubble.get_node("c2").visible = (current_chat == 2)
		bubble.get_node("c3").visible = (current_chat == 3)
	
	elif current_tut == 2:
		# Path: Tut2 -> TextureRect2 -> c1, c2
		var bubble = tut2.get_node("TextureRect2")
		bubble.get_node("c1").visible = (current_chat == 1)
		bubble.get_node("c2").visible = (current_chat == 2)

func finish():
	print("Signaal verzonden: Combat tutorial is klaar!") # Debug line
	emit_signal("tutorial_finished")
	queue_free()
