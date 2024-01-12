extends Node

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

func _ready():
	set_edit_mode(EDIT_MODE.SPHERE)
	saver.load_data()
	
	# Required for surface tool to interact nicely when
	# surface is edited with other tools like sphere
	voxel_tool.sdf_scale = 0.1

func _process(delta):
	update_draw_timer(delta)
	
	if not Input.is_action_pressed("CTRL"):
		update_terraforming()
	
	# Edit sphere position and size can be affected in multiple sources,
	# so might as well just update it every frame
	update_edit_sphere()
	
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
	
	update_last_frame_data()

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

func set_edit_mode(new_edit_mode):
	var edit_mesh = edit_indicators.get_child(new_edit_mode)
	if edit_mesh:
		edit_mode = new_edit_mode
		for c in edit_indicators.get_children():
			c.visible = false
		edit_mesh.visible = true
		
		tool_select.selected = new_edit_mode
		
		tool_info.set_edit_mode(new_edit_mode)

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

func get_pointed_voxel():
	var origin = camera.get_position()
	var forward = -camera.get_transform().basis.z.normalized()
	var hit = voxel_tool.raycast(origin, forward, terraform_distance)
	return hit

func update_edit_sphere():
	if not edit_indicator_is_visible:
		return
	
	terraform_distance = base_terraform_distance * get_tool_scale()
	
	var hit = get_pointed_voxel()
	if hit:
		var pos = Vector3(hit.position)
		edit_indicators.visible = true
		edit_indicators.global_position = pos
		
		var tool_scale = get_tool_scale()
		edit_indicators.scale = Vector3(tool_scale, tool_scale, tool_scale)
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
	var edit_scale = get_tool_scale()
	var edit_strength = get_tool_strength()
	
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
		# TODO: consider adding falloff parameter which increases smoothness towards edges
		voxel_tool.smooth_sphere(hit_pos, edit_scale, edit_strength)
	
	elif edit_mode == EDIT_MODE.SURFACE:
#		do_surface(hit_pos, voxel_tool_mode)
		voxel_tool.do_surface(hit_pos, edit_scale, edit_strength)
		
	elif edit_mode == EDIT_MODE.FLATTEN:
		# TODO: consider adding falloff parameter which increases smoothness towards edges
		
		if last_frame_edit_data.flatten_plane == null:
			last_frame_edit_data.flatten_plane = Plane(forward, hit_pos)

		
#		var center_pos = last_frame_edit_data.flatten_plane.project(hit_pos)
		var center_pos = last_frame_edit_data.flatten_plane.intersects_ray(camera.get_position(), forward)
		if center_pos != null:
			voxel_tool.do_hemisphere(center_pos, edit_scale, offset_sign * last_frame_edit_data.flatten_plane.normal, edit_strength)
#			voxel_tool.do_flatten(center_pos, edit_scale, offset_sign * last_frame_edit_data.flatten_plane.normal, edit_strength)
#		do_flatten(hit_pos, -forward, offset_sign, edit_strength, voxel_tool_mode)

func apply_falloff(t, falloff):
	if falloff > 0:
		return minf(1, (1 - t) / falloff)
	else:
		return 1

#func do_surface(hit_pos, voxel_tool_mode):
#	var edit_scale = get_tool_scale()
#	# TODO: make function for copying values into buffer
#	var radius2_1 = edit_scale * 2 + 1
#	var buffer_size = Vector3i(radius2_1, radius2_1, radius2_1)
#	var buffer_start_pos = Vector3i(hit_pos) - Vector3i(edit_scale, edit_scale, edit_scale)
#
#	var buffer = VoxelBuffer.new()
#	buffer.create(buffer_size.x, buffer_size.y, buffer_size.z)
#
#	var sdf_channel = 1 << VoxelBuffer.CHANNEL_SDF
#	voxel_tool.copy(buffer_start_pos, buffer, sdf_channel)
#
#	for x in radius2_1:
#		var dx = x - edit_scale
#		for y in radius2_1:
#			var dy = y - edit_scale
#			for z in radius2_1:
#				var dz = z - edit_scale
#				var dist = sqrt(dx * dx + dy * dy + dz * dz)
#				if dist > edit_scale:
#					continue
#
#				var curr_value = buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
#				var new_value = 0
#				var falloff_value = apply_falloff(dist / edit_scale, 1.0)
#				if voxel_tool_mode == VoxelTool.MODE_ADD:
#					new_value = lerpf(curr_value, curr_value - get_tool_strength(), falloff_value)
#				else:
#					new_value = lerpf(curr_value, curr_value + get_tool_strength(), falloff_value)
#
#				buffer.set_voxel_f(new_value, x, y, z, VoxelBuffer.CHANNEL_SDF)
#
#	voxel_tool.paste(buffer_start_pos, buffer, sdf_channel)


