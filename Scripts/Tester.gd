extends Node

@onready var file = FileAccess.open("test.txt", FileAccess.WRITE)
@onready var audio_player = $"../AudioStreamPlayer2D"

var file_util = preload("res://Scripts/Utils/FileUtil.gd").new()

func _ready():
	perform_tests()
	
	file.close()
	
	audio_player.volume_db = 10
	audio_player.play()
	pass

func perform_tests():
	#test_accurate_baking_mode_accuracy(64, 32)
	
	#if true:
		#var cell_counts = [2, 128]
		#var partition_subdivs = [16,24,32,40,48,56,64]
		#for c in cell_counts:
			#for p in partition_subdivs:
				#test_accurate_partitioned_baking_speed(c, p)
	
	if true:
		#var cell_counts = [32, 64, 96, 128]
		#var cell_counts = [16, 32, 48, 64, 128, 255]
		var cell_counts = [16, 32, 48]
		for c in cell_counts:
			test_all_baking_speed(c)

	pass

func get_sdf_mesh(bake_mode, mesh, cell_count, partition_subdiv):
	var sdf_mesh = VoxelMeshSDF.new()
	sdf_mesh.bake_mode = bake_mode
	sdf_mesh.mesh = mesh
	sdf_mesh.cell_count = cell_count
	sdf_mesh.partition_subdiv = partition_subdiv
	sdf_mesh.bake()
	return sdf_mesh

func test_accurate_baking_mode_accuracy(cell_count, partition_subdiv):
	for file_name in file_util.get_obj_file_paths():
		var mesh = load(file_name)
		#var mesh = null
		var baking_modes = [
			#VoxelMeshSDF.BAKE_MODE_ACCURATE_NAIVE,
			VoxelMeshSDF.BAKE_MODE_ACCURATE_PARTITIONED,
			VoxelMeshSDF.BAKE_MODE_APPROX_INTERP,
			VoxelMeshSDF.BAKE_MODE_APPROX_FLOODFILL,
		]
		for baking_mode in baking_modes:
			var sdf_mesh1 = get_sdf_mesh(VoxelMeshSDF.BAKE_MODE_ACCURATE_NAIVE, mesh, cell_count, partition_subdiv)
			var sdf_mesh2 = get_sdf_mesh(baking_mode, mesh, cell_count, partition_subdiv)
			
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
			
			var rms = sqrt(sum2 / total)
			file.store_string(str(rms, " ", max_error, " ", baking_mode, " ", file_name, "\n"))
			print("------------------------------------------")
			print("name: ", file_name)
			print("size: ", size)
			print("total: ", total)
			print("sum: ", sum)
			print("rms: ", rms)
			print("max error: ", max_error)
			print("cell_count: ", cell_count)
			print("partition_subdiv: ", partition_subdiv)
			print("------------------------------------------")

func get_sdf_mesh_timed(bake_mode, mesh, cell_count, partition_subdiv):
	var sdf_mesh = VoxelMeshSDF.new()
	sdf_mesh.bake_mode = bake_mode
	sdf_mesh.mesh = mesh
	sdf_mesh.cell_count = cell_count
	sdf_mesh.partition_subdiv = partition_subdiv
	
	var time_before = Time.get_ticks_msec()
	sdf_mesh.bake()
	var time_after = Time.get_ticks_msec()
	var delta_time = time_after - time_before
	
	return [sdf_mesh, delta_time]

func test_all_baking_speed(cell_count):
	for file_name in file_util.get_obj_file_paths():
		var mesh = load(file_name)
		
		var baking_modes = [
			VoxelMeshSDF.BAKE_MODE_ACCURATE_NAIVE,
			#VoxelMeshSDF.BAKE_MODE_ACCURATE_PARTITIONED,
			#VoxelMeshSDF.BAKE_MODE_APPROX_INTERP,
			#VoxelMeshSDF.BAKE_MODE_APPROX_FLOODFILL,
		]
		for baking_mode in baking_modes:
			var result = get_sdf_mesh_timed(baking_mode, mesh, cell_count, 32)
			var sdf_mesh = result[0]
			var delta_time = result[1]
			
			file.store_string(str(cell_count, " ", delta_time, "\n"))
			print("------------------------------------------")
			print("size: ", sdf_mesh.get_voxel_buffer().get_size())
			print("name: ", file_name)
			print("cell_count: ", cell_count)
			print("delta_time ms: ", delta_time)
			print("------------------------------------------")

func test_accurate_partitioned_baking_speed(cell_count, partition_subdiv):
	for file_name in file_util.get_obj_file_paths():
		var mesh = load(file_name)
		
		var result = get_sdf_mesh_timed(VoxelMeshSDF.BAKE_MODE_ACCURATE_PARTITIONED, mesh, cell_count, partition_subdiv)
		#var sdf_mesh = result[0]
		var delta_time = result[1]
		
		file.store_string(str(cell_count, " ", partition_subdiv, " ", delta_time, "\n"))
		print("------------------------------------------")
		print("name: ", file_name)
		print("cell_count: ", cell_count)
		print("partition_subdiv: ", partition_subdiv)
		print("delta_time ms: ", delta_time)
		print("------------------------------------------")
