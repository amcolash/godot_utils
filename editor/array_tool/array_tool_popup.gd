@tool
extends MarginContainer

var _plugin: EditorPlugin
var _is_2d_mode: bool = false

@onready var selection_label: Label = %SelectionLabel
@onready var axis_option: OptionButton = %AxisOption
@onready var spacing_spinbox: SpinBox = %SpacingSpinBox
@onready var copies_label: Label = %CopiesLabel
@onready var copies_spinbox: SpinBox = %CopiesSpinBox
@onready var span_label: Label = %SpanLabel
@onready var execute_button: Button = %ExecuteButton


func setup(p_plugin: EditorPlugin) -> void:
  _plugin = p_plugin


func _ready() -> void:
  _rebuild_axis_options(false)

  if axis_option:
    axis_option.item_selected.connect(
      func(_idx):
        _update_span_info(),
    )
  if spacing_spinbox:
    spacing_spinbox.value_changed.connect(
      func(_val):
        _update_span_info(),
    )
  if copies_spinbox:
    copies_spinbox.value_changed.connect(
      func(_val):
        _update_span_info(),
    )
  if execute_button:
    execute_button.pressed.connect(_on_execute_pressed)

  refresh_ui()


func _rebuild_axis_options(is_2d: bool) -> void:
  if not axis_option:
    return
  _is_2d_mode = is_2d
  var prev_selected = axis_option.selected
  axis_option.clear()

  if is_2d:
    axis_option.add_item("+X Axis (Right)", 0)
    axis_option.add_item("-X Axis (Left)", 1)
    axis_option.add_item("+Y Axis (Down)", 2)
    axis_option.add_item("-Y Axis (Up)", 3)
    if spacing_spinbox:
      spacing_spinbox.suffix = "px"
      if spacing_spinbox.value == 5.0:
        spacing_spinbox.value = 50.0
  else:
    axis_option.add_item("+X Axis", 0)
    axis_option.add_item("-X Axis", 1)
    axis_option.add_item("+Y Axis", 2)
    axis_option.add_item("-Y Axis", 3)
    axis_option.add_item("+Z Axis", 4)
    axis_option.add_item("-Z Axis", 5)
    if spacing_spinbox:
      spacing_spinbox.suffix = "m"
      if spacing_spinbox.value == 50.0:
        spacing_spinbox.value = 5.0

  axis_option.selected = mini(prev_selected, axis_option.item_count - 1) if prev_selected >= 0 else 0


func _set_copies_visible(v: bool) -> void:
  if copies_label:
    copies_label.visible = v
  if copies_spinbox:
    copies_spinbox.visible = v


func refresh_ui() -> void:
  if not is_inside_tree() or not _plugin:
    return

  var nodes = _get_spatial_or_canvas_nodes()
  var count = nodes.size()

  if count == 0:
    selection_label.text = "No Node2D / Node3D selected"
    selection_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
    _set_copies_visible(false)
    span_label.text = "Select 1 node to duplicate & array, or multiple nodes to distribute."
    execute_button.disabled = true
    execute_button.text = "Distribute / Array"
    return

  var is_2d = (nodes[0] is Node2D or nodes[0] is Control)
  if is_2d != _is_2d_mode:
    _rebuild_axis_options(is_2d)

  if count == 1:
    selection_label.text = "1 node selected ('%s')" % nodes[0].name
    selection_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 1.0))
    _set_copies_visible(true)
    execute_button.disabled = false
    _update_span_info()
  else:
    selection_label.text = "%d %s objects selected" % [count, "2D" if is_2d else "3D"]
    selection_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6, 1.0))
    _set_copies_visible(false)
    execute_button.disabled = false
    _update_span_info()


