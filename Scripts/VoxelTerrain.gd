extends VoxelTerrain

@onready var voxel_viewer = get_node("../Camera3D/VoxelViewer")

# Distance upon which voxels will be rendered
var view_distance = 256

func _ready():
	max_view_distance = view_distance
	voxel_viewer.view_distance = view_distance

func _on_tree_exited():
	save_modified_blocks()
	stream = VoxelStreamSQLite.new()
	var file_path = ".editor/" + "file_nametest"
	stream.database_path = file_path

# TODO: fix database transaction error (happens when this function is spammed, though happens rarely)
func set_world_stream(file_name):
	if stream != null:
		var result_tracker = save_modified_blocks()
		while true:
			if result_tracker.is_complete():
				break
			
			await get_tree().create_timer(0.1).timeout
	
	stream = VoxelStreamSQLite.new()
	var file_path = ".editor/" + file_name
	stream.database_path = file_path
