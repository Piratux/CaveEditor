extends Node

var base_terraform_distance = 1000
var terraform_distance = base_terraform_distance

var edit_min_scale = 2
var edit_max_scale = 100
var edit_scale = 10 # default scale

var blend_ball_min_range = 1
var blend_ball_max_range = 15
var blend_ball_range = 3 # default range

var surface_extra_radius_min_range = 1
var surface_extra_radius_max_range = 15
var surface_extra_radius_range = 10 # default range

var edit_intensity_min = 0.1
var edit_intensity_max = 1.0
var edit_intensity = 0.5 # default range
var edit_intensity_step = 0.05

var edit_indicator_is_visible = true

var left_mouse_button_held = false
var right_mouse_button_held = false

var draw_speed = (2.0 / 60.0); # how often edits can be made for terrain in seconds
var draw_speed_accumulate_delta = 0.0;
var can_edit_terrain = true;

var mouse_captured = false
var just_started_capturing_mouse = false

enum EDIT_MODE {SPHERE, CUBE, BLEND_BALL, SURFACE, TRIM}
var edit_mode = EDIT_MODE.SPHERE

@onready var voxel_terrain = get_node("VoxelTerrain")
@onready var voxel_tool = get_node("VoxelTerrain").get_voxel_tool()
@onready var camera = get_node("Camera3D")
@onready var saver = get_node("Saver")
@onready var edit_indicators = get_node("EditIndicators")
@onready var sphere_edit_indicator = get_node("EditIndicators/SphereEdit")
@onready var cube_edit_indicator = get_node("EditIndicators/CubeEdit")

@onready var tool_info = get_node("CanvasLayer/ToolInfo")
@onready var tool_select = get_node("CanvasLayer/ToolInfo/MarginContainer/VBoxContainer/ToolSelect")

func _ready():
	set_edit_mode(EDIT_MODE.SPHERE)
	set_edit_scale(edit_scale)
	set_blend_ball_strength(blend_ball_range)
	set_surface_blend_extra_radius(surface_extra_radius_range)
	set_edit_intensity(edit_intensity)
	saver.load_data()

func _process(delta):
	update_draw_timer(delta)
	
	if not Input.is_action_pressed("CTRL"):
		update_terraforming()

