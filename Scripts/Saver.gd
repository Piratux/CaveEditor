# ABOUT
# Responsible for saving/loading editor and world data to/from file

extends Node

@onready var camera = get_node("../Camera3D")
@onready var world_manager = get_node("../CanvasLayer/WorldManager")

var editor_data = {
	last_world = "autosave",
	worlds = ["autosave"],
}

var world_data = {
	name = "autosave",
	camera_pos = null,
	camera_rot = null,
}

func _ready():
	DirAccess.make_dir_absolute(".editor")
	
	load_editor_data()
	load_current_world_data()

func _notification(what):
	# notification on program exit
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_editor_data()
		save_current_world_data()
		get_tree().quit()

func vec3_from_string(vec3_string):
	var components = vec3_string.replace("(", "").replace(")", "").split(",")

	# Convert the string components to floats and create a Vector3
	return Vector3(
		float(components[0].strip_edges()),  # x
		float(components[1].strip_edges()),  # y
		float(components[2].strip_edges())   # z
	)

func save_json_to_file(file_name, data):
	var file_path = ".editor/" + file_name + ".json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	var json_string = JSON.stringify(data)
	file.store_line(json_string)

func load_json_from_file(file_name):
	var file_path = ".editor/" + file_name + ".json"
	if not FileAccess.file_exists(file_path):
		return

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_line()

	# Creates the helper class to interact with JSON
	var json = JSON.new()

	# Check if there is any error while parsing the JSON string, skip in case of failure
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return null

	# TODO: handle when json doesn't have all fields
	return json.get_data()

func save_editor_data():
	save_json_to_file("editor", editor_data)

func load_editor_data():
	var data = load_json_from_file("editor")
	if data == null:
		return
	
	editor_data = data

func save_current_world_data():
	world_data.name = "autosave"
	world_data.camera_pos = camera.transform.origin
	world_data.camera_rot = camera.basis.get_euler()

	save_json_to_file("autosave", world_data)

func load_current_world_data():
	var data = load_json_from_file("autosave")
	if data == null:
		return
	
	world_data = data

	var camera_pos = vec3_from_string(world_data.camera_pos)
	var camera_rot = vec3_from_string(world_data.camera_rot)
	camera.transform.origin = camera_pos
	camera.basis = camera.basis.from_euler(camera_rot)