#func do_flatten(hit_pos, forward, offset_sign, edit_strength, voxel_tool_mode):
#	if last_frame_edit_data.flatten_plane == null:
#		last_frame_edit_data.flatten_plane = Plane(forward, hit_pos)
#
#	hit_pos = last_frame_edit_data.flatten_plane.project(hit_pos)
#	var plane = offset_sign * last_frame_edit_data.flatten_plane
#
#	var edit_scale = get_tool_scale()
#	# TODO: make function for copying values into buffer
#	var radius2_1 = edit_scale * 2 + 1
#	var buffer_size = Vector3i(radius2_1, radius2_1, radius2_1)
#	var buffer_start_pos = Vector3i(hit_pos) - Vector3i(edit_scale, edit_scale, edit_scale)
#
#	var buffer = VoxelBuffer.new()
#	buffer.create(buffer_size.x, buffer_size.y, buffer_size.z)
#
#	var sdf_channel = 1 << VoxelBuffer.CHANNEL_SDF
#	voxel_tool.copy(buffer_start_pos, buffer, sdf_channel)
#
#	for x in radius2_1:
#		var dx = x - edit_scale
#		for y in radius2_1:
#			var dy = y - edit_scale
#			for z in radius2_1:
#				var dz = z - edit_scale
#
#				var point = Vector3(hit_pos + Vector3(dx, dy, dz))
#				var curr_distance = buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
#				var other_distance = plane.distance_to(point) * voxel_tool.sdf_scale
#
#				var dist = sqrt(dx * dx + dy * dy + dz * dz)
#
#				var final_value = 0.0
#
#				if voxel_tool_mode == VoxelTool.MODE_ADD:
#					final_value = min(other_distance, curr_distance)
#				else:
#					final_value = max(-other_distance, curr_distance)
#
#				var weight = max(0.0, (edit_scale - dist) / edit_scale)
#				weight = clampf(weight * 2.0, 0.0, 1.0)
#
#				final_value = lerpf(curr_distance, final_value, weight)
#				buffer.set_voxel_f(final_value, x, y, z, VoxelBuffer.CHANNEL_SDF)
#
#	voxel_tool.paste(buffer_start_pos, buffer, sdf_channel)

# assumes x, y, z, is center of sphere
func sphere_add(x, y, z, radius):
	var dist = sqrt(x * x + y * y + z * z)
	return (dist - radius) / radius

# creates cylinder it's aligned with y axis
# assumes x, y, z, is center of cyilnder
func cylinder_add(x, _y, z, radius):
	var dist = sqrt(x * x + z * z)
	return (dist - radius) / radius

func edit_terrain(hit_pos):
	var shape_size = get_tool_scale()
	var iteration_size = shape_size + 4
	var radius2_1 = iteration_size * 2 + 1
	var buffer_size = Vector3i(radius2_1, radius2_1, radius2_1)
	var buffer_start_pos = Vector3i(hit_pos) - Vector3i(iteration_size, iteration_size, iteration_size)
	
	var buffer = VoxelBuffer.new()
	buffer.create(buffer_size.x, buffer_size.y, buffer_size.z)
	
	var sdf_channel = 1 << VoxelBuffer.CHANNEL_SDF
	voxel_tool.copy(buffer_start_pos, buffer, sdf_channel)
	
	for x in radius2_1:
		var dx = x - iteration_size
		for y in radius2_1:
			var dy = y - iteration_size
			for z in radius2_1:
				var dz = z - iteration_size
				
				var curr_value = buffer.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
				var new_value = sphere_add(dx, dy, dz, shape_size)
				new_value = min(curr_value, new_value)
				buffer.set_voxel_f(new_value, x, y, z, VoxelBuffer.CHANNEL_SDF)
	
	voxel_tool.paste(buffer_start_pos, buffer, sdf_channel)

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
