@icon("res://addons/godot_utils/icons/arrow_right_arrow_left.svg")

class_name OptionStepper
extends HBoxContainer

signal value_changed(index: int)

@export var left_arrow_texture: Texture2D
@export var right_arrow_texture: Texture2D
@export var separation: int = 16
@export var active_index: int = 2:
  set(val):
    active_index = val
    if options_node:
      update_option()

var options_node: PanelContainer
var total: int = 0
var _focus_style: StyleBox
var _empty_style: StyleBoxEmpty = StyleBoxEmpty.new()


func _ready() -> void:
  focus_mode = Control.FOCUS_ALL
  add_theme_constant_override("separation", separation)

  options_node = PanelContainer.new()
  options_node.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
  options_node.custom_minimum_size = Vector2(32, 32)
  options_node.add_theme_stylebox_override("panel", _empty_style)

  total = get_child_count()
  for child in get_children():
    child.reparent(options_node)

  var arrow_left = _setup_button(left_arrow_texture, _on_left)
  var arrow_right = _setup_button(right_arrow_texture, _on_right)

  add_child(arrow_left)
  add_child(options_node)
  add_child(arrow_right)

  focus_entered.connect(_update_focus)
  focus_exited.connect(_update_focus)

  update_option()
  _update_focus()


func _setup_button(texture: Texture2D, callback: Callable) -> TextureButton:
  var button = TextureButton.new()
  button.texture_normal = texture
  button.focus_mode = Control.FOCUS_NONE
  button.custom_minimum_size = Vector2(24, 24)
  button.custom_maximum_size = Vector2(24, 24)
  button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
  button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
  button.pressed.connect(callback)

  return button


func update_option() -> void:
  var i = 0
  for child in options_node.get_children():
    child.visible = i == active_index
    i += 1


func _get_focus_style() -> StyleBox:
  if not _focus_style:
    var base_style = get_theme_stylebox("focus", "Button")
    if base_style:
      var style = base_style.duplicate()
      if style is StyleBoxFlat:
        style.content_margin_left = 0.0
        style.content_margin_top = 0.0
        style.content_margin_right = 0.0
        style.content_margin_bottom = 0.0
        style.expand_margin_left = 4.0
        style.expand_margin_top = 4.0
        style.expand_margin_right = 4.0
        style.expand_margin_bottom = 4.0
      _focus_style = style
  return _focus_style


func _update_focus() -> void:
  if not options_node:
    return
  if has_focus():
    var style = _get_focus_style()
    options_node.add_theme_stylebox_override("panel", style)
  else:
    options_node.add_theme_stylebox_override("panel", _empty_style)


func _on_left() -> void:
  if total <= 0:
    return
  active_index = posmod(active_index - 1, total)
  update_option()
  grab_focus()

  value_changed.emit(active_index)


func _on_right() -> void:
  if total <= 0:
    return
  active_index = posmod(active_index + 1, total)
  update_option()
  grab_focus()

  value_changed.emit(active_index)


func _gui_input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_left"):
    _on_left()
    UISounds.on_button_pressed()
    accept_event()
  elif event.is_action_pressed("ui_right"):
    _on_right()
    UISounds.on_button_pressed()
    accept_event()
