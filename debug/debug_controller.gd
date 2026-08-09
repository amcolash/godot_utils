@icon("res://addons/godot_utils/icons/joystick.svg")
class_name DebugController
extends Node

var custom_actions: Dictionary[String, Callable] = {}

func _ready() -> void:
  process_mode = Node.PROCESS_MODE_ALWAYS

func register_action(action: String, callback: Callable) -> void:
  custom_actions[action] = callback

func unregister_action(action: String) -> void:
  custom_actions.erase(action)

func _input(event: InputEvent) -> void:
  if !OS.is_debug_build():
    return

  if InputMap.has_action("close") and event.is_action("close"):
    get_tree().quit()

  if InputMap.has_action("speed"):
    if event.is_action_pressed("speed", true):
      Engine.time_scale = 20.0
      Engine.physics_ticks_per_second = int(60 * Engine.time_scale)
      Engine.max_physics_steps_per_frame = 100

    if event.is_action_released("speed"):
      Engine.time_scale = 1.0
      Engine.physics_ticks_per_second = 60
      Engine.max_physics_steps_per_frame = 8

  if InputMap.has_action("restart") and event.is_action_pressed("restart"):
    get_tree().reload_current_scene()

  # Handle custom actions
  for action in custom_actions.keys():
    if InputMap.has_action(action) and event.is_action_pressed(action):
      custom_actions[action].call()
