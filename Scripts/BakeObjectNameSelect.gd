extends OptionButton

var file_util = preload("res://Scripts/Utils/FileUtil.gd").new()

@export var tool_mesh_bake_state: ToolMeshBakeState

func _ready():
	for file_name in file_util.get_obj_file_paths():
		add_item(file_name)
		tool_mesh_bake_state.add_sdf_mesh(load(file_name))
	
	_on_item_selected(0) # for some reason select() doesn't triger item_selected signal...
	
	tool_mesh_bake_state.sdf_mesh_index_updated.connect(sdf_mesh_index_updated)

func sdf_mesh_index_updated(index):
	selected = index

func _on_item_selected(index):
	tool_mesh_bake_state._selected_sdf_mesh_idx = index
	select(index)
