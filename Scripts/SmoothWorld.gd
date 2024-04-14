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

var EDIT_MODE = preload("res://Scripts/EditModeEnum.gd").EDIT_MODE

var base_terraform_distance = 1000
var terraform_distance = base_terraform_distance

var edit_indicator_is_visible = true

var left_mouse_button_held = false
var right_mouse_button_held = false

var draw_speed = (2.0 / 60.0); # how often edits can be made for terrain in seconds
var draw_speed_accumulate_delta = 0.0;
var can_edit_terrain = true;

var mouse_captured = false
var just_started_capturing_mouse = false

var last_frame_edit_data = {
	"flatten_plane": null,
}

func _ready():
	saver.load_data()
	debug_stat_drawer.voxel_terrain = voxel_terrain
	debug_stat_drawer.voxel_tool = voxel_tool
	debug_stat_drawer.camera = camera
	
	tool_mesh_bake_state._scene_root = get_tree()
	tool_mesh_bake_state.bake_all_sdf_meshes()
	
	# Required for surface tool to interact nicely when
	# surface is edited with other tools like sphere
	voxel_tool.sdf_scale = 10

func _process(delta):
	update_draw_timer(delta)
	
	if not Input.is_action_pressed("CTRL"):
		update_terraforming()
	
	# Edit indicator position and size can be affected in multiple sources,
	# so might as well just update it every frame
	update_edit_indicator()

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
				if not Input.is_action_pressed("ALT") and event.pressed:
					set_tool_scale(get_tool_scale() + 1)
			
			MOUSE_BUTTON_WHEEL_DOWN:
				if not Input.is_action_pressed("ALT") and event.pressed:
					set_tool_scale(get_tool_scale() - 1)
	
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ESCAPE:
					capture_mouse(false)
				KEY_X:
					edit_indicator_is_visible = not edit_indicator_is_visible
					edit_indicators.visible = edit_indicator_is_visible
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
					vp.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME - vp.debug_draw
	
	update_last_frame_data()

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

func get_tool_sdf_scale():
	return get_tool_parameter_value("sdf_scale")

func set_tool_sdf_scale(new_value):
	set_tool_parameter_value("sdf_scale", new_value)

func get_edit_mesh(_edit_mode):
	return edit_indicators.get_child(_edit_mode)

func update_draw_timer(delta):
	if draw_speed_accumulate_delta > draw_speed:
		can_edit_terrain = true;
	else:
		draw_speed_accumulate_delta += delta;

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
	var origin = camera.get_position()
	var forward = get_camera_forward_vector()
	var hit = voxel_tool.raycast(origin, forward, terraform_distance)
	return hit

# increases vector length, so that vector touches cube side
func get_elongated_vector(vector):
	var longest_axis = max(abs(vector.x), abs(vector.y), abs(vector.z))
	return vector / longest_axis

func update_edit_indicator():
	if not edit_indicator_is_visible:
		return
	
	terraform_distance = base_terraform_distance * get_tool_scale()
	
	var hit = get_pointed_voxel()
	if hit:
		var pos = Vector3(hit.position)
		edit_indicators.visible = true
		edit_indicators.position = pos
		
		var tool_scale = get_tool_scale()
		edit_indicators.scale = Vector3(tool_scale, tool_scale, tool_scale)
	else:
		edit_indicators.visible = false
	
	update_mesh_edit_indicator()

func update_mesh_edit_indicator():
	if edit_mode_state.edit_mode != EDIT_MODE.MESH:
		return
	
	var sdf_mesh = tool_mesh_bake_state.get_selected_sdf_mesh()
	var edit_mesh = get_edit_mesh(EDIT_MODE.MESH)
	edit_mesh.mesh = sdf_mesh.mesh
	var mat : StandardMaterial3D = edit_mesh.material_override
	
	if sdf_mesh.is_baked():
		mat.albedo_color = Color(1, 1, 1, 0.5)
	elif sdf_mesh.is_baking():
		mat.albedo_color = Color(1, 0.6, 0, 0.5)
	else:
		mat.albedo_color = Color(1, 0, 0, 0.5)
	
	update_mesh_edit_indicator_transform(sdf_mesh)

func update_mesh_edit_indicator_transform(sdf_mesh):
	if sdf_mesh.mesh == null:
		return
	
	var aabb = sdf_mesh.mesh.get_aabb()
	var aabb_half_size = aabb.size / 2.0
	var max_aabb_half_size_axis = max(aabb_half_size.x, aabb_half_size.y, aabb_half_size.z)
	
	var inverse_max_axis = 1.0 / max_aabb_half_size_axis
	var scaled_vector = Vector3(inverse_max_axis, inverse_max_axis, inverse_max_axis)
	edit_indicators.transform = edit_indicators.transform.scaled_local(scaled_vector)
	
	# TODO: I have a feeling offset can be made better than this
	var offset = Vector3(0, aabb_half_size.y * (get_tool_scale() / max_aabb_half_size_axis) + 5, 0)
	edit_indicators.transform = Transform3D(edit_indicators.transform.basis, edit_indicators.transform.origin + offset)

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
	var edit_sdf_scale = get_tool_sdf_scale()
	
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
			var place_transform = edit_indicators.transform
			voxel_tool.stamp_sdf(sdf_mesh, place_transform, edit_isolevel, edit_sdf_scale)
			print(place_transform)

func capture_mouse(value):
	mouse_captured = value
	just_started_capturing_mouse = value
	
	# 'process_mode' disables pressing on UI elements, but still keeps mouse hover effect.
	# 'set_ui_element_mouse_filter' disables mouse hover effect.
	if value:
		# We need it to be "MOUSE_MODE_CAPTURED" instead of "MOUSE_MODE_CONFINED_HIDDEN",
		# otherwise relative mouse movement won't work properly
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		ui_root.process_mode = Node.PROCESS_MODE_DISABLED
		set_ui_element_mouse_filter(ui_root, false)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		ui_root.process_mode = Node.PROCESS_MODE_INHERIT
		set_ui_element_mouse_filter(ui_root, true)

# Since Godot doesn't provide a way to disable all GUI elements when mouse is hidden
# I have to manually crawl through UI elements and disable hover effect.
func set_ui_element_mouse_filter(element, enabled):
	for child in element.get_children():
		set_ui_element_mouse_filter(child, enabled)
	
	# Some UI elements have either stop or pass, so I have to manually
	# check the element type to know what mouse filter to revert it back to
	if enabled:
		if element is BaseButton or element is Range:
			element.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		if element is BaseButton or element is Range:
			element.mouse_filter = Control.MOUSE_FILTER_IGNORE
