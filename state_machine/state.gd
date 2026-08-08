@icon("res://addons/godot_utils/icons/state.svg")
class_name State
extends Node

var root: Node
var state_machine: StateMachine

@warning_ignore("unused_signal")
signal Transitioned(new_state: String)

@export var transition_cooldown: float = 0.0

func enter():
  pass

func exit():
  pass

func state_process(_delta: float) -> void:
  pass

func state_physics_process(_delta: float) -> void:
  pass

func can_transition() -> bool:
  return true
