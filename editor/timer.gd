@tool
extends RichTextLabel

var settings = EditorInterface.get_editor_settings()

const addon = "com.amcolash.addons"
const idle_time = 60 * 60 # 1 hour
const update_duration = 15

var idle_timer = 0
var paused = false

func _ready() -> void:
  if _is_in_edited_scene():
    return
    
  update_text()
  
  var timer = Timer.new()
  timer.wait_time = update_duration
  timer.autostart = true
  timer.timeout.connect(_on_timer_timeout)
  add_child(timer)

func _is_in_edited_scene() -> bool:
  if not is_inside_tree(): return false
  var edited = get_tree().edited_scene_root
  return edited != null and (edited == self or owner == edited)

func _on_timer_timeout() -> void:
  if get_window().has_focus(): idle_timer = 0
  else: idle_timer += update_duration

  # The timer will idle out after 60 minutes of inactivity
  if idle_timer < idle_time:
    var last_update = settings.get_project_metadata(addon, "timer_last_update", 0)
    var time = int(Time.get_unix_time_from_system())

    # last updated check to prevent multiple recordings from script in editor + sidebar
    if time > last_update + update_duration / 2.0:
      var dictionary = settings.get_project_metadata(addon, "timer", {})
      var datetime = Time.get_datetime_dict_from_system()
      var key = str(datetime.year) + "/" + str(datetime.month) + "/" + str(datetime.day)

      dictionary[key] = dictionary.get(key, 0) + update_duration

      settings.set_project_metadata(addon, "timer", dictionary)
      settings.set_project_metadata(addon, "timer_last_update", time)

    paused = false
  else:
    paused = true

  update_text()

func format_time(time: float) -> float:
  return snapped(time, 0.1)

func update_text():
  var dictionary = settings.get_project_metadata(addon, "timer", {})

  var datetime = Time.get_datetime_dict_from_system()
  var today_key = str(datetime.year) + "/" + str(datetime.month) + "/" + str(datetime.day)

  var time = 0
  for key in dictionary:
    time += dictionary[key]

  text = ""
  if paused: text += "[Paused]\n\n"

  var today = format_time(dictionary.get(today_key, 0) / 60.0 / 60.0)
  var hours = format_time(time / 60.0 / 60.0)
  var days = format_time(time / 60.0 / 60.0 / 8.0)
  var percentage = format_time(hours  / 300.0 * 100)

  text += "[b]" + str(today) + "[/b]" + " hours today"
  text += "\n\n[b]" + str(hours) + "[/b]" + " hours total"
  text += "\n" + "[b]" + str(days) + "[/b]" + " workdays"
  text += "\n" + "[b]" + str(percentage) + "%[/b]" + " of 300 hours"
