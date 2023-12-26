# ABOUT
# Responsible for saving/loading editor and world data to/from file

# TODO: add periodic modified block saving

extends Node

@onready var camera = get_node("../Camera3D")
@onready var world_manager = get_node("../CanvasLayer/WorldManager")
@onready var voxel_terrain = get_node("../VoxelTerrain")
@onready var voxel_tool = voxel_terrain.get_voxel_tool()
@onready var current_world_label = get_node("../CanvasLayer/MenuMarginContainer/VBoxContainer/CurrentWorld")

var editor_data = {
	last_world_id = null,
	worlds = {
		"1": {
			name = "autosave",
			file_name = "1.world",
			camera_pos = null,
			camera_rot = null,
		}
	}
}

var default_camera_data = {
	pos = Vector3(0,0,0),
	rot = Vector3(0,0,0),
}

func _ready():
	DirAccess.make_dir_absolute(".editor")

func create_world_id():
	var new_id = 1
	while true:
		var string_id = String.num_uint64(new_id)
		if !editor_data.worlds.has(string_id):
			return string_id
			
		new_id += 1

func load_data():
	load_editor_data()

func get_last_world_id():
	return editor_data.last_world_id

func set_last_world_id(world_id):
	editor_data.last_world_id = world_id

func get_world(world_id):
	return editor_data.worlds[world_id]

func set_world(world_id, world):
	editor_data.worlds[world_id] = world

func get_world_id_by_name(world_name):
	for id in editor_data.worlds.keys():
		var world = editor_data.worlds[id]
		
		if world.name == world_name:
			return id
	
	return null

func _notification(what):
	# notification on program exit
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_world_data(get_last_world_id())
		save_editor_data()
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
	if data != null:
		editor_data = data
	
	for id in editor_data.worlds.keys():
		var world = get_world(id)
		
		if world.has("camera_pos") and world.camera_pos != null:
			world.camera_pos = vec3_from_string(world.camera_pos)
		
		if world.has("camera_rot") and world.camera_rot != null:
			world.camera_rot = vec3_from_string(world.camera_rot)
	
	load_worlds_to_world_manager()
	if get_last_world_id() == null:
		load_world(editor_data.worlds.keys()[0])
	else:
		load_world(get_last_world_id())

func save_world_data(world_id):
	print("save_world_data: " + world_id)
	var world = get_world(world_id)
	world.camera_pos = camera.transform.origin
	world.camera_rot = camera.basis.get_euler()

func load_world_data(world_id):
	print("load_world_data: " + world_id)
	var world = get_world(world_id)
	
	if world.has("camera_pos") and world.camera_pos != null:
		camera.transform.origin = world.camera_pos
		
	if world.has("camera_rot") and world.camera_rot != null:
		camera.basis = camera.basis.from_euler(world.camera_rot)

func load_worlds_to_world_manager():
	var worlds_to_add = editor_data.worlds.duplicate()
	for world_id in worlds_to_add.keys():
		var world = get_world(world_id)
		world_manager.add_new_world(world.name)

func add_new_world(world_name):
	var new_id = create_world_id()
	editor_data.worlds[new_id] = {}
	editor_data.worlds[new_id].name = world_name
	editor_data.worlds[new_id].file_name = new_id + ".world"
	editor_data.worlds[new_id].camera_pos = Vector3(default_camera_data.pos)
	editor_data.worlds[new_id].camera_rot = Vector3(default_camera_data.pos)

func delete_world(world_name):
	var world_id = get_world_id_by_name(world_name)
	var world_file_name = get_world(world_id).file_name
	if world_id == get_last_world_id():
		for id in editor_data.worlds.keys():
			if id != world_id:
				load_world(id)
				break
	
	editor_data.worlds.erase(world_id)
	DirAccess.remove_absolute(".editor/" + world_file_name)

func load_world_by_name(world_name):
	var world_id = get_world_id_by_name(world_name)
	load_world(world_id)

func load_world(world_id):
	print("load_world")
	var last_world_id = get_last_world_id()
	if last_world_id != null and last_world_id != world_id:
		save_world_data(get_last_world_id())
	
	var world = get_world(world_id)
	var file_name = world_id + ".world"
	voxel_terrain.set_world_stream(file_name)
	load_world_data(world_id)
	set_last_world_id(world_id)
	current_world_label.text = "World: " + world.name
	
	
	print("load_world12")

func rename_world(old_name, new_name):
	var world_id = get_world_id_by_name(old_name)
	var world = get_world(world_id)
	world.name = new_name

func endsWithGltf(path: String) -> bool:
	var extension: String = ".gltf"
	var strLength: int = path.length()
	var extLength: int = extension.length()
	
	# Check if the string is long enough to contain the extension
	if strLength < extLength:
		return false
	
	# Extract the last characters of the string with the length of the extension
	var endOfString: String = path.right(extLength)
	
	# Compare the extracted portion with the extension
	return endOfString == extension

func export_world_mesh(path):
	# Should be less than viewing distance, otherwise mesh is insanely large
	var buffer_size = Vector3i(500, 500, 500)
	var buffer_start_pos = Vector3i(camera.transform.origin) - Vector3i(250,250,250)
	
	var buffer = VoxelBuffer.new()
	buffer.create(buffer_size.x, buffer_size.y, buffer_size.z)
	
	var sdf_channel = 1 << VoxelBuffer.CHANNEL_SDF
	voxel_tool.copy(buffer_start_pos, buffer, sdf_channel)
	
	var mesh = voxel_terrain.mesher.build_mesh(buffer, [])
	
	# add mesh
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(camera.position)
	
	var gltf := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	
	gltf.append_from_scene(mesh_instance, gltf_state)
	
	if endsWithGltf(path):
		gltf.write_to_filesystem(gltf_state, path)
	else:
		gltf.write_to_filesystem(gltf_state, str(path, ".gltf"))
