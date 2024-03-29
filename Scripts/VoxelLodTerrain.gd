extends VoxelLodTerrain

const SDFStamper = preload("./SdfStamper.gd")

@onready var voxel_viewer = get_node("../Camera3D/VoxelViewer")
@onready var sdf_stamper : SDFStamper = get_node("../SdfStamper")

# Distance upon which voxels will be rendered
var _view_distance = 256

func _ready():
	view_distance = _view_distance
	voxel_viewer.view_distance = _view_distance
	sdf_stamper.set_terrain(self)

func _on_tree_exited():
	save_modified_blocks()
	stream = VoxelStreamSQLite.new()
	var file_path = ".editor/" + "file_nametest"
	stream.database_path = file_path

# TODO: fix database transaction error (happens when this function is spammed, though happens rarely)
func set_world_stream(file_name, save_edited_blocks):
	if stream != null and save_edited_blocks:
		var result_tracker = save_modified_blocks()
		while true:
			if result_tracker.is_complete():
				break
			
			# TODO: come up with a way to synchronously wait for block saving to be
			# completed as that simplifies things and prevents accidental issues
			await get_tree().create_timer(0.1).timeout
	
	stream = VoxelStreamSQLite.new()
	var file_path = ".editor/" + file_name
	stream.database_path = file_path