func _unhandled_input(event):
	if (event is InputEventMouseButton and 
		(event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and
		!mouse_captured):

		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
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
					else:
						right_mouse_button_held = event.pressed

					if event.pressed and Input.is_action_pressed("CTRL"):
						update_terraforming()

			MOUSE_BUTTON_WHEEL_UP:
				if not Input.is_action_pressed("ALT"):
					set_edit_scale(edit_scale + 1)

			MOUSE_BUTTON_WHEEL_DOWN:
				if not Input.is_action_pressed("ALT"):
					set_edit_scale(edit_scale - 1)

	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ESCAPE:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
					set_edit_mode(EDIT_MODE.TRIM)
				KEY_V:
					test_edit()
				KEY_L:
					try_edit_terrain(EDIT_MODE.SPHERE)
					saver.load_world_by_name("temp")

	update_edit_sphere()

func parameter_slider_changed(_name, value):
	if _name == "Edit Scale":
		set_edit_scale(value)
	elif _name == "Strength":
		set_blend_ball_strength(value)
	elif _name == "Blend Radius":
		set_surface_blend_extra_radius(value)
	elif _name == "Intensity":
		set_edit_intensity(value)

func set_edit_scale(value):
	edit_scale = clamp(value, edit_min_scale, edit_max_scale)
	tool_info.edit_scale_slider.get_node("HSlider").value_changed(edit_scale)
	update_edit_sphere()

func set_blend_ball_strength(value):
	blend_ball_range = clamp(value, blend_ball_min_range, blend_ball_max_range)
	tool_info.blend_ball_strength_slider.get_node("HSlider").value_changed(blend_ball_range)

func set_surface_blend_extra_radius(value):
	surface_extra_radius_range = clamp(value, surface_extra_radius_min_range, surface_extra_radius_max_range)
	tool_info.surface_blend_extra_radius_slider.get_node("HSlider").value_changed(surface_extra_radius_range)

func set_edit_intensity(value):
	edit_intensity = clamp(value, edit_intensity_min, edit_intensity_max)
	tool_info.edit_intensity_slider.get_node("HSlider").value_changed(edit_intensity)

func set_edit_mode(new_edit_mode):
	var edit_mesh = edit_indicators.get_child(new_edit_mode)
	if edit_mesh:
		edit_mode = new_edit_mode
		for c in edit_indicators.get_children():
			c.visible = false
		edit_mesh.visible = true
		
		tool_select.selected = new_edit_mode
		
		tool_info.blend_ball_strength_slider.visible = (
			new_edit_mode == EDIT_MODE.BLEND_BALL
			or new_edit_mode == EDIT_MODE.SURFACE
		)
		tool_info.surface_blend_extra_radius_slider.visible = (
			new_edit_mode == EDIT_MODE.SURFACE
		)

func update_draw_timer(delta):
	if draw_speed_accumulate_delta > draw_speed:
		can_edit_terrain = true;
	else:
		draw_speed_accumulate_delta += delta;

func update_terraforming():
	if not can_edit_terrain:
		return
	
	if left_mouse_button_held:
		can_edit_terrain = false
		draw_speed_accumulate_delta = 0.0
		try_edit_terrain(VoxelTool.MODE_ADD)
	elif right_mouse_button_held:
		can_edit_terrain = false
		draw_speed_accumulate_delta = 0.0
		try_edit_terrain(VoxelTool.MODE_REMOVE)

func get_pointed_voxel():
	var origin = camera.get_global_transform().origin
	var forward = -camera.get_transform().basis.z.normalized()
	var hit = voxel_tool.raycast(origin, forward, terraform_distance)
	return hit

func update_edit_sphere():
	if not edit_indicator_is_visible:
		return
	
	terraform_distance = base_terraform_distance * edit_scale
	
	var hit = get_pointed_voxel()
	if hit:
		var pos = Vector3(hit.position)
		edit_indicators.visible = true
		edit_indicators.global_position = pos
		edit_indicators.scale = Vector3(edit_scale, edit_scale, edit_scale)
	else:
		edit_indicators.visible = false

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
	
	var forward = -camera.get_transform().basis.z.normalized()
	
	if edit_mode == EDIT_MODE.SPHERE:
		offset_pos += offset_sign * forward * (edit_scale - 2)
	elif edit_mode == EDIT_MODE.CUBE:
		# Multiply forward vector to touch cube sides.
		# This way you get smooth offset from any angle and size.
		var longest_axis = max(abs(forward.x), abs(forward.y), abs(forward.z))
		forward.x /= longest_axis
		forward.y /= longest_axis
		forward.z /= longest_axis
		offset_pos += offset_sign * forward * (edit_scale - 2)
	
	voxel_tool.mode = voxel_tool_mode
	
	if edit_mode == EDIT_MODE.SPHERE:
		voxel_tool.do_sphere(offset_pos, edit_scale)
	
	elif edit_mode == EDIT_MODE.CUBE:
		var offset = Vector3(edit_scale, edit_scale, edit_scale)
		voxel_tool.do_box(offset_pos - offset, offset_pos + offset)
	
	elif edit_mode == EDIT_MODE.BLEND_BALL:
		voxel_tool.smooth_sphere(hit_pos, edit_scale, blend_ball_range)
	
	elif edit_mode == EDIT_MODE.SURFACE:
#		edit_terrain(hit_pos)
		do_surface(hit_pos, voxel_tool_mode)
#		voxel_tool.do_sphere(offset_pos, edit_scale)
#		voxel_tool.smooth_sphere(offset_pos, edit_scale + surface_extra_radius_range, blend_ball_range)
		
	elif edit_mode == EDIT_MODE.TRIM:
		voxel_tool.smooth_sphere(hit_pos, edit_scale, blend_ball_range)
	
	update_edit_sphere()

func do_surface(hit_pos, voxel_tool_mode):
	# TODO: make function for copying values into buffer
	var radius2_1 = edit_scale * 2 + 1
	var buffer_size = Vector3i(radius2_1, radius2_1, radius2_1)
	var buffer_start_pos = Vector3i(hit_pos) - Vector3i(edit_scale, edit_scale, edit_scale)
	
	var buffer = VoxelBuffer.new()
	buffer.create(buffer_size.x, buffer_size.y, buffer_size.z)
	
	var sdf_channel = 1 << VoxelBuffer.CHANNEL_SDF
	voxel_tool.copy(buffer_start_pos, buffer, sdf_channel)
	
	for x in radius2_1:
		var dx = x - edit_scale
		for y in radius2_1:
			var dy = y - edit_scale
			for z in radius2_1:
				var dz = z - edit_scale
				var dist = sqrt(dx * dx + dy * dy + dz * dz)
				if dist > edit_scale:
					continue
					
				var value = (edit_scale - dist) / edit_scale
				if voxel_tool_mode == VoxelTool.MODE_ADD:
					value *= -1
				
				value *= edit_intensity
				
				var curr_value = buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
				buffer.set_voxel_f(curr_value + value, x, y, z, VoxelBuffer.CHANNEL_SDF)
	
	voxel_tool.paste(buffer_start_pos, buffer, sdf_channel)

func round_sphere_add(buffer, x, y, z, dx, dy, dz, radius):
	var curr_value = buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
	var dist = sqrt(dx * dx + dy * dy + dz * dz)
	var new_value = (dist - radius) / float(radius)
	return min(curr_value, new_value)

func cylinder_add(buffer, x, y, z, dx, _dy, dz, radius):
	var curr_value = buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
	var dist = sqrt(dx * dx + dz * dz)
	var new_value = (dist - radius) / float(radius)
	return min(curr_value, new_value)

func round_cube_add(buffer, x, y, z, dx, dy, dz, radius):
	var curr_value = buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
	var bx = 15
	var by = 15
	var bz = 15
	var qx = abs(dx) - bx
	var qy = abs(dy) - by
	var qz = abs(dz) - bz
	qx = max(qx, 0.0)
	qy = max(qy, 0.0)
	qz = max(qz, 0.0)
	var dist_q = sqrt(qx * qx + qy * qy + qz * qz)
	var new_value = dist_q + min(max(qx, max(qy, qz)), 0.0) - radius
	return min(curr_value, new_value)

func edit_terrain(hit_pos):
	var radius2_1 = edit_scale * 2 + 1
	var buffer_size = Vector3i(radius2_1, radius2_1, radius2_1)
	var buffer_start_pos = Vector3i(hit_pos) - Vector3i(edit_scale, edit_scale, edit_scale)
	
	var buffer = VoxelBuffer.new()
	buffer.create(buffer_size.x, buffer_size.y, buffer_size.z)
	
	var sdf_channel = 1 << VoxelBuffer.CHANNEL_SDF
	voxel_tool.copy(buffer_start_pos, buffer, sdf_channel)
	
	for x in radius2_1:
		var dx = x - edit_scale
		for y in radius2_1:
			var dy = y - edit_scale
			for z in radius2_1:
				var dz = z - edit_scale
				
#				var dist = sqrt(dx * dx + dy * dy + dz * dz)
#				var new_value = min(buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF), (dist - edit_scale) / float(edit_scale))
#				var new_value = min(buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF), (dist - edit_scale) / float(edit_scale))
#				buffer.set_voxel_f(new_value, x, y, z, VoxelBuffer.CHANNEL_SDF)
				
#				var new_value = round_sphere_add(buffer, x, y, z, dx, dy, dz, edit_scale)
				var new_value = cylinder_add(buffer, x, y, z, dx, dy, dz, edit_scale)
				buffer.set_voxel_f(new_value, x, y, z, VoxelBuffer.CHANNEL_SDF)
	
	voxel_tool.paste(buffer_start_pos, buffer, sdf_channel)

func test_edit():
	var hit = get_pointed_voxel()
	if hit:
		voxel_tool.mode = VoxelTool.MODE_REMOVE
		var hit_pos = Vector3(hit.position)
		var hit_pos2 = Vector3(hit_pos)
		hit_pos2.y += 30
		hit_pos2.x += 30
		var hit_pos3 = Vector3(hit_pos2)
		hit_pos3.x += 30
		hit_pos2.z += 5
		var hit_pos4 = Vector3(hit_pos3)
		hit_pos4.x += 20
		hit_pos4.y += 20
		hit_pos4.z += 20
		var points = PackedVector3Array([hit_pos, hit_pos2, hit_pos3, hit_pos4])
		var radii = PackedFloat32Array([5, 10, 8, 10])
		voxel_tool.do_path(points, radii)
		
		update_edit_sphere()

func capture_mouse(value):
	mouse_captured = value
	just_started_capturing_mouse = value
