extends Node

var base_terraform_distance = 50
var terraform_distance = base_terraform_distance

var edit_min_scale = 1.1
var edit_max_scale = 20
var edit_scale = edit_min_scale
var edit_scale_multiplier = 1.1

var edit_indicator_is_visible = true

var left_mouse_button_held = false
var right_mouse_button_held = false

var draw_speed = (2.0 / 60.0);
var accumulate_delta = 0.0;
var can_edit_terrain = true;

var blend_radius = 4

var mouse_captured = false

enum EDIT_MODE {SPHERE, CUBE, BLEND_BALL}
var edit_mode = EDIT_MODE.SPHERE

# temp
var enable_print = false

@onready var camera = get_node("Camera3D")
@onready var voxel_tool = get_node("VoxelTerrain").get_voxel_tool()
@onready var edit_indicators = get_node("EditIndicators")
@onready var sphere_edit_indicator = get_node("EditIndicators/SphereEdit")
@onready var cube_edit_indicator = get_node("EditIndicators/CubeEdit")
@onready var help_window = get_node("CanvasLayer")

func _ready():
	voxel_tool.sdf_scale = 0.3
	set_edit_mode(EDIT_MODE.SPHERE)

func _process(delta):
	update_draw_timer(delta)
	
	if not Input.is_action_pressed("CTRL"):
		update_terraforming()

func _input(event):
	if Input.is_action_just_pressed("STOP_MOUSE_CAPTURE"):
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !mouse_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true
	
	# Testing
#	if event is InputEventKey:
#		if event.pressed:
#			match event.keycode:
#				KEY_ENTER:
#					remove_child(get_child(0))
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				left_mouse_button_held = event.pressed
				if event.pressed and Input.is_action_pressed("CTRL"):
					update_terraforming()
			MOUSE_BUTTON_RIGHT:
				right_mouse_button_held = event.pressed
				if event.pressed and Input.is_action_pressed("CTRL"):
					update_terraforming()
			MOUSE_BUTTON_WHEEL_UP:
				if not Input.is_action_pressed("ALT"):
					edit_scale= clamp(edit_scale / edit_scale_multiplier, edit_min_scale, edit_max_scale)
			MOUSE_BUTTON_WHEEL_DOWN:
				if not Input.is_action_pressed("ALT"):
					edit_scale= clamp(edit_scale * edit_scale_multiplier, edit_min_scale, edit_max_scale)
	
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_SPACE:
					edit_indicator_is_visible = not edit_indicator_is_visible
					edit_indicators.visible = edit_indicator_is_visible
#				KEY_P:
#					enable_print = not enable_print
#				KEY_T:
#					voxel_tool.sdf_scale = 0.3
				KEY_H:
					help_window.visible = not help_window.visible
				KEY_1:
					set_edit_mode(EDIT_MODE.SPHERE)
				KEY_2:
					set_edit_mode(EDIT_MODE.CUBE)
				KEY_3:
					set_edit_mode(EDIT_MODE.BLEND_BALL)
	
	update_edit_sphere()

func set_edit_mode(new_edit_mode):
	var edit_mesh = edit_indicators.get_child(new_edit_mode)
	if edit_mesh:
		edit_mode = new_edit_mode
		for c in edit_indicators.get_children():
			c.visible = false
		edit_mesh.visible = true

func update_draw_timer(delta):
	if accumulate_delta > draw_speed:
		can_edit_terrain = true;
	else:
		accumulate_delta += delta;

func update_terraforming():
	if not can_edit_terrain:
		return
	
	if left_mouse_button_held:
		can_edit_terrain = false
		accumulate_delta = 0.0
		try_place_block()
#		try_place_block2()
	elif right_mouse_button_held:
		can_edit_terrain = false
		accumulate_delta = 0.0
		try_break_block()

func get_pointed_voxel():
	var origin = camera.get_global_transform().origin
	var forward = -camera.get_transform().basis.z.normalized()
	var hit = voxel_tool.raycast(origin, forward, terraform_distance)
	return hit