func _update_span_info() -> void:
  var nodes = _get_spatial_or_canvas_nodes()
  var count = nodes.size()
  if count == 0 or not spacing_spinbox or not axis_option:
    return

  var spacing = spacing_spinbox.value
  var axis_name = axis_option.get_item_text(axis_option.selected)
  var unit = "px" if _is_2d_mode else "m"

  if count == 1:
    var copies = int(copies_spinbox.value) if copies_spinbox else 20
    var total_span = (copies - 1) * abs(spacing)
    span_label.text = "%d nodes @ %.2f%s step (%s) = %.2f%s total span" % [
      copies,
      spacing,
      unit,
      axis_name,
      total_span,
      unit,
    ]
    execute_button.text = "Duplicate & Array (%d Nodes)" % copies
  elif count > 1:
    var total_span = (count - 1) * abs(spacing)
    span_label.text = "%d nodes @ %.2f%s step (%s) = %.2f%s total span" % [
      count,
      spacing,
      unit,
      axis_name,
      total_span,
      unit,
    ]
    execute_button.text = "Distribute %d Nodes" % count


func _get_spatial_or_canvas_nodes() -> Array[Node]:
  var result: Array[Node] = []
  if not _plugin:
    return result
  var sel = _plugin.get_editor_interface().get_selection()
  if not sel:
    return result
  for node in sel.get_selected_nodes():
    if node is Node3D or node is Node2D or node is Control:
      result.append(node)
  return result


func _on_execute_pressed() -> void:
  var nodes = _get_spatial_or_canvas_nodes()
  if nodes.is_empty():
    return

  var spacing = spacing_spinbox.value
  var ur = _plugin.get_undo_redo()

  if _is_2d_mode:
    var axis_vec_2d = _get_axis_vector_2d()
    if nodes.size() > 1:
      _distribute_2d_nodes(nodes, axis_vec_2d, spacing, ur)
    elif nodes.size() == 1:
      var copies = int(copies_spinbox.value)
      _duplicate_and_array_2d(nodes[0], axis_vec_2d, spacing, copies, ur)
  else:
    var axis_vec_3d = _get_axis_vector_3d()
    if nodes.size() > 1:
      _distribute_3d_nodes(nodes, axis_vec_3d, spacing, ur)
    elif nodes.size() == 1:
      var copies = int(copies_spinbox.value)
      _duplicate_and_array_3d(nodes[0], axis_vec_3d, spacing, copies, ur)

  var parent_popup = get_parent()
  if parent_popup is PopupPanel:
    parent_popup.hide()


func _get_axis_vector_3d() -> Vector3:
  match axis_option.selected:
    0:
      return Vector3(1, 0, 0)
    1:
      return Vector3(-1, 0, 0)
    2:
      return Vector3(0, 1, 0)
    3:
      return Vector3(0, -1, 0)
    4:
      return Vector3(0, 0, 1)
    5:
      return Vector3(0, 0, -1)
    _:
      return Vector3(1, 0, 0)


func _get_axis_vector_2d() -> Vector2:
  match axis_option.selected:
    0:
      return Vector2(1, 0)
    1:
      return Vector2(-1, 0)
    2:
      return Vector2(0, 1)
    3:
      return Vector2(0, -1)
    _:
      return Vector2(1, 0)


func _distribute_3d_nodes(
  nodes: Array[Node],
  axis_vec: Vector3,
  spacing: float,
  ur: EditorUndoRedoManager,
) -> void:
  var sorted_nodes = nodes.duplicate()

  if abs(axis_vec.x) > 0.001:
    sorted_nodes.sort_custom(
      func(a, b):
        return a.position.x < b.position.x,
    )
  elif abs(axis_vec.y) > 0.001:
    sorted_nodes.sort_custom(
      func(a, b):
        return a.position.y < b.position.y,
    )
  elif abs(axis_vec.z) > 0.001:
    sorted_nodes.sort_custom(
      func(a, b):
        return a.position.z < b.position.z,
    )

  var start_pos: Vector3 = sorted_nodes[0].position
  var old_positions: Array[Vector3] = []
  var new_positions: Array[Vector3] = []

  for i in range(sorted_nodes.size()):
    var node: Node3D = sorted_nodes[i]
    old_positions.append(node.position)
    var target_pos = start_pos + (axis_vec * (i * spacing))
    if abs(axis_vec.x) < 0.001:
      target_pos.x = node.position.x
    if abs(axis_vec.y) < 0.001:
      target_pos.y = node.position.y
    if abs(axis_vec.z) < 0.001:
      target_pos.z = node.position.z
    new_positions.append(target_pos)

  ur.create_action("Distribute %d 3D Nodes" % sorted_nodes.size())
  for i in range(sorted_nodes.size()):
    ur.add_do_property(sorted_nodes[i], "position", new_positions[i])
    ur.add_undo_property(sorted_nodes[i], "position", old_positions[i])
  ur.commit_action()


