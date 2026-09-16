@tool
extends EditorInspectorPlugin


func _can_handle(object: Object) -> bool:
  return object is Label or object is RichTextLabel


func _parse_begin(object: Object) -> void:
  var control = object as Control
  if not control:
    return

  var container = HBoxContainer.new()
  container.name = "LabelSizePicker"
  container.custom_minimum_size = Vector2(0, 26)
  container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

  var label = Label.new()
  label.text = "Text Size"
  label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  container.add_child(label)

  var option_button = OptionButton.new()
  option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  option_button.add_item("Normal (32px)", 0)
  option_button.add_item("Header (48px)", 1)
  option_button.add_item("Hero Title (64px)", 2)

  var current_variation = control.theme_type_variation
  if current_variation == &"HeaderMedium":
    option_button.selected = 1
  elif current_variation == &"HeaderLarge":
    option_button.selected = 2
  elif current_variation == &"":
    option_button.selected = 0
  else:
    option_button.add_item(str(current_variation), 3)
    option_button.selected = 3

  option_button.item_selected.connect(
    func(index: int) -> void:
      var new_variation: StringName = &""
      match index:
        0:
          new_variation = &""
        1:
          new_variation = &"HeaderMedium"
        2:
          new_variation = &"HeaderLarge"
        _:
          return

      if control.theme_type_variation == new_variation:
        return

      var undo_redo = EditorInterface.get_editor_undo_redo()
      undo_redo.create_action("Change Text Size")
      undo_redo.add_do_property(control, "theme_type_variation", new_variation)
      undo_redo.add_undo_property(control, "theme_type_variation", control.theme_type_variation)
      undo_redo.commit_action(),
  )

  container.add_child(option_button)
  add_custom_control(container)
