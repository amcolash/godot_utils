@tool
extends MarginContainer

var _plugin: EditorPlugin
var _is_2d_mode: bool = false

# Live viewport preview nodes
var _preview_mesh_instance: MeshInstance3D
var _preview_canvas_item: Node2D

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
        _update_span_info()
        update_preview(),
    )
  if spacing_spinbox:
    spacing_spinbox.value_changed.connect(
      func(_val):
        _update_span_info()
        update_preview(),
    )
  if copies_spinbox:
    copies_spinbox.value_changed.connect(
      func(_val):
        _update_span_info()
        update_preview(),
    )
  if execute_button:
    execute_button.pressed.connect(_on_execute_pressed)

  refresh_ui()


func _exit_tree() -> void:
  clear_preview()


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
    clear_preview()
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

  update_preview()


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
  clear_preview()
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

# ==============================================================================
# Live Viewport Preview (3D & 2D Bounding Boxes)
# ==============================================================================


func update_preview() -> void:
  var parent_popup = get_parent()
  var is_popup_visible = false
  if parent_popup is Window:
    is_popup_visible = parent_popup.visible
  elif parent_popup is CanvasItem:
    is_popup_visible = parent_popup.is_visible_in_tree()

  if not is_popup_visible:
    clear_preview()
    return

  var nodes = _get_spatial_or_canvas_nodes()
  if nodes.is_empty() or not _plugin:
    clear_preview()
    return

  var scene_root = _plugin.get_editor_interface().get_edited_scene_root()
  if not scene_root:
    clear_preview()
    return

  var spacing = spacing_spinbox.value if spacing_spinbox else 5.0

  if _is_2d_mode:
    _update_preview_2d(nodes, scene_root, spacing)
  else:
    _update_preview_3d(nodes, scene_root, spacing)


func clear_preview() -> void:
  if is_instance_valid(_preview_mesh_instance):
    _preview_mesh_instance.queue_free()
    _preview_mesh_instance = null

  if is_instance_valid(_preview_canvas_item):
    _preview_canvas_item.queue_free()
    _preview_canvas_item = null


func _update_preview_3d(nodes: Array[Node], scene_root: Node, spacing: float) -> void:
  if is_instance_valid(_preview_canvas_item):
    _preview_canvas_item.queue_free()
    _preview_canvas_item = null

  if not is_instance_valid(_preview_mesh_instance):
    _preview_mesh_instance = MeshInstance3D.new()
    _preview_mesh_instance.name = "__ArrayToolPreview3D__"
    _preview_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    scene_root.add_child(_preview_mesh_instance)

  var im = ImmediateMesh.new()
  im.surface_begin(Mesh.PRIMITIVE_LINES)

  var axis_vec = _get_axis_vector_3d()

  if nodes.size() == 1:
    var node = nodes[0] as Node3D
    if node:
      var local_aabb = _calculate_node_aabb_local(node)
      var copies = int(copies_spinbox.value) if copies_spinbox else 20
      var base_pos = node.global_position

      for i in range(1, copies):
        var offset_world = node.global_transform.basis * (axis_vec * (i * spacing))
        var target_pos = base_pos + offset_world
        var xform = Transform3D(node.global_transform.basis, target_pos)
        _draw_wireframe_box_3d(im, local_aabb, xform, Color(0.2, 0.85, 1.0, 0.9))

      # Span line
      if copies > 1:
        var total_offset = node.global_transform.basis * (axis_vec * ((copies - 1) * spacing))
        im.surface_set_color(Color(1.0, 0.85, 0.2, 0.75))
        im.surface_add_vertex(base_pos)
        im.surface_add_vertex(base_pos + total_offset)

  elif nodes.size() > 1:
    var sorted_nodes = nodes.duplicate()
    if abs(axis_vec.x) > 0.001:
      sorted_nodes.sort_custom(
        func(a, b):
          return (a as Node3D).position.x < (b as Node3D).position.x,
      )
    elif abs(axis_vec.y) > 0.001:
      sorted_nodes.sort_custom(
        func(a, b):
          return (a as Node3D).position.y < (b as Node3D).position.y,
      )
    elif abs(axis_vec.z) > 0.001:
      sorted_nodes.sort_custom(
        func(a, b):
          return (a as Node3D).position.z < (b as Node3D).position.z,
      )

    var first_node = sorted_nodes[0] as Node3D
    var start_pos = first_node.position

    for i in range(sorted_nodes.size()):
      var node = sorted_nodes[i] as Node3D
      if not node:
        continue
      var local_aabb = _calculate_node_aabb_local(node)
      var target_pos = start_pos + (axis_vec * (i * spacing))
      if abs(axis_vec.x) < 0.001:
        target_pos.x = node.position.x
      if abs(axis_vec.y) < 0.001:
        target_pos.y = node.position.y
      if abs(axis_vec.z) < 0.001:
        target_pos.z = node.position.z

      var parent_xform = node.get_parent_node_3d().global_transform if node.get_parent_node_3d() else Transform3D.IDENTITY
      var global_target_pos = parent_xform * target_pos
      var xform = Transform3D(node.global_transform.basis, global_target_pos)
      _draw_wireframe_box_3d(im, local_aabb, xform, Color(0.2, 0.95, 0.6, 0.9))

  im.surface_end()

  var mat = StandardMaterial3D.new()
  mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.vertex_color_use_as_albedo = true
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.no_depth_test = true
  im.surface_set_material(0, mat)

  _preview_mesh_instance.mesh = im


