class_name ToolMeshBakeState
extends Resource

signal bake_mode_updated(new_value)
signal bake_finished(sdf_mesh)

var bake_mode := VoxelMeshSDF.BAKE_MODE_ACCURATE_PARTITIONED : set = set_bake_mode

var _selected_sdf_mesh_idx := 0 # PRIVATE
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
	return get_sdf_mesh(_selected_sdf_mesh_idx)

func get_sdf_mesh(index):
	return _sdf_meshes[index]

func bake_selected_sdf_mesh():
	bake_sdf_mesh(_selected_sdf_mesh_idx)
	
func bake_sdf_mesh(index):
	assert(_scene_root)
	
	var sdf_mesh = get_sdf_mesh(index)
	sdf_mesh.cell_count = get_slider_value("cell_count")
	sdf_mesh.partition_subdiv = get_slider_value("partition_subdiv")
	sdf_mesh.bake_mode = bake_mode
	sdf_mesh.bake_async.call_deferred(_scene_root)
	print("Building mesh SDF " + str(index) + "...")

func bake_all_sdf_meshes():
	for idx in _sdf_meshes.size():
		bake_sdf_mesh(idx)

func baking_finished(index):
	print("Building mesh SDF " + str(index) + " done")
