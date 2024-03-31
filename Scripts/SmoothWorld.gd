extends Node

@onready var voxel_terrain = get_node("VoxelTerrain")
@onready var voxel_tool = get_node("VoxelTerrain").get_voxel_tool()
@onready var camera = get_node("Camera3D")
@onready var saver = get_node("Saver")
@onready var edit_indicators = get_node("EditIndicators")

@onready var tool_info = get_node("CanvasLayer/ToolInfo")
@onready var tool_select = get_node("CanvasLayer/ToolInfo/MarginContainer/VBoxContainer/ToolSelect")
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

var edit_mode = EDIT_MODE.SPHERE

var last_frame_edit_data = {
	"flatten_plane": null,
}

# Used for mesh tool
var mesh_sdf := VoxelMeshSDF.new()

# TODO: move debug drawing in other script
var debug_draw_stats_enabled = false

var process_stats = {}
var displayed_process_stats = {}
var time_before_display_process_stats = 1.0

const process_stat_names = [
]


func _ready():
	set_edit_mode(EDIT_MODE.SPHERE)
	saver.load_data()
	
	# Required for surface tool to interact nicely when
	# surface is edited with other tools like sphere
	#voxel_tool.sdf_scale = 0.01

func _process(delta):
	update_draw_timer(delta)
	
	if not Input.is_action_pressed("CTRL"):
		update_terraforming()
	
	# Edit indicator position and size can be affected in multiple sources,
	# so might as well just update it every frame
	update_edit_indicator()
	
	if debug_draw_stats_enabled:
		draw_debug_voxel_stats(delta)
	
#	print(voxel_tool.get_voxel_f(camera.transform.origin))

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
					set_edit_mode(EDIT_MODE.SPHERE)
				KEY_2:
					set_edit_mode(EDIT_MODE.CUBE)
				KEY_3:
					set_edit_mode(EDIT_MODE.BLEND_BALL)
				KEY_4:
					set_edit_mode(EDIT_MODE.SURFACE)
				KEY_5:
					set_edit_mode(EDIT_MODE.FLATTEN)
				KEY_6:
					set_edit_mode(EDIT_MODE.MESH)
				KEY_P:
					debug_draw_stats_enabled = !debug_draw_stats_enabled
	
	update_last_frame_data()


func draw_debug_voxel_stats(delta):
	var stats = voxel_terrain.get_statistics()
	
	DDD.set_text("FPS", Engine.get_frames_per_second())
	DDD.set_text("Static memory", _format_memory(OS.get_static_memory_usage()))
#	DDD.set_text("Blocked lods", stats.blocked_lods)
	DDD.set_text("Position", camera.position)

	var global_stats = VoxelEngine.get_stats()
	for p in global_stats:
		var pool_stats = global_stats[p]
		for k in pool_stats:
			DDD.set_text(str(p, "_", k), pool_stats[k])

	for k in process_stat_names:
		var v = stats[k]
		if k in process_stats:
			process_stats[k] = max(process_stats[k], v)
		else:
			process_stats[k] = v

	time_before_display_process_stats -= delta
	if time_before_display_process_stats < 0:
		time_before_display_process_stats = 1.0
		displayed_process_stats = process_stats
		process_stats = {}

	for k in displayed_process_stats:
		DDD.set_text(k, displayed_process_stats[k])

#	_terrain.debug_set_draw_enabled(true)
#	_terrain.debug_set_draw_flag(VoxelLodTerrain.DEBUG_DRAW_MESH_UPDATES, true)


static func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb, ".", mbr, " Mb")


func update_last_frame_data():
	if not left_mouse_button_held and not right_mouse_button_held:
		last_frame_edit_data.flatten_plane = null

func get_tool_parameter_value(parameter_name):
	return tool_info.get_tool_parameter_value(edit_mode, parameter_name)

func set_tool_parameter_value(parameter_name, new_value):
	tool_info.set_tool_parameter_value(edit_mode, parameter_name, new_value)

func get_tool_scale():
	return get_tool_parameter_value("scale")

func set_tool_scale(new_value):
	set_tool_parameter_value("scale", new_value)

func get_tool_strength():
	return get_tool_parameter_value("strength")

