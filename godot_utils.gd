@tool
extends EditorPlugin

var dock
var array_tool
var label_size_inspector_plugin


func _enter_tree() -> void:
  dock = EditorDock.new()
  dock.title = "Godot Utils"
  dock.default_slot = EditorPlugin.DOCK_SLOT_LEFT_BR

  var dock_content = preload("res://addons/godot_utils/editor/editor_tools.tscn").instantiate()
  dock.add_child(dock_content)
  add_dock(dock)

  var array_tool_script = preload("res://addons/godot_utils/editor/array_tool/array_tool.gd")
  array_tool = array_tool_script.new(self)

  var label_size_script = preload("res://addons/godot_utils/editor/label_size_inspector_plugin.gd")
  label_size_inspector_plugin = label_size_script.new()
  add_inspector_plugin(label_size_inspector_plugin)


func _exit_tree() -> void:
  if dock:
    remove_dock(dock)
    dock.queue_free()
    dock = null

  if array_tool:
    array_tool.cleanup()
    array_tool = null

  if label_size_inspector_plugin:
    remove_inspector_plugin(label_size_inspector_plugin)
    label_size_inspector_plugin = null
