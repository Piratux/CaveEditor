extends OptionButton

var file_util = preload("res://Scripts/Utils/FileUtil.gd").new()

@export var tool_mesh_bake_state: ToolMeshBakeState

func _ready():
	for file_path in file_util.get_external_obj_file_paths():
		add_external_obj_file(file_path)
	
	for file_path in file_util.get_internal_obj_file_paths():
		add_internal_obj_file(file_path)
	
	if tool_mesh_bake_state.total_sdf_meshes() > 0:
		_on_item_selected(0) # for some reason select() doesn't triger item_selected signal...
	
	tool_mesh_bake_state.sdf_mesh_index_updated.connect(sdf_mesh_index_updated)

func add_external_obj_file(file_path):
	add_item(file_path.get_file())
	var mesh = ObjExporter.load_mesh_from_file(file_path)
	tool_mesh_bake_state.add_sdf_mesh(mesh)

func add_internal_obj_file(file_path):
	add_item(file_path.get_file())
	var mesh = load(file_path)
	tool_mesh_bake_state.add_sdf_mesh(mesh)

func sdf_mesh_index_updated(index):
	selected = index

func _on_item_selected(index):
	tool_mesh_bake_state._selected_sdf_mesh_idx = index
	select(index)

func _on_mesh_export_dialog_file_selected(path):
	# Avoid adding duplicate objects
	for i in item_count:
		if get_item_text(i) == path.get_file():
			print("ERROR: File with name '", path.get_file(), "' is already imported")
			return
	
	DirAccess.make_dir_absolute(".editor/Objects")
	var path_to = DirAccess.open(".").get_current_dir() + "/.editor/Objects/" + path.get_file()
	DirAccess.copy_absolute(path, path_to)
	
	add_external_obj_file(path_to)
