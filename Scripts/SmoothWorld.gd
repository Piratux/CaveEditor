extends Node

@export var edit_mode_state: EditModeState
@export var tool_state: ToolState
@export var tool_mesh_bake_state: ToolMeshBakeState

@onready var voxel_terrain = get_node("VoxelTerrain")
@onready var voxel_tool = get_node("VoxelTerrain").get_voxel_tool()
@onready var camera = get_node("Camera3D")
@onready var saver = get_node("Saver")
@onready var edit_indicators = get_node("EditIndicators")
@onready var debug_stat_drawer = get_node("DebugStatDrawer")
@onready var ui_root = get_node("CanvasLayer")
@onready var mesh_edit_indicator = get_node("VoxelTerrain/MeshEditPreviewIndicator")

var file_util = preload("res://Scripts/Utils/FileUtil.gd").new()
var math_util = preload("res://Scripts/Utils/MathUtil.gd").new()

var EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE
const SDF_MESH_STATE_COLOUR_DATA = preload("res://Scripts/SdfMeshStateColourData.gd").SDF_MESH_STATE_COLOUR_DATA

var edit_indicator_is_visible = true

var left_mouse_button_held = false
var right_mouse_button_held = false

var draw_speed = 2.0 / 60.0 # how often edits can be made for terrain in seconds
var draw_speed_accumulate_delta = 0.0
var can_edit_terrain = true

var mouse_captured = false
var just_started_capturing_mouse = false

var last_frame_edit_data = {
	"flatten_plane": null,
}

var _sdf_scale = 10

var _last_scale_value = 0
var _last_mesh_tool_paramaters = {}

func _enter_tree():
	# Cybermedium font:
	# https://patorjk.com/software/taag/#p=display&f=Cybermedium&t=Cave%20Editor
	print(r"""
/----------------------------------------------------\
|  ____ ____ _  _ ____    ____ ___  _ ___ ____ ____  |
|  |    |__| |  | |___    |___ |  \ |  |  |  | |__/  |
|  |___ |  |  \/  |___    |___ |__/ |  |  |__| |  \  |
\----------------------------------------------------/
	""")

func _ready():
	saver.load_data()
	debug_stat_drawer.voxel_terrain = voxel_terrain
	debug_stat_drawer.voxel_tool = voxel_tool
	debug_stat_drawer.camera = camera
	
	tool_mesh_bake_state._scene_root = get_tree()
	tool_mesh_bake_state.bake_all_sdf_meshes()
	
	# Required for surface tool to interact nicely when
	# surface is edited with other tools like sphere
	voxel_tool.sdf_scale = _sdf_scale
	
	add_test_meshes()
	
	tool_state.mesh_preview_enabled_updated.connect(mesh_preview_enabled_updated)
	tool_mesh_bake_state.sdf_mesh_index_updated.connect(sdf_mesh_index_updated)
	edit_mode_state.edit_mode_updated.connect(edit_mode_updated)
	
	camera.transform_updated.connect(camera_transform_updated)
	
	update_edit_indicator()

func _process(delta):
	update_draw_timer(delta)
	
	if not Input.is_action_pressed("CTRL"):
		update_terraforming()
	
	update_signals()
	update_mesh_edit_color()

