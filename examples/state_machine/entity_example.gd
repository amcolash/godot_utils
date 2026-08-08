extends CharacterBody2D

# This is an example of an entity using the StateMachine pattern

@onready var state_machine: StateMachine = $StateMachine
@onready var health: int = 10

func _ready() -> void:
	# Optional: connect to transition signals
	# state_machine.get_state("Idle").Transitioned.connect(...)
	pass

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		# Force a transition to death state from root
		state_machine._do_transition("Death")