func update_edit_sphere():
	if not edit_indicator_is_visible:
		return
	
	terraform_distance = base_terraform_distance * edit_scale
	edit_indicators.scale = Vector3(edit_scale, edit_scale, edit_scale)
	var hit = get_pointed_voxel()
	if hit:
		var pos = Vector3(hit.position)
		edit_indicators.visible = true
		edit_indicators.global_position = pos
	else:
		edit_indicators.visible = false


func try_break_block():
	var hit = get_pointed_voxel()
	if hit:
		var hit_pos = Vector3(hit.position)
		
		if edit_mode == EDIT_MODE.SPHERE:
			var forward = -camera.get_transform().basis.z.normalized()
			hit_pos -= forward * (edit_scale- 2)
			voxel_tool.value = 0
			voxel_tool.mode = VoxelTool.MODE_REMOVE
			voxel_tool.do_sphere(hit_pos, edit_scale)
		
		elif edit_mode == EDIT_MODE.CUBE:
			var forward = -camera.get_transform().basis.z.normalized()
			hit_pos -= forward * (edit_scale- 2)
			voxel_tool.value = 0
			voxel_tool.mode = VoxelTool.MODE_REMOVE
			var offset = Vector3(edit_scale, edit_scale, edit_scale)
			voxel_tool.do_box(hit_pos - offset, hit_pos + offset)
		
		elif edit_mode == EDIT_MODE.BLEND_BALL:
			blend_ball(hit_pos, blend_radius)
		
		update_edit_sphere()

func try_place_block():
	var hit = get_pointed_voxel()
	if hit:
		var hit_pos = Vector3(hit.position)
		
		if edit_mode == EDIT_MODE.SPHERE:
			var forward = -camera.get_transform().basis.z.normalized()
			hit_pos += forward * (edit_scale- 2)
			voxel_tool.value = 1
			voxel_tool.mode = VoxelTool.MODE_ADD
			voxel_tool.do_sphere(hit_pos, edit_scale)
		
		elif edit_mode == EDIT_MODE.CUBE:
			var forward = -camera.get_transform().basis.z.normalized()
			hit_pos += forward * (edit_scale- 2)
			voxel_tool.value = 1
			voxel_tool.mode = VoxelTool.MODE_ADD
			var offset = Vector3(edit_scale, edit_scale, edit_scale)
			voxel_tool.do_box(hit_pos - offset, hit_pos + offset)
		
		elif edit_mode == EDIT_MODE.BLEND_BALL:
			blend_ball(hit_pos, blend_radius)
		
		update_edit_sphere()

func blend_ball(pos, radius):
#	blend_ball_test(pos, radius)
#	return
	if enable_print:
		print("--BLEND BALL--")
	
	var brush_size = int(edit_scale)
	var brush_size_squared = brush_size * brush_size
	
	var buffer = VoxelBuffer.new()
	
	var buffer_size = brush_size * 2 + 1
	buffer.create(buffer_size, buffer_size, buffer_size)
	var sdf_mask = 1 << VoxelBuffer.CHANNEL_SDF
	var _sdf_channel = VoxelBuffer.CHANNEL_SDF
	var map_pos = Vector3i(pos)
	map_pos.x -= brush_size
	map_pos.y -= brush_size
	map_pos.z -= brush_size
	voxel_tool.copy(map_pos, buffer, sdf_mask)
	
	if enable_print:
		print("buffer_size: " + str(buffer_size))
	
	for x in buffer_size:
		var xi = x - brush_size
		var x0 = pos.x + xi
		for y in buffer_size:
			var yi = y - brush_size
			var y0 = pos.y + yi
			for z in buffer_size:
				var zi = z - brush_size
				var z0 = pos.z + zi
				
				var distance = xi * xi + yi * yi + zi * zi
				if (distance >= brush_size_squared):
					continue

				var sdf_sum = 0.0
				var blend_range_diameter = radius * 2 + 1

				for ox in blend_range_diameter:
					for oy in blend_range_diameter:
						for oz in blend_range_diameter:
							var pos_x = x0 + (ox - radius)
							var pos_y = y0 + (oy - radius)
							var pos_z = z0 + (oz - radius)
							var voxel_pos = Vector3i(pos_x, pos_y, pos_z)

							sdf_sum += voxel_tool.get_voxel_f(voxel_pos)

				var total_elements = blend_range_diameter * blend_range_diameter * blend_range_diameter
				var average = sdf_sum / float(total_elements);
				if enable_print:
					print("total_elements: " + str(total_elements))
					print("sdf_sum: " + str(sdf_sum))
					print("average: " + str(average))

				# make it map [-1, 1] instead of [0, 1]
				
				# TODO: check if it looks good without this on 2D with weighted result
