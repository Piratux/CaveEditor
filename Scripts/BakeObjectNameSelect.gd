extends OptionButton

@export var tool_mesh_bake_state: ToolMeshBakeState

var root_obj_folder = "res://Objects"

func get_obj_file_paths(path):
	var path_list = []
	var dir = DirAccess.open(path)
	if !dir:
		print("An error occurred when trying to access the path.")
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".obj"):
			path_list.push_back(path + "/" + file_name)
			print("Adding mesh file: " + file_name)
		file_name = dir.get_next()
	
	return path_list

func _ready():
	for file_name in get_obj_file_paths(root_obj_folder):
		add_item(file_name)
		tool_mesh_bake_state.add_sdf_mesh(load(file_name))
	
	_on_item_selected(0) # for some reason select() doesn't triger item_selected signal...

func _on_item_selected(index):
	tool_mesh_bake_state._selected_sdf_mesh_idx = index
	select(index)