func _calculate_node_aabb_local(node: Node3D) -> AABB:
  var aabb = AABB()
  var has_mesh = false
  var meshes: Array[MeshInstance3D] = []
  _find_mesh_instances(node, meshes)

  for mi in meshes:
    if mi.mesh:
      var mesh_aabb = mi.get_aabb()
      var rel_xform = node.global_transform.affine_inverse() * mi.global_transform
      var transformed_aabb = rel_xform * mesh_aabb
      if not has_mesh:
        aabb = transformed_aabb
        has_mesh = true
      else:
        aabb = aabb.merge(transformed_aabb)

  if not has_mesh:
    aabb = AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1.0, 1.0, 1.0))

  return aabb


func _find_mesh_instances(node: Node, out_meshes: Array[MeshInstance3D]) -> void:
  if node is MeshInstance3D:
    out_meshes.append(node)
  for child in node.get_children():
    _find_mesh_instances(child, out_meshes)


func _draw_wireframe_box_3d(
  im: ImmediateMesh,
  aabb: AABB,
  xform: Transform3D,
  color: Color,
) -> void:
  var p = aabb.position
  var s = aabb.size

  var v = [
    xform * (p),
    xform * (p + Vector3(s.x, 0, 0)),
    xform * (p + Vector3(s.x, 0, s.z)),
    xform * (p + Vector3(0, 0, s.z)),
    xform * (p + Vector3(0, s.y, 0)),
    xform * (p + Vector3(s.x, s.y, 0)),
    xform * (p + Vector3(s.x, s.y, s.z)),
    xform * (p + Vector3(0, s.y, s.z)),
  ]

  im.surface_set_color(color)
  # Bottom
  im.surface_add_vertex(v[0])
  im.surface_add_vertex(v[1])
  im.surface_add_vertex(v[1])
  im.surface_add_vertex(v[2])
  im.surface_add_vertex(v[2])
  im.surface_add_vertex(v[3])
  im.surface_add_vertex(v[3])
  im.surface_add_vertex(v[0])
  # Top
  im.surface_add_vertex(v[4])
  im.surface_add_vertex(v[5])
  im.surface_add_vertex(v[5])
  im.surface_add_vertex(v[6])
  im.surface_add_vertex(v[6])
  im.surface_add_vertex(v[7])
  im.surface_add_vertex(v[7])
  im.surface_add_vertex(v[4])
  # Verticals
  im.surface_add_vertex(v[0])
  im.surface_add_vertex(v[4])
  im.surface_add_vertex(v[1])
  im.surface_add_vertex(v[5])
  im.surface_add_vertex(v[2])
  im.surface_add_vertex(v[6])
  im.surface_add_vertex(v[3])
  im.surface_add_vertex(v[7])


