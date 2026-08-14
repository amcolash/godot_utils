# A simple component to reparent a node when added to a scene
class_name Reparent
extends Node

@export var node: Node
@export var keep_global_transform: bool = true


func _ready() -> void:
  if node:
    get_parent().reparent(node, keep_global_transform)
