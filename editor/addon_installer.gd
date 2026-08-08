@tool
extends VBoxContainer

var addons_to_install = {
  "at-icons": {
    "url": "https://github.com/Voxybuns/at-icons/archive/refs/heads/main.zip",
    "zip_subfolder": "at-icons-main/addons/at-icons"
  },
  "gdscript-formatter": {
    "url": "https://github.com/GDQuest/GDScript-formatter/releases/latest/download/godot-addon.zip",
    "zip_subfolder": "addons/GDQuest_GDScript_formatter"
  },
  "plugin-refresher": {
    "url": "https://github.com/godot-extended-libraries/godot-plugin-refresher/archive/refs/heads/master.zip",
    "zip_subfolder": "godot-plugin-refresher-master/addons/plugin_refresher"
  },
  "godot-git-plugin": {
    "url": "https://github.com/godotengine/godot-git-plugin/releases/download/v3.1.1/godot-git-plugin-v3.1.1.zip",
    "zip_subfolder": "addons/godot-git-plugin"
  }
}

@onready var checkboxes_container = $Checkboxes
@onready var install_button = $InstallButton
@onready var status_label = $StatusLabel

var http_request: HTTPRequest
var download_queue = []
var current_download = ""

func _ready() -> void:
  if _is_in_edited_scene():
    return

  if not Engine.is_editor_hint():
    return
    
  http_request = HTTPRequest.new()
  http_request.use_threads = true
  add_child(http_request)
  http_request.request_completed.connect(_on_http_request_request_completed)
    
  var missing_addons = false
  for addon in addons_to_install:
    var cb = CheckBox.new()
    cb.text = addon
    cb.name = addon
    
    # Check if already installed (using the folder name from zip_subfolder)
    var folder_name = _get_target_folder_name(addon, addons_to_install[addon].zip_subfolder)
    var is_installed = DirAccess.dir_exists_absolute("res://addons/" + folder_name)
    cb.button_pressed = not is_installed
    checkboxes_container.add_child(cb)
    
    if not is_installed:
      missing_addons = true

  if not missing_addons:
    hide()

func _is_in_edited_scene() -> bool:
  if not is_inside_tree(): return false
  var edited = get_tree().edited_scene_root
  return edited != null and (edited == self or owner == edited)

func _on_install_button_pressed() -> void:
  download_queue.clear()
  for cb in checkboxes_container.get_children():
    if cb is CheckBox and cb.button_pressed:
      download_queue.append(cb.name)
  
  if download_queue.size() > 0:
    install_button.disabled = true
    _download_next()
  else:
    status_label.text = "Nothing selected."

func _download_next() -> void:
  if download_queue.is_empty():
    status_label.text = "Finished!"
    install_button.disabled = false
    EditorInterface.get_resource_filesystem().scan()
    return
    
  current_download = download_queue.pop_front()
  status_label.text = "Downloading " + current_download + "..."
  
  var url = addons_to_install[current_download].url
  var err = http_request.request(url)
  if err != OK:
    status_label.text = "Error requesting " + current_download
    _download_next()

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
  if response_code != 200:
    status_label.text = "Failed: " + current_download + " (HTTP " + str(response_code) + ")"
    _download_next()
    return
    
  status_label.text = "Extracting " + current_download + "..."
  
  var temp_zip = "user://temp_addon.zip"
  var f = FileAccess.open(temp_zip, FileAccess.WRITE)
  f.store_buffer(body)
  f.close()
  
  var reader = ZIPReader.new()
  var err = reader.open(temp_zip)
  if err != OK:
    status_label.text = "Error opening zip for " + current_download
    _download_next()
    return
    
  var prefix = addons_to_install[current_download].zip_subfolder
  var dest_dir = "res://addons/" + _get_target_folder_name(current_download, prefix)
  
  if not DirAccess.dir_exists_absolute("res://addons"):
    DirAccess.make_dir_absolute("res://addons")
    
  for file in reader.get_files():
    if file.begins_with(prefix) and file != prefix and not file.ends_with("/"):
      var relative_path = file.substr(prefix.length())
      if relative_path.begins_with("/"):
        relative_path = relative_path.substr(1)
      
      var target_path = dest_dir + "/" + relative_path
      var dir = target_path.get_base_dir()
      if not DirAccess.dir_exists_absolute(dir):
        DirAccess.make_dir_recursive_absolute(dir)
        
      var content = reader.read_file(file)
      var out = FileAccess.open(target_path, FileAccess.WRITE)
      if out:
        out.store_buffer(content)
        out.close()
  
  reader.close()
  DirAccess.remove_absolute(temp_zip)
  
  _download_next()

func _get_target_folder_name(addon_name: String, prefix: String) -> String:
  return prefix.get_file()
