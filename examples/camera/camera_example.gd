extends Node2D

@onready var camera: ShakableCamera = $ShakableCamera

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Adding 0.3 trauma. Small hits barely shake, but rapidly mashing it
		# will stack trauma up to 1.0, creating a massive explosion shake!
		camera.add_trauma(0.3)
