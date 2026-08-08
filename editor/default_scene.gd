@tool
extends OptionButton

const main_scene = "application/run/main_scene"
const selected_setting = "godot_utils/selected_scenes"

var all_scene_paths: Array[String] = []
var selected_paths: Array[String] = []

@onready var edit_button: Button = $"../EditButton"
@onready var dialog: AcceptDialog = $"../../SceneSelectDialog"
@onready var checkbox_container: VBoxContainer = $"../../SceneSelectDialog/ScrollContainer/VBoxContainer"

func _ready() -> void:
  if _is_in_edited_scene():
    return
    
  if not ProjectSettings.has_setting(selected_setting):
    ProjectSettings.set_setting(selected_setting, [])
    ProjectSettings.set_initial_value(selected_setting, [])

  _refresh_dropdown()

  if edit_button and not edit_button.pressed.is_connected(_on_edit_pressed):
    edit_button.pressed.connect(_on_edit_pressed)

  if dialog and not dialog.confirmed.is_connected(_on_dialog_confirmed):
    dialog.confirmed.connect(_on_dialog_confirmed)

func _is_in_edited_scene() -> bool:
  if not is_inside_tree(): return false
  var edited = get_tree().edited_scene_root
  return edited != null and (edited == self or owner == edited)

func _refresh_dropdown():
  var current_scene = ProjectSettings.get_setting(main_scene)
  if !(current_scene is String): current_scene = null

  var raw_selected = ProjectSettings.get_setting(selected_setting)
  if typeof(raw_selected) == TYPE_ARRAY:
    selected_paths.assign(raw_selected)
  else:
    selected_paths = []

  all_scene_paths.clear()
  _find_scenes("res://")
  all_scene_paths.sort_custom(func(a, b): return a.get_file().get_basename().capitalize() < b.get_file().get_basename().capitalize())

  clear()

  var display_paths = selected_paths if selected_paths.size() > 0 else all_scene_paths

  var current_index = -1
  var i = 0
  for path in display_paths:
    if not FileAccess.file_exists(path):
      continue
    var scene_name = path.get_file().get_basename().capitalize()
    add_item(scene_name)
    set_item_metadata(i, path)
    if current_scene == path:
      current_index = i
    i += 1

  if current_index != -1:
    select(current_index)

func _find_scenes(dir_path: String) -> void:
  var dir = DirAccess.open(dir_path)
  if dir:
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
      if dir.current_is_dir():
        if file_name != "." and file_name != ".." and not file_name.begins_with("."):
          # Skip addons to avoid clutter
          if dir_path == "res://" and file_name == "addons":
            pass
          else:
            _find_scenes(dir_path + file_name + "/")
      else:
        if file_name.ends_with(".tscn"):
          all_scene_paths.append(dir_path + file_name)
      file_name = dir.get_next()
    dir.list_dir_end()

func _on_item_selected(index: int) -> void:
  var path = get_item_metadata(index)
  if path:
    ProjectSettings.set_setting(main_scene, path)
    ProjectSettings.save()

func _on_edit_pressed():
  for child in checkbox_container.get_children():
    child.queue_free()

  for path in all_scene_paths:
    var cb = CheckBox.new()
    cb.text = path.get_file().get_basename().capitalize() + " (" + path.replace("res://", "") + ")"
    cb.set_meta("path", path)
    cb.button_pressed = path in selected_paths
    checkbox_container.add_child(cb)

  dialog.popup_centered()

func _on_dialog_confirmed():
  var new_selected = []
  for child in checkbox_container.get_children():
    if child is CheckBox and child.button_pressed:
      new_selected.append(child.get_meta("path"))

  ProjectSettings.set_setting(selected_setting, new_selected)
  ProjectSettings.save()

  _refresh_dropdown()