func _unhandled_input(event):
	if (event is InputEventMouseButton and 
		(event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and
		!mouse_captured):
		
		capture_mouse(true)
	
	if not mouse_captured:
		return
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if just_started_capturing_mouse:
					if event.pressed == false:
						just_started_capturing_mouse = false
				else:
					if event.button_index == MOUSE_BUTTON_LEFT:
						left_mouse_button_held = event.pressed
					
					if event.button_index == MOUSE_BUTTON_RIGHT:
						right_mouse_button_held = event.pressed
					
					if Input.is_action_pressed("CTRL") and event.pressed:
						update_terraforming()
			
			MOUSE_BUTTON_WHEEL_UP:
				if Input.is_action_pressed("CTRL") and event.pressed:
					tool_mesh_bake_state.select_previous_sdf_mesh()
				elif not Input.is_action_pressed("ALT") and event.pressed:
					set_tool_scale(get_tool_scale() + 1)
			
			MOUSE_BUTTON_WHEEL_DOWN:
				if Input.is_action_pressed("CTRL") and event.pressed:
					tool_mesh_bake_state.select_next_sdf_mesh()
				elif not Input.is_action_pressed("ALT") and event.pressed:
					set_tool_scale(get_tool_scale() - 1)
	
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ESCAPE:
					capture_mouse(false)
				KEY_1:
					edit_mode_state.edit_mode = EDIT_MODE.SPHERE
				KEY_2:
					edit_mode_state.edit_mode = EDIT_MODE.CUBE
				KEY_3:
					edit_mode_state.edit_mode = EDIT_MODE.BLEND_BALL
				KEY_4:
					edit_mode_state.edit_mode = EDIT_MODE.SURFACE
				KEY_5:
					edit_mode_state.edit_mode = EDIT_MODE.FLATTEN
				KEY_6:
					edit_mode_state.edit_mode = EDIT_MODE.MESH
				KEY_UP:
					if Input.is_action_pressed("CTRL"):
						camera.position.y += 1
					else:
						camera.position.x += 1
				KEY_DOWN:
					if Input.is_action_pressed("CTRL"):
						camera.position.y -= 1
					else:
						camera.position.x -= 1
				KEY_RIGHT:
					camera.position.z += 1
				KEY_LEFT:
					camera.position.z -= 1
				KEY_O:
					var vp = get_viewport()
					#vp.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME - vp.debug_draw
					vp.debug_draw = (vp.debug_draw + 1) % 7
				KEY_X:
					edit_indicator_is_visible = not edit_indicator_is_visible
					edit_indicators.visible = edit_indicator_is_visible
					
					update_edit_indicator()
				KEY_Z:
					if Input.is_action_pressed("ALT"):
						ui_root.visible = not ui_root.visible
	
	update_last_frame_data()

func update_signals():
	# TODO: These should be proper signals, but that requires breaking some abstractions.
	# Might think of better solution later
	
	var tool_scale = get_tool_scale()
	if _last_scale_value != tool_scale:
		_last_scale_value = tool_scale
		tool_scale_updated()
	
	var values = tool_state.get_all_tool_parameter_values(EDIT_MODE.MESH)
	for value in _last_mesh_tool_paramaters:
		# NOTE: we don't want to fire update event for scale as it's handled above
		if values[value] != _last_mesh_tool_paramaters[value] and value != "scale":
			mesh_tool_parameters_updated()
			break
	
	_last_mesh_tool_paramaters = values.duplicate()

func get_edit_indicators_transform(mesh, transform, scale):
	if mesh == null:
		return null
	
	var rot_x = get_tool_rot_x() if get_tool_rot_x() else 0
	var rot_y = get_tool_rot_y() if get_tool_rot_y() else 0
	var rot_z = get_tool_rot_z() if get_tool_rot_z() else 0
	
	# YXZ rotation order is Godot's default.
	transform = transform.rotated_local(Vector3.UP, deg_to_rad(rot_y))
	transform = transform.rotated_local(Vector3.RIGHT, deg_to_rad(rot_x))
	transform = transform.rotated_local(Vector3.BACK, deg_to_rad(rot_z))
	
	transform = math_util.get_unit_scaled_transform_from_mesh(mesh, transform)
	
	# Looks better when object is a bit above the ground
	var offset = Vector3(0, scale + 10, 0)
	return transform.translated(offset)

func get_edit_mesh_transform(mesh):
	var transform = Transform3D()
	
	var pivot_offset_x = get_tool_pivot_offset_x() if get_tool_pivot_offset_x() else 0
	var pivot_offset_y = get_tool_pivot_offset_y() if get_tool_pivot_offset_y() else 0
	var pivot_offset_z = get_tool_pivot_offset_z() if get_tool_pivot_offset_z() else 0
	
	var mesh_aabb = mesh.get_aabb()
	transform = transform.translated(-mesh_aabb.get_center())
	
	var mesh_aabb_half_size = mesh_aabb.size / 2
	var pivot_offset = Vector3(
		mesh_aabb_half_size.x * (pivot_offset_x / 100),
		mesh_aabb_half_size.y * (pivot_offset_y / 100),
		mesh_aabb_half_size.z * (pivot_offset_z / 100)
	)
	
	transform = transform.translated(pivot_offset)
	
	return transform

func add_test_meshes():
	var pos = Vector3(0, 20, -100)
	var pos_spacing = Vector3(50, 0, 0)
	for file_name in file_util.get_obj_file_paths():
		var mesh = ObjExporter.load_mesh_from_file(file_name)
		if !mesh:
			continue
		
		var node_instance := Node3D.new()
		node_instance.transform = get_edit_indicators_transform(mesh, node_instance.transform, 1)
		node_instance.position = pos
		
		var transform_scale = 20
		var scaled_vector = Vector3(transform_scale, transform_scale, transform_scale)
		node_instance.transform = node_instance.transform.scaled_local(scaled_vector)
		
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.transform = get_edit_mesh_transform(mesh)
		
		node_instance.add_child(mesh_instance)
		get_parent().add_child.call_deferred(node_instance)
		pos += pos_spacing

func update_last_frame_data():
	if not left_mouse_button_held and not right_mouse_button_held:
		last_frame_edit_data.flatten_plane = null

func get_tool_parameter_value(parameter_name):
	return tool_state.get_tool_parameter_value(edit_mode_state.edit_mode, parameter_name)

func set_tool_parameter_value(parameter_name, new_value):
	tool_state.set_tool_parameter_value(new_value, edit_mode_state.edit_mode, parameter_name)

func get_tool_scale():
	return get_tool_parameter_value("scale")

func set_tool_scale(new_value):
	set_tool_parameter_value("scale", new_value)

func get_tool_strength():
	return get_tool_parameter_value("strength")

func set_tool_strength(new_value):
	set_tool_parameter_value("strength", new_value)

func get_tool_isolevel():
	return get_tool_parameter_value("isolevel")

func set_tool_isolevel(new_value):
	set_tool_parameter_value("isolevel", new_value)

func get_tool_rot_x():
	return get_tool_parameter_value("rot_x")

func set_tool_rot_x(new_value):
	set_tool_parameter_value("rot_x", new_value)

func get_tool_rot_y():
	return get_tool_parameter_value("rot_y")

func set_tool_rot_y(new_value):
	set_tool_parameter_value("rot_y", new_value)

func get_tool_rot_z():
	return get_tool_parameter_value("rot_z")

func set_tool_rot_z(new_value):
	set_tool_parameter_value("rot_z", new_value)

func get_tool_pivot_offset_x():
	return get_tool_parameter_value("pivot_offset_x")

func set_tool_pivot_offset_x(new_value):
	set_tool_parameter_value("pivot_offset_x", new_value)

func get_tool_pivot_offset_y():
	return get_tool_parameter_value("pivot_offset_y")

func set_tool_pivot_offset_y(new_value):
	set_tool_parameter_value("pivot_offset_y", new_value)

func get_tool_pivot_offset_z():
	return get_tool_parameter_value("pivot_offset_z")

func set_tool_pivot_offset_z(new_value):
	set_tool_parameter_value("pivot_offset_z", new_value)

func get_edit_mesh(_edit_mode):
	return edit_indicators.get_child(_edit_mode)

func update_draw_timer(delta):
	if draw_speed_accumulate_delta > draw_speed:
		can_edit_terrain = true
	else:
		draw_speed_accumulate_delta += delta

func update_terraforming():
	if not can_edit_terrain:
		return
	
	if left_mouse_button_held or right_mouse_button_held:
		can_edit_terrain = false
		draw_speed_accumulate_delta = 0.0
	
	if left_mouse_button_held:
		try_edit_terrain(VoxelTool.MODE_ADD)
	
	if right_mouse_button_held:
		try_edit_terrain(VoxelTool.MODE_REMOVE)

func get_camera_forward_vector():
	return -camera.get_transform().basis.z.normalized()

func get_pointed_voxel():
	# When we cast the ray, we don't want voxel_modifier_mesh to be hit, as that causes
	# it to endlessly adjust the edit indicator position.
	# So we move it away temporarily just for the raycast.
	
	# Even though mesh_sdf is null, tasks still get added, and we don't want that for performance reasons.
	if mesh_edit_indicator.mesh_sdf != null:
		mesh_edit_indicator.position.x += 100000
	
	var origin = camera.get_position()
	var forward = get_camera_forward_vector()
	var max_distance = 1000
	var hit = voxel_tool.raycast(origin, forward, max_distance)
	
	if mesh_edit_indicator.mesh_sdf != null:
		mesh_edit_indicator.position.x -= 100000
	
	return hit

# increases vector length, so that vector touches cube side
func get_elongated_vector(vector):
	var longest_axis = max(abs(vector.x), abs(vector.y), abs(vector.z))
	return vector / longest_axis

func update_edit_indicator():
	if tool_mesh_bake_state.total_sdf_meshes() == 0:
		return
	
	update_mesh_edit_preview_indicator()
	
	if not edit_indicator_is_visible:
		return
	
	var hit = get_pointed_voxel()
	if hit:
		var pos = Vector3(hit.position)
		edit_indicators.visible = true
		edit_indicators.position = pos
		
		var tool_scale = get_tool_scale()
		edit_indicators.scale = Vector3(tool_scale, tool_scale, tool_scale)
		
		edit_indicators.rotation = Vector3(0,0,0)
	else:
		edit_indicators.visible = false
	
	update_mesh_edit_indicator()

func update_mesh_edit_indicator():
	if edit_mode_state.edit_mode != EDIT_MODE.MESH:
		return
	
	var sdf_mesh = tool_mesh_bake_state.get_selected_sdf_mesh()

	var edit_mesh = get_edit_mesh(EDIT_MODE.MESH)
	edit_mesh.mesh = sdf_mesh.mesh
	
	update_edit_mode_mesh_transform(sdf_mesh)

func update_edit_mode_mesh_transform(sdf_mesh):
	edit_indicators.transform = get_edit_indicators_transform(sdf_mesh.mesh, edit_indicators.transform, get_tool_scale())
	
	get_edit_mesh(EDIT_MODE.MESH).transform = get_edit_mesh_transform(sdf_mesh.mesh)
	
	if mesh_edit_indicator.mesh_sdf != null:
		mesh_edit_indicator.global_transform = get_edit_mesh(EDIT_MODE.MESH).global_transform

func get_edit_mesh_sdf_scale(mesh):
	var aabb = mesh.get_aabb()
	var aabb_half_size = aabb.size / 2.0
	var max_aabb_half_size_axis = max(aabb_half_size.x, aabb_half_size.y, aabb_half_size.z)
	
	# (25 * sdf_scale) magic number gives close enough results that make stamped cube mesh and do_box SDF look similarly
	return (25 * _sdf_scale) / max_aabb_half_size_axis

func try_edit_terrain(voxel_tool_mode):
	var hit = get_pointed_voxel()
	
	if not hit:
		return
	
	var hit_pos = Vector3(hit.position)
	var offset_pos = Vector3(hit_pos)
	var offset_sign = 1
	
	if voxel_tool_mode == VoxelTool.MODE_ADD:
		offset_sign = 1
		voxel_tool.value = 1
	else:
		offset_sign = -1
		voxel_tool.value = 0
	
	var forward = get_camera_forward_vector()
	var edit_scale = get_tool_scale()
	var edit_strength = get_tool_strength()
	var edit_isolevel = get_tool_isolevel()
	if edit_isolevel:
		edit_isolevel *= _sdf_scale
	
	voxel_tool.mode = voxel_tool_mode
	
	if edit_mode_state.edit_mode == EDIT_MODE.SPHERE:
		offset_pos += offset_sign * forward * (edit_scale - 2)
		voxel_tool.do_sphere(offset_pos, edit_scale)
	
	elif edit_mode_state.edit_mode == EDIT_MODE.CUBE:
		forward = get_elongated_vector(forward)
		offset_pos += offset_sign * forward * (edit_scale - 2)
		var offset = Vector3(edit_scale, edit_scale, edit_scale)
		voxel_tool.do_box(offset_pos - offset, offset_pos + offset)
	
	elif edit_mode_state.edit_mode == EDIT_MODE.BLEND_BALL:
		# TODO: consider adding falloff parameter which increases smoothness towards edges
		voxel_tool.smooth_sphere(hit_pos, edit_scale, edit_strength)
	
	elif edit_mode_state.edit_mode == EDIT_MODE.SURFACE:
		voxel_tool.grow_sphere(hit_pos, edit_scale, edit_strength)
		
	elif edit_mode_state.edit_mode == EDIT_MODE.FLATTEN:
		# TODO: consider adding falloff parameter which increases smoothness towards edges
		if last_frame_edit_data.flatten_plane == null:
			last_frame_edit_data.flatten_plane = Plane(forward, hit_pos)
		
		var center_pos = last_frame_edit_data.flatten_plane.intersects_ray(camera.get_position(), forward)
		if center_pos != null:
			voxel_tool.do_hemisphere(center_pos, edit_scale, offset_sign * last_frame_edit_data.flatten_plane.normal, edit_strength)
	
	elif edit_mode_state.edit_mode == EDIT_MODE.MESH:
		var sdf_mesh = tool_mesh_bake_state.get_selected_sdf_mesh()
		if sdf_mesh.is_baked():
			print("Mesh sdf voxel buffer size:")
			print(sdf_mesh.get_voxel_buffer().get_size())
			var edit_mesh = get_edit_mesh(EDIT_MODE.MESH)
			var place_transform = edit_mesh.global_transform
			var sdf_scale = get_edit_mesh_sdf_scale(edit_mesh.mesh)
			voxel_tool.stamp_sdf(sdf_mesh, place_transform, edit_isolevel, sdf_scale)
			print(place_transform)

func capture_mouse(value):
	mouse_captured = value
	just_started_capturing_mouse = value
	
	ui_root.capture_mouse(value)

func update_mesh_edit_preview_indicator():
	if not edit_indicator_is_visible:
		mesh_edit_indicator.mesh_sdf = null
		return
	
	if edit_mode_state.edit_mode != EDIT_MODE.MESH:
		mesh_edit_indicator.mesh_sdf = null
		return
	
	if not tool_state.mesh_preview_enabled:
		mesh_edit_indicator.mesh_sdf = null
		return
	
	var sdf_mesh = tool_mesh_bake_state.get_selected_sdf_mesh()
	mesh_edit_indicator.mesh_sdf = sdf_mesh

func mesh_preview_enabled_updated(_new_value):
	update_edit_indicator()

func sdf_mesh_index_updated(_new_value):
	update_edit_indicator()

func edit_mode_updated(_new_edit_mode):
	update_edit_indicator()

func camera_transform_updated():
	update_edit_indicator()

func tool_scale_updated():
	update_edit_indicator()

func mesh_tool_parameters_updated():
	update_edit_indicator()

func update_mesh_edit_color():
	if edit_mode_state.edit_mode != EDIT_MODE.MESH:
		return
	
	if tool_mesh_bake_state.total_sdf_meshes() == 0:
		return
	
	var edit_mesh = get_edit_mesh(EDIT_MODE.MESH)
	var mat : StandardMaterial3D = edit_mesh.material_override
	
	var edit_mesh_state = tool_mesh_bake_state.get_selected_sdf_mesh_state()
	mat.albedo_color = SDF_MESH_STATE_COLOUR_DATA[edit_mesh_state].colour
