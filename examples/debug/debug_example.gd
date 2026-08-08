extends Node

# Example of how to hook up custom actions to the DebugController

func _ready() -> void:
	if OS.is_debug_build() and has_node("/root/DebugController"):
		var debug = get_node("/root/DebugController")
		
		# Assuming 'cheat_gold' is mapped in ProjectSettings -> Input Map
		debug.register_action("cheat_gold", _give_gold)
		debug.register_action("cheat_level", _level_up)

func _give_gold() -> void:
	print("Cheat activated: +1000 Gold!")

func _level_up() -> void:
	print("Cheat activated: Level Up!")
