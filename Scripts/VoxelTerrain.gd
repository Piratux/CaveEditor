extends VoxelTerrain

# Distance upon which voxels will be rendered
var view_distance = 256

func _ready():
	max_view_distance = view_distance
	get_node("../Camera3D/VoxelViewer").view_distance = view_distance
	stream = VoxelStreamSQLite.new()
	stream.database_path = "MapSave"

func _on_tree_exited():
	save_modified_blocks()
