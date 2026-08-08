@tool
extends Button

@onready var settings = EditorInterface.get_editor_settings()

func _ready() -> void:
  if _is_in_edited_scene():
    return
    
  var timer = Timer.new()
  timer.wait_time = 5.0
  timer.autostart = true
  timer.timeout.connect(_on_timer_timeout)
  add_child(timer)

func _is_in_edited_scene() -> bool:
  if not is_inside_tree(): return false
  var edited = get_tree().edited_scene_root
  return edited != null and (edited == self or owner == edited)

# Auto-switch scale, makes the button kinda useless
func _on_timer_timeout() -> void:
  var screen_size = DisplayServer.screen_get_size()
  var current_scale = settings.get_setting("interface/editor/display_scale")

  if get_window().has_focus():
    var modified = false
    if screen_size.x != 2560 && current_scale == 2:
      settings.set_setting("interface/editor/display_scale", 5)
      modified = true

    if screen_size.x == 2560 && current_scale == 5:
      settings.set_setting("interface/editor/display_scale", 2)
      modified = true

    if modified:
      OS.execute("notify-send", ["Restarting Godot in correct resolution"])
      EditorInterface.restart_editor(true)

func _on_pressed() -> void:
  # 100% = 2, 175% = 5
  var current = settings.get_setting("interface/editor/display_scale")
  if current == 2:
    settings.set_setting("interface/editor/display_scale", 5)
  else:
    settings.set_setting("interface/editor/display_scale", 2)

  EditorInterface.restart_editor(true)
