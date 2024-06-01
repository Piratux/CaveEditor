class_name ToolMeshBakeState
extends Resource

const SDF_MESH_STATE = preload("res://Scripts/SdfMeshStateEnum.gd").SDF_MESH_STATE

signal sdf_mesh_index_updated(new_value)
signal bake_mode_updated(new_value)
signal boundary_sign_fix_enabled_updated(new_value)

var bake_mode := VoxelMeshSDF.BAKE_MODE_ACCURATE_PARTITIONED : set = set_bake_mode
var boundary_sign_fix_enabled := true : set = set_boundary_sign_fix_enabled
var cell_count := 64 : set = set_cell_count, get = get_cell_count
var partition_subdiv := 32 : set = set_partition_subdiv, get = get_partition_subdiv

var _selected_sdf_mesh_idx := 0 : set = set_selected_sdf_mesh_idx # PRIVATE
var _sdf_meshes = [] # PRIVATE
var _parameter_sliders = {} # PRIVATE

# TODO This is not supposed to be a requirement.
# Check source code of `VoxelMeshSDF` to see why scene root is necessary...
var _scene_root = null # PRIVATE

func get_slider_value(parameter_name):
	if (_parameter_sliders.has(parameter_name)):
		return _parameter_sliders[parameter_name].get_value()
	
	return null

func set_slider_value(new_value, parameter_name):
	_parameter_sliders[parameter_name].set_value(new_value)

func set_cell_count(value):
	set_slider_value(value, "cell_count")

func get_cell_count() -> int:
	return get_slider_value("cell_count")

func set_partition_subdiv(value):
	set_slider_value(value, "partition_subdiv")

func get_partition_subdiv() -> int:
	return get_slider_value("partition_subdiv")

func set_selected_sdf_mesh_idx(value):
	_selected_sdf_mesh_idx = value
	
	# During initialisation, parameter container may not be initialised yet
	if _parameter_sliders.is_empty():
		return
	
	var sdf_mesh = get_sdf_mesh(value)
	bake_mode = sdf_mesh.bake_mode
	boundary_sign_fix_enabled = sdf_mesh.boundary_sign_fix_enabled
	cell_count = sdf_mesh.cell_count
	partition_subdiv = sdf_mesh.partition_subdiv
	
	sdf_mesh_index_updated.emit(value)

func set_boundary_sign_fix_enabled(value):
	boundary_sign_fix_enabled = value
	boundary_sign_fix_enabled_updated.emit(value)

func set_bake_mode(value: VoxelMeshSDF.BakeMode):
	# TODO: enforce valid value through enums
	var total_bake_modes = VoxelMeshSDF.BAKE_MODE_COUNT
	if not (value >= 0 && value < total_bake_modes):
		print("Invalid bake mode selected")
		return
	
	bake_mode = value
	bake_mode_updated.emit(value)

func add_sdf_mesh(mesh):
	var sdf_mesh = VoxelMeshSDF.new()
	sdf_mesh.mesh = mesh
	sdf_mesh.baked.connect(baking_finished.bind(_sdf_meshes.size()))
	_sdf_meshes.push_back(sdf_mesh)

func get_selected_sdf_mesh():
	assert(total_sdf_meshes() > 0)
	
	return get_sdf_mesh(_selected_sdf_mesh_idx)

func get_sdf_mesh(index):
	return _sdf_meshes[index]

func bake_selected_sdf_mesh():
	bake_sdf_mesh(_selected_sdf_mesh_idx)
	
func bake_sdf_mesh(index):
	assert(_scene_root)
	
	var sdf_mesh = get_sdf_mesh(index)
	sdf_mesh.bake_mode = bake_mode
	sdf_mesh.boundary_sign_fix_enabled = boundary_sign_fix_enabled
	sdf_mesh.cell_count = cell_count
	sdf_mesh.partition_subdiv = partition_subdiv
	sdf_mesh.bake_async.call_deferred(_scene_root)
	print("Building mesh SDF " + str(index) + "...")

func bake_all_sdf_meshes():
	for idx in _sdf_meshes.size():
		bake_sdf_mesh(idx)

func baking_finished(index):
	print("Building mesh SDF " + str(index) + " done")
	
	# Debug
	var mesh_sdf = get_sdf_mesh(index)
	var images = mesh_sdf.get_voxel_buffer().debug_print_sdf_y_slices(1.0)
	for i in len(images):
		var im = images[i]
		
		var path = ".debug_data"
		DirAccess.make_dir_absolute(path)
		
		# TODO: delete folder first, to clear it from previous baking
		var subpath = str(path, "/sdf_slice_", index)
		DirAccess.make_dir_absolute(subpath)
		
		var fpath = str(subpath, "/", i, ".png")
		var err = im.save_png(fpath)
		if err != OK:
			push_error(str("Could not save image ", fpath, ", error ", err))

func select_next_sdf_mesh():
	set_selected_sdf_mesh_idx((_selected_sdf_mesh_idx + 1) % _sdf_meshes.size())

func select_previous_sdf_mesh():
	set_selected_sdf_mesh_idx((_selected_sdf_mesh_idx - 1 + _sdf_meshes.size()) % _sdf_meshes.size())

func get_selected_sdf_mesh_state():
	assert(total_sdf_meshes() > 0)

	var sdf_mesh = get_selected_sdf_mesh()
	
	if sdf_mesh.is_baking():
		return SDF_MESH_STATE.BAKING
	elif (sdf_mesh.bake_mode != bake_mode
		|| sdf_mesh.boundary_sign_fix_enabled != boundary_sign_fix_enabled
		|| sdf_mesh.cell_count != cell_count
		|| sdf_mesh.partition_subdiv != partition_subdiv
		):
		return SDF_MESH_STATE.BAKING_PARAMETERS_CHANGED
	elif sdf_mesh.is_baked():
		return SDF_MESH_STATE.READY
	else:
		return SDF_MESH_STATE.NOT_BAKED_ONCE

func total_sdf_meshes():
	return _sdf_meshes.size()
