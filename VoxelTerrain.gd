extends VoxelTerrain

var view_distance = 256

@onready var world = get_node("..")
@onready var camera = get_node("../Camera3D")
@onready var voxel_tool = get_node("../VoxelTerrain").get_voxel_tool()

func _ready():
	max_view_distance = view_distance
	get_node("../Camera3D/VoxelViewer").view_distance = view_distance
	stream = VoxelStreamSQLite.new()
	stream.database_path = "MapSave"

func _on_tree_exited():
	save_modified_blocks()

#func _input(event):
#	# Receives key input
#	if event is InputEventKey:
#		match event.keycode:
#			KEY_K:
#				create_cube()

func create_cube():
	var buffer = VoxelBuffer.new()
	var size = 10
	buffer.create(size, size, size)
	
	var camera_pos = camera.get_global_transform().origin
	var sdf_mask = 1 << VoxelBuffer.CHANNEL_SDF
	var sdf_channel = VoxelBuffer.CHANNEL_SDF
#	voxel_tool.copy(camera_pos, buffer, sdf_channel)

	var map_pos = Vector3i(camera_pos)
	map_pos.x -= size / 2.0
	map_pos.y -= size / 2.0
	map_pos.z -= size / 2.0
	voxel_tool.copy(map_pos, buffer, sdf_mask)
	
	var air_value = 1.0
	
	for x in size:
		for y in size:
			for z in size:
				buffer.set_voxel_f(air_value, x, y, z, sdf_channel)
	
	
#	buffer.fill_f(air_value, VoxelBuffer.CHANNEL_SDF)
	
	voxel_tool.paste(map_pos, buffer, sdf_mask, 0xffffffff)
