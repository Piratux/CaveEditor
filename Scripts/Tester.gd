extends Node

var file_util = preload("res://Scripts/Utils/FileUtil.gd").new()

func _ready():
	perform_tests()

func perform_tests():
	test_accurate_baking_mode_accuracy()

func get_sdf_mesh(bake_mode, mesh):
	var sdf_mesh = VoxelMeshSDF.new()
	sdf_mesh.bake_mode = bake_mode
	sdf_mesh.mesh = mesh
	sdf_mesh.bake()
	return sdf_mesh

func test_accurate_baking_mode_accuracy():
	for file_name in file_util.get_obj_file_paths():
		var mesh = load(file_name)
		#var mesh = null
		var sdf_mesh1 = get_sdf_mesh(VoxelMeshSDF.BAKE_MODE_ACCURATE_NAIVE, mesh)
		var sdf_mesh2 = get_sdf_mesh(VoxelMeshSDF.BAKE_MODE_ACCURATE_PARTITIONED, mesh)
		
		var size = sdf_mesh1.get_voxel_buffer().get_size()
		var voxel_buffer1 = sdf_mesh1.get_voxel_buffer()
		var voxel_buffer2 = sdf_mesh2.get_voxel_buffer()
		
		var mesh_aabb_size = sdf_mesh1.mesh.get_aabb().size
		var max_mesh_aabb_size = max(mesh_aabb_size.x, mesh_aabb_size.y, mesh_aabb_size.z)
		
		var sum = 0
		var sum2 = 0
		var total = 0
		var max_error = 0
		for pos_x in size.x:
			for pos_y in size.y:
				for pos_z in size.z:
					total += 1
					var value1 = voxel_buffer1.get_voxel_f(pos_x, pos_y, pos_z, VoxelBuffer.CHANNEL_SDF)
					var value2 = voxel_buffer2.get_voxel_f(pos_x, pos_y, pos_z, VoxelBuffer.CHANNEL_SDF)
					# Normalise, to avoid seeing bigger errors, for scaled objects
					value1 /= max_mesh_aabb_size
					value2 /= max_mesh_aabb_size
					var diff = abs(value1 - value2)
					sum += diff
					sum2 += diff * diff
					
					max_error = max(max_error, diff)
		
		var size1 = sdf_mesh1.get_voxel_buffer().get_size()
		var size2 = sdf_mesh2.get_voxel_buffer().get_size()
		assert(
			size1.x == size2.x
			and size1.y == size2.y
			and size1.z == size2.z
			, "sizes must match")
		
		print("------------------------------------------")
		print("name: ", file_name)
		print("size: ", size)
		print("total: ", total)
		print("sum: ", sum)
		print("rms: ", sqrt(sum2 / total))
		print("max error: ", max_error)
		print("------------------------------------------")
