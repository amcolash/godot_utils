@icon("res://addons/godot_utils/icons/die.svg")
class_name CustomRandom
extends Node

## Global game seed, used for global rng
var game_seed: int = 12345
var _rng = RandomNumberGenerator.new()

func _init() -> void:
  # Seed rng only for prod builds
  setup(game_seed if OS.is_debug_build() else randi())

func setup(new_seed: int) -> void:
  game_seed = new_seed
  _rng.seed = game_seed

func rand_weighted(weights: PackedFloat32Array) -> int:
  return _rng.rand_weighted(weights)

func randf() -> float:
  return _rng.randf()

func randf_range(from: float, to: float) -> float:
  return _rng.randf_range(from, to)

func randfn(mean: float = 0.0, deviation: float = 1.0) -> float:
  return _rng.randfn(mean, deviation)

func randi() -> int:
  return _rng.randi()

func randi_range(from: int, to: int) -> int:
  return _rng.randi_range(from, to)
