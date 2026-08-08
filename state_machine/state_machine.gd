@icon("res://addons/godot_utils/icons/state_machine.svg")
class_name StateMachine
extends Node

@export var initial_state: State
@export var debug: bool = false

var current_state: State
var states: Dictionary[String, State] = {}

var _transition_timer: float = 0.0
var _pending_state_name: String = ""

func _ready() -> void:
  for child in get_children():
    if child is State:
      states[child.name] = child
      child.Transitioned.connect(on_child_transition)
      child.state_machine = self
      child.root = get_parent()

  if initial_state:
    initial_state.enter()
    current_state = initial_state

func get_state(state_name: String) -> State:
  return states.get(state_name)

func _process(delta: float) -> void:
  if current_state:
    current_state.state_process(delta)

func _physics_process(delta: float) -> void:
  if _transition_timer > 0:
    _transition_timer -= delta
    if _transition_timer <= 0 and _pending_state_name != "":
      _do_transition(_pending_state_name)
      _pending_state_name = ""
    return

  if current_state:
    current_state.state_physics_process(delta)

func on_child_transition(new_state_name: String) -> void:
  if current_state and current_state.name == new_state_name:
    return

  if _transition_timer > 0:
    return

  if current_state and current_state.transition_cooldown > 0:
    _transition_timer = current_state.transition_cooldown
    _pending_state_name = new_state_name
  else:
    _do_transition(new_state_name)

func _do_transition(new_state_name: String) -> void:
  if debug:
    print("transition from ", current_state.name, " to ", new_state_name)

  var new_state = states.get(new_state_name)

  if OS.is_debug_build():
    assert(new_state)

  if !new_state or !new_state.can_transition():
    return

  if current_state:
    current_state.exit()

  new_state.enter()
  current_state = new_state
