@tool
extends EditorPlugin

var dock

func _enter_tree():
   dock = EditorDock.new()
   dock.title = "Godot Utils"
   dock.default_slot = EditorPlugin.DOCK_SLOT_LEFT_BR

   var dock_content = preload("res://addons/godot_utils/editor/editor_tools.tscn").instantiate()
   dock.add_child(dock_content)
   add_dock(dock)


func _exit_tree():
  remove_dock(dock)
  dock.queue_free()
  dock = null
