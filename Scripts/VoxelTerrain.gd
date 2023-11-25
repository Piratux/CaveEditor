extends VoxelTerrain

# Distance upon which voxels will be rendered
var view_distance = 256

func _ready():
	max_view_distance = view_distance
	get_node("../Camera3D/VoxelViewer").view_distance = view_distance
	stream = VoxelStreamSQLite.new()
	stream.database_path = ".editor/autosave.world"

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_K:
					save_modified_blocks()
					stream = VoxelStreamSQLite.new()
					stream.database_path = ".editor/autosave.world"
				KEY_L:
					save_modified_blocks()
					stream = VoxelStreamSQLite.new()
					stream.database_path = ".editor/test.world"

func _on_tree_exited():
	save_modified_blocks()