func _update_preview_2d(nodes: Array[Node], scene_root: Node, spacing: float) -> void:
  if is_instance_valid(_preview_mesh_instance):
    _preview_mesh_instance.queue_free()
    _preview_mesh_instance = null

  if not is_instance_valid(_preview_canvas_item):
    _preview_canvas_item = Node2D.new()
    _preview_canvas_item.name = "__ArrayToolPreview2D__"
    scene_root.add_child(_preview_canvas_item)

  var axis_vec = _get_axis_vector_2d()
  var rects_to_draw: Array[Dictionary] = []

  if nodes.size() == 1:
    var node = nodes[0]
    var base_pos: Vector2 = node.global_position if node is Node2D else (node as Control).global_position
    var node_rect = _get_node_2d_rect(node)
    var copies = int(copies_spinbox.value) if copies_spinbox else 20

    for i in range(1, copies):
      var target_pos = base_pos + (axis_vec * (i * spacing))
      var r = Rect2(target_pos + node_rect.position, node_rect.size)
      rects_to_draw.append({ "rect": r, "color": Color(0.2, 0.85, 1.0, 0.9) })

  elif nodes.size() > 1:
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

    var first_pos: Vector2 = sorted_nodes[0].position
    for i in range(sorted_nodes.size()):
      var node = sorted_nodes[i]
      var node_rect = _get_node_2d_rect(node)
      var target_pos = first_pos + (axis_vec * (i * spacing))
      if abs(axis_vec.x) < 0.001:
        target_pos.x = node.position.x
      if abs(axis_vec.y) < 0.001:
        target_pos.y = node.position.y

      var parent_node = node.get_parent()
      var global_target = parent_node.to_global(target_pos) if parent_node is CanvasItem else target_pos
      var r = Rect2(global_target + node_rect.position, node_rect.size)
      rects_to_draw.append({ "rect": r, "color": Color(0.2, 0.95, 0.6, 0.9) })

  _preview_canvas_item.set_script(null)
  _preview_canvas_item.queue_redraw()
  _preview_canvas_item.draw.connect(
    func():
      for item in rects_to_draw:
        _preview_canvas_item.draw_rect(item["rect"], item["color"], false, 2.0),
    CONNECT_ONE_SHOT,
  )


func _get_node_2d_rect(node: Node) -> Rect2:
  if node is Sprite2D and node.texture:
    var sz = node.texture.get_size()
    return Rect2(-sz * 0.5, sz)
  elif node is Control:
    return Rect2(Vector2.ZERO, node.size)
  return Rect2(Vector2(-16, -16), Vector2(32, 32))

# ==============================================================================
# Execution & Recursive Ownership Cloning
# ==============================================================================


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
    ur.add_do_method(self, "_set_owner_recursive", dup, scene_root)
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
    ur.add_do_method(self, "_set_owner_recursive", dup, scene_root)
    ur.add_undo_method(parent, "remove_child", dup)
  ur.commit_action()

  var sel = _plugin.get_editor_interface().get_selection()
  if sel:
    sel.clear()
    sel.add_node(orig_node)
    for dup in created_nodes:
      sel.add_node(dup)


func _set_owner_recursive(node: Node, scene_root: Node) -> void:
  if not is_instance_valid(node) or not is_instance_valid(scene_root):
    return
  node.owner = scene_root
  for child in node.get_children():
    if node.scene_file_path.is_empty():
      _set_owner_recursive(child, scene_root)