func _duplicate_and_array_3d(
  orig_node: Node,
  axis_vec: Vector3,
  spacing: float,
  copies: int,
  ur: EditorUndoRedoManager,
) -> void:
  var parent = orig_node.get_parent()
  if not parent:
    return

  var scene_root = _plugin.get_editor_interface().get_edited_scene_root()
  var created_nodes: Array[Node3D] = []

  for i in range(1, copies):
    var dup = orig_node.duplicate(7) as Node3D
    dup.name = "%s_%d" % [orig_node.name, i + 1]
    dup.position = (orig_node as Node3D).position + (axis_vec * (i * spacing))
    created_nodes.append(dup)

  ur.create_action("Duplicate & Array %d 3D Nodes" % copies)
  for dup in created_nodes:
    ur.add_do_method(parent, "add_child", dup)
    ur.add_do_property(dup, "owner", scene_root)
    ur.add_undo_method(parent, "remove_child", dup)
  ur.commit_action()

  var sel = _plugin.get_editor_interface().get_selection()
  if sel:
    sel.clear()
    sel.add_node(orig_node)
    for dup in created_nodes:
      sel.add_node(dup)


func _distribute_2d_nodes(
  nodes: Array[Node],
  axis_vec: Vector2,
  spacing: float,
  ur: EditorUndoRedoManager,
) -> void:
  var sorted_nodes = nodes.duplicate()

  if abs(axis_vec.x) > 0.001:
    sorted_nodes.sort_custom(
      func(a, b):
        return a.position.x < b.position.x,
    )
  elif abs(axis_vec.y) > 0.001:
    sorted_nodes.sort_custom(
      func(a, b):
        return a.position.y < b.position.y,
    )

  var start_pos: Vector2 = sorted_nodes[0].position
  var old_positions: Array[Vector2] = []
  var new_positions: Array[Vector2] = []

  for i in range(sorted_nodes.size()):
    var node = sorted_nodes[i]
    old_positions.append(node.position)
    var target_pos = start_pos + (axis_vec * (i * spacing))
    if abs(axis_vec.x) < 0.001:
      target_pos.x = node.position.x
    if abs(axis_vec.y) < 0.001:
      target_pos.y = node.position.y
    new_positions.append(target_pos)

  ur.create_action("Distribute %d 2D Nodes" % sorted_nodes.size())
  for i in range(sorted_nodes.size()):
    ur.add_do_property(sorted_nodes[i], "position", new_positions[i])
    ur.add_undo_property(sorted_nodes[i], "position", old_positions[i])
  ur.commit_action()


func _duplicate_and_array_2d(
  orig_node: Node,
  axis_vec: Vector2,
  spacing: float,
  copies: int,
  ur: EditorUndoRedoManager,
) -> void:
  var parent = orig_node.get_parent()
  if not parent:
    return

  var scene_root = _plugin.get_editor_interface().get_edited_scene_root()
  var created_nodes: Array[Node] = []

  for i in range(1, copies):
    var dup = orig_node.duplicate(7)
    dup.name = "%s_%d" % [orig_node.name, i + 1]
    dup.position = orig_node.position + (axis_vec * (i * spacing))
    created_nodes.append(dup)

  ur.create_action("Duplicate & Array %d 2D Nodes" % copies)
  for dup in created_nodes:
    ur.add_do_method(parent, "add_child", dup)
    ur.add_do_property(dup, "owner", scene_root)
    ur.add_undo_method(parent, "remove_child", dup)
  ur.commit_action()

  var sel = _plugin.get_editor_interface().get_selection()
  if sel:
    sel.clear()
    sel.add_node(orig_node)
    for dup in created_nodes:
      sel.add_node(dup)
