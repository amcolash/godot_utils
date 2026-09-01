@tool
class_name ArrayTool
extends RefCounted

var plugin: EditorPlugin
var toolbar_button_3d: Button
var toolbar_button_2d: Button
var popup_panel: PopupPanel
var array_ui: Node


func _init(p_plugin: EditorPlugin) -> void:
  plugin = p_plugin
  _setup()


func _setup() -> void:
  var base_control = plugin.get_editor_interface().get_base_control()

  # 1. 3D Viewport Toolbar Button
  toolbar_button_3d = Button.new()
  toolbar_button_3d.flat = true
  toolbar_button_3d.tooltip_text = "Node Array & Distribute Tool (3D)"
  if base_control:
    if base_control.has_theme_icon("VisualInstance3D", "EditorIcons"):
      toolbar_button_3d.icon = base_control.get_theme_icon("VisualInstance3D", "EditorIcons")
    elif base_control.has_theme_icon("Node3D", "EditorIcons"):
      toolbar_button_3d.icon = base_control.get_theme_icon("Node3D", "EditorIcons")
  toolbar_button_3d.pressed.connect(
    func():
      _toggle_popup(toolbar_button_3d),
  )
  plugin.add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, toolbar_button_3d)

  # 2. 2D Viewport Toolbar Button
  toolbar_button_2d = Button.new()
  toolbar_button_2d.flat = true
  toolbar_button_2d.tooltip_text = "Node Array & Distribute Tool (2D)"
  if base_control:
    if base_control.has_theme_icon("CanvasItem", "EditorIcons"):
      toolbar_button_2d.icon = base_control.get_theme_icon("CanvasItem", "EditorIcons")
    elif base_control.has_theme_icon("Node2D", "EditorIcons"):
      toolbar_button_2d.icon = base_control.get_theme_icon("Node2D", "EditorIcons")
  toolbar_button_2d.pressed.connect(
    func():
      _toggle_popup(toolbar_button_2d),
  )
  plugin.add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, toolbar_button_2d)

  # 3. Popup Panel UI
  var popup_scene = preload("res://addons/godot_utils/editor/array_tool/array_tool_popup.tscn")
  array_ui = popup_scene.instantiate()
  array_ui.setup(plugin)

  popup_panel = PopupPanel.new()
  popup_panel.wrap_controls = true
  popup_panel.unresizable = true
  if base_control and base_control.theme:
    popup_panel.theme = base_control.theme
    array_ui.theme = base_control.theme
  popup_panel.add_child(array_ui)
  plugin.add_child(popup_panel)

  popup_panel.popup_hide.connect(
    func():
      if array_ui and array_ui.has_method("clear_preview"):
        array_ui.clear_preview(),
  )

  var selection = plugin.get_editor_interface().get_selection()
  if selection:
    selection.selection_changed.connect(_on_selection_changed)


func cleanup() -> void:
  if array_ui and array_ui.has_method("clear_preview"):
    array_ui.clear_preview()

  if toolbar_button_3d:
    plugin.remove_control_from_container(
      EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,
      toolbar_button_3d,
    )
    toolbar_button_3d.queue_free()
    toolbar_button_3d = null

  if toolbar_button_2d:
    plugin.remove_control_from_container(
      EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,
      toolbar_button_2d,
    )
    toolbar_button_2d.queue_free()
    toolbar_button_2d = null

  if popup_panel:
    popup_panel.queue_free()
    popup_panel = null


func _toggle_popup(from_button: Button) -> void:
  if not popup_panel or not from_button:
    return

  if popup_panel.visible:
    popup_panel.hide()
  else:
    if array_ui and array_ui.has_method("refresh_ui"):
      array_ui.refresh_ui()

    var ed_scale = plugin.get_editor_interface().get_editor_scale()
    var btn_rect = from_button.get_global_rect()
    var popup_pos = Vector2i(int(btn_rect.position.x), int(btn_rect.end.y + 4 * ed_scale))

    var req_size = Vector2i(int(300.0 * ed_scale), int(230.0 * ed_scale))
    if array_ui:
      var min_sz = array_ui.get_combined_minimum_size()
      if min_sz.x > 0 and min_sz.y > 0:
        req_size = Vector2i(int(maxf(req_size.x, min_sz.x)), int(maxf(req_size.y, min_sz.y)))

    popup_panel.popup(Rect2i(popup_pos, req_size))
    popup_panel.reset_size()


func _on_selection_changed() -> void:
  if array_ui and array_ui.has_method("refresh_ui"):
    array_ui.refresh_ui()
