class_name ShakableCamera
extends Camera2D

@export var max_x: float = 150.0
@export var max_y: float = 150.0
@export var max_rotation: float = 0.1
@export var trauma_reduction_rate: float = 1.0

var trauma: float = 0.0
var noise = FastNoiseLite.new()
var noise_y = 0.0

func _ready():
  noise.seed = randi()
  noise.frequency = 0.5 # High frequency for fast shaking

func _process(delta: float):
  if trauma > 0:
    trauma = max(trauma - trauma_reduction_rate * delta, 0.0)
    _shake()
  else:
    offset = Vector2.ZERO
    rotation = 0.0

func add_trauma(amount: float):
  trauma = min(trauma + amount, 1.0)

func _shake():
  var amount = pow(trauma, 2)
  noise_y += 1.0
  rotation = max_rotation * amount * noise.get_noise_2d(noise.seed, noise_y)
  offset.x = max_x * amount * noise.get_noise_2d(noise.seed * 2, noise_y)
  offset.y = max_y * amount * noise.get_noise_2d(noise.seed * 3, noise_y)
