extends Label

var velocity = Vector2(0, -120)
var lifetime = 0.8
var time_passed = 0.0

func _ready():
	# Add random horizontal drift
	velocity.x = randf_range(-40, 40)

func _process(delta):
	time_passed += delta
	
	# Move
	position += velocity * delta
	
	# Fade out
	modulate.a = 1.0 - (time_passed / lifetime)
	
	# Slight scale up (juice)
	scale += Vector2(0.6, 0.6) * delta
	
	if time_passed >= lifetime:
		queue_free()