#				average = map_value(average, -1, 1, 0, 1)
#				average = ease_in_out_cubic(average);
#				average = map_value(average, 0, 1, -1, 1)
				
				var voxel_pos = Vector3i(x0, y0, z0)
				var curr_voxel_value = voxel_tool.get_voxel_f(voxel_pos)
				
				var distance_normalised = float(distance) / float(brush_size_squared)
				var new_voxel_value = curr_voxel_value * distance_normalised + average * (1 - distance_normalised)
				
				buffer.set_voxel_f(new_voxel_value, x, y, z, VoxelBuffer.CHANNEL_SDF)
	
	voxel_tool.paste(map_pos, buffer, sdf_mask, 0xffffffff)

func blend_ball_test(pos, radius):
	var brush_size = int(edit_scale)
	var brush_size_squared = brush_size * brush_size
	
	var buffer = VoxelBuffer.new()
	
	var buffer_size = brush_size * 2 + 1
	buffer.create(buffer_size, buffer_size, buffer_size)
	var sdf_mask = 1 << VoxelBuffer.CHANNEL_SDF
	var _sdf_channel = VoxelBuffer.CHANNEL_SDF
	var map_pos = Vector3i(pos)
	map_pos.x -= brush_size
	map_pos.y -= brush_size
	map_pos.z -= brush_size
	voxel_tool.copy(map_pos, buffer, sdf_mask)
	
	for x in buffer_size:
		var xi = x - brush_size
		var x0 = pos.x + xi
		for y in buffer_size:
			var yi = y - brush_size
			var y0 = pos.y + yi
			for z in buffer_size:
				var zi = z - brush_size
				var z0 = pos.z + zi
				
				var distance = xi * xi + yi * yi + zi * zi
				if (distance >= brush_size_squared):
					continue

				var air_count = 0
				var ground_count = 0
				var blend_range_diameter = radius * 2 + 1

				for ox in blend_range_diameter:
					for oy in blend_range_diameter:
						for oz in blend_range_diameter:
							var pos_x = x0 + (ox - radius)
							var pos_y = y0 + (oy - radius)
							var pos_z = z0 + (oz - radius)
							var voxel_pos = Vector3i(pos_x, pos_y, pos_z)
							
							var value = voxel_tool.get_voxel_f(voxel_pos)
							if value > 0:
								air_count += 1
							else:
								ground_count += 1
				
				var blend_strength_decrease = 0.2 * (air_count + ground_count)
				var diff = abs(air_count - ground_count)
				if air_count > ground_count and diff > blend_strength_decrease:
					buffer.set_voxel_f(1, x, y, z, VoxelBuffer.CHANNEL_SDF)
				elif air_count < ground_count and diff > blend_strength_decrease:
					buffer.set_voxel_f(-1, x, y, z, VoxelBuffer.CHANNEL_SDF)
	
	voxel_tool.paste(map_pos, buffer, sdf_mask, 0xffffffff)

func ease_in_out_cubic(x):
	if x < 0.5:
		return 4 * x * x * x
	else:
		return 1 - pow(-2 * x + 2, 3) / 2

func map_value(value, in_min, in_max, out_min, out_max):
	return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min

func try_place_block2():
	var hit = get_pointed_voxel()
	if hit:
		var pos = camera.get_global_transform().origin
		var forward = camera.get_transform().basis.z.normalized()
#		pos = pos - forward * (edit_scale- 1)
		pos = pos - hit.distance * forward * edit_scale
		
		voxel_tool.value = 1
		voxel_tool.mode = VoxelTool.MODE_ADD
		voxel_tool.do_sphere(pos, edit_scale)
		update_edit_sphere()