func set_tool_strength(new_value):
	set_tool_parameter_value("strength", new_value)

func get_edit_mesh(_edit_mode):
	return edit_indicators.get_child(_edit_mode)

func set_edit_mode(new_edit_mode):
	var total_tools = EDIT_MODE.keys().size()
	if not (new_edit_mode >= 0 && new_edit_mode < total_tools):
		print("Invalid edit mode selected")
		return
	
	for c in edit_indicators.get_children():
		c.visible = false
	
	edit_mode = new_edit_mode
	tool_select.selected = new_edit_mode
	tool_info.set_edit_mode(new_edit_mode)
	
	var edit_mesh = get_edit_mesh(new_edit_mode)
	if edit_mesh:
		edit_mesh.visible = true

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
	if (not mesh_sdf.is_baked()) and (not mesh_sdf.is_baking()):
		# TODO This is not supposed to be a requirement.
		# Check source code of `VoxelMeshSDF` to see why `get_tree()` is necessary...
		assert(is_inside_tree())
		
		var mesh = load("res://Objects/suzanne.obj")
		mesh_sdf.mesh = mesh
		mesh_sdf.baked.connect(func(): print("Building mesh SDF done"))
		mesh_sdf.bake_async(get_tree())
		print("Building mesh SDF...")
	
	var edit_mesh = get_edit_mesh(EDIT_MODE.MESH)
	var mat : StandardMaterial3D = edit_mesh.material_override
	# TODO: transparency should be standardised for all edit indicators...
	if mesh_sdf.is_baked():
		mat.albedo_color = Color(1, 1, 1, 0.5)
	else:
		mat.albedo_color = Color(1, 0, 0, 0.5)
	
	if edit_mode == EDIT_MODE.MESH:
		# TODO: I have a feeling offset can be made better than this
		var forward = get_camera_forward_vector()
		forward = get_elongated_vector(forward)
		var aabb = mesh_sdf.mesh.get_aabb()
		var aabb_half_size = aabb.size / 2.0
		var offset = sqrt(aabb_half_size.x * aabb_half_size.x + aabb_half_size.y * aabb_half_size.y)
		offset *= forward * edit_indicators.scale
		edit_indicators.transform = Transform3D(edit_indicators.transform.basis, edit_indicators.transform.origin - offset)

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
	
	if edit_mode == EDIT_MODE.SPHERE:
		offset_pos += offset_sign * forward * (edit_scale - 2)
	elif edit_mode == EDIT_MODE.CUBE:
		forward = get_elongated_vector(forward)
		offset_pos += offset_sign * forward * (edit_scale - 2)
	
	voxel_tool.mode = voxel_tool_mode
	
	if edit_mode == EDIT_MODE.SPHERE:
		voxel_tool.do_sphere(offset_pos, edit_scale)
	
	elif edit_mode == EDIT_MODE.CUBE:
		var offset = Vector3(edit_scale, edit_scale, edit_scale)
		voxel_tool.do_box(offset_pos - offset, offset_pos + offset)
	
	elif edit_mode == EDIT_MODE.BLEND_BALL:
		# TODO: consider adding falloff parameter which increases smoothness towards edges
		voxel_tool.smooth_sphere(hit_pos, edit_scale, edit_strength)
	
	elif edit_mode == EDIT_MODE.SURFACE:
		voxel_tool.grow_sphere(hit_pos, edit_scale, edit_strength)
		
	elif edit_mode == EDIT_MODE.FLATTEN:
		# TODO: consider adding falloff parameter which increases smoothness towards edges
		if last_frame_edit_data.flatten_plane == null:
			last_frame_edit_data.flatten_plane = Plane(forward, hit_pos)
		
		var center_pos = last_frame_edit_data.flatten_plane.intersects_ray(camera.get_position(), forward)
		if center_pos != null:
			voxel_tool.do_hemisphere(center_pos, edit_scale, offset_sign * last_frame_edit_data.flatten_plane.normal, edit_strength)
	
	elif edit_mode == EDIT_MODE.MESH:
		if mesh_sdf.is_baked():
			var place_transform = edit_indicators.transform
			voxel_tool.stamp_sdf(mesh_sdf, place_transform, 0.1, 1.0)

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
